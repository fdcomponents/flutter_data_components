// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:async';

import '../fdc_change_set.dart';
import '../fdc_data_adapter.dart';
import '../fdc_data_errors.dart';
import '../fdc_dataset_state.dart';
import '../fdc_record.dart';

/// Internal owner of dataset apply scheduling and pending immediate-update
/// bookkeeping.
///
/// The dataset remains the public facade and record-store host. This
/// coordinator owns apply control flow, serialization, shared concurrent calls,
/// adapter invocation sequencing, and immediate-mode recovery state.
final class FdcDataSetApplyCoordinator {
  FdcDataSetApplyCoordinator({
    required FdcUpdateMode updateMode,
    required bool Function() hasUpdates,
    required FdcDataSetState Function() readState,
    required void Function() ensureOpen,
    required bool Function() tryPostActiveEdit,
    required FdcChangeSet Function() buildApplyChangeSet,
    required Future<FdcDataApplyResult> Function(FdcChangeSet changes)
    applyLocalChanges,
    required FdcDataSetState Function() beginAdapterApply,
    required int Function() captureLifecycleGeneration,
    required bool Function(int generation) isLifecycleCurrent,
    required Future<FdcDataApplyResult> Function(
      IFdcDataAdapter adapter,
      FdcChangeSet changes,
    )
    applyAdapterChanges,
    required Future<FdcDataApplyResult> Function(
      FdcChangeSet changes,
      FdcDataApplyResult result,
      FdcDataSetState previousState,
    )
    completeApplyResult,
    required FdcDataApplyResult Function(
      FdcChangeSet changes,
      Object error,
      StackTrace stackTrace,
      FdcDataSetState previousState,
      int lifecycleGeneration,
    )
    completeApplyException,
    required IFdcDataAdapter? Function() readAdapter,
    required String Function(Object error) exceptionMessage,
  }) : _updateMode = updateMode,
       _hasUpdates = hasUpdates,
       _readState = readState,
       _ensureOpen = ensureOpen,
       _tryPostActiveEdit = tryPostActiveEdit,
       _buildApplyChangeSet = buildApplyChangeSet,
       _applyLocalChanges = applyLocalChanges,
       _beginAdapterApply = beginAdapterApply,
       _captureLifecycleGeneration = captureLifecycleGeneration,
       _isLifecycleCurrent = isLifecycleCurrent,
       _applyAdapterChanges = applyAdapterChanges,
       _completeApplyResult = completeApplyResult,
       _completeApplyException = completeApplyException,
       _readAdapter = readAdapter,
       _exceptionMessage = exceptionMessage;

  final FdcUpdateMode _updateMode;
  final bool Function() _hasUpdates;
  final FdcDataSetState Function() _readState;
  final void Function() _ensureOpen;
  final bool Function() _tryPostActiveEdit;
  final FdcChangeSet Function() _buildApplyChangeSet;
  final Future<FdcDataApplyResult> Function(FdcChangeSet changes)
  _applyLocalChanges;
  final FdcDataSetState Function() _beginAdapterApply;
  final int Function() _captureLifecycleGeneration;
  final bool Function(int generation) _isLifecycleCurrent;
  final Future<FdcDataApplyResult> Function(
    IFdcDataAdapter adapter,
    FdcChangeSet changes,
  )
  _applyAdapterChanges;
  final Future<FdcDataApplyResult> Function(
    FdcChangeSet changes,
    FdcDataApplyResult result,
    FdcDataSetState previousState,
  )
  _completeApplyResult;
  final FdcDataApplyResult Function(
    FdcChangeSet changes,
    Object error,
    StackTrace stackTrace,
    FdcDataSetState previousState,
    int lifecycleGeneration,
  )
  _completeApplyException;
  final IFdcDataAdapter? Function() _readAdapter;
  final String Function(Object error) _exceptionMessage;

  bool _immediateApplyScheduled = false;
  bool _immediateApplyKickoffQueued = false;
  bool _immediateApplyRunning = false;
  Future<FdcDataApplyResult>? _applyUpdatesFuture;

