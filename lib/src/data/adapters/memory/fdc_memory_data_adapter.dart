// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import '../../../common/fdc_aggregate.dart';
import '../../../common/platform/fdc_background_runner.dart';
import '../../fdc_change_set.dart';
import '../../fdc_data_adapter.dart';
import '../../fdc_data_errors.dart';
import '../../fdc_dataset_search.dart';
import '../../fdc_field_def.dart';
import '../../fdc_field_name.dart';
import '../../fdc_record.dart';
import '../../types/fdc_decimal.dart';

T _runMemoryInline<T>(T Function() body) => body();

/// In-memory adapter for local rows, tests, demos, and small client-side data.
///
/// The adapter supports synchronous opening and evaluates supported filter,
/// sort, search, paging, and aggregate operations against its in-memory rows.
class FdcMemoryDataAdapter extends FdcDataAdapter
    implements IFdcSynchronousDataAdapter {
  /// Creates an in-memory adapter backed by [rows].
  FdcMemoryDataAdapter({
    required List<Map<String, Object?>> rows,
    super.filters = const <FdcDataAdapterFilter>[],
    super.sorts = const <FdcDataAdapterSort>[],
  }) : _rows = <_FdcMemoryRow>[],
       super(
         readOnly: false,
         capabilities: const FdcDataAdapterCapabilities(
           filtering: true,
           sorting: true,
           paging: true,
           totalCount: true,
           search: true,
           aggregates: true,
           selectedKeyFiltering: true,
         ),
       ) {
    replaceRows(rows);
  }

  final List<_FdcMemoryRow> _rows;

  static const int _backgroundQueryRowThreshold = 2000;
  int _nextRowIdentity = 1;

  /// Returns a defensive copy of the current adapter rows.
  List<Map<String, Object?>> get rows =>
      _rows.map((entry) => Map<String, Object?>.of(entry.values)).toList();

  /// Replaces all rows managed by this adapter.
  void replaceRows(List<Map<String, Object?>> rows) {
    _rows
      ..clear()
      ..addAll(rows.map(_createRow));
  }

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    final rows = List<_FdcMemoryRow>.of(_rows, growable: false);
    final nextRowIdentity = _nextRowIdentity;
    if (rows.length < _backgroundQueryRowThreshold) {
      return _runMemoryInline(
        () => _FdcMemoryQueryExecutor.load(rows, nextRowIdentity, request),
      );
    }
    try {
      return await fdcRunInBackground<FdcDataLoadResult>(
        () => _FdcMemoryQueryExecutor.load(rows, nextRowIdentity, request),
      );
    } on Object catch (_) {
      return _runMemoryInline(
        () => _FdcMemoryQueryExecutor.load(rows, nextRowIdentity, request),
      );
    }
  }

  @override
  FdcDataLoadResult loadSync(FdcDataLoadRequest request) =>
      _FdcMemoryQueryExecutor.load(_rows, _nextRowIdentity, request);

  @override
  Future<FdcDataAggregateResult> aggregate(
    FdcDataAggregateRequest request,
  ) async {
    final rows = List<_FdcMemoryRow>.of(_rows, growable: false);
    if (rows.length < _backgroundQueryRowThreshold) {
      return _runMemoryInline(
        () => _FdcMemoryQueryExecutor.aggregate(rows, request),
      );
    }
    try {
      return await fdcRunInBackground<FdcDataAggregateResult>(
        () => _FdcMemoryQueryExecutor.aggregate(rows, request),
      );
    } on Object catch (_) {
      return _runMemoryInline(
        () => _FdcMemoryQueryExecutor.aggregate(rows, request),
      );
    }
  }

  /// Calculates aggregates synchronously against the in-memory rows.
  FdcDataAggregateResult aggregateSync(FdcDataAggregateRequest request) =>
      _FdcMemoryQueryExecutor.aggregate(_rows, request);

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    if (changes.isEmpty) {
      return const FdcDataApplyResult.success();
    }

    final nextRows = _rows.map((row) => row.copy()).toList();
    final keyFields = changes.fields
        .where((field) => field.isKey)
        .toList(growable: false);

    for (final delete in changes.deletes) {
      if (!_removeEntry(nextRows, delete, keyFields)) {
        return _missingEntryApplyResult(delete, operation: 'Delete');
      }
    }

    for (final update in changes.updates) {
      final row = _findEntryRow(nextRows, update, keyFields);
      if (row == null) {
        return _missingEntryApplyResult(update, operation: 'Update');
      }
      _mergeCaseInsensitive(row.values, update.values);
    }

    for (final insert in changes.inserts) {
      nextRows.add(
        _FdcMemoryRow(
          identity: insert.recordId,
          values: Map<String, Object?>.of(insert.values),
        ),
      );
      if (insert.recordId >= _nextRowIdentity) {
        _nextRowIdentity = insert.recordId + 1;
      }
    }

    _rows
      ..clear()
      ..addAll(nextRows);

    return const FdcDataApplyResult.success();
  }

  void _mergeCaseInsensitive(
    Map<String, Object?> target,
    Map<String, Object?> updates,
  ) {
    for (final update in updates.entries) {
      final existingKey = _existingKeyIgnoringCase(target, update.key);
      target[existingKey ?? update.key] = update.value;
    }
  }

  String? _existingKeyIgnoringCase(Map<String, Object?> values, String key) {
    final normalizedKey = FdcFieldName.normalize(key);
    for (final existingKey in values.keys) {
      if (FdcFieldName.normalize(existingKey) == normalizedKey) {
        return existingKey;
      }
    }
    return null;
  }

  _FdcMemoryRow _createRow(Map<String, Object?> row) {
    return _FdcMemoryRow(
      identity: _nextRowIdentity++,
      values: Map<String, Object?>.of(row),
    );
  }

  FdcDataApplyResult _missingEntryApplyResult(
    FdcChangeSetEntry entry, {
    required String operation,
  }) {
    return FdcDataApplyResult.failure(
      errors: <FdcDataApplyError>[
        FdcDataApplyError(
          recordId: entry.recordId,
          message: '$operation failed: no matching memory row was found.',
          code: 'not_found',
        ),
      ],
    );
  }

  _FdcMemoryRow? _findEntryRow(
    List<_FdcMemoryRow> rows,
    FdcChangeSetEntry entry,
    List<FdcFieldDef> keyFields,
  ) {
    final index = _findEntryIndex(rows, entry, keyFields);
    return index == null ? null : rows[index];
  }

  bool _removeEntry(
    List<_FdcMemoryRow> rows,
    FdcChangeSetEntry entry,
    List<FdcFieldDef> keyFields,
  ) {
    final index = _findEntryIndex(rows, entry, keyFields);
    if (index == null) {
      return false;
    }
    rows.removeAt(index);
    return true;
  }

  int? _findEntryIndex(
    List<_FdcMemoryRow> rows,
    FdcChangeSetEntry entry,
    List<FdcFieldDef> keyFields,
  ) {
    if (keyFields.isEmpty) {
      final index = rows.indexWhere((row) => row.identity == entry.recordId);
      return index < 0 ? null : index;
    }

    for (var i = 0; i < rows.length; i++) {
      if (_matchesEntry(rows[i].values, entry, keyFields)) {
        return i;
      }
    }
    return null;
  }

  bool _matchesEntry(
    Map<String, Object?> row,
    FdcChangeSetEntry entry,
    List<FdcFieldDef> keyFields,
  ) {
    final fieldNames = _entryMatchFieldNames(entry, keyFields);
    if (fieldNames.isEmpty) {
      return false;
    }

    for (final fieldName in fieldNames) {
      final rowValue = FdcFieldName.valueFromRow(
        row,
        fieldName,
        defaultValue: null,
      );
      final originalValue = FdcFieldName.valueFromRow(
        entry.originalValues,
        fieldName,
        defaultValue: null,
      );
      if (_compareValues(rowValue, originalValue) != 0) {
        return false;
      }
    }
    return true;
  }

  List<String> _entryMatchFieldNames(
    FdcChangeSetEntry entry,
    List<FdcFieldDef> keyFields,
  ) {
    if (keyFields.isEmpty) {
      return const <String>[];
    }
    final fieldNames = keyFields
        .map((keyField) => keyField.name)
        .toList(growable: false);
    final allKeyValuesAvailable = fieldNames.every(
      (fieldName) => _rowContainsField(entry.originalValues, fieldName),
    );
    return allKeyValuesAvailable ? fieldNames : const <String>[];
  }

  bool _rowContainsField(Map<String, Object?> row, String fieldName) {
    final normalizedFieldName = FdcFieldName.normalize(fieldName);
    return row.keys.any(
      (key) => FdcFieldName.normalize(key) == normalizedFieldName,
    );
  }

  int _compareValues(Object? left, Object? right) {
    if (left == right) {
      return 0;
    }
    if (left == null) {
      return -1;
    }
    if (right == null) {
      return 1;
    }
    if (left is String && right is String) {
      return _compareStrings(left, right);
    }
    if (left is Comparable && right.runtimeType == left.runtimeType) {
      return left.compareTo(right);
    }
    return _compareStrings(left.toString(), right.toString());
  }

  int _compareStrings(String left, String right) {
    final insensitiveCompare = left.toLowerCase().compareTo(
      right.toLowerCase(),
    );
    if (insensitiveCompare != 0) {
      return insensitiveCompare;
    }
    return left.compareTo(right);
  }
}

