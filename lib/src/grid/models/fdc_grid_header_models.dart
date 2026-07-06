// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show ValueListenable, VoidCallback, immutable;
import 'package:flutter/material.dart';

import '../../common/theme/fdc_grid_styles.dart';
import '../../data/fdc_data.dart';
import '../columns/fdc_grid_columns.dart';
import '../core/fdc_grid_core.dart';
import 'fdc_column_identity.dart';
import 'fdc_grid_layout_models.dart';

class FdcGridHeaderModel {
  const FdcGridHeaderModel({
    required this.geometries,
    required this.columns,
    required this.columnWidths,
    required this.columnOffsets,
    required this.contentWidth,
    required this.runtimeColumnIds,
    required this.columnIndexes,
    required this.resizeTargetLocalColumnIndexes,
    required this.resizeTargetColumns,
    required this.resizeTargetRuntimeColumnIds,
    required this.resizeTargetColumnIndexes,
    required this.resizeDeltaFactors,
    required this.columnGroupCells,
    required this.groupHeaderHeight,
    required this.groupHeaderBackgroundColor,
    required this.groupHeaderTextStyle,
    required this.groupHeaderAlignment,
    required this.groupHeaderPadding,
    required this.groupHeaderBottomSeparatorColor,
    required this.groupHeaderVerticalSeparatorColor,
    required this.groupHeaderSeparatorTopInset,
    required this.groupHeaderSeparatorBottomInset,
    required this.options,
    required this.rowIndicator,
    required this.filterOptions,
    required this.mainMenuInToolbar,
    required this.height,
    required this.filterRowHeight,
    required this.showsFilterRow,
    required this.headerBackgroundColor,
    required this.headerSeparatorColor,
    required this.horizontalGridLineColor,
    required this.verticalGridLineColor,
    required this.showVerticalGridLines,
    required this.headerTextStyle,
    required this.headerFilterStyle,
    required this.controlsStyle,
    required this.headerSeparatorTopInset,
    required this.headerSeparatorBottomInset,
    required this.fullHeightTrailingSeparator,
    required this.headerFilterResetGeneration,
    required this.headerFilterRangeAutoOpenGeneration,
    required this.rangeAutoOpenColumnId,
    required this.headerFilterValues,
    required this.draggingColumnIndex,
    required this.invalidColumnDropTargetHovering,
    required this.invalidColumnDropTargetHoverListenable,
    required this.resizingRuntimeColumnId,
    required this.resizingDeltaFactor,
    required this.visibleColumnCount,
    required this.suppressTrailingEdgeAffordances,
    required this.suppressTrailingSeparator,
  });

  final List<FdcGridColumnGeometry> geometries;
  final List<FdcGridColumn<dynamic>> columns;
  final List<double> columnWidths;
  final List<double> columnOffsets;
  final double contentWidth;
  final List<FdcColumnIdentity> runtimeColumnIds;
  final List<int> columnIndexes;
  final List<int?> resizeTargetLocalColumnIndexes;
  final List<FdcGridColumn<dynamic>?> resizeTargetColumns;
  final List<FdcColumnIdentity?> resizeTargetRuntimeColumnIds;
  final List<int?> resizeTargetColumnIndexes;
  final List<double> resizeDeltaFactors;
  final List<FdcGridColumnGroupCell> columnGroupCells;
  final double groupHeaderHeight;
  final Color groupHeaderBackgroundColor;
  final TextStyle? groupHeaderTextStyle;
  final Alignment groupHeaderAlignment;
  final EdgeInsetsGeometry groupHeaderPadding;
  final Color groupHeaderBottomSeparatorColor;
  final Color groupHeaderVerticalSeparatorColor;
  final double groupHeaderSeparatorTopInset;
  final double groupHeaderSeparatorBottomInset;
  final FdcGridOptions options;
  final FdcGridRowIndicator rowIndicator;
  final FdcGridFilterOptions filterOptions;
  final bool mainMenuInToolbar;
  final double height;
  final double filterRowHeight;
  final bool showsFilterRow;
  final Color headerBackgroundColor;
  final Color headerSeparatorColor;
  final Color horizontalGridLineColor;
  final Color verticalGridLineColor;
  final bool showVerticalGridLines;

