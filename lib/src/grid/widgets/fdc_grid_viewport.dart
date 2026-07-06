// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;

import '../../common/menu/fdc_menu_entry.dart';
import '../../common/menu/fdc_menu_renderer.dart';
import '../core/fdc_grid_runtime_constants.dart';
import '../managers/fdc_grid_scroll_coordinator.dart';
import '../models/fdc_grid_internal_models.dart';
import '../models/fdc_grid_range_selection_feature.dart';
import 'fdc_grid_painters.dart';
import 'fdc_grid_visible_column_window.dart';

const Set<PointerDeviceKind> _fdcGridScrollDragDevices = {
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.trackpad,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
};

class FdcGridScrollBehavior extends MaterialScrollBehavior {
  const FdcGridScrollBehavior({this.dragScrollEnabled = true});

  final bool dragScrollEnabled;

  @override
  Set<PointerDeviceKind> get dragDevices {
    return dragScrollEnabled
        ? _fdcGridScrollDragDevices
        : const <PointerDeviceKind>{};
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return dragScrollEnabled
        ? const ClampingScrollPhysics()
        : const NeverScrollableScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _FdcGridSizeObserver extends SingleChildRenderObjectWidget {
  const _FdcGridSizeObserver({
    required this.onSizeChanged,
    required super.child,
  });

  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _FdcGridSizeObserverRenderObject(onSizeChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _FdcGridSizeObserverRenderObject renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _FdcGridSizeObserverRenderObject extends RenderProxyBox {
  _FdcGridSizeObserverRenderObject(this._onSizeChanged);

  ValueChanged<Size> _onSizeChanged;
  Size? _reportedSize;

  ValueChanged<Size> get onSizeChanged => _onSizeChanged;

  set onSizeChanged(ValueChanged<Size> value) {
    if (identical(_onSizeChanged, value)) {
      return;
    }
    // The viewport builder supplies a fresh closure on each rebuild. Changing
    // only the callback identity must not invalidate the last reported size:
    // nested child interaction would otherwise report an unchanged detail
    // extent again and unnecessarily rebuild the owning master grid.
    _onSizeChanged = value;
  }

  @override
  void performLayout() {
    super.performLayout();
    if (_reportedSize == size) {
      return;
    }
    _reportedSize = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached && _reportedSize == size) {
        onSizeChanged(size);
      }
    });
  }
}

bool _isOwnedGridMetricsNotification(
  FdcGridViewportModel model,
  ScrollMetricsNotification notification,
) {
  final scrollable = Scrollable.maybeOf(notification.context);
  if (scrollable == null) {
    return false;
  }

  final position = scrollable.position;
  final controller = notification.metrics.axis == Axis.vertical
      ? model.verticalScrollController
      : model.horizontalScrollController;
  if (!controller.hasClients) {
    return false;
  }

  for (final ownedPosition in controller.positions) {
    if (identical(ownedPosition, position)) {
      return true;
    }
  }
  return false;
}

class FdcGridViewport extends StatefulWidget {
  const FdcGridViewport({
    super.key,
    required this.model,
    required this.callbacks,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;

  @override
  State<FdcGridViewport> createState() => _FdcGridViewportState();
}

class _FdcGridViewportState extends State<FdcGridViewport> {
  bool _rangeDragging = false;
  Offset? _lastPointerGlobalPosition;
  ({int rowIndex, int columnIndex})? _rangeContextMenuCell;
  OverlayEntry? _rangeContextMenuOverlay;
  Timer? _autoScrollTimer;

  FdcGridViewportModel get model => widget.model;
  FdcGridViewportCallbacks get callbacks => widget.callbacks;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _hideRangeContextMenu();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FdcGridViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (model.selectedRangeBounds == null) {
      _hideRangeContextMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _handlePointerEnter,
      onHover: _handlePointerHover,
      onExit: (_) => callbacks.onRangePointerCellChanged(null, null),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerHover: _handlePointerHover,
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: (_) => _finishRangeDrag(),
        onPointerCancel: (_) => _finishRangeDrag(),
        onPointerSignal: (event) {
          // A completed range remains visible after Shift is released, but it
          // must not make the grid viewport inert. Only the active Shift/drag
          // phases suppress scrolling in the grid runtime; plain wheel/trackpad
          // scroll should continue to move the viewport while the selected
          // range stays painted.
          if (_isHeaderPointerScroll(model, event)) {
            GestureBinding.instance.pointerSignalResolver.register(
              event,
              (_) {},
            );
            return;
          }
          callbacks.onPointerSignal(event);
        },
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) {
            final owned = _isOwnedGridMetricsNotification(model, notification);
            if (!owned) return false;
            model.scrollCoordinator.updateViewportMetrics(notification.metrics);
            return false;
          },
          child: ScrollConfiguration(
            behavior: FdcGridScrollBehavior(
              dragScrollEnabled:
                  !model.hasActiveCellEditor &&
                  !model.rangeSelectionModifierActive,
            ),
            child: AbsorbPointer(
              // During Shift range selection the outer Listener is the sole
              // pointer owner. Prevent every nested Scrollable, MouseRegion and
              // cell control from joining the mouse gesture arena or receiving
              // drag updates that can move the viewport behind the range drag.
              absorbing:
                  model.rangeSelectionModifierActive ||
                  model.selectedRangeBounds != null,
              child: ColoredBox(
                color: model.backgroundColor,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: model.topInset,
                    bottom: model.bottomInset,
                  ),
                  child: FdcGridSplitViewport(
                    model: model,
                    callbacks: callbacks,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePointerEnter(PointerEnterEvent event) {
    _publishPointerCell(event.localPosition);
  }

  void _handlePointerHover(PointerHoverEvent event) {
    _publishPointerCell(event.localPosition);
  }

  void _publishPointerCell(Offset localPosition) {
    final cell = _cellAt(localPosition, clampToBody: false);
    callbacks.onRangePointerCellChanged(cell?.rowIndex, cell?.columnIndex);
  }

  void _handlePointerDown(PointerDownEvent event) {
    _publishPointerCell(event.localPosition);
    final primaryPressed = (event.buttons & kPrimaryMouseButton) != 0;
    final secondaryPressed = (event.buttons & kSecondaryMouseButton) != 0;
    if (_updateRangeContextMenuTarget(event, secondaryPressed)) {
      _showRangeContextMenu(event.position);
    }
    if (!primaryPressed) return;
    if (!model.rangeSelectionModifierActive) {
      if (model.selectedRangeBounds != null) {
        // The range overlay is modal. The first click only dismisses it and is
        // deliberately not forwarded to lookup/picker/cell controls below.
        _hideRangeContextMenu();
        callbacks.onRangeOverlayDismiss();
      }
      return;
    }
    final cell = _cellAt(event.localPosition, clampToBody: false);
    if (cell == null) return;
    _rangeDragging = true;
    _lastPointerGlobalPosition = event.position;
    callbacks.onRangeDragStart(cell.rowIndex, cell.columnIndex);
    _startAutoScrollTimer();
  }

  bool _updateRangeContextMenuTarget(
    PointerDownEvent event,
    bool secondaryPressed,
  ) {
    _rangeContextMenuCell = null;
    if (!secondaryPressed ||
        model.rangeSelectionContextMenuBuilder == null ||
        model.selectedRangeBounds == null) {
      return false;
    }
    final cell = _cellAt(event.localPosition, clampToBody: false);
    if (!_rangeSelectionContainsCell(cell)) {
      return false;
    }
    _rangeContextMenuCell = cell;
    return true;
  }

  List<FdcMenuEntry> _buildRangeSelectionContextMenuEntries() {
    final builder = model.rangeSelectionContextMenuBuilder;
    if (builder == null || !_canOpenRangeSelectionContextMenu()) {
      return const <FdcMenuEntry>[];
    }
    return builder(
      context,
      FdcGridRangeSelectionContextMenuContext(
        copyEnabled: model.rangeSelectionCopyEnabled,
        pasteEnabled: model.rangeSelectionPasteEnabled,
        onCopy: () {
          _hideRangeContextMenu();
          callbacks.onRangeSelectionCopy();
        },
        onPaste: () {
          _hideRangeContextMenu();
          callbacks.onRangeSelectionPaste();
        },
      ),
    );
  }

  bool _canOpenRangeSelectionContextMenu() {
    return model.rangeSelectionContextMenuBuilder != null &&
        _rangeSelectionContainsCell(_rangeContextMenuCell);
  }

  void _showRangeContextMenu(Offset globalPosition) {
    final overlay = Overlay.maybeOf(context);
    final overlayBox = overlay?.context.findRenderObject();
    if (overlay == null ||
        overlayBox is! RenderBox ||
        !_canOpenRangeSelectionContextMenu()) {
      return;
    }
    final entries = _buildRangeSelectionContextMenuEntries();
    if (entries.isEmpty) {
      return;
    }
    _rangeContextMenuOverlay?.remove();
    _rangeContextMenuOverlay = null;
    final menuPosition = overlayBox.globalToLocal(globalPosition);

    final entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  final primaryPressed =
                      (event.buttons & kPrimaryMouseButton) != 0;
                  _hideRangeContextMenu();
                  if (primaryPressed &&
                      model.selectedRangeBounds != null &&
                      !model.rangeSelectionModifierActive) {
                    callbacks.onRangeOverlayDismiss();
                  }
                },
              ),
            ),
            Positioned(
              left: menuPosition.dx,
              top: menuPosition.dy,
              child: FdcMenuPanel(entries: entries),
            ),
          ],
        );
      },
    );
    _rangeContextMenuOverlay = entry;
    overlay.insert(entry);
  }

  void _hideRangeContextMenu() {
    _rangeContextMenuOverlay?.remove();
    _rangeContextMenuOverlay = null;
    _rangeContextMenuCell = null;
  }

  bool _rangeSelectionContainsCell(({int rowIndex, int columnIndex})? cell) {
    final containsCell = model.rangeSelectionContainsCell;
    return cell != null &&
        containsCell?.call(cell.rowIndex, cell.columnIndex) == true;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _publishPointerCell(event.localPosition);
    if (!_rangeDragging) return;
    _lastPointerGlobalPosition = event.position;
    _applyRangePointerGlobal(event.position, allowAutoScroll: true);
  }

  void _finishRangeDrag() {
    if (!_rangeDragging) return;
    _rangeDragging = false;
    _lastPointerGlobalPosition = null;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    callbacks.onRangeDragEnd();
  }

  void _startAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      final globalPosition = _lastPointerGlobalPosition;
      if (!mounted || !_rangeDragging || globalPosition == null) return;
      _applyRangePointerGlobal(globalPosition, allowAutoScroll: true);
    });
  }

  void _applyRangePointerGlobal(
    Offset globalPosition, {
    required bool allowAutoScroll,
  }) {
    final localPosition = _localPositionFromGlobal(globalPosition);
    if (localPosition == null) return;
    if (allowAutoScroll) _autoScroll(globalPosition);
    final cell = _cellAt(localPosition, clampToBody: true);
    if (cell == null) return;
    callbacks.onRangeDragUpdate(cell.rowIndex, cell.columnIndex);
  }

  Offset? _localPositionFromGlobal(Offset globalPosition) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    return renderObject.globalToLocal(globalPosition);
  }

  Rect? _globalRangeBodyRect() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final bodyTop = model.topInset + model.effectiveHeaderHeight;
    final bodyBottom = bodyTop + model.visibleRowsHeight;
    final topLeft = renderObject.localToGlobal(Offset(0, bodyTop));
    final bottomRight = renderObject.localToGlobal(
      Offset(renderObject.size.width, bodyBottom),
    );
    return Rect.fromPoints(topLeft, bottomRight);
  }

  void _autoScroll(Offset globalPosition) {
    const edge = 24.0;
    const step = 18.0;
    final bodyRect = _globalRangeBodyRect();
    if (bodyRect == null || bodyRect.contains(globalPosition)) return;

    double verticalDelta = 0;
    if (globalPosition.dy < bodyRect.top) {
      verticalDelta = -step * (1 + (bodyRect.top - globalPosition.dy) / edge);
    } else if (globalPosition.dy > bodyRect.bottom) {
      verticalDelta = step * (1 + (globalPosition.dy - bodyRect.bottom) / edge);
    }
    if (verticalDelta != 0 && model.verticalScrollController.hasClients) {
      final controller = model.verticalScrollController;
      final target = (controller.offset + verticalDelta)
          .clamp(
            controller.position.minScrollExtent,
            controller.position.maxScrollExtent,
          )
          .toDouble();
      model.scrollCoordinator.moveVerticalOffsetRestoreLock(target);
    }

    double horizontalDelta = 0;
    if (globalPosition.dx < bodyRect.left) {
      horizontalDelta =
          -step * (1 + (bodyRect.left - globalPosition.dx) / edge);
    } else if (globalPosition.dx > bodyRect.right) {
      horizontalDelta =
          step * (1 + (globalPosition.dx - bodyRect.right) / edge);
    }
    if (horizontalDelta != 0 && model.horizontalScrollController.hasClients) {
      final controller = model.horizontalScrollController;
      final target = (controller.offset + horizontalDelta)
          .clamp(
            controller.position.minScrollExtent,
            controller.position.maxScrollExtent,
          )
          .toDouble();
      model.scrollCoordinator.moveHorizontalOffsetRestoreLock(target);
    }
  }

  ({int rowIndex, int columnIndex})? _cellAt(
    Offset position, {
    required bool clampToBody,
  }) {
    if (model.rowsLength <= 0) return null;
    final size = context.size;
    final viewportWidth = size?.width ?? model.paintedGridWidth;
    final bodyTop = model.topInset + model.effectiveHeaderHeight;
    final bodyBottom = bodyTop + model.visibleRowsHeight;
    if (bodyBottom <= bodyTop) return null;
    if (!clampToBody && (position.dy < bodyTop || position.dy > bodyBottom)) {
      return null;
    }
    final y = position.dy.clamp(bodyTop, bodyBottom - 0.001).toDouble();
    final contentY = y - bodyTop + model.scrollCoordinator.liveVerticalOffset;
    final rowIndex = model.rowIndexAtOffset(contentY);

    final rowIndicatorWidth = model.layoutRegions.rowIndicatorWidth;
    final left = model.columnBandLayouts.pinnedLeft;
    final center = model.columnBandLayouts.scrollable;
    final right = model.columnBandLayouts.pinnedRight;
    final centerOrigin = rowIndicatorWidth + left.width;
    final rightOrigin = math.max(centerOrigin, viewportWidth - right.width);
    if (viewportWidth <= rowIndicatorWidth) return null;
    if (!clampToBody &&
        (position.dx < rowIndicatorWidth || position.dx >= viewportWidth)) {
      return null;
    }
    final x = position.dx
        .clamp(rowIndicatorWidth, viewportWidth - 0.001)
        .toDouble();

    FdcGridColumnBandLayout layout;
    double localX;
    if (x < centerOrigin && left.isNotEmpty) {
      layout = left;
      localX = x - rowIndicatorWidth;
    } else if (x >= rightOrigin && right.isNotEmpty) {
      layout = right;
      localX = x - rightOrigin;
    } else {
      layout = center;
      localX = x - centerOrigin + model.scrollCoordinator.liveHorizontalOffset;
    }
    if (layout.isEmpty) return null;
    final geometry = layout.geometries.firstWhere(
      (g) => localX >= g.offset && localX < g.offset + g.width,
      orElse: () =>
          localX < 0 ? layout.geometries.first : layout.geometries.last,
    );
    final result = (
      rowIndex: rowIndex,
      columnIndex: geometry.sourceColumnIndex,
    );
    return result;
  }
}

