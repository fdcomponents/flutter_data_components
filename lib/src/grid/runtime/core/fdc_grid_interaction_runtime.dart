// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridInteractionRuntime on _FdcGridState {
  void _setGridState(
    VoidCallback fn, {
    FdcGridFocusChangeReason focusReason =
        FdcGridFocusChangeReason.programmatic,
  }) {
    if (!mounted) {
      return;
    }

    final previousFocus = _currentGridFocusSnapshot();
    _applyGridState(() {
      fn();
      _syncInteractionState();
    });
    _emitGridFocusEvents(
      previousFocus,
      _currentGridFocusSnapshot(),
      focusReason,
    );
  }

  bool get _hasHeaderFilterFocus {
    return _headerFilterFocusNodes.values.any((node) => node.hasFocus);
  }

  FdcGridFocusState get _focusState {
    if (_hasHeaderFilterFocus) {
      return FdcGridFocusState.headerFilter;
    }
    if (!_gridFocusNode.hasFocus || !_ownsPrimaryKeyboardFocus) {
      return FdcGridFocusState.none;
    }
    return _editingCell == null
        ? FdcGridFocusState.cell
        : FdcGridFocusState.editor;
  }

  bool get _gridCellHasPrimaryFocus {
    return _focusState == FdcGridFocusState.cell &&
        _gridFocusNode.hasPrimaryFocus;
  }

  FocusNode? get _primaryGridKeyboardFocusRoot {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) {
      return null;
    }

    if (_fdcGridKeyboardFocusRoots.contains(primaryFocus)) {
      return primaryFocus;
    }

    for (final ancestor in primaryFocus.ancestors) {
      if (_fdcGridKeyboardFocusRoots.contains(ancestor)) {
        return ancestor;
      }
    }

    return null;
  }

  bool get _ownsPrimaryKeyboardFocus {
    return identical(_primaryGridKeyboardFocusRoot, _gridFocusNode);
  }

  bool get _cellFocusVisible {
    final state = _focusState;
    return state == FdcGridFocusState.cell || state == FdcGridFocusState.editor;
  }

  int? get _currentRowIndex {
    final rowIndex = FdcDataSetInternal.activeIndex(widget.dataSet);
    return _isLiveGridRowIndex(rowIndex) ? rowIndex : null;
  }

  void _syncInteractionState() {
    final next = FdcGridInteractionState(
      selectedCell: _selectedCell,
      editingCell: _editingCell,
      pendingEditCell: _pendingEditCell,
      editAtEndCell: _editAtEndCell,
      selectedRowIndex: _selectedRowIndex,
      currentRowIndex: _currentRowIndex,
      focusState: _focusState,
    );

    if (_interactionState.value != next) {
      _interactionState.value = next;
    }
  }

  IFdcGridRowSource _rowsFromDataSet() {
    if (_shouldShowEmptyInsertRow) {
      return FdcEmptyInsertGridRowSource(widget.dataSet);
    }
    return FdcDataSetGridRowSource(widget.dataSet);
  }

  bool get _shouldShowEmptyInsertRow {
    return widget.dataSet.isOpen &&
        widget.dataSet.state == FdcDataSetState.browse &&
        widget.dataSet.recordCount == 0 &&
        _hasEditableEmptyInsertField;
  }

  bool get _hasEditableEmptyInsertField {
    if (FdcDataSetInternal.isReadOnly(widget.dataSet) ||
        widget.options.readOnly) {
      return false;
    }
    for (final field in widget.dataSet.fields) {
      if (!field.isPersistent ||
          field.isReadOnly ||
          field.dataType == FdcDataType.guid) {
        continue;
      }
      return true;
    }
    return false;
  }

  void _handleGridFocusChanged() {
    if (!mounted) {
      return;
    }

    _applyGridState(() {
      if (!_ownsPrimaryKeyboardFocus) {
        // Losing primary focus should stop an active Shift/drag gesture, but it
        // must not clear the selected cell range. Range context menus and other
        // overlays can take focus while the user is about to choose Copy/Paste.
        _releaseRangeSelectionInputState(rebuild: false);
      }
      _syncInteractionState();
    });
  }
}