  int? _pendingImmediatePostRecordId;
  FdcDataSetState? _pendingImmediatePostState;
  final Map<int, int> _pendingImmediateDeleteOldIndexes = <int, int>{};

  int? get pendingImmediatePostRecordId => _pendingImmediatePostRecordId;

  bool get isImmediateApplyRunning => _immediateApplyRunning;

  FdcDataSetState? get pendingImmediatePostState => _pendingImmediatePostState;

  void markPendingImmediatePost(int recordId, FdcDataSetState previousState) {
    _pendingImmediatePostRecordId = recordId;
    _pendingImmediatePostState = previousState;
  }

  void clearPendingImmediatePost() {
    _pendingImmediatePostRecordId = null;
    _pendingImmediatePostState = null;
  }

  void markPendingImmediateDelete(int recordId, int oldIndex) {
    _pendingImmediateDeleteOldIndexes[recordId] = oldIndex;
  }

  bool get hasPendingImmediateDeletes =>
      _pendingImmediateDeleteOldIndexes.isNotEmpty;

  int? takePendingImmediateDeleteOldIndex(int recordId) =>
      _pendingImmediateDeleteOldIndexes.remove(recordId);

  void clearAppliedImmediateDeletes(Set<int> appliedRecordIds) {
    if (appliedRecordIds.isEmpty || _pendingImmediateDeleteOldIndexes.isEmpty) {
      return;
    }
    for (final recordId in appliedRecordIds) {
      _pendingImmediateDeleteOldIndexes.remove(recordId);
    }
  }

  void clearPendingImmediateDeletes() {
    _pendingImmediateDeleteOldIndexes.clear();
  }

  void scheduleImmediateApplyUpdates() {
    if (_updateMode != FdcUpdateMode.immediate || !_hasUpdates()) {
      return;
    }

    if (_immediateApplyScheduled || _immediateApplyRunning) {
      _immediateApplyScheduled = true;
      return;
    }

    _immediateApplyScheduled = true;
    _queueImmediateApplyUpdatesRun();
  }

  Future<FdcDataApplyResult> applyUpdates() {
    final runningApply = _applyUpdatesFuture;
    if (runningApply != null) {
      return runningApply;
    }

    final sharedCompleter = Completer<FdcDataApplyResult>();
    final sharedFuture = sharedCompleter.future;
    _applyUpdatesFuture = sharedFuture;
    unawaited(
      _runApplyUpdates()
          .then<void>(
            sharedCompleter.complete,
            onError: sharedCompleter.completeError,
          )
          .whenComplete(() {
            if (identical(_applyUpdatesFuture, sharedFuture)) {
              _applyUpdatesFuture = null;
            }
          }),
    );
    return sharedFuture;
  }

  Future<FdcDataApplyResult> _runApplyUpdates() async {
    _ensureOpen();
    if (!_tryPostActiveEdit()) {
      return const FdcDataApplyResult.failure();
    }

    final changes = _buildApplyChangeSet();
    if (changes.isEmpty) {
      return const FdcDataApplyResult.success();
    }

    final adapter = _readAdapter();
    if (adapter == null) {
      return _applyLocalChanges(changes);
    }

    final previousState = _beginAdapterApply();
    final lifecycleGeneration = _captureLifecycleGeneration();
    try {
      final result = await _applyAdapterChanges(adapter, changes);
      if (!_isLifecycleCurrent(lifecycleGeneration)) {
        return result;
      }
      return _completeApplyResult(changes, result, previousState);
    } on Object catch (error, stackTrace) {
      return _completeApplyException(
        changes,
        error,
        stackTrace,
        previousState,
        lifecycleGeneration,
      );
    }
  }

  Set<int> changeSetRecordIds(FdcChangeSet changes) {
    return <int>{
      for (final insert in changes.inserts) insert.recordId,
      for (final update in changes.updates) update.recordId,
      for (final delete in changes.deletes) delete.recordId,
    };
  }

