// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:async';

import '../fdc_data_adapter.dart';
import '../fdc_data_errors.dart';
import '../fdc_dataset_filter.dart';
import '../fdc_dataset_search.dart';
import '../fdc_field_def.dart';
import '../fdc_filter_operator.dart';

/// Internal owner of dataset lifecycle orchestration and stale-result state.
///
/// The dataset remains the public facade and owns row/schema commit, callbacks,
/// work reporting, and listener notifications. This coordinator owns the
/// lifecycle entry-point routing plus generation/disposal bookkeeping.
final class FdcDataSetLifecycleCoordinator {
  FdcDataSetLifecycleCoordinator({
    required void Function(FdcDataLoadRequest request) openCore,
    required Future<void> Function(FdcDataLoadRequest request) openFutureCore,
    required void Function(List<Map<String, Object?>> rows) loadRowsCore,
    required Future<void> Function(FutureOr<List<Map<String, Object?>>> rows)
    loadRowsFutureCore,
    required void Function() closeCore,
  }) : _openCore = openCore,
       _openFutureCore = openFutureCore,
       _loadRowsCore = loadRowsCore,
       _loadRowsFutureCore = loadRowsFutureCore,
       _closeCore = closeCore;

  final void Function(FdcDataLoadRequest request) _openCore;
  final Future<void> Function(FdcDataLoadRequest request) _openFutureCore;
  final void Function(List<Map<String, Object?>> rows) _loadRowsCore;
  final Future<void> Function(FutureOr<List<Map<String, Object?>>> rows)
  _loadRowsFutureCore;
  final void Function() _closeCore;

  int _generation = 0;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  void openSync({FdcDataLoadRequest request = const FdcDataLoadRequest()}) {
    _ensureNotDisposed();
    _openCore(request);
  }

  Future<void> open({FdcDataLoadRequest request = const FdcDataLoadRequest()}) {
    _ensureNotDisposed();
    return _openFutureCore(request);
  }

  void loadRowsSync(List<Map<String, Object?>> rows) {
    _ensureNotDisposed();
    _loadRowsCore(rows);
  }

  Future<void> loadRows(FutureOr<List<Map<String, Object?>>> rows) {
    _ensureNotDisposed();
    return _loadRowsFutureCore(rows);
  }

  void close() {
    _ensureNotDisposed();
    _closeCore();
  }

  void commitLoadedResult({
    required FdcDataLoadResult result,
    required void Function(FdcDataLoadResult result) adoptFields,
    required void Function(
      List<Map<String, Object?>> rows, {
      List<int>? internalRowIds,
      int? internalNextRowId,
    })
    replaceRows,
    required void Function() rebuildView,
    required void Function(int? totalRecordCount) setTotalRecordCount,
    required int Function() readRecordCount,
    required void Function(int index) setCurrentIndex,
    required void Function(bool value) setEof,
    required void Function() clearEditBuffer,
  }) {
    adoptFields(result);
    replaceRows(
      result.rows,
      internalRowIds: result.internalRowIds,
      internalNextRowId: result.internalNextRowId,
    );
    rebuildView();
    setTotalRecordCount(result.totalCount);
    final recordCount = readRecordCount();
    setCurrentIndex(recordCount > 0 ? 0 : -1);
    setEof(recordCount == 0);
    clearEditBuffer();
  }

  void commitAdapterLoadResult({
    required FdcDataLoadResult result,
    required bool pagingEnabled,
    required bool requireTotalCount,
    required bool appendPage,
    required int? pageIndex,
    required int? pageSize,
    required int defaultPageSize,
    required int previousIndex,
    required bool preserveTotalCount,
    required void Function(FdcDataLoadResult result) adoptFields,
    required void Function(
      List<Map<String, Object?>> rows, {
      List<int>? internalRowIds,
      int? internalNextRowId,
    })
    appendRows,
    required void Function(
      List<Map<String, Object?>> rows, {
      List<int>? internalRowIds,
      int? internalNextRowId,
      required bool adapterQueryChanged,
    })
    replaceRows,
    required void Function() syncLoadedSelection,
    required void Function(FdcDataLoadResult result)
    applyPagedUnselectedLocalFilter,
    required void Function({
      required int pageIndex,
      required int pageSize,
      required int loadedRecordCount,
      required int? totalRecordCount,
      required Object? previousPageCursor,
      required Object? nextPageCursor,
      required bool appendPage,
      required bool preserveTotalCount,
    })
    commitPaging,
    required int Function(int currentIndex) rebuildAdapterPageView,
    required void Function() rebuildLocalView,
    required void Function(int? totalRecordCount) setTotalRecordCount,
    required int Function() readRecordCount,
    required void Function(int index) setCurrentIndex,
    required void Function(bool value) setEof,
    required void Function({required bool invalidateAggregateCache})
    clearEditBuffer,
    required void Function() invalidateAggregateCache,
  }) {
    if (pagingEnabled && requireTotalCount && result.totalCount == null) {
      throw const FdcDataSetException(
        message:
            'Paged dataset requires adapter totalCount, '
            'but the adapter returned null.',
      );
    }

    adoptFields(result);
    if (appendPage) {
      appendRows(
        result.rows,
        internalRowIds: result.internalRowIds,
        internalNextRowId: result.internalNextRowId,
      );
    } else {
      replaceRows(
        result.rows,
        internalRowIds: result.internalRowIds,
        internalNextRowId: result.internalNextRowId,
        adapterQueryChanged: !pagingEnabled,
      );
    }

    if (pagingEnabled) {
      syncLoadedSelection();
      applyPagedUnselectedLocalFilter(result);
      commitPaging(
        pageIndex: pageIndex ?? 0,
        pageSize: pageSize ?? defaultPageSize,
        loadedRecordCount: result.rows.length,
        totalRecordCount: result.totalCount,
        previousPageCursor: result.previousPageCursor,
        nextPageCursor: result.nextPageCursor,
        appendPage: appendPage,
        preserveTotalCount: preserveTotalCount,
      );
      setCurrentIndex(rebuildAdapterPageView(appendPage ? previousIndex : -1));
    } else {
      rebuildLocalView();
      setTotalRecordCount(result.totalCount);
      setCurrentIndex(readRecordCount() > 0 ? 0 : -1);
    }

    setEof(appendPage ? false : readRecordCount() == 0);
    if (appendPage) {
      invalidateAggregateCache();
    } else {
      clearEditBuffer(invalidateAggregateCache: !pagingEnabled);
    }
  }

