// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../fdc_data_adapter.dart';
import '../fdc_field_def.dart';
import '../fdc_field_name.dart';
import '../fdc_record.dart';

/// Internal owner of dataset row-selection state and key synchronization.
///
/// The dataset remains the public facade and owns notifications, record/view
/// mutation, paging commits, and aggregate cache invalidation. This coordinator
/// unifies local record selection with paged key-based selection so callers do
/// not need to know which storage strategy is active.
final class FdcDataSetSelectionCoordinator {
  FdcDataSetSelectionCoordinator({
    required bool Function() pagingEnabled,
    required List<int> Function() readViewIndexes,
    required FdcRecord Function(int rawIndex) recordAtRawIndex,
    required List<FdcRecord> Function() readRecords,
    required void Function(List<FdcRecord> records) replaceRecords,
    required void Function(List<int> internalIds) ensureNextRecordIdAfter,
    required List<FdcFieldDef> Function() readFields,
    required int? Function(String normalizedName) fieldIndexByNormalizedName,
    required bool? Function() readSelectedFilter,
    required void Function(int? totalRecordCount) setTotalRecordCount,
    required Map<String, Object?> Function(
      FdcRecord record, {
      required bool includeNonPersistent,
    })
    recordToMap,
  }) : _pagingEnabled = pagingEnabled,
       _readViewIndexes = readViewIndexes,
       _recordAtRawIndex = recordAtRawIndex,
       _readRecords = readRecords,
       _replaceRecords = replaceRecords,
       _ensureNextRecordIdAfter = ensureNextRecordIdAfter,
       _readFields = readFields,
       _fieldIndexByNormalizedName = fieldIndexByNormalizedName,
       _readSelectedFilter = readSelectedFilter,
       _setTotalRecordCount = setTotalRecordCount,
       _recordToMap = recordToMap;

  final bool Function() _pagingEnabled;
  final List<int> Function() _readViewIndexes;
  final FdcRecord Function(int rawIndex) _recordAtRawIndex;
  final List<FdcRecord> Function() _readRecords;
  final void Function(List<FdcRecord> records) _replaceRecords;
  final void Function(List<int> internalIds) _ensureNextRecordIdAfter;
  final List<FdcFieldDef> Function() _readFields;
  final int? Function(String normalizedName) _fieldIndexByNormalizedName;
  final bool? Function() _readSelectedFilter;
  final void Function(int? totalRecordCount) _setTotalRecordCount;
  final Map<String, Object?> Function(
    FdcRecord record, {
    required bool includeNonPersistent,
  })
  _recordToMap;

  final Set<FdcDataRecordKey> _selectedRecordKeys = <FdcDataRecordKey>{};

  List<FdcDataRecordKey> get selectedKeysSnapshot =>
      List<FdcDataRecordKey>.unmodifiable(_selectedRecordKeys);

  int get selectedCount {
    var count = 0;
    for (final rawIndex in _readViewIndexes()) {
      if (_recordAtRawIndex(rawIndex).selected) {
        count++;
      }
    }
    return count;
  }

  bool isSelectedAt(int rowIndex) => _recordAtViewIndex(rowIndex).selected;

  bool setSelectedAt(int rowIndex, bool selected) {
    final record = _recordAtViewIndex(rowIndex);
    if (record.selected == selected) {
      return false;
    }
    record.selected = selected;
    syncSelectionKeyForRecord(record, selected);
    return true;
  }

  bool setAllVisible(bool selected) {
    var changed = false;
    for (final rawIndex in _readViewIndexes()) {
      final record = _recordAtRawIndex(rawIndex);
      if (record.selected != selected) {
        record.selected = selected;
        syncSelectionKeyForRecord(record, selected);
        changed = true;
      }
    }
    return changed;
  }

  List<Map<String, Object?>> selectedRows({
    required bool includeNonPersistent,
  }) {
    return <Map<String, Object?>>[
      for (final rawIndex in _readViewIndexes())
        if (_recordAtRawIndex(rawIndex).selected)
          _recordToMap(
            _recordAtRawIndex(rawIndex),
            includeNonPersistent: includeNonPersistent,
          ),
    ];
  }

  void syncSelectionKeyForRecord(FdcRecord record, bool selected) {
    if (!_pagingEnabled()) {
      return;
    }
    final key = _recordKeyForSelection(record);
    if (key == null) {
      throw StateError(
        'Paged row selection requires at least one dataset key field.',
      );
    }
    if (selected) {
      _selectedRecordKeys.add(key);
    } else {
      _selectedRecordKeys.remove(key);
    }
  }

  void syncLoadedRecordsFromKeys() {
    if (!_pagingEnabled() || _selectedRecordKeys.isEmpty) {
      return;
    }
    for (final record in _readRecords()) {
      final key = _recordKeyForSelection(record);
      record.selected = key != null && _selectedRecordKeys.contains(key);
    }
  }

  void applyPagedUnselectedLocalFilter(FdcDataLoadResult result) {
    if (!_pagingEnabled() || _readSelectedFilter() != false) {
      return;
    }
    final total = result.totalCount;
    if (total != null) {
      final deductedTotal = _selectedRecordKeys.isEmpty
          ? total
          : (total - _selectedRecordKeys.length).clamp(0, total).toInt();
      _setTotalRecordCount(deductedTotal);
    }
    if (_selectedRecordKeys.isEmpty) {
      return;
    }
    final records = _readRecords();
    final visibleRecords = <FdcRecord>[];
    final internalIds = <int>[];
    for (final record in records) {
      final key = _recordKeyForSelection(record);
      if (key != null && _selectedRecordKeys.contains(key)) {
        continue;
      }
      visibleRecords.add(record);
      internalIds.add(record.id);
    }
    if (visibleRecords.length == records.length) {
      return;
    }
    _replaceRecords(visibleRecords);
    _ensureNextRecordIdAfter(internalIds);
  }

  void clear() {
    _selectedRecordKeys.clear();
  }

  void dispose() {
    clear();
  }

  FdcRecord _recordAtViewIndex(int rowIndex) {
    final viewIndexes = _readViewIndexes();
    if (rowIndex < 0 || rowIndex >= viewIndexes.length) {
      throw RangeError.index(rowIndex, viewIndexes, 'rowIndex');
    }
    return _recordAtRawIndex(viewIndexes[rowIndex]);
  }

  FdcDataRecordKey? _recordKeyForSelection(FdcRecord record) {
    final keyFields = _readFields()
        .where((field) => field.isKey)
        .toList(growable: false);
    if (keyFields.isEmpty) {
      return null;
    }
    final fieldNames = <String>[];
    final values = <Object?>[];
    for (final field in keyFields) {
      final index = _fieldIndexByNormalizedName(
        FdcFieldName.normalize(field.name),
      );
      if (index == null) {
        return null;
      }
      fieldNames.add(field.name);
      values.add(record.valueAt(index));
    }
    return FdcDataRecordKey(
      fieldNames: List<String>.unmodifiable(fieldNames),
      values: List<Object?>.unmodifiable(values),
    );
  }
}