bool _isHeaderPointerScroll(
  FdcGridViewportModel model,
  PointerSignalEvent event,
) {
  if (event is! PointerScrollEvent || model.effectiveHeaderHeight <= 0) {
    return false;
  }

  final localY = event.localPosition.dy;
  final insetAdjustedY = localY - model.topInset;
  return _isHeaderLocalY(localY, headerHeight: model.effectiveHeaderHeight) ||
      _isHeaderLocalY(
        insetAdjustedY,
        headerHeight: model.effectiveHeaderHeight,
      );
}

bool _isHeaderLocalY(double localY, {required double headerHeight}) {
  return localY >= 0 && localY <= headerHeight;
}

class FdcGridOptionalScrollbar extends StatelessWidget {
  const FdcGridOptionalScrollbar({
    super.key,
    required this.visible,
    required this.controller,
    required this.notificationPredicate,
    required this.child,
  });

  final bool visible;
  final ScrollController controller;
  final ScrollNotificationPredicate notificationPredicate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return child;
    }

    return Scrollbar(
      controller: controller,
      notificationPredicate: notificationPredicate,
      child: child,
    );
  }
}

class FdcGridSplitViewport extends StatelessWidget {
  const FdcGridSplitViewport({
    super.key,
    required this.model,
    required this.callbacks,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.hasBoundedHeight
            ? math.max(0.0, constraints.maxHeight)
            : model.effectiveHeaderHeight + model.visibleRowsHeight;
        final headerHeight = math.min(
          model.effectiveHeaderHeight,
          availableHeight,
        );
        final remainingHeight = math.max(0.0, availableHeight - headerHeight);
        final bodyHeight = math.min(model.visibleRowsHeight, remainingHeight);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (headerHeight > 0)
              SizedBox(
                height: headerHeight,
                child: FdcGridHeaderRow(
                  model: model,
                  callbacks: callbacks,
                  height: headerHeight,
                ),
              ),
            if (bodyHeight > 0)
              SizedBox(
                height: bodyHeight,
                child: FdcGridOptionalScrollbar(
                  visible: model.options.showVerticalScrollbar,
                  controller: model.verticalScrollController,
                  notificationPredicate: (notification) {
                    return notification.depth == 0 &&
                        notification.metrics.axis == Axis.vertical;
                  },
                  child: FdcGridBodyRow(
                    model: model,
                    callbacks: callbacks,
                    height: bodyHeight,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class FdcGridHeaderRow extends StatelessWidget {
  const FdcGridHeaderRow({
    super.key,
    required this.model,
    required this.callbacks,
    required this.height,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;
  final double height;

  @override
  Widget build(BuildContext context) {
    final rowIndicatorRegionLayout = model.layoutRegions.rowIndicatorLayout;
    final pinnedLeftLayout = model.columnBandLayouts.pinnedLeft;
    final scrollableLayout = model.columnBandLayouts.scrollable;
    final pinnedRightLayout = model.columnBandLayouts.pinnedRight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.hasBoundedWidth
            ? math.max(0.0, constraints.maxWidth)
            : model.layoutRegions.leadingPinnedWidth +
                  scrollableLayout.width +
                  pinnedRightLayout.width;
        final headerBottomSeparatorSegments = _headerBottomSeparatorSegments(
          viewportWidth: viewportWidth,
          rowIndicatorWidth: model.layoutRegions.rowIndicatorWidth,
          pinnedLeftWidth: pinnedLeftLayout.width,
          scrollableDataWidth: scrollableLayout.width,
          pinnedRightWidth: pinnedRightLayout.width,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (rowIndicatorRegionLayout != null)
                    SizedBox(
                      width: rowIndicatorRegionLayout.width,
                      height: height,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topLeft,
                          heightFactor: 1,
                          child: callbacks.buildRowIndicatorRegionHeader(
                            context,
                            rowIndicatorRegionLayout.width,
                          ),
                        ),
                      ),
                    ),
                  if (pinnedLeftLayout.isNotEmpty)
                    FdcGridPinnedHeaderRegion(
                      model: model,
                      callbacks: callbacks,
                      columnLayout: pinnedLeftLayout,
                      height: height,
                      showTrailingBoundary: model.showVerticalGridLines,
                    ),
                  Expanded(
                    child: model.centerViewportWidth <= 0.5
                        ? const SizedBox.shrink()
                        : _FdcHeaderScrollInputRegion(
                            model: model,
                            callbacks: callbacks,
                            height: height,
                            child: FdcGridScrollableHeaderRegion(
                              model: model,
                              callbacks: callbacks,
                              height: height,
                            ),
                          ),
                  ),
                  if (pinnedRightLayout.isNotEmpty)
                    FdcGridPinnedHeaderRegion(
                      model: model,
                      callbacks: callbacks,
                      columnLayout: pinnedRightLayout,
                      height: height,
                      showLeadingBoundary: model.showVerticalGridLines,
                      enableLeadingResizeHandle: true,
                    ),
                ],
              ),
            ),
            for (final segment in headerBottomSeparatorSegments)
              Positioned(
                left: segment.left,
                bottom: 0,
                width: segment.width,
                height: 1,
                child: IgnorePointer(
                  child: ColoredBox(color: model.headerSeparatorColor),
                ),
              ),
          ],
        );
      },
    );
  }