  FdcDataLoadRequest effectiveAdapterLoadRequest({
    required IFdcDataAdapter? adapter,
    required FdcDataLoadRequest request,
  }) {
    final filters = effectiveAdapterFilters(
      adapter: adapter,
      filters: request.filters,
    );
    final sorts = effectiveAdapterSorts(adapter: adapter, sorts: request.sorts);
    if (identical(filters, request.filters) &&
        identical(sorts, request.sorts)) {
      return request;
    }
    return request.copyWith(filters: filters, sorts: sorts);
  }

  List<FdcDataAdapterFilter> effectiveAdapterFilters({
    required IFdcDataAdapter? adapter,
    required List<FdcDataAdapterFilter> filters,
  }) {
    final sourceFilters = adapter is FdcDataAdapter
        ? adapter.filters
        : const <FdcDataAdapterFilter>[];
    if (sourceFilters.isEmpty) {
      return filters;
    }
    if (filters.isEmpty) {
      return sourceFilters;
    }
    return <FdcDataAdapterFilter>[...sourceFilters, ...filters];
  }

  List<FdcDataAdapterSort> effectiveAdapterSorts({
    required IFdcDataAdapter? adapter,
    required List<FdcDataAdapterSort> sorts,
  }) {
    if (sorts.isNotEmpty) {
      return sorts;
    }
    if (adapter is! FdcDataAdapter || adapter.sorts.isEmpty) {
      return const <FdcDataAdapterSort>[];
    }
    return adapter.sorts;
  }

  FdcDataLoadRequest pagedLoadRequest({
    required IFdcDataAdapter? adapter,
    required FdcDataLoadRequest request,
    required int pageIndex,
    required int pageSize,
    required List<FdcDataSetFilter> viewFilters,
    required List<FdcDataSetSort> viewSorts,
    required FdcDataSetSearchState viewSearch,
    required bool? selectedFilter,
    required List<FdcFieldDef> fields,
    required bool requireTotalCount,
    required List<FdcDataRecordKey> selectedKeys,
  }) {
    final requestFilters = request.filters.isEmpty
        ? adapterFiltersFromView(viewFilters)
        : request.filters;
    final requestSorts = request.sorts.isEmpty
        ? adapterSortsFromView(viewSorts)
        : request.sorts;
    final requestSearch = request.search.isActive ? request.search : viewSearch;

    return effectiveAdapterLoadRequest(
      adapter: adapter,
      request: request.copyWith(
        filters: requestFilters,
        sorts: requestSorts,
        search: requestSearch,
        offset: pageIndex * pageSize,
        limit: pageSize,
        includeFields: fields.isEmpty,
        includeTotalCount: requireTotalCount || !requestSearch.isActive,
        fields: fields,
        selectedKeysOnly: selectedFilter == true,
        selectedKeys: selectedFilter == true
            ? selectedKeys
            : const <FdcDataRecordKey>[],
      ),
    );
  }

  void validateAdapterLoadRequest({
    required IFdcDataAdapter adapter,
    required FdcDataLoadRequest request,
    required bool pagingEnabled,
    required bool requireTotalCount,
  }) {
    request.validatePagingContract();
    final capabilities = adapter.capabilities;
    final unsupported = <String>{};

    if (request.filters.isNotEmpty && !capabilities.filtering) {
      unsupported.add('filtering');
    }
    if (request.sorts.isNotEmpty && !capabilities.sorting) {
      unsupported.add('sorting');
    }
    if (request.search.isActive && !capabilities.search) {
      unsupported.add('search');
    }
    if ((request.offset != null || request.limit != null) &&
        !capabilities.paging) {
      unsupported.add('paging');
    }
    if (pagingEnabled && !capabilities.paging) {
      unsupported.add('dataset paging');
    }
    if (pagingEnabled && requireTotalCount && !capabilities.totalCount) {
      unsupported.add('total count');
    }
    if (request.selectedKeysOnly && !capabilities.selectedKeyFiltering) {
      unsupported.add('selected-key filtering');
    }

    if (unsupported.isEmpty) {
      return;
    }

    final adapterName = adapter.runtimeType.toString();
    throw FdcDataAdapterException(
      operation: 'load',
      code: 'unsupported_adapter_operation',
      message:
          '$adapterName does not support ${unsupported.join(', ')}. '
          'Use an adapter variant that supports these adapter-side query '
          'operations or disable dataset paging/filtering/sorting for this '
          'adapter.',
    );
  }

