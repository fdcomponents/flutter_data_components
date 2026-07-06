// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart' show VoidCallback;

import '../common/format/fdc_date_format.dart';
import '../common/format/fdc_format_settings.dart';
import 'fdc_data_type.dart';
import 'fdc_filter_operator.dart';
import 'types/fdc_decimal.dart';
import 'types/fdc_guid.dart';
import 'types/fdc_time.dart';

/// Resolves a stored field value before local filter comparison.
///
/// Use this for fields whose filterable value differs from the stored object.
/// The resolver is applied while evaluating [FdcDataSetFilter] locally.
typedef FdcDataSetValueResolver = Object? Function(Object? value);

/// Sort direction for dataset and adapter ordering.
enum FdcSortType {
  /// Orders lower values before higher values.
  ascending,

  /// Orders higher values before lower values.
  descending;

  /// Whether this sort type represents ascending order.
  bool get isAscending => this == FdcSortType.ascending;

  /// Returns the opposite sort direction.
  FdcSortType get toggled =>
      isAscending ? FdcSortType.descending : FdcSortType.ascending;
}

/// Describes one field predicate in the active dataset filter.
///
/// Filters are value objects used by the dataset, fluent filter API, grids,
/// and adapters. [secondValue] is used by two-bound operators, while
/// [caseSensitive] controls textual comparisons where supported.
class FdcDataSetFilter {
  /// Creates a [FdcDataSetFilter].
  const FdcDataSetFilter({
    required this.fieldName,
    required this.operator,
    this.value,
    this.secondValue,
    this.caseSensitive = false,
    this.dataType,
    this.formatSettings,
    this.valueResolver,
  });

  /// Dataset field name associated with this object.
  final String fieldName;

  /// Comparison operator applied to the field value.
  final FdcFilterOperator operator;

  /// Primary comparison value.
  final Object? value;

  /// Optional upper/second comparison value for two-bound operators.
  final Object? secondValue;

  /// Whether textual comparison preserves letter case.
  final bool caseSensitive;

  /// Optional explicit data type used when the filter is built outside a
  /// dataset schema context.
  final FdcDataType? dataType;

  /// Format settings applied to FDC controls.
  final FdcFormatSettings? formatSettings;

  /// Optional transform applied to stored values before comparison.
  final FdcDataSetValueResolver? valueResolver;
}

/// Describes one field ordering rule in the active dataset sort.
///
/// Multiple sort descriptors are applied in list order, so earlier entries
/// have higher sort priority.
class FdcDataSetSort {
  /// Creates a [FdcDataSetSort].
  const FdcDataSetSort({
    required this.fieldName,
    this.sortType = FdcSortType.ascending,
  });

  /// Dataset field name associated with this object.
  final String fieldName;

  /// Direction used to order values from [fieldName].
  final FdcSortType sortType;
}

class _FdcUnsetFilterContextValue {
  const _FdcUnsetFilterContextValue();
}

const Object _fdcUnsetFilterContextValue = _FdcUnsetFilterContextValue();

/// Runtime context used while preparing and evaluating dataset filters.
///
/// The context supplies parsing/formatting rules and the optional row-selection
/// predicate used by `selected(...)` filter operations.
class FdcDataSetFilterContext {
  /// Creates a [FdcDataSetFilterContext].
  const FdcDataSetFilterContext({
    this.formatSettings = const FdcFormatSettings(),
    this.selected,
  });

  /// Format settings applied to FDC controls.
  final FdcFormatSettings formatSettings;

  /// Optional row-state selector used by the fluent filter DSL.
  ///
  /// When set, the dataset view only contains records whose internal
  /// selection state matches this value. This is not a field filter and does
  /// not mutate selection state.
  final bool? selected;

  /// Returns a copy with changed filter context values.
  ///
  /// `selected` intentionally uses a sentinel parameter so `copyWith()` keeps
  /// the current selection predicate, while `copyWith(selected: null)` clears
  /// it. Passing a non-null value must still be a `bool`.
  FdcDataSetFilterContext copyWith({
    FdcFormatSettings? formatSettings,
    Object? selected = _fdcUnsetFilterContextValue,
  }) {
    if (!identical(selected, _fdcUnsetFilterContextValue) &&
        selected != null &&
        selected is! bool) {
      throw ArgumentError.value(
        selected,
        'selected',
        'Expected bool, null, or omitted value.',
      );
    }

    return FdcDataSetFilterContext(
      formatSettings: formatSettings ?? this.formatSettings,
      selected: identical(selected, _fdcUnsetFilterContextValue)
          ? this.selected
          : selected as bool?,
    );
  }
}