  static List<FdcHeaderBottomSeparatorSegment> _headerBottomSeparatorSegments({
    required double viewportWidth,
    required double rowIndicatorWidth,
    required double pinnedLeftWidth,
    required double scrollableDataWidth,
    required double pinnedRightWidth,
  }) {
    if (viewportWidth <= 0) {
      return const <FdcHeaderBottomSeparatorSegment>[];
    }

    final leadingWidth = rowIndicatorWidth + pinnedLeftWidth;
    final rightPinnedWidth = math.min(pinnedRightWidth, viewportWidth);
    final scrollableViewportWidth = math.max(
      0.0,
      viewportWidth - leadingWidth - rightPinnedWidth,
    );
    final visibleScrollableWidth =
        rightPinnedWidth > 0 && scrollableDataWidth > 0
        ? scrollableViewportWidth
        : math.min(scrollableDataWidth, scrollableViewportWidth);
    final leftSegmentWidth = math.min(
      viewportWidth,
      math.max(0.0, leadingWidth + visibleScrollableWidth),
    );

    if (rightPinnedWidth <= 0) {
      if (leftSegmentWidth <= 0) {
        return const <FdcHeaderBottomSeparatorSegment>[];
      }
      return <FdcHeaderBottomSeparatorSegment>[
        FdcHeaderBottomSeparatorSegment(left: 0, width: leftSegmentWidth),
      ];
    }

    final rightSegmentLeft = math.max(0.0, viewportWidth - rightPinnedWidth);
    final segments = <FdcHeaderBottomSeparatorSegment>[];

    if (leftSegmentWidth > 0) {
      segments.add(
        FdcHeaderBottomSeparatorSegment(
          left: 0,
          width: math.min(leftSegmentWidth, rightSegmentLeft),
        ),
      );
    }

    if (rightPinnedWidth > 0) {
      segments.add(
        FdcHeaderBottomSeparatorSegment(
          left: rightSegmentLeft,
          width: rightPinnedWidth,
        ),
      );
    }

    return segments;
  }
}

@immutable
class FdcHeaderBottomSeparatorSegment {
  const FdcHeaderBottomSeparatorSegment({
    required this.left,
    required this.width,
  });

  final double left;
  final double width;
}

class _FdcHeaderScrollInputRegion extends StatefulWidget {
  const _FdcHeaderScrollInputRegion({
    required this.model,
    required this.callbacks,
    required this.height,
    required this.child,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;
  final double height;
  final Widget child;

  @override
  State<_FdcHeaderScrollInputRegion> createState() =>
      _FdcHeaderScrollInputRegionState();
}

class _FdcHeaderScrollInputRegionState
    extends State<_FdcHeaderScrollInputRegion> {
  static const double _dragSlop = 4.0;

  int? _pointer;
  Offset? _lastLocalPosition;
  double _pendingDeltaX = 0.0;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: widget.child,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _resetPointerState();
    if (!_isPrimaryPointer(event) || !_canStartFrom(event.localPosition)) {
      return;
    }

    _pointer = event.pointer;
    _lastLocalPosition = event.localPosition;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer ||
        widget.model.resizingRuntimeColumnId != null ||
        widget.model.draggingColumnIndex != null) {
      _endDrag();
      return;
    }

    final previous = _lastLocalPosition;
    if (previous == null) {
      return;
    }

    final delta = event.localPosition - previous;
    _lastLocalPosition = event.localPosition;

    if (!_dragging) {
      _pendingDeltaX += delta.dx;
      if (_pendingDeltaX.abs() < _dragSlop) {
        return;
      }
      _dragging = true;
      widget.callbacks.onHeaderHorizontalDragStart();
      widget.callbacks.onHeaderHorizontalDragUpdate(_pendingDeltaX);
      _pendingDeltaX = 0.0;
      return;
    }

    widget.callbacks.onHeaderHorizontalDragUpdate(delta.dx);
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer == _pointer) {
      _endDrag();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _pointer) {
      _endDrag();
    }
  }

  bool _isPrimaryPointer(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse) {
      return (event.buttons & kPrimaryMouseButton) != 0;
    }
    return true;
  }

  bool _canStartFrom(Offset localPosition) {
    if (!widget.model.scrollCoordinator.hasHorizontalClients ||
        !widget.model.scrollCoordinator.hasHorizontalScrollableRange ||
        widget.model.resizingRuntimeColumnId != null ||
        widget.model.draggingColumnIndex != null ||
        widget.model.columnBandLayouts.scrollable.isEmpty) {
      return false;
    }

    final filterRowHeight = widget.model.headerFilterRowHeight;
    if (filterRowHeight > 0 &&
        localPosition.dy >= widget.height - filterRowHeight) {
      return false;
    }

    return !_isOverColumnResizeHandle(localPosition.dx);
  }

  bool _isOverColumnResizeHandle(double localX) {
    final layout = widget.model.columnBandLayouts.scrollable;
    final contentX =
        localX + widget.model.scrollCoordinator.liveHorizontalOffset;
    const handleWidth = fdcGridColumnResizeHandleWidth;
    var rightEdge = 0.0;

    for (var i = 0; i < layout.length; i++) {
      rightEdge += layout.columnWidthAt(
        i,
        fallbackWidth: widget.model.defaultColumnWidth,
      );
      final column = layout.columns[i];
      if (!widget.model.options.allowColumnResize || !column.allowResize) {
        continue;
      }
      if (contentX >= rightEdge - handleWidth && contentX <= rightEdge) {
        return true;
      }
    }

    return false;
  }

  void _endDrag() {
    if (_dragging) {
      widget.callbacks.onHeaderHorizontalDragEnd();
    }
    _resetPointerState();
  }

  void _resetPointerState() {
    _pointer = null;
    _lastLocalPosition = null;
    _pendingDeltaX = 0.0;
    _dragging = false;
  }
}

