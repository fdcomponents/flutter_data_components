// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../common/format/fdc_decimal_math.dart';
import 'fdc_data_type.dart';
import 'fdc_field_def.dart';
import 'fields/fdc_decimal_field.dart';
import 'fields/fdc_string_field.dart';
import 'fields/fdc_time_field.dart';
import 'types/fdc_decimal.dart';
import 'types/fdc_guid.dart';
import 'types/fdc_time.dart';

/// Central type normalization/validation layer for dataset field values.
///
/// All values entering the data layer should pass through this class before
/// they are stored in records/edit buffers. It keeps runtime field values
/// aligned with their [FdcFieldDef.dataType] metadata and fails early with a
/// descriptive error when a user/external value cannot be represented by the
/// target field.
///
/// Calculated numeric values may optionally keep non-finite values so the
/// validation layer can report them as validation errors instead of turning
/// record materialization into a hard normalization failure.
class FdcFieldValueNormalizer {
  const FdcFieldValueNormalizer._();

  static Object? normalize(
    FdcFieldDef field,
    Object? value, {
    bool allowNonFiniteNumbers = false,
  }) {
    if (value == null) {
      return null;
    }

    // Empty editor text maps to null for non-string fields, so required
    // validation can handle it instead of turning it into a type error.
    if (value is String &&
        value.trim().isEmpty &&
        field.dataType != FdcDataType.string &&
        field.dataType != FdcDataType.guid &&
        field.dataType != FdcDataType.object) {
      return null;
    }

    try {
      return switch (field.dataType) {
        FdcDataType.string => _normalizeString(field, value),
        FdcDataType.integer => _normalizeInteger(
          field,
          value,
          allowNonFiniteNumbers: allowNonFiniteNumbers,
        ),
        FdcDataType.decimal => _normalizeDecimal(
          field,
          value,
          allowNonFiniteNumbers: allowNonFiniteNumbers,
        ),
        FdcDataType.boolean => _normalizeBoolean(field, value),
        FdcDataType.date => _normalizeDate(field, value),
        FdcDataType.dateTime => _normalizeDateTime(field, value),
        FdcDataType.time => _normalizeTime(field, value),
        FdcDataType.guid => _normalizeGuid(field, value),
        FdcDataType.object => value,
      };
      // ignore: avoid_catching_errors
    } on ArgumentError {
      rethrow;
    } on Object catch (_) {
      _throwInvalid(field, value, _expectedTypeDescription(field));
    }
  }

