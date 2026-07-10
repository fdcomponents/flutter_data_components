// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;

import '../common/platform/fdc_background_runner.dart';

import 'fdc_data_type.dart';
import 'fdc_dataset_filter.dart';
import 'fdc_dataset_search.dart';
import 'fdc_dataset_state.dart';
import 'fdc_dataset_work.dart';
import 'fdc_field_def.dart';
import 'fdc_field_name.dart';
import 'fdc_record.dart';

const _fdcComparableCacheUsageValue = 'value';
const _fdcComparableCacheUsageSort = 'sort';
const _fdcSortRankCacheUsage = 'rank';

/// List-compatible view index storage with a compact identity-range mode.
///
/// The common unfiltered/unsorted view is physically identical to the record
/// store order, so storing `0..recordCount - 1` duplicates a large int list.
/// This class still behaves like a normal growable `List<int>` for dataset and
/// grid code, but keeps that identity view as a length sentinel until a real
/// permutation/filter mutation requires materializing the list.
class _FdcDataSetViewIndexes extends ListBase<int> {
  final List<int> _indexes = <int>[];
  int? _physicalRangeLength;

  bool get isPhysicalRange => _physicalRangeLength != null;

  @override
  int get length => _physicalRangeLength ?? _indexes.length;

  @override
  set length(int value) {
    RangeError.checkNotNegative(value, 'length');

    final rangeLength = _physicalRangeLength;
    if (rangeLength != null) {
      if (value == rangeLength) {
        return;
      }
      if (value == 0) {
        clear();
        return;
      }
      if (value < rangeLength) {
        _physicalRangeLength = value;
        return;
      }
      _materialize();
    }

    _indexes.length = value;
  }

  @override
  int operator [](int index) {
    final rangeLength = _physicalRangeLength;
    if (rangeLength != null) {
      RangeError.checkValidIndex(index, this);
      return index;
    }
    return _indexes[index];
  }

  @override
  void operator []=(int index, int value) {
    _materialize();
    _indexes[index] = value;
  }

  @override
  void add(int value) {
    final rangeLength = _physicalRangeLength;
    if (rangeLength != null && value == rangeLength) {
      _physicalRangeLength = rangeLength + 1;
      return;
    }

    _materialize();
    _indexes.add(value);
  }

  @override
  void addAll(Iterable<int> iterable) {
    if (iterable is _FdcDataSetViewIndexes && iterable.isPhysicalRange) {
      if (isEmpty) {
        setPhysicalRange(iterable.length);
        return;
      }
    }

    final rangeLength = _physicalRangeLength;
    if (rangeLength != null) {
      final values = iterable is List<int>
          ? iterable
          : List<int>.of(iterable, growable: false);
      var expected = rangeLength;
      var canExtendRange = true;
      for (final value in values) {
        if (value != expected) {
          canExtendRange = false;
          break;
        }
        expected++;
      }
      if (canExtendRange) {
        _physicalRangeLength = expected;
        return;
      }
      _materialize();
      _indexes.addAll(values);
      return;
    }

    _indexes.addAll(iterable);
  }

  @override
  void clear() {
    _physicalRangeLength = null;
    _indexes.clear();
  }

  @override
  void insert(int index, int element) {
    _materialize();
    _indexes.insert(index, element);
  }

  @override
  int removeAt(int index) {
    _materialize();
    return _indexes.removeAt(index);
  }

  @override
  void sort([int Function(int a, int b)? compare]) {
    _materialize();
    _indexes.sort(compare);
  }

  void setPhysicalRange(int length) {
    RangeError.checkNotNegative(length, 'length');
    _indexes.clear();
    _physicalRangeLength = length;
  }

  void replaceWith(Iterable<int> iterable) {
    if (identical(iterable, this)) {
      return;
    }
    if (iterable is _FdcDataSetViewIndexes && iterable.isPhysicalRange) {
      setPhysicalRange(iterable.length);
      return;
    }

    _physicalRangeLength = null;
    _indexes
      ..clear()
      ..addAll(iterable);
  }

  void _materialize() {
    final rangeLength = _physicalRangeLength;
    if (rangeLength == null) {
      return;
    }

    _physicalRangeLength = null;
    _indexes
      ..clear()
      ..addAll(List<int>.generate(rangeLength, (index) => index));
  }
}

/// Owns the dataset view projection: filters, sorts, visible raw indexes,
/// retained-visible rows and comparable-value caches.
///
/// FdcDataSet remains the public API and lifecycle orchestrator. This class
/// deliberately contains no event handling and does not notify listeners; the
/// dataset decides when a view rebuild should be visible to widgets.
class FdcDataSetViewController {
  final List<int> viewIndexes = _FdcDataSetViewIndexes();
  final Set<int> retainedVisibleRecordIds = <int>{};
  final LinkedHashMap<String, List<Object?>> comparableValueCache =
      LinkedHashMap<String, List<Object?>>();
  final LinkedHashMap<String, List<int?>> sortRankCache =
      LinkedHashMap<String, List<int?>>();
  _FdcSortedFullViewCache? _sortedFullViewCache;
  final List<FdcDataSetFilter> filters = <FdcDataSetFilter>[];
  final Map<Object, List<FdcDataSetFilter>> queryConstraintFilters =
      <Object, List<FdcDataSetFilter>>{};
  final Set<Object> blockedQueryConstraints = <Object>{};
  final List<FdcDataSetSort> sorts = <FdcDataSetSort>[];
  FdcDataSetSearchState searchState = const FdcDataSetSearchState();

  FdcDataSetOperationOptions operationOptions =
      const FdcDataSetOperationOptions();
  FdcDataSetFilterContext filterContext = const FdcDataSetFilterContext();
  int get recordCount => viewIndexes.length;

  _FdcDataSetViewIndexes get _viewIndexStorage =>
      viewIndexes as _FdcDataSetViewIndexes;

  @visibleForTesting
  bool get debugViewIndexesUsePhysicalRange =>
      _viewIndexStorage.isPhysicalRange;

  List<FdcDataSetFilter> get unmodifiableFilters =>
      List<FdcDataSetFilter>.unmodifiable(filters);

  Iterable<FdcDataSetFilter> get effectiveFilters sync* {
    for (final constraint in queryConstraintFilters.values) {
      yield* constraint;
    }
    yield* filters;
  }

  bool get isQueryConstraintBlocked => blockedQueryConstraints.isNotEmpty;

  List<FdcDataSetSort> get unmodifiableSorts =>
      List<FdcDataSetSort>.unmodifiable(sorts);

  FdcDataSetSearchState get currentSearchState => searchState;

  void clearComparableValueCache() {
    comparableValueCache.clear();
    sortRankCache.clear();
    _sortedFullViewCache = null;
  }

