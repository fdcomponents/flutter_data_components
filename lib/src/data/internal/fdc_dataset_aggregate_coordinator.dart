// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../common/fdc_aggregate.dart';
import '../aggregation/fdc_dataset_aggregator.dart';
import '../fdc_data_adapter.dart';
import '../fdc_data_type.dart';
import '../fdc_dataset_field_writer.dart';
import '../fdc_dataset_filter.dart';
import '../fdc_field_def.dart';
import '../fdc_field_name.dart';
import '../types/fdc_decimal.dart';

/// Internal owner of dataset aggregate cache state.
///
/// The dataset remains the public facade and retains adapter request/work
/// orchestration. This coordinator owns local cached calculation, adapter cache
/// lookup/storage, invalidation, revisions, and incremental cache maintenance.
final class FdcDataSetAggregateCoordinator {
  final Map<FdcDataSetAggregateCacheKey, FdcDataSetAggregateCacheEntry>
  _localCache = <FdcDataSetAggregateCacheKey, FdcDataSetAggregateCacheEntry>{};

  final Map<FdcDataAggregateKey, Object?> _adapterCache =
      <FdcDataAggregateKey, Object?>{};

  int adapterRevision = 0;

  int get localCacheCount => _localCache.length;

  int get adapterCacheCount => _adapterCache.length;

  Object? cachedValue({
    required String fieldName,
    required FdcAggregate aggregate,
    required FdcDataSetAggregator Function() createAggregator,
  }) {
    final normalizedFieldName = FdcFieldName.normalize(fieldName);
    final key = FdcDataSetAggregateCacheKey(
      fieldName: normalizedFieldName,
      aggregate: aggregate,
    );
    final cached = _localCache[key];
    if (cached != null && cached.isValid) {
      return cached.value;
    }

    final aggregator = createAggregator();
    if (aggregate == FdcAggregate.avg) {
      final state = aggregator.avgState(normalizedFieldName);
      _localCache[key] = FdcDataSetAggregateCacheEntry.avg(state);
      return state.value;
    }

    final value = aggregator.aggregate(normalizedFieldName, aggregate);
    _localCache[key] = FdcDataSetAggregateCacheEntry(value: value);
    return value;
  }

  FdcDataAggregateResult? adapterResultFromCache(
    List<FdcDataAggregateItem> aggregates,
  ) {
    if (_adapterCache.isEmpty) {
      return null;
    }

    final values = <FdcDataAggregateKey, Object?>{};
    for (final item in aggregates) {
      final key = FdcDataAggregateKey(
        fieldName: item.fieldName,
        aggregate: item.aggregate,
      );
      if (!_adapterCache.containsKey(key)) {
        return null;
      }
      values[key] = _adapterCache[key];
    }

    return FdcDataAggregateResult(values: Map.unmodifiable(values));
  }

  void storeAdapterResult(FdcDataAggregateResult result) {
    _adapterCache.addAll(result.values);
  }

  void invalidate({required bool adapterQueryChanged}) {
    if (adapterQueryChanged) {
      adapterRevision++;
      _adapterCache.clear();
    }
    _localCache.clear();
  }

  void markAdapterChanged() {
    adapterRevision++;
  }

  void clearAdapter() {
    _adapterCache.clear();
  }

  void clear() {
    _localCache.clear();
    _adapterCache.clear();
    adapterRevision = 0;
  }

  /// Incrementally updates or invalidates cached aggregates for field changes.
  ///
  /// Calculated fields without an explicit dependency graph are conservatively
  /// invalidated whenever another field changes.
  void invalidateForChanges(
    List<FdcFieldDef> fields,
    List<FdcFieldChange> changes,
  ) {
    if (changes.isEmpty) {
      return;
    }

    final changedFieldNames = <String>{};
    for (final change in changes) {
      if (change.fieldIndex >= 0 && change.fieldIndex < fields.length) {
        final fieldName = FdcFieldName.normalize(
          fields[change.fieldIndex].name,
        );
        changedFieldNames.add(fieldName);
        _updateForFieldChange(fieldName, fields[change.fieldIndex], change);
      }
    }

    for (final field in fields) {
      if (!field.isCalculated) {
        continue;
      }
      final fieldName = FdcFieldName.normalize(field.name);
      if (!changedFieldNames.contains(fieldName)) {
        _invalidateField(fieldName);
      }
    }
  }

  void _invalidateField(String fieldName) {
    _localCache.removeWhere((key, _) => key.fieldName == fieldName);
  }

  void _updateForFieldChange(
    String fieldName,
    FdcFieldDef field,
    FdcFieldChange change,
  ) {
    for (final entry in _localCache.entries.toList()) {
      final key = entry.key;
      if (key.fieldName != fieldName) {
        continue;
      }

      final cacheEntry = entry.value;
      if (!cacheEntry.isValid) {
        continue;
      }

      final updated = _incrementalValue(
        key.aggregate,
        field,
        key.aggregate == FdcAggregate.avg ? cacheEntry : cacheEntry.value,
        change.oldValue,
        change.newValue,
      );
      switch (updated) {
        case FdcAggregateIncrementalUnsupported():
          _localCache.remove(key);
        case FdcAggregateIncrementalSupported(:final value):
          cacheEntry.value = value;
      }
    }
  }

