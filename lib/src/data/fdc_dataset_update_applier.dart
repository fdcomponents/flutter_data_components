// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'fdc_data_adapter.dart';
import 'fdc_dataset_state.dart';
import 'fdc_field_def.dart';
import 'fdc_field_name.dart';
import 'fdc_field_value_normalizer.dart';
import 'fdc_record.dart';
import 'fdc_record_store.dart';

/// Applies successful adapter results and cached-update rollback rules to the
/// internal record store.
///
/// It intentionally contains no event/state/notification logic. FdcDataSet
/// remains responsible for lifecycle orchestration and listener updates.
class FdcDataSetUpdateApplier {
  const FdcDataSetUpdateApplier({
    required this.fields,
    required this.fieldIndexByName,
    required this.applyCalculatedFields,
    required this.invalidateComparableCacheForField,
  });

  final List<FdcFieldDef> fields;
  final Map<String, int> fieldIndexByName;
  final bool Function(List<Object?> values) applyCalculatedFields;
  final void Function(int fieldIndex) invalidateComparableCacheForField;

  void acceptAppliedChanges({
    required FdcRecordStore recordStore,
    required FdcDataApplyResult result,
    required Set<int> appliedRecordIds,
  }) {
    recordStore.removeWhere(
      (record) =>
          record.state == FdcRecordState.deleted &&
          appliedRecordIds.contains(record.id),
    );

    for (final record in recordStore.records) {
      if (!appliedRecordIds.contains(record.id)) {
        continue;
      }

      final serverRow = result.serverRows[record.id];
      if (serverRow != null) {
        applyServerRow(record, serverRow);
      }
      record.acceptChanges();
    }
  }

  void cancelCachedUpdates(FdcRecordStore recordStore) {
    recordStore.removeWhere(
      (record) => record.state == FdcRecordState.inserted,
    );

    for (final record in recordStore.records) {
      if (record.state == FdcRecordState.modified ||
          record.state == FdcRecordState.deleted) {
        record.restoreOriginalValues();
        record.state = FdcRecordState.unchanged;
      }
    }
  }

  void applyServerRow(FdcRecord record, Map<String, Object?> row) {
    final values = record.valuesSnapshot();

    final seenFieldNames = <String, String>{};
    for (final entry in row.entries) {
      final normalizedFieldName = FdcFieldName.normalize(entry.key);
      final previousKey = seenFieldNames[normalizedFieldName];
      if (previousKey != null) {
        throw ArgumentError.value(
          entry.key,
          'row',
          'Duplicate row field name differing only by case: '
              '"$previousKey" and "${entry.key}".',
        );
      }
      seenFieldNames[normalizedFieldName] = entry.key;

      final index = fieldIndexByName[normalizedFieldName];
      if (index == null) {
        continue;
      }
      values[index] = FdcFieldValueNormalizer.normalize(
        fields[index],
        entry.value,
      );
    }

    applyCalculatedFields(values);
    FdcFieldValueNormalizer.normalizeCalculatedValuesInPlace(fields, values);

    for (var index = 0; index < values.length; index++) {
      if (record.valueAt(index) == values[index]) {
        continue;
      }
      record.setValueAt(index, values[index]);
      invalidateComparableCacheForField(index);
    }
  }
}
