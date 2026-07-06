// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../common/format/fdc_format_settings.dart';
import '../fdc_dataset_filter.dart';
import '../fdc_dataset_search.dart';
import '../fdc_field_name.dart';

/// Internal owner of dataset query-change orchestration.
///
/// The dataset remains the public facade and owns work reporting, validation,
/// adapter loading, view storage, cursor state, and notifications. This
/// coordinator centralizes the behavior-neutral decision flow for search and
/// sort changes, including local rebuild versus paged adapter reload.
final class FdcDataSetQueryCoordinator {
  FdcDataSetQueryCoordinator({
    required bool Function() pagingEnabled,
    required void Function(FdcDataSetSearchState state) validateSearchFields,
    required FdcDataSetSearchState Function() readSearchState,
    required void Function(FdcDataSetSearchState state) writeSearchState,
    required void Function(List<FdcDataSetFilter> filters) validateFilterFields,
    required List<FdcDataSetFilter> Function() readFilters,
    required void Function(List<FdcDataSetFilter> filters) writeFilters,
    required FdcDataSetFilterContext Function() readFilterContext,
    required void Function(FdcDataSetFilterContext context) writeFilterContext,
    required bool Function() retainedVisibleRecordsAreEmpty,
    required void Function({required bool clearHeaderFilters})
    notifyFilterChanged,
    required List<FdcDataSetSort> Function() readSorts,
    required void Function(List<FdcDataSetSort> sorts) writeSorts,
    required List<FdcDataSetSort> Function(List<FdcDataSetSort> sorts)
    normalizeSorts,
    required bool Function() isCursorAtFirst,
    required bool Function() resolveActiveEdit,
    required void Function() clearRetainedVisibleRecords,
    required void Function() invalidateAggregateCache,
    required void Function({required bool notify, required bool resetToFirst})
    rebuildView,
    required Future<void> Function({
      required bool notify,
      required bool resetToFirst,
    })
    rebuildViewAsync,
    required Future<void> Function() openFirstPage,
    required void Function() notifyListeners,
  }) : _pagingEnabled = pagingEnabled,
       _validateSearchFields = validateSearchFields,
       _readSearchState = readSearchState,
       _writeSearchState = writeSearchState,
       _validateFilterFields = validateFilterFields,
       _readFilters = readFilters,
       _writeFilters = writeFilters,
       _readFilterContext = readFilterContext,
       _writeFilterContext = writeFilterContext,
       _retainedVisibleRecordsAreEmpty = retainedVisibleRecordsAreEmpty,
       _notifyFilterChanged = notifyFilterChanged,
       _readSorts = readSorts,
       _writeSorts = writeSorts,
       _normalizeSorts = normalizeSorts,
       _isCursorAtFirst = isCursorAtFirst,
       _resolveActiveEdit = resolveActiveEdit,
       _clearRetainedVisibleRecords = clearRetainedVisibleRecords,
       _invalidateAggregateCache = invalidateAggregateCache,
       _rebuildView = rebuildView,
       _rebuildViewAsync = rebuildViewAsync,
       _openFirstPage = openFirstPage,
       _notifyListeners = notifyListeners;

  final bool Function() _pagingEnabled;
  final void Function(FdcDataSetSearchState state) _validateSearchFields;
  final FdcDataSetSearchState Function() _readSearchState;
  final void Function(FdcDataSetSearchState state) _writeSearchState;
  final void Function(List<FdcDataSetFilter> filters) _validateFilterFields;
  final List<FdcDataSetFilter> Function() _readFilters;
  final void Function(List<FdcDataSetFilter> filters) _writeFilters;
  final FdcDataSetFilterContext Function() _readFilterContext;
  final void Function(FdcDataSetFilterContext context) _writeFilterContext;
  final bool Function() _retainedVisibleRecordsAreEmpty;
  final void Function({required bool clearHeaderFilters}) _notifyFilterChanged;
  final List<FdcDataSetSort> Function() _readSorts;
  final void Function(List<FdcDataSetSort> sorts) _writeSorts;
  final List<FdcDataSetSort> Function(List<FdcDataSetSort> sorts)
  _normalizeSorts;
  final bool Function() _isCursorAtFirst;
  final bool Function() _resolveActiveEdit;
  final void Function() _clearRetainedVisibleRecords;
  final void Function() _invalidateAggregateCache;
  final void Function({required bool notify, required bool resetToFirst})
  _rebuildView;
  final Future<void> Function({
    required bool notify,
    required bool resetToFirst,
  })
  _rebuildViewAsync;
  final Future<void> Function() _openFirstPage;
  final void Function() _notifyListeners;