  FdcDataSetState resolveStateAfterApplyResult({
    required bool restoredImmediatePost,
    required bool completedImmediatePost,
    required FdcDataSetState currentState,
    required FdcDataSetState previousState,
  }) {
    final nextState = restoredImmediatePost
        ? currentState
        : completedImmediatePost
        ? FdcDataSetState.browse
        : previousState == FdcDataSetState.closed
        ? FdcDataSetState.browse
        : previousState;
    return nextState == FdcDataSetState.applyingUpdates
        ? FdcDataSetState.browse
        : nextState;
  }

  FdcDataSetState resolveStateAfterApplyException({
    required bool restoredImmediatePost,
    required FdcDataSetState currentState,
    required FdcDataSetState previousState,
  }) {
    final nextState = restoredImmediatePost
        ? currentState
        : previousState == FdcDataSetState.closed
        ? FdcDataSetState.browse
        : previousState;
    return nextState == FdcDataSetState.applyingUpdates
        ? FdcDataSetState.browse
        : nextState;
  }

  FdcDataApplyError mapApplyException(FdcChangeSet changes, Object error) {
    final delete = changes.deletes.isNotEmpty ? changes.deletes.first : null;
    if (delete != null) {
      return _mapAdapterApplyException(
        delete,
        error,
        FdcDataApplyOperation.delete,
      );
    }

    final update = changes.updates.isNotEmpty ? changes.updates.first : null;
    if (update != null) {
      return _mapAdapterApplyException(
        update,
        error,
        FdcDataApplyOperation.update,
      );
    }

    final insert = changes.inserts.isNotEmpty ? changes.inserts.first : null;
    if (insert != null) {
      return _mapAdapterApplyException(
        insert,
        error,
        FdcDataApplyOperation.insert,
      );
    }

    return FdcDataApplyError(
      recordId: -1,
      message: _exceptionMessage(error),
      code: 'adapter_error',
    );
  }

  FdcDataApplyError _mapAdapterApplyException(
    FdcChangeSetEntry entry,
    Object error,
    FdcDataApplyOperation operation,
  ) {
    if (error is FdcDataAdapterException) {
      return FdcDataApplyError(
        recordId: error.recordId ?? entry.recordId,
        message: error.message,
        fieldName: error.fieldName,
        code: error.code ?? 'adapter_error',
      );
    }

    try {
      final adapter = _readAdapter();
      if (adapter == null) {
        return FdcDataApplyError(
          recordId: entry.recordId,
          message: _exceptionMessage(error),
          code: 'local_apply_error',
        );
      }
      return adapter.mapApplyException(entry, error, operation: operation);
    } on Object catch (_) {
      final adapterError = fdcNormalizeAdapterException(
        error,
        operation: operation.name,
        recordId: entry.recordId,
      );
      return FdcDataApplyError(
        recordId: adapterError.recordId ?? entry.recordId,
        message: adapterError.message,
        fieldName: adapterError.fieldName,
        code: adapterError.code ?? 'adapter_error',
      );
    }
  }

  bool restoreImmediatePostAfterFailure({
    required FdcChangeSet changes,
    required FdcUpdateMode updateMode,
    required int? editRecordId,
    required int Function(int recordId) activeIndexForRecordId,
    required void Function(int index) setCurrentIndex,
    required void Function(FdcDataSetState state) setState,
  }) {
    final recordId = _pendingImmediatePostRecordId;
    final pendingState = _pendingImmediatePostState;
    if (updateMode != FdcUpdateMode.immediate ||
        recordId == null ||
        pendingState == null) {
      return false;
    }

    final attemptedPost =
        changes.inserts.any((entry) => entry.recordId == recordId) ||
        changes.updates.any((entry) => entry.recordId == recordId);
    if (!attemptedPost) {
      return false;
    }

    clearPendingImmediatePost();

    // Immediate apply completes asynchronously. A newer edit/insert buffer may
    // already be active, so only restore the failed record when the current
    // edit session still belongs to that record.
    if (editRecordId != recordId) {
      return false;
    }

    final index = activeIndexForRecordId(recordId);
    if (index >= 0) {
      setCurrentIndex(index);
    }
    setState(pendingState);
    return true;
  }

