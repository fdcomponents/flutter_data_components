// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/fdc_app.dart';
import '../../common/menu/fdc_menu.dart';
import '../../common/theme/fdc_grid_styles.dart';
import '../../data/fdc_data.dart';
import '../../i18n/fdc_translations.dart';
import '../columns/fdc_grid_columns.dart';
import '../core/fdc_grid_runtime_constants.dart';
import '../managers/fdc_grid_scroll_coordinator.dart';
import '../models/fdc_grid_internal_models.dart';
import 'fdc_grid_header_metrics.dart';
import 'fdc_grid_separators.dart';
import 'fdc_grid_visible_column_window.dart';

class FdcGridSummaryRow extends StatelessWidget {
  const FdcGridSummaryRow({
    super.key,
    required this.style,
    required this.topSeparatorColor,
    required this.height,
    required this.columnBandLayouts,
    required this.layoutRegions,
    required this.centerViewportWidth,
    required this.scrollCoordinator,
    required this.values,
    required this.aggregates,
    required this.runtimeAggregateOverrides,
    required this.showVerticalGridLines,
    required this.verticalGridLineColor,
    required this.allowColumnResize,
    required this.resizingRuntimeColumnId,
    required this.animateColumnReorder,
    required this.onColumnResizeStart,
    required this.onColumnResizeUpdate,
    required this.onColumnResizeEnd,
    required this.onPointerSignal,
    required this.onHorizontalDragStart,
    required this.onHorizontalDragUpdate,
    required this.onHorizontalDragEnd,
    required this.onSummaryMenuOpen,
    required this.canEditSummary,
    required this.onSummaryAggregateChanged,
  });

  final FdcGridSummaryStyle style;
  final Color topSeparatorColor;
  final double height;
  final FdcGridColumnBandLayouts columnBandLayouts;
  final FdcGridLayoutRegions layoutRegions;
  final double centerViewportWidth;
  final FdcGridScrollCoordinator scrollCoordinator;
  final Map<FdcColumnIdentity, String> values;
  final Map<FdcColumnIdentity, FdcAggregate?> aggregates;
  final Set<FdcColumnIdentity> runtimeAggregateOverrides;
  final bool showVerticalGridLines;
  final Color verticalGridLineColor;
  final bool allowColumnResize;
  final FdcColumnIdentity? resizingRuntimeColumnId;
  final bool animateColumnReorder;
  final void Function(
    int columnIndex,
    FdcColumnIdentity runtimeColumnId,
    double globalX,
    double deltaFactor,
  )
  onColumnResizeStart;
  final void Function(
    int columnIndex,
    FdcColumnIdentity runtimeColumnId,
    double globalX,
    double deltaFactor,
  )
  onColumnResizeUpdate;
  final void Function(int columnIndex, FdcColumnIdentity runtimeColumnId)
  onColumnResizeEnd;
  final void Function(PointerSignalEvent event) onPointerSignal;
  final VoidCallback onHorizontalDragStart;
  final void Function(double deltaX) onHorizontalDragUpdate;
  final VoidCallback onHorizontalDragEnd;
  final VoidCallback onSummaryMenuOpen;
  final bool canEditSummary;
  final void Function(
    FdcColumnIdentity runtimeColumnId,
    FdcAggregate? aggregate,
  )
  onSummaryAggregateChanged;