  Color get effectiveVerticalGridLineColor =>
      showVerticalGridLines ? verticalGridLineColor : Colors.transparent;
  final TextStyle? headerTextStyle;
  final FdcGridHeaderFilterStyle headerFilterStyle;
  final FdcGridControlsStyle controlsStyle;
  final double headerSeparatorTopInset;
  final double headerSeparatorBottomInset;
  final bool fullHeightTrailingSeparator;
  final int headerFilterResetGeneration;
  final int headerFilterRangeAutoOpenGeneration;
  final FdcColumnIdentity? rangeAutoOpenColumnId;
  final Map<FdcColumnIdentity, Object?> headerFilterValues;
  final int? draggingColumnIndex;
  final bool invalidColumnDropTargetHovering;
  final ValueListenable<bool> invalidColumnDropTargetHoverListenable;
  final FdcColumnIdentity? resizingRuntimeColumnId;
  final double? resizingDeltaFactor;
  final int visibleColumnCount;
  final bool suppressTrailingEdgeAffordances;
  final bool suppressTrailingSeparator;

  bool get columnDragActive => draggingColumnIndex != null;

  bool get interactionLocked =>
      columnDragActive || resizingRuntimeColumnId != null;

  bool suppressTrailingEdgeAt(int localColumnIndex) {
    return suppressTrailingEdgeAffordances &&
        localColumnIndex == visibleColumnCount - 1;
  }

  bool suppressTrailingSeparatorAt(int localColumnIndex) {
    return (suppressTrailingEdgeAffordances || suppressTrailingSeparator) &&
        localColumnIndex == visibleColumnCount - 1;
  }

  bool get hasColumnGroups =>
      groupHeaderHeight > 0 && columnGroupCells.isNotEmpty;

  bool get showMainMenuInHeader => !mainMenuInToolbar;

  bool get showMainMenuInColumnMenu =>
      !rowIndicator.visible && !mainMenuInToolbar;

  double get leafHeaderHeight =>
      math.max(0.0, height - (hasColumnGroups ? groupHeaderHeight : 0.0));

  double columnWidthAt(int columnIndex, {required double fallbackWidth}) {
    if (columnIndex < 0 || columnIndex >= columnWidths.length) {
      return fallbackWidth;
    }
    return columnWidths[columnIndex];
  }

  double columnOffsetAt(int columnIndex, {required double fallbackWidth}) {
    if (columnIndex < 0) {
      return 0.0;
    }
    if (columnIndex < columnOffsets.length) {
      return columnOffsets[columnIndex];
    }
    if (columnIndex == columnOffsets.length) {
      return contentWidth;
    }
    return contentWidth + (columnIndex - columnOffsets.length) * fallbackWidth;
  }

