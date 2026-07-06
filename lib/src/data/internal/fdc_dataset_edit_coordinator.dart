// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../fdc_data_validation.dart';
import '../fdc_dataset_edit_buffer.dart';
import '../fdc_dataset_insert_target.dart';
import '../fdc_dataset_state.dart';
import '../fdc_record.dart';

/// Internal owner of the active dataset edit/insert session bookkeeping.
///
/// The dataset remains the public facade and still owns record-store mutation,
/// validation, event dispatch, view rebuilding, and persistence handoff. This
/// coordinator owns the mutable edit buffer and centralizes the common
/// post/cancel decision flow used before navigation and recordset changes.
final class FdcDataSetEditCoordinator {
  FdcDataSetEditCoordinator({
    required FdcDataSetState Function() readState,
    required bool Function() isImmediateApplyRunning,
    required int? Function() readPendingImmediatePostRecordId,
    required bool Function() hasDirtyEdit,
    required void Function() ensureWritable,
    required void Function() ensureOpen,
    required FdcRecord? Function() readCurrentRecord,
    required void Function() clearErrors,
    required void Function() beforeEdit,
    required void Function(FdcRecord record) beginEdit,
    required void Function(FdcDataSetState state) setState,
    required void Function() afterEdit,
    required void Function() notifyListeners,
    required void Function({
      required String operation,
      required int recordId,
      required void Function() body,
    })
    runOperation,
    required void Function() ensureBrowseLikeState,
    required int? Function() readCurrentRecordId,
    required FdcRecord Function() createInsertedRecord,
    required void Function(FdcRecord record) prepareInsert,
    required int Function(FdcDataSetInsertTarget target) resolveInsertRawIndex,
    required void Function(int rawIndex, FdcRecord record) insertRawRecord,
    required void Function(FdcRecord record) activateInsertedRecord,
    required void Function() emitNewRecordDefaults,
    required void Function(
      FdcRecord record, {
      required bool keepAtViewEnd,
      int? keepBeforeRecordId,
    })
    refreshInsertedRecordView,
    required void Function(FdcRecord record, int? previousRecordId)
    rollbackFailedInsert,
    required void Function() beforeInsert,
    required void Function() afterInsert,
    required void Function() ensureDeleteAllowed,
    required void Function() beforeDelete,
    required void Function() afterDelete,
    required void Function(int recordId, int oldIndex)
    markPendingImmediateDelete,
    required void Function(FdcRecord record, int oldIndex) markRecordDeleted,
    required void Function() ensureEditState,
    required void Function({
      required String operation,
      required int recordId,
      required void Function() body,
    })
    runPostOperation,
    required void Function() beforePost,
    required void Function(List<Object?> values) calculateCalculatedValues,
    required List<FdcValidationError> Function(
      FdcRecord record,
      List<Object?> values,
    )
    validatePost,
    required void Function(List<FdcValidationError> errors)
    publishValidationErrors,
    required List<int> Function(FdcRecord record, List<Object?> values)
    changedIndexesBetween,
    required void Function(
      FdcRecord record,
      List<Object?> values,
      List<int> changedIndexes,
    )
    applyPostedValues,
    required void Function(FdcRecord record) resolvePostedRecordState,
    required void Function(int recordId) retainVisibleRecord,
    required bool Function() hasAdapter,
    required FdcUpdateMode Function() readUpdateMode,
    required void Function(FdcRecord record) acceptChanges,
    required void Function({required bool invalidateAggregateCache})
    clearEditBuffer,
    required void Function(int recordId, FdcDataSetState state)
    markPendingImmediatePost,
    required void Function() afterPost,
    required void Function() scheduleImmediateApply,
    required bool Function() readPagingEnabled,
    required int Function() readCurrentIndex,
    required void Function(FdcRecord record, {required int oldIndex})
    discardRecordFromStore,
    required void Function({int? preserveRecordId}) rebuildView,
    required void Function() beforeCancel,
    required void Function() afterCancel,
  }) : _readState = readState,
       _isImmediateApplyRunning = isImmediateApplyRunning,
       _readPendingImmediatePostRecordId = readPendingImmediatePostRecordId,
       _hasDirtyEdit = hasDirtyEdit,
       _ensureWritable = ensureWritable,
       _ensureOpen = ensureOpen,
       _readCurrentRecord = readCurrentRecord,
       _clearErrors = clearErrors,
       _beforeEdit = beforeEdit,
       _beginEdit = beginEdit,
       _setState = setState,
       _afterEdit = afterEdit,
       _notifyListeners = notifyListeners,
       _runOperation = runOperation,
       _ensureBrowseLikeState = ensureBrowseLikeState,
       _readCurrentRecordId = readCurrentRecordId,
       _createInsertedRecord = createInsertedRecord,
       _prepareInsert = prepareInsert,
       _resolveInsertRawIndex = resolveInsertRawIndex,
       _insertRawRecord = insertRawRecord,
       _activateInsertedRecord = activateInsertedRecord,
       _emitNewRecordDefaults = emitNewRecordDefaults,
       _refreshInsertedRecordView = refreshInsertedRecordView,
       _rollbackFailedInsert = rollbackFailedInsert,
       _beforeInsert = beforeInsert,
       _afterInsert = afterInsert,
       _ensureDeleteAllowed = ensureDeleteAllowed,
       _beforeDelete = beforeDelete,
       _afterDelete = afterDelete,
       _markPendingImmediateDelete = markPendingImmediateDelete,
       _markRecordDeleted = markRecordDeleted,
       _ensureEditState = ensureEditState,
       _runPostOperation = runPostOperation,
       _beforePost = beforePost,
       _calculateCalculatedValues = calculateCalculatedValues,
       _validatePost = validatePost,
       _publishValidationErrors = publishValidationErrors,
       _changedIndexesBetween = changedIndexesBetween,
       _applyPostedValues = applyPostedValues,
       _resolvePostedRecordState = resolvePostedRecordState,
       _retainVisibleRecord = retainVisibleRecord,
       _hasAdapter = hasAdapter,
       _readUpdateMode = readUpdateMode,
       _acceptChanges = acceptChanges,
       _clearEditBuffer = clearEditBuffer,
       _markPendingImmediatePost = markPendingImmediatePost,
       _afterPost = afterPost,
       _scheduleImmediateApply = scheduleImmediateApply,
       _readPagingEnabled = readPagingEnabled,
       _readCurrentIndex = readCurrentIndex,
       _discardRecordFromStore = discardRecordFromStore,
       _rebuildView = rebuildView,
       _beforeCancel = beforeCancel,
       _afterCancel = afterCancel;

