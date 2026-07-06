// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridRowBuildRuntime on _FdcGridState {
  Widget _buildRow(
    BuildContext context,
    FdcGridColumnBandLayout columnLayout,
    int rowIndex,
    FdcValueFormatter valueFormatter,
  ) {
    return FdcGridRowWidget(
      key: _rowWidgetKey(rowIndex),
      columnLayout: columnLayout,
      rowIndex: rowIndex,
      rowHeight: widget.options.resolvedRowHeight,
      animateColumnReorder: _draggingColumnIndex != null,
      interactionState: _interactionState,
      selectedRowBackgroundColor: _selectedRowBackgroundColor(),
      callbacks: _cellCallbacks,
      detailExpanderColumnId: _detailExpanderColumnId,
      canExpandDetail: _canExpandDetailRow(rowIndex),
      detailExpanded: _isDetailRowVisuallyExpanded(rowIndex),
      onToggleDetail: () => _toggleDetailRow(rowIndex),
      cellModelBuilder: (context, column, rowIndex, columnIndex, columnWidth) {
        return _buildCellModel(
          context,
          column,
          rowIndex,
          columnIndex,
          columnWidth,
          valueFormatter,
        );
      },
    );
  }

  FdcGridCellCallbacks _createCellCallbacks() {
    return FdcGridCellCallbacks(
      onCellPointerTap: _handleCellPointerTap,
      onCellValueChanged: (column, rowIndex, value) {
        _clearPendingEditText();
        final accepted = _updateCell(rowIndex, column, value);
        if (accepted && column.effectiveEditor == FdcEditorType.combo) {
          _cancelActiveCellEditing(value, restoreValue: false);
        }
        return accepted;
      },
      onLookup: _lookupCellValue,
      onCellFieldValue: (rowIndex, recordId, fieldName) {
        return _dataSetFieldValueAt(
          _resolveLiveRowIndex(rowIndex, recordId),
          fieldName,
        );
      },
      onCellFieldValueChanged:
          (rowIndex, recordId, columnIndex, fieldName, value) {
            _clearPendingEditText();
            return _updateFieldFromCell(
              rowIndex,
              recordId,
              columnIndex,
              fieldName,
              value,
            );
          },
      onMoveNext: _moveToNextCell,
      onMovePrevious: _moveToPreviousCell,
      onMoveNextTab: _moveToNextTabCell,
      onMovePreviousTab: _moveToPreviousTabCell,
      onMoveDown: _moveToNextRow,
      onMoveUp: _moveToPreviousRow,
      onMovePageDown: _movePageDown,
      onMovePageUp: _movePageUp,
      onBeginKeyboardMoveScrollGuard: () => _beginKeyboardMoveGuard(),
      onCancelEditing: _cancelActiveCellEditing,
      onCellControlPointerDown: _captureCellControlPointerViewport,
      onBooleanCellChanged: _setBooleanCell,
      onPickCellValue: _pickCellValue,
      onRowIndicatorSelected: _setRowIndicatorSelected,
      onActionActivateRow: _activateActionRow,
      onActionDeleteRow: _deleteActionRow,
    );
  }

  Key _rowWidgetKey(int rowIndex) {
    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null) {
      return ValueKey<String>('fdc-grid-row-index-$rowIndex');
    }

    try {
      final recordId = FdcDataSetInternal.recordIdAt(
        widget.dataSet,
        sourceIndex,
      );
      return ValueKey<String>('fdc-grid-row-record-$recordId');
      // ignore: avoid_catching_errors
    } on RangeError {
      return ValueKey<String>('fdc-grid-row-index-$rowIndex');
    }
  }
}
