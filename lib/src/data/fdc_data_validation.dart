// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_data_type.dart';
import 'fdc_field_name.dart';
import 'types/fdc_decimal.dart';

/// Stable validation error codes emitted by built-in dataset validators.
///
/// Applications may use these codes to map validation failures to localized
/// messages, custom UI treatment, analytics, or backend-compatible validation
/// payloads without parsing human-readable error text. Custom validators may use
/// their own codes; these constants identify only the built-in validation rules.
class FdcValidationCodes {
  const FdcValidationCodes._();

  /// Emitted when a field marked required has no accepted value.
  static const String requiredField = 'required';

  /// Emitted when a numeric field value is below its configured minimum.
  static const String minValue = 'minValue';

  /// Emitted when a numeric field value is above its configured maximum.
  static const String maxValue = 'maxValue';

  /// Emitted when a numeric field contains a non-finite value such as NaN or
  /// infinity.
  static const String nonFiniteNumber = 'nonFiniteNumber';
}

/// Public read-only row context used by calculated fields and validators.
///
/// This is intentionally a value/context API, not a record API. It lets user
/// code inspect field values for the row being calculated or validated without
/// exposing the dataset's internal mutable record representation.
class FdcRowContext {
  /// Creates a [FdcRowContext].
  const FdcRowContext({
    required Map<String, int> fieldIndexByName,
    required List<String> fieldNames,
    required List<Object?> values,
    List<Object?>? originalValues,
    List<FdcDataType>? fieldTypes,
    bool decimalNullAsZero = false,
  }) : _fieldIndexByName = fieldIndexByName,
       _fieldNames = fieldNames,
       _values = values,
       _originalValues = originalValues,
       _fieldTypes = fieldTypes,
       _decimalNullAsZero = decimalNullAsZero;

  final Map<String, int> _fieldIndexByName;
  final List<String> _fieldNames;
  final List<Object?> _values;
  final List<Object?>? _originalValues;
  final List<FdcDataType>? _fieldTypes;
  final bool _decimalNullAsZero;

  /// Returns the current field count.
  int get fieldCount => _values.length;

  /// Returns the runtime value for [fieldName].
  ///
  /// This accessor is intentionally `dynamic` for calculated-field ergonomics,
  /// so expressions like `context.value('amount') ?? 0` keep working with
  /// `FdcDecimal` arithmetic. During calculated-field evaluation, null decimal
  /// field values are exposed as [FdcDecimal.zero] so mixed decimal expressions
  /// do not accidentally dispatch through Dart's `int`/`double` operators.
  /// Prefer typed helpers such as [numValue], [decimalValue], [intValue], and
  /// [doubleValue] when strict static typing is more important than expression
  /// brevity.
  dynamic value(String fieldName) => valueAt(_indexOf(fieldName));

  /// Returns the runtime value at [fieldIndex], applying decimal-null-as-zero
  /// behavior when this context was configured for calculated-field evaluation.
  dynamic valueAt(int fieldIndex) {
    final value = _values[fieldIndex];
    if (value != null) {
      return value;
    }

    if (_decimalNullAsZero && _fieldTypeAt(fieldIndex) == FdcDataType.decimal) {
      return FdcDecimal.zero;
    }

    return null;
  }

  /// Returns the raw decimal value for [fieldName], or `null` when the field
  /// is null or cannot be converted to a decimal.
  ///
  /// Unlike [value], this typed helper does not apply the calculated-context
  /// decimal-null-as-zero convenience fallback. Use [decimalOrZero] when that
  /// fallback is desired explicitly.
  FdcDecimal? decimalValue(String fieldName) =>
      decimalValueAt(_indexOf(fieldName));

  /// Returns the value at [fieldIndex] converted to [FdcDecimal], or `null`
  /// when it cannot be represented as a decimal.
  FdcDecimal? decimalValueAt(int fieldIndex) => _toDecimal(_values[fieldIndex]);

  /// Returns [fieldName] as [FdcDecimal], using [FdcDecimal.zero] for null or
  /// non-convertible values.
  FdcDecimal decimalOrZero(String fieldName) =>
      decimalValue(fieldName) ?? FdcDecimal.zero;

  /// Returns the value at [fieldIndex] as [FdcDecimal], using
  /// [FdcDecimal.zero] for null or non-convertible values.
  FdcDecimal decimalOrZeroAt(int fieldIndex) =>
      decimalValueAt(fieldIndex) ?? FdcDecimal.zero;

  /// Returns the raw numeric value for [fieldName], or `null` when the field
  /// is null or cannot be converted to a number.
  ///
  /// Unlike [value], this typed helper does not apply calculated-context
  /// decimal-null-as-zero fallback. Use [numOrZero] when zero fallback is
  /// desired explicitly.
  num? numValue(String fieldName) => numValueAt(_indexOf(fieldName));

  /// Returns the value at [fieldIndex] converted to [num], or `null` when
  /// conversion is not possible.
  num? numValueAt(int fieldIndex) => _toNum(_values[fieldIndex]);

  /// Returns [fieldName] as [num], using zero when the value is null or
  /// cannot be converted.
  num numOrZero(String fieldName) => numValue(fieldName) ?? 0;

