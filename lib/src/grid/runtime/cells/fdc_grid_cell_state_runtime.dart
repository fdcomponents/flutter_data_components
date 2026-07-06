// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateCellStateRuntime on _FdcGridState {
  int? _sourceRowIndex(int rowIndex) {
    // The grid row index is the dataset view row index. Treat the dataset view
    // as the source of truth, not a previously built sliver child or cached
    // interaction cell. This prevents stale row indexes from surviving a
    // delete/cancel of the last inserted row.
    if (!_isLiveGridRowIndex(rowIndex)) {
      return null;
    }
    return rowIndex;
  }

  void _validateCellState() {
    if (_selectedRowIndex != null && _selectedRowIndex! >= _rows.length) {
      _selectedRowIndex = _rows.isEmpty ? null : _rows.length - 1;
    }
    _selectedCell = _resolveCellRef(_selectedCell);
    _editingCell = _resolveCellRef(_editingCell);
    _editAtEndCell = _resolveCellRef(_editAtEndCell);
    _pendingEditCell = _resolveCellRef(_pendingEditCell);
    if (_pendingEditCell == null) {
      _clearPendingEditText();
    }
  }
}
