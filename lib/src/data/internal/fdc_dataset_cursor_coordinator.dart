// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

/// Internal owner of dataset cursor position and navigation orchestration.
///
/// The dataset remains the public facade and owns records, view storage,
/// edit-state resolution, scroll callbacks, operation error handling, and
/// listener notification. This coordinator owns only cursor state and the
/// behavior-neutral movement rules around that state.
final class FdcDataSetCursorCoordinator {
  FdcDataSetCursorCoordinator({
    required void Function() ensureOpen,
    required int Function() readRecordCount,
    required Object Function() readViewIndexes,
    required bool Function() resolveActiveEdit,
    required int? Function() readCurrentRecordId,
    required void Function({
      required String operation,
      required int? recordId,
      required void Function() body,
    })
    runOperation,
    required void Function(int previousRecordNumber, int targetRecordNumber)
    beforeScroll,
    required void Function(int previousRecordNumber, int currentRecordNumber)
    afterScroll,
    required void Function() notifyListeners,
  }) : _ensureOpen = ensureOpen,
       _readRecordCount = readRecordCount,
       _readViewIndexes = readViewIndexes,
       _resolveActiveEdit = resolveActiveEdit,
       _readCurrentRecordId = readCurrentRecordId,
       _runOperation = runOperation,
       _beforeScroll = beforeScroll,
       _afterScroll = afterScroll,
       _notifyListeners = notifyListeners;

  final void Function() _ensureOpen;
  final int Function() _readRecordCount;
  final Object Function() _readViewIndexes;
  final bool Function() _resolveActiveEdit;
  final int? Function() _readCurrentRecordId;
  final void Function({
    required String operation,
    required int? recordId,
    required void Function() body,
  })
  _runOperation;
  final void Function(int previousRecordNumber, int targetRecordNumber)
  _beforeScroll;
  final void Function(int previousRecordNumber, int currentRecordNumber)
  _afterScroll;
  final void Function() _notifyListeners;

  int currentIndex = -1;
  bool eof = true;

  bool get bof => _readRecordCount() == 0 || currentIndex <= 0;

  int get recordNumber {
    if (_readRecordCount() == 0 || currentIndex < 0) {
      return -1;
    }
    return currentIndex + 1;
  }

  bool get isAtFirst => _readRecordCount() == 0
      ? currentIndex == -1 && eof
      : currentIndex == 0 && !eof;

  void first() {
    moveToPosition(_readRecordCount() == 0 ? -1 : 0);
  }

  void prior() {
    _ensureOpen();
    if (_readRecordCount() == 0) {
      eof = true;
      return;
    }
    moveToPosition(currentIndex <= 0 ? 0 : currentIndex - 1);
  }

  void next() {
    _ensureOpen();
    final recordCount = _readRecordCount();
    if (recordCount == 0) {
      eof = true;
      return;
    }
    if (currentIndex < recordCount - 1) {
      moveToPosition(currentIndex + 1);
      return;
    }
    moveToPosition(recordCount - 1, markEof: true);
  }

  void last() {
    final recordCount = _readRecordCount();
    moveToPosition(recordCount == 0 ? -1 : recordCount - 1, markEof: true);
  }

  void moveToRecord(int recordNumber) {
    _ensureOpen();
    final recordCount = _readRecordCount();
    if (recordCount == 0) {
      throw StateError('Dataset has no records.');
    }
    if (recordNumber < 1 || recordNumber > recordCount) {
      throw RangeError.range(recordNumber, 1, recordCount, 'recordNumber');
    }
    moveToPosition(recordNumber - 1, markEof: recordNumber == recordCount);
  }

  void moveToIndex(int index) {
    _ensureOpen();
    final recordCount = _readRecordCount();
    if (recordCount == 0) {
      throw StateError('Dataset has no records.');
    }
    if (index < 0 || index >= recordCount) {
      throw RangeError.index(index, _readViewIndexes(), 'index');
    }
    moveToPosition(index);
  }

  int recordNumberForIndex(int index) {
    if (index < 0 || index >= _readRecordCount()) {
      return -1;
    }
    return index + 1;
  }

  void moveToPosition(int targetIndex, {bool markEof = false}) {
    _ensureOpen();
    if (!_resolveActiveEdit()) {
      return;
    }

    final recordCount = _readRecordCount();
    final int normalizedTargetIndex;
    if (recordCount == 0) {
      normalizedTargetIndex = -1;
    } else {
      if (targetIndex < 0 || targetIndex >= recordCount) {
        throw RangeError.index(targetIndex, _readViewIndexes(), 'targetIndex');
      }
      normalizedTargetIndex = targetIndex;
    }

    final normalizedEof = recordCount == 0 || markEof;
    if (normalizedTargetIndex == currentIndex && normalizedEof == eof) {
      _notifyListeners();
      return;
    }

    final previousIndex = currentIndex;
    final previousRecordNumber = recordNumberForIndex(previousIndex);
    final targetRecordNumber = recordNumberForIndex(normalizedTargetIndex);

    _runOperation(
      operation: 'moveToRecord',
      recordId: _readCurrentRecordId(),
      body: () {
        _beforeScroll(previousRecordNumber, targetRecordNumber);
        currentIndex = normalizedTargetIndex;
        eof = normalizedEof;
        _afterScroll(previousRecordNumber, recordNumberForIndex(currentIndex));
        _notifyListeners();
      },
    );
  }

  void normalize(int normalizedIndex) {
    currentIndex = normalizedIndex;
    eof = _readRecordCount() == 0;
  }

  void reset() {
    currentIndex = -1;
    eof = true;
  }
}