  List<Object?>? _cachedSortComparableValues(String cacheKey, int length) {
    if (!operationOptions.enableSortValueCache) {
      return null;
    }
    final cached = comparableValueCache.remove(cacheKey);
    if (cached == null || cached.length != length) {
      return null;
    }
    comparableValueCache[cacheKey] = cached;
    return cached;
  }

  List<int?>? _cachedSortRanks(String cacheKey, int length) {
    if (!operationOptions.enableSortValueCache) {
      return null;
    }
    final cached = sortRankCache.remove(cacheKey);
    if (cached == null || cached.length != length) {
      return null;
    }
    sortRankCache[cacheKey] = cached;
    return cached;
  }

  void _cacheSortComparableValues(String cacheKey, List<Object?> values) {
    if (!operationOptions.enableSortValueCache) {
      return;
    }
    comparableValueCache[cacheKey] = values;
    _trimSortComparableValueCache();
  }

  void _cacheSortRanks(String cacheKey, List<int?> ranks) {
    if (!operationOptions.enableSortValueCache) {
      return;
    }
    sortRankCache[cacheKey] = ranks;
    _trimSortRankCache();
  }

  void _trimSortComparableValueCache() {
    final limit = operationOptions.sortValueCacheSize;
    if (limit < 1) {
      comparableValueCache.removeWhere(
        (key, _) => key.startsWith('$_fdcComparableCacheUsageSort|'),
      );
      return;
    }
    while (_sortComparableValueCacheCount() > limit) {
      final key = comparableValueCache.keys.firstWhere(
        (key) => key.startsWith('$_fdcComparableCacheUsageSort|'),
        orElse: () => '',
      );
      if (key.isEmpty) {
        return;
      }
      comparableValueCache.remove(key);
    }
  }

  void _trimSortRankCache() {
    final limit = operationOptions.sortValueCacheSize;
    if (limit < 1) {
      sortRankCache.clear();
      return;
    }
    while (sortRankCache.length > limit) {
      sortRankCache.remove(sortRankCache.keys.first);
    }
  }

  int _sortComparableValueCacheCount() {
    var count = 0;
    for (final key in comparableValueCache.keys) {
      if (key.startsWith('$_fdcComparableCacheUsageSort|')) {
        count++;
      }
    }
    return count;
  }

  void invalidateComparableCacheForField(int fieldIndex) {
    comparableValueCache.removeWhere(
      (key, _) => _isComparableCacheKeyForField(key, fieldIndex),
    );
    sortRankCache.removeWhere(
      (key, _) => _isSortRankCacheKeyForField(key, fieldIndex),
    );
    if (_sortedFullViewCache?.dependsOnField(fieldIndex) ?? false) {
      _sortedFullViewCache = null;
    }
  }

  void retainVisibleRecord({
    required int recordId,
    required List<FdcRecord> records,
  }) {
    if (activeIndexForRecordId(recordId, records: records) >= 0) {
      retainedVisibleRecordIds.add(recordId);
    }
  }

  void clearRetainedVisibleRecords() {
    retainedVisibleRecordIds.clear();
  }

  bool _canUsePhysicalRangeView(List<FdcRecord> records) {
    for (final record in records) {
      if (record.state == FdcRecordState.deleted) {
        return false;
      }
    }
    return true;
  }

  int pruneRetainedVisibleRecords(List<FdcRecord> records) {
    if (retainedVisibleRecordIds.isEmpty) {
      return 0;
    }

    final existingRecordIds = <int>{for (final record in records) record.id};
    final before = retainedVisibleRecordIds.length;
    retainedVisibleRecordIds.removeWhere(
      (recordId) => !existingRecordIds.contains(recordId),
    );
    return before - retainedVisibleRecordIds.length;
  }

  int rawIndexForActiveIndex({
    required int activeIndex,
    required int fallbackRawIndex,
  }) {
    if (activeIndex < 0 || activeIndex >= viewIndexes.length) {
      return fallbackRawIndex;
    }
    return viewIndexes[activeIndex];
  }

  int activeIndexForRecordId(int recordId, {required List<FdcRecord> records}) {
    for (var viewIndex = 0; viewIndex < viewIndexes.length; viewIndex++) {
      final rawIndex = viewIndexes[viewIndex];
      if (rawIndex < 0 || rawIndex >= records.length) {
        continue;
      }
      if (records[rawIndex].id == recordId) {
        return viewIndex;
      }
    }
    return -1;
  }

  int normalizeCurrentIndex(int currentIndex) {
    final count = recordCount;
    if (count == 0) {
      return -1;
    }
    if (currentIndex < 0) {
      return 0;
    }
    if (currentIndex >= count) {
      return count - 1;
    }
    return currentIndex;
  }

  int rebuildAdapterPageView({
    required List<FdcRecord> records,
    required int currentIndex,
    int? preserveRecordId,
  }) {
    // In adapter-driven paged mode the adapter has already applied filter,
    // search, sort, and page limits. Keep the active query state stored on the
    // view controller for UI/header state, but do not evaluate it again against
    // the loaded page. Reapplying those criteria locally duplicates work,
    // rebuilds comparable/sort caches, and can incorrectly hide
    // adapter-returned rows such as retained/server-shaped results.
    pruneRetainedVisibleRecords(records);
    clearComparableValueCache();
    if (_canUsePhysicalRangeView(records)) {
      _viewIndexStorage.setPhysicalRange(records.length);
    } else {
      viewIndexes.clear();
      for (var recordIndex = 0; recordIndex < records.length; recordIndex++) {
        if (records[recordIndex].state != FdcRecordState.deleted) {
          viewIndexes.add(recordIndex);
        }
      }
    }

    var nextIndex = normalizeCurrentIndex(currentIndex);
    if (preserveRecordId != null) {
      final preservedIndex = activeIndexForRecordId(
        preserveRecordId,
        records: records,
      );
      if (preservedIndex >= 0) {
        nextIndex = preservedIndex;
      }
    }
    return nextIndex;
  }