  final FdcDataSetState Function() _readState;
  final bool Function() _isImmediateApplyRunning;
  final int? Function() _readPendingImmediatePostRecordId;
  final bool Function() _hasDirtyEdit;
  final void Function() _ensureWritable;
  final void Function() _ensureOpen;
  final FdcRecord? Function() _readCurrentRecord;
  final void Function() _clearErrors;
  final void Function() _beforeEdit;
  final void Function(FdcRecord record) _beginEdit;
  final void Function(FdcDataSetState state) _setState;
  final void Function() _afterEdit;
  final void Function() _notifyListeners;
  final void Function({
    required String operation,
    required int recordId,
    required void Function() body,
  })
  _runOperation;
  final void Function() _ensureBrowseLikeState;
  final int? Function() _readCurrentRecordId;
  final FdcRecord Function() _createInsertedRecord;
  final void Function(FdcRecord record) _prepareInsert;
  final int Function(FdcDataSetInsertTarget target) _resolveInsertRawIndex;
  final void Function(int rawIndex, FdcRecord record) _insertRawRecord;
  final void Function(FdcRecord record) _activateInsertedRecord;
  final void Function() _emitNewRecordDefaults;
  final void Function(
    FdcRecord record, {
    required bool keepAtViewEnd,
    int? keepBeforeRecordId,
  })
  _refreshInsertedRecordView;
  final void Function(FdcRecord record, int? previousRecordId)
  _rollbackFailedInsert;
  final void Function() _beforeInsert;
  final void Function() _afterInsert;
  final void Function() _ensureDeleteAllowed;
  final void Function() _beforeDelete;
  final void Function() _afterDelete;
  final void Function(int recordId, int oldIndex) _markPendingImmediateDelete;
  final void Function(FdcRecord record, int oldIndex) _markRecordDeleted;
  final void Function() _ensureEditState;
  final void Function({
    required String operation,
    required int recordId,
    required void Function() body,
  })
  _runPostOperation;
  final void Function() _beforePost;
  final void Function(List<Object?> values) _calculateCalculatedValues;
  final List<FdcValidationError> Function(
    FdcRecord record,
    List<Object?> values,
  )
  _validatePost;
  final void Function(List<FdcValidationError> errors) _publishValidationErrors;
  final List<int> Function(FdcRecord record, List<Object?> values)
  _changedIndexesBetween;
  final void Function(
    FdcRecord record,
    List<Object?> values,
    List<int> changedIndexes,
  )
  _applyPostedValues;
  final void Function(FdcRecord record) _resolvePostedRecordState;
  final void Function(int recordId) _retainVisibleRecord;
  final bool Function() _hasAdapter;
  final FdcUpdateMode Function() _readUpdateMode;
  final void Function(FdcRecord record) _acceptChanges;
  final void Function({required bool invalidateAggregateCache})
  _clearEditBuffer;
  final void Function(int recordId, FdcDataSetState state)
  _markPendingImmediatePost;
  final void Function() _afterPost;
  final void Function() _scheduleImmediateApply;
  final bool Function() _readPagingEnabled;
  final int Function() _readCurrentIndex;
  final void Function(FdcRecord record, {required int oldIndex})
  _discardRecordFromStore;
  final void Function({int? preserveRecordId}) _rebuildView;
  final void Function() _beforeCancel;
  final void Function() _afterCancel;