class FdcGridScrollableHeaderRegion extends StatefulWidget {
  const FdcGridScrollableHeaderRegion({
    super.key,
    required this.model,
    required this.callbacks,
    required this.height,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;
  final double height;

  @override
  State<FdcGridScrollableHeaderRegion> createState() =>
      _FdcGridScrollableHeaderRegionState();
}

class _FdcGridScrollableHeaderRegionState
    extends State<FdcGridScrollableHeaderRegion> {
  FdcGridVisibleColumnWindow? _columnWindow;
  FdcGridColumnBandLayout _effectiveColumnLayout =
      FdcGridColumnBandLayout.empty;
  double _viewportWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _attachHorizontalListeners();
  }

  @override
  void didUpdateWidget(FdcGridScrollableHeaderRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.scrollCoordinator != widget.model.scrollCoordinator) {
      _detachHorizontalListeners(oldWidget.model.scrollCoordinator);
      _attachHorizontalListeners();
    }
    _columnWindow = null;
  }

  @override
  void dispose() {
    _detachHorizontalListeners(widget.model.scrollCoordinator);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextEffectiveLayout = widget.model.columnBandLayouts.scrollable;

    return LayoutBuilder(
      builder: (context, _) {
        final nextViewportWidth = widget.model.centerViewportWidth;
        if ((_viewportWidth - nextViewportWidth).abs() >= 0.5) {
          _columnWindow = null;
        }
        _viewportWidth = nextViewportWidth;
        if (_effectiveColumnLayout.width != nextEffectiveLayout.width ||
            _effectiveColumnLayout.columnSignature !=
                nextEffectiveLayout.columnSignature ||
            !listEquals(
              _effectiveColumnLayout.columnWidths,
              nextEffectiveLayout.columnWidths,
            )) {
          _effectiveColumnLayout = nextEffectiveLayout;
          _columnWindow = null;
        }
        final contentWidth = _effectiveColumnLayout.width;
        // The shell runtime resolved this center projection once for the
        // current layout pass. Header virtualization only selects a visible
        // subrange from that shared immutable layout.
        final columnWindow = _resolveColumnWindow();
        _columnWindow = columnWindow;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: contentWidth,
            maxWidth: contentWidth,
            minHeight: widget.height,
            maxHeight: widget.height,
            child: AnimatedBuilder(
              // The center header is not a Scrollable. It is a full-width column
              // band laid out in absolute band coordinates and clipped by the
              // center viewport. Keep the overflow layout outside the transform
              // so the transform's render object has the full content width.
              animation: Listenable.merge([
                widget.model.scrollCoordinator.horizontalOffset,
                widget.model.scrollCoordinator.horizontalResizeTick,
                widget.model.scrollCoordinator.verticalOffset,
              ]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-_effectiveHorizontalOffset, 0),
                  child: child,
                );
              },
              child: SizedBox(
                width: contentWidth,
                height: widget.height,
                child: widget.callbacks.buildHeader(
                  context,
                  columnWindow.layout,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _attachHorizontalListeners() {
    widget.model.scrollCoordinator.horizontalOffset.addListener(
      _handleHorizontalWindowChanged,
    );
    widget.model.scrollCoordinator.horizontalResizeTick.addListener(
      _handleHorizontalWindowChanged,
    );
  }

  void _detachHorizontalListeners(FdcGridScrollCoordinator coordinator) {
    coordinator.horizontalOffset.removeListener(_handleHorizontalWindowChanged);
    coordinator.horizontalResizeTick.removeListener(
      _handleHorizontalWindowChanged,
    );
  }

  void _handleHorizontalWindowChanged() {
    if (_viewportWidth <= 0) {
      return;
    }
    final nextWindow = _resolveColumnWindow();
    _applyColumnWindow(nextWindow);
  }

  void _applyColumnWindow(FdcGridVisibleColumnWindow nextWindow) {
    final currentWindow = _columnWindow;
    if (currentWindow != null && currentWindow.sameRangeAs(nextWindow)) {
      _columnWindow = nextWindow;
      return;
    }

    if (_isUnsafeFramePhase) {
      // Horizontal metric notifications can be dispatched while Flutter is
      // still laying out the grid viewport. Calling setState from that path
      // triggers "Build scheduled during frame" assertions. Do not schedule a
      // post-frame rebuild either: tests using pumpAndSettle can wait forever if
      // scroll metrics keep producing frame callbacks. Cache the new window and
      // let the current/natural next build consume it.
      _columnWindow = nextWindow;
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _columnWindow = nextWindow;
    });
  }

  bool get _isUnsafeFramePhase {
    final phase = SchedulerBinding.instance.schedulerPhase;
    return phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks ||
        phase == SchedulerPhase.persistentCallbacks;
  }

  double get _effectiveHorizontalOffset {
    final layout = _effectiveColumnLayout.isNotEmpty
        ? _effectiveColumnLayout
        : widget.model.columnBandLayouts.scrollable;
    final maxOffset = math.max(0.0, layout.width - _viewportWidth);
    return widget.model.scrollCoordinator.liveHorizontalOffset
        .clamp(0.0, maxOffset)
        .toDouble();
  }

  FdcGridVisibleColumnWindow _resolveColumnWindow() {
    return resolveFdcGridVisibleColumnWindow(
      _effectiveColumnLayout.isNotEmpty
          ? _effectiveColumnLayout
          : widget.model.columnBandLayouts.scrollable,
      horizontalOffset: _effectiveHorizontalOffset,
      viewportWidth: _viewportWidth,
    );
  }
}

class FdcGridPinnedBoundary {
  const FdcGridPinnedBoundary._();

  static Color color(Color baseColor, {required bool active}) {
    if (!active) {
      return baseColor;
    }
    return Color.lerp(baseColor, Colors.black, 0.18) ?? baseColor;
  }
}

class FdcGridPinnedHeaderRegion extends StatelessWidget {
  const FdcGridPinnedHeaderRegion({
    super.key,
    required this.model,
    required this.callbacks,
    required this.columnLayout,
    required this.height,
    this.showLeadingBoundary = false,
    this.showTrailingBoundary = false,
    this.enableLeadingResizeHandle = false,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;
  final FdcGridColumnBandLayout columnLayout;
  final double height;
  final bool showLeadingBoundary;
  final bool showTrailingBoundary;
  final bool enableLeadingResizeHandle;

  bool get _leadingBoundaryActive {
    return showLeadingBoundary &&
        columnLayout.isNotEmpty &&
        model.resizingRuntimeColumnId == columnLayout.runtimeColumnIdAt(0) &&
        (model.resizingDeltaFactor ?? -1) < 0;
  }

  bool get _trailingBoundaryActive {
    return showTrailingBoundary &&
        columnLayout.isNotEmpty &&
        model.resizingRuntimeColumnId ==
            columnLayout.runtimeColumnIdAt(columnLayout.length - 1) &&
        (model.resizingDeltaFactor ?? 1) > 0;
  }

  @override
  Widget build(BuildContext context) {
    final leadingBoundaryColor = FdcGridPinnedBoundary.color(
      model.pinnedSeparatorColor,
      active: _leadingBoundaryActive,
    );
    final trailingBoundaryColor = FdcGridPinnedBoundary.color(
      model.pinnedSeparatorColor,
      active: _trailingBoundaryActive,
    );
    final boundaryInset = model.pinnedSeparatorInset;

    return SizedBox(
      width: columnLayout.width,
      height: height,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topLeft,
                heightFactor: 1,
                child: callbacks.buildHeader(context, columnLayout),
              ),
            ),
            if (showLeadingBoundary)
              Positioned(
                left: 0,
                top: boundaryInset,
                bottom: boundaryInset,
                width: 1,
                child: IgnorePointer(
                  child: ColoredBox(color: leadingBoundaryColor),
                ),
              ),
            if (showTrailingBoundary)
              Positioned(
                right: 0,
                top: boundaryInset,
                bottom: boundaryInset,
                width: 1,
                child: IgnorePointer(
                  child: ColoredBox(color: trailingBoundaryColor),
                ),
              ),
            if (enableLeadingResizeHandle)
              FdcGridRightPinnedLeadingResizeHandle(
                model: model,
                callbacks: callbacks,
                columnLayout: columnLayout,
              ),
          ],
        ),
      ),
    );
  }
}