  int rebuildView({
    required List<FdcRecord> records,
    required List<FdcFieldDef> fields,
    required Map<String, int> fieldIndexByName,
    required int currentIndex,
    required int? preserveRecordId,
    required bool Function(FdcRecord record) mustKeepRecordInView,
  }) {
    pruneRetainedVisibleRecords(records);
    viewIndexes.clear();
    if (isQueryConstraintBlocked) {
      return -1;
    }

    final preparedFilters = <FdcPreparedDataSetFilter>[];
    for (final filter in effectiveFilters) {
      final fieldIndex =
          fieldIndexByName[FdcFieldName.normalize(filter.fieldName)];
      if (fieldIndex == null) {
        continue;
      }
      final dataType = filter.dataType ?? fields[fieldIndex].dataType;
      final prepared = prepareDataSetFilter(
        filter: filter,
        fieldIndex: fieldIndex,
        dataType: dataType,
        context: filterContext,
      );
      if (prepared != null) {
        preparedFilters.add(prepared);
      }
    }
    final selectedFilter = filterContext.selected;
    final preparedSearch = prepareDataSetSearch(
      search: searchState,
      fields: fields,
      fieldIndexByName: fieldIndexByName,
      formatSettings: searchState.formatSettings,
    );

    final comparableFilterValues = <FdcPreparedDataSetFilter, List<Object?>>{};
    for (final filter in preparedFilters) {
      if (!canCacheComparableFilter(filter)) {
        continue;
      }

      comparableFilterValues[filter] = _comparableValuesFor(
        records: records,
        fieldIndex: filter.fieldIndex,
        dataType: filter.dataType,
        compareByDay: filter.compareByDay,
        valueResolver: filter.valueResolver,
        usePrimitiveComparable: filter.usePrimitiveComparable,
        useNormalizedTextComparable: filter.useNormalizedTextComparable,
        caseSensitive: filter.filter.caseSensitive,
      );
    }

    final preparedSorts = _prepareSorts(
      fields: fields,
      fieldIndexByName: fieldIndexByName,
    );
    final sortSignature = _sortSignatureFor(preparedSorts);
    final canUseFullSortedViewCache =
        selectedFilter == null &&
        preparedFilters.isEmpty &&
        preparedSearch == null &&
        retainedVisibleRecordIds.isEmpty &&
        sortSignature.isNotEmpty;

    final cachedFullSortedView = canUseFullSortedViewCache
        ? _sortedFullViewCache?.viewIndexesFor(
            recordCount: records.length,
            sortSignature: sortSignature,
          )
        : null;

    if (cachedFullSortedView != null) {
      viewIndexes.addAll(cachedFullSortedView);
    } else if (selectedFilter == null &&
        preparedFilters.isEmpty &&
        preparedSearch == null &&
        retainedVisibleRecordIds.isEmpty &&
        preparedSorts.isEmpty) {
      if (_canUsePhysicalRangeView(records)) {
        _viewIndexStorage.setPhysicalRange(records.length);
      } else {
        for (var recordIndex = 0; recordIndex < records.length; recordIndex++) {
          final record = records[recordIndex];
          if (record.state != FdcRecordState.deleted) {
            viewIndexes.add(recordIndex);
          }
        }
      }
    } else {
      for (var recordIndex = 0; recordIndex < records.length; recordIndex++) {
        final record = records[recordIndex];
        if (record.state == FdcRecordState.deleted) {
          continue;
        }
        if (mustKeepRecordInView(record) ||
            retainedVisibleRecordIds.contains(record.id)) {
          viewIndexes.add(recordIndex);
          continue;
        }
        if (selectedFilter != null && record.selected != selectedFilter) {
          continue;
        }
        var matches = true;
        for (final filter in preparedFilters) {
          final comparableValues = comparableFilterValues[filter];
          final filterMatches = comparableValues == null
              ? matchesPreparedDataSetFilter(
                  record.valueAt(filter.fieldIndex),
                  filter,
                )
              : matchesPreparedComparableFilter(
                  comparableValues[recordIndex],
                  filter,
                );

          if (!filterMatches) {
            matches = false;
            break;
          }
        }
        if (matches) {
          var searchMatches = true;
          if (preparedSearch != null) {
            searchMatches = preparedSearch.matches(record);
          }
          if (searchMatches) {
            viewIndexes.add(recordIndex);
          }
        }
      }

      if (preparedSorts.isNotEmpty) {
        _sortViewIndexes(records: records, preparedSorts: preparedSorts);

        if (canUseFullSortedViewCache) {
          _sortedFullViewCache = _FdcSortedFullViewCache(
            recordCount: records.length,
            sortSignature: sortSignature,
            sortFieldIndexes: <int>{
              for (final sort in preparedSorts) sort.fieldIndex,
            },
            viewIndexes: List<int>.unmodifiable(viewIndexes),
          );
        }
      }
    }

    var nextIndex = normalizeCurrentIndex(currentIndex);
    if (preserveRecordId != null) {
      final preservedIndex = activeIndexForRecordId(
        preserveRecordId,
        records: records,
      );
      if (preservedIndex >= 0) {
        nextIndex = preservedIndex;
      }
    }

    return nextIndex;
  }