class _FdcMemoryRow {
  const _FdcMemoryRow({required this.identity, required this.values});

  final int identity;
  final Map<String, Object?> values;

  _FdcMemoryRow copy() => _FdcMemoryRow(
    identity: identity,
    values: Map<String, Object?>.of(values),
  );
}

class _FdcMemoryQueryExecutor {
  const _FdcMemoryQueryExecutor._();

  static FdcDataLoadResult load(
    List<_FdcMemoryRow> rows,
    int nextRowIdentity,
    FdcDataLoadRequest request,
  ) {
    request.validatePagingContract();
    final safeOffset = request.offset ?? 0;
    final safeLimit = request.limit;
    final matcher = _FdcMemoryRowMatcher(
      filters: request.filters,
      search: request.search,
      fields: request.fields,
    );

    if (request.sorts.isNotEmpty) {
      final filteredRows = <_FdcMemoryRow>[
        for (final row in rows)
          if (matcher.matches(row.values) && _matchesSelectedKeys(row, request))
            row,
      ];
      filteredRows.sort((left, right) {
        for (final sort in request.sorts) {
          final compareResult = _compareValues(
            FdcFieldName.valueFromRow(
              left.values,
              sort.fieldName,
              defaultValue: null,
            ),
            FdcFieldName.valueFromRow(
              right.values,
              sort.fieldName,
              defaultValue: null,
            ),
          );
          if (compareResult != 0) {
            return sort.sortType.isAscending ? compareResult : -compareResult;
          }
        }
        return 0;
      });

      final totalCount = filteredRows.length;
      final safeStart = safeOffset.clamp(0, totalCount).toInt();
      final end = safeLimit == null
          ? totalCount
          : (safeStart + safeLimit).clamp(safeStart, totalCount).toInt();
      final pageRows = filteredRows.sublist(safeStart, end);
      return _loadResult(
        pageRows,
        totalCount: request.includeTotalCount ? totalCount : null,
        nextRowIdentity: nextRowIdentity,
      );
    }

    var totalCount = 0;
    final result = <_FdcMemoryRow>[];
    final canTakeRows = safeLimit == null || safeLimit > 0;
    for (final row in rows) {
      if (!matcher.matches(row.values) || !_matchesSelectedKeys(row, request)) {
        continue;
      }
      final rowIndex = totalCount++;
      if (!canTakeRows || rowIndex < safeOffset) {
        continue;
      }
      if (safeLimit != null && result.length >= safeLimit) {
        continue;
      }
      result.add(row);
    }
    return _loadResult(
      result,
      totalCount: request.includeTotalCount ? totalCount : null,
      nextRowIdentity: nextRowIdentity,
    );
  }