  double get _verticalSeparatorInset =>
      style.verticalSeparatorInset ??
      FdcGridSummaryStyle.defaults.verticalSeparatorInset ??
      FdcGridHeaderMetrics.verticalSeparatorInset;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = style.backgroundColor;
    final showTopSeparator = style.showTopSeparator ?? true;
    return DecoratedBox(
      key: const ValueKey('fdc_grid_summary_row'),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: showTopSeparator
              ? BorderSide(color: topSeparatorColor)
              : BorderSide.none,
        ),
      ),
      child: FdcGridSummaryPointerSignalRegion(
        onPointerSignal: onPointerSignal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (layoutRegions.hasRowIndicatorRegion)
              FdcGridSummaryTopSeparatorRegion(
                width: layoutRegions.rowIndicatorWidth,
                showTopSeparator: showTopSeparator,
                topSeparatorColor: topSeparatorColor,
              ),
            if (columnBandLayouts.pinnedLeft.isNotEmpty)
              FdcGridSummaryRowBand(
                layout: columnBandLayouts.pinnedLeft,
                values: values,
                aggregates: aggregates,
                runtimeAggregateOverrides: runtimeAggregateOverrides,
                style: style,
                showVerticalGridLines: showVerticalGridLines,
                verticalGridLineColor: verticalGridLineColor,
                allowColumnResize: allowColumnResize,
                resizingRuntimeColumnId: resizingRuntimeColumnId,
                animateColumnReorder: animateColumnReorder,
                onColumnResizeStart: onColumnResizeStart,
                onColumnResizeUpdate: onColumnResizeUpdate,
                onColumnResizeEnd: onColumnResizeEnd,
                verticalSeparatorInset: _verticalSeparatorInset,
                summaryRowHeight: height,
                showTopSeparator: showTopSeparator,
                topSeparatorColor: topSeparatorColor,
                previousColumnHasSummary: false,
                leadingResizeTargetGeometry: null,
                isRightPinnedBand: false,
                onSummaryMenuOpen: onSummaryMenuOpen,
                canEditSummary: canEditSummary,
                onSummaryAggregateChanged: onSummaryAggregateChanged,
              ),
            Expanded(
              child: _FdcSummaryScrollInputRegion(
                scrollCoordinator: scrollCoordinator,
                layout: columnBandLayouts.scrollable,
                aggregates: aggregates,
                showVerticalGridLines: showVerticalGridLines,
                allowColumnResize: allowColumnResize,
                leadingResizeTargetGeometry: _lastGeometry(
                  columnBandLayouts.pinnedLeft,
                ),
                onHorizontalDragStart: onHorizontalDragStart,
                onHorizontalDragUpdate: onHorizontalDragUpdate,
                onHorizontalDragEnd: onHorizontalDragEnd,
                child: ClipRect(
                  child: FdcGridSummaryScrollableBand(
                    viewportWidth: centerViewportWidth,
                    layout: columnBandLayouts.scrollable,
                    values: values,
                    aggregates: aggregates,
                    runtimeAggregateOverrides: runtimeAggregateOverrides,
                    style: style,
                    scrollCoordinator: scrollCoordinator,
                    showVerticalGridLines: showVerticalGridLines,
                    verticalGridLineColor: verticalGridLineColor,
                    allowColumnResize: allowColumnResize,
                    resizingRuntimeColumnId: resizingRuntimeColumnId,
                    animateColumnReorder: animateColumnReorder,
                    onColumnResizeStart: onColumnResizeStart,
                    onColumnResizeUpdate: onColumnResizeUpdate,
                    onColumnResizeEnd: onColumnResizeEnd,
                    verticalSeparatorInset: _verticalSeparatorInset,
                    summaryRowHeight: height,
                    showTopSeparator: showTopSeparator,
                    topSeparatorColor: topSeparatorColor,
                    previousColumnHasSummary: _lastColumnHasSummary(
                      columnBandLayouts.pinnedLeft,
                    ),
                    leadingResizeTargetGeometry: _lastGeometry(
                      columnBandLayouts.pinnedLeft,
                    ),
                    isRightPinnedBand: false,
                    onSummaryMenuOpen: onSummaryMenuOpen,
                    canEditSummary: canEditSummary,
                    onSummaryAggregateChanged: onSummaryAggregateChanged,
                  ),
                ),
              ),
            ),
            if (columnBandLayouts.pinnedRight.isNotEmpty)
              FdcGridSummaryRowBand(
                layout: columnBandLayouts.pinnedRight,
                values: values,
                aggregates: aggregates,
                runtimeAggregateOverrides: runtimeAggregateOverrides,
                style: style,
                showVerticalGridLines: showVerticalGridLines,
                verticalGridLineColor: verticalGridLineColor,
                allowColumnResize: allowColumnResize,
                resizingRuntimeColumnId: resizingRuntimeColumnId,
                animateColumnReorder: animateColumnReorder,
                onColumnResizeStart: onColumnResizeStart,
                onColumnResizeUpdate: onColumnResizeUpdate,
                onColumnResizeEnd: onColumnResizeEnd,
                verticalSeparatorInset: _verticalSeparatorInset,
                summaryRowHeight: height,
                showTopSeparator: showTopSeparator,
                topSeparatorColor: topSeparatorColor,
                previousColumnHasSummary:
                    columnBandLayouts.scrollable.isNotEmpty
                    ? _lastColumnHasSummary(columnBandLayouts.scrollable)
                    : _lastColumnHasSummary(columnBandLayouts.pinnedLeft),
                leadingResizeTargetGeometry:
                    _lastGeometry(columnBandLayouts.scrollable) ??
                    _lastGeometry(columnBandLayouts.pinnedLeft),
                isRightPinnedBand: true,
                onSummaryMenuOpen: onSummaryMenuOpen,
                canEditSummary: canEditSummary,
                onSummaryAggregateChanged: onSummaryAggregateChanged,
              ),
          ],
        ),
      ),
    );
  }

  bool _lastColumnHasSummary(FdcGridColumnBandLayout layout) {
    final geometry = _lastGeometry(layout);
    if (geometry == null) {
      return false;
    }
    return aggregates[geometry.runtimeColumnId] != null;
  }

  FdcGridColumnGeometry? _lastGeometry(FdcGridColumnBandLayout layout) {
    if (layout.geometries.isEmpty) {
      return null;
    }
    return layout.geometries.last;
  }
}

class FdcGridSummaryTopSeparatorRegion extends StatelessWidget {
  const FdcGridSummaryTopSeparatorRegion({
    super.key,
    required this.width,
    required this.showTopSeparator,
    required this.topSeparatorColor,
  });

  final double width;
  final bool showTopSeparator;
  final Color topSeparatorColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          if (showTopSeparator)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: FdcGridHeaderMetrics.verticalSeparatorWidth,
              child: FdcGridHorizontalSeparator(
                width: width,
                color: topSeparatorColor,
              ),
            ),
        ],
      ),
    );
  }
}

class FdcGridSummaryPointerSignalRegion extends StatelessWidget {
  const FdcGridSummaryPointerSignalRegion({
    super.key,
    required this.onPointerSignal,
    required this.child,
  });

  final void Function(PointerSignalEvent event) onPointerSignal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: onPointerSignal,
      child: child,
    );
  }
}

class _FdcSummaryScrollInputRegion extends StatefulWidget {
  const _FdcSummaryScrollInputRegion({
    required this.scrollCoordinator,
    required this.layout,
    required this.aggregates,
    required this.showVerticalGridLines,
    required this.allowColumnResize,
    required this.leadingResizeTargetGeometry,
    required this.onHorizontalDragStart,
    required this.onHorizontalDragUpdate,
    required this.onHorizontalDragEnd,
    required this.child,
  });

  final FdcGridScrollCoordinator scrollCoordinator;
  final FdcGridColumnBandLayout layout;
  final Map<FdcColumnIdentity, FdcAggregate?> aggregates;
  final bool showVerticalGridLines;
  final bool allowColumnResize;
  final FdcGridColumnGeometry? leadingResizeTargetGeometry;
  final VoidCallback onHorizontalDragStart;
  final void Function(double deltaX) onHorizontalDragUpdate;
  final VoidCallback onHorizontalDragEnd;
  final Widget child;

  @override
  State<_FdcSummaryScrollInputRegion> createState() =>
      _FdcSummaryScrollInputRegionState();
}