  Future<int> rebuildViewAsync({
    required List<FdcRecord> records,
    required List<FdcFieldDef> fields,
    required Map<String, int> fieldIndexByName,
    required int currentIndex,
    required int? preserveRecordId,
    required bool Function(FdcRecord record) mustKeepRecordInView,
    void Function({
      double? progress,
      String? message,
      FdcDataSetWorkPhase? phase,
    })?
    onProgress,
  }) async {
    final yieldEveryRecords = operationOptions.cooperativeChunkSize <= 0
        ? 8192
        : operationOptions.cooperativeChunkSize;
    final paintYieldEveryRecords = yieldEveryRecords * 4;

    pruneRetainedVisibleRecords(records);

    // Build the async view projection in a private buffer and publish it only
    // after the full rebuild completes. Long-running async filter/sort work
    // yields to the UI between chunks; mutating the public viewIndexes list
    // during those yields lets bound widgets observe partial record counts such
    // as "Record 1 of 1523" while a million-row sort is still in progress.
    final nextViewIndexes = _FdcDataSetViewIndexes();
    if (isQueryConstraintBlocked) {
      viewIndexes.clear();
      return -1;
    }

    onProgress?.call(progress: 0.02);
    await _yieldForAsyncViewChunk();

    final preparedFilters = <FdcPreparedDataSetFilter>[];
    for (final filter in effectiveFilters) {
      final fieldIndex =
          fieldIndexByName[FdcFieldName.normalize(filter.fieldName)];
      if (fieldIndex == null) {
        continue;
      }
      final dataType = filter.dataType ?? fields[fieldIndex].dataType;
      final prepared = prepareDataSetFilter(
        filter: filter,
        fieldIndex: fieldIndex,
        dataType: dataType,
        context: filterContext,
      );
      if (prepared != null) {
        preparedFilters.add(prepared);
      }
    }
    final selectedFilter = filterContext.selected;
    final preparedSearch = prepareDataSetSearch(
      search: searchState,
      fields: fields,
      fieldIndexByName: fieldIndexByName,
      formatSettings: searchState.formatSettings,
    );
    onProgress?.call(progress: 0.05);

    final comparableFilterValues = <FdcPreparedDataSetFilter, List<Object?>>{};
    for (final filter in preparedFilters) {
      if (!canCacheComparableFilter(filter)) {
        continue;
      }

      comparableFilterValues[filter] = _comparableValuesFor(
        records: records,
        fieldIndex: filter.fieldIndex,
        dataType: filter.dataType,
        compareByDay: filter.compareByDay,
        valueResolver: filter.valueResolver,
        usePrimitiveComparable: filter.usePrimitiveComparable,
        useNormalizedTextComparable: filter.useNormalizedTextComparable,
        caseSensitive: filter.filter.caseSensitive,
      );
      await _yieldForAsyncViewChunk();
    }

    final preparedSorts = _prepareSorts(
      fields: fields,
      fieldIndexByName: fieldIndexByName,
    );
    final sortSignature = _sortSignatureFor(preparedSorts);
    final canUseFullSortedViewCache =
        selectedFilter == null &&
        preparedFilters.isEmpty &&
        preparedSearch == null &&
        retainedVisibleRecordIds.isEmpty &&
        sortSignature.isNotEmpty;

    final cachedFullSortedView = canUseFullSortedViewCache
        ? _sortedFullViewCache?.viewIndexesFor(
            recordCount: records.length,
            sortSignature: sortSignature,
          )
        : null;

    if (cachedFullSortedView != null) {
      nextViewIndexes.addAll(cachedFullSortedView);
      onProgress?.call(progress: 0.95);
    } else if (selectedFilter == null &&
        preparedFilters.isEmpty &&
        preparedSearch == null &&
        retainedVisibleRecordIds.isEmpty &&
        preparedSorts.isEmpty) {
      if (_canUsePhysicalRangeView(records)) {
        nextViewIndexes.setPhysicalRange(records.length);
      } else {
        for (var recordIndex = 0; recordIndex < records.length; recordIndex++) {
          final record = records[recordIndex];
          if (record.state != FdcRecordState.deleted) {
            nextViewIndexes.add(recordIndex);
          }
        }
      }
      onProgress?.call(progress: 0.95);
    } else {
      final total = records.length;
      for (var recordIndex = 0; recordIndex < total; recordIndex++) {
        final record = records[recordIndex];
        if (record.state == FdcRecordState.deleted) {
          continue;
        }
        if (mustKeepRecordInView(record) ||
            retainedVisibleRecordIds.contains(record.id)) {
          nextViewIndexes.add(recordIndex);
        } else if (selectedFilter != null &&
            record.selected != selectedFilter) {
          continue;
        } else {
          var matches = true;
          for (final filter in preparedFilters) {
            final comparableValues = comparableFilterValues[filter];
            final filterMatches = comparableValues == null
                ? matchesPreparedDataSetFilter(
                    record.valueAt(filter.fieldIndex),
                    filter,
                  )
                : matchesPreparedComparableFilter(
                    comparableValues[recordIndex],
                    filter,
                  );

            if (!filterMatches) {
              matches = false;
              break;
            }
          }
          if (matches) {
            var searchMatches = true;
            if (preparedSearch != null) {
              searchMatches = preparedSearch.matches(record);
            }
            if (searchMatches) {
              nextViewIndexes.add(recordIndex);
            }
          }
        }

        if (recordIndex % yieldEveryRecords == 0) {
          final progress = total == 0
              ? 0.8
              : 0.05 + (recordIndex / total * 0.75);
          onProgress?.call(progress: progress);
          if (recordIndex % paintYieldEveryRecords == 0) {
            await _yieldForAsyncViewPaint();
          } else {
            await _yieldForAsyncViewChunk();
          }
        }
      }

      if (preparedSorts.isNotEmpty) {
        // Sorting is either inline for smaller views or isolate-backed for
        // large views, depending on dataset work options. The comparator phase
        // has no meaningful percentage, so switch progress consumers to
        // indeterminate mode while sorting is active.
        onProgress?.call(
          phase: FdcDataSetWorkPhase.sort,
          message: 'Sorting dataset',
        );
        await _yieldForAsyncViewChunk();
        await _sortViewIndexesAsync(
          records: records,
          preparedSorts: preparedSorts,
          targetIndexes: nextViewIndexes,
          onProgress: onProgress,
        );

        if (canUseFullSortedViewCache) {
          _sortedFullViewCache = _FdcSortedFullViewCache(
            recordCount: records.length,
            sortSignature: sortSignature,
            sortFieldIndexes: <int>{
              for (final sort in preparedSorts) sort.fieldIndex,
            },
            viewIndexes: List<int>.unmodifiable(nextViewIndexes),
          );
        }
      }
    }

    onProgress?.call(progress: 0.98);
    var nextIndex = _normalizeIndexForCount(
      currentIndex,
      nextViewIndexes.length,
    );
    if (preserveRecordId != null) {
      final preservedIndex = _activeIndexForRecordIdInIndexes(
        preserveRecordId,
        records: records,
        indexes: nextViewIndexes,
      );
      if (preservedIndex >= 0) {
        nextIndex = preservedIndex;
      }
    }

    _viewIndexStorage.replaceWith(nextViewIndexes);

    onProgress?.call(progress: 1.0);

    return nextIndex;
  }

  int _normalizeIndexForCount(int currentIndex, int count) {
    if (count == 0) {
      return -1;
    }
    if (currentIndex < 0) {
      return 0;
    }
    if (currentIndex >= count) {
      return count - 1;
    }
    return currentIndex;
  }

  int _activeIndexForRecordIdInIndexes(
    int recordId, {
    required List<FdcRecord> records,
    required List<int> indexes,
  }) {
    for (var viewIndex = 0; viewIndex < indexes.length; viewIndex++) {
      final rawIndex = indexes[viewIndex];
      if (rawIndex < 0 || rawIndex >= records.length) {
        continue;
      }
      if (records[rawIndex].id == recordId) {
        return viewIndex;
      }
    }
    return -1;
  }

  void _sortViewIndexes({
    required List<FdcRecord> records,
    required List<_PreparedDataSetSort> preparedSorts,
    List<int>? targetIndexes,
  }) {
    final compiledSorts = _compiledSortsFor(
      records: records,
      preparedSorts: preparedSorts,
    );
    final indexes = targetIndexes ?? viewIndexes;
    _sortIndexesInline(indexes: indexes, compiledSorts: compiledSorts);
  }

