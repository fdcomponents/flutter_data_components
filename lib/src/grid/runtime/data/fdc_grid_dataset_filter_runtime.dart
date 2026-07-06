// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateDatasetFilterRuntime on _FdcGridState {
  List<FdcDataSetFilter> _resolvedHeaderDataSetFilters() {
    final result = <FdcDataSetFilter>[];

    if (!_columnFilteringAllowed || !_hasHeaderFilterState) {
      return result;
    }

    // Header filter state is scoped to the runtime grid column. This allows two
    // visual columns bound to the same dataset field to keep independent header
    // filter editor state while still producing field-based dataset filters.
    for (
      var columnIndex = 0;
      columnIndex < _visibleColumnsCache.length;
      columnIndex++
    ) {
      final column = _visibleColumnsCache[columnIndex];
      if (!column.filterEnabled) {
        continue;
      }
      final runtimeColumnId = _runtimeColumnIdAt(columnIndex);
      if (runtimeColumnId == null) {
        continue;
      }
      result.addAll(_headerDataSetFiltersForColumn(column, runtimeColumnId));
    }

    return result;
  }

  List<FdcDataSetFilter> _headerDataSetFiltersForColumn(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  ) {
    final state = _headerFilterStateFor(column, runtimeColumnId);

    // Do not turn a column's default operator into an active filter.
    // This is especially important for boolean columns where the default
    // operator is usually `isTrue` and ignores the filter value. When another
    // header filter is active, all filterable columns are inspected; without
    // this guard every untouched boolean column would silently become an
    // `isTrue` filter.
    if (!state.hasState) {
      return const <FdcDataSetFilter>[];
    }

    final operator = state.operator;
    final value = state.value;
    final columnFormatSettings = column.formatSettings;
    final dataType = _fieldDataTypeFor(column);
    final valueResolver = _dataSetValueResolverFor(column);
    final caseSensitive = column.filterConfig?.caseSensitive ?? false;

    if (operator == FdcFilterOperator.between && value is FdcFilterRangeValue) {
      final from = _parseHeaderFilterValue(
        column,
        value.from,
        runtimeColumnId: runtimeColumnId,
      );
      final to = _parseHeaderFilterValue(
        column,
        value.to,
        runtimeColumnId: runtimeColumnId,
      );
      if (from == null || to == null) {
        return const <FdcDataSetFilter>[];
      }

      // Represent the inclusive range as two primitive predicates. This keeps
      // paged adapters compatible without introducing a second adapter value.
      return <FdcDataSetFilter>[
        FdcDataSetFilter(
          fieldName: column.fieldName,
          operator: FdcFilterOperator.greaterThanOrEqual,
          value: from,
          caseSensitive: caseSensitive,
          dataType: dataType,
          formatSettings: columnFormatSettings,
          valueResolver: valueResolver,
        ),
        FdcDataSetFilter(
          fieldName: column.fieldName,
          operator: FdcFilterOperator.lessThanOrEqual,
          value: to,
          caseSensitive: caseSensitive,
          dataType: dataType,
          formatSettings: columnFormatSettings,
          valueResolver: valueResolver,
        ),
      ];
    }

    final preparedValue = _parseHeaderFilterValue(
      column,
      value,
      runtimeColumnId: runtimeColumnId,
    );
    if (!_operatorIgnoresValue(operator) && preparedValue == null) {
      return const <FdcDataSetFilter>[];
    }

    return <FdcDataSetFilter>[
      FdcDataSetFilter(
        fieldName: column.fieldName,
        operator: operator,
        value: preparedValue,
        caseSensitive: caseSensitive,
        dataType: dataType,
        formatSettings: columnFormatSettings,
        valueResolver: valueResolver,
      ),
    ];
  }
}