class _FdcSummaryScrollInputRegionState
    extends State<_FdcSummaryScrollInputRegion> {
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
    if (!_isPrimaryPointer(event) ||
        !_canStart() ||
        _isOverSummaryResizeHandle(event.localPosition.dx)) {
      return;
    }

    _pointer = event.pointer;
    _lastLocalPosition = event.localPosition;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) {
      return;
    }

    if (!_canStart()) {
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
      widget.onHorizontalDragStart();
      widget.onHorizontalDragUpdate(_pendingDeltaX);
      _pendingDeltaX = 0.0;
      return;
    }

    widget.onHorizontalDragUpdate(delta.dx);
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

  bool _isOverSummaryResizeHandle(double localX) {
    if (!widget.allowColumnResize || !widget.showVerticalGridLines) {
      return false;
    }

    final contentX = localX + widget.scrollCoordinator.liveHorizontalOffset;
    const handleWidth = fdcGridColumnResizeHandleWidth;
    for (var index = 0; index < widget.layout.geometries.length; index++) {
      final geometry = widget.layout.geometries[index];
      if (widget.aggregates[geometry.runtimeColumnId] == null) {
        continue;
      }

      final leftTarget = _leadingResizeTargetGeometryAt(index);
      if (leftTarget?.column.allowResize == true) {
        final leftEdge = geometry.offset;
        if (contentX >= leftEdge && contentX <= leftEdge + handleWidth) {
          return true;
        }
      }

      final resizeRuntimeColumnId = widget.layout.resizeTargetRuntimeColumnIdAt(
        index,
      );
      final resizeColumn = widget.layout.resizeTargetColumnAt(index);
      if (resizeRuntimeColumnId == null || resizeColumn?.allowResize != true) {
        continue;
      }
      final rightEdge = geometry.offset + geometry.width;
      if (contentX >= rightEdge - handleWidth && contentX <= rightEdge) {
        return true;
      }
    }
    return false;
  }

  FdcGridColumnGeometry? _leadingResizeTargetGeometryAt(int index) {
    if (!_startsSummarySegment(index)) {
      return null;
    }
    if (index == 0) {
      return widget.leadingResizeTargetGeometry;
    }
    return widget.layout.geometries[index - 1];
  }

  bool _startsSummarySegment(int index) {
    if (widget.aggregates[widget.layout.geometries[index].runtimeColumnId] ==
        null) {
      return false;
    }
    if (index == 0) {
      return widget.leadingResizeTargetGeometry != null &&
          widget.aggregates[widget
                  .leadingResizeTargetGeometry!
                  .runtimeColumnId] ==
              null;
    }
    return widget.aggregates[widget
            .layout
            .geometries[index - 1]
            .runtimeColumnId] ==
        null;
  }

  bool _canStart() {
    return widget.scrollCoordinator.hasHorizontalClients &&
        widget.scrollCoordinator.hasHorizontalScrollableRange;
  }

  void _endDrag() {
    if (_dragging) {
      widget.onHorizontalDragEnd();
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

class FdcGridSummaryScrollableBand extends StatefulWidget {
  const FdcGridSummaryScrollableBand({
    super.key,
    required this.viewportWidth,
    required this.layout,
    required this.values,
    required this.aggregates,
    required this.runtimeAggregateOverrides,
    required this.style,
    required this.scrollCoordinator,
    required this.showVerticalGridLines,
    required this.verticalGridLineColor,
    required this.allowColumnResize,
    required this.resizingRuntimeColumnId,
    required this.animateColumnReorder,
    required this.onColumnResizeStart,
    required this.onColumnResizeUpdate,
    required this.onColumnResizeEnd,
    required this.verticalSeparatorInset,
    required this.summaryRowHeight,
    required this.showTopSeparator,
    required this.topSeparatorColor,
    required this.previousColumnHasSummary,
    required this.leadingResizeTargetGeometry,
    required this.isRightPinnedBand,
    required this.onSummaryMenuOpen,
    required this.canEditSummary,
    required this.onSummaryAggregateChanged,
  });

  final double viewportWidth;
  final FdcGridColumnBandLayout layout;
  final Map<FdcColumnIdentity, String> values;
  final Map<FdcColumnIdentity, FdcAggregate?> aggregates;
  final Set<FdcColumnIdentity> runtimeAggregateOverrides;
  final FdcGridSummaryStyle style;
  final FdcGridScrollCoordinator scrollCoordinator;
  final bool showVerticalGridLines;
  final Color verticalGridLineColor;
  final bool allowColumnResize;
  final FdcColumnIdentity? resizingRuntimeColumnId;
  final bool animateColumnReorder;
  final void Function(
    int columnIndex,
    FdcColumnIdentity runtimeColumnId,
    double globalX,
    double deltaFactor,
  )
  onColumnResizeStart;
  final void Function(
    int columnIndex,
    FdcColumnIdentity runtimeColumnId,
    double globalX,
    double deltaFactor,
  )
  onColumnResizeUpdate;
  final void Function(int columnIndex, FdcColumnIdentity runtimeColumnId)
  onColumnResizeEnd;
  final double verticalSeparatorInset;
  final double summaryRowHeight;
  final bool showTopSeparator;
  final Color topSeparatorColor;
  final bool previousColumnHasSummary;
  final FdcGridColumnGeometry? leadingResizeTargetGeometry;
  final bool isRightPinnedBand;
  final VoidCallback onSummaryMenuOpen;
  final bool canEditSummary;
  final void Function(
    FdcColumnIdentity runtimeColumnId,
    FdcAggregate? aggregate,
  )
  onSummaryAggregateChanged;

  @override
  State<FdcGridSummaryScrollableBand> createState() =>
      _FdcGridSummaryScrollableBandState();
}

class _FdcGridSummaryScrollableBandState
    extends State<FdcGridSummaryScrollableBand> {
  FdcGridVisibleColumnWindow? _columnWindow;

  @override
  void initState() {
    super.initState();
    _attachHorizontalListeners();
    _columnWindow = _resolveColumnWindow();
  }

  @override
  void didUpdateWidget(FdcGridSummaryScrollableBand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollCoordinator != widget.scrollCoordinator) {
      _detachHorizontalListeners(oldWidget.scrollCoordinator);
      _attachHorizontalListeners();
    }
    _columnWindow = _resolveColumnWindow();
  }

  @override
  void dispose() {
    _detachHorizontalListeners(widget.scrollCoordinator);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLayout = widget.layout;
    final columnWindow = resolveFdcGridVisibleColumnWindow(
      effectiveLayout,
      horizontalOffset: widget.scrollCoordinator.liveHorizontalOffset,
      viewportWidth: widget.viewportWidth,
    );
    _columnWindow = columnWindow;
    return AnimatedBuilder(
      // During a live resize at the right edge the coordinator intentionally
      // keeps the public horizontal offset stable and publishes the visual
      // origin through horizontalResizeTick. Summary must consume the same
      // signal as header/body or its transform trails the resized geometry by
      // one frame and visibly jumps.
      animation: Listenable.merge([
        widget.scrollCoordinator.horizontalOffset,
        widget.scrollCoordinator.horizontalResizeTick,
      ]),
      builder: (context, child) {
        final maxOffset = math.max(
          0.0,
          effectiveLayout.width - widget.viewportWidth,
        );
        final offset = widget.scrollCoordinator.liveHorizontalOffset
            .clamp(0.0, maxOffset)
            .toDouble();
        return OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: effectiveLayout.width,
          maxWidth: effectiveLayout.width,
          child: Transform.translate(offset: Offset(-offset, 0), child: child),
        );
      },
      child: FdcGridSummaryRowBand(
        layout: columnWindow.layout,
        values: widget.values,
        aggregates: widget.aggregates,
        runtimeAggregateOverrides: widget.runtimeAggregateOverrides,
        style: widget.style,
        showVerticalGridLines: widget.showVerticalGridLines,
        verticalGridLineColor: widget.verticalGridLineColor,
        allowColumnResize: widget.allowColumnResize,
        resizingRuntimeColumnId: widget.resizingRuntimeColumnId,
        animateColumnReorder: widget.animateColumnReorder,
        onColumnResizeStart: widget.onColumnResizeStart,
        onColumnResizeUpdate: widget.onColumnResizeUpdate,
        onColumnResizeEnd: widget.onColumnResizeEnd,
        verticalSeparatorInset: widget.verticalSeparatorInset,
        summaryRowHeight: widget.summaryRowHeight,
        showTopSeparator: widget.showTopSeparator,
        topSeparatorColor: widget.topSeparatorColor,
        previousColumnHasSummary: widget.previousColumnHasSummary,
        leadingResizeTargetGeometry: widget.leadingResizeTargetGeometry,
        isRightPinnedBand: widget.isRightPinnedBand,
        onSummaryMenuOpen: widget.onSummaryMenuOpen,
        canEditSummary: widget.canEditSummary,
        onSummaryAggregateChanged: widget.onSummaryAggregateChanged,
      ),
    );
  }

  void _attachHorizontalListeners() {
    widget.scrollCoordinator.horizontalOffset.addListener(
      _handleHorizontalWindowChanged,
    );
    widget.scrollCoordinator.horizontalResizeTick.addListener(
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
      widget.layout,
      horizontalOffset: widget.scrollCoordinator.liveHorizontalOffset,
      viewportWidth: widget.viewportWidth,
    );
  }
}