class FdcGridRightPinnedLeadingResizeHandle extends StatelessWidget {
  const FdcGridRightPinnedLeadingResizeHandle({
    super.key,
    required this.model,
    required this.callbacks,
    required this.columnLayout,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;
  final FdcGridColumnBandLayout columnLayout;

  @override
  Widget build(BuildContext context) {
    if (!model.options.allowColumnResize || columnLayout.isEmpty) {
      return const SizedBox.shrink();
    }

    final column = columnLayout.columnAt(0);
    final columnIndex = columnLayout.columnIndexAt(0);
    final runtimeColumnId = columnLayout.runtimeColumnIdAt(0);
    if (column?.allowResize != true || runtimeColumnId == null) {
      return const SizedBox.shrink();
    }

    final resizing = model.resizingRuntimeColumnId == runtimeColumnId;
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      width: resizing
          ? fdcGridColumnResizeHandleWidth * 2
          : fdcGridColumnResizeHandleWidth,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) => callbacks.onColumnResizeStart(
            columnIndex,
            runtimeColumnId,
            details.globalPosition.dx,
            -1,
          ),
          onHorizontalDragUpdate: (details) {
            callbacks.onColumnResizeUpdate(
              columnIndex,
              runtimeColumnId,
              details.globalPosition.dx,
              -1,
            );
          },
          onHorizontalDragEnd: (_) =>
              callbacks.onColumnResizeEnd(columnIndex, runtimeColumnId),
          onHorizontalDragCancel: () =>
              callbacks.onColumnResizeEnd(columnIndex, runtimeColumnId),
        ),
      ),
    );
  }
}

class FdcGridBodyRow extends StatelessWidget {
  const FdcGridBodyRow({
    super.key,
    required this.model,
    required this.callbacks,
    required this.height,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;
  final double height;

  @override
  Widget build(BuildContext context) {
    final rowIndicatorRegionLayout = model.layoutRegions.rowIndicatorLayout;
    final pinnedLeftLayout = model.columnBandLayouts.pinnedLeft;
    final pinnedRightLayout = model.columnBandLayouts.pinnedRight;

    return KeyedSubtree(
      key: model.bodyKey,
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rowIndicatorRegionLayout != null)
                  FdcGridRowIndicatorBodyRegion(
                    model: model,
                    callbacks: callbacks,
                    layout: rowIndicatorRegionLayout,
                    height: height,
                  ),
                if (pinnedLeftLayout.isNotEmpty)
                  FdcGridPinnedColumnBodyRegion(
                    model: model,
                    callbacks: callbacks,
                    columnLayout: pinnedLeftLayout,
                    height: height,
                    showTrailingBoundary: model.showVerticalGridLines,
                  ),
                Expanded(
                  child: model.centerViewportWidth <= 0.5
                      ? const SizedBox.shrink()
                      : FdcGridScrollableBodyRegion(
                          model: model,
                          callbacks: callbacks,
                          height: height,
                        ),
                ),
                if (pinnedRightLayout.isNotEmpty)
                  FdcGridPinnedColumnBodyRegion(
                    model: model,
                    callbacks: callbacks,
                    columnLayout: pinnedRightLayout,
                    height: height,
                    showLeadingBoundary: model.showVerticalGridLines,
                  ),
              ],
            ),
          ),
          if (model.hasDetailRows)
            Positioned.fill(
              child: _FdcGridDetailRowsOverlay(
                model: model,
                callbacks: callbacks,
              ),
            ),
          Positioned.fill(child: _FdcGridRangeSelectionOverlay(model: model)),
        ],
      ),
    );
  }
}

class _FdcGridRangeSelectionOverlay extends StatelessWidget {
  const _FdcGridRangeSelectionOverlay({required this.model});

  final FdcGridViewportModel model;

  @override
  Widget build(BuildContext context) {
    final bounds = model.selectedRangeBounds;
    final style = model.rangeOutlineStyle;
    final color = style?.color;
    final thickness = style?.thickness ?? 0.0;
    final overlayBuilder = model.rangeSelectionOverlayBuilder;
    if (bounds == null ||
        color == null ||
        thickness <= 0 ||
        overlayBuilder == null) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = constraints.hasBoundedWidth
              ? math.max(0.0, constraints.maxWidth)
              : model.paintedGridWidth;
          final viewportHeight = constraints.hasBoundedHeight
              ? math.max(0.0, constraints.maxHeight)
              : model.visibleRowsHeight;
          final vertical = model.resolveVerticalLayout();
          final rowIndicatorWidth = model.layoutRegions.rowIndicatorWidth;
          final pinnedLeft = model.columnBandLayouts.pinnedLeft;
          final scrollable = model.columnBandLayouts.scrollable;
          final pinnedRight = model.columnBandLayouts.pinnedRight;
          final leadingWidth = rowIndicatorWidth + pinnedLeft.width;
          final rightOrigin = math.max(
            leadingWidth,
            viewportWidth - pinnedRight.width,
          );
          final centerWidth = math.max(0.0, rightOrigin - leadingWidth);

          List<FdcGridRangeSelectionOverlayColumnGeometry> mapGeometries(
            FdcGridColumnBandLayout layout,
          ) {
            return layout.geometries
                .map(
                  (geometry) => FdcGridRangeSelectionOverlayColumnGeometry(
                    sourceColumnIndex: geometry.sourceColumnIndex,
                    offset: geometry.offset,
                    width: geometry.width,
                  ),
                )
                .toList(growable: false);
          }

          final overlayContext = FdcGridRangeSelectionOverlayContext(
            bounds: bounds,
            viewportWidth: viewportWidth,
            viewportHeight: viewportHeight,
            rowHeight: model.rowHeight,
            verticalScrollOffset: vertical.scrollOffset,
            rowTopAt: model.rowTopAt,
            bands: [
              FdcGridRangeSelectionOverlayBand(
                name: 'pinned-left',
                geometries: mapGeometries(pinnedLeft),
                origin: rowIndicatorWidth,
                clipWidth: pinnedLeft.width,
                scrollOffset: 0,
              ),
              FdcGridRangeSelectionOverlayBand(
                name: 'scrollable',
                geometries: mapGeometries(scrollable),
                origin: leadingWidth,
                clipWidth: centerWidth,
                scrollOffset: model.scrollCoordinator.liveHorizontalOffset,
              ),
              FdcGridRangeSelectionOverlayBand(
                name: 'pinned-right',
                geometries: mapGeometries(pinnedRight),
                origin: rightOrigin,
                clipWidth: pinnedRight.width,
                scrollOffset: 0,
              ),
            ],
            borderColor: color,
            backgroundColor: model.rangeBackgroundColor,
            borderThickness: thickness,
          );
          return overlayBuilder(context, overlayContext);
        },
      ),
    );
  }
}