  static bool _matchesSelectedKeys(
    _FdcMemoryRow row,
    FdcDataLoadRequest request,
  ) {
    if (!request.selectedKeysOnly) {
      return true;
    }
    if (request.selectedKeys.isEmpty) {
      return false;
    }
    for (final key in request.selectedKeys) {
      var matches = true;
      final keyValues = key.toMap();
      for (final entry in keyValues.entries) {
        if (FdcFieldName.valueFromRow(
              row.values,
              entry.key,
              defaultValue: null,
            ) !=
            entry.value) {
          matches = false;
          break;
        }
      }
      if (matches) {
        return true;
      }
    }
    return false;
  }

  static bool _matchesSelectedAggregateKeys(
    _FdcMemoryRow row,
    FdcDataAggregateRequest request,
  ) {
    if (!request.selectedKeysOnly) {
      return true;
    }
    return _matchesSelectedKeys(
      row,
      FdcDataLoadRequest(
        selectedKeysOnly: request.selectedKeysOnly,
        selectedKeys: request.selectedKeys,
      ),
    );
  }

  static FdcDataAggregateResult aggregate(
    List<_FdcMemoryRow> rows,
    FdcDataAggregateRequest request,
  ) {
    final matcher = _FdcMemoryRowMatcher(
      filters: request.filters,
      search: request.search,
      fields: request.fields,
    );
    final accumulators = <_FdcMemoryAggregateAccumulator>[
      for (final item in request.aggregates)
        _FdcMemoryAggregateAccumulator(item),
    ];

    for (final row in rows) {
      if (!matcher.matches(row.values) ||
          !_matchesSelectedAggregateKeys(row, request)) {
        continue;
      }
      for (final accumulator in accumulators) {
        accumulator.addRow(row.values);
      }
    }

    return FdcDataAggregateResult(
      values: Map<FdcDataAggregateKey, Object?>.unmodifiable({
        for (final accumulator in accumulators)
          accumulator.key: accumulator.value,
      }),
    );
  }