  static bool normalizeCalculatedValuesInPlace(
    List<FdcFieldDef> fields,
    List<Object?> values, {
    bool allowNonFiniteNumbers = true,
  }) {
    var changed = false;
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      if (!field.isCalculated) {
        continue;
      }
      final normalized = normalize(
        field,
        values[i],
        allowNonFiniteNumbers: allowNonFiniteNumbers,
      );
      if (values[i] != normalized) {
        values[i] = normalized;
        changed = true;
      }
    }
    return changed;
  }

  static String _normalizeString(FdcFieldDef field, Object value) {
    if (value is! String) {
      _throwInvalid(field, value, 'String');
    }

    final size = field is FdcStringField ? field.size : null;
    if (size != null && value.length > size) {
      throw ArgumentError.value(
        value,
        'value',
        'Invalid value for field "${field.name}" (string). '
            'Value length ${value.length} exceeds field size $size and would be truncated.',
      );
    }

    return value;
  }

  static Object _normalizeInteger(
    FdcFieldDef field,
    Object value, {
    required bool allowNonFiniteNumbers,
  }) {
    if (value is int) {
      return value;
    }
    if (value is BigInt) {
      return value;
    }
    if (value is num) {
      if (value.isFinite && value == value.truncateToDouble()) {
        return value.toInt();
      }
      if (allowNonFiniteNumbers && !value.isFinite) {
        return value;
      }
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        final parsedInt = int.tryParse(trimmed);
        if (parsedInt != null) {
          return parsedInt;
        }
        final parsedBigInt = _tryParsePlainIntegerText(trimmed);
        if (parsedBigInt != null) {
          return parsedBigInt;
        }
        final parsedNum = num.tryParse(trimmed.replaceAll(',', '.'));
        if (parsedNum != null &&
            parsedNum.isFinite &&
            parsedNum == parsedNum.truncateToDouble()) {
          return parsedNum.toInt();
        }
      }
    }
    _throwInvalid(field, value, 'int');
  }

  static BigInt? _tryParsePlainIntegerText(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final digits = trimmed.startsWith('-') || trimmed.startsWith('+')
        ? trimmed.substring(1)
        : trimmed;
    final isPlainInteger =
        digits.isNotEmpty &&
        digits.runes.every((rune) => rune >= 0x30 && rune <= 0x39);
    if (!isPlainInteger) {
      return null;
    }
    return BigInt.tryParse(trimmed);
  }

  static Object _normalizeDecimal(
    FdcFieldDef field,
    Object value, {
    required bool allowNonFiniteNumbers,
  }) {
    if (field is! FdcDecimalField) {
      _throwInvalid(field, value, 'decimal field metadata');
    }

    if (allowNonFiniteNumbers && value is num && !value.isFinite) {
      return value;
    }

    if (value is FdcDecimal) {
      final roundedText = value.toStringAsFixed(field.scale);
      if (!FdcDecimalMath.fitsPrecision(
        roundedText,
        field.precision,
        field.scale,
      )) {
        throw ArgumentError.value(
          value,
          'value',
          'Invalid value for field "${field.name}" (decimal). '
              'Value $roundedText exceeds precision ${field.precision} and scale ${field.scale}.',
        );
      }
      return FdcDecimal.parseNormalized(roundedText, scale: field.scale);
    }

    final normalizedText = _decimalTextFromInput(field, value);
    if (normalizedText == null) {
      _throwInvalid(field, value, 'finite num');
    }

    final roundedText = FdcDecimalMath.roundNormalizedText(
      normalizedText,
      scale: field.scale,
    );
    if (roundedText == null) {
      _throwInvalid(field, value, 'finite num');
    }

    if (!FdcDecimalMath.fitsPrecision(
      roundedText,
      field.precision,
      field.scale,
    )) {
      throw ArgumentError.value(
        value,
        'value',
        'Invalid value for field "${field.name}" (decimal). '
            'Value $roundedText exceeds precision ${field.precision} and scale ${field.scale}.',
      );
    }

    final decimal = FdcDecimal.tryParseNormalized(
      roundedText,
      scale: field.scale,
    );
    if (decimal == null) {
      _throwInvalid(field, value, 'finite decimal');
    }

    return decimal;
  }

  static bool _normalizeBoolean(FdcFieldDef field, Object value) {
    if (value is bool) {
      return value;
    }
    if (value is num && value.isFinite) {
      if (value == 0) {
        return false;
      }
      if (value == 1) {
        return true;
      }
    }
    if (value is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case 't':
        case 'yes':
        case 'y':
        case '1':
          return true;
        case 'false':
        case 'f':
        case 'no':
        case 'n':
        case '0':
          return false;
      }
    }
    _throwInvalid(field, value, 'bool');
  }

  static DateTime _normalizeDate(FdcFieldDef field, Object value) {
    final dateTime = _dateTimeFromValue(
      field,
      value,
      expected: 'DateTime/date string',
    );
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  static DateTime _normalizeDateTime(FdcFieldDef field, Object value) {
    return _dateTimeFromValue(
      field,
      value,
      expected: 'DateTime/date-time string',
    );
  }

  static FdcTime _normalizeTime(FdcFieldDef field, Object value) {
    final FdcTime time;
    if (value is FdcTime) {
      time = value;
    } else if (value is DateTime) {
      time = FdcTime.fromDateTime(value);
    } else if (value is String) {
      final parsed = FdcTime.tryParse(value);
      if (parsed == null) {
        _throwInvalid(field, value, 'FdcTime or SQL time string');
      }
      time = parsed;
    } else {
      _throwInvalid(field, value, 'FdcTime or SQL time string');
    }

    final scale = field is FdcTimeField ? field.scale : 7;
    return time.roundedToScale(scale);
  }

  static FdcGuid _normalizeGuid(FdcFieldDef field, Object value) {
    if (value is FdcGuid) {
      return value;
    }
    if (value is String) {
      final parsed = FdcGuid.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    _throwInvalid(field, value, 'FdcGuid or GUID string');
  }

  static DateTime _dateTimeFromValue(
    FdcFieldDef field,
    Object value, {
    required String expected,
  }) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        final parsed = DateTime.tryParse(trimmed);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    _throwInvalid(field, value, expected);
  }

  static String? _decimalTextFromInput(FdcFieldDef field, Object value) {
    if (value is num) {
      return FdcDecimalMath.normalizeNumberForParsing(
        value,
        scale: field is FdcDecimalField ? field.scale : null,
      );
    }
    if (value is String) {
      return FdcDecimalMath.normalizeTextForParsing(
        value,
        decimalSeparator: '.',
      );
    }
    return null;
  }

  static Never _throwInvalid(FdcFieldDef field, Object value, String expected) {
    throw ArgumentError.value(
      value,
      'value',
      'Invalid value for field "${field.name}" (${field.dataType.name}). '
          'Expected $expected, got ${value.runtimeType}.',
    );
  }

  static String _expectedTypeDescription(FdcFieldDef field) {
    return switch (field.dataType) {
      FdcDataType.string => 'String',
      FdcDataType.integer => 'int',
      FdcDataType.decimal => 'finite decimal',
      FdcDataType.boolean => 'bool',
      FdcDataType.date => 'DateTime/date string',
      FdcDataType.dateTime => 'DateTime/date-time string',
      FdcDataType.time => 'FdcTime or SQL time string',
      FdcDataType.guid => 'FdcGuid or GUID string',
      FdcDataType.object => 'Object',
    };
  }
}