/// Defines a prepared data set filter API.
class FdcPreparedDataSetFilter {
  /// Creates a [FdcPreparedDataSetFilter].
  FdcPreparedDataSetFilter({
    required this.filter,
    required this.fieldIndex,
    required this.dataType,
    required this.preparedValue,
    required this.preparedSecondValue,
    required this.compareByDay,
    required this.usePrimitiveComparable,
    required this.useNormalizedTextComparable,
    required this.preparedValueSet,
    required this.valueResolver,
  });

  /// The filter.
  final FdcDataSetFilter filter;

  /// The field index.
  final int fieldIndex;

  /// Optional explicit data type used when the filter is built outside a
  /// dataset schema context.
  final FdcDataType dataType;

  /// The prepared value.
  final Object? preparedValue;

  /// The prepared second value.
  final Object? preparedSecondValue;

  /// The compare by day.
  final bool compareByDay;

  /// Whether use primitive comparable.
  final bool usePrimitiveComparable;

  /// Whether use normalized text comparable.
  final bool useNormalizedTextComparable;

  /// The prepared value set.
  final Set<Object?>? preparedValueSet;

  /// Optional transform applied to stored values before comparison.
  final FdcDataSetValueResolver? valueResolver;
}

/// Prepares a dataset filter for repeated matching.
FdcPreparedDataSetFilter? prepareDataSetFilter({
  required FdcDataSetFilter filter,
  required int fieldIndex,
  required FdcDataType dataType,
  required FdcDataSetFilterContext context,
}) {
  if (_operatorIgnoresValue(filter.operator)) {
    return FdcPreparedDataSetFilter(
      filter: filter,
      fieldIndex: fieldIndex,
      dataType: dataType,
      preparedValue: null,
      preparedSecondValue: null,
      compareByDay: false,
      usePrimitiveComparable: false,
      useNormalizedTextComparable: false,
      preparedValueSet: null,
      valueResolver: filter.valueResolver,
    );
  }

  if (_isEmptyValue(filter.value)) {
    return null;
  }

  var compareByDay = false;
  final Object? preparedValue;
  if (_operatorUsesValueList(filter.operator)) {
    preparedValue = _prepareValueList(
      filter,
      dataType,
      context,
      onDateOnlyForDateTime: () => compareByDay = true,
    );
  } else {
    final resolvedFilterValue =
        filter.valueResolver?.call(filter.value) ?? filter.value;
    preparedValue = _prepareValue(
      resolvedFilterValue,
      dataType,
      filter,
      context,
      allowDateOnlyForDateTime: true,
      onDateOnlyForDateTime: () => compareByDay = true,
    );
  }
  if (preparedValue == _invalidPreparedValue) {
    return null;
  }

  Object? preparedSecondValue;
  if (filter.operator == FdcFilterOperator.between) {
    if (_isEmptyValue(filter.secondValue)) {
      return null;
    }
    final resolvedSecondValue =
        filter.valueResolver?.call(filter.secondValue) ?? filter.secondValue;
    preparedSecondValue = _prepareValue(
      resolvedSecondValue,
      dataType,
      filter,
      context,
      allowDateOnlyForDateTime: true,
      onDateOnlyForDateTime: () {},
    );
    if (preparedSecondValue == _invalidPreparedValue) {
      return null;
    }
  }

  final usePrimitiveComparable = _canUsePrimitiveComparable(
    filter.operator,
    dataType,
  );
  final useNormalizedTextComparable = _canUseNormalizedTextComparable(
    filter.operator,
  );

  final Object? finalPreparedValue;
  final Object? finalPreparedSecondValue;
  if (usePrimitiveComparable) {
    finalPreparedValue = primitiveComparableValue(
      preparedValue,
      dataType,
      compareByDay: compareByDay,
    );
    finalPreparedSecondValue = primitiveComparableValue(
      preparedSecondValue,
      dataType,
      compareByDay: compareByDay,
    );
  } else if (useNormalizedTextComparable) {
    finalPreparedValue = normalizedTextDataSetValue(
      preparedValue,
      caseSensitive: filter.caseSensitive,
    );
    finalPreparedSecondValue = normalizedTextDataSetValue(
      preparedSecondValue,
      caseSensitive: filter.caseSensitive,
    );
  } else {
    finalPreparedValue = preparedValue;
    finalPreparedSecondValue = preparedSecondValue;
  }

  return FdcPreparedDataSetFilter(
    filter: filter,
    fieldIndex: fieldIndex,
    dataType: dataType,
    preparedValue: finalPreparedValue,
    preparedSecondValue: finalPreparedSecondValue,
    compareByDay: compareByDay,
    usePrimitiveComparable: usePrimitiveComparable,
    useNormalizedTextComparable: useNormalizedTextComparable,
    preparedValueSet: _preparedValueSetFor(
      finalPreparedValue,
      operator: filter.operator,
      dataType: dataType,
      caseSensitive: filter.caseSensitive,
      usePrimitiveComparable: usePrimitiveComparable,
    ),
    valueResolver: filter.valueResolver,
  );
}