  bool replaceSearch(FdcDataSetSearchState searchState, {bool notify = true}) {
    if (_pagingEnabled()) {
      throw StateError('Use search() when dataset paging is enabled.');
    }
    _validateSearchFields(searchState);
    final current = _readSearchState();
    if (current == searchState ||
        _isEquivalentSearchRefresh(current, searchState)) {
      _writeSearchState(searchState);
      if (notify) {
        _notifyListeners();
      }
      return true;
    }
    if (!_resolveActiveEdit()) {
      return false;
    }
    _clearRetainedVisibleRecords();
    _writeSearchState(searchState);
    _invalidateAggregateCache();
    _rebuildView(notify: notify, resetToFirst: true);
    return true;
  }

  Future<bool> replaceSearchAsync(
    FdcDataSetSearchState searchState, {
    bool notify = true,
  }) async {
    _validateSearchFields(searchState);
    final current = _readSearchState();
    if (current == searchState ||
        _isEquivalentSearchRefresh(current, searchState)) {
      _writeSearchState(searchState);
      if (_pagingEnabled()) {
        await _openFirstPage();
      } else if (notify) {
        _notifyListeners();
      }
      return true;
    }
    if (!_resolveActiveEdit()) {
      return false;
    }
    _clearRetainedVisibleRecords();
    _writeSearchState(searchState);
    _invalidateAggregateCache();
    if (_pagingEnabled()) {
      await _openFirstPage();
      return true;
    }
    await _rebuildViewAsync(notify: notify, resetToFirst: true);
    return true;
  }

  bool replaceFilters(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context, {
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
    required bool clearHeaderFilters,
  }) {
    if (_pagingEnabled()) {
      throw StateError('Use async filter APIs when dataset paging is enabled.');
    }
    _validateFilterFields(filters);

    final filtersMatch = _activeFiltersMatch(filters, context);
    final retainedVisibleRecordsAlreadyClear =
        !clearRetainedVisibleRecords || _retainedVisibleRecordsAreEmpty();
    final mustRebuildForMutableRowState = context.selected != null;

    if (filtersMatch &&
        retainedVisibleRecordsAlreadyClear &&
        !mustRebuildForMutableRowState) {
      _notifyFilterChanged(clearHeaderFilters: clearHeaderFilters);
      if (notify) {
        _notifyListeners();
      }
      return true;
    }
    if (!_resolveActiveEdit()) {
      return false;
    }
    if (clearRetainedVisibleRecords) {
      _clearRetainedVisibleRecords();
    }
    _writeFilters(filters);
    _writeFilterContext(context);
    _invalidateAggregateCache();
    _notifyFilterChanged(clearHeaderFilters: clearHeaderFilters);
    _rebuildView(notify: notify, resetToFirst: true);
    return true;
  }

  Future<bool> replaceFiltersAsync(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context, {
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
    required bool clearHeaderFilters,
  }) async {
    _validateFilterFields(filters);

    final filtersMatch = _activeFiltersMatch(filters, context);
    final retainedVisibleRecordsAlreadyClear =
        !clearRetainedVisibleRecords || _retainedVisibleRecordsAreEmpty();
    final mustRebuildForMutableRowState = context.selected != null;

    if (filtersMatch &&
        retainedVisibleRecordsAlreadyClear &&
        !mustRebuildForMutableRowState) {
      _notifyFilterChanged(clearHeaderFilters: clearHeaderFilters);
      if (notify) {
        _notifyListeners();
      }
      return true;
    }
    if (!_resolveActiveEdit()) {
      return false;
    }
    if (clearRetainedVisibleRecords) {
      _clearRetainedVisibleRecords();
    }
    _writeFilters(filters);
    _writeFilterContext(context);
    _invalidateAggregateCache();
    _notifyFilterChanged(clearHeaderFilters: clearHeaderFilters);
    if (_pagingEnabled()) {
      final watch = Stopwatch()..start();
      await _openFirstPage();
      watch.stop();
      return true;
    }
    final watch = Stopwatch()..start();
    await _rebuildViewAsync(notify: notify, resetToFirst: true);
    watch.stop();
    return true;
  }