  /// Returns the value at [fieldIndex] as [num], using zero when conversion
  /// is not possible.
  num numOrZeroAt(int fieldIndex) => numValueAt(fieldIndex) ?? 0;

  /// Returns [fieldName] converted to [double], or `null` when unavailable.
  double? doubleValue(String fieldName) => numValue(fieldName)?.toDouble();

  /// Returns [fieldName] converted to [int], or `null` when unavailable.
  int? intValue(String fieldName) => numValue(fieldName)?.toInt();

  /// Returns the original accepted value of [fieldName], or `null` when this
  /// context has no original-value snapshot.
  dynamic originalValue(String fieldName) {
    return originalValueAt(_indexOf(fieldName));
  }

  /// Returns the original accepted value at [fieldIndex], or `null` when no
  /// original-value snapshot is available.
  dynamic originalValueAt(int fieldIndex) => _originalValues?[fieldIndex];

  /// Whether the current value of [fieldName] differs from its original value.
  bool isFieldChanged(String fieldName) =>
      isFieldChangedAt(_indexOf(fieldName));

  /// Whether the current value at [fieldIndex] differs from its original value.
  bool isFieldChangedAt(int fieldIndex) {
    final originalValues = _originalValues;
    return originalValues != null &&
        _values[fieldIndex] != originalValues[fieldIndex];
  }

  /// Returns an immutable-style copy of the row values used for validation.
  List<Object?> valuesSnapshot() => List<Object?>.of(_values);

  /// Returns a copy of the original accepted row values, when available.
  List<Object?> originalValuesSnapshot() {
    final originalValues = _originalValues;
    return originalValues == null
        ? const <Object?>[]
        : List<Object?>.of(originalValues);
  }

  /// Materializes the current row values as a field-name map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      for (var i = 0; i < _fieldNames.length; i++) _fieldNames[i]: _values[i],
    };
  }

  static FdcDecimal? _toDecimal(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is FdcDecimal) {
      return value;
    }
    if (value is num && value.isFinite) {
      return FdcDecimal.tryFromNum(value, scale: 12);
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return FdcDecimal.tryParseNormalized(
        trimmed.replaceAll(',', '.'),
        scale: 12,
      );
    }
    return null;
  }

  static num? _toNum(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is FdcDecimal) {
      return value.toNum();
    }
    if (value is num) {
      return value;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return num.tryParse(trimmed.replaceAll(',', '.'));
    }
    return null;
  }

  FdcDataType? _fieldTypeAt(int fieldIndex) {
    final fieldTypes = _fieldTypes;
    if (fieldTypes == null ||
        fieldIndex < 0 ||
        fieldIndex >= fieldTypes.length) {
      return null;
    }
    return fieldTypes[fieldIndex];
  }

  int _indexOf(String fieldName) {
    final index = _fieldIndexByName[FdcFieldName.normalize(fieldName)];
    if (index == null) {
      throw ArgumentError.value(fieldName, 'fieldName', 'Unknown field.');
    }
    return index;
  }
}

/// Backwards-compatible type alias for calculated field callbacks.
typedef FdcCalculatedFieldContext = FdcRowContext;

/// Computes the value of a calculated field for the supplied row.
///
/// The dataset calls this callback while materializing or refreshing calculated
/// values. Read source fields from [FdcRowContext]; do not write dataset state
/// from the callback. Return `null` when the calculated value is null.
typedef FdcCalculatedFieldValue = Object? Function(FdcRowContext context);

/// Structured validation failure for a field or whole record.
///
/// [fieldName] is null for record-level validation errors.
class FdcValidationError {
  /// Creates a [FdcValidationError].
  const FdcValidationError({
    required this.message,
    this.fieldName,
    this.recordId,
    this.code,
  });

  /// User-facing message text.
  final String message;

  /// Dataset field name associated with this object.
  final String? fieldName;

  /// Internal record identifier.
  final int? recordId;

  /// Optional stable machine-readable validation code.
  final String? code;
}

/// Exception containing one or more dataset validation errors.
///
/// Normal editing APIs generally expose validation through dataset errors and
/// callbacks; this exception is useful for explicit validation flows.
class FdcDataSetValidationException implements Exception {
  /// Creates a [FdcDataSetValidationException].
  const FdcDataSetValidationException(this.errors);

  /// Errors associated with this result.
  final List<FdcValidationError> errors;

  @override
  String toString() {
    if (errors.isEmpty) {
      return 'FdcDataSetValidationException';
    }

    return 'FdcDataSetValidationException: '
        '${errors.map((error) => error.message).join('; ')}';
  }
}

/// Validates one field value in the context of its row.
///
/// The dataset calls the validator during validation flows. Return `null` when
/// the value is valid, or a user-facing validation message when it is invalid.
/// The callback should inspect [FdcRowContext] without mutating dataset state.
typedef FdcFieldValidator = String? Function(FdcRowContext row, Object? value);

/// Validates a row as a whole after field-level values are available.
///
/// Return an empty list when the row is valid. Returned errors may target a
/// specific field or the whole record. The validator may read sibling values
/// from [FdcRowContext] and should not mutate dataset state.
typedef FdcRecordValidator =
    List<FdcValidationError> Function(FdcRowContext row);
