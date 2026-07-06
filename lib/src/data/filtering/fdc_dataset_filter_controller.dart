// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:meta/meta.dart';

import '../fdc_dataset_filter.dart';
import 'fdc_filter_builder.dart';

/// Dataset-level filter API.
///
/// The dataset owns exactly one active filtered view. This object is a
/// small public entry point for replacing, clearing and fluently building that
/// active filter. Every change is applied by the owning dataset and triggers a
/// view rebuild there.
class FdcDataSetFilters {
  /// Creates a [FdcDataSetFilters].
  @internal
  FdcDataSetFilters({
    required bool Function() canApplyViewOperation,
    required bool Function() useAsyncViewOperations,
    required List<FdcDataSetFilter> Function() readFilters,
    required FdcDataSetFilterContext Function() readContext,
    required bool Function() isQueryConstraintBlocked,
    required bool Function(
      List<FdcDataSetFilter> filters,
      FdcDataSetFilterContext context, {
      required bool clearRetainedVisibleRecords,
      required bool notify,
    })
    replaceFilters,
    required Future<bool> Function(
      List<FdcDataSetFilter> filters,
      FdcDataSetFilterContext context, {
      required bool clearRetainedVisibleRecords,
      required bool notify,
    })
    replaceFiltersAsync,
    required bool Function(
      List<FdcDataSetFilter> filters,
      FdcDataSetFilterContext context,
      List<FdcDataSetSort> sorts, {
      required bool clearRetainedVisibleRecords,
      required bool notify,
    })
    replaceFiltersAndSorts,
    required Future<bool> Function(
      List<FdcDataSetFilter> filters,
      FdcDataSetFilterContext context,
      List<FdcDataSetSort> sorts, {
      required bool clearRetainedVisibleRecords,
      required bool notify,
    })
    replaceFiltersAndSortsAsync,
  }) : _canApplyViewOperation = canApplyViewOperation,
       _useAsyncViewOperations = useAsyncViewOperations,
       _readFilters = readFilters,
       _readContext = readContext,
       _isQueryConstraintBlocked = isQueryConstraintBlocked,
       _replaceFilters = replaceFilters,
       _replaceFiltersAsync = replaceFiltersAsync,
       _replaceFiltersAndSorts = replaceFiltersAndSorts,
       _replaceFiltersAndSortsAsync = replaceFiltersAndSortsAsync;

  /// Runs the function operation.
  final bool Function() _canApplyViewOperation;

  /// Runs the function operation.
  final bool Function() _useAsyncViewOperations;

  /// Runs the function operation.
  final List<FdcDataSetFilter> Function() _readFilters;

  /// Runs the function operation.
  final FdcDataSetFilterContext Function() _readContext;

  /// Runs the function operation.
  final bool Function() _isQueryConstraintBlocked;

  /// Runs the function operation.
  final bool Function(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context, {
    required bool clearRetainedVisibleRecords,
    required bool notify,
  })
  _replaceFilters;

  /// Runs the function operation.
  final Future<bool> Function(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context, {
    required bool clearRetainedVisibleRecords,
    required bool notify,
  })
  _replaceFiltersAsync;

  /// Runs the function operation.
  final bool Function(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context,
    List<FdcDataSetSort> sorts, {
    required bool clearRetainedVisibleRecords,
    required bool notify,
  })
  _replaceFiltersAndSorts;

  /// Runs the function operation.
  final Future<bool> Function(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context,
    List<FdcDataSetSort> sorts, {
    required bool clearRetainedVisibleRecords,
    required bool notify,
  })
  _replaceFiltersAndSortsAsync;

  /// Active field-level filter descriptors.
  ///
  /// This list intentionally contains only filters that target dataset fields.
  /// Context filters, such as row-selection filtering, are exposed separately
  /// through [context] and [selectedFilter].
  List<FdcDataSetFilter> get fieldItems => _readFilters();

  /// Active field-level filter descriptors.
  List<FdcDataSetFilter> get items => fieldItems;

