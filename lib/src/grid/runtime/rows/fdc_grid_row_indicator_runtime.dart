// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateRowIndicator on _FdcGridState {
  FdcGridRowIndicatorCellModel _buildRowIndicatorCellModel(
    BuildContext context,
    int rowIndex,
  ) {
    return FdcGridRowIndicatorCellModel(
      rowIndex: rowIndex,
      rowNumber: widget.dataSet.paging.pageOffset + rowIndex + 1,
      options: widget.rowIndicator.options,
      selected: _isRowIndicatorSelected(rowIndex),
      selectionEnabled: _isRowIndicatorSelectionEnabled(rowIndex),
      recordId: _rowIndicatorRecordId(rowIndex),
      status: _recordIndicatorStatus(rowIndex),
      textStyle: DefaultTextStyle.of(context).style,
      controlsStyle: _controlsStyle(context),
    );
  }

  bool _isRowIndicatorSelectionEnabled(int rowIndex) {
    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null) {
      return false;
    }

    if (!FdcDataSetInternal.hasActiveEdit(widget.dataSet)) {
      return true;
    }

    return FdcDataSetInternal.activeIndex(widget.dataSet) == sourceIndex;
  }

  bool _isRowIndicatorSelected(int rowIndex) {
    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null) {
      return false;
    }

    try {
      return FdcDataSetInternal.isRecordSelectedAt(widget.dataSet, sourceIndex);
      // ignore: avoid_catching_errors
    } on RangeError {
      return false;
    }
  }

  bool? _selectAllRowIndicatorValue() {
    final visibleCount = widget.dataSet.recordCount;
    if (visibleCount == 0) {
      return false;
    }

    final selectedCount = FdcDataSetInternal.visibleSelectedRecordCount(
      widget.dataSet,
    );
    if (selectedCount == 0) {
      return false;
    }
    if (selectedCount == visibleCount) {
      return true;
    }
    return null;
  }

  int? _rowIndicatorRecordId(int rowIndex) {
    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null) {
      return null;
    }

    try {
      return FdcDataSetInternal.recordIdAt(widget.dataSet, sourceIndex);
      // ignore: avoid_catching_errors
    } on RangeError {
      return null;
    }
  }

  FdcGridRowIndicatorStatus? _recordIndicatorStatus(int rowIndex) {
    if (!widget.rowIndicator.options.showRecordStatus) {
      return null;
    }

    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null ||
        sourceIndex < 0 ||
        sourceIndex >= widget.dataSet.recordCount) {
      return null;
    }

    final isDataSetCurrentRow =
        FdcDataSetInternal.activeIndex(widget.dataSet) == sourceIndex;
    if (!isDataSetCurrentRow) {
      return null;
    }

    // Dataset edit/insert state only applies to the dataset current record.
    // `modified` is intentionally the active edit-buffer dirty state, not the
    // posted FdcRecordState.modified change-tracking state. Posted records
    // return to browse mode in the row indicator until a future cached/batch
    // update visual explicitly asks for posted change markers.
    if (widget.dataSet.state == FdcDataSetState.insert) {
      return FdcGridRowIndicatorStatus.insert;
    }
    if (widget.dataSet.state == FdcDataSetState.edit) {
      return FdcDataSetInternal.isActiveEditBufferModified(widget.dataSet)
          ? FdcGridRowIndicatorStatus.modified
          : FdcGridRowIndicatorStatus.edit;
    }
    return FdcGridRowIndicatorStatus.browse;
  }

  void _activateRowIndicatorRow(int rowIndex) {
    _cancelDirectSelectionGuard();
    _activateVisibleRecordScrollRow(
      rowIndex,
      focusReason: FdcGridFocusChangeReason.rowIndicator,
    );
  }

  void _activateRowIndicatorSelectionRow(int rowIndex) {
    _cancelDirectSelectionGuard();
    if (!_postCurrentRowIfLeaving(rowIndex)) {
      return;
    }
    if (!_syncDataSetCurrentRow(rowIndex)) {
      return;
    }
    _setGridState(() {
      _selectedRowIndex = rowIndex;
      _selectedCell = null;
      _editingCell = null;
      _editAtEndCell = null;
      _clearPendingEditText();
      _clearEditingOriginalValue();
    }, focusReason: FdcGridFocusChangeReason.rowIndicator);
  }

  void _setRowIndicatorSelected(int rowIndex, bool selected) {
    final initialSourceIndex = _sourceRowIndex(rowIndex);
    if (initialSourceIndex == null) {
      return;
    }

    final horizontalOffsetToPreserve = _scrollCoordinator.liveHorizontalOffset;
    var horizontalOffsetRestoreLocked = false;

    void lockHorizontalOffset() {
      if (horizontalOffsetRestoreLocked) {
        return;
      }
      _scrollCoordinator.beginHorizontalOffsetRestore(
        horizontalOffsetToPreserve,
      );
      horizontalOffsetRestoreLocked = true;
    }

    try {
      final recordId = FdcDataSetInternal.recordIdAt(
        widget.dataSet,
        initialSourceIndex,
      );
      final activeIndex = FdcDataSetInternal.activeIndex(widget.dataSet);
      final isSameRecord = activeIndex == initialSourceIndex;

      var targetSourceIndex = initialSourceIndex;
      if (!isSameRecord &&
          (widget.dataSet.state == FdcDataSetState.edit ||
              widget.dataSet.state == FdcDataSetState.insert)) {
        lockHorizontalOffset();
        if (_activeCellEditorState?.finalizeEditing() == false) {
          return;
        }
        if (!_postCurrentRowIfLeaving(rowIndex)) {
          return;
        }

        targetSourceIndex = FdcDataSetInternal.activeIndexForRecordId(
          widget.dataSet,
          recordId,
        );
        if (targetSourceIndex < 0) {
          return;
        }
      }

      lockHorizontalOffset();
      _blurGrid();

      _setGridState(() {
        FdcDataSetInternal.setRecordSelectedAt(
          widget.dataSet,
          targetSourceIndex,
          selected,
        );
      });
    } finally {
      if (horizontalOffsetRestoreLocked) {
        _preserveHorizontalOffsetAfterLayout(
          horizontalOffsetToPreserve,
          horizontalOffsetRestoreAlreadyLocked: true,
        );
      }
    }
  }

  void _setAllRowIndicatorRowsSelected(bool selected) {
    final horizontalOffsetToPreserve = _scrollCoordinator.liveHorizontalOffset;
    _scrollCoordinator.beginHorizontalOffsetRestore(horizontalOffsetToPreserve);

    try {
      _setGridState(() {
        FdcDataSetInternal.setAllVisibleRecordsSelected(
          widget.dataSet,
          selected,
        );
      });
    } finally {
      _preserveHorizontalOffsetAfterLayout(
        horizontalOffsetToPreserve,
        horizontalOffsetRestoreAlreadyLocked: true,
      );
    }
  }
}
