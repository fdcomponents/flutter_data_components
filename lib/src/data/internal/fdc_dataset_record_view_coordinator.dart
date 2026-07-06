// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../fdc_data_errors.dart';
import '../fdc_dataset_record_mapper.dart';
import '../fdc_dataset_state.dart';
import '../fdc_dataset_view_controller.dart';
import '../fdc_record.dart';
import '../fdc_record_store.dart';
import 'fdc_dataset_cursor_coordinator.dart';

/// Internal owner of structural record/view commit orchestration.
///
/// The dataset remains the public facade and retains schema, validation,
/// lifecycle events, notifications, and revision ownership. This coordinator
/// centralizes the behavior-neutral mechanics for loading, replacing,
/// appending, discarding, and positioning records in the active view.
final class FdcDataSetRecordViewCoordinator {
  FdcDataSetRecordViewCoordinator({
    required FdcRecordStore recordStore,
    required FdcDataSetViewController view,
    required FdcDataSetCursorCoordinator cursor,
    required FdcDataSetRecordMapper Function() readRecordMapper,
    required void Function({int? preserveRecordId, required bool notify})
    rebuildView,
    required void Function() beforeAppendRows,
    required void Function(bool adapterQueryChanged) beforeReplaceRows,
    required void Function(FdcRecord record) beforeDiscardRecord,
    required void Function({required bool invalidateAggregateCache})
    clearEditBuffer,
    required bool Function() readDiscardInvalidatesAggregateCache,
    required bool Function() readPagingEnabled,
  }) : _recordStore = recordStore,
       _view = view,
       _cursor = cursor,
       _readRecordMapper = readRecordMapper,
       _rebuildView = rebuildView,
       _beforeAppendRows = beforeAppendRows,
       _beforeReplaceRows = beforeReplaceRows,
       _beforeDiscardRecord = beforeDiscardRecord,
       _clearEditBuffer = clearEditBuffer,
       _readDiscardInvalidatesAggregateCache =
           readDiscardInvalidatesAggregateCache,
       _readPagingEnabled = readPagingEnabled;

  final FdcRecordStore _recordStore;
  final FdcDataSetViewController _view;
  final FdcDataSetCursorCoordinator _cursor;
  final FdcDataSetRecordMapper Function() _readRecordMapper;
  final void Function({int? preserveRecordId, required bool notify})
  _rebuildView;
  final void Function() _beforeAppendRows;
  final void Function(bool adapterQueryChanged) _beforeReplaceRows;
  final void Function(FdcRecord record) _beforeDiscardRecord;
  final void Function({required bool invalidateAggregateCache})
  _clearEditBuffer;
  final bool Function() _readDiscardInvalidatesAggregateCache;
  final bool Function() _readPagingEnabled;

  int get visibleRecordCount => _view.viewIndexes.length;

  FdcRecord? currentRecord({
    required FdcDataSetState state,
    required int? editRecordId,
  }) {
    if ((state == FdcDataSetState.edit || state == FdcDataSetState.insert) &&
        editRecordId != null) {
      return _recordStore.byId(editRecordId);
    }

    final activeIndex = _cursor.currentIndex;
    if (activeIndex < 0 || activeIndex >= _view.viewIndexes.length) {
      return null;
    }

    final rawIndex = _view.viewIndexes[activeIndex];
    if (rawIndex < 0 || rawIndex >= _recordStore.length) {
      return null;
    }
    return _recordStore.atRawIndex(rawIndex);
  }

  int rawIndexForActiveIndex(int activeIndex) {
    return _view.rawIndexForActiveIndex(
      activeIndex: activeIndex,
      fallbackRawIndex: _recordStore.length,
    );
  }

  FdcRecord recordAtActiveIndex(int activeIndex) {
    if (activeIndex < 0 || activeIndex >= _view.viewIndexes.length) {
      throw RangeError.index(activeIndex, _view.viewIndexes, 'activeIndex');
    }
    return _recordStore.atRawIndex(_view.viewIndexes[activeIndex]);
  }

  int activeIndexForRecordId(int recordId) {
    return _view.activeIndexForRecordId(
      recordId,
      records: _recordStore.records,
    );
  }

  void appendRows(
    List<Map<String, Object?>> rows, {
    List<int>? internalRowIds,
    int? internalNextRowId,
  }) {
    _beforeAppendRows();
    final loadedRecords = _mapLoadedRecords(rows, internalRowIds);
    _recordStore.appendAll(loadedRecords);
    _advanceRecordIdentity(internalRowIds, internalNextRowId);
  }

  void replaceRows(
    List<Map<String, Object?>> rows, {
    List<int>? internalRowIds,
    int? internalNextRowId,
    bool adapterQueryChanged = true,
  }) {
    _beforeReplaceRows(adapterQueryChanged);
    final loadedRecords = _mapLoadedRecords(rows, internalRowIds);
    _recordStore.replaceAll(loadedRecords);
    _advanceRecordIdentity(internalRowIds, internalNextRowId);
    _rebuildView(notify: false);
    _cursor.normalize(_view.normalizeCurrentIndex(_cursor.currentIndex));
  }

