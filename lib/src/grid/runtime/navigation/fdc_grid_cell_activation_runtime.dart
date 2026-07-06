// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateCellActivationRuntime on _FdcGridState {
  void _rememberEditingOriginalValue(
    FdcGridCellRef cell,
    FdcGridColumn<dynamic> column,
  ) {
    if (_hasEditingOriginalValue && _editingOriginalCell == cell) {
      return;
    }
    _editingOriginalCell = cell;
    _editingOriginalValue = _dataSetValueAt(cell.rowIndex, column);
    _hasEditingOriginalValue = true;
  }

  void _clearEditingOriginalValue() {
    _editingOriginalCell = null;
    _editingOriginalValue = null;
    _hasEditingOriginalValue = false;
  }

  Object? _originalValueForEditingCell(FdcGridCellRef cell, Object? fallback) {
    if (_hasEditingOriginalValue && _editingOriginalCell == cell) {
      return _editingOriginalValue;
    }
    return fallback;
  }

  void _activateCell(
    FdcGridCellRef requestedCell, {
    required bool editIfPossible,
    bool placeCursorAtEnd = false,
    bool preferLeadingColumnContext = false,
    bool revealColumn = true,
    bool revealColumnOnlyIfOutside = false,
    FdcGridFocusChangeReason focusReason =
        FdcGridFocusChangeReason.programmatic,
  }) {
    final columns = _visibleColumns;
    if (requestedCell.rowIndex < 0 ||
        requestedCell.rowIndex >= _rows.length ||
        requestedCell.columnIndex < 0 ||
        requestedCell.columnIndex >= columns.length) {
      return;
    }

    final editingCellBeforeActivation = _editingCell;
    var targetCell = requestedCell;
    var cell = _cellRef(targetCell.rowIndex, targetCell.columnIndex);
    var column = columns[cell.columnIndex];
    final requestedPlaceholderEdit =
        editIfPossible &&
        _isEmptyInsertGridRowIndex(cell.rowIndex) &&
        _isCellEditable(column, cell.rowIndex);

    if (requestedPlaceholderEdit) {
      final appendedRowIndex = _appendDataSetRow();
      if (appendedRowIndex < 0 || appendedRowIndex >= _rows.length) {
        return;
      }
      targetCell = FdcGridCellRef(
        appendedRowIndex,
        requestedCell.columnIndex,
        runtimeColumnId: requestedCell.runtimeColumnId,
      );
      cell = _cellRef(targetCell.rowIndex, targetCell.columnIndex);
      column = columns[cell.columnIndex];
    } else if (_isEmptyInsertGridRowIndex(cell.rowIndex)) {
      _setGridState(() {
        _selectedRowIndex = cell.rowIndex;
        _selectedCell = cell;
        _editingCell = null;
        _editAtEndCell = null;
        _clearPendingEditText();
        _clearEditingOriginalValue();
      }, focusReason: focusReason);
      if (_shouldRevealColumnForActivation(revealColumn)) {
        if (revealColumnOnlyIfOutside) {
          _scrollColumnIntoViewIfOutside(
            cell.columnIndex,
            preferLeadingContext: preferLeadingColumnContext,
          );
        } else {
          _scrollColumnIntoView(
            cell.columnIndex,
            preferLeadingContext: preferLeadingColumnContext,
          );
        }
      }
      _focusGridForSelectedCell();
      return;
    }

    if (!_syncDataSetCurrentRow(targetCell.rowIndex)) {
      return;
    }
    final requestedEdit =
        editIfPossible && _isCellEditable(column, cell.rowIndex);
    final canEdit =
        requestedEdit &&
        _ensureDataSetEditForCell(
          cell.rowIndex,
          column,
          focusActiveEditorAfterDialog: true,
        );
    final usesDisplayEditor = canEdit && _usesDisplayCellInEdit(column);
    _setGridState(() {
      _selectedRowIndex = cell.rowIndex;
      _selectedCell = cell;
      _clearPendingEditText();
      if (canEdit) {
        _rememberEditingOriginalValue(cell, column);
      } else {
        _clearEditingOriginalValue();
      }
      _editingCell = canEdit ? cell : null;
      _editAtEndCell = canEdit && placeCursorAtEnd ? cell : null;
    }, focusReason: focusReason);
    if (_shouldRevealColumnForActivation(revealColumn)) {
      if (revealColumnOnlyIfOutside) {
        _scrollColumnIntoViewIfOutside(
          cell.columnIndex,
          preferLeadingContext: preferLeadingColumnContext,
        );
      } else {
        _scrollColumnIntoView(
          cell.columnIndex,
          preferLeadingContext: preferLeadingColumnContext,
        );
      }
    } else {
      _deferColumnRevealIfSuppressed(
        editingCellBeforeActivation: editingCellBeforeActivation,
        targetCell: cell,
        revealColumn: revealColumn,
        revealColumnOnlyIfOutside: revealColumnOnlyIfOutside,
        preferLeadingContext: preferLeadingColumnContext,
      );
    }

    if (canEdit && !usesDisplayEditor) {
      if (placeCursorAtEnd) {
        _focusActiveEditorAtEndAfterLayout();
      } else {
        _focusActiveEditorAfterLayout();
      }
      return;
    }

    _focusGridForSelectedCell();
  }

  bool _shouldRevealColumnForActivation(bool revealColumn) {
    return revealColumn && !_suppressKeyboardColumnReveal;
  }

  void _deferColumnRevealIfSuppressed({
    required FdcGridCellRef? editingCellBeforeActivation,
    required FdcGridCellRef targetCell,
    required bool revealColumn,
    required bool revealColumnOnlyIfOutside,
    required bool preferLeadingContext,
  }) {
    if (!revealColumn || !_suppressKeyboardColumnReveal) {
      return;
    }

    // While an in-place editor is committing, the current/editing column must
    // not pull the horizontal viewport around. If keyboard navigation enters a
    // different column, however, the target column still needs the normal
    // reveal behavior once the editor-scroll guard has settled.
    if (editingCellBeforeActivation == null ||
        editingCellBeforeActivation.columnIndex == targetCell.columnIndex) {
      return;
    }

    if (revealColumnOnlyIfOutside) {
      _revealColumnIfNeededAfterLayout(
        targetCell.columnIndex,
        preferLeadingContext: preferLeadingContext,
        delayFrameCount: 6,
      );
      return;
    }

    _scrollColumnIntoViewAfterLayout(
      targetCell.columnIndex,
      preferLeadingContext: preferLeadingContext,
      delayFrameCount: 6,
    );
  }

  void _cancelActiveCellEditing(Object? oldValue, {bool restoreValue = true}) {
    final cell = _editingCell ?? _selectedCell;
    if (cell == null) {
      _focusGridForSelectedCell();
      return;
    }

    final columns = _visibleColumns;
    if (cell.columnIndex >= 0 && cell.columnIndex < columns.length) {
      final column = columns[cell.columnIndex];
      if (restoreValue && cell.rowIndex >= 0 && cell.rowIndex < _rows.length) {
        final restoreValueForCell = _originalValueForEditingCell(
          cell,
          oldValue,
        );
        final currentValue = _dataSetValueAt(cell.rowIndex, column);
        if (currentValue != restoreValueForCell) {
          _updateCell(cell.rowIndex, column, restoreValueForCell);
        }
      }
    }

    _setGridState(() {
      _editingCell = null;
      _pendingEditCell = null;
      _editAtEndCell = null;
      _clearEditingOriginalValue();
      _selectedCell = cell;
      _selectedRowIndex = cell.rowIndex;
    }, focusReason: FdcGridFocusChangeReason.editCancel);
    _focusGridForSelectedCell();
  }

  void _focusGridForSelectedCell() {
    if (!mounted || _editingCell != null) {
      return;
    }

    _gridFocusNode.requestFocus();
  }

  void _focusGridForSelectedCellAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _editingCell != null) {
        return;
      }

      _gridFocusNode.requestFocus();
    });
  }

  bool _beginGridMove() {
    if (_handlingGridMove) {
      return false;
    }

    // Mouse cell activation temporarily preserves the viewport so focus/selection
    // changes cannot pull the clicked cell around. Once the user explicitly
    // navigates with the keyboard, that pending mouse restore must no longer
    // own the vertical offset; otherwise the first PageUp/PageDown after a mouse
    // click is treated as a stale programmatic jump and gets blocked.
    _cancelVerticalRestoreForUserInput();

    _handlingGridMove = true;
    unawaited(
      Future<void>.microtask(() {
        if (mounted) {
          _handlingGridMove = false;
        }
      }),
    );
    return true;
  }
}
