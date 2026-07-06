// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:collection';

import 'fdc_record.dart';

/// Owns the dataset's physical record list and record identity allocation.
///
/// The store intentionally knows nothing about filters, sorts, validation, or
/// dataset lifecycle events. `FdcDataSet` remains the orchestrator; this class
/// only centralizes raw storage operations so insert/delete/load/apply flows do
/// not manipulate the backing list and id counter directly.
class FdcRecordStore {
  final List<FdcRecord> _records = <FdcRecord>[];
  final Map<int, FdcRecord> _recordsById = <int, FdcRecord>{};
  final Map<int, int> _rawIndexById = <int, int>{};
  int _nextRecordId = 1;

  /// Read-only view of the physical record list.
  ///
  /// Records themselves remain mutable because dataset collaborators update
  /// field values and states, but structural mutations must go through this
  /// store so the id indexes stay in sync.
  List<FdcRecord> get records => UnmodifiableListView<FdcRecord>(_records);

  int get length => _records.length;

  /// Runtime identities for all existing physical records.
  ///
  /// These ids are internal dataset identities, not business primary keys.
  /// They are stable for a record lifetime and are intentionally not reset on
  /// close/reload so stale UI state can never collide with newly loaded rows.
  Iterable<int> get ids => _records.map((record) => record.id);

  int takeNextRecordId() => _nextRecordId++;

  void ensureNextRecordIdAfter(Iterable<int> recordIds) {
    for (final recordId in recordIds) {
      if (recordId >= _nextRecordId) {
        _nextRecordId = recordId + 1;
      }
    }
  }

  void ensureNextRecordIdAtLeast(int nextRecordId) {
    if (nextRecordId > _nextRecordId) {
      _nextRecordId = nextRecordId;
    }
  }

  FdcRecord? byId(int? recordId) {
    if (recordId == null) {
      return null;
    }
    return _recordsById[recordId];
  }

  bool containsId(int recordId) => _recordsById.containsKey(recordId);

  FdcRecord atRawIndex(int rawIndex) {
    if (rawIndex < 0 || rawIndex >= _records.length) {
      throw RangeError.index(rawIndex, _records, 'rawIndex');
    }
    return _records[rawIndex];
  }

  int? rawIndexForId(int recordId) => _rawIndexById[recordId];

  void insertRaw(int rawIndex, FdcRecord record) {
    if (rawIndex < 0 || rawIndex > _records.length) {
      throw RangeError.range(rawIndex, 0, _records.length, 'rawIndex');
    }
    if (_recordsById.containsKey(record.id)) {
      throw ArgumentError.value(
        record.id,
        'record.id',
        'A record with the same runtime id already exists.',
      );
    }

    _records.insert(rawIndex, record);
    _recordsById[record.id] = record;
    _shiftRawIndexes(start: rawIndex, delta: 1);
    _rawIndexById[record.id] = rawIndex;
  }

  bool removeById(int recordId) {
    final index = rawIndexForId(recordId);
    if (index == null) {
      return false;
    }
    _records.removeAt(index);
    _recordsById.remove(recordId);
    _rawIndexById.remove(recordId);
    _shiftRawIndexes(start: index + 1, delta: -1);
    return true;
  }

  int removeWhere(bool Function(FdcRecord record) test) {
    final before = _records.length;
    _records.removeWhere(test);
    final removed = before - _records.length;
    if (removed > 0) {
      rebuildIndex();
    }
    return removed;
  }

  void clear() {
    _records.clear();
    _recordsById.clear();
    _rawIndexById.clear();
  }

  void replaceAll(Iterable<FdcRecord> records) {
    _records
      ..clear()
      ..addAll(records);
    rebuildIndex();
  }

  void appendAll(Iterable<FdcRecord> records) {
    _records.addAll(records);
    rebuildIndex();
  }

  /// Rebuilds the id lookup indexes after bulk replacement operations.
  ///
  /// This is the preferred path for bulk structural changes. Single-row
  /// insert/remove operations shift cached raw indexes incrementally, which is
  /// intentionally simple but O(n). Bulk operations should rebuild or replace
  /// the store once instead of performing repeated per-row index shifts.
  void rebuildIndex() {
    final recordsById = <int, FdcRecord>{};
    final rawIndexById = <int, int>{};

    for (var rawIndex = 0; rawIndex < _records.length; rawIndex++) {
      final record = _records[rawIndex];
      if (recordsById.containsKey(record.id)) {
        throw ArgumentError.value(
          record.id,
          'record.id',
          'A record with the same runtime id already exists.',
        );
      }
      recordsById[record.id] = record;
      rawIndexById[record.id] = rawIndex;
    }

    _recordsById
      ..clear()
      ..addAll(recordsById);
    _rawIndexById
      ..clear()
      ..addAll(rawIndexById);
  }

  void _shiftRawIndexes({required int start, required int delta}) {
    // O(n) by design for single-row insert/remove operations. Keep bulk
    // structural changes on rebuild/replace paths to avoid repeated shifts.
    for (final entry in _rawIndexById.entries.toList()) {
      if (entry.value >= start) {
        _rawIndexById[entry.key] = entry.value + delta;
      }
    }
  }
}