  static FdcDataLoadResult _loadResult(
    List<_FdcMemoryRow> rows, {
    required int? totalCount,
    required int nextRowIdentity,
  }) => FdcDataLoadResult(
    rows: <Map<String, Object?>>[
      for (final row in rows) Map<String, Object?>.of(row.values),
    ],
    totalCount: totalCount,
    internalRowIds: <int>[for (final row in rows) row.identity],
    internalNextRowId: nextRowIdentity,
  );
}

class _FdcMemoryRowMatcher {
  _FdcMemoryRowMatcher({
    required this.filters,
    required FdcDataSetSearchState search,
    required this.fields,
  }) : _search = search.isActive
           ? _FdcMemoryPreparedSearch(search: search, fields: fields)
           : null;

  final List<FdcDataAdapterFilter> filters;
  final List<FdcFieldDef> fields;
  final _FdcMemoryPreparedSearch? _search;

  bool matches(Map<String, Object?> row) {
    for (final filter in filters) {
      final value = FdcFieldName.valueFromRow(
        row,
        filter.fieldName,
        defaultValue: null,
      );
      if (!_matchesFilter(value, filter)) {
        return false;
      }
    }
    return _search?.matches(row) ?? true;
  }
}

class _FdcMemoryPreparedSearch {
  _FdcMemoryPreparedSearch({
    required FdcDataSetSearchState search,
    required List<FdcFieldDef> fields,
  }) : _fields = fields,
       _fallback = fields.isEmpty ? _FdcMemoryFallbackSearch(search) : null,
       _prepared = fields.isEmpty
           ? null
           : prepareDataSetSearch(
               search: search,
               fields: fields,
               fieldIndexByName: <String, int>{
                 for (var index = 0; index < fields.length; index++)
                   FdcFieldName.normalize(fields[index].name): index,
               },
               formatSettings: search.formatSettings,
             );

  final List<FdcFieldDef> _fields;
  final _FdcMemoryFallbackSearch? _fallback;
  final FdcPreparedDataSetSearch? _prepared;