  /// Active non-field filter context.
  FdcDataSetFilterContext get context => _readContext();

  /// Active row-selection-state filter, or `null` when no selection filter is
  /// applied.
  bool? get selectedFilter => context.selected;

  /// Whether there are no field, selection-state, or internal query constraints.
  bool get isEmpty =>
      fieldItems.isEmpty &&
      selectedFilter == null &&
      !_isQueryConstraintBlocked();

  /// Whether any filter or query constraint is active.
  bool get isNotEmpty => !isEmpty;

  /// True when the owning dataset has active filters.
  bool get active => isNotEmpty;

  /// Starts a fluent AND-only filter expression.
  @useResult
  FdcFilterConditionBuilder where(
    String fieldName, {
    FdcDataSetFilterContext context = const FdcDataSetFilterContext(),
  }) {
    return FdcFilterBuilder.internal(
      controller: this,
      context: context,
    ).where(fieldName);
  }

  /// Starts a filter expression with an ORDER BY clause and no conditions.
  @useResult
  FdcFilterOrderStep orderBy(
    String fieldName, {
    FdcDataSetFilterContext context = const FdcDataSetFilterContext(),
  }) {
    return FdcFilterBuilder.internal(
      controller: this,
      context: context,
    ).orderBy(fieldName);
  }

  /// Starts a fluent filter expression by filtering on internal row selection
  /// state. This changes only the dataset view; it does not select/unselect
  /// records.
  @useResult
  FdcFilterBuilder selected(
    bool value, {
    FdcDataSetFilterContext context = const FdcDataSetFilterContext(),
  }) {
    return FdcFilterBuilder.internal(
      controller: this,
      context: context,
    ).selected(value);
  }

  /// Replaces the active dataset filter and rebuilds or reloads the view.
  ///
  /// Local datasets evaluate the descriptors in memory. Adapter-backed paged
  /// datasets translate supported predicates into adapter query criteria.
  Future<bool> set(
    List<FdcDataSetFilter> filters, {
    FdcDataSetFilterContext context = const FdcDataSetFilterContext(),
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
  }) {
    if (!_canApplyViewOperation()) {
      return Future<bool>.value(false);
    }

    final normalizedFilters = List<FdcDataSetFilter>.unmodifiable(filters);
    if (_useAsyncViewOperations()) {
      return _replaceFiltersAsync(
        normalizedFilters,
        context,
        clearRetainedVisibleRecords: clearRetainedVisibleRecords,
        notify: notify,
      );
    }

    return Future<bool>.value(
      _replaceFilters(
        normalizedFilters,
        context,
        clearRetainedVisibleRecords: clearRetainedVisibleRecords,
        notify: notify,
      ),
    );
  }

  /// Clears public field and selection filters and rebuilds or reloads the view.
  ///
  /// Adapter-level default filters and internal query constraints remain in
  /// effect.
  Future<bool> clear({
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
  }) {
    return set(
      const <FdcDataSetFilter>[],
      clearRetainedVisibleRecords: clearRetainedVisibleRecords,
      notify: notify,
    );
  }

  /// Runs the apply built filters operation.
  @internal
  Future<bool> applyBuiltFilters(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context, {
    List<FdcDataSetSort>? sorts,
  }) {
    if (!_canApplyViewOperation()) {
      return Future<bool>.value(false);
    }

    if (sorts == null) {
      return set(filters, context: context);
    }

    final normalizedFilters = List<FdcDataSetFilter>.unmodifiable(filters);
    final normalizedSorts = List<FdcDataSetSort>.unmodifiable(sorts);
    if (_useAsyncViewOperations()) {
      return _replaceFiltersAndSortsAsync(
        normalizedFilters,
        context,
        normalizedSorts,
        clearRetainedVisibleRecords: true,
        notify: true,
      );
    }

    return Future<bool>.value(
      _replaceFiltersAndSorts(
        normalizedFilters,
        context,
        normalizedSorts,
        clearRetainedVisibleRecords: true,
        notify: true,
      ),
    );
  }
}
