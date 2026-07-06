// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcDatasetLifecycleRuntime on _FdcGridState {
  void _handleDataSetError(
    FdcDataSet dataSet,
    List<FdcDataSetError> errors,
    Object? cause,
  ) {
    if (!mounted || dataSet != widget.dataSet || errors.isEmpty) {
      return;
    }

    _clearPendingAppend();
    _clearPendingCellMove();

    // Field validation errors are already surfaced inline/through dataset
    // validation callbacks and must stay non-modal for normal grid editing.
    // Backend/apply errors, such as SQLite constraint failures, are operation
    // failures and should be shown by the grid even when they arrive from the
    // asynchronous immediate-apply pipeline.
    if (!_hasGridOperationErrorForDialog(errors, cause: cause)) {
      return;
    }

    _showGridOperationErrorsIfNeeded(focusActiveEditorAfterDialog: true);
  }

  bool _hasGridOperationErrorForDialog(
    List<FdcDataSetError> errors, {
    Object? cause,
  }) {
    if (cause != null) {
      return true;
    }

    for (final error in errors) {
      if (!_isFieldValidationErrorCode(error.code)) {
        return true;
      }
    }
    return false;
  }

  bool _isFieldValidationErrorCode(String? code) {
    return code == FdcValidationCodes.requiredField ||
        code == FdcValidationCodes.minValue ||
        code == FdcValidationCodes.maxValue ||
        code == FdcValidationCodes.nonFiniteNumber;
  }

  void _clearPendingAppend() {
    _pendingAppendAfterImmediatePost = false;
    _pendingAppendUsesTabOrder = false;
  }

  void _clearPendingCellMove() {
    _pendingCellMoveAfterImmediatePost = null;
    _pendingCellMoveEditIfPossible = false;
    _preferLeadingColumnForPendingMove = false;
    _pendingCellMoveFocusReason = FdcGridFocusChangeReason.keyboard;
    _suppressRevealForPendingMove = false;
    _ui.data.operation.pendingCellMoveHasValueWrite = false;
    _ui.data.operation.pendingCellMoveValueWrite = null;
  }

  void _setPendingCellMove(
    FdcGridCellRef cell, {
    bool editIfPossible = false,
    bool preferLeadingColumnContext = false,
    FdcGridFocusChangeReason focusReason = FdcGridFocusChangeReason.keyboard,
    bool suppressColumnReveal = false,
  }) {
    _ui.data.operation.pendingCellMoveHasValueWrite = false;
    _ui.data.operation.pendingCellMoveValueWrite = null;
    _pendingCellMoveAfterImmediatePost = _enrichCellRef(cell) ?? cell;
    _pendingCellMoveEditIfPossible = editIfPossible;
    _preferLeadingColumnForPendingMove = preferLeadingColumnContext;
    _pendingCellMoveFocusReason = focusReason;
    _suppressRevealForPendingMove = suppressColumnReveal;
  }

  void _setPendingCellWrite(Object? value) {
    if (_pendingCellMoveAfterImmediatePost == null) {
      return;
    }
    _ui.data.operation.pendingCellMoveHasValueWrite = true;
    _ui.data.operation.pendingCellMoveValueWrite = value;
  }

  void _continuePendingCellMoveIfReady() {
    final pendingCell = _pendingCellMoveAfterImmediatePost;
    if (pendingCell == null || !mounted) {
      return;
    }

    if (widget.dataSet.state != FdcDataSetState.browse ||
        widget.dataSet.errors.messages.isNotEmpty) {
      return;
    }

    final cell = _enrichCellRef(pendingCell);
    final editIfPossible = _pendingCellMoveEditIfPossible;
    final preferLeadingColumnContext = _preferLeadingColumnForPendingMove;
    final focusReason = _pendingCellMoveFocusReason;
    final suppressColumnReveal = _suppressRevealForPendingMove;
    final hasValueWrite = _ui.data.operation.pendingCellMoveHasValueWrite;
    final valueWrite = _ui.data.operation.pendingCellMoveValueWrite;
    _clearPendingCellMove();

    if (cell == null || !_isLiveGridRowIndex(cell.rowIndex)) {
      _refreshRowsAndValidateState();
      return;
    }

    final endScrollGuard = _beginKeyboardMoveGuard(
      suppressColumnReveal: suppressColumnReveal,
    );
    try {
      _scrollRowIntoView(cell.rowIndex);
      _activateCell(
        cell,
        editIfPossible: editIfPossible,
        preferLeadingColumnContext: preferLeadingColumnContext,
        revealColumn: !suppressColumnReveal,
        revealColumnOnlyIfOutside: !suppressColumnReveal,
        focusReason: focusReason,
      );
      if (hasValueWrite &&
          cell.columnIndex >= 0 &&
          cell.columnIndex < _visibleColumns.length) {
        _updateCell(
          cell.rowIndex,
          _visibleColumns[cell.columnIndex],
          valueWrite,
        );
      }
    } finally {
      endScrollGuard();
    }
  }

  void _continuePendingAppendIfReady() {
    if (!_pendingAppendAfterImmediatePost || !mounted) {
      return;
    }

    if (widget.dataSet.state != FdcDataSetState.browse ||
        widget.dataSet.errors.messages.isNotEmpty) {
      return;
    }

    final useTabOrder = _pendingAppendUsesTabOrder;
    _clearPendingAppend();
    _appendEmptyRowAndFocusFirstField(useTabOrder: useTabOrder);
  }

  void _handleDataSetFilterChanged(FdcDataSetFilterChange change) {
    if (!mounted || !change.clearHeaderFilters || _updatingDataSetFromGrid) {
      return;
    }

    if (!_hasHeaderFilterState) {
      return;
    }

    _applyGridState(_clearHeaderFilterUiState);
  }

  void _syncHeaderSortFromDataSet() {
    if (!widget.options.allowColumnSorting ||
        widget.dataSet.sort.items.isEmpty) {
      _sort.clear();
      return;
    }

    final items = <FdcGridSortItem>[];
    final usedRuntimeColumnIds = <FdcColumnIdentity>{};
    for (final sort in widget.dataSet.sort.items) {
      final normalizedFieldName = FdcFieldName.normalize(sort.fieldName);
      for (
        var columnIndex = 0;
        columnIndex < _visibleColumns.length;
        columnIndex++
      ) {
        final column = _visibleColumns[columnIndex];
        if (!column.allowSort ||
            FdcFieldName.normalize(column.fieldName) != normalizedFieldName) {
          continue;
        }

        final runtimeColumnId = _runtimeColumnIdAt(columnIndex);
        if (runtimeColumnId == null ||
            usedRuntimeColumnIds.contains(runtimeColumnId)) {
          continue;
        }

        usedRuntimeColumnIds.add(runtimeColumnId);
        items.add(
          FdcGridSortItem(
            runtimeColumnId: runtimeColumnId,
            ascending: sort.sortType.isAscending,
          ),
        );
        break;
      }
    }

    if (items.isEmpty) {
      _sort.clear();
      return;
    }
    _sort.setAll(items);
  }

  void _clearViewStateAfterDataSetClose() {
    _sort.clear();
    _cancelHeaderFilterDebounce();
    _headerFilterValues.clear();
    _headerFilterOperators.clear();
    _rowSelectionFilter = null;
    _lastAppliedHeaderFilterSignature = _headerFilterSignature();
    _headerFilterResetGeneration++;
    _toolbarSearchGeneration++;
    _clearFieldMetadataCache();
    _clearStaleInteractionState();
    _clearSummaryAggregateCache(clearDisplayedValues: true);
    _clearDetailRowState();
  }

  void _handleDataSetWorkChanged() {
    if (!mounted || widget.dataSet.work.isWorking) {
      return;
    }
    if (!_showsSummaryRow || !_summaryAggregateLoadDeferred) {
      return;
    }

    // Adapter-backed paged summary aggregates are intentionally deferred while
    // the dataset is loading/filtering. The dataset row notification is emitted
    // before the reported work lifecycle has fully completed, so listen for the
    // work-idle transition and repaint once to start aggregate loading after
    // the new page is visible.
    _applyGridState(() {
      _summaryAggregateLoadDeferred = false;
    });
  }

  void _handleDataSetClosed() {
    _runtime.domains.toolbar.searchController.clearSilently();
    _applyGridState(() {
      _resetRangeSelectionState(rebuild: false);
      _rowIndicatorWidthAnchorRowCount = null;
      _holdRowIndicatorWidthUntilCountRestores = false;
      _clearViewStateAfterDataSetClose();
      _rows = _rowsFromDataSet();
      _refreshRowsFromDataSet();
      _validateCellState();
      _syncInteractionState();
    });
    _resetVerticalScrollToTopAfterLayout(
      reason: 'dataset-closed-clear-managed-view-state',
    );
  }

  void _handleDataSetChanged() {
    if (!mounted) {
      return;
    }

    final previousState = _lastObservedDataSetState;
    final previousRecordCount = _lastObservedDataSetRecordCount;
    final currentState = widget.dataSet.state;
    final currentRecordCount = widget.dataSet.recordCount;
    _lastObservedDataSetState = currentState;
    _lastObservedDataSetRecordCount = currentRecordCount;

    if (_updatingDataSetFromGrid) {
      return;
    }

    final apiInsertOrAppendStarted =
        currentState == FdcDataSetState.insert &&
        previousState != FdcDataSetState.insert &&
        currentRecordCount > previousRecordCount;

    if (!widget.dataSet.isOpen) {
      _handleDataSetClosed();
      return;
    }

    _clearSummaryCacheIfQueryChanged();

    if (apiInsertOrAppendStarted) {
      // API-driven insert/append bypasses the grid command path. Collapse detail
      // rows synchronously and without animation before rebuilding the row
      // model so new-record positioning always uses fixed row geometry.
      _collapseAllDetailRowsImmediately();
    }

    _applyGridState(() {
      _resetRangeSelectionState(rebuild: false);

      _syncHeaderSortFromDataSet();

      // A dataset notification means the underlying rows changed, not that the
      // user explicitly requested a new filter/sort pass. Keep the current
      // dataset view snapshot intact so an edited or newly inserted visible row
      // is not ejected just because it no longer matches the active header
      // filter. Explicit filter changes still call _refreshRowsFromSource() with
      // retained rows cleared. Sorting only changes order and keeps retained
      // visible rows intact.
      _rows = _rowsFromDataSet();
      _refreshRowsFromDataSet();

      // If the dataset was changed from outside the grid and it is no longer in
      // edit/insert state, any active grid editor is now stale. This happens
      // especially when an unposted append/insert row is canceled through
      // DataSet.cancel()/delete(). Keeping the editor alive lets a later focus
      // loss try to commit/validate text for a record that no longer exists.
      final dataSetIsEditing =
          widget.dataSet.state == FdcDataSetState.edit ||
          widget.dataSet.state == FdcDataSetState.insert;
      if (!dataSetIsEditing) {
        _editingCell = null;
        _editAtEndCell = null;
        _clearPendingEditText();
        _clearEditingOriginalValue();
      }

      _validateCellState();
      final restoredDeleteSelection = _restorePendingDeleteSelection(
        clear: widget.dataSet.state != FdcDataSetState.applyingUpdates,
      );
      if (!restoredDeleteSelection) {
        if (apiInsertOrAppendStarted) {
          _syncGridSelectionFromDataSetCurrent(preferEditableColumn: true);
        } else {
          final cellFocusVisible = _cellFocusVisible;
          _syncGridSelectionFromDataSetCurrent(
            scrollColumnIntoView: cellFocusVisible,
            syncCell: cellFocusVisible || _editingCell != null,
          );
        }
      }
      _syncInteractionState();
    });

    if (apiInsertOrAppendStarted) {
      final rowIndex = FdcDataSetInternal.activeIndex(widget.dataSet);
      if (_isLiveGridRowIndex(rowIndex)) {
        _focusNewRecordRowField(rowIndex);
      }
    }

    _continuePendingCellMoveIfReady();
    _continuePendingAppendIfReady();

    // Do not present validation dialogs from passive dataset notifications.
    // The control that initiated the failing action owns the UX response.
    // This prevents a grid bound to the same dataset from showing dialogs for
    // validation errors caused by standalone editors or other external controls.
  }
}