  bool matches(Map<String, Object?> row) {
    final fallback = _fallback;
    if (fallback != null) {
      return fallback.matches(row);
    }
    final prepared = _prepared;
    if (prepared == null) {
      return true;
    }
    return prepared.matches(
      FdcRecord(
        id: 0,
        values: <Object?>[
          for (final field in _fields)
            FdcFieldName.valueFromRow(row, field.name, defaultValue: null),
        ],
      ),
    );
  }
}

class _FdcMemoryFallbackSearch {
  _FdcMemoryFallbackSearch(FdcDataSetSearchState search)
    : mode = search.mode,
      caseSensitive = search.caseSensitive,
      phrase = search.caseSensitive
          ? search.text.trim()
          : search.text.trim().toLowerCase(),
      tokens =
          (search.caseSensitive
                  ? search.text.trim()
                  : search.text.trim().toLowerCase())
              .split(RegExp(r'\s+'))
              .where((value) => value.isNotEmpty)
              .toList(growable: false);

  final FdcSearchMode mode;
  final bool caseSensitive;
  final String phrase;
  final List<String> tokens;

  bool matches(Map<String, Object?> row) {
    if (phrase.isEmpty) {
      return true;
    }
    final values = <String>[
      for (final value in row.values)
        if (value != null) caseSensitive ? '$value' : '$value'.toLowerCase(),
    ];
    bool contains(String term) => values.any((value) => value.contains(term));
    bool startsWith(String term) =>
        values.any((value) => value.startsWith(term));
    bool exact(String term) => values.any((value) => value == term);
    return switch (mode) {
      FdcSearchMode.phrase => contains(phrase),
      FdcSearchMode.anyWord => tokens.any(contains),
      FdcSearchMode.allWords => tokens.every(contains),
      FdcSearchMode.exactPhrase => exact(phrase),
      FdcSearchMode.startsWith => startsWith(phrase),
    };
  }
}

class _FdcMemoryAggregateAccumulator {
  _FdcMemoryAggregateAccumulator(this.item);

  final FdcDataAggregateItem item;
  FdcDecimal _sum = FdcDecimal.zero;
  int _count = 0;
  Object? _min;
  Object? _max;

  FdcDataAggregateKey get key =>
      FdcDataAggregateKey(fieldName: item.fieldName, aggregate: item.aggregate);

  void addRow(Map<String, Object?> row) {
    final value = FdcFieldName.valueFromRow(
      row,
      item.fieldName,
      defaultValue: null,
    );
    if (value == null) {
      return;
    }
    switch (item.aggregate) {
      case FdcAggregate.sum:
      case FdcAggregate.avg:
        final decimal = _decimalValueOrNull(value);
        if (decimal != null) {
          _sum += decimal;
          _count++;
        }
        break;
      case FdcAggregate.min:
        if (_min == null || _compareValues(value, _min) < 0) {
          _min = value;
        }
        break;
      case FdcAggregate.max:
        if (_max == null || _compareValues(value, _max) > 0) {
          _max = value;
        }
        break;
    }
  }

  Object? get value => switch (item.aggregate) {
    FdcAggregate.sum => _sum,
    FdcAggregate.avg => _count == 0 ? null : _sum / _count,
    FdcAggregate.min => _min,
    FdcAggregate.max => _max,
  };
}

FdcDecimal? _decimalValueOrNull(Object? value) {
  if (value == null) return null;
  if (value is FdcDecimal) return value;
  if (value is int) return FdcDecimal.fromScaled(BigInt.from(value), scale: 0);
  if (value is BigInt) return FdcDecimal.fromScaled(value, scale: 0);
  if (value is num) return FdcDecimal.tryFromNum(value);
  return FdcDecimal.tryParse(value.toString());
}