class FdcGridSummaryRowBand extends StatelessWidget {
  const FdcGridSummaryRowBand({
    super.key,
    required this.layout,
    required this.values,
    required this.aggregates,
    required this.runtimeAggregateOverrides,
    required this.style,
    required this.showVerticalGridLines,
    required this.verticalGridLineColor,
    required this.allowColumnResize,
    required this.resizingRuntimeColumnId,
    required this.animateColumnReorder,
    required this.onColumnResizeStart,
    required this.onColumnResizeUpdate,
    required this.onColumnResizeEnd,
    required this.verticalSeparatorInset,
    required this.summaryRowHeight,
    required this.showTopSeparator,
    required this.topSeparatorColor,
    required this.previousColumnHasSummary,
    required this.leadingResizeTargetGeometry,
    required this.isRightPinnedBand,
    required this.onSummaryMenuOpen,
    required this.canEditSummary,
    required this.onSummaryAggregateChanged,
  });

  final FdcGridColumnBandLayout layout;
  final Map<FdcColumnIdentity, String> values;
  final Map<FdcColumnIdentity, FdcAggregate?> aggregates;
  final Set<FdcColumnIdentity> runtimeAggregateOverrides;
  final FdcGridSummaryStyle style;
  final bool showVerticalGridLines;
  final Color verticalGridLineColor;
  final bool allowColumnResize;
  final FdcColumnIdentity? resizingRuntimeColumnId;
  final bool animateColumnReorder;
  final void Function(
    int columnIndex,
    FdcColumnIdentity runtimeColumnId,
    double globalX,
    double deltaFactor,
  )
  onColumnResizeStart;
  final void Function(
    int columnIndex,
    FdcColumnIdentity runtimeColumnId,
    double globalX,
    double deltaFactor,
  )
  onColumnResizeUpdate;
  final void Function(int columnIndex, FdcColumnIdentity runtimeColumnId)
  onColumnResizeEnd;
  final double verticalSeparatorInset;
  final double summaryRowHeight;
  final bool showTopSeparator;
  final Color topSeparatorColor;
  final bool previousColumnHasSummary;
  final FdcGridColumnGeometry? leadingResizeTargetGeometry;
  final bool isRightPinnedBand;
  final VoidCallback onSummaryMenuOpen;
  final bool canEditSummary;
  final void Function(
    FdcColumnIdentity runtimeColumnId,
    FdcAggregate? aggregate,
  )
  onSummaryAggregateChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: layout.width,
      child: Stack(
        children: [
          for (final geometry in layout.geometries)
            AnimatedPositioned(
              key: ValueKey<Object?>(
                'fdc-grid-summary-cell-${geometry.runtimeColumnId}',
              ),
              duration: animateColumnReorder
                  ? fdcGridColumnReorderAnimationDuration
                  : Duration.zero,
              curve: Curves.easeOutCubic,
              left: geometry.offset,
              top: 0,
              width: geometry.width,
              bottom: 0,
              child: FdcGridSummaryCell(
                runtimeColumnId: geometry.runtimeColumnId,
                column: geometry.column,
                value: values[geometry.runtimeColumnId] ?? '',
                aggregate: aggregates[geometry.runtimeColumnId],
                hasRuntimeAggregateOverride: runtimeAggregateOverrides.contains(
                  geometry.runtimeColumnId,
                ),
                availableAggregates: _availableAggregates(geometry.column),
                textStyle: style.textStyle,
                padding:
                    style.padding ?? const EdgeInsets.symmetric(horizontal: 10),
                showLeftSummarySeparator: _showLeftSummarySeparator(geometry),
                showRightSummarySeparator: _showRightSummarySeparator(geometry),
                summarySeparatorColor: verticalGridLineColor,
                verticalSeparatorInset: verticalSeparatorInset,
                summaryRowHeight: summaryRowHeight,
                allowColumnResize: allowColumnResize,
                leadingResizeColumnIndex: _leadingResizeTargetGeometryAt(
                  geometry,
                )?.sourceColumnIndex,
                leadingResizeRuntimeColumnId: _leadingResizeTargetGeometryAt(
                  geometry,
                )?.runtimeColumnId,
                leadingResizeColumnAllowResize:
                    _leadingResizeTargetGeometryAt(
                      geometry,
                    )?.column.allowResize ==
                    true,
                leadingResizeDeltaFactor: isRightPinnedBand ? -1.0 : 1.0,
                resizeColumnIndex: layout.resizeTargetColumnIndexAt(
                  geometry.localColumnIndex,
                ),
                resizeRuntimeColumnId: layout.resizeTargetRuntimeColumnIdAt(
                  geometry.localColumnIndex,
                ),
                resizeColumnAllowResize:
                    layout
                        .resizeTargetColumnAt(geometry.localColumnIndex)
                        ?.allowResize ==
                    true,
                resizeDeltaFactor: layout.resizeDeltaFactorAt(
                  geometry.localColumnIndex,
                ),
                resizingRuntimeColumnId: resizingRuntimeColumnId,
                onColumnResizeStart: onColumnResizeStart,
                onColumnResizeUpdate: onColumnResizeUpdate,
                onColumnResizeEnd: onColumnResizeEnd,
                onSummaryMenuOpen: onSummaryMenuOpen,
                canEditSummary: canEditSummary,
                onSummaryAggregateChanged: onSummaryAggregateChanged,
              ),
            ),
          if (showTopSeparator)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: FdcGridHeaderMetrics.verticalSeparatorWidth,
              child: FdcGridHorizontalSeparator(
                width: layout.width,
                color: topSeparatorColor,
              ),
            ),
        ],
      ),
    );
  }

  FdcGridColumnGeometry? _leadingResizeTargetGeometryAt(
    FdcGridColumnGeometry geometry,
  ) {
    if (!_showLeftSummarySeparator(geometry)) {
      return null;
    }
    if (isRightPinnedBand) {
      return geometry;
    }
    final previousLocalColumnIndex = geometry.localColumnIndex - 1;
    if (previousLocalColumnIndex < 0) {
      return leadingResizeTargetGeometry;
    }
    return _geometryForLocalColumn(previousLocalColumnIndex);
  }

  bool _showLeftSummarySeparator(FdcGridColumnGeometry geometry) {
    if (!_hasSummarySeparator(geometry)) {
      return false;
    }
    final previousLocalColumnIndex = geometry.localColumnIndex - 1;
    if (previousLocalColumnIndex < 0) {
      return !previousColumnHasSummary;
    }
    return !_hasSummaryAtLocalColumn(previousLocalColumnIndex);
  }

  bool _showRightSummarySeparator(FdcGridColumnGeometry geometry) {
    if (layout.stretchesLastColumn &&
        geometry.localColumnIndex == layout.length - 1) {
      return false;
    }
    return _hasSummarySeparator(geometry);
  }

  bool _hasSummarySeparator(FdcGridColumnGeometry geometry) {
    return showVerticalGridLines &&
        _hasSummaryAtRuntimeId(geometry.runtimeColumnId);
  }

  bool _hasSummaryAtLocalColumn(int localColumnIndex) {
    final runtimeColumnId = layout.runtimeColumnIdAt(localColumnIndex);
    return runtimeColumnId != null && _hasSummaryAtRuntimeId(runtimeColumnId);
  }

  bool _hasSummaryAtRuntimeId(FdcColumnIdentity runtimeColumnId) {
    return aggregates[runtimeColumnId] != null;
  }

  FdcGridColumnGeometry? _geometryForLocalColumn(int localColumnIndex) {
    final column = layout.columnAt(localColumnIndex);
    final runtimeColumnId = layout.runtimeColumnIdAt(localColumnIndex);
    if (column == null || runtimeColumnId == null) {
      return null;
    }
    return FdcGridColumnGeometry(
      runtimeColumnId: runtimeColumnId,
      column: column,
      sourceColumnIndex: layout.columnIndexAt(localColumnIndex),
      localColumnIndex: localColumnIndex,
      width: layout.columnWidthAt(localColumnIndex, fallbackWidth: 0.0),
      offset: layout.columnOffsetAt(localColumnIndex, fallbackWidth: 0.0),
      visible: true,
    );
  }

  List<FdcAggregate> _availableAggregates(FdcGridColumn<dynamic> column) {
    return switch (column.dataType) {
      FdcDataType.integer || FdcDataType.decimal => FdcAggregate.values,
      FdcDataType.date || FdcDataType.dateTime || FdcDataType.time =>
        const <FdcAggregate>[FdcAggregate.min, FdcAggregate.max],
      _ => const <FdcAggregate>[],
    };
  }
}

