// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'fdc_change_set.dart';
import 'fdc_dataset_record_mapper.dart';
import 'fdc_dataset_state.dart';
import 'fdc_field_def.dart';
import 'fdc_record.dart';

/// Builds a cached-update change set from the internal record store.
///
/// Kept separate from `FdcDataSet` so update extraction rules are isolated
/// from navigation/editing/validation lifecycle code.
class FdcDataSetChangeSetBuilder {
  const FdcDataSetChangeSetBuilder({
    required this.fields,
    required this.records,
    required this.recordMapper,
    this.excludedRecordIds = const <int>{},
  });

  final List<FdcFieldDef> fields;
  final List<FdcRecord> records;
  final FdcDataSetRecordMapper recordMapper;
  final Set<int> excludedRecordIds;

  FdcChangeSet build() {
    final inserts = <FdcChangeSetEntry>[];
    final updates = <FdcChangeSetEntry>[];
    final deletes = <FdcChangeSetEntry>[];

    for (final record in records) {
      if (excludedRecordIds.contains(record.id)) {
        continue;
      }

      switch (record.state) {
        case FdcRecordState.inserted:
          inserts.add(
            FdcChangeSetEntry(
              recordId: record.id,
              values: recordMapper.recordToMap(record),
              originalValues: const <String, Object?>{},
              changedFields: _fieldNamesForIndexes(
                _persistentFieldIndexes(record.changedFieldIndexes()),
              ),
            ),
          );
        case FdcRecordState.modified:
          final changedIndexes = _persistentFieldIndexes(
            record.changedFieldIndexes(),
          );
          if (changedIndexes.isEmpty) {
            continue;
          }
          final originalIndexes = <int>{
            ...changedIndexes,
            ..._keyFieldIndexes(),
          };
          updates.add(
            FdcChangeSetEntry(
              recordId: record.id,
              values: recordMapper.recordToMap(
                record,
                onlyFieldIndexes: changedIndexes,
              ),
              originalValues: recordMapper.recordToOriginalMap(
                record,
                onlyFieldIndexes: originalIndexes,
              ),
              changedFields: _fieldNamesForIndexes(changedIndexes),
            ),
          );
        case FdcRecordState.deleted:
          deletes.add(
            FdcChangeSetEntry(
              recordId: record.id,
              values: recordMapper.recordToMap(record),
              originalValues: recordMapper.recordToOriginalMap(record),
              changedFields: const <String>{},
            ),
          );
        case FdcRecordState.unchanged:
          break;
      }
    }

    return FdcChangeSet(
      inserts: inserts,
      updates: updates,
      deletes: deletes,
      fields: fields,
    );
  }

  Set<int> _keyFieldIndexes() {
    final result = <int>{};
    for (final key in fields.where((field) => field.isKey)) {
      final normalized = key.name.toLowerCase();
      for (var i = 0; i < fields.length; i++) {
        if (fields[i].name.toLowerCase() == normalized) {
          result.add(i);
          break;
        }
      }
    }
    return result;
  }

  Set<int> _persistentFieldIndexes(Set<int> indexes) {
    return {
      for (final index in indexes)
        if (fields[index].isPersistent) index,
    };
  }

  Set<String> _fieldNamesForIndexes(Set<int> indexes) {
    return {for (final index in indexes) fields[index].name};
  }
}