  FdcColumnIdentity? runtimeColumnIdAt(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= runtimeColumnIds.length) {
      return null;
    }
    return runtimeColumnIds[columnIndex];
  }

  int sourceColumnIndexAt(int localColumnIndex) {
    if (localColumnIndex < 0 || localColumnIndex >= columnIndexes.length) {
      return localColumnIndex;
    }
    return columnIndexes[localColumnIndex];
  }

  int? resizeTargetLocalColumnIndexAt(int localColumnIndex) {
    if (localColumnIndex < 0 ||
        localColumnIndex >= resizeTargetLocalColumnIndexes.length) {
      return null;
    }
    return resizeTargetLocalColumnIndexes[localColumnIndex];
  }

  FdcGridColumn<dynamic>? resizeTargetColumnAt(int localColumnIndex) {
    if (localColumnIndex < 0 ||
        localColumnIndex >= resizeTargetColumns.length) {
      return null;
    }
    return resizeTargetColumns[localColumnIndex];
  }

  FdcColumnIdentity? resizeTargetRuntimeColumnIdAt(int localColumnIndex) {
    if (localColumnIndex < 0 ||
        localColumnIndex >= resizeTargetRuntimeColumnIds.length) {
      return null;
    }
    return resizeTargetRuntimeColumnIds[localColumnIndex];
  }

  int? resizeTargetColumnIndexAt(int localColumnIndex) {
    if (localColumnIndex < 0 ||
        localColumnIndex >= resizeTargetColumnIndexes.length) {
      return null;
    }
    return resizeTargetColumnIndexes[localColumnIndex];
  }

  double resizeDeltaFactorAt(int localColumnIndex) {
    if (localColumnIndex < 0 || localColumnIndex >= resizeDeltaFactors.length) {
      return 1.0;
    }
    return resizeDeltaFactors[localColumnIndex];
  }

  List<int> sourceColumnIndexesInRange(int startLocalIndex, int columnSpan) {
    final indexes = <int>[];
    final endLocalIndex = math.min(
      columnIndexes.length,
      math.max(0, startLocalIndex + columnSpan),
    );
    for (
      var index = math.max(0, startLocalIndex);
      index < endLocalIndex;
      index++
    ) {
      indexes.add(sourceColumnIndexAt(index));
    }
    return List<int>.unmodifiable(indexes);
  }

  List<FdcColumnIdentity> runtimeColumnIdsInRange(
    int startLocalIndex,
    int columnSpan,
  ) {
    final ids = <FdcColumnIdentity>[];
    final endLocalIndex = math.min(
      runtimeColumnIds.length,
      math.max(0, startLocalIndex + columnSpan),
    );
    for (
      var index = math.max(0, startLocalIndex);
      index < endLocalIndex;
      index++
    ) {
      ids.add(runtimeColumnIds[index]);
    }
    return List<FdcColumnIdentity>.unmodifiable(ids);
  }
}

@immutable
class FdcGridColumnGroupCell {
  const FdcGridColumnGroupCell({
    required this.label,
    required this.style,
    required this.startLocalColumnIndex,
    required this.columnSpan,
    required this.left,
    required this.width,
    required this.labelLeftOffset,
    required this.labelWidth,
    int? resizeStartLocalColumnIndex,
    int? resizeColumnSpan,
  }) : resizeStartLocalColumnIndex =
           resizeStartLocalColumnIndex ?? startLocalColumnIndex,
       resizeColumnSpan = resizeColumnSpan ?? columnSpan;

  final String label;
  final FdcGridColumnGroupStyle style;
  final int startLocalColumnIndex;
  final int columnSpan;
  final double left;
  final double width;

  /// Horizontal offset of the full group label area relative to this visible
  /// clipped group segment.
  ///
  /// Virtualized group headers may render only the currently visible part of a
  /// larger group. The label still needs to be aligned inside the full group
  /// span so it does not re-center inside each clipped segment while the user
  /// scrolls horizontally.
  final double labelLeftOffset;

  /// Width of the full group label area used for label alignment.
  final double labelWidth;
  final int resizeStartLocalColumnIndex;
  final int resizeColumnSpan;

  int get trailingLocalColumnIndex => startLocalColumnIndex + columnSpan - 1;
}

