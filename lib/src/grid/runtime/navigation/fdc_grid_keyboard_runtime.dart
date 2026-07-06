// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateKeyboardRuntime on _FdcGridState {
  KeyEventResult _handleGridKeyEvent(FocusNode node, KeyEvent event) {
    // Key events bubble through ancestor Focus widgets. When this grid contains
    // another FdcGrid (for example in a detail row), both grid focus nodes have
    // `hasFocus == true`. Only the nearest/live grid focus root that owns the
    // primary focus may process navigation or auto-edit typing.
    if (!_ownsPrimaryKeyboardFocus) {
      return KeyEventResult.ignored;
    }

    final featureKeyResult = widget.rangeSelection?.handleKeyEvent(event);
    if (featureKeyResult != null) {
      return featureKeyResult;
    }

    _updateRangeSelectionModifier(event);

    if (!FdcKeyUtils.isKeyDownOrRepeat(event)) {
      return KeyEventResult.ignored;
    }

    if (FdcKeyUtils.isFindShortcut(event)) {
      return _openToolbarSearchFromShortcut()
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }

    if (FdcKeyUtils.isCopyShortcut(event) && _shouldHandleGridCopyShortcut()) {
      unawaited(_copySelectedCellToClipboard());
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isPasteShortcut(event) &&
        _shouldHandleGridPasteShortcut()) {
      unawaited(_pasteClipboardIntoSelectedCell());
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isEscape(event)) {
      if (_editingCell != null) {
        final editorState = _activeCellEditorState;
        if (editorState == null) {
          _cancelActiveCellEditing(null, restoreValue: false);
        } else {
          final oldValue = editorState.cancelEditing();
          _cancelActiveCellEditing(oldValue);
        }
        return KeyEventResult.handled;
      }

      if (_rangeSelectionSession.shouldHandleEscape(
        enabled: _rangeSelectionEnabled,
      )) {
        _clearCellRange();
        return KeyEventResult.handled;
      }

      if (_cancelDataSetEditOrInsertFromEscape()) {
        return KeyEventResult.handled;
      }
    }

    if (FdcKeyUtils.isPageDown(event)) {
      if (FdcKeyUtils.isControlPressed) {
        _moveToLastRow();
      } else {
        _movePageDown();
      }
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isPageUp(event)) {
      if (FdcKeyUtils.isControlPressed) {
        _moveToFirstRow();
      } else {
        _movePageUp();
      }
      return KeyEventResult.handled;
    }

    if (_editingCell == null && FdcKeyUtils.isHome(event)) {
      if (_hasGridTextInputFocus) {
        return KeyEventResult.ignored;
      }
      _moveToFirstColumnInCurrentRow();
      return KeyEventResult.handled;
    }

    if (_editingCell == null && FdcKeyUtils.isEnd(event)) {
      if (_hasGridTextInputFocus) {
        return KeyEventResult.ignored;
      }
      _moveToLastColumnInCurrentRow();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isInsert(event) &&
        !FdcKeyUtils.isControlPressed &&
        !FdcKeyUtils.isShiftPressed &&
        !HardwareKeyboard.instance.isAltPressed &&
        !FdcKeyUtils.isMetaPressed &&
        _gridCellHasPrimaryFocus) {
      return _insertCurrentRecordFromKeyboard()
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }

    if (FdcKeyUtils.isDelete(event) &&
        FdcKeyUtils.isControlPressed &&
        _gridCellHasPrimaryFocus) {
      return _deleteCurrentRecordFromKeyboard()
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }

    if ((FdcKeyUtils.isBackspace(event) || FdcKeyUtils.isDelete(event)) &&
        !FdcKeyUtils.isControlPressed &&
        _gridCellHasPrimaryFocus) {
      return _clearSelectedCellValue()
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }

    if (_handleLookupShortcut(event)) {
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isF2(event)) {
      return _handleF2Key() ? KeyEventResult.handled : KeyEventResult.ignored;
    }

    if (FdcKeyUtils.isSpace(event)) {
      if (_handleBooleanSpaceKey()) {
        return KeyEventResult.handled;
      }
      if (_editingCell != null && _isEditingDropdownCell()) {
        final editorState = _activeCellEditorState;
        if (editorState != null) {
          editorState.activateDropdown();
        } else {
          _activateDropdownEditorAfterLayout();
        }
        return KeyEventResult.handled;
      }
      return _handleDropdownSpaceKey()
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }

    if (FdcKeyUtils.isEnter(event)) {
      _moveToNextCell();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isTab(event) && !FdcKeyUtils.isShiftPressed) {
      _moveToNextTabCell();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isTab(event) && FdcKeyUtils.isShiftPressed) {
      _moveToPreviousTabCell();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isArrowRight(event)) {
      if (_hasHeaderFilterFocus ||
          (_editingCell != null && !_isEditingDropdownCell())) {
        return KeyEventResult.ignored;
      }
      final previousCell = _selectedCell;
      _moveHorizontal(columnOffset: 1);
      if (FdcKeyUtils.isShiftPressed && previousCell != null) {
        _beginOrExtendCellRange(previousCell);
      } else {
        _clearCellRange();
      }
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isArrowLeft(event)) {
      if (_hasHeaderFilterFocus ||
          (_editingCell != null && !_isEditingDropdownCell())) {
        return KeyEventResult.ignored;
      }
      final previousCell = _selectedCell;
      _moveHorizontal(columnOffset: -1);
      if (FdcKeyUtils.isShiftPressed && previousCell != null) {
        _beginOrExtendCellRange(previousCell);
      } else {
        _clearCellRange();
      }
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isArrowDown(event)) {
      if (_editingCell != null && FdcKeyUtils.isShiftPressed) {
        return KeyEventResult.ignored;
      }
      final previousCell = _selectedCell;
      _moveToNextRow();
      if (FdcKeyUtils.isShiftPressed && previousCell != null) {
        _beginOrExtendCellRange(previousCell);
      } else {
        _clearCellRange();
      }
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isArrowUp(event)) {
      if (_editingCell != null && FdcKeyUtils.isShiftPressed) {
        return KeyEventResult.ignored;
      }
      final previousCell = _selectedCell;
      _moveToPreviousRow();
      if (FdcKeyUtils.isShiftPressed && previousCell != null) {
        _beginOrExtendCellRange(previousCell);
      } else {
        _clearCellRange();
      }
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent && _tryStartEditingWithKey(event)) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool get _hasGridTextInputFocus {
    return _hasHeaderFilterFocus ||
        _runtime.domains.toolbar.searchController.hasFocus;
  }

  bool _handleLookupShortcut(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    final cell = _selectedCell;
    final columns = _visibleColumns;
    if (cell == null ||
        cell.rowIndex < 0 ||
        cell.rowIndex >= _rows.length ||
        cell.columnIndex < 0 ||
        cell.columnIndex >= columns.length) {
      return false;
    }

    final column = columns[cell.columnIndex];
    final shortcut = column.lookupShortcut;
    if (column.lookupSignatureToken == null ||
        shortcut == null ||
        !fdcKeyboardShortcutAccepts(
          shortcut,
          event,
          HardwareKeyboard.instance,
        ) ||
        !_isCellEditable(column, cell.rowIndex)) {
      return false;
    }

    final editorText = _editingCell == cell
        ? _activeCellEditorState?.lookupEditorText
        : null;
    unawaited(
      _lookupCellValue(
        context,
        column,
        cell.rowIndex,
        cell.columnIndex,
        editorText,
        FdcLookupMode.search,
      ),
    );
    return true;
  }

  bool _handleF2Key() {
    if (_editingCell != null) {
      final editorState = _activeCellEditorState;
      if (editorState != null) {
        editorState.focusAndMoveCursorToEnd();
      } else {
        _focusActiveEditorAtEndAfterLayout();
      }
      return true;
    }

    return _tryStartEditingSelectedCell();
  }

  bool _handleDropdownSpaceKey() {
    // Space is an explicit grid action for combo cells. It must work even when
    // autoEdit is disabled; autoEdit only controls typed-text edit start.
    final cell = _selectedCell;
    final columns = _visibleColumns;
    if (cell == null ||
        cell.rowIndex < 0 ||
        cell.rowIndex >= _rows.length ||
        cell.columnIndex < 0 ||
        cell.columnIndex >= columns.length) {
      return false;
    }

    final column = columns[cell.columnIndex];
    if (!_isDropdownEditor(column) || !_isCellEditable(column, cell.rowIndex)) {
      return false;
    }

    _activateCell(
      cell,
      editIfPossible: true,
      focusReason: FdcGridFocusChangeReason.keyboard,
    );
    _activateDropdownEditorAfterLayout();
    return true;
  }

  bool _handleBooleanSpaceKey() {
    final cell = _selectedCell;
    final columns = _visibleColumns;
    if (cell == null ||
        cell.rowIndex < 0 ||
        cell.rowIndex >= _rows.length ||
        cell.columnIndex < 0 ||
        cell.columnIndex >= columns.length) {
      return false;
    }

    final column = columns[cell.columnIndex];
    if (!_shouldToggleBooleanCell(column, cell.rowIndex)) {
      return false;
    }

    _toggleBooleanCell(column, cell.rowIndex, cell.columnIndex);
    return true;
  }

  bool _isEditingDropdownCell() {
    final cell = _editingCell;
    final columns = _visibleColumns;
    if (cell == null ||
        cell.columnIndex < 0 ||
        cell.columnIndex >= columns.length) {
      return false;
    }
    return _isDropdownEditor(columns[cell.columnIndex]);
  }

  void _activateDropdownEditorAfterLayout([int remainingAttempts = 6]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final editorState = _activeCellEditorState;
      if (editorState != null) {
        editorState.activateDropdown();
        return;
      }
      if (remainingAttempts > 0) {
        _activateDropdownEditorAfterLayout(remainingAttempts - 1);
      }
    });
  }

  bool _tryStartEditingWithKey(KeyDownEvent event) {
    if (!widget.options.autoEdit) {
      return false;
    }

    final text = event.character;
    if (text == null || text.isEmpty || _isControlCharacter(text)) {
      return false;
    }

    final cell = _selectedCell;
    final columns = _visibleColumns;
    if (cell == null ||
        cell.rowIndex < 0 ||
        cell.rowIndex >= _rows.length ||
        cell.columnIndex < 0 ||
        cell.columnIndex >= columns.length) {
      return false;
    }

    var column = columns[cell.columnIndex];
    if (_isDropdownEditor(column)) {
      return true;
    }

    if (_editingCell != null) {
      if (_editingCell != cell || !_gridCellHasPrimaryFocus) {
        return false;
      }

      final editorState = _activeCellEditorState;
      if (editorState != null) {
        editorState.requestTextFocus();
        return false;
      }
      if (!_isPendingEditCell(cell.rowIndex, cell.columnIndex)) {
        return false;
      }
    }

    if (!_isCellEditable(column, cell.rowIndex) ||
        !_typing.canStartTyping(column, text)) {
      return false;
    }

    if (!_ensureDataSetEditForCell(
      cell.rowIndex,
      column,
      focusActiveEditorAfterDialog: true,
    )) {
      return true;
    }

    // Starting to type in the empty insert placeholder synchronously appends
    // the first dataset row. The originally selected placeholder cell has no
    // stable record identity, while the rebuilt editor is keyed by the real
    // appended record identity. Resolve the cell again after the edit guard so
    // pending/editing state and editor focus target the live row, not the
    // pre-append placeholder key.
    final editCell = _cellRef(cell.rowIndex, cell.columnIndex);
    column = columns[editCell.columnIndex];

    final metadata = _fieldMetadata(column.fieldName);
    final rawPendingText = text;
    final pendingText = _typing.formatTypedText(
      context,
      column,
      rawPendingText,
      runtimeColumnId: editCell.runtimeColumnId,
      decimalScale: metadata.decimalScale,
      decimalPrecision: metadata.decimalPrecision,
    );
    final value = _typing.valueFromTypedText(
      context,
      column,
      pendingText,
      runtimeColumnId: editCell.runtimeColumnId,
      decimalScale: metadata.decimalScale,
      decimalPrecision: metadata.decimalPrecision,
    );
    final oldValue = _dataSetValueAt(editCell.rowIndex, column);
    final changed = oldValue != value;

    _setGridState(() {
      _pendingEditText = pendingText;
      _pendingEditCell = editCell;
      _selectedRowIndex = editCell.rowIndex;
      _selectedCell = editCell;
      _editingOriginalCell = editCell;
      _editingOriginalValue = oldValue;
      _hasEditingOriginalValue = true;
      _editingCell = editCell;
      _editAtEndCell = editCell;
      if (changed) {
        // Keep the typed text local to the editor until it is committed. The
        // dataset remains the source of truth and is updated by _updateCell().
        _markColumnWidthsDirtyFor(column);
      }
    });

    _focusActiveEditorAtEndAfterLayout();
    return true;
  }

  bool _tryStartEditingSelectedCell() {
    final cell = _selectedCell;
    final columns = _visibleColumns;
    if (cell == null ||
        cell.rowIndex < 0 ||
        cell.rowIndex >= _rows.length ||
        cell.columnIndex < 0 ||
        cell.columnIndex >= columns.length ||
        !_isCellEditable(columns[cell.columnIndex], cell.rowIndex)) {
      return false;
    }

    _activateCell(
      cell,
      editIfPossible: true,
      placeCursorAtEnd: true,
      focusReason: FdcGridFocusChangeReason.keyboard,
    );
    return true;
  }

  void _focusActiveEditorAfterLayout([int remainingAttempts = 6]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final editorState = _activeCellEditorState;
      if (editorState != null) {
        editorState.requestTextFocus();
        return;
      }
      if (remainingAttempts > 0) {
        _focusActiveEditorAfterLayout(remainingAttempts - 1);
      }
    });
  }

  void _focusGridForAutoEditAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // Deferred auto-edit must never steal focus back from a nested grid or
      // one of its editors. The parent may retain its selected cell while the
      // nearest nested grid remains the keyboard owner.
      final owner = _primaryGridKeyboardFocusRoot;
      if (owner != null && !identical(owner, _gridFocusNode)) {
        return;
      }
      _gridFocusNode.requestFocus();
    });
  }

  void _focusActiveEditorAtEndAfterLayout([int remainingAttempts = 6]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final editorState = _activeCellEditorState;
      if (editorState != null) {
        editorState.focusAndMoveCursorToEnd();
        return;
      }
      if (remainingAttempts > 0) {
        _focusActiveEditorAtEndAfterLayout(remainingAttempts - 1);
      }
    });
  }

  FdcGridCellEditorState? get _activeCellEditorState {
    return _runtime.domains.editing.editorKeys.activeEditorState(
      editingCell: _editingCell,
      rowCount: _rows.length,
      columns: _visibleColumns,
    );
  }

  bool _isDropdownEditor(FdcGridColumn<dynamic> column) {
    return column.effectiveEditor == FdcEditorType.combo;
  }

  bool _clearSelectedCellValue() {
    final cell = _selectedCell;
    final columns = _visibleColumns;
    if (cell == null ||
        cell.rowIndex < 0 ||
        cell.rowIndex >= _rows.length ||
        cell.columnIndex < 0 ||
        cell.columnIndex >= columns.length) {
      return false;
    }

    final column = columns[cell.columnIndex];
    if (!_isCellEditable(column, cell.rowIndex)) {
      return false;
    }

    final oldValue = _dataSetValueAt(cell.rowIndex, column);
    if (oldValue == null) {
      return true;
    }

    _clearPendingEditText();
    _updateCell(cell.rowIndex, column, null);
    _setGridState(() {
      if (_editingCell == cell) {
        _editingCell = null;
      }
      if (_editAtEndCell == cell) {
        _editAtEndCell = null;
      }
    });
    return true;
  }

  bool _isControlCharacter(String text) {
    return text.runes.any((rune) => rune < 0x20 || rune == 0x7F);
  }

  bool _isPendingEditCell(int rowIndex, int columnIndex) {
    return _pendingEditText != null &&
        _pendingEditCell?.matches(_cellRef(rowIndex, columnIndex)) == true;
  }

  void _clearPendingEditText() {
    _pendingEditText = null;
    _pendingEditCell = null;
  }
}