  FdcAggregateIncrementalResult _incrementalValue(
    FdcAggregate aggregate,
    FdcFieldDef field,
    Object? cachedValue,
    Object? oldValue,
    Object? newValue,
  ) {
    return switch (aggregate) {
      FdcAggregate.sum => _incrementalSum(
        field,
        cachedValue,
        oldValue,
        newValue,
      ),
      FdcAggregate.avg => _incrementalAvg(
        field,
        cachedValue,
        oldValue,
        newValue,
      ),
      FdcAggregate.min => _incrementalMinMax(
        field,
        cachedValue,
        oldValue,
        newValue,
        findMin: true,
      ),
      FdcAggregate.max => _incrementalMinMax(
        field,
        cachedValue,
        oldValue,
        newValue,
        findMin: false,
      ),
    };
  }

  FdcAggregateIncrementalResult _incrementalSum(
    FdcFieldDef field,
    Object? cachedValue,
    Object? oldValue,
    Object? newValue,
  ) {
    if (cachedValue is! FdcDecimal || !_isNumericField(field)) {
      return FdcAggregateIncrementalResult.unsupported;
    }

    final oldDecimal = _decimalValueOrNull(oldValue);
    final newDecimal = _decimalValueOrNull(newValue);
    return FdcAggregateIncrementalResult.supported(
      cachedValue -
          (oldDecimal ?? FdcDecimal.zero) +
          (newDecimal ?? FdcDecimal.zero),
    );
  }

  FdcAggregateIncrementalResult _incrementalAvg(
    FdcFieldDef field,
    Object? cachedValue,
    Object? oldValue,
    Object? newValue,
  ) {
    if (cachedValue is! FdcDataSetAggregateCacheEntry ||
        !_isNumericField(field)) {
      return FdcAggregateIncrementalResult.unsupported;
    }

    final oldDecimal = _decimalValueOrNull(oldValue);
    final newDecimal = _decimalValueOrNull(newValue);
    var sum = cachedValue.sum ?? FdcDecimal.zero;
    var count = cachedValue.count;

    if (oldDecimal != null) {
      sum -= oldDecimal;
      count--;
    }
    if (newDecimal != null) {
      sum += newDecimal;
      count++;
    }

    cachedValue.sum = sum;
    cachedValue.count = count;
    if (count == 0) {
      return const FdcAggregateIncrementalResult.supported(null);
    }
    final average = sum / count;
    return average is FdcDecimal
        ? FdcAggregateIncrementalResult.supported(average)
        : FdcAggregateIncrementalResult.unsupported;
  }

  FdcAggregateIncrementalResult _incrementalMinMax(
    FdcFieldDef field,
    Object? cachedValue,
    Object? oldValue,
    Object? newValue, {
    required bool findMin,
  }) {
    if (cachedValue == null) {
      return FdcAggregateIncrementalResult.supported(newValue);
    }
    if (newValue == null) {
      return FdcAggregateIncrementalResult.unsupported;
    }

    final newCompare = compareDataSetSortValues(
      newValue,
      cachedValue,
      field.dataType,
    );
    if ((findMin && newCompare < 0) || (!findMin && newCompare > 0)) {
      return FdcAggregateIncrementalResult.supported(newValue);
    }

    if (oldValue == null) {
      return FdcAggregateIncrementalResult.supported(cachedValue);
    }
    final oldCompare = compareDataSetSortValues(
      oldValue,
      cachedValue,
      field.dataType,
    );
    if (oldCompare == 0) {
      return FdcAggregateIncrementalResult.unsupported;
    }

    return FdcAggregateIncrementalResult.supported(cachedValue);
  }

  bool _isNumericField(FdcFieldDef field) {
    return field.dataType == FdcDataType.integer ||
        field.dataType == FdcDataType.decimal;
  }

  FdcDecimal? _decimalValueOrNull(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is FdcDecimal) {
      return value;
    }
    if (value is int) {
      return FdcDecimal.fromScaled(BigInt.from(value), scale: 0);
    }
    if (value is num && value.isFinite) {
      return FdcDecimal.fromNum(value);
    }
    return null;
  }

  void dispose() {
    clear();
  }
}

final class FdcDataSetAggregateCacheEntry {
  FdcDataSetAggregateCacheEntry({required this.value});

  FdcDataSetAggregateCacheEntry.avg(FdcAverageAggregateState state)
    : value = state.value,
      sum = state.sum,
      count = state.count;

  Object? value;
  FdcDecimal? sum;
  int count = 0;
  bool isValid = true;
}

sealed class FdcAggregateIncrementalResult {
  const FdcAggregateIncrementalResult._();

  const factory FdcAggregateIncrementalResult.supported(Object? value) =
      FdcAggregateIncrementalSupported;

  static const FdcAggregateIncrementalUnsupported unsupported =
      FdcAggregateIncrementalUnsupported();
}

final class FdcAggregateIncrementalSupported
    extends FdcAggregateIncrementalResult {
  const FdcAggregateIncrementalSupported(this.value) : super._();

  final Object? value;
}

final class FdcAggregateIncrementalUnsupported
    extends FdcAggregateIncrementalResult {
  const FdcAggregateIncrementalUnsupported() : super._();
}

final class FdcDataSetAggregateCacheKey {
  const FdcDataSetAggregateCacheKey({
    required this.fieldName,
    required this.aggregate,
  });

  final String fieldName;
  final FdcAggregate aggregate;

  @override
  bool operator ==(Object other) {
    return other is FdcDataSetAggregateCacheKey &&
        other.fieldName == fieldName &&
        other.aggregate == aggregate;
  }

  @override
  int get hashCode => Object.hash(fieldName, aggregate);
}
