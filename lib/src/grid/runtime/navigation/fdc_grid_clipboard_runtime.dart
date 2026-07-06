// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridClipboardRuntime on _FdcGridState {
  bool _shouldHandleGridCopyShortcut() {
    if (_editingCell != null || !_gridCellHasPrimaryFocus) {
      return false;
    }
    if (_rangeSelectionSession.shouldHandleCopyShortcut(
      enabled: _rangeSelectionEnabled,
      copyEnabled: _rangeSelectionCopyEnabled,
      hasActiveCellEditor: false,
      gridCellHasPrimaryFocus: true,
    )) {
      return true;
    }
    return _selectedClipboardCell() != null;
  }

  bool _shouldHandleGridPasteShortcut() {
    if (_editingCell != null || !_gridCellHasPrimaryFocus) {
      return false;
    }
    if (_rangeSelectionSession.shouldHandlePasteShortcut(
      enabled: _rangeSelectionEnabled,
      pasteEnabled: _rangeSelectionPasteEnabled,
      hasActiveCellEditor: false,
      gridCellHasPrimaryFocus: true,
    )) {
      return true;
    }
    return _selectedClipboardCell(requireEditable: true) != null;
  }

  Future<void> _copySelectedCellToClipboard() async {
    final bounds = _selectedRangeBounds();
    if (_rangeSelectionCopyEnabled && bounds != null) {
      final columns = _visibleColumns;
      await _rangeSelectionSession.copySelectionToClipboard(
        bounds: bounds,
        rowCount: _rows.length,
        columnCount: columns.length,
        readCellText: (rowIndex, columnIndex) {
          final column = columns[columnIndex];
          if (!column.isDataBound) {
            return '';
          }
          return _cellClipboardText(rowIndex, columnIndex, column);
        },
      );
      return;
    }

    final target = _selectedClipboardCell();
    if (target == null) {
      return;
    }
    final text = _cellClipboardText(
      target.cell.rowIndex,
      target.cell.columnIndex,
      target.column,
    );
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> _pasteClipboardIntoSelectedCell() async {
    final target = _selectedClipboardCell(requireEditable: true);
    if (target == null) {
      return;
    }

    final bounds = _selectedRangeBounds();
    if (_rangeSelectionPasteEnabled && bounds != null) {
      final columns = _visibleColumns;
      final plan = await _rangeSelectionSession.readClipboardPastePlan(
        bounds: bounds,
        rowCount: _rows.length,
        columnCount: columns.length,
        fillSingleValue: _rangeSelectionFillSingleValueEnabled,
        isCellEditable: (rowIndex, columnIndex) {
          final column = columns[columnIndex];
          return column.isDataBound && _isCellEditable(column, rowIndex);
        },
        parseCellText: (rowIndex, columnIndex, text) {
          final column = columns[columnIndex];
          return _parseClipboardCellText(rowIndex, columnIndex, column, text);
        },
      );
      if (!mounted || plan == null) {
        return;
      }
      if (plan.errorText != null) {
        _showGridOperationErrorDialog(plan.errorText!);
        return;
      }

      _clearPendingEditText();
      for (final update in plan.updates) {
        _updateCell(update.rowIndex, columns[update.columnIndex], update.value);
      }
      return;
    }

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || data == null) {
      return;
    }
    final text = _firstClipboardCellText(data.text ?? '');
    final parsed = _parseClipboardCellText(
      target.cell.rowIndex,
      target.cell.columnIndex,
      target.column,
      text,
    );
    if (parsed.errorText != null) {
      _showGridOperationErrorDialog(parsed.errorText!);
      return;
    }
    _clearPendingEditText();
    _updateCell(target.cell.rowIndex, target.column, parsed.value);
  }

  String _cellClipboardText(
    int rowIndex,
    int columnIndex,
    FdcGridColumn<dynamic> column,
  ) {
    final cell = _cellRef(rowIndex, columnIndex);
    final value = _dataSetValueAt(rowIndex, column);
    return value == null
        ? ''
        : _valueFormatter.format(
            column,
            value,
            runtimeColumnId: cell.runtimeColumnId,
            forEditing: true,
          );
  }

  ({Object? value, String? errorText}) _parseClipboardCellText(
    int rowIndex,
    int columnIndex,
    FdcGridColumn<dynamic> column,
    String text,
  ) {
    final metadata = _fieldMetadata(column.fieldName);
    final cell = _cellRef(rowIndex, columnIndex);
    final parsed =
        FdcFieldValueCodec(
          settings: column.formatSettings ?? _formatSettings,
        ).parseGridTextForCommit(
          column,
          text,
          runtimeColumnId: cell.runtimeColumnId,
          decimalScale: metadata.decimalScale,
          decimalPrecision: metadata.decimalPrecision,
        );
    return (value: parsed.value, errorText: parsed.errorText);
  }

  String _firstClipboardCellText(String text) {
    if (text.isEmpty) {
      return '';
    }
    final firstLineEnd = text.indexOf(RegExp(r'\r?\n'));
    final firstLine = firstLineEnd == -1
        ? text
        : text.substring(0, firstLineEnd);
    final firstTab = firstLine.indexOf('\t');
    return firstTab == -1 ? firstLine : firstLine.substring(0, firstTab);
  }

  ({FdcGridCellRef cell, FdcGridColumn<dynamic> column})?
  _selectedClipboardCell({bool requireEditable = false}) {
    final cell = _selectedCell;
    final columns = _visibleColumns;
    if (cell == null ||
        cell.rowIndex < 0 ||
        cell.rowIndex >= _rows.length ||
        cell.columnIndex < 0 ||
        cell.columnIndex >= columns.length) {
      return null;
    }

    final column = columns[cell.columnIndex];
    if (!column.isDataBound ||
        (requireEditable && !_isCellEditable(column, cell.rowIndex))) {
      return null;
    }
    return (cell: cell, column: column);
  }
}
