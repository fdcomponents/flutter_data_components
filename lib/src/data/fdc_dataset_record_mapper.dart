// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'fdc_data_errors.dart';
import 'fdc_data_type.dart';
import 'fdc_dataset_state.dart';
import 'fdc_field_def.dart';
import 'fdc_field_name.dart';
import 'fdc_field_value_normalizer.dart';
import 'fdc_record.dart';

/// Converts between the dataset's external row shapes and its compact internal
/// [FdcRecord] representation.
///
/// FdcDataSet owns lifecycle, navigation and events; this mapper owns only
/// record materialization/projection rules. Keeping those rules here prevents
/// map/list conversion logic from being scattered through the dataset core.
class FdcDataSetRecordMapper {
  const FdcDataSetRecordMapper({
    required this.fields,
    required this.applyCalculatedFields,
  });

  final List<FdcFieldDef> fields;
  final bool Function(List<Object?> values) applyCalculatedFields;

  FdcRecord recordFromMap(Map<String, Object?> row, {required int recordId}) {
    final values = <Object?>[];
    for (final field in fields) {
      values.add(
        FdcFieldValueNormalizer.normalize(
          field,
          FdcFieldName.valueFromRow(
            row,
            FdcFieldName.normalize(field.name),
            defaultValue: null,
          ),
        ),
      );
    }
    applyCalculatedFields(values);
    FdcFieldValueNormalizer.normalizeCalculatedValuesInPlace(fields, values);
    return FdcRecord(id: recordId, values: values);
  }

  FdcRecord createInsertedRecord({required int recordId}) {
    final values = [
      for (final field in fields)
        FdcFieldValueNormalizer.normalize(
          field,
          _materializeDefaultValue(field),
        ),
    ];
    applyCalculatedFields(values);
    FdcFieldValueNormalizer.normalizeCalculatedValuesInPlace(fields, values);
    return FdcRecord(
      id: recordId,
      values: values,
      state: FdcRecordState.inserted,
    );
  }

  Map<String, Object?> recordToMap(
    FdcRecord record, {
    Set<int>? onlyFieldIndexes,
    bool includeNonPersistent = false,
  }) {
    return <String, Object?>{
      for (var i = 0; i < fields.length; i++)
        if ((includeNonPersistent || fields[i].isPersistent) &&
            (onlyFieldIndexes == null || onlyFieldIndexes.contains(i)))
          fields[i].name: record.valueAt(i),
    };
  }

  Map<String, Object?> recordToOriginalMap(
    FdcRecord record, {
    Set<int>? onlyFieldIndexes,
    bool includeNonPersistent = false,
  }) {
    return <String, Object?>{
      for (var i = 0; i < fields.length; i++)
        if ((includeNonPersistent || fields[i].isPersistent) &&
            (onlyFieldIndexes == null || onlyFieldIndexes.contains(i)))
          fields[i].name: record.originalValueAt(i),
    };
  }

  Object? _materializeDefaultValue(FdcFieldDef field) {
    final defaultValue = field.defaultValue;
    if (defaultValue == null) {
      return null;
    }
    if (defaultValue is FdcFieldDefaultValueFactory) {
      return defaultValue();
    }
    if (field.dataType == FdcDataType.guid) {
      throw const FdcDataSetException(
        message:
            'FdcGuidField does not support static default values. '
            'Use defaultValue: FdcGuid.newGuid so a fresh GUID is generated '
            'for each inserted/appended record.',
      );
    }
    return defaultValue;
  }
}