class FdcGridHeaderCallbacks {
  const FdcGridHeaderCallbacks({
    required this.columnLabelOf,
    required this.sortIconOf,
    required this.sortIconColorOf,
    required this.onHeaderSortTap,
    required this.onHeaderSortAscending,
    required this.onHeaderSortDescending,
    required this.onHeaderAddSortAscending,
    required this.onHeaderAddSortDescending,
    required this.onHeaderClearSort,
    required this.onHeaderClearAllSorts,
    required this.hasGridLayoutChanges,
    required this.onResetGridLayout,
    required this.hasUserPinnedColumns,
    required this.onUnpinAllUserColumns,
    required this.canHeaderSort,
    required this.canChangeView,
    required this.headerSortCount,
    required this.hasDataSetSortState,
    required this.headerSortPosition,
    required this.isHeaderSortAscending,
    required this.isHeaderSortDescending,
    required this.isHeaderSortActive,
    required this.headerColumnPinOf,
    required this.onSetHeaderColumnPin,
    required this.canHeaderColumnPin,
    required this.canMoveColumn,
    required this.onColumnDragHoverTarget,
    required this.onColumnDragStarted,
    required this.onColumnDragEnded,
    required this.onColumnDragInvalidTargetHoverChanged,
    required this.onColumnResizeStart,
    required this.onColumnResizeUpdate,
    required this.onColumnResizeEnd,
    required this.onColumnGroupResizeStart,
    required this.onColumnGroupResizeUpdate,
    required this.onColumnGroupResizeEnd,
    required this.headerFilterFocusNodeOf,
    required this.onFocusHeaderFilterField,
    required this.onFocusNextHeaderFilter,
    required this.onFocusGridCellFromHeaderFilter,
    required this.onSetHeaderFilterTextValue,
    required this.onSetHeaderFilterValue,
    required this.parseHeaderFilterValue,
    required this.formatHeaderFilterValue,
    required this.onCancelHeaderFilterDebounce,
    required this.onSetHeaderFilterOperator,
    required this.onRangeAutoOpenHandled,
    required this.onCancelHeaderFilterRangeEdit,
    required this.onClearHeaderFilter,
    required this.onClearFocusedCell,
    required this.onOpenHeaderMenu,
    required this.canOpenFilterMenu,
    required this.onOpenFilterMenu,
    required this.selectAllRowIndicatorValue,
    required this.canSelectAllRows,
    required this.onSelectAllRows,
    required this.rowSelectionFilterValue,
    required this.hasRowSelectionControls,
    required this.onSetRowSelectionFilter,
    required this.hasHeaderFilterState,
    required this.headerFilterStateCount,
    required this.onClearHeaderFilters,
    required this.canToggleColumnFilters,
    required this.columnFiltersVisible,
    required this.onToggleColumnFilters,
    required this.headerFilterOperatorOf,
    required this.hasHeaderFilterStateForColumn,
    required this.isHeaderFilterActive,
    required this.operatorsForColumn,
    required this.headerFilterOptions,
    required this.filterOperatorLabel,
    required this.filterIconColorOf,
    required this.headerFilterTextStyleOf,
    required this.dataTypeOf,
    required this.decimalScaleOf,
    required this.decimalPrecisionOf,
  });

  final String Function(FdcGridColumn<dynamic> column) columnLabelOf;
  final IconData? Function(int columnIndex) sortIconOf;
  final Color Function(BuildContext context, int columnIndex) sortIconColorOf;
  final void Function(int columnIndex) onHeaderSortTap;
  final void Function(int columnIndex) onHeaderSortAscending;
  final void Function(int columnIndex) onHeaderSortDescending;
  final void Function(int columnIndex) onHeaderAddSortAscending;
  final void Function(int columnIndex) onHeaderAddSortDescending;
  final void Function(int columnIndex) onHeaderClearSort;
  final VoidCallback onHeaderClearAllSorts;
  final bool Function() hasGridLayoutChanges;
  final VoidCallback onResetGridLayout;
  final bool Function() hasUserPinnedColumns;
  final VoidCallback onUnpinAllUserColumns;
  final bool Function(int columnIndex) canHeaderSort;
  final bool Function() canChangeView;
  final int Function() headerSortCount;
  final bool Function() hasDataSetSortState;
  final int Function(int columnIndex) headerSortPosition;
  final bool Function(int columnIndex) isHeaderSortAscending;
  final bool Function(int columnIndex) isHeaderSortDescending;
  final bool Function(int columnIndex) isHeaderSortActive;
  final FdcGridColumnPin Function(int columnIndex) headerColumnPinOf;
  final void Function(int columnIndex, FdcGridColumnPin pin)
  onSetHeaderColumnPin;
  final bool Function(int columnIndex) canHeaderColumnPin;
  final bool Function(int fromIndex, int toIndex) canMoveColumn;
  final void Function(int targetColumnIndex) onColumnDragHoverTarget;
  final void Function(int columnIndex) onColumnDragStarted;
  final void Function(int columnIndex) onColumnDragEnded;
  final void Function(bool hovering) onColumnDragInvalidTargetHoverChanged;
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
  final void Function(
    List<int> columnIndexes,
    List<FdcColumnIdentity> runtimeColumnIds,
    FdcColumnIdentity resizeRuntimeColumnId,
    double globalX,
    double deltaFactor,
  )
  onColumnGroupResizeStart;
  final void Function(
    List<int> columnIndexes,
    List<FdcColumnIdentity> runtimeColumnIds,
    FdcColumnIdentity resizeRuntimeColumnId,
    double globalX,
    double deltaFactor,
  )
  onColumnGroupResizeUpdate;
  final void Function(FdcColumnIdentity resizeRuntimeColumnId)
  onColumnGroupResizeEnd;

