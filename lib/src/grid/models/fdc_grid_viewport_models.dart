// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../common/theme/fdc_grid_styles.dart';
import '../core/fdc_grid_core.dart';
import '../format/fdc_value_formatter.dart';
import '../managers/fdc_grid_scroll_coordinator.dart';
import 'fdc_column_identity.dart';
import 'fdc_grid_layout_models.dart';
import 'fdc_grid_range_selection_feature.dart';

class FdcGridVerticalLayoutSnapshot {
  const FdcGridVerticalLayoutSnapshot({
    required this.viewportHeight,
    required this.contentHeight,
    required this.scrollOffset,
    required this.firstMountedRow,
    required this.lastMountedRow,
    required this.firstMountedRowTop,
  });

  final double viewportHeight;
  final double contentHeight;
  final double scrollOffset;
  final int firstMountedRow;
  final int lastMountedRow;
  final double firstMountedRowTop;
}

class FdcGridViewportModel {
  const FdcGridViewportModel({
    required this.columnBandLayouts,
    required this.valueFormatter,
    required this.layoutRegions,
    required this.defaultColumnWidth,
    required this.rowHeight,
    required this.effectiveHeaderHeight,
    required this.headerFilterRowHeight,
    required this.topInset,
    required this.bottomInset,
    required this.visibleRowsHeight,
    required this.paintedGridWidth,
    required this.centerViewportWidth,
    required this.paintedGridHeight,
    required this.rowsLength,
    required this.expandedDetailRows,
    required this.visibleDetailRows,
    required this.detailRowHeight,
    required this.detailRowHeights,
    required this.detailRowContentSized,
    required this.backgroundColor,
    required this.rowIndicatorBackgroundColor,
    required this.headerSeparatorColor,
    required this.gridLines,
    required this.options,
    required this.horizontalGridLineColor,
    required this.verticalGridLineColor,
    required this.pinnedSeparatorColor,
    required this.pinnedSeparatorInset,
    required this.verticalLineExtent,
    required this.scrollCoordinator,
    required this.resizingRuntimeColumnId,
    required this.resizingDeltaFactor,
    required this.draggingColumnIndex,
    required this.hasActiveCellEditor,
    required this.recordScroll,
    required this.bodyKey,
    required this.selectedRangeBounds,
    required this.rangeOutlineStyle,
    required this.rangeBackgroundColor,
    required this.rangeSelectionModifierActive,
    required this.rangeSelectionCopyEnabled,
    required this.rangeSelectionPasteEnabled,
    required this.rangeSelectionContextMenuBuilder,
    required this.rangeSelectionContainsCell,
    required this.rangeSelectionOverlayBuilder,
  });

  final FdcGridColumnBandLayouts columnBandLayouts;
  final FdcValueFormatter valueFormatter;
  final FdcGridLayoutRegions layoutRegions;
  final double defaultColumnWidth;
  final double rowHeight;
  final double effectiveHeaderHeight;
  final double headerFilterRowHeight;
  final double topInset;
  final double bottomInset;
  final double visibleRowsHeight;
  final double paintedGridWidth;
  final double centerViewportWidth;
  final double paintedGridHeight;
  final int rowsLength;
  final Set<int> expandedDetailRows;
  final Set<int> visibleDetailRows;
  final double detailRowHeight;
  final Map<int, double> detailRowHeights;
  final bool detailRowContentSized;

  bool get hasDetailRows => expandedDetailRows.isNotEmpty;

  double detailHeightAt(int rowIndex) {
    return detailRowHeights[rowIndex] ?? detailRowHeight;
  }

  double rowExtentAt(int rowIndex) {
    return rowHeight +
        (expandedDetailRows.contains(rowIndex)
            ? detailHeightAt(rowIndex)
            : 0.0);
  }

  double rowTopAt(int rowIndex) {
    if (rowIndex <= 0) {
      return 0.0;
    }
    var top = rowIndex * rowHeight;
    for (final expandedRow in expandedDetailRows) {
      if (expandedRow < rowIndex) {
        top += detailHeightAt(expandedRow);
      }
    }
    return top;
  }

  double get contentHeight {
    var detailHeight = 0.0;
    for (final rowIndex in expandedDetailRows) {
      detailHeight += detailHeightAt(rowIndex);
    }
    return rowsLength * rowHeight + detailHeight;
  }

