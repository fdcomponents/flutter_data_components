// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateCellTraversalRuntime on _FdcGridState {
  FdcGridCellRef? _findNextEditableCell({required bool forward}) {
    final columns = _visibleColumns;
    return _navigation.findNextCellInOrder(
      rowCount: _rows.length,
      columnOrder: _visualNavigationColumnIndexes(),
      current: _editingCell ?? _selectedCell,
      fallbackRowIndex: _selectedRowIndex ?? 0,
      forward: forward,
      canUseCell: (rowIndex, columnIndex) =>
          _isCellEditable(columns[columnIndex], rowIndex),
    );
  }

  FdcGridCellRef? _findNextTabCell({required bool forward}) {
    final columns = _visibleColumns;
    return _navigation.findNextCellInOrder(
      rowCount: _rows.length,
      columnOrder: _tabTraversalColumnIndexes(),
      current: _editingCell ?? _selectedCell,
      fallbackRowIndex: _selectedRowIndex ?? 0,
      forward: forward,
      canUseCell: (rowIndex, columnIndex) =>
          _isTabNavigableCell(columns[columnIndex], rowIndex),
    );
  }

  List<int> _tabTraversalColumnIndexes() {
    return _navigation.tabTraversalColumnIndexes(
      columns: _visibleColumns,
      bands: _columnBandsCache,
    );
  }

  List<int> _visualNavigationColumnIndexes() {
    return _navigation.visualColumnIndexes(
      columns: _visibleColumns,
      bands: _columnBandsCache,
    );
  }

  FdcGridCellRef? _findVerticalCell({required int rowOffset}) {
    return _navigation.findVerticalCell(
      rowOffset: rowOffset,
      rowCount: _rows.length,
      columns: _visibleColumns,
      editingCell: _editingCell,
      selectedCell: _selectedCell,
    );
  }

  FdcGridCellRef? _findPageCell({required int rowOffset}) {
    return _navigation.findPageCell(
      rowOffset: rowOffset,
      rowCount: _rows.length,
      columns: _visibleColumns,
      editingCell: _editingCell,
      selectedCell: _selectedCell,
    );
  }

  bool _isCellEditable(FdcGridColumn<dynamic> column, int rowIndex) {
    if (FdcDataSetInternal.isReadOnly(widget.dataSet) || !column.isDataBound) {
      return false;
    }
    final metadata = _fieldMetadata(column.fieldName);
    if ((!_isLiveGridRowIndex(rowIndex) &&
            !_isEmptyInsertGridRowIndex(rowIndex)) ||
        !_rowContainsField(rowIndex, column.fieldName) ||
        metadata.isReadOnlyForEditing ||
        metadata.dataType == FdcDataType.guid) {
      return false;
    }
    return _navigation.isCellEditable(
      rows: _rows,
      options: widget.options,
      column: column,
      rowIndex: rowIndex,
      canEditRow: _guardedCanEditRow,
      canEditColumn: _guardedCanEditColumn,
    );
  }

  bool _isTabNavigableCell(FdcGridColumn<dynamic> column, int rowIndex) {
    if (!column.isDataBound) {
      return false;
    }
    return column.visible &&
        column.showIndicator &&
        column.tabStop &&
        (_isLiveGridRowIndex(rowIndex) ||
            _isEmptyInsertGridRowIndex(rowIndex)) &&
        _rowContainsField(rowIndex, column.fieldName);
  }

  bool _shouldAppendAfterLeavingCell(FdcGridCellRef cell) {
    final columns = _visibleColumns;
    if (cell.rowIndex != _rows.length - 1 ||
        cell.columnIndex < 0 ||
        cell.columnIndex >= columns.length) {
      return false;
    }

    final column = columns[cell.columnIndex];
    if (!_isCellEditable(column, cell.rowIndex)) {
      return false;
    }

    final order = _visualNavigationColumnIndexes();
    if (!order.contains(cell.columnIndex)) {
      return false;
    }

    return !_navigation.hasLaterCellInOrder(
      columnOrder: order,
      fromColumnIndex: cell.columnIndex,
      canUseColumn: (columnIndex) {
        final nextColumn = columns[columnIndex];
        return nextColumn.showIndicator &&
            nextColumn.isDataBound &&
            _rowContainsField(cell.rowIndex, nextColumn.fieldName);
      },
    );
  }

  bool _shouldAppendAfterLeavingTabCell(FdcGridCellRef cell) {
    final columns = _visibleColumns;
    if (cell.rowIndex != _rows.length - 1 ||
        cell.columnIndex < 0 ||
        cell.columnIndex >= columns.length) {
      return false;
    }

    final column = columns[cell.columnIndex];
    if (!_isTabNavigableCell(column, cell.rowIndex)) {
      return false;
    }

    final order = _tabTraversalColumnIndexes();
    if (!order.contains(cell.columnIndex)) {
      return false;
    }

    return !_navigation.hasLaterCellInOrder(
      columnOrder: order,
      fromColumnIndex: cell.columnIndex,
      canUseColumn: (columnIndex) =>
          _isTabNavigableCell(columns[columnIndex], cell.rowIndex),
    );
  }

  void _appendEmptyRowAndFocusFirstField({bool useTabOrder = false}) {
    final columns = _visibleColumns;
    final dataColumns = columns;
    final rowIndex = _rows.length;
    final fieldNames = [for (final column in dataColumns) column.fieldName];
    final transientRow = FdcGridTransientRow(
      rowIndex: rowIndex,
      fieldNames: fieldNames,
      valueResolver: (_) => null,
    );
    final hasEditableCell = columns.any(
      (column) => _isCellEditableForRow(column, rowIndex, transientRow),
    );
    if (!hasEditableCell) {
      return;
    }

    final visibleRowIndex = _appendDataSetRow();
    if (visibleRowIndex < 0 || visibleRowIndex >= _rows.length) {
      return;
    }

    final firstColumnIndex = useTabOrder
        ? _firstTabColumnIndexForRow(visibleRowIndex)
        : _firstEditableColumnIndexForRow(visibleRowIndex);
    if (firstColumnIndex < 0) {
      return;
    }

    _setGridState(() {
      _markColumnWidthsDirty();
      _selectedRowIndex = visibleRowIndex;
      final next = _cellRef(visibleRowIndex, firstColumnIndex);
      _selectedCell = next;
      // ArrowDown auto-append should only select the first editable cell.
      // `autoEdit` means that typing into the selected cell starts editing
      // automatically; it must not pre-open the inplace editor while focus
      // still belongs to the grid.
      _clearEditingOriginalValue();
      _editingCell = null;
    });
    _scrollRowIntoViewAfterLayout(visibleRowIndex);
    _scrollToFirstColumnAfterLayout();
    _revealColumnIfNeededAfterLayout(firstColumnIndex);

    if (widget.options.autoEdit) {
      _focusGridForAutoEditAfterLayout();
    } else {
      _focusGridForSelectedCell();
    }
  }

  int _firstEditableColumnIndexForRow(int rowIndex) {
    final columns = _visibleColumns;
    for (final columnIndex in _visualNavigationColumnIndexes()) {
      final column = columns[columnIndex];
      if (_isCellEditable(column, rowIndex)) {
        return columnIndex;
      }
    }
    return -1;
  }

  int _firstTabColumnIndexForRow(int rowIndex) {
    final columns = _visibleColumns;
    for (final columnIndex in _tabTraversalColumnIndexes()) {
      final column = columns[columnIndex];
      if (_isTabNavigableCell(column, rowIndex)) {
        return columnIndex;
      }
    }
    return -1;
  }

  bool _isCellEditableForRow(
    FdcGridColumn<dynamic> column,
    int rowIndex,
    FdcGridRowContext row,
  ) {
    if (FdcDataSetInternal.isReadOnly(widget.dataSet) || !column.isDataBound) {
      return false;
    }
    final metadata = _fieldMetadata(column.fieldName);
    if (!row.containsField(column.fieldName) ||
        metadata.isReadOnlyForEditing ||
        metadata.dataType == FdcDataType.guid) {
      return false;
    }
    return _navigation.isCellEditableForRow(
      options: widget.options,
      column: column,
      rowIndex: rowIndex,
      row: row,
      canEditRow: _guardedCanEditRow,
      canEditColumn: _guardedCanEditColumn,
    );
  }

  bool _rowContainsField(int rowIndex, String fieldName) {
    if (!_isLiveGridRowIndex(rowIndex) &&
        !_isEmptyInsertGridRowIndex(rowIndex)) {
      return false;
    }
    return _rows[rowIndex].containsField(fieldName);
  }

  FdcGridCanEditRow? get _guardedCanEditRow {
    final callback = widget.canEditRow;
    if (callback == null) {
      return null;
    }

    return (rowIndex, row) {
      var allowed = false;
      _runGridAppCallback(() {
        allowed = callback(rowIndex, row);
      });
      return allowed;
    };
  }

  FdcGridCanEditColumn? get _guardedCanEditColumn {
    final callback = widget.canEditColumn;
    if (callback == null) {
      return null;
    }

    return (rowIndex, column, row) {
      var allowed = false;
      _runGridAppCallback(() {
        allowed = callback(rowIndex, column, row);
      });
      return allowed;
    };
  }
}
