// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateCellMovementRuntime on _FdcGridState {
  void _moveToNextCell() {
    if (!_beginGridMove()) {
      return;
    }

    final current = _editingCell ?? _selectedCell;
    final next = _findNextEditableCell(forward: true);
    if (next == null &&
        current != null &&
        _shouldAppendAfterLeavingCell(current)) {
      if (_cancelPristineInsertRowIfNeeded(current.rowIndex)) {
        return;
      }
      _pendingAppendAfterImmediatePost = true;
      _pendingAppendUsesTabOrder = false;
      if (!_postRow(current.rowIndex)) {
        return;
      }
      _pendingAppendAfterImmediatePost = false;
      _appendEmptyRowAndFocusFirstField();
      return;
    }

    if (next == null) {
      return;
    }

    final preferLeadingColumnContext = current?.rowIndex != next.rowIndex;
    if (!_postCurrentRowIfLeaving(
      next.rowIndex,
      continueToCellAfterImmediatePost: next,
      preferLeadingColumnContext: preferLeadingColumnContext,
    )) {
      return;
    }
    _scrollRowIntoView(next.rowIndex);
    _activateCell(
      next,
      editIfPossible: false,
      preferLeadingColumnContext: preferLeadingColumnContext,
      revealColumnOnlyIfOutside: true,
      focusReason: FdcGridFocusChangeReason.keyboard,
    );
  }

  void _moveToPreviousCell() {
    if (!_beginGridMove()) {
      return;
    }

    final current = _editingCell ?? _selectedCell;
    final next = _findNextEditableCell(forward: false);
    if (next == null) {
      return;
    }

    final preferLeadingColumnContext = current?.rowIndex != next.rowIndex;
    if (!_postCurrentRowIfLeaving(
      next.rowIndex,
      continueToCellAfterImmediatePost: next,
      preferLeadingColumnContext: preferLeadingColumnContext,
    )) {
      return;
    }
    _scrollRowIntoView(next.rowIndex);
    _activateCell(
      next,
      editIfPossible: false,
      preferLeadingColumnContext: preferLeadingColumnContext,
      revealColumnOnlyIfOutside: true,
      focusReason: FdcGridFocusChangeReason.keyboard,
    );
  }

  void _moveToNextTabCell() {
    if (!_beginGridMove()) {
      return;
    }

    final current = _editingCell ?? _selectedCell;
    final next = _findNextTabCell(forward: true);
    if (next == null &&
        current != null &&
        _shouldAppendAfterLeavingTabCell(current)) {
      if (_cancelPristineInsertRowIfNeeded(current.rowIndex)) {
        return;
      }
      _pendingAppendAfterImmediatePost = true;
      _pendingAppendUsesTabOrder = true;
      if (!_postRow(current.rowIndex)) {
        return;
      }
      _pendingAppendAfterImmediatePost = false;
      _appendEmptyRowAndFocusFirstField(useTabOrder: true);
      return;
    }

    if (next == null) {
      return;
    }

    final preferLeadingColumnContext = current?.rowIndex != next.rowIndex;
    if (!_postCurrentRowIfLeaving(
      next.rowIndex,
      continueToCellAfterImmediatePost: next,
      preferLeadingColumnContext: preferLeadingColumnContext,
    )) {
      return;
    }
    _scrollRowIntoView(next.rowIndex);
    _activateCell(
      next,
      editIfPossible: false,
      preferLeadingColumnContext: preferLeadingColumnContext,
      revealColumnOnlyIfOutside: true,
      focusReason: FdcGridFocusChangeReason.keyboard,
    );
  }

  void _moveToPreviousTabCell() {
    if (!_beginGridMove()) {
      return;
    }

    final current = _editingCell ?? _selectedCell;
    final next = _findNextTabCell(forward: false);
    if (next == null) {
      return;
    }

    final preferLeadingColumnContext = current?.rowIndex != next.rowIndex;
    if (!_postCurrentRowIfLeaving(
      next.rowIndex,
      continueToCellAfterImmediatePost: next,
      preferLeadingColumnContext: preferLeadingColumnContext,
    )) {
      return;
    }
    _scrollRowIntoView(next.rowIndex);
    _activateCell(
      next,
      editIfPossible: false,
      preferLeadingColumnContext: preferLeadingColumnContext,
      revealColumnOnlyIfOutside: true,
      focusReason: FdcGridFocusChangeReason.keyboard,
    );
  }

  void _moveToNextRow() {
    if (!_beginGridMove()) {
      return;
    }

    final current = _editingCell ?? _selectedCell;
    final next = _findVerticalCell(rowOffset: 1);
    if (next == null) {
      if (current != null && current.rowIndex == _rows.length - 1) {
        // ArrowDown on the already-active append row should be a no-op while
        // the insert buffer is still pristine. Leaving the row by clicking a
        // different row still uses the normal pristine-insert cancel path, but
        // vertical keyboard navigation at EOF must not silently cancel the
        // append and move the DataSet back to browse/current-previous-row.
        if (_isPristineActiveInsertRow(current.rowIndex)) {
          _scrollRowIntoView(current.rowIndex);
          return;
        }
        _pendingAppendAfterImmediatePost = true;
        _pendingAppendUsesTabOrder = false;
        if (!_postRow(current.rowIndex)) {
          return;
        }
        _pendingAppendAfterImmediatePost = false;
        _appendEmptyRowAndFocusFirstField();
      }
      return;
    }

    if (!_postCurrentRowIfLeaving(
      next.rowIndex,
      continueToCellAfterImmediatePost: next,
    )) {
      return;
    }
    _scrollRowIntoView(next.rowIndex);
    _activateCell(
      next,
      editIfPossible: false,
      revealColumnOnlyIfOutside: true,
      focusReason: FdcGridFocusChangeReason.keyboard,
    );
  }

  void _moveToPreviousRow() {
    if (!_beginGridMove()) {
      return;
    }

    if (_isEditingFirstGridRow()) {
      return;
    }

    if (_focusHeaderFilterFromFirstGridRow()) {
      return;
    }

    final next = _findVerticalCell(rowOffset: -1);
    if (next == null) {
      return;
    }

    if (!_postCurrentRowIfLeaving(
      next.rowIndex,
      continueToCellAfterImmediatePost: next,
    )) {
      return;
    }
    _scrollRowIntoView(next.rowIndex);
    _activateCell(
      next,
      editIfPossible: false,
      revealColumnOnlyIfOutside: true,
      focusReason: FdcGridFocusChangeReason.keyboard,
    );
  }

  bool _isEditingFirstGridRow() {
    final state = widget.dataSet.state;
    if (state != FdcDataSetState.edit && state != FdcDataSetState.insert) {
      return false;
    }

    final cell = _editingCell ?? _selectedCell;
    return cell != null && cell.rowIndex == 0;
  }

  void _movePageDown() {
    _moveByPage(rowOffset: _visibleRowCount);
  }

  void _movePageUp() {
    _moveByPage(rowOffset: -_visibleRowCount);
  }

  void _moveToFirstRow() {
    _moveToBoundaryRow(rowIndex: 0);
  }

  void _moveToLastRow() {
    _moveToBoundaryRow(rowIndex: _rows.length - 1);
  }

  void _moveToBoundaryRow({required int rowIndex}) {
    if (!_beginGridMove() || _rows.isEmpty) {
      return;
    }

    final targetRowIndex = rowIndex.clamp(0, _rows.length - 1).toInt();
    if (targetRowIndex == _rows.length - 1) {
      // Absolute-end navigation is intentionally a geometry reset point.
      // Keeping expanded panels alive here makes the final viewport depend on
      // transient variable extents and destabilizes subsequent append/cancel.
      _collapseAllDetailRowsImmediately();
    }

    final current = _editingCell ?? _selectedCell;
    final fallbackColumnIndex = _currentScrollableSelectionColumnIndex();
    var columnIndex = current?.columnIndex ?? fallbackColumnIndex;
    if (columnIndex == null ||
        columnIndex < 0 ||
        columnIndex >= _visibleColumns.length) {
      return;
    }

    final navigationOrder = _visualNavigationColumnIndexes();
    if (!navigationOrder.contains(columnIndex)) {
      columnIndex = _nearestColumnIndexInOrder(
        navigationOrder,
        fromColumnIndex: columnIndex,
      );
      if (columnIndex == null) {
        return;
      }
    }

    final next = _cellRef(targetRowIndex, columnIndex);
    if (!_postCurrentRowIfLeaving(
      next.rowIndex,
      continueToCellAfterImmediatePost: next,
    )) {
      return;
    }
    _scrollRowIntoView(next.rowIndex);
    _activateCell(
      next,
      editIfPossible: false,
      revealColumnOnlyIfOutside: true,
      focusReason: FdcGridFocusChangeReason.keyboard,
    );
  }

  void _moveByPage({required int rowOffset}) {
    if (!_beginGridMove()) {
      return;
    }

    final next = _findPageCell(rowOffset: rowOffset);
    if (next == null) {
      return;
    }

    if (!_postCurrentRowIfLeaving(
      next.rowIndex,
      continueToCellAfterImmediatePost: next,
    )) {
      return;
    }
    _scrollRowIntoView(next.rowIndex);
    _activateCell(
      next,
      editIfPossible: false,
      revealColumnOnlyIfOutside: true,
      focusReason: FdcGridFocusChangeReason.keyboard,
    );
  }

  void _moveHorizontal({required int columnOffset}) {
    if (!_beginGridMove()) {
      return;
    }

    final columns = _visibleColumns;
    final current = _editingCell ?? _selectedCell;
    if (current == null || columns.isEmpty) {
      return;
    }

    final nextColumnIndex = _findHorizontalDataColumnIndex(
      fromColumnIndex: current.columnIndex,
      columnOffset: columnOffset,
    );
    if (nextColumnIndex == null) {
      _scrollPastKeyboardSkippedEdgeColumn(
        fromColumnIndex: current.columnIndex,
        columnOffset: columnOffset,
      );
      return;
    }

    final next = _cellRef(current.rowIndex, nextColumnIndex);
    if (!_postCurrentRowIfLeaving(next.rowIndex)) {
      return;
    }
    _activateCell(
      next,
      editIfPossible: false,
      revealColumnOnlyIfOutside: true,
      focusReason: FdcGridFocusChangeReason.keyboard,
    );
  }

  void _moveToFirstColumnInCurrentRow() {
    _moveToBoundaryColumnInCurrentRow(forward: true);
  }

  void _moveToLastColumnInCurrentRow() {
    _moveToBoundaryColumnInCurrentRow(forward: false);
  }

  void _moveToBoundaryColumnInCurrentRow({required bool forward}) {
    if (!_beginGridMove()) {
      return;
    }

    final columns = _visibleColumns;
    if (columns.isEmpty) {
      return;
    }

    final current = _editingCell ?? _selectedCell;
    var rowIndex =
        current?.rowIndex ?? FdcDataSetInternal.activeIndex(widget.dataSet);
    if (rowIndex < 0 && _rows.isNotEmpty) {
      rowIndex = 0;
    }
    if (rowIndex < 0 || rowIndex >= _rows.length) {
      if (forward) {
        _scrollToFirstColumn();
      } else {
        _scrollToLastColumn();
      }
      return;
    }

    final columnIndex = _findBoundaryDataColumnIndex(forward: forward);
    if (columnIndex == null) {
      if (forward) {
        _scrollToFirstColumn();
      } else {
        _scrollToLastColumn();
      }
      return;
    }

    final next = _cellRef(rowIndex, columnIndex);
    _activateCell(
      next,
      editIfPossible: false,
      revealColumnOnlyIfOutside: true,
      focusReason: FdcGridFocusChangeReason.keyboard,
    );
    _scrollPastKeyboardSkippedEdgeColumn(
      fromColumnIndex: columnIndex,
      columnOffset: forward ? -1 : 1,
    );
  }

  void _scrollPastKeyboardSkippedEdgeColumn({
    required int fromColumnIndex,
    required int columnOffset,
  }) {
    final columns = _visibleColumns;
    if (columns.isEmpty || columnOffset == 0) {
      return;
    }

    if (columnOffset > 0) {
      for (
        var columnIndex = columns.length - 1;
        columnIndex > fromColumnIndex;
        columnIndex--
      ) {
        if (columns[columnIndex].visible) {
          _scrollColumnIntoView(columnIndex);
          return;
        }
      }
      return;
    }

    for (var columnIndex = 0; columnIndex < fromColumnIndex; columnIndex++) {
      if (columns[columnIndex].visible) {
        _scrollColumnIntoView(columnIndex);
        return;
      }
    }
  }

  int? _nearestColumnIndexInOrder(
    List<int> columnOrder, {
    required int fromColumnIndex,
  }) {
    if (columnOrder.isEmpty) {
      return null;
    }
    if (columnOrder.contains(fromColumnIndex)) {
      return fromColumnIndex;
    }

    int? bestColumnIndex;
    int? bestDistance;
    for (final columnIndex in columnOrder) {
      final distance = (columnIndex - fromColumnIndex).abs();
      if (bestDistance == null || distance < bestDistance) {
        bestDistance = distance;
        bestColumnIndex = columnIndex;
      }
    }
    return bestColumnIndex;
  }

  int? _findBoundaryDataColumnIndex({required bool forward}) {
    return _navigation.boundaryColumnIndex(
      _visualNavigationColumnIndexes(),
      forward: forward,
    );
  }

  int? _findHorizontalDataColumnIndex({
    required int fromColumnIndex,
    required int columnOffset,
  }) {
    return _navigation.adjacentColumnIndex(
      columnOrder: _visualNavigationColumnIndexes(),
      fromColumnIndex: fromColumnIndex,
      columnOffset: columnOffset,
    );
  }
}