/// Tests whether a record value matches a prepared filter.
bool matchesPreparedDataSetFilter(
  Object? value,
  FdcPreparedDataSetFilter prepared,
) {
  final operator = prepared.filter.operator;
  if (operator == FdcFilterOperator.isNull) {
    return value == null;
  }
  if (operator == FdcFilterOperator.isNotNull) {
    return value != null;
  }
  if (operator == FdcFilterOperator.isEmpty) {
    return _isEmptyStringValue(value);
  }
  if (operator == FdcFilterOperator.isNotEmpty) {
    return !_isEmptyStringValue(value);
  }
  if (operator == FdcFilterOperator.isNullOrWhitespace) {
    return _isNullOrWhitespaceStringValue(value);
  }
  if (operator == FdcFilterOperator.isNotNullOrWhitespace) {
    return !_isNullOrWhitespaceStringValue(value);
  }
  if (operator == FdcFilterOperator.isTrue) {
    return value == true;
  }
  if (operator == FdcFilterOperator.isFalse) {
    return value == false;
  }

  final preparedValue = prepared.preparedValue;
  if (preparedValue == null) {
    return false;
  }

  final comparableValue = prepared.usePrimitiveComparable
      ? primitiveComparableValue(
          value,
          prepared.dataType,
          compareByDay: prepared.compareByDay,
          valueResolver: prepared.valueResolver,
        )
      : comparableDataSetRecordValue(
          value,
          prepared.dataType,
          compareByDay: prepared.compareByDay,
          valueResolver: prepared.valueResolver,
        );

  return matchesPreparedComparableFilter(comparableValue, prepared);
}

/// Tests a comparable value against a prepared filter.
bool matchesPreparedComparableFilter(
  Object? comparableValue,
  FdcPreparedDataSetFilter prepared,
) {
  final operator = prepared.filter.operator;
  final preparedValue = prepared.preparedValue;

  if (prepared.useNormalizedTextComparable) {
    final left = comparableValue?.toString() ?? '';
    final right = preparedValue?.toString() ?? '';
    return switch (operator) {
      FdcFilterOperator.contains => left.contains(right),
      FdcFilterOperator.notContains => !left.contains(right),
      FdcFilterOperator.startsWith => left.startsWith(right),
      FdcFilterOperator.endsWith => left.endsWith(right),
      _ => false,
    };
  }

  return switch (operator) {
    FdcFilterOperator.contains => _contains(
      comparableValue,
      preparedValue,
      caseSensitive: prepared.filter.caseSensitive,
    ),
    FdcFilterOperator.notContains => !_contains(
      comparableValue,
      preparedValue,
      caseSensitive: prepared.filter.caseSensitive,
    ),
    FdcFilterOperator.startsWith => _startsWith(
      comparableValue,
      preparedValue,
      caseSensitive: prepared.filter.caseSensitive,
    ),
    FdcFilterOperator.endsWith => _endsWith(
      comparableValue,
      preparedValue,
      caseSensitive: prepared.filter.caseSensitive,
    ),
    FdcFilterOperator.equals => _compare(comparableValue, preparedValue) == 0,
    FdcFilterOperator.notEquals =>
      _compare(comparableValue, preparedValue) != 0,
    FdcFilterOperator.greaterThan =>
      _compare(comparableValue, preparedValue) > 0,
    FdcFilterOperator.greaterThanOrEqual =>
      _compare(comparableValue, preparedValue) >= 0,
    FdcFilterOperator.lessThan => _compare(comparableValue, preparedValue) < 0,
    FdcFilterOperator.lessThanOrEqual =>
      _compare(comparableValue, preparedValue) <= 0,
    FdcFilterOperator.between =>
      _compare(comparableValue, preparedValue) >= 0 &&
          _compare(comparableValue, prepared.preparedSecondValue) <= 0,
    FdcFilterOperator.inList => _isInPreparedList(comparableValue, prepared),
    FdcFilterOperator.notInList => !_isInPreparedList(
      comparableValue,
      prepared,
    ),
    FdcFilterOperator.isNull ||
    FdcFilterOperator.isNotNull ||
    FdcFilterOperator.isEmpty ||
    FdcFilterOperator.isNotEmpty ||
    FdcFilterOperator.isNullOrWhitespace ||
    FdcFilterOperator.isNotNullOrWhitespace ||
    FdcFilterOperator.isTrue ||
    FdcFilterOperator.isFalse => false,
  };
}