  Future<void> _sortViewIndexesAsync({
    required List<FdcRecord> records,
    required List<_PreparedDataSetSort> preparedSorts,
    required List<int> targetIndexes,
    void Function({
      double? progress,
      String? message,
      FdcDataSetWorkPhase? phase,
    })?
    onProgress,
  }) async {
    final useIsolate = _shouldUseIsolateSort(targetIndexes.length);
    if (!useIsolate) {
      _sortViewIndexes(
        records: records,
        preparedSorts: preparedSorts,
        targetIndexes: targetIndexes,
      );
      return;
    }

    // Build compact rank arrays on the UI isolate, then move the O(n log n)
    // comparator sort itself to a background isolate. This keeps the public
    // viewIndexes publish atomic while preventing large List.sort() operations
    // from freezing the Flutter UI isolate.
    onProgress?.call(
      progress: 0.82,
      phase: FdcDataSetWorkPhase.sort,
      message: 'Preparing sort keys',
    );
    final compiledSorts = await _compiledSortsForAsync(
      records: records,
      preparedSorts: preparedSorts,
      onProgress: onProgress,
    );

    onProgress?.call(
      phase: FdcDataSetWorkPhase.sort,
      message: 'Sorting dataset in background',
    );

    final payload = <String, Object?>{
      'indexes': List<int>.of(targetIndexes, growable: false),
      'ranks': <List<int?>>[for (final sort in compiledSorts) sort.ranks],
      'ascending': <bool>[for (final sort in compiledSorts) sort.ascending],
    };
    try {
      final sortedIndexes = await fdcRunInBackground<List<int>>(
        () => _fdcSortIndexesInIsolate(payload),
      );
      targetIndexes
        ..clear()
        ..addAll(sortedIndexes);
    } on Object catch (_) {
      // Isolate sort is an optimization, not a correctness dependency. If a
      // platform/test environment rejects the payload, fall back to the
      // existing inline engine and preserve behavior.
      _sortIndexesInline(indexes: targetIndexes, compiledSorts: compiledSorts);
    }
  }

  bool _shouldUseIsolateSort(int viewCount) {
    final mode = operationOptions.sortExecutionMode;
    if (mode == FdcDataSetOperationExecutionMode.inline) {
      return false;
    }
    if (mode == FdcDataSetOperationExecutionMode.isolate) {
      return viewCount > 1;
    }

    final threshold = operationOptions.isolateSortThreshold;
    return threshold > 0 && viewCount >= threshold;
  }

  List<_CompiledDataSetSort> _compiledSortsFor({
    required List<FdcRecord> records,
    required List<_PreparedDataSetSort> preparedSorts,
  }) {
    final compiledSorts = <_CompiledDataSetSort>[];
    for (final sort in preparedSorts) {
      final ranks = _sortRanksFor(
        records: records,
        fieldIndex: sort.fieldIndex,
        dataType: sort.dataType,
        compareByDay: sort.dataType == FdcDataType.date,
      );
      compiledSorts.add(
        _CompiledDataSetSort(ranks: ranks, ascending: sort.ascending),
      );
    }
    return compiledSorts;
  }

  Future<List<_CompiledDataSetSort>> _compiledSortsForAsync({
    required List<FdcRecord> records,
    required List<_PreparedDataSetSort> preparedSorts,
    void Function({
      double? progress,
      String? message,
      FdcDataSetWorkPhase? phase,
    })?
    onProgress,
  }) async {
    final compiledSorts = <_CompiledDataSetSort>[];
    if (preparedSorts.isEmpty) {
      return compiledSorts;
    }

    for (var sortIndex = 0; sortIndex < preparedSorts.length; sortIndex++) {
      final sort = preparedSorts[sortIndex];
      final ranks = await _sortRanksForAsync(
        records: records,
        fieldIndex: sort.fieldIndex,
        dataType: sort.dataType,
        compareByDay: sort.dataType == FdcDataType.date,
        sortIndex: sortIndex,
        sortCount: preparedSorts.length,
        onProgress: onProgress,
      );
      compiledSorts.add(
        _CompiledDataSetSort(ranks: ranks, ascending: sort.ascending),
      );
    }
    return compiledSorts;
  }

  void _sortIndexesInline({
    required List<int> indexes,
    required List<_CompiledDataSetSort> compiledSorts,
    VoidCallback? onComparison,
  }) {
    indexes.sort((leftIndex, rightIndex) {
      onComparison?.call();
      for (final sort in compiledSorts) {
        final compare = _compareNullableSortRanks(
          sort.ranks[leftIndex],
          sort.ranks[rightIndex],
        );
        if (compare != 0) {
          return sort.ascending ? compare : -compare;
        }
      }

      return leftIndex.compareTo(rightIndex);
    });
  }

  String _sortSignatureFor(List<_PreparedDataSetSort> preparedSorts) {
    if (preparedSorts.isEmpty) {
      return '';
    }
    return preparedSorts
        .map(
          (sort) =>
              '${sort.fieldIndex}|${sort.ascending}|${sort.dataType.name}',
        )
        .join(';');
  }

  List<_PreparedDataSetSort> _prepareSorts({
    required List<FdcFieldDef> fields,
    required Map<String, int> fieldIndexByName,
  }) {
    if (sorts.isEmpty) {
      return const <_PreparedDataSetSort>[];
    }

    final result = <_PreparedDataSetSort>[];
    for (final sort in sorts) {
      final fieldIndex =
          fieldIndexByName[FdcFieldName.normalize(sort.fieldName)];
      if (fieldIndex == null) {
        continue;
      }

      result.add(
        _PreparedDataSetSort(
          fieldIndex: fieldIndex,
          ascending: sort.sortType.isAscending,
          dataType: fields[fieldIndex].dataType,
        ),
      );
    }
    return result;
  }

  List<Object?> _comparableValuesFor({
    required List<FdcRecord> records,
    required int fieldIndex,
    required FdcDataType dataType,
    required bool compareByDay,
    FdcDataSetValueResolver? valueResolver,
    required bool usePrimitiveComparable,
    required bool useNormalizedTextComparable,
    required bool caseSensitive,
  }) {
    final cacheKey = _comparableValueCacheKey(
      fieldIndex: fieldIndex,
      dataType: dataType,
      compareByDay: compareByDay,
      valueResolver: valueResolver,
      usePrimitiveComparable: usePrimitiveComparable,
      useNormalizedTextComparable: useNormalizedTextComparable,
      caseSensitive: caseSensitive,
    );
    final cached = comparableValueCache[cacheKey];
    if (cached != null && cached.length == records.length) {
      return cached;
    }

    final values = List<Object?>.generate(records.length, (recordIndex) {
      final value = records[recordIndex].valueAt(fieldIndex);
      if (usePrimitiveComparable) {
        return primitiveComparableValue(
          value,
          dataType,
          compareByDay: compareByDay,
          valueResolver: valueResolver,
        );
      }
      if (useNormalizedTextComparable) {
        return normalizedTextDataSetValue(
          value,
          caseSensitive: caseSensitive,
          valueResolver: valueResolver,
        );
      }
      return comparableDataSetRecordValue(
        value,
        dataType,
        compareByDay: compareByDay,
        valueResolver: valueResolver,
      );
    }, growable: false);
    comparableValueCache[cacheKey] = values;
    return values;
  }