  final FdcDataSetEditBuffer _bufferState = FdcDataSetEditBuffer();

  FdcDataSetEditBuffer get rawBuffer => _bufferState;
  int? get editRecordId => _bufferState.editRecordId;
  List<Object?>? get buffer => _bufferState.buffer;
  List<Object?>? get startValues => _bufferState.startValues;
  FdcRecordState? get startRecordState => _bufferState.startRecordState;
  int? get insertRecordId => _bufferState.insertRecordId;
  bool get modifiedByUser => _bufferState.modifiedByUser;
  set modifiedByUser(bool value) => _bufferState.modifiedByUser = value;
  bool get suppressUserTracking => _bufferState.suppressUserTracking;
  set suppressUserTracking(bool value) =>
      _bufferState.suppressUserTracking = value;

  bool get isActive => _bufferState.isActive;
  bool get isActiveInsertBufferUnmodified =>
      _bufferState.isActiveInsertBufferUnmodified;

  bool isEditingRecord(FdcRecord record) =>
      _bufferState.isEditingRecord(record);

  void begin(FdcRecord record, {required bool insertRecord}) {
    _bufferState.begin(record, insertRecord: insertRecord);
  }

  void clear() {
    _bufferState.clear();
  }

  void edit() {
    _ensureWritable();
    _ensureOpen();
    if (_isEditState(_readState())) {
      return;
    }
    final record = _readCurrentRecord();
    if (record == null) {
      throw StateError('Dataset has no current record to edit.');
    }

    _runOperation(
      operation: 'edit',
      recordId: record.id,
      body: () {
        _clearErrors();
        _beforeEdit();
        _beginEdit(record);
        _setState(FdcDataSetState.edit);
        _afterEdit();
        _notifyListeners();
      },
    );
  }

  void append() => _insert(const FdcDataSetInsertTarget.append());

  void insert() => _insert(const FdcDataSetInsertTarget.insertBeforeCurrent());

  void _insert(FdcDataSetInsertTarget target) {
    _ensureOpen();
    if (_readState() == FdcDataSetState.insert) {
      return;
    }

    _ensureWritable();
    _ensureBrowseLikeState();
    final insertBeforeRecordId = target.isInsertBeforeCurrent
        ? _readCurrentRecordId()
        : null;
    final record = _createInsertedRecord();

    _runOperation(
      operation: 'insert',
      recordId: record.id,
      body: () {
        var completed = false;
        try {
          _clearErrors();
          _beforeInsert();
          _prepareInsert(record);
          final rawIndex = _resolveInsertRawIndex(target);
          _insertRawRecord(rawIndex, record);
          _activateInsertedRecord(record);
          _emitNewRecordDefaults();
          _refreshInsertedRecordView(
            record,
            keepAtViewEnd: target.isAppend,
            keepBeforeRecordId: insertBeforeRecordId,
          );
          _afterInsert();
          _notifyListeners();
          completed = true;
        } finally {
          if (!completed) {
            _rollbackFailedInsert(record, insertBeforeRecordId);
          }
        }
      },
    );
  }