/// Whether comparable values for [prepared] may be cached safely.
bool canCacheComparableFilter(FdcPreparedDataSetFilter prepared) {
  return !_operatorIgnoresValue(prepared.filter.operator);
}

/// Compares two values using dataset sort semantics.
int compareDataSetSortValues(
  Object? left,
  Object? right,
  FdcDataType dataType, {
  FdcDataSetValueResolver? valueResolver,
}) {
  left = valueResolver?.call(left) ?? left;
  right = valueResolver?.call(right) ?? right;
  if (left == null && right == null) {
    return 0;
  }
  if (left == null) {
    return 1;
  }
  if (right == null) {
    return -1;
  }

  return switch (dataType) {
    FdcDataType.integer || FdcDataType.decimal => _compareNumbers(left, right),
    FdcDataType.boolean => _compareBooleans(left, right),
    FdcDataType.date || FdcDataType.dateTime => _compareDateTimes(left, right),
    FdcDataType.time => _compareTimes(left, right),
    FdcDataType.string ||
    FdcDataType.guid ||
    FdcDataType.object => _compareStrings(left, right),
  };
}

const Object _invalidPreparedValue = Object();

bool _operatorIgnoresValue(FdcFilterOperator operator) {
  return operator == FdcFilterOperator.isNull ||
      operator == FdcFilterOperator.isNotNull ||
      operator == FdcFilterOperator.isEmpty ||
      operator == FdcFilterOperator.isNotEmpty ||
      operator == FdcFilterOperator.isNullOrWhitespace ||
      operator == FdcFilterOperator.isNotNullOrWhitespace ||
      operator == FdcFilterOperator.isTrue ||
      operator == FdcFilterOperator.isFalse;
}

bool _operatorUsesValueList(FdcFilterOperator operator) {
  return operator == FdcFilterOperator.inList ||
      operator == FdcFilterOperator.notInList;
}

bool _canUsePrimitiveComparable(
  FdcFilterOperator operator,
  FdcDataType dataType,
) {
  final comparableOperator =
      operator == FdcFilterOperator.equals ||
      operator == FdcFilterOperator.notEquals ||
      operator == FdcFilterOperator.greaterThan ||
      operator == FdcFilterOperator.greaterThanOrEqual ||
      operator == FdcFilterOperator.lessThan ||
      operator == FdcFilterOperator.lessThanOrEqual ||
      operator == FdcFilterOperator.between ||
      operator == FdcFilterOperator.inList ||
      operator == FdcFilterOperator.notInList;
  if (!comparableOperator) {
    return false;
  }

  return dataType == FdcDataType.integer ||
      dataType == FdcDataType.boolean ||
      dataType == FdcDataType.date ||
      dataType == FdcDataType.dateTime ||
      dataType == FdcDataType.time;
}

bool _canUseNormalizedTextComparable(FdcFilterOperator operator) {
  return operator == FdcFilterOperator.contains ||
      operator == FdcFilterOperator.notContains ||
      operator == FdcFilterOperator.startsWith ||
      operator == FdcFilterOperator.endsWith;
}