  int rowIndexAtOffset(double offset) {
    if (rowsLength <= 0) {
      return 0;
    }
    var low = 0;
    var high = rowsLength - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final top = rowTopAt(mid);
      final bottom = top + rowExtentAt(mid);
      if (offset < top) {
        high = mid - 1;
      } else if (offset >= bottom) {
        low = mid + 1;
      } else {
        return mid;
      }
    }
    return low.clamp(0, rowsLength - 1);
  }

  final Color backgroundColor;
  final Color rowIndicatorBackgroundColor;
  final Color headerSeparatorColor;
  final FdcGridLines gridLines;
  final FdcGridOptions options;
  final Color horizontalGridLineColor;
  final Color verticalGridLineColor;
  final Color pinnedSeparatorColor;
  final double pinnedSeparatorInset;
  final FdcGridVerticalLines verticalLineExtent;

  bool get showHorizontalGridLines =>
      gridLines == FdcGridLines.horizontal || gridLines == FdcGridLines.both;

  bool get showVerticalGridLines =>
      gridLines == FdcGridLines.vertical || gridLines == FdcGridLines.both;
  final FdcGridScrollCoordinator scrollCoordinator;
  final FdcColumnIdentity? resizingRuntimeColumnId;
  final double? resizingDeltaFactor;
  final int? draggingColumnIndex;
  final bool hasActiveCellEditor;

  ScrollController get horizontalScrollController =>
      scrollCoordinator.horizontalFlutterController;

  ScrollController get verticalScrollController =>
      scrollCoordinator.verticalFlutterController;
  final bool recordScroll;
  final GlobalKey bodyKey;
  final ({
    int firstRow,
    int lastRow,
    int firstColumn,
    int lastColumn,
    List<int> columnIndexes,
  })?
  selectedRangeBounds;
  final FdcGridResolvedCellIndicatorStyle? rangeOutlineStyle;
  final Color? rangeBackgroundColor;
  final bool rangeSelectionModifierActive;
  final bool rangeSelectionCopyEnabled;
  final bool rangeSelectionPasteEnabled;
  final FdcGridRangeSelectionContextMenuBuilder?
  rangeSelectionContextMenuBuilder;
  final bool Function(int rowIndex, int columnIndex)?
  rangeSelectionContainsCell;
  final FdcGridRangeSelectionOverlayBuilder? rangeSelectionOverlayBuilder;

  /// Resolves detached vertical bands from metrics already confirmed by the
  /// center ListView. The current shell viewport remains an authoritative
  /// lower bound while header/filter height changes are settling: the detached
  /// row-indicator and pinned bands must not keep using an older, shorter
  /// confirmed viewport and leave newly exposed body rows blank.
  FdcGridVerticalLayoutSnapshot resolveVerticalLayout() {
    final confirmedViewportHeight = scrollCoordinator
        .confirmedVerticalViewportDimension(visibleRowsHeight)
        .clamp(0.0, double.infinity)
        .toDouble();
    final currentViewportHeight = visibleRowsHeight
        .clamp(0.0, double.infinity)
        .toDouble();
    final resolvedViewportHeight = math.max(
      confirmedViewportHeight,
      currentViewportHeight,
    );
    final contentHeight = this.contentHeight;
    final maxContentOffset = contentHeight > resolvedViewportHeight
        ? contentHeight - resolvedViewportHeight
        : 0.0;
    // Detached row content must follow the same live ScrollPosition pixels
    // as the center ListView and grid-line painters. Confirmed metrics are used
    // only for the viewport dimension; a post-frame confirmed offset would
    // make cell backgrounds/content jump ahead of an in-progress correction.
    // Flutter can temporarily report pixels outside the newly reduced scroll
    // extent while a ballistic correction settles after a viewport resize.
    // Detached cells must follow those raw visual pixels exactly, just like the
    // center ListView and line painters. Use a clamped logical offset only to
    // choose a safe mounted-row window.
    final visualScrollOffset = scrollCoordinator.liveVerticalOffset;
    final logicalScrollOffset = visualScrollOffset
        .clamp(0.0, maxContentOffset)
        .toDouble();
    final firstVisibleRow = rowHeight <= 0 || rowsLength == 0
        ? 0
        : rowIndexAtOffset(logicalScrollOffset);
    final firstMountedRow = firstVisibleRow > 0 ? firstVisibleRow - 1 : 0;
    final lastVisibleRow = rowHeight <= 0 || rowsLength == 0
        ? rowsLength - 1
        : rowIndexAtOffset(logicalScrollOffset + resolvedViewportHeight);
    final lastMountedRow = math.min(rowsLength, lastVisibleRow + 3);
    final firstMountedRowTop = rowTopAt(firstMountedRow) - visualScrollOffset;

    return FdcGridVerticalLayoutSnapshot(
      viewportHeight: resolvedViewportHeight,
      contentHeight: contentHeight,
      scrollOffset: visualScrollOffset,
      firstMountedRow: firstMountedRow,
      lastMountedRow: lastMountedRow,
      firstMountedRowTop: firstMountedRowTop,
    );
  }
}