  List<Object?> _sortComparableValuesFor({
    required List<FdcRecord> records,
    required int fieldIndex,
    required FdcDataType dataType,
    required bool compareByDay,
    FdcDataSetValueResolver? valueResolver,
  }) {
    final cacheKey = _comparableValueCacheKey(
      fieldIndex: fieldIndex,
      dataType: dataType,
      compareByDay: compareByDay,
      valueResolver: valueResolver,
      usage: _fdcComparableCacheUsageSort,
      usePrimitiveComparable: true,
    );
    final cached = _cachedSortComparableValues(cacheKey, records.length);
    if (cached != null) {
      return cached;
    }

    final values = List<Object?>.generate(records.length, (recordIndex) {
      return _sortComparableDataSetRecordValue(
        records[recordIndex].valueAt(fieldIndex),
        dataType,
        compareByDay: compareByDay,
        valueResolver: valueResolver,
      );
    }, growable: false);
    _cacheSortComparableValues(cacheKey, values);
    return values;
  }

  List<int?> _sortRanksFor({
    required List<FdcRecord> records,
    required int fieldIndex,
    required FdcDataType dataType,
    required bool compareByDay,
    FdcDataSetValueResolver? valueResolver,
  }) {
    final cacheKey = _sortRankCacheKey(
      fieldIndex: fieldIndex,
      dataType: dataType,
      compareByDay: compareByDay,
      valueResolver: valueResolver,
    );
    final cached = _cachedSortRanks(cacheKey, records.length);
    if (cached != null) {
      return cached;
    }

    if (_canUsePrimitiveSortRanks(dataType)) {
      final ranks = _primitiveSortRanksFor(
        records: records,
        fieldIndex: fieldIndex,
        dataType: dataType,
        compareByDay: compareByDay,
        valueResolver: valueResolver,
      );
      _cacheSortRanks(cacheKey, ranks);
      return ranks;
    }

    final values = _sortComparableValuesFor(
      records: records,
      fieldIndex: fieldIndex,
      dataType: dataType,
      compareByDay: compareByDay,
      valueResolver: valueResolver,
    );
    final ranks = _sortRanksForValues(values, dataType);
    _cacheSortRanks(cacheKey, ranks);
    return ranks;
  }

  Future<List<Object?>> _sortComparableValuesForAsync({
    required List<FdcRecord> records,
    required int fieldIndex,
    required FdcDataType dataType,
    required bool compareByDay,
    FdcDataSetValueResolver? valueResolver,
    required double progressStart,
    required double progressEnd,
    void Function({
      double? progress,
      String? message,
      FdcDataSetWorkPhase? phase,
    })?
    onProgress,
  }) async {
    final cacheKey = _comparableValueCacheKey(
      fieldIndex: fieldIndex,
      dataType: dataType,
      compareByDay: compareByDay,
      valueResolver: valueResolver,
      usage: _fdcComparableCacheUsageSort,
      usePrimitiveComparable: true,
    );
    final cached = _cachedSortComparableValues(cacheKey, records.length);
    if (cached != null) {
      return cached;
    }

    final values = List<Object?>.filled(records.length, null);
    final yieldEveryRecords = operationOptions.cooperativeChunkSize <= 0
        ? 8192
        : operationOptions.cooperativeChunkSize;
    final total = records.length;
    for (var recordIndex = 0; recordIndex < total; recordIndex++) {
      values[recordIndex] = _sortComparableDataSetRecordValue(
        records[recordIndex].valueAt(fieldIndex),
        dataType,
        compareByDay: compareByDay,
        valueResolver: valueResolver,
      );

      if (recordIndex % yieldEveryRecords == 0) {
        final localProgress = total == 0 ? 1.0 : recordIndex / total;
        onProgress?.call(
          progress:
              progressStart + ((progressEnd - progressStart) * localProgress),
          phase: FdcDataSetWorkPhase.sort,
          message: 'Preparing sort keys',
        );
        await _yieldForAsyncViewChunk();
      }
    }

    _cacheSortComparableValues(cacheKey, values);
    return values;
  }

  Future<List<int?>> _sortRanksForAsync({
    required List<FdcRecord> records,
    required int fieldIndex,
    required FdcDataType dataType,
    required bool compareByDay,
    FdcDataSetValueResolver? valueResolver,
    required int sortIndex,
    required int sortCount,
    void Function({
      double? progress,
      String? message,
      FdcDataSetWorkPhase? phase,
    })?
    onProgress,
  }) async {
    final cacheKey = _sortRankCacheKey(
      fieldIndex: fieldIndex,
      dataType: dataType,
      compareByDay: compareByDay,
      valueResolver: valueResolver,
    );
    final cached = _cachedSortRanks(cacheKey, records.length);
    if (cached != null) {
      return cached;
    }

    final sortSpan = sortCount <= 0 ? 1.0 : 1.0 / sortCount;
    final sortStart = 0.82 + (sortIndex * sortSpan * 0.12);
    final valuesEnd = sortStart + (sortSpan * 0.06);
    final ranksEnd = sortStart + (sortSpan * 0.12);

    if (_canUsePrimitiveSortRanks(dataType)) {
      final ranks = await _primitiveSortRanksForAsync(
        records: records,
        fieldIndex: fieldIndex,
        dataType: dataType,
        compareByDay: compareByDay,
        valueResolver: valueResolver,
        progressStart: sortStart,
        progressEnd: ranksEnd,
        onProgress: onProgress,
      );
      _cacheSortRanks(cacheKey, ranks);
      return ranks;
    }

    final values = await _sortComparableValuesForAsync(
      records: records,
      fieldIndex: fieldIndex,
      dataType: dataType,
      compareByDay: compareByDay,
      valueResolver: valueResolver,
      progressStart: sortStart,
      progressEnd: valuesEnd,
      onProgress: onProgress,
    );

    onProgress?.call(
      progress: valuesEnd,
      phase: FdcDataSetWorkPhase.sort,
      message: 'Ranking sort keys',
    );
    await _yieldForAsyncViewChunk();

    final ranks = await _sortRanksForValuesAsync(
      values,
      dataType,
      progressStart: valuesEnd,
      progressEnd: ranksEnd,
      onProgress: onProgress,
    );
    _cacheSortRanks(cacheKey, ranks);
    return ranks;
  }

