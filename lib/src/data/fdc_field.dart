// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart' show internal;

import 'fdc_data_type.dart';
import 'fdc_field_def.dart';
import 'types/fdc_decimal.dart';
import 'types/fdc_guid.dart';
import 'types/fdc_time.dart';

/// Reads the current runtime value for a field name.
///
/// Dataset internals provide this callback when binding [FdcField] to the
/// current record or edit buffer. It is not an application extension point.
@internal
typedef FdcFieldValueReader = Object? Function(String fieldName);

/// Writes a runtime value for a field name through the dataset-owned path.
///
/// Dataset internals provide this callback so [FdcField] writes participate in
/// normalization, edit buffering, validation, and change tracking. It is not an
/// application extension point.
@internal
typedef FdcFieldValueWriter = void Function(String fieldName, Object? value);

/// Runtime accessor for a dataset field on the current record/edit buffer.
///
/// [FdcFieldDef] is schema metadata only. [FdcField] is the bound runtime
/// object returned by `FdcDataSet.fieldByName`, and owns value accessors such
/// as [value], [isNull], and the typed read views [asString], [asDecimal], etc.
class FdcField {
  /// Creates a [FdcField].
  @internal
  const FdcField({
    required FdcFieldDef definition,
    required FdcFieldValueReader valueReader,
    required FdcFieldValueWriter valueWriter,
  }) : _definition = definition,
       _valueReader = valueReader,
       _valueWriter = valueWriter;

  final FdcFieldDef _definition;
  final FdcFieldValueReader _valueReader;
  final FdcFieldValueWriter _valueWriter;

  /// Schema/metadata definition behind this runtime field accessor.
  FdcFieldDef get definition => _definition;

  /// Schema field name from [definition]; it does not vary with record
  /// navigation.
  String get name => _definition.name;

  /// Schema data type from [definition]; this describes field metadata, not the
  /// runtime value type of one record.
  FdcDataType get dataType => _definition.dataType;

  /// Optional schema label from [definition] used by controls and validation
  /// UI.
  String? get label => _definition.label;

  /// Schema-required flag from [definition], used by built-in validation.
  bool get required => _definition.required;

  /// Schema default from [definition], applied by dataset insert initialization
  /// where supported.
  Object? get defaultValue => _definition.defaultValue;

  /// Optional persistence override from [definition]; `null` keeps the field
  /// type's default persistence policy.
  bool? get persistent => _definition.persistent;

  /// True when this field is backed by a calculated field definition.
  ///
  /// Calculated fields derive their values from row data and reject normal
  /// dataset writes.
  bool get isCalculated => _definition.isCalculated;

  /// True when this field participates in persistence-oriented dataset output.
  ///
  /// The value follows the field definition: regular fields are persistent by
  /// default, while calculated fields are not unless explicitly overridden.
  bool get isPersistent => _definition.isPersistent;

  /// Current value from the dataset current record/edit buffer.
  Object? get value => _valueReader(name);

  /// Writes the current edit/insert buffer value.
  set value(Object? newValue) => _valueWriter(name, newValue);

  /// Whether [value] is currently null on the dataset current record.
  bool get isNull => value == null;

  /// Read-only string view of [value]. Use [value] to write.
  String? get asString {
    _ensureValueAccessor(FdcDataType.string, 'asString');
    return value as String?;
  }

  /// Read-only integer view of [value]. Use [value] to write.
  int? get asInteger {
    _ensureValueAccessor(FdcDataType.integer, 'asInteger');
    return value as int?;
  }

  /// Read-only fixed-scale decimal view of [value]. Use [value] to write.
  FdcDecimal? get asDecimal {
    _ensureValueAccessor(FdcDataType.decimal, 'asDecimal');
    final current = value;
    return current is FdcDecimal ? current : null;
  }

  /// Numeric compatibility view for decimal values.
  ///
  /// Prefer [asDecimal] for exact decimal-safe reads. This accessor exists for
  /// calculations and UI code that still need a Dart [num].
  num? get asNum {
    _ensureValueAccessor(FdcDataType.decimal, 'asNum');
    final current = value;
    if (current is FdcDecimal) {
      return current.toNum();
    }
    return current is num ? current : null;
  }

  /// Read-only boolean view of [value]. Use [value] to write.
  bool? get asBoolean {
    _ensureValueAccessor(FdcDataType.boolean, 'asBoolean');
    return value as bool?;
  }

  /// Read-only date-only view of [value]. Use [value] to write.
  DateTime? get asDate {
    _ensureValueAccessor(FdcDataType.date, 'asDate');
    return value as DateTime?;
  }

  /// Read-only date-time view of [value]. Use [value] to write.
  DateTime? get asDateTime {
    _ensureValueAccessor(FdcDataType.dateTime, 'asDateTime');
    return value as DateTime?;
  }

  /// Read-only time view of [value]. Use [value] to write.
  FdcTime? get asTime {
    _ensureValueAccessor(FdcDataType.time, 'asTime');
    return value as FdcTime?;
  }

  /// Read-only GUID view of [value]. Use [value] to write.
  FdcGuid? get asGuid {
    _ensureValueAccessor(FdcDataType.guid, 'asGuid');
    return value as FdcGuid?;
  }

  /// Read-only object view of [value]. Use [value] to write.
  Object? get asObject {
    _ensureValueAccessor(FdcDataType.object, 'asObject');
    return value;
  }

  void _ensureValueAccessor(FdcDataType expected, String accessorName) {
    if (dataType == expected) {
      return;
    }

    throw StateError(
      'Invalid field value access: field "$name" is $_publicFieldTypeName, '
      'cannot access $accessorName.',
    );
  }

  String get _publicFieldTypeName {
    switch (dataType) {
      case FdcDataType.string:
        return 'FdcStringField';
      case FdcDataType.integer:
        return 'FdcIntegerField';
      case FdcDataType.decimal:
        return 'FdcDecimalField';
      case FdcDataType.boolean:
        return 'FdcBooleanField';
      case FdcDataType.date:
        return 'FdcDateField';
      case FdcDataType.dateTime:
        return 'FdcDateTimeField';
      case FdcDataType.time:
        return 'FdcTimeField';
      case FdcDataType.guid:
        return 'FdcGuidField';
      case FdcDataType.object:
        return 'FdcObjectField';
    }
  }
}