class FdcGridSummaryCell extends StatelessWidget {
  const FdcGridSummaryCell({
    super.key,
    required this.runtimeColumnId,
    required this.column,
    required this.value,
    required this.aggregate,
    required this.hasRuntimeAggregateOverride,
    required this.availableAggregates,
    required this.textStyle,
    required this.padding,
    required this.showLeftSummarySeparator,
    required this.showRightSummarySeparator,
    required this.summarySeparatorColor,
    required this.verticalSeparatorInset,
    required this.summaryRowHeight,
    required this.allowColumnResize,
    required this.leadingResizeColumnIndex,
    required this.leadingResizeRuntimeColumnId,
    required this.leadingResizeColumnAllowResize,
    required this.leadingResizeDeltaFactor,
    required this.resizeColumnIndex,
    required this.resizeRuntimeColumnId,
    required this.resizeColumnAllowResize,
    required this.resizeDeltaFactor,
    required this.resizingRuntimeColumnId,
    required this.onColumnResizeStart,
    required this.onColumnResizeUpdate,
    required this.onColumnResizeEnd,
    required this.onSummaryMenuOpen,
    required this.canEditSummary,
    required this.onSummaryAggregateChanged,
  });

  final FdcColumnIdentity runtimeColumnId;
  final FdcGridColumn<dynamic> column;
  final String value;
  final FdcAggregate? aggregate;
  final bool hasRuntimeAggregateOverride;
  final List<FdcAggregate> availableAggregates;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final bool showLeftSummarySeparator;
  final bool showRightSummarySeparator;
  final Color summarySeparatorColor;
  final double verticalSeparatorInset;
  final double summaryRowHeight;
  final bool allowColumnResize;
  final int? leadingResizeColumnIndex;
  final FdcColumnIdentity? leadingResizeRuntimeColumnId;
  final bool leadingResizeColumnAllowResize;
  final double leadingResizeDeltaFactor;
  final int? resizeColumnIndex;
  final FdcColumnIdentity? resizeRuntimeColumnId;
  final bool resizeColumnAllowResize;
  final double resizeDeltaFactor;
  final FdcColumnIdentity? resizingRuntimeColumnId;
  final void Function(
    int columnIndex,
    FdcColumnIdentity runtimeColumnId,
    double globalX,
    double deltaFactor,
  )
  onColumnResizeStart;
  final void Function(
    int columnIndex,
    FdcColumnIdentity runtimeColumnId,
    double globalX,
    double deltaFactor,
  )
  onColumnResizeUpdate;
  final void Function(int columnIndex, FdcColumnIdentity runtimeColumnId)
  onColumnResizeEnd;
  final VoidCallback onSummaryMenuOpen;
  final bool canEditSummary;
  final void Function(
    FdcColumnIdentity runtimeColumnId,
    FdcAggregate? aggregate,
  )
  onSummaryAggregateChanged;