  String _comparableValueCacheKey({
    required int fieldIndex,
    required FdcDataType dataType,
    required bool compareByDay,
    FdcDataSetValueResolver? valueResolver,
    String usage = _fdcComparableCacheUsageValue,
    bool usePrimitiveComparable = false,
    bool useNormalizedTextComparable = false,
    bool caseSensitive = false,
  }) {
    return '$usage|$fieldIndex|${dataType.name}|$compareByDay|'
        '$usePrimitiveComparable|$useNormalizedTextComparable|$caseSensitive|'
        '${identityHashCode(valueResolver)}';
  }

  String _sortRankCacheKey({
    required int fieldIndex,
    required FdcDataType dataType,
    required bool compareByDay,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return '$_fdcSortRankCacheUsage|$fieldIndex|${dataType.name}|'
        '$compareByDay|${identityHashCode(valueResolver)}';
  }
}

bool _isComparableCacheKeyForField(String key, int fieldIndex) {
  return key.startsWith('$_fdcComparableCacheUsageValue|$fieldIndex|') ||
      key.startsWith('$_fdcComparableCacheUsageSort|$fieldIndex|');
}

bool _isSortRankCacheKeyForField(String key, int fieldIndex) {
  return key.startsWith('$_fdcSortRankCacheUsage|$fieldIndex|');
}

bool _canUsePrimitiveSortRanks(FdcDataType dataType) {
  return dataType == FdcDataType.integer ||
      dataType == FdcDataType.boolean ||
      dataType == FdcDataType.date ||
      dataType == FdcDataType.dateTime ||
      dataType == FdcDataType.time;
}

List<int?> _primitiveSortRanksFor({
  required List<FdcRecord> records,
  required int fieldIndex,
  required FdcDataType dataType,
  required bool compareByDay,
  FdcDataSetValueResolver? valueResolver,
}) {
  final keys = List<int?>.filled(records.length, null);
  final uniqueKeys = <int>[];
  final seenKeys = <int>{};

  for (var recordIndex = 0; recordIndex < records.length; recordIndex++) {
    final key = _primitiveSortKeyOrNull(
      records[recordIndex].valueAt(fieldIndex),
      dataType,
      compareByDay: compareByDay,
      valueResolver: valueResolver,
    );
    keys[recordIndex] = key;
    if (key != null && seenKeys.add(key)) {
      uniqueKeys.add(key);
    }
  }

  uniqueKeys.sort();
  final ranksByKey = <int, int>{};
  for (var index = 0; index < uniqueKeys.length; index++) {
    ranksByKey[uniqueKeys[index]] = index;
  }

  return List<int?>.generate(keys.length, (index) {
    final key = keys[index];
    return key == null ? null : ranksByKey[key];
  }, growable: false);
}

Future<List<int?>> _primitiveSortRanksForAsync({
  required List<FdcRecord> records,
  required int fieldIndex,
  required FdcDataType dataType,
  required bool compareByDay,
  FdcDataSetValueResolver? valueResolver,
  required double progressStart,
  required double progressEnd,
  void Function({
    double? progress,
    String? message,
    FdcDataSetWorkPhase? phase,
  })?
  onProgress,
}) async {
  final keys = List<int?>.filled(records.length, null);
  final uniqueKeys = <int>[];
  final seenKeys = <int>{};
  const yieldEveryRecords = 8192;
  final total = records.length;

  for (var recordIndex = 0; recordIndex < total; recordIndex++) {
    final key = _primitiveSortKeyOrNull(
      records[recordIndex].valueAt(fieldIndex),
      dataType,
      compareByDay: compareByDay,
      valueResolver: valueResolver,
    );
    keys[recordIndex] = key;
    if (key != null && seenKeys.add(key)) {
      uniqueKeys.add(key);
    }

    if (recordIndex % yieldEveryRecords == 0) {
      final localProgress = total == 0 ? 1.0 : recordIndex / total;
      onProgress?.call(
        progress:
            progressStart +
            ((progressEnd - progressStart) * 0.45 * localProgress),
        phase: FdcDataSetWorkPhase.sort,
        message: 'Preparing primitive sort keys',
      );
      await _yieldForAsyncViewChunk();
    }
  }

  onProgress?.call(
    progress: progressStart + ((progressEnd - progressStart) * 0.50),
    phase: FdcDataSetWorkPhase.sort,
    message: 'Ranking primitive sort keys',
  );
  await _yieldForAsyncViewChunk();

  uniqueKeys.sort();
  final ranksByKey = <int, int>{};
  for (var index = 0; index < uniqueKeys.length; index++) {
    ranksByKey[uniqueKeys[index]] = index;
  }

  final ranks = List<int?>.filled(keys.length, null);
  for (var index = 0; index < keys.length; index++) {
    final key = keys[index];
    if (key != null) {
      ranks[index] = ranksByKey[key];
    }

    if (index % yieldEveryRecords == 0) {
      final localProgress = keys.isEmpty ? 1.0 : index / keys.length;
      onProgress?.call(
        progress:
            progressStart +
            ((progressEnd - progressStart) * (0.55 + (0.45 * localProgress))),
        phase: FdcDataSetWorkPhase.sort,
        message: 'Applying primitive sort ranks',
      );
      await _yieldForAsyncViewChunk();
    }
  }

  onProgress?.call(
    progress: progressEnd,
    phase: FdcDataSetWorkPhase.sort,
    message: 'Primitive sort keys ready',
  );
  return ranks;
}

int? _primitiveSortKeyOrNull(
  Object? value,
  FdcDataType dataType, {
  required bool compareByDay,
  FdcDataSetValueResolver? valueResolver,
}) {
  final key = primitiveComparableValue(
    value,
    dataType,
    compareByDay: compareByDay,
    valueResolver: valueResolver,
  );
  return key is int ? key : null;
}

List<int?> _sortRanksForValues(List<Object?> values, FdcDataType dataType) {
  final uniqueValues = <Object?>[];
  final seenKeys = <Object>{};

  for (final value in values) {
    if (value == null) {
      continue;
    }
    final key = _sortRankKey(value, dataType);
    if (!seenKeys.add(key)) {
      continue;
    }
    uniqueValues.add(value);
  }

  uniqueValues.sort(
    (left, right) => _comparePreparedSortValues(left, right, dataType),
  );

  final ranksByKey = <Object, int>{};
  for (var index = 0; index < uniqueValues.length; index++) {
    ranksByKey[_sortRankKey(uniqueValues[index]!, dataType)] = index;
  }

  return List<int?>.generate(values.length, (index) {
    final value = values[index];
    if (value == null) {
      return null;
    }
    return ranksByKey[_sortRankKey(value, dataType)];
  }, growable: false);
}

Future<List<int?>> _sortRanksForValuesAsync(
  List<Object?> values,
  FdcDataType dataType, {
  required double progressStart,
  required double progressEnd,
  void Function({
    double? progress,
    String? message,
    FdcDataSetWorkPhase? phase,
  })?
  onProgress,
}) async {
  final uniqueValues = <Object?>[];
  final seenKeys = <Object>{};
  const yieldEveryValues = 8192;

  for (var index = 0; index < values.length; index++) {
    final value = values[index];
    if (value != null) {
      final key = _sortRankKey(value, dataType);
      if (seenKeys.add(key)) {
        uniqueValues.add(value);
      }
    }

    if (index % yieldEveryValues == 0) {
      final localProgress = values.isEmpty ? 1.0 : index / values.length;
      onProgress?.call(
        progress:
            progressStart +
            ((progressEnd - progressStart) * 0.30 * localProgress),
        phase: FdcDataSetWorkPhase.sort,
        message: 'Collecting sort keys',
      );
      await _yieldForAsyncViewChunk();
    }
  }

  onProgress?.call(
    progress: progressStart + ((progressEnd - progressStart) * 0.35),
    phase: FdcDataSetWorkPhase.sort,
    message: 'Ordering sort keys',
  );
  await _yieldForAsyncViewChunk();

  // Sorting the unique key set is still synchronous, but it is usually much
  // smaller than the full row count. The heavy row comparator sort is handled
  // by the isolate-backed path.
  uniqueValues.sort(
    (left, right) => _comparePreparedSortValues(left, right, dataType),
  );

  final ranksByKey = <Object, int>{};
  for (var index = 0; index < uniqueValues.length; index++) {
    ranksByKey[_sortRankKey(uniqueValues[index]!, dataType)] = index;
  }

  final ranks = List<int?>.filled(values.length, null);
  for (var index = 0; index < values.length; index++) {
    final value = values[index];
    if (value != null) {
      ranks[index] = ranksByKey[_sortRankKey(value, dataType)];
    }

    if (index % yieldEveryValues == 0) {
      final localProgress = values.isEmpty ? 1.0 : index / values.length;
      onProgress?.call(
        progress:
            progressStart +
            ((progressEnd - progressStart) * (0.55 + (0.45 * localProgress))),
        phase: FdcDataSetWorkPhase.sort,
        message: 'Applying sort ranks',
      );
      await _yieldForAsyncViewChunk();
    }
  }

  onProgress?.call(
    progress: progressEnd,
    phase: FdcDataSetWorkPhase.sort,
    message: 'Sort keys ready',
  );
  return ranks;
}

Object? _sortComparableDataSetRecordValue(
  Object? value,
  FdcDataType dataType, {
  required bool compareByDay,
  FdcDataSetValueResolver? valueResolver,
}) {
  // Sort and comparable filter paths intentionally share the same primitive-key
  // conversion. This keeps temporal fields on compact integers and prevents
  // DateTime/FdcTime object comparison logic from diverging between filtering,
  // searching and sorting.
  return primitiveComparableValue(
    value,
    dataType,
    compareByDay: compareByDay,
    valueResolver: valueResolver,
  );
}

int _comparePreparedSortValues(
  Object? left,
  Object? right,
  FdcDataType dataType,
) {
  if (left == null && right == null) {
    return 0;
  }
  if (left == null) {
    return 1;
  }
  if (right == null) {
    return -1;
  }
  if (left is int && right is int) {
    return left.compareTo(right);
  }
  if (left is num && right is num) {
    return left.compareTo(right);
  }
  return compareDataSetSortValues(left, right, dataType);
}

Object _sortRankKey(Object value, FdcDataType dataType) {
  if (dataType == FdcDataType.string ||
      dataType == FdcDataType.guid ||
      dataType == FdcDataType.object) {
    return value.toString();
  }
  return value;
}

int _compareNullableSortRanks(int? left, int? right) {
  if (left == null && right == null) {
    return 0;
  }
  if (left == null) {
    return 1;
  }
  if (right == null) {
    return -1;
  }
  return left.compareTo(right);
}

List<int> _fdcSortIndexesInIsolate(Map<String, Object?> payload) {
  final indexes = List<int>.of((payload['indexes'] as List).cast<int>());
  final rankPayload = (payload['ranks'] as List)
      .map((item) => (item as List).cast<int?>())
      .toList(growable: false);
  final ascending = (payload['ascending'] as List).cast<bool>();

  indexes.sort((leftIndex, rightIndex) {
    for (var sortIndex = 0; sortIndex < rankPayload.length; sortIndex++) {
      final ranks = rankPayload[sortIndex];
      final compare = _compareNullableSortRanks(
        ranks[leftIndex],
        ranks[rightIndex],
      );
      if (compare != 0) {
        return ascending[sortIndex] ? compare : -compare;
      }
    }

    return leftIndex.compareTo(rightIndex);
  });

  return indexes;
}

Future<void> _yieldForAsyncViewChunk() async {
  // Keep async rebuild loops cooperative without scheduling zero-duration
  // timers. Fake-async widget tests treat those timers as pending work if a
  // grid-triggered async rebuild is still unwinding during disposal. A
  // microtask handoff preserves async sequencing and lets awaited API calls
  // cleanly in tests without introducing artificial slowdown.
  await Future<void>.value();
}

Future<void> _yieldForAsyncViewPaint() async {
  // A microtask yield keeps async APIs cooperative, but it does not give timers
  // and frames a chance to run. Long scans need an occasional event/frame yield
  // so dataset progress bars can poll/repaint while the scan is still active.
  try {
    await SchedulerBinding.instance.endOfFrame;
    return;
    // ignore: avoid_catching_errors
  } on FlutterError {
    // Pure VM tests may run without a Flutter binding. Fall back to one event
    // loop turn so Timer-based progress polling can still observe updates.
  }
  await Future<void>.delayed(Duration.zero);
}

class _FdcSortedFullViewCache {
  const _FdcSortedFullViewCache({
    required this.recordCount,
    required this.sortSignature,
    required this.sortFieldIndexes,
    required this.viewIndexes,
  });

  final int recordCount;
  final String sortSignature;
  final Set<int> sortFieldIndexes;
  final List<int> viewIndexes;

  bool dependsOnField(int fieldIndex) => sortFieldIndexes.contains(fieldIndex);

  List<int>? viewIndexesFor({
    required int recordCount,
    required String sortSignature,
  }) {
    if (this.recordCount != recordCount ||
        this.sortSignature != sortSignature) {
      return null;
    }
    return viewIndexes;
  }
}

class _CompiledDataSetSort {
  const _CompiledDataSetSort({required this.ranks, required this.ascending});

  final List<int?> ranks;
  final bool ascending;
}

class _PreparedDataSetSort {
  const _PreparedDataSetSort({
    required this.fieldIndex,
    required this.ascending,
    required this.dataType,
  });

  final int fieldIndex;
  final bool ascending;
  final FdcDataType dataType;
}
