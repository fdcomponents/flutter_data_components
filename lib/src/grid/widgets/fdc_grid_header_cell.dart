// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../columns/fdc_grid_columns.dart';
import '../core/fdc_grid_runtime_constants.dart';
import '../models/fdc_grid_internal_models.dart';
import 'fdc_grid_cell_frame.dart';
import 'fdc_grid_header_label.dart';
import 'fdc_grid_header_metrics.dart';
import 'fdc_grid_separators.dart';
import 'header_filters/fdc_grid_header_filter_cell.dart';

class FdcGridHeaderCell extends StatelessWidget {
  const FdcGridHeaderCell({
    super.key,
    required this.model,
    required this.callbacks,
    required this.column,
    required this.localColumnIndex,
    required this.columnIndex,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final FdcGridColumn<dynamic> column;
  final int localColumnIndex;
  final int columnIndex;

  @override
  Widget build(BuildContext context) {
    final draggingColumn = model.columnDragActive;
    final columnReorderingEnabled = model.options.allowColumnReordering;
    final allowColumnDragSource =
        columnReorderingEnabled && model.visibleColumnCount > 1;
    final content = FdcGridHeaderCellContent(
      model: model,
      callbacks: callbacks,
      column: column,
      localColumnIndex: localColumnIndex,
      columnIndex: columnIndex,
      allowColumnDrag: allowColumnDragSource,
    );
    final sortableChild = _wrapSortable(
      content,
      cursor: draggingColumn
          ? SystemMouseCursors.move
          : SystemMouseCursors.basic,
    );
    Widget child = sortableChild;

    // Drag sources and drop targets are intentionally independent. A pinned
    // band may contain only one column, which correctly makes that column a
    // non-draggable source, but it must still participate as a hover target so
    // cross-band drops can render the invalid (red) drag feedback.
    if (columnReorderingEnabled) {
      child = FdcGridHeaderReorderTarget(
        model: model,
        callbacks: callbacks,
        columnIndex: columnIndex,
        sortableChild: sortableChild,
      );
    }

    return FdcGridHeaderResizeHandle(
      model: model,
      callbacks: callbacks,
      localColumnIndex: localColumnIndex,
      child: child,
    );
  }

  Widget _wrapSortable(
    Widget child, {
    MouseCursor cursor = SystemMouseCursors.click,
  }) {
    if (!model.options.allowColumnSorting ||
        !column.allowSort ||
        model.showsFilterRow) {
      return child;
    }

    return MouseRegion(
      cursor: model.resizingRuntimeColumnId == null
          ? cursor
          : SystemMouseCursors.resizeLeftRight,
      child: child,
    );
  }
}

class FdcGridHeaderReorderTarget extends StatelessWidget {
  const FdcGridHeaderReorderTarget({
    super.key,
    required this.model,
    required this.callbacks,
    required this.columnIndex,
    required this.sortableChild,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final int columnIndex;
  final Widget sortableChild;

  Color _dragHighlightColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
  }

  double get _dragHighlightHeight {
    if (!model.showsFilterRow) {
      return model.leafHeaderHeight;
    }
    return math.max(0.0, model.leafHeaderHeight - model.filterRowHeight);
  }

  @override
  Widget build(BuildContext context) {
    final draggingColumn = model.draggingColumnIndex != null;
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        final sourceColumnIndex = model.draggingColumnIndex ?? details.data;
        final sameSourceTarget = sourceColumnIndex == columnIndex;
        final canAccept =
            model.resizingRuntimeColumnId == null &&
            !sameSourceTarget &&
            callbacks.canMoveColumn(sourceColumnIndex, columnIndex);
        callbacks.onColumnDragInvalidTargetHoverChanged(
          !canAccept && !sameSourceTarget,
        );
        return canAccept;
      },
      onMove: (details) {
        final sourceColumnIndex = model.draggingColumnIndex ?? details.data;
        final sameSourceTarget = sourceColumnIndex == columnIndex;
        if (sameSourceTarget) {
          callbacks.onColumnDragInvalidTargetHoverChanged(false);
          callbacks.onColumnDragHoverTarget(columnIndex);
          return;
        }

        final canSwap =
            model.resizingRuntimeColumnId == null &&
            callbacks.canMoveColumn(sourceColumnIndex, columnIndex);
        callbacks.onColumnDragInvalidTargetHoverChanged(!canSwap);
        if (canSwap) {
          callbacks.onColumnDragHoverTarget(columnIndex);
        }
      },
      onAcceptWithDetails: (_) {
        callbacks.onColumnDragInvalidTargetHoverChanged(false);
      },
      onLeave: (_) => callbacks.onColumnDragInvalidTargetHoverChanged(false),
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.any((candidate) {
          if (candidate == null) {
            return false;
          }
          final sourceColumnIndex = model.draggingColumnIndex ?? candidate;
          return sourceColumnIndex != columnIndex;
        });

        return MouseRegion(
          cursor: draggingColumn
              ? SystemMouseCursors.move
              : SystemMouseCursors.basic,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              sortableChild,
              if (hovering)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _dragHighlightHeight,
                  child: IgnorePointer(
                    child: ColoredBox(color: _dragHighlightColor(context)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class FdcGridHeaderResizeHandle extends StatelessWidget {
  const FdcGridHeaderResizeHandle({
    super.key,
    required this.model,
    required this.callbacks,
    required this.localColumnIndex,
    required this.child,
    this.separatorHeight,
    this.separatorColor,
    this.separatorTopInset,
    this.separatorBottomInset,
    this.useFullHeightTrailingSeparator = true,
    this.allowResizeHandle = true,
    this.groupResizeColumnIndexes = const <int>[],
    this.groupResizeRuntimeColumnIds = const <FdcColumnIdentity>[],
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final int localColumnIndex;
  final Widget child;
  final double? separatorHeight;
  final Color? separatorColor;
  final double? separatorTopInset;
  final double? separatorBottomInset;
  final bool useFullHeightTrailingSeparator;
  final bool allowResizeHandle;
  final List<int> groupResizeColumnIndexes;
  final List<FdcColumnIdentity> groupResizeRuntimeColumnIds;

  bool get _isGroupResizeHandle =>
      groupResizeColumnIndexes.length > 1 &&
      groupResizeColumnIndexes.length == groupResizeRuntimeColumnIds.length;

  @override
  Widget build(BuildContext context) {
    final resizeRuntimeColumnId = model.resizeTargetRuntimeColumnIdAt(
      localColumnIndex,
    );
    final resizeDeltaFactor = model.resizeDeltaFactorAt(localColumnIndex);
    final resizing =
        resizeRuntimeColumnId != null &&
        model.resizingRuntimeColumnId == resizeRuntimeColumnId &&
        (model.resizingDeltaFactor == null ||
            (model.resizingDeltaFactor! - resizeDeltaFactor).abs() < 0.01);
    final useFullHeightSeparator =
        useFullHeightTrailingSeparator &&
        model.fullHeightTrailingSeparator &&
        localColumnIndex == model.visibleColumnCount - 1;
    final resolvedSeparatorTopInset = useFullHeightSeparator
        ? 0.0
        : separatorTopInset ?? model.headerSeparatorTopInset;
    final resolvedSeparatorBottomInset = useFullHeightSeparator
        ? 0.0
        : separatorBottomInset ?? model.headerSeparatorBottomInset;
    final suppressTrailingEdge = model.suppressTrailingEdgeAt(localColumnIndex);
    final suppressTrailingSeparator = model.suppressTrailingSeparatorAt(
      localColumnIndex,
    );
    final stackChildren = <Widget>[
      child,
      if (!suppressTrailingSeparator)
        Positioned.fill(
          child: FdcGridVerticalSeparator(
            height: separatorHeight ?? model.leafHeaderHeight,
            color: separatorColor ?? model.effectiveVerticalGridLineColor,
            isActive: resizing,
            topInset: resolvedSeparatorTopInset,
            bottomInset: resolvedSeparatorBottomInset,
          ),
        ),
    ];

    final resizeColumn = model.resizeTargetColumnAt(localColumnIndex);
    final resizeColumnIndex = model.resizeTargetColumnIndexAt(localColumnIndex);
    if (!suppressTrailingEdge &&
        allowResizeHandle &&
        model.options.allowColumnResize &&
        resizeColumnIndex != null &&
        resizeRuntimeColumnId != null &&
        (_isGroupResizeHandle || resizeColumn?.allowResize == true)) {
      final deltaFactor = resizeDeltaFactor;
      stackChildren.add(
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          left: resizing ? 0 : null,
          width: resizing ? null : fdcGridColumnResizeHandleWidth,
          child: IgnorePointer(
            ignoring: model.columnDragActive,
            child: MouseRegion(
              cursor: model.columnDragActive
                  ? SystemMouseCursors.move
                  : SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  if (_isGroupResizeHandle) {
                    callbacks.onColumnGroupResizeStart(
                      groupResizeColumnIndexes,
                      groupResizeRuntimeColumnIds,
                      resizeRuntimeColumnId,
                      details.globalPosition.dx,
                      deltaFactor,
                    );
                    return;
                  }
                  callbacks.onColumnResizeStart(
                    resizeColumnIndex,
                    resizeRuntimeColumnId,
                    details.globalPosition.dx,
                    deltaFactor,
                  );
                },
                onHorizontalDragUpdate: (details) {
                  if (_isGroupResizeHandle) {
                    callbacks.onColumnGroupResizeUpdate(
                      groupResizeColumnIndexes,
                      groupResizeRuntimeColumnIds,
                      resizeRuntimeColumnId,
                      details.globalPosition.dx,
                      deltaFactor,
                    );
                    return;
                  }
                  callbacks.onColumnResizeUpdate(
                    resizeColumnIndex,
                    resizeRuntimeColumnId,
                    details.globalPosition.dx,
                    deltaFactor,
                  );
                },
                onHorizontalDragEnd: (_) {
                  if (_isGroupResizeHandle) {
                    callbacks.onColumnGroupResizeEnd(resizeRuntimeColumnId);
                    return;
                  }
                  callbacks.onColumnResizeEnd(
                    resizeColumnIndex,
                    resizeRuntimeColumnId,
                  );
                },
                onHorizontalDragCancel: () {
                  if (_isGroupResizeHandle) {
                    callbacks.onColumnGroupResizeEnd(resizeRuntimeColumnId);
                    return;
                  }
                  callbacks.onColumnResizeEnd(
                    resizeColumnIndex,
                    resizeRuntimeColumnId,
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: stackChildren);
  }
}

class FdcGridHeaderCellContent extends StatelessWidget {
  const FdcGridHeaderCellContent({
    super.key,
    required this.model,
    required this.callbacks,
    required this.column,
    required this.localColumnIndex,
    required this.columnIndex,
    this.highlighted = false,
    this.allowColumnDrag = false,
    this.suppressSortAffordance = false,
    this.suppressFilterRow = false,
    this.suppressHeaderMenuIcon = false,
    this.width,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final FdcGridColumn<dynamic> column;
  final int localColumnIndex;
  final int columnIndex;
  final bool highlighted;
  final bool allowColumnDrag;
  final bool suppressSortAffordance;
  final bool suppressFilterRow;
  final bool suppressHeaderMenuIcon;
  final double? width;

  FdcColumnIdentity? get _runtimeColumnId =>
      model.runtimeColumnIdAt(localColumnIndex);

  Color _dragHighlightColor(BuildContext context) {
    return Color.alphaBlend(
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
      model.headerBackgroundColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortIcon = suppressSortAffordance
        ? null
        : callbacks.sortIconOf(columnIndex);
    final cellWidth =
        width ?? model.columnWidthAt(localColumnIndex, fallbackWidth: 0.0);

    return SizedBox(
      width: cellWidth,
      height: double.infinity,
      child: LayoutBuilder(
        builder: (context, outerConstraints) {
          final showsFilterRow = model.showsFilterRow && !suppressFilterRow;
          final filterHeight = showsFilterRow
              ? math.min(model.filterRowHeight, outerConstraints.maxHeight)
              : 0.0;
          final labelHeight = math.max(
            0.0,
            outerConstraints.maxHeight - filterHeight,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              FdcGridCellFrame(
                width: cellWidth,
                alignment: Alignment.centerLeft,
                color: highlighted ? _dragHighlightColor(context) : null,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showHeaderMenuIcon =
                        column.isDataBound &&
                        !suppressHeaderMenuIcon &&
                        FdcGridHeaderMetrics.hasRoomForHeaderMenu(
                          constraints.maxWidth,
                        );
                    final showSortIcon =
                        !suppressSortAffordance &&
                        model.options.allowColumnSorting &&
                        column.allowSort &&
                        FdcGridHeaderMetrics.hasRoomForSortIcon(
                          constraints.maxWidth,
                        );
                    final innerFilterHeight = showsFilterRow
                        ? math.min(model.filterRowHeight, constraints.maxHeight)
                        : 0.0;
                    final innerLabelHeight = math.max(
                      0.0,
                      constraints.maxHeight - innerFilterHeight,
                    );
                    return Column(
                      children: [
                        FdcGridHeaderLabel(
                          model: model,
                          callbacks: callbacks,
                          column: column,
                          localColumnIndex: localColumnIndex,
                          columnIndex: columnIndex,
                          runtimeColumnId: _runtimeColumnId,
                          height: innerLabelHeight,
                          sortIcon: sortIcon,
                          showHeaderMenuIcon: showHeaderMenuIcon,
                          showSortIcon: showSortIcon,
                          allowColumnDrag: allowColumnDrag,
                          dragFeedbackHeight: innerLabelHeight,
                          dragFeedbackChild: allowColumnDrag
                              ? FdcGridHeaderCellContent(
                                  model: model,
                                  callbacks: callbacks,
                                  column: column,
                                  localColumnIndex: localColumnIndex,
                                  columnIndex: columnIndex,
                                  highlighted: true,
                                  suppressFilterRow: true,
                                  width: FdcGridHeaderMetrics
                                      .columnDragFeedbackWidth,
                                )
                              : null,
                        ),
                        if (showsFilterRow)
                          SizedBox(
                            height: innerFilterHeight,
                            child: FdcGridHeaderFilterCell(
                              model: model,
                              callbacks: callbacks,
                              column: column,
                              runtimeColumnId: _runtimeColumnId,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              if (showsFilterRow &&
                  filterHeight > 0 &&
                  column is! FdcActionColumn)
                Positioned(
                  left: 0,
                  right: 0,
                  top: labelHeight,
                  child: FdcGridHeaderLabelFilterSeparator(
                    width: outerConstraints.maxWidth,
                    color: model.headerSeparatorColor,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class FdcGridHeaderLabelFilterSeparator extends StatelessWidget {
  const FdcGridHeaderLabelFilterSeparator({
    super.key,
    required this.width,
    required this.color,
  });

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FdcGridHorizontalSeparator(width: width, color: color);
  }
}
