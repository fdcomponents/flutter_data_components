// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridDatasetEventRuntime on _FdcGridState {
  void _refreshRowsFromDataSet({bool updateColumnWidths = true}) {
    _rows = _rowsFromDataSet();
    _invalidateDetailRowIndices();
    if (updateColumnWidths) {
      _markColumnWidthsDirty();
    }
    _clampVerticalScrollOffsetAfterLayout();
    _scheduleAccumulatedPageFillCheck();
  }

  bool _isLiveDataSetRowIndex(int rowIndex) {
    return rowIndex >= 0 && rowIndex < widget.dataSet.recordCount;
  }

  bool _isLiveGridRowIndex(int rowIndex) {
    return rowIndex >= 0 &&
        rowIndex < _rows.length &&
        _isLiveDataSetRowIndex(rowIndex);
  }

  bool _isEmptyInsertGridRowIndex(int rowIndex) {
    return _shouldShowEmptyInsertRow && rowIndex == 0 && _rows.length == 1;
  }

  void _clearStaleInteractionState() {
    _selectedRowIndex = null;
    _selectedCell = null;
    _editingCell = null;
    _editAtEndCell = null;
    _clearPendingEditText();
    _clearEditingOriginalValue();
  }

  void _refreshRowsAndValidateState() {
    _refreshRowsFromDataSet();
    _validateCellState();
  }

  bool _syncDataSetCurrentRow(int rowIndex) {
    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null) {
      return false;
    }

    if (FdcDataSetInternal.activeIndex(widget.dataSet) == sourceIndex) {
      return true;
    }

    _updatingDataSetFromGrid = true;
    try {
      FdcDataSetInternal.moveToIndex(widget.dataSet, sourceIndex);
    } on Object catch (error, stackTrace) {
      unawaited(
        _handleDataSetPostError(
          error,
          stackTrace,
          focusActiveEditorAfterDialog: true,
        ),
      );
      return false;
    } finally {
      _updatingDataSetFromGrid = false;
    }

    if (FdcDataSetInternal.activeIndex(widget.dataSet) != sourceIndex) {
      _syncInteractionState();
      _showGridOperationErrorsIfNeeded(focusActiveEditorAfterDialog: true);
      return false;
    }

    _collapseDetailRowsForCurrentRowChange(rowIndex);

    if (widget.dataSet.state == FdcDataSetState.edit ||
        widget.dataSet.state == FdcDataSetState.insert) {
      _restoreCellAfterFailedRowPost(
        FdcDataSetInternal.activeIndex(widget.dataSet),
      );
      if (widget.dataSet.errors.messages.isNotEmpty) {
        _showGridOperationErrorsIfNeeded(focusActiveEditorAfterDialog: true);
        return false;
      }
    }

    return true;
  }

  void _rememberDeleteSelectionRestore() {
    final cell = _selectedCell;
    if (cell == null) {
      _pendingDeleteRestoreRowIndex = _selectedRowIndex;
      _pendingDeleteRestoreColumnIndex = null;
      return;
    }

    _pendingDeleteRestoreRowIndex = cell.rowIndex;
    _pendingDeleteRestoreColumnIndex = cell.columnIndex;
  }

  bool _restorePendingDeleteSelection({required bool clear}) {
    final rowIndex = _pendingDeleteRestoreRowIndex;
    if (rowIndex == null) {
      return false;
    }

    // The dataset current row is the source of truth after the delete/apply
    // lifecycle. The pending delete row only says that a delete selection
    // restore is in progress; do not use it as a second independent current
    // row or the row indicator can show both the dataset-current marker and a
    // stale grid-selected marker.
    _syncGridSelectionFromDataSetCurrent(
      preferredColumnIndex: _pendingDeleteRestoreColumnIndex,
    );

    if (clear) {
      _pendingDeleteRestoreRowIndex = null;
      _pendingDeleteRestoreColumnIndex = null;
    }
    return true;
  }

  void _syncGridSelectionFromDataSetCurrent({
    bool scrollRowIntoView = true,
    bool scrollColumnIntoView = true,
    bool syncCell = true,
    bool preferEditableColumn = false,
    int? preferredColumnIndex,
  }) {
    final rowIndex = FdcDataSetInternal.activeIndex(widget.dataSet);
    if (!_isLiveGridRowIndex(rowIndex)) {
      _clearStaleInteractionState();
      return;
    }

    _collapseDetailRowsForCurrentRowChange(rowIndex);

    final columns = _visibleColumns;
    if (!syncCell) {
      _selectedRowIndex = rowIndex;
      _selectedCell = null;
      _editingCell = null;
      _editAtEndCell = null;
      _clearPendingEditText();
      _clearEditingOriginalValue();
      if (scrollRowIntoView) {
        _scrollRowIntoViewAfterLayout(rowIndex);
      }
      return;
    }

    if (columns.isEmpty) {
      _selectedRowIndex = rowIndex;
      _selectedCell = null;
      _editingCell = null;
      _editAtEndCell = null;
      _clearPendingEditText();
      _clearEditingOriginalValue();
      return;
    }

    var columnIndex = preferredColumnIndex ?? _selectedCell?.columnIndex ?? 0;
    if (columnIndex < 0 || columnIndex >= columns.length) {
      columnIndex = preferEditableColumn
          ? _firstEditableColumnIndexForRow(rowIndex)
          : 0;
    } else if (preferEditableColumn &&
        !_isCellEditable(columns[columnIndex], rowIndex)) {
      columnIndex = _firstEditableColumnIndexForRow(rowIndex);
    }

    if (columnIndex < 0) {
      _selectedRowIndex = rowIndex;
      _selectedCell = null;
      _editingCell = null;
      _editAtEndCell = null;
      _clearPendingEditText();
      _clearEditingOriginalValue();
      return;
    }

    final next = _cellRef(rowIndex, columnIndex);
    _selectedRowIndex = rowIndex;
    _selectedCell = next;
    _editingCell = null;
    _editAtEndCell = null;
    _clearPendingEditText();
    _clearEditingOriginalValue();
    if (scrollRowIntoView) {
      _scrollRowIntoViewAfterLayout(rowIndex);
    }
    if (scrollColumnIntoView) {
      _scrollColumnIntoViewAfterLayout(columnIndex);
    }
  }

  void _refreshRowsFromSource({
    bool clearRetainedVisibleRecords = true,
    bool notifyDataSet = true,
    bool applyFilters = true,
    bool updateColumnWidths = true,
  }) {
    _invalidateDetailRowIndices();
    if (widget.dataSet.paging.enabled) {
      unawaited(
        _refreshRowsFromSourceAsync(
          clearRetainedVisibleRecords: clearRetainedVisibleRecords,
          notifyDataSet: notifyDataSet,
          applyFilters: applyFilters,
          updateColumnWidths: updateColumnWidths,
        ),
      );
      return;
    }

    _applyDataSetViewState(
      clearRetainedVisibleRecords: clearRetainedVisibleRecords,
      notifyDataSet: notifyDataSet,
      applyFilters: applyFilters,
    );
    _refreshRowsFromDataSet(updateColumnWidths: updateColumnWidths);
  }

  Future<void> _refreshRowsFromSourceAsync({
    bool clearRetainedVisibleRecords = true,
    bool notifyDataSet = true,
    bool applyFilters = true,
    bool updateColumnWidths = true,
  }) async {
    final applyWatch = Stopwatch()..start();
    final applied = await _applyDataSetViewStateAsync(
      clearRetainedVisibleRecords: clearRetainedVisibleRecords,
      notifyDataSet: notifyDataSet,
      applyFilters: applyFilters,
    );
    applyWatch.stop();
    if (!applied || !mounted) {
      return;
    }

    final refreshWatch = Stopwatch()..start();
    _setGridState(() {
      _refreshRowsFromDataSet(updateColumnWidths: updateColumnWidths);
    });
    refreshWatch.stop();
  }

  void _applyDataSetViewState({
    bool clearRetainedVisibleRecords = true,
    bool notifyDataSet = true,
    bool applyFilters = true,
  }) {
    if (!widget.dataSet.isOpen) {
      return;
    }

    final filters = applyFilters ? _resolvedHeaderDataSetFilters() : null;
    final sorts = _sort.hasSort ? _effectiveDataSetSorts() : null;

    _updatingDataSetFromGrid = true;
    try {
      if (filters != null) {
        final filtersApplied = FdcDataSetInternal.applyInternalFilter(
          widget.dataSet,
          filters,
          context: FdcDataSetFilterContext(
            formatSettings: _formatSettings,
            selected: _rowSelectionFilter,
          ),
          clearRetainedVisibleRecords: clearRetainedVisibleRecords,
          notify: false,
        );
        if (!filtersApplied) {
          return;
        }
      }

      if (sorts != null) {
        FdcDataSetInternal.setViewState(
          widget.dataSet,
          sorts: sorts,
          clearRetainedVisibleRecords: applyFilters
              ? false
              : clearRetainedVisibleRecords,
          notify: notifyDataSet,
        );
      } else if (filters != null) {
        FdcDataSetInternal.setViewState(
          widget.dataSet,
          clearRetainedVisibleRecords: false,
          notify: notifyDataSet,
        );
      } else if (clearRetainedVisibleRecords) {
        FdcDataSetInternal.setViewState(
          widget.dataSet,
          clearRetainedVisibleRecords: true,
          notify: notifyDataSet,
        );
      }
    } finally {
      _updatingDataSetFromGrid = false;
    }
  }

  Future<bool> _applyDataSetViewStateAsync({
    bool clearRetainedVisibleRecords = true,
    bool notifyDataSet = true,
    bool applyFilters = true,
  }) async {
    if (!widget.dataSet.isOpen) {
      return false;
    }

    final filters = applyFilters ? _resolvedHeaderDataSetFilters() : null;
    final sorts = _sort.hasSort ? _effectiveDataSetSorts() : null;

    _updatingDataSetFromGrid = true;
    try {
      if (filters != null) {
        final filtersApplied =
            await FdcDataSetInternal.applyInternalFilterQuery(
              widget.dataSet,
              filters,
              context: FdcDataSetFilterContext(
                formatSettings: _formatSettings,
                selected: _rowSelectionFilter,
              ),
              clearRetainedVisibleRecords: clearRetainedVisibleRecords,
              notify: sorts == null && notifyDataSet,
            );
        if (!filtersApplied) {
          return false;
        }
      }

      if (sorts != null) {
        await widget.dataSet.sort.set(sorts, notify: notifyDataSet);
      } else if (clearRetainedVisibleRecords && filters == null) {
        FdcDataSetInternal.setViewState(
          widget.dataSet,
          clearRetainedVisibleRecords: true,
          notify: notifyDataSet,
        );
      }
      return true;
    } finally {
      _updatingDataSetFromGrid = false;
    }
  }
}