Object? _prepareValueList(
  FdcDataSetFilter filter,
  FdcDataType dataType,
  FdcDataSetFilterContext context, {
  required VoidCallback onDateOnlyForDateTime,
}) {
  final rawValue = filter.value;
  final Iterable<Object?> rawValues;
  if (rawValue is Iterable<Object?>) {
    rawValues = rawValue;
  } else if (rawValue is Iterable) {
    rawValues = rawValue.cast<Object?>();
  } else {
    rawValues = <Object?>[rawValue];
  }

  final values = <Object?>[];
  for (final rawItem in rawValues) {
    final resolvedItem = filter.valueResolver?.call(rawItem) ?? rawItem;
    final preparedItem = _prepareValue(
      resolvedItem,
      dataType,
      filter,
      context,
      allowDateOnlyForDateTime: true,
      onDateOnlyForDateTime: onDateOnlyForDateTime,
    );
    if (preparedItem == _invalidPreparedValue) {
      return _invalidPreparedValue;
    }
    values.add(preparedItem);
  }

  return List<Object?>.unmodifiable(values);
}

Object? _prepareValue(
  Object? value,
  FdcDataType dataType,
  FdcDataSetFilter filter,
  FdcDataSetFilterContext context, {
  required bool allowDateOnlyForDateTime,
  required VoidCallback onDateOnlyForDateTime,
}) {
  if (value == null) {
    return null;
  }

  return switch (dataType) {
    FdcDataType.integer ||
    FdcDataType.decimal => _prepareNumber(value, dataType, filter, context),
    FdcDataType.boolean => _prepareBoolean(value),
    FdcDataType.date => _prepareDate(value, filter, context),
    FdcDataType.dateTime => _prepareDateTime(
      value,
      filter,
      context,
      allowDateOnlyForDateTime: allowDateOnlyForDateTime,
      onDateOnlyForDateTime: onDateOnlyForDateTime,
    ),
    FdcDataType.time => _prepareTime(value, filter, context),
    FdcDataType.guid => _prepareGuid(value, filter.operator),
    FdcDataType.string || FdcDataType.object => value.toString(),
  };
}

Object? _prepareGuid(Object value, FdcFilterOperator operator) {
  if (operator == FdcFilterOperator.contains ||
      operator == FdcFilterOperator.notContains ||
      operator == FdcFilterOperator.startsWith ||
      operator == FdcFilterOperator.endsWith) {
    return value.toString().trim();
  }

  if (value is FdcGuid) {
    return value;
  }
  final parsed = FdcGuid.tryParse(value.toString());
  return parsed ?? _invalidPreparedValue;
}

Object? _prepareNumber(
  Object value,
  FdcDataType dataType,
  FdcDataSetFilter filter,
  FdcDataSetFilterContext context,
) {
  if (value is FdcDecimal) {
    return value;
  }
  if (value is num) {
    return value.isFinite ? value : _invalidPreparedValue;
  }

  var text = value.toString().trim();
  if (text.isEmpty) {
    return _invalidPreparedValue;
  }

  final settings = filter.formatSettings ?? context.formatSettings;
  final thousandSeparator = settings.thousandSeparator;
  final decimalSeparator = settings.decimalSeparator;

  if (thousandSeparator.isNotEmpty && thousandSeparator != decimalSeparator) {
    text = text.replaceAll(thousandSeparator, '');
  }
  if (decimalSeparator.isNotEmpty && decimalSeparator != '.') {
    text = text.replaceAll(decimalSeparator, '.');
  }

  if (dataType == FdcDataType.integer) {
    final parsed = int.tryParse(text);
    return parsed ?? _invalidPreparedValue;
  }

  final decimal = FdcDecimal.tryParse(text, scale: 18);
  return decimal ?? _invalidPreparedValue;
}

Object? _prepareBoolean(Object value) {
  if (value is bool) {
    return value;
  }
  final text = value.toString().toLowerCase().trim();
  if (text == 'true' || text == '1' || text == 'yes') {
    return true;
  }
  if (text == 'false' || text == '0' || text == 'no') {
    return false;
  }
  return _invalidPreparedValue;
}