  void delete() {
    _ensureDeleteAllowed();

    // A record that is still in insert/append mode has not been posted yet.
    // Deleting it silently discards the active insert buffer: no validation,
    // no delete events, and no cancel events. A user-facing cancel remains
    // available through cancel(), with normal beforeCancel/afterCancel flow.
    final fireDeleteEvents = _readState() != FdcDataSetState.insert;
    final record = _readCurrentRecord();
    if (record == null) {
      return;
    }

    final deletedRecordId = record.id;
    final oldIndex = _readCurrentIndex();

    _runOperation(
      operation: 'delete',
      recordId: deletedRecordId,
      body: () {
        _clearErrors();
        if (fireDeleteEvents) {
          _beforeDelete();
        }

        if (_readUpdateMode() == FdcUpdateMode.immediate &&
            record.state != FdcRecordState.inserted &&
            record.id != insertRecordId) {
          _markPendingImmediateDelete(record.id, oldIndex);
        }

        final removeRecord =
            !_hasAdapter() ||
            record.id == insertRecordId ||
            record.state == FdcRecordState.inserted;

        if (removeRecord) {
          _discardRecordFromStore(record, oldIndex: oldIndex);
        } else {
          _markRecordDeleted(record, oldIndex);
        }

        _setState(FdcDataSetState.browse);
        if (fireDeleteEvents) {
          _afterDelete();
        }
        _notifyListeners();
        _scheduleImmediateApply();
      },
    );
  }

  void post() {
    _ensureEditState();
    final record = _readCurrentRecord();
    if (record == null) {
      throw StateError('Dataset has no current record to post.');
    }

    final values = buffer;
    if (values == null || !isEditingRecord(record)) {
      throw StateError('Dataset has no active edit buffer to post.');
    }

    _runPostOperation(
      operation: 'post',
      recordId: record.id,
      body: () {
        _clearErrors();
        _beforePost();
        _calculateCalculatedValues(values);

        final errors = _validatePost(record, values);
        if (errors.isNotEmpty) {
          _publishValidationErrors(errors);
          throw FdcDataSetValidationException(errors);
        }

        final changedIndexes = _changedIndexesBetween(record, values);
        if (changedIndexes.isNotEmpty) {
          _applyPostedValues(record, values, changedIndexes);
        }
        _resolvePostedRecordState(record);
        _retainVisibleRecord(record.id);

        if (!_hasAdapter()) {
          _acceptChanges(record);
          _clearEditBuffer(invalidateAggregateCache: false);
          _setState(FdcDataSetState.browse);
          _afterPost();
          _notifyListeners();
          return;
        }

        if (_readUpdateMode() == FdcUpdateMode.immediate) {
          _markPendingImmediatePost(record.id, _readState());
          _setState(FdcDataSetState.browse);
          _afterPost();
          _notifyListeners();
          _scheduleImmediateApply();
          return;
        }

        _clearEditBuffer(invalidateAggregateCache: false);
        _setState(FdcDataSetState.browse);
        _afterPost();
        _notifyListeners();
        _scheduleImmediateApply();
      },
    );
  }

  void cancel() {
    _ensureEditState();
    final record = _readCurrentRecord();
    if (record == null) {
      _clearEditBuffer(invalidateAggregateCache: !_readPagingEnabled());
      _rebuildView();
      _setState(FdcDataSetState.browse);
      _notifyListeners();
      return;
    }

    _runOperation(
      operation: 'cancel',
      recordId: record.id,
      body: () {
        _clearErrors();
        _beforeCancel();

        final recordId = record.id;
        final oldIndex = _readCurrentIndex();
        if (_readState() == FdcDataSetState.insert ||
            record.id == insertRecordId) {
          _discardRecordFromStore(record, oldIndex: oldIndex);
        } else {
          final values = startValues;
          final recordState = startRecordState;
          if (values != null) {
            record.restoreValues(values);
          }
          if (recordState != null) {
            record.state = recordState;
          }
          _rebuildView(preserveRecordId: recordId);
        }

        _clearEditBuffer(invalidateAggregateCache: !_readPagingEnabled());
        _setState(FdcDataSetState.browse);
        _afterCancel();
        _notifyListeners();
      },
    );
  }

  bool tryPostActiveEdit() {
    final state = _readState();
    if (!_isEditState(state)) {
      return true;
    }

    if (_isImmediateApplyRunning() &&
        _readPendingImmediatePostRecordId() != null) {
      return true;
    }

    if (state == FdcDataSetState.insert && isActiveInsertBufferUnmodified) {
      return true;
    }

    post();
    return !_isEditState(_readState());
  }

  bool tryResolveEditForRecordsetChange() {
    if (!_isEditState(_readState())) {
      return true;
    }

    if (_hasDirtyEdit()) {
      post();
    } else {
      cancel();
    }

    return !_isEditState(_readState());
  }

  bool tryCancelActiveEdit() {
    if (!_isEditState(_readState())) {
      return true;
    }

    cancel();
    return !_isEditState(_readState());
  }

  void dispose() {
    clear();
  }

  static bool _isEditState(FdcDataSetState state) =>
      state == FdcDataSetState.edit || state == FdcDataSetState.insert;
}