bool _matchesFilter(Object? value, FdcDataAdapterFilter filter) {
  switch (filter.operator) {
    case FdcDataAdapterFilterOperator.equals:
      return _filterScalarValuesEqual(value, filter.value);
    case FdcDataAdapterFilterOperator.notEquals:
      return !_filterScalarValuesEqual(value, filter.value);
    case FdcDataAdapterFilterOperator.contains:
      return _filterString(
        value,
        filter,
      ).contains(_filterString(filter.value, filter));
    case FdcDataAdapterFilterOperator.startsWith:
      return _filterString(
        value,
        filter,
      ).startsWith(_filterString(filter.value, filter));
    case FdcDataAdapterFilterOperator.endsWith:
      return _filterString(
        value,
        filter,
      ).endsWith(_filterString(filter.value, filter));
    case FdcDataAdapterFilterOperator.greaterThan:
      return _compareValues(value, filter.value) > 0;
    case FdcDataAdapterFilterOperator.greaterThanOrEqual:
      return _compareValues(value, filter.value) >= 0;
    case FdcDataAdapterFilterOperator.lessThan:
      return _compareValues(value, filter.value) < 0;
    case FdcDataAdapterFilterOperator.lessThanOrEqual:
      return _compareValues(value, filter.value) <= 0;
    case FdcDataAdapterFilterOperator.inList:
      return _filterListValues(filter.value).any(
        (candidate) => _filterValuesEqual(
          value,
          candidate,
          caseSensitive: filter.caseSensitive,
        ),
      );
    case FdcDataAdapterFilterOperator.notInList:
      return !_filterListValues(filter.value).any(
        (candidate) => _filterValuesEqual(
          value,
          candidate,
          caseSensitive: filter.caseSensitive,
        ),
      );
    case FdcDataAdapterFilterOperator.isEmpty:
      return _isEmptyStringValue(value);
    case FdcDataAdapterFilterOperator.isNotEmpty:
      return !_isEmptyStringValue(value);
    case FdcDataAdapterFilterOperator.isNull:
      return value == null;
    case FdcDataAdapterFilterOperator.isNotNull:
      return value != null;
    case FdcDataAdapterFilterOperator.isNullOrWhitespace:
      return _isNullOrWhitespaceStringValue(value);
    case FdcDataAdapterFilterOperator.isNotNullOrWhitespace:
      return !_isNullOrWhitespaceStringValue(value);
  }
}

Iterable<Object?> _filterListValues(Object? value) {
  if (value is Iterable<Object?>) return value;
  if (value is Iterable) return value.cast<Object?>();
  return value == null ? const <Object?>[] : <Object?>[value];
}

bool _filterScalarValuesEqual(Object? left, Object? right) {
  if (left is String || right is String) {
    return (left?.toString() ?? '') == (right?.toString() ?? '');
  }
  return _compareValues(left, right) == 0;
}

bool _filterValuesEqual(
  Object? left,
  Object? right, {
  bool caseSensitive = false,
}) {
  if (left is String || right is String) {
    return _filterStringValue(left, caseSensitive: caseSensitive) ==
        _filterStringValue(right, caseSensitive: caseSensitive);
  }
  return _compareValues(left, right) == 0;
}

int _compareValues(Object? left, Object? right) {
  if (left == right) return 0;
  if (left == null) return -1;
  if (right == null) return 1;
  if (left is String && right is String) return _compareStrings(left, right);
  if (left is Comparable && right.runtimeType == left.runtimeType) {
    return left.compareTo(right);
  }
  return _compareStrings(left.toString(), right.toString());
}

int _compareStrings(String left, String right) {
  final insensitiveCompare = left.toLowerCase().compareTo(right.toLowerCase());
  return insensitiveCompare != 0 ? insensitiveCompare : left.compareTo(right);
}

String _filterString(Object? value, FdcDataAdapterFilter filter) {
  return _filterStringValue(value, caseSensitive: filter.caseSensitive);
}

String _filterStringValue(Object? value, {required bool caseSensitive}) {
  final text = value?.toString() ?? '';
  return caseSensitive ? text : text.toLowerCase();
}

bool _isEmptyStringValue(Object? value) {
  return value == null || value is String && value.isEmpty;
}

bool _isNullOrWhitespaceStringValue(Object? value) {
  return value == null || value is String && value.trim().isEmpty;
}