  List<FdcDataAdapterFilter> adapterFiltersFromView(
    List<FdcDataSetFilter> filters,
  ) {
    if (filters.isEmpty) {
      return const <FdcDataAdapterFilter>[];
    }
    return <FdcDataAdapterFilter>[
      for (final filter in filters) adapterFilterFromViewFilter(filter),
    ];
  }

  FdcDataAdapterFilter adapterFilterFromViewFilter(FdcDataSetFilter filter) {
    FdcDataAdapterFilterOperator operator;
    Object? value = filter.value;
    switch (filter.operator) {
      case FdcFilterOperator.equals:
      case FdcFilterOperator.isTrue:
      case FdcFilterOperator.isFalse:
        operator = FdcDataAdapterFilterOperator.equals;
        if (filter.operator == FdcFilterOperator.isTrue) {
          value = true;
        } else if (filter.operator == FdcFilterOperator.isFalse) {
          value = false;
        }
        break;
      case FdcFilterOperator.notEquals:
        operator = FdcDataAdapterFilterOperator.notEquals;
        break;
      case FdcFilterOperator.contains:
        operator = FdcDataAdapterFilterOperator.contains;
        break;
      case FdcFilterOperator.startsWith:
        operator = FdcDataAdapterFilterOperator.startsWith;
        break;
      case FdcFilterOperator.endsWith:
        operator = FdcDataAdapterFilterOperator.endsWith;
        break;
      case FdcFilterOperator.greaterThan:
        operator = FdcDataAdapterFilterOperator.greaterThan;
        break;
      case FdcFilterOperator.greaterThanOrEqual:
        operator = FdcDataAdapterFilterOperator.greaterThanOrEqual;
        break;
      case FdcFilterOperator.lessThan:
        operator = FdcDataAdapterFilterOperator.lessThan;
        break;
      case FdcFilterOperator.lessThanOrEqual:
        operator = FdcDataAdapterFilterOperator.lessThanOrEqual;
        break;
      case FdcFilterOperator.isEmpty:
        operator = FdcDataAdapterFilterOperator.isEmpty;
        break;
      case FdcFilterOperator.isNotEmpty:
        operator = FdcDataAdapterFilterOperator.isNotEmpty;
        break;
      case FdcFilterOperator.isNull:
        operator = FdcDataAdapterFilterOperator.isNull;
        break;
      case FdcFilterOperator.isNotNull:
        operator = FdcDataAdapterFilterOperator.isNotNull;
        break;
      case FdcFilterOperator.isNullOrWhitespace:
        operator = FdcDataAdapterFilterOperator.isNullOrWhitespace;
        break;
      case FdcFilterOperator.isNotNullOrWhitespace:
        operator = FdcDataAdapterFilterOperator.isNotNullOrWhitespace;
        break;
      case FdcFilterOperator.inList:
        operator = FdcDataAdapterFilterOperator.inList;
        break;
      case FdcFilterOperator.notInList:
        operator = FdcDataAdapterFilterOperator.notInList;
        break;
      case FdcFilterOperator.notContains:
      case FdcFilterOperator.between:
        throw FdcDataSetException(
          message:
              'Filter operator ${filter.operator.name} '
              'is not supported by adapter paging yet.',
        );
    }
    return FdcDataAdapterFilter(
      fieldName: filter.fieldName,
      value: value,
      operator: operator,
      caseSensitive: filter.caseSensitive,
    );
  }

  List<FdcDataAdapterSort> adapterSortsFromView(List<FdcDataSetSort> sorts) {
    if (sorts.isEmpty) {
      return const <FdcDataAdapterSort>[];
    }
    return <FdcDataAdapterSort>[
      for (final sort in sorts)
        FdcDataAdapterSort(fieldName: sort.fieldName, sortType: sort.sortType),
    ];
  }

  int captureGeneration() => _generation;

  bool isCurrent(int generation) => !_disposed && generation == _generation;

  /// Advances the lifecycle generation so in-flight async work becomes stale.
  void invalidate() {
    _generation++;
  }

  /// Marks the lifecycle as disposed and invalidates all in-flight work.
  ///
  /// Returns `false` when disposal has already been processed.
  bool dispose() {
    if (_disposed) {
      return false;
    }
    _disposed = true;
    invalidate();
    return true;
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('FdcDataSet has been disposed.');
    }
  }
}
