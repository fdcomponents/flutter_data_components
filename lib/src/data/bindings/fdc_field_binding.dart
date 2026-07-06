// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';

import '../fdc_data_validation.dart';
import '../fdc_dataset.dart';
import '../fdc_field_def.dart';
import '../fields/fdc_fields.dart';

/// Internal typed adapter between a dataset field and data-aware components.
///
/// This class intentionally lives under `src/` and is not exported by the
/// package barrel. User code should bind controls with `dataSet` + `fieldName`;
///
/// controls use this adapter to share strict field resolution, read/write,
/// validation and metadata access rules.
@internal
class FdcFieldBinding<TField extends FdcFieldDef> {
  FdcFieldBinding._({
    required this.dataSet,
    required this.fieldName,
    required TField fieldDef,
    required int? recordId,
  }) : _fieldDef = fieldDef,
       _recordId = recordId;

  final FdcDataSet dataSet;
  final String fieldName;
  final TField _fieldDef;
  final int? _recordId;

  TField get fieldDef => _fieldDef;

  String get label => fieldDef.label ?? fieldDef.name;

  bool get readOnly =>
      FdcDataSetInternal.isReadOnly(dataSet) || fieldDef.isReadOnly;

  bool get required => fieldDef.required;

  int? get recordId => _recordId;

  bool get hasCurrentRecord {
    final recordId = _recordId;
    return recordId != null &&
        FdcDataSetInternal.containsRecordId(dataSet, recordId);
  }

  Object? get value {
    final recordId = _recordId;
    if (recordId == null) {
      throw StateError('Dataset has no current record.');
    }
    return FdcDataSetInternal.fieldValueForRecordId(
      dataSet,
      recordId,
      fieldName,
    );
  }

  Object? get valueOrNull {
    if (!hasCurrentRecord) {
      return null;
    }
    return value;
  }

  @internal
  void ensureCurrentRecordStillBound() {
    _ensureCurrentRecordStillBound();
  }

  Object? valueAt(int rowIndex) =>
      FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, fieldName);

  void setValue(Object? value) {
    _ensureCurrentRecordStillBound();
    dataSet.setFieldValue(fieldName, value);
  }

  List<FdcValidationError> validateValue(Object? value) {
    _ensureCurrentRecordStillBound();
    return dataSet.validateFieldValue(fieldName, value);
  }

  List<FdcValidationError> validateValueAndEmit(Object? value) {
    _ensureCurrentRecordStillBound();
    return FdcDataSetInternal.validateFieldValueAndEmit(
      dataSet,
      fieldName,
      value,
    );
  }

  void _ensureCurrentRecordStillBound() {
    final recordId = _recordId;
    if (recordId == null) {
      throw StateError('Dataset has no current record.');
    }

    if (FdcDataSetInternal.currentRecordId(dataSet) != recordId) {
      throw StateError(
        'Bound editor record changed before the value could be committed.',
      );
    }
  }
}

/// Internal resolver for field bindings.
///
/// Keeping resolution and error text here prevents every data-aware component
/// from growing its own `fieldDef<T>()` try/catch and type mismatch messages.
@internal
final class FdcFieldBindingResolver {
  const FdcFieldBindingResolver._();

  static FdcFieldBinding<TField> resolve<TField extends FdcFieldDef>(
    FdcDataSet dataSet,
    String fieldName, {
    String? ownerName,
  }) {
    if (fieldName.isEmpty) {
      throw ArgumentError.value(
        fieldName,
        'fieldName',
        '${_ownerPrefix(ownerName)}Field name must not be empty.',
      );
    }

    try {
      return FdcFieldBinding<TField>._(
        dataSet: dataSet,
        fieldName: fieldName,
        fieldDef: dataSet.fieldDef<TField>(fieldName),
        recordId: FdcDataSetInternal.currentRecordId(dataSet),
      );
      // ignore: avoid_catching_errors
    } on ArgumentError catch (error) {
      throw ArgumentError.value(
        fieldName,
        'fieldName',
        '${_ownerPrefix(ownerName)}Unknown field "$fieldName". $error',
      );
      // ignore: avoid_catching_errors
    } on StateError catch (error) {
      throw StateError(
        '${_ownerPrefix(ownerName)}Invalid field binding for "$fieldName": '
        '$error',
      );
    }
  }

  static FdcFieldBinding<FdcFieldDef> resolveAnyOf(
    FdcDataSet dataSet,
    String fieldName, {
    required List<Type> allowedFieldTypes,
    String? ownerName,
  }) {
    final binding = resolve<FdcFieldDef>(
      dataSet,
      fieldName,
      ownerName: ownerName,
    );

    if (_isAllowed(binding.fieldDef, allowedFieldTypes)) {
      return binding;
    }

    final allowed = allowedFieldTypes.map(_typeName).join(', ');
    throw StateError(
      '${_ownerPrefix(ownerName)}Invalid field binding for "$fieldName": '
      'field is ${binding.fieldDef.runtimeType}, but allowed field types are: '
      '$allowed.',
    );
  }

  static FdcFieldBinding<TField>? tryResolve<TField extends FdcFieldDef>(
    FdcDataSet dataSet,
    String fieldName,
  ) {
    if (fieldName.isEmpty) {
      return null;
    }

    try {
      return resolve<TField>(dataSet, fieldName);
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return null;
      // ignore: avoid_catching_errors
    } on StateError {
      return null;
    }
  }

  static FdcFieldBinding<FdcFieldDef>? tryResolveAny(
    FdcDataSet dataSet,
    String fieldName,
  ) {
    return tryResolve<FdcFieldDef>(dataSet, fieldName);
  }

  static bool _isAllowed(FdcFieldDef fieldDef, List<Type> allowedFieldTypes) {
    for (final type in allowedFieldTypes) {
      if (_isAssignableToAllowedType(fieldDef, type)) {
        return true;
      }
    }
    return false;
  }

  static bool _isAssignableToAllowedType(FdcFieldDef fieldDef, Type type) {
    if (type == FdcFieldDef) {
      return true;
    }
    if (type == FdcStringField) {
      return fieldDef is FdcStringField;
    }
    if (type == FdcIntegerField) {
      return fieldDef is FdcIntegerField;
    }
    if (type == FdcDecimalField) {
      return fieldDef is FdcDecimalField;
    }
    if (type == FdcBooleanField) {
      return fieldDef is FdcBooleanField;
    }
    if (type == FdcDateField) {
      return fieldDef is FdcDateField;
    }
    if (type == FdcDateTimeField) {
      return fieldDef is FdcDateTimeField;
    }
    if (type == FdcTimeField) {
      return fieldDef is FdcTimeField;
    }
    if (type == FdcGuidField) {
      return fieldDef is FdcGuidField;
    }
    if (type == FdcObjectField) {
      return fieldDef is FdcObjectField;
    }

    // Dart does not allow `fieldDef is type` when `type` is a runtime Type
    // value. Keep an exact runtime-type fallback for rare internal/custom uses
    // that pass a concrete custom field class in allowedFieldTypes.
    return fieldDef.runtimeType == type;
  }

  static String _typeName(Type type) => type.toString();

  static String _ownerPrefix(String? ownerName) {
    if (ownerName == null || ownerName.isEmpty) {
      return '';
    }
    return '$ownerName: ';
  }
}