  bool replaceFiltersAndSorts(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context,
    List<FdcDataSetSort> sorts, {
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
  }) {
    if (_pagingEnabled()) {
      throw StateError(
        'Use async filter/sort APIs when dataset paging is enabled.',
      );
    }
    _validateFilterFields(filters);
    final normalizedSorts = _normalizeSorts(sorts);
    final filtersMatch = _activeFiltersMatch(filters, context);
    final sortsMatch = _sortsEqual(_readSorts(), normalizedSorts);
    final retainedVisibleRecordsAlreadyClear =
        !clearRetainedVisibleRecords || _retainedVisibleRecordsAreEmpty();
    final mustRebuildForMutableRowState = context.selected != null;

    if (filtersMatch &&
        sortsMatch &&
        retainedVisibleRecordsAlreadyClear &&
        !mustRebuildForMutableRowState) {
      _notifyFilterChanged(clearHeaderFilters: true);
      if (notify) {
        _notifyListeners();
      }
      return true;
    }
    if (!_resolveActiveEdit()) {
      return false;
    }
    if (clearRetainedVisibleRecords) {
      _clearRetainedVisibleRecords();
    }
    _writeFilters(filters);
    _writeFilterContext(context);
    _writeSorts(normalizedSorts);
    if (!filtersMatch ||
        !retainedVisibleRecordsAlreadyClear ||
        mustRebuildForMutableRowState) {
      _invalidateAggregateCache();
    }
    _notifyFilterChanged(clearHeaderFilters: true);
    _rebuildView(notify: notify, resetToFirst: true);
    return true;
  }

  Future<bool> replaceFiltersAndSortsAsync(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context,
    List<FdcDataSetSort> sorts, {
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
  }) async {
    _validateFilterFields(filters);
    final normalizedSorts = _normalizeSorts(sorts);
    final filtersMatch = _activeFiltersMatch(filters, context);
    final sortsMatch = _sortsEqual(_readSorts(), normalizedSorts);
    final retainedVisibleRecordsAlreadyClear =
        !clearRetainedVisibleRecords || _retainedVisibleRecordsAreEmpty();
    final mustRebuildForMutableRowState = context.selected != null;

    if (filtersMatch &&
        sortsMatch &&
        retainedVisibleRecordsAlreadyClear &&
        !mustRebuildForMutableRowState) {
      _notifyFilterChanged(clearHeaderFilters: true);
      if (notify) {
        _notifyListeners();
      }
      return true;
    }
    if (!_resolveActiveEdit()) {
      return false;
    }
    if (clearRetainedVisibleRecords) {
      _clearRetainedVisibleRecords();
    }
    _writeFilters(filters);
    _writeFilterContext(context);
    _writeSorts(normalizedSorts);
    if (!filtersMatch ||
        !retainedVisibleRecordsAlreadyClear ||
        mustRebuildForMutableRowState) {
      _invalidateAggregateCache();
    }
    _notifyFilterChanged(clearHeaderFilters: true);
    if (_pagingEnabled()) {
      await _openFirstPage();
    } else {
      await _rebuildViewAsync(notify: notify, resetToFirst: true);
    }
    return true;
  }

  bool _activeFiltersMatch(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context,
  ) {
    final currentFilters = _readFilters();
    if (!_filterListsEqual(currentFilters, filters)) {
      return false;
    }
    final currentContext = _readFilterContext();
    if (currentContext.selected != context.selected) {
      return false;
    }
    if (currentFilters.isEmpty) {
      return true;
    }
    return currentContext.formatSettings == context.formatSettings;
  }

