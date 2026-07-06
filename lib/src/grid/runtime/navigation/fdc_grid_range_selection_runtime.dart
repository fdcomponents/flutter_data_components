// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridRangeSelectionRuntime on _FdcGridState {
  FdcGridRangeSelectionSession _createGridRangeSelectionSession() {
    return widget.rangeSelection?.createSession(_rangeSelectionHost) ??
        FdcGridRangeSelectionSession.noop();
  }

  bool get _rangeSelectionConfigured =>
      widget.rangeSelection?.isAvailable(_rangeSelectionHost) ?? false;

  bool get _rangeSelectionCopyEnabled =>
      widget.rangeSelection?.canCopyRange(_rangeSelectionHost) ?? false;

  bool get _rangeSelectionPasteEnabled =>
      widget.rangeSelection?.canPasteRange(_rangeSelectionHost) ?? false;

  bool get _rangeSelectionFillSingleValueEnabled =>
      widget.rangeSelection?.canFillSingleValue(_rangeSelectionHost) ?? false;

  bool get _rangeSelectionEnabled => _rangeSelectionConfigured;

  bool get _hasExplicitCellRange => _rangeSelectionSession.hasExplicitCellRange;

  void _attachGridRangeSelectionFeature() {
    widget.rangeSelection?.attach(_rangeSelectionHost);
  }

  void _detachGridRangeSelectionFeature(FdcGridRangeSelectionFeature? feature) {
    feature?.detach();
  }

  void _notifyRangeSelectionReset({bool rebuild = true}) {
    widget.rangeSelection?.reset(rebuild: rebuild);
  }

  ({
    int firstRow,
    int lastRow,
    int firstColumn,
    int lastColumn,
    List<int> columnIndexes,
  })?
  _selectedRangeOverlayBounds() {
    if (!_rangeSelectionEnabled || !_hasExplicitCellRange) return null;
    return _selectedRangeBounds();
  }

  bool get _rangeSelectionModifierActive =>
      _rangeSelectionEnabled && _rangeSelectionSession.modifierDown;

  bool _handleGlobalRangeSelectionKeyEvent(KeyEvent event) {
    final modifierKey = _rangeSelectionSession.isModifierKeyEvent(event);
    final pressed = _rangeSelectionSession.isModifierPressedEvent(event);
    if (!_rangeSelectionSession.shouldProcessGlobalModifierEvent(
      enabled: _rangeSelectionEnabled,
      modifierKey: modifierKey,
      pressed: pressed,
      hoverCell: _rangeSelectionSession.pointerHoverCell,
      hasActiveCellEditor: _editingCell != null,
      hasGridTextInputFocus: _hasGridTextInputFocus,
    )) {
      return false;
    }

    _updateRangeSelectionModifier(event);
    return false;
  }

  void _updateRangeSelectionModifier(KeyEvent event) {
    final modifierKey = _rangeSelectionSession.isModifierKeyEvent(event);
    if (!modifierKey) return;
    final pressed = _rangeSelectionSession.isModifierPressedEvent(event);
    var changed = false;
    _setGridState(() {
      changed = _rangeSelectionSession.updateModifierFromKeyboard(
        enabled: _rangeSelectionEnabled,
        pressed: pressed,
        currentCell: _rangeSelectionSession.pointerHoverCell ?? _selectedCell,
      );
      if (!changed) return;
      if (pressed) {
        _beginRangeSelectionScrollLock();
      } else {
        _endRangeSelectionScrollLock();
      }
    });
  }

  void _updateRangePointerHoverCell(int? rowIndex, int? columnIndex) {
    final next = rowIndex == null || columnIndex == null
        ? null
        : _cellRef(rowIndex, columnIndex);
    _rangeSelectionSession.updatePointerHoverCell(next);
  }

  void _beginRangeSelectionScrollLock() {
    if (_rangeSelectionSession.scrollOffsetLockActive) return;
    final verticalOffset = _scrollCoordinator.liveVerticalOffset;
    final horizontalOffset = _scrollCoordinator.liveHorizontalOffset;
    _scrollCoordinator.beginVerticalOffsetRestore(verticalOffset);
    _scrollCoordinator.beginHorizontalOffsetRestore(horizontalOffset);
    _rangeSelectionSession.scrollOffsetLockActive = true;
  }

  void _endRangeSelectionScrollLock() {
    if (!_rangeSelectionSession.scrollOffsetLockActive) return;
    _rangeSelectionSession.scrollOffsetLockActive = false;
    _scrollCoordinator.endVerticalOffsetRestore();
    _scrollCoordinator.endHorizontalOffsetRestore();
  }

  void _resetRangeSelectionState({bool rebuild = true}) {
    if (!_rangeSelectionSession.hasRangeState) return;

    void reset() {
      _endRangeSelectionScrollLock();
      _rangeSelectionSession.reset();
    }

    if (rebuild) {
      _setGridState(reset);
    } else {
      reset();
    }
  }

  void _releaseRangeSelectionInputState({bool rebuild = true}) {
    if (!_rangeSelectionSession.hasInputState) return;

    void release() {
      _endRangeSelectionScrollLock();
      _rangeSelectionSession.releaseInput();
    }

    if (rebuild) {
      _setGridState(release);
    } else {
      release();
    }
  }

  void _clearCellRange({bool rebuild = true}) {
    if (_rangeSelectionSession.anchorCell == null &&
        _rangeSelectionSession.extentCell == null) {
      return;
    }
    if (rebuild) {
      _setGridState(() {
        _rangeSelectionSession.dismissRange();
      });
    } else {
      _rangeSelectionSession.dismissRange();
    }
  }

  void _beginOrExtendCellRange(FdcGridCellRef previousCell) {
    if (!_rangeSelectionEnabled) return;
    final current = _selectedCell;
    if (current == null) return;
    var changed = false;
    _setGridState(() {
      changed = _rangeSelectionSession.beginOrExtendFromSelectedCell(
        previousCell: previousCell,
        currentCell: current,
      );
    });
    if (!changed) return;
  }

  void _startCellRangeFromPointer(int rowIndex, int columnIndex) {
    final target = _cellRef(rowIndex, columnIndex);
    var started = false;
    _setGridState(() {
      started = _rangeSelectionSession.startPointerDrag(
        enabled: _rangeSelectionEnabled,
        modifierActive: _rangeSelectionModifierActive,
        target: target,
        selectedCell: _selectedCell,
      );
    });
    if (!started) return;
  }

  void _updateCellRangeFromPointer(int rowIndex, int columnIndex) {
    final target = _cellRef(rowIndex, columnIndex);
    if (!_rangeSelectionSession.updatePointerDrag(target)) return;
    _setGridState(() {});
  }

  void _endCellRangePointerDrag() {
    if (!_rangeSelectionSession.endPointerDrag()) return;
    _setGridState(() {});
  }

  bool _rangeSelectionContainsCell(int rowIndex, int columnIndex) {
    return _rangeSelectionSession.containsCell(
      _selectedRangeOverlayBounds(),
      _cellRef(rowIndex, columnIndex),
    );
  }

  List<int> _visualRangeColumnIndexes() {
    final bands = _columnBandsCache;
    return <int>[
          ...bands.pinnedLeft.columnIndexes,
          ...bands.scrollable.columnIndexes,
          ...bands.pinnedRight.columnIndexes,
        ]
        .where((index) => index >= 0 && index < _visibleColumns.length)
        .toList(growable: false);
  }

  ({
    int firstRow,
    int lastRow,
    int firstColumn,
    int lastColumn,
    List<int> columnIndexes,
  })?
  _selectedRangeBounds() {
    return _rangeSelectionSession.resolveBounds(
      enabled: _rangeSelectionEnabled,
      selectedCell: _selectedCell,
      visualColumnIndexes: _visualRangeColumnIndexes(),
    );
  }
}

class _FdcGridRangeSelectionHostAdapter extends FdcGridRangeSelectionHost {
  const _FdcGridRangeSelectionHostAdapter(this._state);

  final _FdcGridState _state;

  @override
  FdcDataSet get dataSet => _state.widget.dataSet;

  @override
  FdcDataSetState get dataSetState => _state.widget.dataSet.state;

  @override
  FdcGridCellRef? get selectedCell => _state._selectedCell;

  @override
  List<FdcGridColumn<dynamic>> get visibleColumns => _state._visibleColumns;

  @override
  int get rowCount => _state._rows.length;

  @override
  bool get hasExpandedDetailRows => _state._hasExpandedDetailRows;

  @override
  bool get hasActiveCellEditor => _state._editingCell != null;

  @override
  void requestRebuild() {
    if (!_state.mounted) return;
    _state._setGridState(() {});
  }

  @override
  void resetRangeSelectionState({bool rebuild = true}) {
    _state._resetRangeSelectionState(rebuild: rebuild);
  }
}