class FdcGridViewportCallbacks {
  const FdcGridViewportCallbacks({
    required this.onPointerSignal,
    required this.onRangePointerCellChanged,
    required this.onRangeDragStart,
    required this.onRangeDragUpdate,
    required this.onRangeDragEnd,
    required this.onRangeOverlayDismiss,
    required this.onRangeSelectionCopy,
    required this.onRangeSelectionPaste,
    required this.onColumnScrollUpdate,
    required this.onColumnScrollEnd,
    required this.onRowScrollStart,
    required this.onRowScrollUpdate,
    required this.onRowScrollEnd,
    required this.onBodyVerticalDragStart,
    required this.onBodyVerticalDragUpdate,
    required this.onBodyVerticalDragEnd,
    required this.onHeaderHorizontalDragStart,
    required this.onHeaderHorizontalDragUpdate,
    required this.onHeaderHorizontalDragEnd,
    required this.onColumnResizeStart,
    required this.onColumnResizeUpdate,
    required this.onColumnResizeEnd,
    required this.buildHeader,
    required this.buildRow,
    required this.buildRowIndicatorRegionHeader,
    required this.buildRowIndicatorRegionRow,
    required this.buildDetailRow,
    required this.onDetailRowSizeChanged,
  });

  final void Function(PointerSignalEvent event) onPointerSignal;
  final void Function(int? rowIndex, int? columnIndex)
  onRangePointerCellChanged;
  final void Function(int rowIndex, int columnIndex) onRangeDragStart;
  final void Function(int rowIndex, int columnIndex) onRangeDragUpdate;
  final void Function() onRangeDragEnd;
  final void Function() onRangeOverlayDismiss;
  final VoidCallback onRangeSelectionCopy;
  final VoidCallback onRangeSelectionPaste;
  final bool Function(ScrollUpdateNotification notification)
  onColumnScrollUpdate;
  final bool Function(ScrollEndNotification notification) onColumnScrollEnd;
  final bool Function(ScrollStartNotification notification) onRowScrollStart;
  final bool Function(ScrollUpdateNotification notification) onRowScrollUpdate;
  final bool Function(ScrollEndNotification notification) onRowScrollEnd;
  final void Function() onBodyVerticalDragStart;
  final void Function(DragUpdateDetails details) onBodyVerticalDragUpdate;
  final void Function(DragEndDetails? details) onBodyVerticalDragEnd;
  final void Function() onHeaderHorizontalDragStart;
  final void Function(double deltaX) onHeaderHorizontalDragUpdate;
  final void Function() onHeaderHorizontalDragEnd;
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
  final Widget Function(
    BuildContext context,
    FdcGridColumnBandLayout columnLayout,
  )
  buildHeader;
  final Widget Function(
    BuildContext context,
    FdcGridColumnBandLayout columnLayout,
    int rowIndex,
    FdcValueFormatter valueFormatter,
  )
  buildRow;
  final Widget Function(BuildContext context, double width)
  buildRowIndicatorRegionHeader;
  final Widget Function(BuildContext context, int rowIndex, double width)
  buildRowIndicatorRegionRow;
  final Widget Function(BuildContext context, int rowIndex) buildDetailRow;
  final void Function(int rowIndex, Size size) onDetailRowSizeChanged;
}