  static bool _filterListsEqual(
    List<FdcDataSetFilter> left,
    List<FdcDataSetFilter> right,
  ) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (!_filtersEqual(left[index], right[index])) {
        return false;
      }
    }
    return true;
  }

  static bool _filtersEqual(FdcDataSetFilter left, FdcDataSetFilter right) {
    return FdcFieldName.normalize(left.fieldName) ==
            FdcFieldName.normalize(right.fieldName) &&
        left.operator == right.operator &&
        _filterValuesEqual(left.value, right.value) &&
        _filterValuesEqual(left.secondValue, right.secondValue) &&
        left.caseSensitive == right.caseSensitive &&
        left.dataType == right.dataType &&
        left.formatSettings == right.formatSettings &&
        identical(left.valueResolver, right.valueResolver);
  }

  static bool _filterValuesEqual(Object? left, Object? right) {
    if (identical(left, right)) {
      return true;
    }
    if (left is Iterable && right is Iterable) {
      final leftItems = left.toList(growable: false);
      final rightItems = right.toList(growable: false);
      if (leftItems.length != rightItems.length) {
        return false;
      }
      for (var index = 0; index < leftItems.length; index++) {
        if (leftItems[index] != rightItems[index]) {
          return false;
        }
      }
      return true;
    }
    return left == right;
  }

  bool replaceSorts(List<FdcDataSetSort> sorts, {required bool notify}) {
    if (_pagingEnabled()) {
      throw StateError('Use async sort APIs when dataset paging is enabled.');
    }
    final normalizedSorts = _normalizeSorts(sorts);
    final sortsMatch = _sortsEqual(_readSorts(), normalizedSorts);
    final alreadyAtFirst = _isCursorAtFirst();
    if ((!sortsMatch || !alreadyAtFirst) && !_resolveActiveEdit()) {
      return false;
    }
    if (sortsMatch) {
      if (alreadyAtFirst) {
        return false;
      }
      _rebuildView(notify: notify, resetToFirst: true);
      return true;
    }
    _writeSorts(normalizedSorts);
    _rebuildView(notify: notify, resetToFirst: true);
    return true;
  }

  Future<bool> replaceSortsAsync(
    List<FdcDataSetSort> sorts, {
    required bool notify,
  }) async {
    final normalizedSorts = _normalizeSorts(sorts);
    final sortsMatch = _sortsEqual(_readSorts(), normalizedSorts);
    final alreadyAtFirst = _isCursorAtFirst();
    if ((!sortsMatch || !alreadyAtFirst) && !_resolveActiveEdit()) {
      return false;
    }
    if (sortsMatch) {
      if (alreadyAtFirst) {
        return false;
      }
      if (_pagingEnabled()) {
        await _openFirstPage();
      } else {
        await _rebuildViewAsync(notify: notify, resetToFirst: true);
      }
      return true;
    }
    _writeSorts(normalizedSorts);
    if (_pagingEnabled()) {
      await _openFirstPage();
    } else {
      await _rebuildViewAsync(notify: notify, resetToFirst: true);
    }
    return true;
  }

  static bool _isEquivalentSearchRefresh(
    FdcDataSetSearchState current,
    FdcDataSetSearchState next,
  ) {
    return current.text == next.text &&
        current.mode == next.mode &&
        current.caseSensitive == next.caseSensitive &&
        _searchStringSetsEqual(current.fields, next.fields) &&
        _searchFormatterKeysEqual(
          current.fieldTextFormatters,
          next.fieldTextFormatters,
        ) &&
        _searchFormatSettingsMapsEqual(
          current.fieldFormatSettings,
          next.fieldFormatSettings,
        ) &&
        current.formatSettings == next.formatSettings;
  }

  static bool _searchStringSetsEqual(Set<String>? a, Set<String>? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null || a.length != b.length) {
      return false;
    }
    return a.containsAll(b);
  }

  static bool _searchFormatterKeysEqual(
    Map<String, FdcSearchFieldTextFormatter>? a,
    Map<String, FdcSearchFieldTextFormatter>? b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null || a.length != b.length) {
      return false;
    }
    for (final key in a.keys) {
      if (!b.containsKey(key)) {
        return false;
      }
    }
    return true;
  }

  static bool _searchFormatSettingsMapsEqual(
    Map<String, FdcFormatSettings>? a,
    Map<String, FdcFormatSettings>? b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null || a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  static bool _sortsEqual(
    List<FdcDataSetSort> left,
    List<FdcDataSetSort> right,
  ) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      final leftSort = left[index];
      final rightSort = right[index];
      if (FdcFieldName.normalize(leftSort.fieldName) !=
              FdcFieldName.normalize(rightSort.fieldName) ||
          leftSort.sortType != rightSort.sortType) {
        return false;
      }
    }
    return true;
  }
}