  final FocusNode Function(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  )
  headerFilterFocusNodeOf;
  final void Function(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  )
  onFocusHeaderFilterField;
  final void Function(
    FdcColumnIdentity runtimeColumnId, {
    required bool forward,
  })
  onFocusNextHeaderFilter;
  final void Function(FdcColumnIdentity runtimeColumnId)
  onFocusGridCellFromHeaderFilter;
  final void Function(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
    String value, {
    required bool submitted,
  })
  onSetHeaderFilterTextValue;
  final void Function(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
    Object? value,
  )
  onSetHeaderFilterValue;
  final Object? Function(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
    Object? value,
  )
  parseHeaderFilterValue;
  final String Function(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
    Object? value,
  )
  formatHeaderFilterValue;
  final VoidCallback onCancelHeaderFilterDebounce;
  final void Function(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
    FdcFilterOperator operator,
  )
  onSetHeaderFilterOperator;
  final void Function(FdcColumnIdentity runtimeColumnId) onRangeAutoOpenHandled;
  final void Function(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  )
  onCancelHeaderFilterRangeEdit;
  final void Function(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  )
  onClearHeaderFilter;
  final VoidCallback onClearFocusedCell;
  final bool Function() onOpenHeaderMenu;
  final bool Function() canOpenFilterMenu;
  final bool Function() onOpenFilterMenu;

  final bool? Function() selectAllRowIndicatorValue;
  final bool Function() canSelectAllRows;
  final void Function(bool selected) onSelectAllRows;
  final bool? Function() rowSelectionFilterValue;
  final bool Function() hasRowSelectionControls;
  final void Function(bool? selected) onSetRowSelectionFilter;
  final bool Function() hasHeaderFilterState;
  final int Function() headerFilterStateCount;
  final VoidCallback onClearHeaderFilters;
  final bool Function() canToggleColumnFilters;
  final bool Function() columnFiltersVisible;
  final VoidCallback onToggleColumnFilters;

  final FdcFilterOperator Function(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  )
  headerFilterOperatorOf;
  final bool Function(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  )
  hasHeaderFilterStateForColumn;
  final bool Function(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  )
  isHeaderFilterActive;
  final List<FdcFilterOperator> Function(FdcGridColumn<dynamic> column)
  operatorsForColumn;
  final List<FdcOption<Object?>> Function(
    BuildContext context,
    FdcGridColumn<dynamic> column,
  )
  headerFilterOptions;
  final String Function(FdcFilterOperator operator) filterOperatorLabel;
  final Color Function(BuildContext context, {required bool active})
  filterIconColorOf;
  final TextStyle Function(BuildContext context) headerFilterTextStyleOf;
  final FdcDataType Function(FdcGridColumn<dynamic> column) dataTypeOf;
  final int? Function(FdcGridColumn<dynamic> column) decimalScaleOf;
  final int? Function(FdcGridColumn<dynamic> column) decimalPrecisionOf;
}