class FdcGridScrollableBodyRegion extends StatelessWidget {
  const FdcGridScrollableBodyRegion({
    super.key,
    required this.model,
    required this.callbacks,
    required this.height,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scrollableLayout = model.columnBandLayouts.scrollable;

    return LayoutBuilder(
      builder: (context, _) {
        final columns = scrollableLayout.columns;
        return FdcGridOptionalScrollbar(
          visible: model.options.showHorizontalScrollbar,
          controller: model.horizontalScrollController,
          notificationPredicate: (notification) {
            return notification.depth == 0 &&
                notification.metrics.axis == Axis.horizontal;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // Only the grid-level horizontal SingleChildScrollView owns this
              // coordinator offset. Descendant controls, most notably the
              // in-place TextField/EditableText, also emit horizontal scroll
              // notifications while keeping their own caret visible. Treating
              // those nested notifications as grid scroll makes the whole
              // center band drift left as text overflows a narrow cell.
              if (notification.depth != 0) {
                return false;
              }
              if (notification is ScrollUpdateNotification &&
                  callbacks.onColumnScrollUpdate(notification)) {
                return true;
              }
              model.scrollCoordinator.updateMetrics(notification.metrics);
              if (notification is ScrollEndNotification) {
                return callbacks.onColumnScrollEnd(notification);
              }
              return false;
            },
            child: SingleChildScrollView(
              controller: model.horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: CustomPaint(
                foregroundPainter: model.showVerticalGridLines
                    ? VerticalGridLinePainter(
                        columns: columns,
                        defaultColumnWidth: model.defaultColumnWidth,
                        columnWidths: scrollableLayout.columnWidths,
                        runtimeColumnIds: scrollableLayout.runtimeColumnIds,
                        activeResizeRuntimeColumnId:
                            model.resizingRuntimeColumnId,
                        activeResizeDeltaFactor: model.resizingDeltaFactor,
                        suppressTrailingSeparator:
                            scrollableLayout.stretchesLastColumn ||
                            model.columnBandLayouts.pinnedRight.isNotEmpty,
                        topInset: 0,
                        headerHeight: 0,
                        visibleRowsHeight: height,
                        rowHeight: model.rowHeight,
                        rowCount: model.rowsLength,
                        contentHeightOverride: model.contentHeight,
                        verticalLines: model.verticalLineExtent,
                        color: model.verticalGridLineColor,
                        scrollCoordinator: model.scrollCoordinator,
                      )
                    : null,
                child: SizedBox(
                  width: scrollableLayout.width,
                  height: height,
                  child: ClipRect(
                    child: CustomPaint(
                      foregroundPainter: model.showHorizontalGridLines
                          ? model.hasDetailRows
                                ? _FdcVariableHorizontalGridLinePainter(
                                    model: model,
                                    lineWidth: scrollableLayout.width,
                                  )
                                : HorizontalGridLinePainter(
                                    rowHeight: model.rowHeight,
                                    rowCount: model.rowsLength,
                                    color: model.horizontalGridLineColor,
                                    scrollCoordinator: model.scrollCoordinator,
                                    lineWidth: scrollableLayout.width,
                                  )
                          : null,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.depth != 0) {
                            return false;
                          }
                          if (notification is ScrollStartNotification) {
                            model.scrollCoordinator.updateMetrics(
                              notification.metrics,
                            );
                            return callbacks.onRowScrollStart(notification);
                          }
                          if (notification is ScrollUpdateNotification &&
                              callbacks.onRowScrollUpdate(notification)) {
                            return true;
                          }
                          model.scrollCoordinator.updateMetrics(
                            notification.metrics,
                          );
                          if (notification is ScrollEndNotification) {
                            return callbacks.onRowScrollEnd(notification);
                          }
                          return false;
                        },
                        child: _FdcVirtualBodyRows(
                          model: model,
                          callbacks: callbacks,
                          columnLayout: scrollableLayout,
                          viewportWidth: model.centerViewportWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FdcVirtualBodyRows extends StatefulWidget {
  const _FdcVirtualBodyRows({
    required this.model,
    required this.callbacks,
    required this.columnLayout,
    required this.viewportWidth,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;
  final FdcGridColumnBandLayout columnLayout;
  final double viewportWidth;

  @override
  State<_FdcVirtualBodyRows> createState() => _FdcVirtualBodyRowsState();
}

class _FdcVirtualBodyRowsState extends State<_FdcVirtualBodyRows> {
  FdcGridVisibleColumnWindow? _columnWindow;

  @override
  void initState() {
    super.initState();
    _attachHorizontalListeners();
    _columnWindow = _resolveColumnWindow();
  }

  @override
  void didUpdateWidget(_FdcVirtualBodyRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.scrollCoordinator != widget.model.scrollCoordinator) {
      _detachHorizontalListeners(oldWidget.model.scrollCoordinator);
      _attachHorizontalListeners();
    }
    _columnWindow = _resolveColumnWindow();
  }

  @override
  void dispose() {
    _detachHorizontalListeners(widget.model.scrollCoordinator);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columnWindow = _columnWindow ??= _resolveColumnWindow();
    final controller = widget.model.verticalScrollController;

    return ListView.builder(
      controller: controller,
      // Keep row extents index-addressable. Without an extent provider,
      // Flutter must progressively lay out intermediate children when jumping
      // to a distant row. That became especially expensive after detail rows
      // introduced variable heights and could stall the Windows UI thread.
      itemExtentBuilder: (rowIndex, _) => widget.model.rowExtentAt(rowIndex),
      // The grid owns the complete body viewport. ListView must not inherit
      // MediaQuery padding because that creates artificial leading/trailing
      // scroll space and, most visibly, a gap below the last row.
      padding: EdgeInsets.zero,
      itemCount: widget.model.rowsLength,
      itemBuilder: (context, rowIndex) {
        return SizedBox(
          height: widget.model.rowExtentAt(rowIndex),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: widget.model.rowHeight,
              child: widget.callbacks.buildRow(
                context,
                columnWindow.layout,
                rowIndex,
                widget.model.valueFormatter,
              ),
            ),
          ),
        );
      },
    );
  }

  void _attachHorizontalListeners() {
    widget.model.scrollCoordinator.horizontalOffset.addListener(
      _handleHorizontalWindowChanged,
    );
    widget.model.scrollCoordinator.horizontalResizeTick.addListener(
      _handleHorizontalWindowChanged,
    );
  }

  void _detachHorizontalListeners(FdcGridScrollCoordinator coordinator) {
    coordinator.horizontalOffset.removeListener(_handleHorizontalWindowChanged);
    coordinator.horizontalResizeTick.removeListener(
      _handleHorizontalWindowChanged,
    );
  }

  void _handleHorizontalWindowChanged() {
    final nextWindow = _resolveColumnWindow();
    _applyColumnWindow(nextWindow);
  }

  void _applyColumnWindow(FdcGridVisibleColumnWindow nextWindow) {
    final currentWindow = _columnWindow;
    if (currentWindow != null && currentWindow.sameRangeAs(nextWindow)) {
      _columnWindow = nextWindow;
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _columnWindow = nextWindow;
    });
  }

  FdcGridVisibleColumnWindow _resolveColumnWindow() {
    return resolveFdcGridVisibleColumnWindow(
      widget.columnLayout,
      horizontalOffset: widget.model.scrollCoordinator.liveHorizontalOffset,
      viewportWidth: widget.viewportWidth,
    );
  }
}

class _FdcVariableHorizontalGridLinePainter extends CustomPainter {
  _FdcVariableHorizontalGridLinePainter({required this.model, this.lineWidth})
    : super(
        repaint: Listenable.merge([
          model.scrollCoordinator.verticalOffset,
          model.scrollCoordinator.verticalViewportTick,
        ]),
      );

  final FdcGridViewportModel model;
  final double? lineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (model.rowsLength <= 0 || model.rowHeight <= 0 || size.height <= 0) {
      return;
    }
    final projection = model.resolveVerticalLayout();
    final paint = Paint()
      ..color = model.horizontalGridLineColor
      ..strokeWidth = 1;
    final width = math.min(lineWidth ?? size.width, size.width);
    for (
      var rowIndex = projection.firstMountedRow;
      rowIndex < projection.lastMountedRow;
      rowIndex++
    ) {
      final rowTop = model.rowTopAt(rowIndex) - projection.scrollOffset;
      final mainBottom = rowTop + model.rowHeight;
      if (mainBottom >= 0 && mainBottom <= size.height) {
        canvas.drawLine(
          Offset(0, mainBottom - 0.5),
          Offset(width, mainBottom - 0.5),
          paint,
        );
      }
      if (model.expandedDetailRows.contains(rowIndex)) {
        final detailBottom = rowTop + model.rowExtentAt(rowIndex);
        if (detailBottom >= 0 && detailBottom <= size.height) {
          canvas.drawLine(
            Offset(0, detailBottom - 0.5),
            Offset(width, detailBottom - 0.5),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _FdcVariableHorizontalGridLinePainter oldDelegate,
  ) {
    return oldDelegate.model != model || oldDelegate.lineWidth != lineWidth;
  }
}

class _FdcGridDetailRowsOverlay extends StatelessWidget {
  const _FdcGridDetailRowsOverlay({
    required this.model,
    required this.callbacks,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        model.scrollCoordinator.horizontalOffset,
        model.scrollCoordinator.verticalOffset,
        model.scrollCoordinator.verticalViewportTick,
      ]),
      builder: (context, _) {
        final projection = model.resolveVerticalLayout();
        final rowIndicatorWidth = model.layoutRegions.rowIndicatorWidth;
        final horizontalOffset = model.scrollCoordinator.liveHorizontalOffset;
        final visibleScrollableWidth = math.min(
          model.centerViewportWidth,
          math.max(0.0, model.paintedGridWidth - horizontalOffset),
        );
        final panelWidth =
            model.layoutRegions.pinnedLeftWidth +
            visibleScrollableWidth +
            model.layoutRegions.pinnedRightWidth;
        final lastColumnEdgeVisible =
            !model.layoutRegions.hasPinnedRightRegion &&
            model.paintedGridWidth - horizontalOffset <=
                model.centerViewportWidth + 0.5;

        return Stack(
          children: [
            for (
              var rowIndex = projection.firstMountedRow;
              rowIndex < projection.lastMountedRow;
              rowIndex++
            )
              if (model.expandedDetailRows.contains(rowIndex)) ...[
                if (rowIndicatorWidth > 0)
                  Positioned(
                    left: 0,
                    width: rowIndicatorWidth,
                    top:
                        model.rowTopAt(rowIndex) +
                        model.rowHeight -
                        projection.scrollOffset,
                    height: model.detailHeightAt(rowIndex),
                    child: CustomPaint(
                      key: ValueKey<String>(
                        'fdc-grid-detail-indicator-$rowIndex',
                      ),
                      foregroundPainter: _FdcGridDetailFramePainter(
                        horizontalColor: model.horizontalGridLineColor,
                        verticalColor: model.verticalGridLineColor,
                        showBottom: model.showHorizontalGridLines,
                        showRight: model.showVerticalGridLines,
                      ),
                      child: ColoredBox(
                        color: model.rowIndicatorBackgroundColor,
                      ),
                    ),
                  ),
                Positioned(
                  left: rowIndicatorWidth,
                  width: panelWidth,
                  top:
                      model.rowTopAt(rowIndex) +
                      model.rowHeight -
                      projection.scrollOffset,
                  // Content-sized detail rows are measured while hidden. Once
                  // visible, both the panel and detached indicator must use the
                  // exact same committed extent. Leaving the visible panel
                  // unconstrained lets a nested scrollable temporarily paint at
                  // its own height during rebuilds, while the indicator still
                  // uses the cached extent.
                  height:
                      model.detailRowContentSized &&
                          !model.visibleDetailRows.contains(rowIndex)
                      ? null
                      : model.detailHeightAt(rowIndex),
                  child: _FdcGridSizeObserver(
                    onSizeChanged: (size) =>
                        callbacks.onDetailRowSizeChanged(rowIndex, size),
                    child: ClipRect(
                      child: Opacity(
                        opacity: model.visibleDetailRows.contains(rowIndex)
                            ? 1
                            : 0,
                        child: CustomPaint(
                          key: ValueKey<String>(
                            'fdc-grid-detail-panel-$rowIndex',
                          ),
                          foregroundPainter: _FdcGridDetailFramePainter(
                            horizontalColor: model.horizontalGridLineColor,
                            verticalColor: model.verticalGridLineColor,
                            showBottom: model.showHorizontalGridLines,
                            showRight:
                                model.showVerticalGridLines &&
                                lastColumnEdgeVisible,
                          ),
                          child: ColoredBox(
                            color: model.backgroundColor,
                            child: callbacks.buildDetailRow(context, rowIndex),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
          ],
        );
      },
    );
  }
}

class _FdcGridDetailFramePainter extends CustomPainter {
  const _FdcGridDetailFramePainter({
    required this.horizontalColor,
    required this.verticalColor,
    required this.showBottom,
    required this.showRight,
  });

  final Color horizontalColor;
  final Color verticalColor;
  final bool showBottom;
  final bool showRight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final horizontalPaint = Paint()
      ..color = horizontalColor
      ..strokeWidth = 1;
    final verticalPaint = Paint()
      ..color = verticalColor
      ..strokeWidth = 1;
    final right = math.max(0.5, size.width - 0.5);
    final bottom = math.max(0.5, size.height - 0.5);

    if (showBottom) {
      canvas.drawLine(
        Offset(0, bottom),
        Offset(size.width, bottom),
        horizontalPaint,
      );
    }
    if (showRight) {
      canvas.drawLine(
        Offset(right, 0),
        Offset(right, size.height),
        verticalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FdcGridDetailFramePainter oldDelegate) {
    return oldDelegate.horizontalColor != horizontalColor ||
        oldDelegate.verticalColor != verticalColor ||
        oldDelegate.showBottom != showBottom ||
        oldDelegate.showRight != showRight;
  }
}

/// Body-only input surface for pinned and row-indicator regions.
///
/// This widget intentionally does not create a Scrollable. It forwards touch
/// drag input to the central scroll coordinator through viewport callbacks.
class FdcGridBodyScrollInputRegion extends StatelessWidget {
  const FdcGridBodyScrollInputRegion({
    super.key,
    required this.callbacks,
    required this.child,
    this.dragScrollEnabled = true,
  });

  final FdcGridViewportCallbacks callbacks;
  final Widget child;
  final bool dragScrollEnabled;

  @override
  Widget build(BuildContext context) {
    if (!dragScrollEnabled) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      dragStartBehavior: DragStartBehavior.down,
      onVerticalDragStart: (_) => callbacks.onBodyVerticalDragStart(),
      onVerticalDragUpdate: callbacks.onBodyVerticalDragUpdate,
      onVerticalDragEnd: callbacks.onBodyVerticalDragEnd,
      onVerticalDragCancel: () => callbacks.onBodyVerticalDragEnd(null),
      child: child,
    );
  }
}

class FdcGridPinnedColumnBodyRegion extends StatelessWidget {
  const FdcGridPinnedColumnBodyRegion({
    super.key,
    required this.model,
    required this.callbacks,
    required this.columnLayout,
    required this.height,
    this.showLeadingBoundary = false,
    this.showTrailingBoundary = false,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;
  final FdcGridColumnBandLayout columnLayout;
  final double height;
  final bool showLeadingBoundary;
  final bool showTrailingBoundary;

  bool get _leadingBoundaryActive {
    return showLeadingBoundary &&
        columnLayout.isNotEmpty &&
        model.resizingRuntimeColumnId == columnLayout.runtimeColumnIdAt(0) &&
        (model.resizingDeltaFactor ?? -1) < 0;
  }

  bool get _trailingBoundaryActive {
    return showTrailingBoundary &&
        columnLayout.isNotEmpty &&
        model.resizingRuntimeColumnId ==
            columnLayout.runtimeColumnIdAt(columnLayout.length - 1) &&
        (model.resizingDeltaFactor ?? 1) > 0;
  }

  @override
  Widget build(BuildContext context) {
    final leadingBoundaryColor = FdcGridPinnedBoundary.color(
      model.pinnedSeparatorColor,
      active: _leadingBoundaryActive,
    );
    final trailingBoundaryColor = FdcGridPinnedBoundary.color(
      model.pinnedSeparatorColor,
      active: _trailingBoundaryActive,
    );
    final boundaryInset = model.pinnedSeparatorInset;
    final showBodyBoundaries = model.rowsLength > 0;

    return SizedBox(
      width: columnLayout.width,
      height: height,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                foregroundPainter: model.showVerticalGridLines
                    ? VerticalGridLinePainter(
                        columns: columnLayout.columns,
                        ignoreHorizontalOffset: true,
                        defaultColumnWidth: model.defaultColumnWidth,
                        columnWidths: columnLayout.columnWidths,
                        runtimeColumnIds: columnLayout.runtimeColumnIds,
                        activeResizeRuntimeColumnId:
                            model.resizingRuntimeColumnId,
                        activeResizeDeltaFactor: model.resizingDeltaFactor,
                        topInset: 0,
                        headerHeight: 0,
                        visibleRowsHeight: height,
                        rowHeight: model.rowHeight,
                        rowCount: model.rowsLength,
                        contentHeightOverride: model.contentHeight,
                        verticalLines: model.verticalLineExtent,
                        color: model.verticalGridLineColor,
                        scrollCoordinator: model.scrollCoordinator,
                      )
                    : null,
                child: CustomPaint(
                  foregroundPainter: model.showHorizontalGridLines
                      ? model.hasDetailRows
                            ? _FdcVariableHorizontalGridLinePainter(
                                model: model,
                              )
                            : HorizontalGridLinePainter(
                                rowHeight: model.rowHeight,
                                rowCount: model.rowsLength,
                                color: model.horizontalGridLineColor,
                                scrollCoordinator: model.scrollCoordinator,
                              )
                      : null,
                  child: FdcGridBodyScrollInputRegion(
                    callbacks: callbacks,
                    dragScrollEnabled: !model.hasActiveCellEditor,
                    child: FdcGridPinnedColumnRegionRows(
                      model: model,
                      callbacks: callbacks,
                      columnLayout: columnLayout,
                    ),
                  ),
                ),
              ),
            ),
            if (showBodyBoundaries &&
                (showLeadingBoundary || showTrailingBoundary))
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    foregroundPainter: _FdcGridPinnedBodyBoundaryPainter(
                      showLeadingBoundary: showLeadingBoundary,
                      showTrailingBoundary: showTrailingBoundary,
                      leadingColor: leadingBoundaryColor,
                      trailingColor: trailingBoundaryColor,
                      inset: boundaryInset,
                      rowHeight: model.rowHeight,
                      rowCount: model.rowsLength,
                      scrollCoordinator: model.scrollCoordinator,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FdcGridPinnedBodyBoundaryPainter extends CustomPainter {
  _FdcGridPinnedBodyBoundaryPainter({
    required this.showLeadingBoundary,
    required this.showTrailingBoundary,
    required this.leadingColor,
    required this.trailingColor,
    required this.inset,
    required this.rowHeight,
    required this.rowCount,
    required this.scrollCoordinator,
  }) : super(
         repaint: Listenable.merge([
           scrollCoordinator.verticalOffset,
           scrollCoordinator.verticalViewportTick,
         ]),
       );

  final bool showLeadingBoundary;
  final bool showTrailingBoundary;
  final Color leadingColor;
  final Color trailingColor;
  final double inset;
  final double rowHeight;
  final int rowCount;
  final FdcGridScrollCoordinator scrollCoordinator;

  @override
  void paint(Canvas canvas, Size size) {
    if (rowHeight <= 0 || rowCount <= 0 || size.height <= 0) {
      return;
    }

    final contentHeight = rowHeight * rowCount;
    final scrollOffset = scrollCoordinator.liveVerticalOffset;
    final visibleRowsHeight = (contentHeight - scrollOffset).clamp(
      0.0,
      size.height,
    );
    final top = inset.clamp(0.0, visibleRowsHeight).toDouble();
    final bottom = (visibleRowsHeight - inset)
        .clamp(top, size.height)
        .toDouble();
    if (bottom <= top) {
      return;
    }

    final paint = Paint()..strokeWidth = 1;
    final pixelOffset = paint.strokeWidth / 2;
    if (showLeadingBoundary) {
      paint.color = leadingColor;
      canvas.drawLine(
        Offset(pixelOffset, top),
        Offset(pixelOffset, bottom),
        paint,
      );
    }
    if (showTrailingBoundary) {
      paint.color = trailingColor;
      final x = size.width - pixelOffset;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FdcGridPinnedBodyBoundaryPainter oldDelegate) {
    return oldDelegate.showLeadingBoundary != showLeadingBoundary ||
        oldDelegate.showTrailingBoundary != showTrailingBoundary ||
        oldDelegate.leadingColor != leadingColor ||
        oldDelegate.trailingColor != trailingColor ||
        oldDelegate.inset != inset ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.rowCount != rowCount ||
        oldDelegate.scrollCoordinator != scrollCoordinator;
  }

  @override
  bool shouldRebuildSemantics(
    covariant _FdcGridPinnedBodyBoundaryPainter oldDelegate,
  ) {
    return false;
  }
}

class FdcGridPinnedColumnRegionRows extends StatelessWidget {
  const FdcGridPinnedColumnRegionRows({
    super.key,
    required this.model,
    required this.callbacks,
    required this.columnLayout,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;
  final FdcGridColumnBandLayout columnLayout;

  @override
  Widget build(BuildContext context) {
    return _FdcGridDetachedVerticalRows(
      model: model,
      rowBuilder: (context, rowIndex) {
        return callbacks.buildRow(
          context,
          columnLayout,
          rowIndex,
          model.valueFormatter,
        );
      },
    );
  }
}

class FdcGridRowIndicatorBodyRegion extends StatelessWidget {
  const FdcGridRowIndicatorBodyRegion({
    super.key,
    required this.model,
    required this.callbacks,
    required this.layout,
    required this.height,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;
  final FdcGridRowIndicatorLayout layout;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: model.showVerticalGridLines
          ? VerticalGridLinePainter(
              columns: const [],
              columnCount: 1,
              ignoreHorizontalOffset: true,
              defaultColumnWidth: model.defaultColumnWidth,
              columnWidths: [layout.width],
              topInset: 0,
              headerHeight: 0,
              visibleRowsHeight: height,
              rowHeight: model.rowHeight,
              rowCount: model.rowsLength,
              contentHeightOverride: model.contentHeight,
              verticalLines: model.verticalLineExtent,
              color: model.verticalGridLineColor,
              scrollCoordinator: model.scrollCoordinator,
            )
          : null,
      child: SizedBox(
        width: layout.width,
        height: height,
        child: ClipRect(
          child: CustomPaint(
            foregroundPainter: model.showHorizontalGridLines
                ? model.hasDetailRows
                      ? _FdcVariableHorizontalGridLinePainter(model: model)
                      : HorizontalGridLinePainter(
                          rowHeight: model.rowHeight,
                          rowCount: model.rowsLength,
                          color: model.horizontalGridLineColor,
                          scrollCoordinator: model.scrollCoordinator,
                        )
                : null,
            child: FdcGridBodyScrollInputRegion(
              callbacks: callbacks,
              dragScrollEnabled: !model.hasActiveCellEditor,
              child: FdcGridRowIndicatorRegionRows(
                model: model,
                callbacks: callbacks,
                width: layout.width,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FdcGridRowIndicatorRegionRows extends StatelessWidget {
  const FdcGridRowIndicatorRegionRows({
    super.key,
    required this.model,
    required this.callbacks,
    required this.width,
  });

  final FdcGridViewportModel model;
  final FdcGridViewportCallbacks callbacks;
  final double width;

  @override
  Widget build(BuildContext context) {
    return _FdcGridDetachedVerticalRows(
      model: model,
      rowBuilder: (context, rowIndex) {
        return ColoredBox(
          color: model.rowIndicatorBackgroundColor,
          child: callbacks.buildRowIndicatorRegionRow(context, rowIndex, width),
        );
      },
    );
  }
}

class _FdcGridDetachedVerticalRows extends StatelessWidget {
  const _FdcGridDetachedVerticalRows({
    required this.model,
    required this.rowBuilder,
  });

  final FdcGridViewportModel model;
  final Widget Function(BuildContext context, int rowIndex) rowBuilder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        model.scrollCoordinator.verticalOffset,
        model.scrollCoordinator.verticalViewportTick,
      ]),
      builder: (context, _) {
        final projection = model.resolveVerticalLayout();

        // The parent body band receives the new shell height before Flutter's
        // central ListView has committed its updated viewport metrics. Keep the
        // detached projection clipped to the last ListView-confirmed viewport
        // height so overscan rows cannot be revealed one frame ahead of the
        // center. The confirmed height advances from ScrollPosition metrics.
        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: double.infinity,
            height: projection.viewportHeight,
            child: Stack(
              children: [
                for (
                  var rowIndex = projection.firstMountedRow;
                  rowIndex < projection.lastMountedRow;
                  rowIndex++
                )
                  Positioned(
                    left: 0,
                    right: 0,
                    top: model.rowTopAt(rowIndex) - projection.scrollOffset,
                    height: model.rowHeight,
                    child: rowBuilder(context, rowIndex),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
