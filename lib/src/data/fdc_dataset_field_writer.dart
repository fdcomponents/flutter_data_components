// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'fdc_dataset_edit_buffer.dart';
import 'fdc_field_def.dart';
import 'fdc_field_name.dart';
import 'fdc_field_value_normalizer.dart';

/// Describes a single field value change produced by a dataset write operation.
class FdcFieldChange {
  const FdcFieldChange({
    required this.fieldIndex,
    required this.oldValue,
    required this.newValue,
  });

  final int fieldIndex;
  final Object? oldValue;
  final Object? newValue;
}

/// Internal field mutation engine for `FdcDataSet`.
///
/// This class owns the low-level rules for writing user values into the active
/// edit buffer. The dataset remains responsible for lifecycle orchestration,
/// event emission, view rebuilds, cache invalidation and listener notifications.
class FdcDataSetFieldWriter {
  const FdcDataSetFieldWriter({
    required this.fields,
    required this.fieldIndexByName,
    required this.applyCalculatedFields,
  });

  final List<FdcFieldDef> fields;
  final Map<String, int> fieldIndexByName;
  final bool Function(List<Object?> values) applyCalculatedFields;

  List<FdcFieldChange> writeEditBufferFieldValue({
    required FdcDataSetEditBuffer edit,
    required String fieldName,
    required Object? value,
  }) {
    final index = fieldIndex(fieldName);
    final field = fields[index];
    // Calculated and storage read-only fields are owned by calculators or
    // adapters/server refreshes. User/programmatic dataset writes should follow
    // the same field-level write rules that bindings and visual controls use.
    if (field.isReadOnly) {
      throw StateError(
        'Read-only field cannot be assigned directly: $fieldName',
      );
    }

    final buffer = edit.buffer;
    if (buffer == null) {
      throw StateError('Dataset has no active edit buffer.');
    }

    final normalizedValue = FdcFieldValueNormalizer.normalize(field, value);

    if (buffer[index] == normalizedValue) {
      return const <FdcFieldChange>[];
    }

    final oldValues = List<Object?>.of(buffer);
    buffer[index] = normalizedValue;
    applyCalculatedFields(buffer);
    return fieldChangesBetween(oldValues, buffer);
  }

  Set<int> changedIndexesBetween(
    List<Object?> oldValues,
    List<Object?> newValues,
  ) {
    if (oldValues.length != newValues.length) {
      throw ArgumentError('Value buffers do not have the same length.');
    }

    final result = <int>{};
    for (var i = 0; i < oldValues.length; i++) {
      if (oldValues[i] != newValues[i]) {
        result.add(i);
      }
    }
    return result;
  }

  List<FdcFieldChange> fieldChangesBetween(
    List<Object?> oldValues,
    List<Object?> newValues,
  ) {
    if (oldValues.length != newValues.length) {
      throw ArgumentError('Value buffers do not have the same length.');
    }

    final result = <FdcFieldChange>[];
    for (var i = 0; i < oldValues.length; i++) {
      if (oldValues[i] != newValues[i]) {
        result.add(
          FdcFieldChange(
            fieldIndex: i,
            oldValue: oldValues[i],
            newValue: newValues[i],
          ),
        );
      }
    }
    return result;
  }

  int fieldIndex(String fieldName) {
    final index = fieldIndexByName[FdcFieldName.normalize(fieldName)];
    if (index == null) {
      throw ArgumentError.value(fieldName, 'fieldName', 'Unknown field.');
    }
    return index;
  }
}
