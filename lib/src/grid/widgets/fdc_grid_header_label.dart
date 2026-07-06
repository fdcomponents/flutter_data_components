// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../columns/fdc_grid_columns.dart';
import '../models/fdc_grid_internal_models.dart';
import 'fdc_grid_header_menus.dart';
import 'fdc_grid_header_metrics.dart';

class FdcGridHeaderLabel extends StatefulWidget {
  const FdcGridHeaderLabel({
    super.key,
    required this.model,
    required this.callbacks,
    required this.column,
    required this.localColumnIndex,
    required this.columnIndex,
    required this.runtimeColumnId,
    required this.height,
    required this.sortIcon,
    required this.showHeaderMenuIcon,
    required this.showSortIcon,
    required this.allowColumnDrag,
    required this.dragFeedbackChild,
    required this.dragFeedbackHeight,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final FdcGridColumn<dynamic> column;
  final int localColumnIndex;
  final int columnIndex;
  final FdcColumnIdentity? runtimeColumnId;
  final double height;
  final IconData? sortIcon;
  final bool showHeaderMenuIcon;
  final bool showSortIcon;
  final bool allowColumnDrag;
  final Widget? dragFeedbackChild;
  final double dragFeedbackHeight;

  @override
  State<FdcGridHeaderLabel> createState() => FdcGridHeaderLabelState();
}

class FdcGridHeaderLabelState extends State<FdcGridHeaderLabel> {
  bool _hovering = false;

  bool get _sortEnabled =>
      widget.model.options.allowColumnSorting && widget.column.allowSort;

  bool get _canSort =>
      !widget.model.interactionLocked &&
      _sortEnabled &&
      widget.callbacks.canChangeView();

  bool get _hasHeaderMenuActions {
    return FdcGridHeaderColumnMenuEntries(
      callbacks: widget.callbacks,
      columnIndex: widget.columnIndex,
      column: widget.column,
      runtimeColumnId: widget.runtimeColumnId,
      includeMainMenuEntries: _showMainMenuInColumnMenu,
    ).hasColumnActions;
  }

  bool get _showMainMenuInColumnMenu => widget.model.showMainMenuInColumnMenu;

  Color _invalidDropFeedbackHighlightColor(BuildContext context) {
    return Theme.of(context).colorScheme.error.withValues(alpha: 0.32);
  }

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: double.infinity,
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showHeaderMenuIcon =
              _hasHeaderMenuActions &&
              widget.showHeaderMenuIcon &&
              FdcGridHeaderMetrics.hasRoomForHeaderMenu(constraints.maxWidth);

          final labelArea = _buildHeaderLabelArea(
            context,
            constraints.maxWidth,
          );

          if (_headerHorizontalAlignment == FdcGridHorizontalAlignment.end &&
              showHeaderMenuIcon) {
            return Row(
              children: [
                const SizedBox(width: FdcGridHeaderMetrics.menuEndPadding),
                IgnorePointer(
                  ignoring: widget.model.interactionLocked,
                  child: FdcGridHeaderColumnMenuButton(
                    callbacks: widget.callbacks,
                    columnIndex: widget.columnIndex,
                    column: widget.column,
                    runtimeColumnId: widget.runtimeColumnId,
                    includeMainMenuEntries: _showMainMenuInColumnMenu,
                  ),
                ),
                const SizedBox(width: FdcGridHeaderMetrics.menuGap),
                labelArea,
              ],
            );
          }

          return Row(
            children: [
              labelArea,
              if (showHeaderMenuIcon) ...[
                const SizedBox(width: FdcGridHeaderMetrics.menuGap),
                IgnorePointer(
                  ignoring: widget.model.interactionLocked,
                  child: FdcGridHeaderColumnMenuButton(
                    callbacks: widget.callbacks,
                    columnIndex: widget.columnIndex,
                    column: widget.column,
                    runtimeColumnId: widget.runtimeColumnId,
                    includeMainMenuEntries: _showMainMenuInColumnMenu,
                  ),
                ),
                const SizedBox(width: FdcGridHeaderMetrics.menuEndPadding),
              ],
            ],
          );
        },
      ),
    );

    final interactiveContent = !_canSort
        ? content
        : MouseRegion(
            onHover: (_) => _setHovering(true),
            onEnter: (_) => _setHovering(true),
            onExit: (_) => _setHovering(false),
            child: content,
          );

    return _wrapColumnDrag(_wrapColumnHintTooltip(interactiveContent));
  }

  Widget _buildHeaderLabelArea(BuildContext context, double maxWidth) {
    return Expanded(
      child: Padding(
        padding: _headerLabelPadding(maxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showSortAffordance = _canShowSortAffordance(
              constraints.maxWidth,
            );
            return ClipRect(
              child: Row(
                mainAxisAlignment: _headerMainAxisAlignment,
                children: _buildHeaderLabelChildren(
                  context,
                  showSortAffordance: showSortAffordance,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildHeaderLabelChildren(
    BuildContext context, {
    required bool showSortAffordance,
  }) {
    final label = Flexible(
      child: _wrapHeaderLabelTarget(
        context,
        Text(
          widget.callbacks.columnLabelOf(widget.column),
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: _headerTextAlign,
          style: widget.model.headerTextStyle,
        ),
      ),
    );

    if (!showSortAffordance) {
      return <Widget>[label];
    }

    final sortAffordance = FdcGridHeaderSortAffordance(
      visible: true,
      active: _hasActiveSortIcon,
      icon: _visibleSortIcon,
      color: _sortAffordanceColor(context),
      sortPosition: _visibleSortPosition,
      showSortPosition: _showSortPosition,
      padding: _sortAffordancePadding,
      childBuilder: (child) => _wrapHeaderLabelTarget(context, child),
    );

    if (_headerHorizontalAlignment == FdcGridHorizontalAlignment.end) {
      return <Widget>[sortAffordance, label];
    }

    return <Widget>[label, sortAffordance];
  }

  EdgeInsetsGeometry get _sortAffordancePadding {
    return switch (_headerHorizontalAlignment) {
      FdcGridHorizontalAlignment.end => const EdgeInsetsDirectional.only(
        end: FdcGridHeaderMetrics.sortIconGap,
      ),
      FdcGridHorizontalAlignment.start ||
      FdcGridHorizontalAlignment.center => const EdgeInsetsDirectional.only(
        start: FdcGridHeaderMetrics.sortIconGap,
      ),
    };
  }

  EdgeInsetsGeometry _headerLabelPadding(double maxWidth) {
    final padding = math.min(FdcGridHeaderMetrics.labelStartPadding, maxWidth);
    return switch (_headerHorizontalAlignment) {
      FdcGridHorizontalAlignment.start => EdgeInsetsDirectional.only(
        start: padding,
      ),
      FdcGridHorizontalAlignment.center => EdgeInsets.zero,
      FdcGridHorizontalAlignment.end => EdgeInsetsDirectional.only(
        end: padding,
      ),
    };
  }

  FdcGridHorizontalAlignment get _headerHorizontalAlignment {
    return widget.column.horizontalAlignment ??
        FdcGridHorizontalAlignment.start;
  }

  MainAxisAlignment get _headerMainAxisAlignment {
    return switch (_headerHorizontalAlignment) {
      FdcGridHorizontalAlignment.start => MainAxisAlignment.start,
      FdcGridHorizontalAlignment.center => MainAxisAlignment.center,
      FdcGridHorizontalAlignment.end => MainAxisAlignment.end,
    };
  }

  TextAlign get _headerTextAlign {
    return switch (_headerHorizontalAlignment) {
      FdcGridHorizontalAlignment.start => TextAlign.start,
      FdcGridHorizontalAlignment.center => TextAlign.center,
      FdcGridHorizontalAlignment.end => TextAlign.end,
    };
  }

  Widget _wrapColumnHintTooltip(Widget child) {
    if (widget.model.interactionLocked) {
      return child;
    }

    final hint = widget.column.hint?.trim();
    if (hint == null || hint.isEmpty) {
      return child;
    }

    return Tooltip(
      message: hint,
      waitDuration: const Duration(milliseconds: 600),
      child: child,
    );
  }

  Widget _wrapColumnDrag(Widget child) {
    final feedbackChild = widget.dragFeedbackChild;
    if (!widget.allowColumnDrag || feedbackChild == null) {
      return child;
    }

    return LongPressDraggable<int>(
      data: widget.columnIndex,
      axis: Axis.horizontal,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () =>
          widget.callbacks.onColumnDragStarted(widget.columnIndex),
      onDragEnd: (_) => widget.callbacks.onColumnDragEnded(widget.columnIndex),
      onDraggableCanceled: (_, _) =>
          widget.callbacks.onColumnDragEnded(widget.columnIndex),
      feedback: Transform.translate(
        offset: FdcGridHeaderMetrics.columnDragFeedbackOffset,
        child: Material(
          color: Colors.transparent,
          elevation: 6,
          borderRadius: BorderRadius.circular(6),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: FdcGridHeaderMetrics.columnDragFeedbackWidth,
            height: math.min(
              FdcGridHeaderMetrics.columnDragFeedbackHeight,
              math.max(0.0, widget.dragFeedbackHeight),
            ),
            child: Opacity(
              opacity: 0.88,
              child: ValueListenableBuilder<bool>(
                valueListenable:
                    widget.model.invalidColumnDropTargetHoverListenable,
                builder: (context, invalidDropTargetHovering, child) {
                  if (!invalidDropTargetHovering) {
                    return child!;
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      child!,
                      IgnorePointer(
                        child: ColoredBox(
                          color: _invalidDropFeedbackHighlightColor(context),
                        ),
                      ),
                    ],
                  );
                },
                child: feedbackChild,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: child),
      child: child,
    );
  }

  bool get _hasActiveSortIcon => widget.sortIcon != null;

  bool get _showGhostSortIcon =>
      _sortEnabled && !_hasActiveSortIcon && _hovering && widget.showSortIcon;

  bool get _showSortAffordance =>
      widget.showSortIcon && (_hasActiveSortIcon || _showGhostSortIcon);

  bool _canShowSortAffordance(double width) {
    return _showSortAffordance &&
        FdcGridHeaderMetrics.hasRoomForSortAffordance(width);
  }

  IconData? get _visibleSortIcon {
    if (_hasActiveSortIcon) {
      return widget.sortIcon;
    }
    if (_showGhostSortIcon) {
      return Icons.north;
    }
    return null;
  }

  int get _visibleSortPosition {
    if (!_hasActiveSortIcon) {
      return 0;
    }
    return widget.callbacks.headerSortPosition(widget.columnIndex);
  }

  bool get _showSortPosition =>
      _hasActiveSortIcon &&
      widget.callbacks.headerSortCount() > 1 &&
      _visibleSortPosition > 0;

  Color _sortAffordanceColor(BuildContext context) {
    final color = widget.callbacks.sortIconColorOf(context, widget.columnIndex);
    if (_hasActiveSortIcon) {
      return color;
    }

    return Color.lerp(color, widget.model.headerBackgroundColor, 0.38) ?? color;
  }

  void _setHovering(bool value) {
    if (_hovering == value) {
      return;
    }
    setState(() {
      _hovering = value;
    });
  }

  MouseCursor get _headerLabelCursor {
    if (widget.model.columnDragActive) {
      return SystemMouseCursors.move;
    }
    if (widget.model.resizingRuntimeColumnId != null) {
      return SystemMouseCursors.resizeLeftRight;
    }
    return _canSort ? SystemMouseCursors.click : SystemMouseCursors.basic;
  }

  Widget _wrapHeaderLabelTarget(BuildContext context, Widget child) {
    return MouseRegion(
      cursor: _headerLabelCursor,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_canSort) {
            widget.callbacks.onHeaderSortTap(widget.columnIndex);
            return;
          }
          widget.callbacks.onClearFocusedCell();
        },
        child: child,
      ),
    );
  }
}

class FdcGridHeaderSortAffordance extends StatelessWidget {
  const FdcGridHeaderSortAffordance({
    super.key,
    required this.visible,
    required this.active,
    required this.icon,
    required this.color,
    required this.sortPosition,
    required this.showSortPosition,
    required this.padding,
    required this.childBuilder,
  });

  final bool visible;
  final bool active;
  final IconData? icon;
  final Color color;
  final int sortPosition;
  final bool showSortPosition;
  final EdgeInsetsGeometry padding;
  final Widget Function(Widget child) childBuilder;

  @override
  Widget build(BuildContext context) {
    final sortIcon = icon;

    return AnimatedSwitcher(
      duration: FdcGridHeaderMetrics.sortFadeInDuration,
      reverseDuration: FdcGridHeaderMetrics.sortFadeOutDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: visible && sortIcon != null
          ? Padding(
              key: ValueKey<String>(
                'sort-affordance-${active ? 'active' : 'ghost'}-$sortIcon-$sortPosition',
              ),
              padding: padding,
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: childBuilder(
                  FdcGridHeaderSortIconWithPosition(
                    icon: sortIcon,
                    color: color,
                    position: sortPosition,
                    showPosition: showSortPosition,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(
              key: ValueKey<String>('sort-affordance-none'),
            ),
    );
  }
}

class FdcGridHeaderSortIconWithPosition extends StatelessWidget {
  const FdcGridHeaderSortIconWithPosition({
    super.key,
    required this.icon,
    required this.color,
    required this.position,
    required this.showPosition,
  });

  final IconData icon;
  final Color color;
  final int position;
  final bool showPosition;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: FdcGridHeaderMetrics.sortIconSize,
      color: color,
    );

    if (!showPosition) {
      return iconWidget;
    }

    return SizedBox(
      width: FdcGridHeaderMetrics.sortIndicatorWidth,
      height: FdcGridHeaderMetrics.headerControlHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          iconWidget,
          Positioned(
            left: FdcGridHeaderMetrics.sortPositionSuperscriptLeft,
            top: FdcGridHeaderMetrics.sortPositionSuperscriptTop,
            child: FdcGridHeaderSortPositionNumber(
              position: position,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class FdcGridHeaderSortPositionNumber extends StatelessWidget {
  const FdcGridHeaderSortPositionNumber({
    super.key,
    required this.position,
    required this.color,
  });

  final int position;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$position',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontSize: FdcGridHeaderMetrics.sortPositionFontSize,
        height: 1,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