  void refreshInsertedRecordView(
    FdcRecord record, {
    required bool keepAtViewEnd,
    int? keepBeforeRecordId,
  }) {
    _view.clearComparableValueCache();
    if (_readPagingEnabled()) {
      _cursor.currentIndex = _view.rebuildAdapterPageView(
        records: _recordStore.records,
        currentIndex: _cursor.currentIndex,
        preserveRecordId: record.id,
      );
    } else {
      _rebuildView(preserveRecordId: record.id, notify: false);
    }

    if (keepAtViewEnd) {
      _moveRecordToViewEnd(record.id);
    } else if (keepBeforeRecordId != null) {
      _moveRecordBeforeInView(record.id, keepBeforeRecordId);
    } else {
      _selectRecord(record.id);
    }
  }

  void discardRecord(FdcRecord record, {required int oldIndex}) {
    _beforeDiscardRecord(record);
    _recordStore.removeById(record.id);
    _clearEditBuffer(
      invalidateAggregateCache: _readDiscardInvalidatesAggregateCache(),
    );
    rebuildViewSelectingNearestRow(oldIndex);
  }

  void rebuildViewSelectingNearestRow(int oldIndex) {
    // Do not let the view infer preserveRecordId from stale indexes after the
    // current record was removed. Select the nearest remaining visual row.
    _cursor.currentIndex = -1;
    _rebuildView(notify: false);
    final count = visibleRecordCount;
    _cursor.currentIndex = count == 0
        ? -1
        : oldIndex.clamp(0, count - 1).toInt();
    _cursor.eof = count == 0;
  }

  List<FdcRecord> _mapLoadedRecords(
    List<Map<String, Object?>> rows,
    List<int>? internalRowIds,
  ) {
    if (internalRowIds != null && internalRowIds.length != rows.length) {
      throw FdcDataSetException(
        message:
            'Adapter returned ${internalRowIds.length} '
            'internal row ids for '
            '${rows.length} loaded rows.',
      );
    }

    final mapper = _readRecordMapper();
    return <FdcRecord>[
      for (var i = 0; i < rows.length; i++)
        mapper.recordFromMap(
          rows[i],
          recordId: internalRowIds == null
              ? _recordStore.takeNextRecordId()
              : internalRowIds[i],
        ),
    ];
  }

  void _advanceRecordIdentity(
    List<int>? internalRowIds,
    int? internalNextRowId,
  ) {
    if (internalRowIds != null) {
      _recordStore.ensureNextRecordIdAfter(internalRowIds);
    }
    if (internalNextRowId != null) {
      _recordStore.ensureNextRecordIdAtLeast(internalNextRowId);
    }
  }

  void _moveRecordToViewEnd(int recordId) {
    final rawIndex = _recordStore.rawIndexForId(recordId);
    if (rawIndex == null) {
      _cursor.reset();
      return;
    }

    final viewPosition = _view.viewIndexes.indexOf(rawIndex);
    if (viewPosition < 0) {
      _selectRecord(recordId);
      return;
    }

    _view.viewIndexes
      ..removeAt(viewPosition)
      ..add(rawIndex);
    _cursor.currentIndex = _view.viewIndexes.length - 1;
    _cursor.eof = visibleRecordCount == 0;
  }

  void _moveRecordBeforeInView(int recordId, int anchorRecordId) {
    if (recordId == anchorRecordId) {
      _selectRecord(recordId);
      return;
    }

    final rawIndex = _recordStore.rawIndexForId(recordId);
    final anchorRawIndex = _recordStore.rawIndexForId(anchorRecordId);
    if (rawIndex == null || anchorRawIndex == null) {
      _selectRecord(recordId);
      return;
    }

    final viewPosition = _view.viewIndexes.indexOf(rawIndex);
    final anchorViewPosition = _view.viewIndexes.indexOf(anchorRawIndex);
    if (viewPosition < 0 || anchorViewPosition < 0) {
      _selectRecord(recordId);
      return;
    }

    _view.viewIndexes.removeAt(viewPosition);
    final adjustedAnchorPosition = viewPosition < anchorViewPosition
        ? anchorViewPosition - 1
        : anchorViewPosition;
    _view.viewIndexes.insert(adjustedAnchorPosition, rawIndex);
    _cursor.currentIndex = adjustedAnchorPosition;
    _cursor.eof = visibleRecordCount == 0;
  }

  void _selectRecord(int recordId) {
    _cursor.currentIndex = activeIndexForRecordId(recordId);
    _cursor.eof = visibleRecordCount == 0;
  }
}
