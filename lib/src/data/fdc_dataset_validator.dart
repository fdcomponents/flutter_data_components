// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../i18n/fdc_translations.dart';
import 'fdc_data_type.dart';
import 'fdc_data_validation.dart';
import 'fdc_field_def.dart';
import 'fdc_field_value_normalizer.dart';
import 'fdc_record.dart';
import 'fields/fdc_decimal_field.dart';
import 'fields/fdc_integer_field.dart';
import 'types/fdc_decimal.dart';

/// Internal record/field validation engine for FdcDataSet.
///
/// It owns only validation rules. The dataset remains responsible for when
/// validation is invoked and how resulting errors are stored/emitted.
class FdcDataSetValidator {
  FdcDataSetValidator({
    required this.fields,
    required this.fieldIndexByName,
    this.recordValidator,
    this.validationTranslations = const FdcValidationTranslations(),
  }) : _fieldNames = List<String>.unmodifiable(
         fields.map((field) => field.name),
       ),
       _fieldTypes = List<FdcDataType>.unmodifiable(
         fields.map((field) => field.dataType),
       );

  final List<FdcFieldDef> fields;
  final Map<String, int> fieldIndexByName;
  final FdcRecordValidator? recordValidator;
  final FdcValidationTranslations validationTranslations;
  final List<String> _fieldNames;
  final List<FdcDataType> _fieldTypes;

  List<FdcValidationError> validateRecord(
    FdcRecord record, {
    List<Object?>? values,
  }) {
    final validationValues = values == null ? null : List<Object?>.of(values);
    if (validationValues != null) {
      applyCalculatedFields(validationValues);
    }

    final validationRecord = validationValues == null
        ? record
        : FdcRecord(
            id: record.id,
            values: validationValues,
            originalValues: record.originalValuesSnapshot(),
            state: record.state,
          );
    final errors = <FdcValidationError>[];

    for (var i = 0; i < fields.length; i++) {
      errors.addAll(validateFieldAtIndex(validationRecord, i));
    }

    final validator = recordValidator;
    if (validator != null) {
      errors.addAll(
        _withDefaultRecordId(
          validator(rowContext(validationRecord)),
          validationRecord.id,
        ),
      );
    }

    return errors;
  }

  List<FdcValidationError> validateFieldAtIndex(
    FdcRecord record,
    int fieldIndex,
  ) {
    final field = fields[fieldIndex];
    final value = record.valueAt(fieldIndex);
    final errors = <FdcValidationError>[];

    final fieldLabel = field.label ?? field.name;

    if (field.required && _isEmptyValue(value)) {
      errors.add(
        FdcValidationError(
          fieldName: field.name,
          recordId: record.id,
          message: validationTranslations.requiredField(fieldLabel),
          code: FdcValidationCodes.requiredField,
        ),
      );
    }

    if (_isNonFiniteNumericValue(value)) {
      errors.add(
        FdcValidationError(
          fieldName: field.name,
          recordId: record.id,
          message: validationTranslations.invalidNumericField(fieldLabel),
          code: FdcValidationCodes.nonFiniteNumber,
        ),
      );
    }

    final minValue = _minValueForField(field);
    if (minValue != null && _isLessThanMinValue(field, value, minValue)) {
      errors.add(
        FdcValidationError(
          fieldName: field.name,
          recordId: record.id,
          message: validationTranslations.minValueField(fieldLabel, minValue),
          code: FdcValidationCodes.minValue,
        ),
      );
    }

    final maxValue = _maxValueForField(field);
    if (maxValue != null && _isGreaterThanMaxValue(field, value, maxValue)) {
      errors.add(
        FdcValidationError(
          fieldName: field.name,
          recordId: record.id,
          message: validationTranslations.maxValueField(fieldLabel, maxValue),
          code: FdcValidationCodes.maxValue,
        ),
      );
    }

    final validator = field.validator;
    if (validator != null) {
      final message = validator(rowContext(record), value);
      if (message != null && message.isNotEmpty) {
        errors.add(
          FdcValidationError(
            fieldName: field.name,
            recordId: record.id,
            message: message,
          ),
        );
      }
    }

    return errors;
  }