  double get _separatorHeight => math.max(
    0.0,
    summaryRowHeight - verticalSeparatorInset - verticalSeparatorInset,
  );

  @override
  Widget build(BuildContext context) {
    final translations = FdcApp.translationsOf(context).grid;
    final columnStyle = column.summary.style;
    final alignment =
        columnStyle?.alignment ??
        _summaryCellAlignment(column, Directionality.of(context));
    final effectivePadding = columnStyle?.padding ?? padding;
    final effectiveTextStyle = columnStyle?.textStyle ?? textStyle;
    final effectiveLeadingResizeRuntimeColumnId = leadingResizeRuntimeColumnId;
    final effectiveLeadingResizeColumnIndex = leadingResizeColumnIndex;
    final effectiveResizeRuntimeColumnId = resizeRuntimeColumnId;
    final effectiveResizeColumnIndex = resizeColumnIndex;
    final resizingLeading =
        effectiveLeadingResizeRuntimeColumnId != null &&
        resizingRuntimeColumnId == effectiveLeadingResizeRuntimeColumnId;
    final resizingTrailing =
        effectiveResizeRuntimeColumnId != null &&
        resizingRuntimeColumnId == effectiveResizeRuntimeColumnId;
    final showLeadingResizeHandle =
        showLeftSummarySeparator &&
        allowColumnResize &&
        leadingResizeColumnAllowResize &&
        effectiveLeadingResizeRuntimeColumnId != null &&
        effectiveLeadingResizeColumnIndex != null;
    final showResizeHandle =
        showRightSummarySeparator &&
        allowColumnResize &&
        resizeColumnAllowResize &&
        effectiveResizeRuntimeColumnId != null &&
        effectiveResizeColumnIndex != null;
    final content = DecoratedBox(
      decoration: BoxDecoration(color: columnStyle?.backgroundColor),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: effectivePadding,
            child: Align(
              alignment: alignment,
              child: _buildSummaryText(
                alignment: alignment,
                textStyle: effectiveTextStyle,
                textDirection: Directionality.of(context),
                translations: translations,
              ),
            ),
          ),
          if (showLeftSummarySeparator)
            Positioned(
              key: ValueKey<Object?>(
                'fdc-grid-summary-cell-$runtimeColumnId-left-separator',
              ),
              left: 0,
              top: verticalSeparatorInset,
              bottom: verticalSeparatorInset,
              child: FdcGridVerticalSeparator(
                alignment: Alignment.centerLeft,
                height: _separatorHeight,
                color: summarySeparatorColor,
                isActive: resizingLeading,
              ),
            ),
          if (showRightSummarySeparator)
            Positioned(
              key: ValueKey<Object?>(
                'fdc-grid-summary-cell-$runtimeColumnId-right-separator',
              ),
              right: 0,
              top: verticalSeparatorInset,
              bottom: verticalSeparatorInset,
              child: FdcGridVerticalSeparator(
                height: _separatorHeight,
                color: summarySeparatorColor,
                isActive: resizingTrailing,
              ),
            ),
          if (showLeadingResizeHandle)
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              width: fdcGridColumnResizeHandleWidth,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) => onColumnResizeStart(
                    effectiveLeadingResizeColumnIndex,
                    effectiveLeadingResizeRuntimeColumnId,
                    details.globalPosition.dx,
                    leadingResizeDeltaFactor,
                  ),
                  onHorizontalDragUpdate: (details) {
                    onColumnResizeUpdate(
                      effectiveLeadingResizeColumnIndex,
                      effectiveLeadingResizeRuntimeColumnId,
                      details.globalPosition.dx,
                      leadingResizeDeltaFactor,
                    );
                  },
                  onHorizontalDragEnd: (_) => onColumnResizeEnd(
                    effectiveLeadingResizeColumnIndex,
                    effectiveLeadingResizeRuntimeColumnId,
                  ),
                  onHorizontalDragCancel: () => onColumnResizeEnd(
                    effectiveLeadingResizeColumnIndex,
                    effectiveLeadingResizeRuntimeColumnId,
                  ),
                ),
              ),
            ),
          if (showResizeHandle)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              left: resizingTrailing ? 0 : null,
              width: resizingTrailing ? null : fdcGridColumnResizeHandleWidth,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) => onColumnResizeStart(
                    effectiveResizeColumnIndex,
                    effectiveResizeRuntimeColumnId,
                    details.globalPosition.dx,
                    resizeDeltaFactor,
                  ),
                  onHorizontalDragUpdate: (details) {
                    onColumnResizeUpdate(
                      effectiveResizeColumnIndex,
                      effectiveResizeRuntimeColumnId,
                      details.globalPosition.dx,
                      resizeDeltaFactor,
                    );
                  },
                  onHorizontalDragEnd: (_) => onColumnResizeEnd(
                    effectiveResizeColumnIndex,
                    effectiveResizeRuntimeColumnId,
                  ),
                  onHorizontalDragCancel: () => onColumnResizeEnd(
                    effectiveResizeColumnIndex,
                    effectiveResizeRuntimeColumnId,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    return content;
  }

  Widget _buildSummaryText({
    required Alignment alignment,
    required TextStyle? textStyle,
    required TextDirection textDirection,
    required FdcGridTranslations translations,
  }) {
    final label = _effectiveLabel(translations);
    if (label == null || label.trim().isEmpty) {
      return _buildSummaryValueText(
        alignment: alignment,
        textStyle: textStyle,
        translations: translations,
      );
    }

    return _buildLabeledSummaryText(
      label: label,
      alignment: alignment,
      textStyle: textStyle,
      textDirection: textDirection,
      translations: translations,
    );
  }

  bool get _summaryMenuEnabled =>
      canEditSummary &&
      column.summary.allowAggregateChange &&
      aggregate != null &&
      availableAggregates.isNotEmpty;

  Widget _buildSummaryMenuTarget(
    Widget child,
    FdcGridTranslations translations,
  ) {
    if (!_summaryMenuEnabled) {
      return child;
    }
    return FdcMenuAnchor(
      openOnTap: true,
      onOpen: onSummaryMenuOpen,
      entries: _summaryAggregateMenuEntries(translations),
      child: child,
    );
  }

  Widget _buildLabeledSummaryText({
    required String label,
    required Alignment alignment,
    required TextStyle? textStyle,
    required TextDirection textDirection,
    required FdcGridTranslations translations,
  }) {
    return switch (column.summary.labelAlignment) {
      FdcSummaryLabelAlignment.inline => _buildSummaryMenuTarget(
        Text.rich(
          _summaryTextSpan(label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
          textAlign: _summaryTextAlign(alignment),
        ),
        translations,
      ),
      FdcSummaryLabelAlignment.startAligned => _buildSeparatedLabelText(
        label: label,
        labelAlignment: textDirection == TextDirection.ltr
            ? Alignment.centerLeft
            : Alignment.centerRight,
        valueAlignment: alignment,
        textStyle: textStyle,
        translations: translations,
      ),
    };
  }

  Widget _buildSeparatedLabelText({
    required String label,
    required Alignment labelAlignment,
    required Alignment valueAlignment,
    required TextStyle? textStyle,
    required FdcGridTranslations translations,
  }) {
    final normalizedLabel = label.trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveTextStyle = DefaultTextStyle.of(
          context,
        ).style.merge(textStyle);
        final textDirection = Directionality.of(context);
        const overlapGap = 4.0;
        final labelWidth = _measureTextWidth(
          text: normalizedLabel,
          style: effectiveTextStyle,
          textDirection: textDirection,
        );
        final valueWidth = _measureTextWidth(
          text: value,
          style: effectiveTextStyle,
          textDirection: textDirection,
        );
        final valueStartsAtStartEdge = textDirection == TextDirection.ltr
            ? valueAlignment.x <= -1.0
            : valueAlignment.x >= 1.0;
        if (valueStartsAtStartEdge) {
          final shouldShowLabel =
              !constraints.maxWidth.isFinite ||
              labelWidth + overlapGap + valueWidth <= constraints.maxWidth;

          return SizedBox.expand(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildSummaryMenuTarget(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (shouldShowLabel) ...[
                      Flexible(
                        child: Text(
                          normalizedLabel,
                          key: ValueKey<Object?>(
                            'fdc-grid-summary-cell-$runtimeColumnId-label',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textStyle,
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const SizedBox(width: overlapGap),
                    ],
                    Flexible(
                      child: _buildSummaryValueText(
                        alignment: valueAlignment,
                        textStyle: textStyle,
                        translations: translations,
                        enableSummaryMenu: false,
                      ),
                    ),
                  ],
                ),
                translations,
              ),
            ),
          );
        }

        final valueLeft = _alignedTextLeft(
          containerWidth: constraints.maxWidth,
          textWidth: valueWidth,
          alignment: valueAlignment,
        );
        final availableStartSpace = textDirection == TextDirection.ltr
            ? valueLeft
            : constraints.maxWidth - (valueLeft + valueWidth);
        final shouldShowLabel =
            !constraints.maxWidth.isFinite ||
            labelWidth + overlapGap <= availableStartSpace;

        return SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (shouldShowLabel)
                Align(
                  alignment: labelAlignment,
                  child: _buildSummaryMenuTarget(
                    Text(
                      normalizedLabel,
                      key: ValueKey<Object?>(
                        'fdc-grid-summary-cell-$runtimeColumnId-label',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                      textAlign: _summaryTextAlign(labelAlignment),
                    ),
                    translations,
                  ),
                ),
              Align(
                alignment: valueAlignment,
                child: _buildSummaryValueText(
                  alignment: valueAlignment,
                  textStyle: textStyle,
                  translations: translations,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static double _measureTextWidth({
    required String text,
    required TextStyle style,
    required TextDirection textDirection,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: textDirection,
    )..layout();
    return painter.width;
  }

  static double _alignedTextLeft({
    required double containerWidth,
    required double textWidth,
    required Alignment alignment,
  }) {
    if (!containerWidth.isFinite) {
      return double.infinity;
    }
    return (containerWidth - textWidth) * ((alignment.x + 1) / 2);
  }

  Widget _buildSummaryValueText({
    required Alignment alignment,
    required TextStyle? textStyle,
    required FdcGridTranslations translations,
    bool enableSummaryMenu = true,
  }) {
    final text = Text(
      value,
      key: ValueKey<Object?>('fdc-grid-summary-cell-$runtimeColumnId-value'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
      textAlign: _summaryTextAlign(alignment),
    );
    if (!enableSummaryMenu) {
      return text;
    }
    return _buildSummaryMenuTarget(text, translations);
  }

  static TextAlign _summaryTextAlign(Alignment alignment) {
    if (alignment.x > 0) {
      return TextAlign.right;
    }
    if (alignment.x == 0) {
      return TextAlign.center;
    }
    return TextAlign.left;
  }

  TextSpan _summaryTextSpan(String label) {
    final normalizedLabel = label.trim();
    return TextSpan(
      children: <InlineSpan>[
        TextSpan(text: normalizedLabel),
        const TextSpan(text: ' '),
        TextSpan(text: value),
      ],
    );
  }

  String? _effectiveLabel(FdcGridTranslations translations) {
    if (!column.summary.labelVisible) {
      return null;
    }

    final effectiveAggregate = aggregate;
    if (effectiveAggregate == null) {
      return null;
    }

    final configuredLabel = _normalizedConfiguredLabel();
    final compileTimeAggregate = column.summary.aggregate;
    final usesCompileTimeAggregate = effectiveAggregate == compileTimeAggregate;

    if (configuredLabel != null &&
        (!hasRuntimeAggregateOverride || usesCompileTimeAggregate)) {
      return configuredLabel;
    }

    if (hasRuntimeAggregateOverride) {
      return translations.aggregateLabel(effectiveAggregate);
    }

    return null;
  }

  String? _normalizedConfiguredLabel() {
    final configuredLabel = column.summary.label?.trim();
    if (configuredLabel == null || configuredLabel.isEmpty) {
      return null;
    }
    return configuredLabel;
  }

  List<FdcMenuEntry> _summaryAggregateMenuEntries(
    FdcGridTranslations translations,
  ) {
    return <FdcMenuEntry>[
      for (final item in availableAggregates)
        FdcMenuCheckAction(
          text: _aggregateMenuLabel(item, translations),
          checked: aggregate == item,
          enabled: canEditSummary,
          onPressed: canEditSummary
              ? () => onSummaryAggregateChanged(runtimeColumnId, item)
              : null,
        ),
    ];
  }

  String _aggregateMenuLabel(
    FdcAggregate aggregate,
    FdcGridTranslations translations,
  ) {
    final configuredLabel = _normalizedConfiguredLabel();
    if (configuredLabel != null && aggregate == column.summary.aggregate) {
      return configuredLabel;
    }
    return translations.aggregateLabel(aggregate);
  }

  static Alignment _summaryCellAlignment(
    FdcGridColumn<dynamic> column,
    TextDirection textDirection,
  ) {
    final dataType = column.dataType;
    if (column.cellStyle?.alignment != null) {
      return column.cellStyle!.alignment!;
    }
    final horizontalAlignment = column.horizontalAlignment;
    if (horizontalAlignment != null) {
      return switch (horizontalAlignment) {
        FdcGridHorizontalAlignment.start =>
          textDirection == TextDirection.ltr
              ? Alignment.centerLeft
              : Alignment.centerRight,
        FdcGridHorizontalAlignment.center => Alignment.center,
        FdcGridHorizontalAlignment.end =>
          textDirection == TextDirection.ltr
              ? Alignment.centerRight
              : Alignment.centerLeft,
      };
    }
    if (dataType == FdcDataType.integer || dataType == FdcDataType.decimal) {
      return textDirection == TextDirection.ltr
          ? Alignment.centerRight
          : Alignment.centerLeft;
    }
    return textDirection == TextDirection.ltr
        ? Alignment.centerLeft
        : Alignment.centerRight;
  }
}