Object? _prepareDate(
  Object value,
  FdcDataSetFilter filter,
  FdcDataSetFilterContext context,
) {
  final formatSettings = filter.formatSettings ?? context.formatSettings;
  final parsed = _asDateTime(value, formatSettings.dateFormat);
  if (parsed == null) {
    return _invalidPreparedValue;
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

Object? _prepareDateTime(
  Object value,
  FdcDataSetFilter filter,
  FdcDataSetFilterContext context, {
  required bool allowDateOnlyForDateTime,
  required VoidCallback onDateOnlyForDateTime,
}) {
  if (value is DateTime) {
    return value;
  }

  final text = value.toString().trim();
  final formatSettings = filter.formatSettings ?? context.formatSettings;
  final dateOnly = _asDateTime(text, formatSettings.dateFormat);
  final hasTimePart = RegExp(r'\d{1,2}:\d{2}').hasMatch(text);
  if (dateOnly != null && !hasTimePart && allowDateOnlyForDateTime) {
    onDateOnlyForDateTime();
    return DateTime(dateOnly.year, dateOnly.month, dateOnly.day);
  }

  final parsed = _asDateTime(text, formatSettings.effectiveDateTimeFormat);
  if (parsed == null) {
    return _invalidPreparedValue;
  }
  return parsed;
}

Object? _prepareTime(
  Object value,
  FdcDataSetFilter filter,
  FdcDataSetFilterContext context,
) {
  final formatSettings = filter.formatSettings ?? context.formatSettings;
  final parsed = _asTime(value, formatSettings.timeFormat);
  return parsed?.ticksSinceMidnight ?? _invalidPreparedValue;
}

DateTime? _asDateTime(Object value, String format) {
  if (value is DateTime) {
    return value;
  }

  final text = value.toString().trim();
  final formatter = FdcDateFormat(format);
  final parsed = formatter.parseDate(text);
  if (parsed != null) {
    return parsed;
  }

  return DateTime.tryParse(text);
}

FdcTime? _asTime(Object value, String format) {
  if (value is FdcTime) {
    return value;
  }
  if (value is DateTime) {
    return FdcTime.fromDateTime(value);
  }

  final trimmed = value.toString().trim();
  final formatter = FdcDateFormat(format);
  final parsed = formatter.parseTime(trimmed);
  if (parsed != null) {
    return parsed;
  }

  final iso = DateTime.tryParse(trimmed);
  if (iso != null) {
    return FdcTime.fromDateTime(iso);
  }

  return FdcTime.tryParse(trimmed);
}

/// Converts a record value to the comparable representation used by sorting.
Object? comparableDataSetRecordValue(
  Object? value,
  FdcDataType dataType, {
  required bool compareByDay,
  FdcDataSetValueResolver? valueResolver,
}) {
  value = valueResolver?.call(value) ?? value;
  if (value == null) {
    return null;
  }

  if (compareByDay && value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }

  if (dataType == FdcDataType.date && value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }

  if (dataType == FdcDataType.time) {
    if (value is FdcTime) {
      return value.ticksSinceMidnight;
    }
    if (value is DateTime) {
      return FdcTime.fromDateTime(value).ticksSinceMidnight;
    }
    if (value is String) {
      return FdcTime.tryParse(value)?.ticksSinceMidnight;
    }
  }

  return value;
}

/// Converts a primitive value to a normalized comparable representation.
Object? primitiveComparableValue(
  Object? value,
  FdcDataType dataType, {
  required bool compareByDay,
  FdcDataSetValueResolver? valueResolver,
}) {
  value = valueResolver?.call(value) ?? value;
  if (value == null) {
    return null;
  }

  if (value is Iterable<Object?>) {
    return List<Object?>.unmodifiable(
      value.map(
        (item) => primitiveComparableValue(
          item,
          dataType,
          compareByDay: compareByDay,
        ),
      ),
    );
  }
  if (value is Iterable) {
    return List<Object?>.unmodifiable(
      value.cast<Object?>().map(
        (item) => primitiveComparableValue(
          item,
          dataType,
          compareByDay: compareByDay,
        ),
      ),
    );
  }

  if (dataType == FdcDataType.integer) {
    return _integerPrimitiveKey(value);
  }

  if (dataType == FdcDataType.boolean) {
    return _booleanPrimitiveKey(value);
  }

  if (dataType == FdcDataType.date) {
    return _dateOnlyPrimitiveKey(value);
  }

  if (dataType == FdcDataType.dateTime) {
    if (compareByDay) {
      return _dateOnlyPrimitiveKey(value);
    }
    return _dateTimePrimitiveKey(value);
  }

  if (dataType == FdcDataType.time) {
    return _timePrimitiveKey(value);
  }

  return comparableDataSetRecordValue(
    value,
    dataType,
    compareByDay: compareByDay,
  );
}

/// Normalizes text for dataset filtering and comparison.
String normalizedTextDataSetValue(
  Object? value, {
  required bool caseSensitive,
  FdcDataSetValueResolver? valueResolver,
}) {
  final resolved = valueResolver?.call(value) ?? value;
  final text = resolved?.toString() ?? '';
  return caseSensitive ? text : text.toLowerCase();
}

Set<Object?>? _preparedValueSetFor(
  Object? preparedValue, {
  required FdcFilterOperator operator,
  required FdcDataType dataType,
  required bool caseSensitive,
  required bool usePrimitiveComparable,
}) {
  if (!_operatorUsesValueList(operator) ||
      preparedValue is! Iterable<Object?>) {
    return null;
  }

  // Keep Set lookup to value domains with stable equality semantics. Decimal
  // remains on the existing compareTo-based linear path because scale-equivalent
  // decimals may not be identical objects/keys.
  if (!usePrimitiveComparable &&
      dataType != FdcDataType.string &&
      dataType != FdcDataType.guid) {
    return null;
  }

  final set = <Object?>{};
  for (final item in preparedValue) {
    if (item == null) {
      set.add(null);
    } else if (item is String) {
      set.add(caseSensitive ? item : item.toLowerCase());
    } else {
      set.add(item);
    }
  }
  return Set<Object?>.unmodifiable(set);
}

int? _integerPrimitiveKey(Object value) {
  if (value is int) {
    return value;
  }
  if (value is num && value.isFinite) {
    final intValue = value.toInt();
    return value == intValue ? intValue : null;
  }
  return int.tryParse(value.toString().trim());
}

int? _booleanPrimitiveKey(Object value) {
  if (value is bool) {
    return value ? 1 : 0;
  }
  final text = value.toString().toLowerCase().trim();
  if (text == 'true' || text == '1' || text == 'yes') {
    return 1;
  }
  if (text == 'false' || text == '0' || text == 'no') {
    return 0;
  }
  return null;
}

int? _dateOnlyPrimitiveKey(Object value) {
  if (value is DateTime) {
    return _dateOnlyPrimitiveKeyFromDate(value);
  }
  if (value is int) {
    return value;
  }
  final comparable = comparableDataSetRecordValue(
    value,
    FdcDataType.date,
    compareByDay: true,
  );
  if (comparable is DateTime) {
    return _dateOnlyPrimitiveKeyFromDate(comparable);
  }
  if (comparable is int) {
    return comparable;
  }
  return null;
}

int? _dateTimePrimitiveKey(Object value) {
  if (value is DateTime) {
    return value.microsecondsSinceEpoch;
  }
  if (value is int) {
    return value;
  }
  final comparable = comparableDataSetRecordValue(
    value,
    FdcDataType.dateTime,
    compareByDay: false,
  );
  if (comparable is DateTime) {
    return comparable.microsecondsSinceEpoch;
  }
  if (comparable is int) {
    return comparable;
  }
  return null;
}

int? _timePrimitiveKey(Object value) {
  if (value is FdcTime) {
    return value.ticksSinceMidnight;
  }
  if (value is DateTime) {
    return FdcTime.fromDateTime(value).ticksSinceMidnight;
  }
  if (value is int) {
    return value;
  }
  if (value is String) {
    return FdcTime.tryParse(value)?.ticksSinceMidnight;
  }
  final comparable = comparableDataSetRecordValue(
    value,
    FdcDataType.time,
    compareByDay: false,
  );
  if (comparable is int) {
    return comparable;
  }
  if (comparable is FdcTime) {
    return comparable.ticksSinceMidnight;
  }
  return null;
}

int _dateOnlyPrimitiveKeyFromDate(DateTime value) {
  return value.year * 512 + value.month * 32 + value.day;
}

bool _contains(Object? value, Object? filter, {required bool caseSensitive}) {
  final left = _stringValue(value, caseSensitive: caseSensitive);
  final right = _stringValue(filter, caseSensitive: caseSensitive);
  return left.contains(right);
}

bool _startsWith(Object? value, Object? filter, {required bool caseSensitive}) {
  final left = _stringValue(value, caseSensitive: caseSensitive);
  final right = _stringValue(filter, caseSensitive: caseSensitive);
  return left.startsWith(right);
}

bool _endsWith(Object? value, Object? filter, {required bool caseSensitive}) {
  final left = _stringValue(value, caseSensitive: caseSensitive);
  final right = _stringValue(filter, caseSensitive: caseSensitive);
  return left.endsWith(right);
}

bool _isInPreparedList(Object? value, FdcPreparedDataSetFilter prepared) {
  final preparedSet = prepared.preparedValueSet;
  if (preparedSet != null) {
    final key = value is String && !prepared.filter.caseSensitive
        ? value.toLowerCase()
        : value;
    return preparedSet.contains(key);
  }

  return _isInList(
    value,
    prepared.preparedValue,
    caseSensitive: prepared.filter.caseSensitive,
  );
}

bool _isInList(
  Object? value,
  Object? preparedValue, {
  required bool caseSensitive,
}) {
  if (preparedValue is! Iterable<Object?>) {
    return false;
  }
  for (final item in preparedValue) {
    if (_equalsForListFilter(value, item, caseSensitive: caseSensitive)) {
      return true;
    }
  }
  return false;
}

bool _equalsForListFilter(
  Object? left,
  Object? right, {
  required bool caseSensitive,
}) {
  if (left is String || right is String) {
    return _stringValue(left, caseSensitive: caseSensitive) ==
        _stringValue(right, caseSensitive: caseSensitive);
  }
  return _compare(left, right) == 0;
}

String _stringValue(Object? value, {required bool caseSensitive}) {
  final text = value?.toString() ?? '';
  return caseSensitive ? text : text.toLowerCase();
}

int _compare(Object? left, Object? right) {
  if (left == null && right == null) {
    return 0;
  }
  if (left == null) {
    return -1;
  }
  if (right == null) {
    return 1;
  }

  if (left is FdcDecimal || right is FdcDecimal) {
    final leftDecimal = _decimalFromComparable(left);
    final rightDecimal = _decimalFromComparable(right);
    if (leftDecimal != null && rightDecimal != null) {
      return leftDecimal.compareTo(rightDecimal);
    }
  }
  if (left is num && right is num) {
    return left.compareTo(right);
  }
  if (left is bool && right is bool) {
    return (left ? 1 : 0).compareTo(right ? 1 : 0);
  }
  if (left is FdcGuid && right is FdcGuid) {
    return left.compareTo(right);
  }
  if (left is DateTime && right is DateTime) {
    return left.compareTo(right);
  }
  if (left is int && right is int) {
    return left.compareTo(right);
  }
  return left.toString().compareTo(right.toString());
}

int _compareNumbers(Object left, Object right) {
  final leftDecimal = _decimalFromComparable(left);
  final rightDecimal = _decimalFromComparable(right);
  if (leftDecimal != null && rightDecimal != null) {
    return leftDecimal.compareTo(rightDecimal);
  }

  final leftNumber = left is num ? left : num.tryParse(left.toString());
  final rightNumber = right is num ? right : num.tryParse(right.toString());
  if (leftNumber != null && rightNumber != null) {
    return leftNumber.compareTo(rightNumber);
  }
  return _compareStrings(left, right);
}

FdcDecimal? _decimalFromComparable(Object? value) {
  if (value is FdcDecimal) {
    return value;
  }
  if (value is num && value.isFinite) {
    return FdcDecimal.tryFromNum(value, scale: 18);
  }
  if (value is String) {
    return FdcDecimal.tryParse(value, scale: 18);
  }
  return null;
}

int _compareBooleans(Object left, Object right) {
  if (left is bool && right is bool) {
    return (left ? 1 : 0).compareTo(right ? 1 : 0);
  }
  return _compareStrings(left, right);
}

int _compareDateTimes(Object left, Object right) {
  if (left is DateTime && right is DateTime) {
    return left.compareTo(right);
  }
  if (left is int && right is int) {
    return left.compareTo(right);
  }
  return _compareStrings(left, right);
}

int _compareTimes(Object left, Object right) {
  final leftTime = left is FdcTime ? left : null;
  final rightTime = right is FdcTime ? right : null;
  if (leftTime != null && rightTime != null) {
    return leftTime.compareTo(rightTime);
  }
  return _compareNumbers(left, right);
}

int _compareStrings(Object left, Object right) {
  final leftText = left.toString();
  final rightText = right.toString();
  final insensitiveCompare = leftText.toLowerCase().compareTo(
    rightText.toLowerCase(),
  );
  if (insensitiveCompare != 0) {
    return insensitiveCompare;
  }
  return leftText.compareTo(rightText);
}

bool _isEmptyValue(Object? value) {
  return value == null || value is String && value.trim().isEmpty;
}

bool _isEmptyStringValue(Object? value) {
  return value == null || value is String && value.isEmpty;
}

bool _isNullOrWhitespaceStringValue(Object? value) {
  return value == null || value is String && value.trim().isEmpty;
}