  FdcRowContext rowContext(FdcRecord record) {
    return FdcRowContext(
      fieldIndexByName: fieldIndexByName,
      fieldNames: _fieldNames,
      values: record.valuesSnapshot(),
      originalValues: record.originalValuesSnapshot(),
      fieldTypes: _fieldTypes,
    );
  }

  bool applyCalculatedFields(List<Object?> values) {
    var changed = false;
    for (var i = 0; i < fields.length; i++) {
      final calculator = fields[i].calculatedValue;
      if (calculator == null) {
        continue;
      }

      final nextValue = FdcFieldValueNormalizer.normalize(
        fields[i],
        calculator(
          FdcRowContext(
            fieldIndexByName: fieldIndexByName,
            fieldNames: _fieldNames,
            values: values,
            fieldTypes: _fieldTypes,
            decimalNullAsZero: true,
          ),
        ),
        allowNonFiniteNumbers: true,
      );
      if (values[i] != nextValue) {
        values[i] = nextValue;
        changed = true;
      }
    }
    return changed;
  }

  List<FdcValidationError> _withDefaultRecordId(
    List<FdcValidationError> errors,
    int recordId,
  ) {
    return <FdcValidationError>[
      for (final error in errors)
        error.recordId == null
            ? FdcValidationError(
                message: error.message,
                fieldName: error.fieldName,
                recordId: recordId,
                code: error.code,
              )
            : error,
    ];
  }

  bool _isLessThanMinValue(FdcFieldDef field, Object? value, num minValue) {
    final comparison = _compareNumericConstraintValue(field, value, minValue);
    return comparison != null && comparison < 0;
  }

  bool _isGreaterThanMaxValue(FdcFieldDef field, Object? value, num maxValue) {
    final comparison = _compareNumericConstraintValue(field, value, maxValue);
    return comparison != null && comparison > 0;
  }

  int? _compareNumericConstraintValue(
    FdcFieldDef field,
    Object? value,
    num limit,
  ) {
    if (value == null) {
      return null;
    }

    if (field is FdcDecimalField && value is FdcDecimal) {
      return value.compareTo(FdcDecimal.fromNum(limit, scale: field.scale));
    }

    final numericValue = _numericValidationValue(value);
    if (numericValue == null) {
      return null;
    }
    if (numericValue < limit) {
      return -1;
    }
    if (numericValue > limit) {
      return 1;
    }
    return 0;
  }

  num? _minValueForField(FdcFieldDef field) {
    if (field is FdcIntegerField) {
      return field.minValue;
    }
    if (field is FdcDecimalField) {
      return field.minValue;
    }
    return null;
  }

  num? _maxValueForField(FdcFieldDef field) {
    if (field is FdcIntegerField) {
      return field.maxValue;
    }
    if (field is FdcDecimalField) {
      return field.maxValue;
    }
    return null;
  }

  num? _numericValidationValue(Object? value) {
    if (value is FdcDecimal) {
      return value.toNum();
    }
    if (value is num) {
      return value.isFinite ? value : null;
    }
    if (value is String && value.trim().isNotEmpty) {
      final parsed = num.tryParse(value.trim().replaceAll(',', '.'));
      return parsed != null && parsed.isFinite ? parsed : null;
    }
    return null;
  }

  bool _isNonFiniteNumericValue(Object? value) {
    if (value is FdcDecimal) {
      return false;
    }
    if (value is num) {
      return !value.isFinite;
    }
    if (value is String && value.trim().isNotEmpty) {
      final parsed = num.tryParse(value.trim().replaceAll(',', '.'));
      return parsed != null && !parsed.isFinite;
    }
    return false;
  }

  bool _isEmptyValue(Object? value) {
    return value == null || value is String && value.trim().isEmpty;
  }
}