  bool completeImmediatePostIfApplied({
    required Set<int> appliedRecordIds,
    required FdcUpdateMode updateMode,
    required int? editRecordId,
    required void Function() clearEditBuffer,
    required void Function(FdcDataSetState state) setState,
  }) {
    final recordId = _pendingImmediatePostRecordId;
    if (updateMode != FdcUpdateMode.immediate ||
        recordId == null ||
        !appliedRecordIds.contains(recordId)) {
      return false;
    }

    clearPendingImmediatePost();

    // Do not force a newer edit/insert buffer back to browse when an older
    // immediate apply completes in the background.
    if (editRecordId != recordId) {
      return false;
    }

    clearEditBuffer();
    setState(FdcDataSetState.browse);
    return true;
  }

  void restoreImmediateDeletesAfterFailure({
    required FdcChangeSet changes,
    required FdcUpdateMode updateMode,
    required FdcRecord? Function(int recordId) recordById,
    required void Function(int? preserveRecordId) rebuildView,
    required int Function() readRecordCount,
    required int Function(int recordId) activeIndexForRecordId,
    required void Function(int index) setCurrentIndex,
    required void Function(bool value) setEof,
  }) {
    if (updateMode != FdcUpdateMode.immediate || changes.deletes.isEmpty) {
      return;
    }

    int? preserveRecordId;
    int? restoreOldIndex;
    var restoredAny = false;

    for (final delete in changes.deletes) {
      final recordId = delete.recordId;
      final record = recordById(recordId);
      final oldIndex = takePendingImmediateDeleteOldIndex(recordId);
      if (record == null || record.state != FdcRecordState.deleted) {
        continue;
      }

      record.state = FdcRecordState.unchanged;
      restoredAny = true;
      preserveRecordId ??= recordId;
      restoreOldIndex ??= oldIndex;
    }

    if (!restoredAny) {
      return;
    }

    rebuildView(preserveRecordId);
    final recordCount = readRecordCount();
    if (restoreOldIndex != null && recordCount > 0) {
      setCurrentIndex(restoreOldIndex.clamp(0, recordCount - 1).toInt());
    } else if (preserveRecordId != null) {
      setCurrentIndex(activeIndexForRecordId(preserveRecordId));
    }
    setEof(recordCount == 0);
  }

  void dispose() {
    _immediateApplyScheduled = false;
    _immediateApplyKickoffQueued = false;
    _applyUpdatesFuture = null;
    clearPendingImmediatePost();
    clearPendingImmediateDeletes();
  }

  void _queueImmediateApplyUpdatesRun() {
    if (_immediateApplyKickoffQueued || _immediateApplyRunning) {
      return;
    }

    _immediateApplyKickoffQueued = true;
    scheduleMicrotask(() {
      _immediateApplyKickoffQueued = false;
      if (_immediateApplyScheduled && _hasUpdates()) {
        unawaited(_runImmediateApplyUpdates());
      }
    });
  }

  Future<void> _runImmediateApplyUpdates() async {
    if (_immediateApplyRunning) {
      return;
    }

    _immediateApplyRunning = true;
    try {
      while (_immediateApplyScheduled) {
        _immediateApplyScheduled = false;
        final state = _readState();
        if (!_hasUpdates() ||
            state == FdcDataSetState.closed ||
            state == FdcDataSetState.loading ||
            state == FdcDataSetState.applyingUpdates) {
          continue;
        }

        try {
          await applyUpdates();
        } on Object catch (_) {
          // The dataset core already publishes dataset and work errors.
          // Immediate mode must not leak an unhandled asynchronous exception
          // from a synchronous post/delete call site.
        }
      }
    } finally {
      _immediateApplyRunning = false;
      if (_immediateApplyScheduled && _hasUpdates()) {
        _queueImmediateApplyUpdatesRun();
      }
    }
  }
}
