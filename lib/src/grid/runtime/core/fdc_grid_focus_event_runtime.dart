// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

class _FdcGridFocusSnapshot {
  const _FdcGridFocusSnapshot({
    required this.rowIndex,
    required this.row,
    required this.columnIndex,
    required this.column,
    required this.fieldName,
  });

  final int? rowIndex;
  final FdcGridRowContext? row;
  final int? columnIndex;
  final FdcGridColumn<dynamic>? column;
  final String? fieldName;
}

extension _FdcGridFocusEventRuntime on _FdcGridState {
  void _emitGridFocusEvents(
    _FdcGridFocusSnapshot from,
    _FdcGridFocusSnapshot to,
    FdcGridFocusChangeReason reason,
  ) {
    if (!_hasGridFocusEventListeners) {
      return;
    }
    final rowChanged = from.rowIndex != to.rowIndex;
    final columnChanged =
        from.columnIndex != to.columnIndex || from.fieldName != to.fieldName;

    if (!rowChanged && !columnChanged) {
      return;
    }

    final cellChanged = rowChanged || columnChanged;

    if (cellChanged && from.rowIndex != null && from.columnIndex != null) {
      final listener = widget.onCellExit;
      if (listener != null) {
        _runGridAppCallback(() {
          listener(
            _cellFocusContext(target: from, from: from, to: to, reason: reason),
          );
        });
      }
    }

    if (columnChanged && from.columnIndex != null) {
      final listener = widget.onColumnExit;
      if (listener != null) {
        _runGridAppCallback(() {
          listener(
            _columnFocusContext(
              target: from,
              from: from,
              to: to,
              row: from.row ?? to.row,
              rowIndex: from.rowIndex ?? to.rowIndex,
              reason: reason,
            ),
          );
        });
      }
    }

    if (rowChanged && from.rowIndex != null) {
      final listener = widget.onRowExit;
      if (listener != null) {
        _runGridAppCallback(() {
          listener(
            _rowFocusContext(
              target: from,
              from: from,
              to: to,
              column: from.column ?? to.column,
              columnIndex: from.columnIndex ?? to.columnIndex,
              fieldName: from.fieldName ?? to.fieldName,
              reason: reason,
            ),
          );
        });
      }
    }

    if (rowChanged && to.rowIndex != null) {
      final listener = widget.onRowEnter;
      if (listener != null) {
        _runGridAppCallback(() {
          listener(
            _rowFocusContext(
              target: to,
              from: from,
              to: to,
              column: to.column ?? from.column,
              columnIndex: to.columnIndex ?? from.columnIndex,
              fieldName: to.fieldName ?? from.fieldName,
              reason: reason,
            ),
          );
        });
      }
    }

    if (columnChanged && to.columnIndex != null) {
      final listener = widget.onColumnEnter;
      if (listener != null) {
        _runGridAppCallback(() {
          listener(
            _columnFocusContext(
              target: to,
              from: from,
              to: to,
              row: to.row ?? from.row,
              rowIndex: to.rowIndex ?? from.rowIndex,
              reason: reason,
            ),
          );
        });
      }
    }

    if (cellChanged && to.rowIndex != null && to.columnIndex != null) {
      final listener = widget.onCellEnter;
      if (listener != null) {
        _runGridAppCallback(() {
          listener(
            _cellFocusContext(target: to, from: from, to: to, reason: reason),
          );
        });
      }
    }
  }

  bool get _hasGridFocusEventListeners =>
      widget.onRowExit != null ||
      widget.onRowEnter != null ||
      widget.onColumnExit != null ||
      widget.onColumnEnter != null ||
      widget.onCellExit != null ||
      widget.onCellEnter != null;

  _FdcGridFocusSnapshot _currentGridFocusSnapshot() {
    final cell = _selectedCell;
    if (cell != null) {
      return _focusSnapshotForCell(cell);
    }

    final rowIndex = _selectedRowIndex;
    if (rowIndex != null && _isLiveGridRowIndex(rowIndex)) {
      return _FdcGridFocusSnapshot(
        rowIndex: rowIndex,
        row: _rows.rowAt(rowIndex),
        columnIndex: null,
        column: null,
        fieldName: null,
      );
    }

    return const _FdcGridFocusSnapshot(
      rowIndex: null,
      row: null,
      columnIndex: null,
      column: null,
      fieldName: null,
    );
  }

  _FdcGridFocusSnapshot _focusSnapshotForCell(FdcGridCellRef? cell) {
    final resolvedCell = _resolveCellRef(cell);
    if (resolvedCell == null) {
      return const _FdcGridFocusSnapshot(
        rowIndex: null,
        row: null,
        columnIndex: null,
        column: null,
        fieldName: null,
      );
    }

    FdcGridRowContext? row;
    if (_isLiveGridRowIndex(resolvedCell.rowIndex)) {
      row = _rows.rowAt(resolvedCell.rowIndex);
    }

    FdcGridColumn<dynamic>? column;
    String? fieldName;
    if (resolvedCell.columnIndex >= 0 &&
        resolvedCell.columnIndex < _visibleColumns.length) {
      column = _visibleColumns[resolvedCell.columnIndex];
      fieldName = column.isDataBound ? column.fieldName : null;
    }

    return _FdcGridFocusSnapshot(
      rowIndex: resolvedCell.rowIndex,
      row: row,
      columnIndex: resolvedCell.columnIndex,
      column: column,
      fieldName: fieldName,
    );
  }

  FdcFieldFocusContext<dynamic> _rowFocusContext({
    required _FdcGridFocusSnapshot target,
    required _FdcGridFocusSnapshot from,
    required _FdcGridFocusSnapshot to,
    required int? columnIndex,
    required FdcGridColumn<dynamic>? column,
    required String? fieldName,
    required FdcFieldFocusChangeReason reason,
  }) {
    return _fieldFocusContext(
      target: target,
      from: from,
      to: to,
      columnIndex: columnIndex,
      column: column,
      fieldName: fieldName,
      reason: reason,
    );
  }

  FdcFieldFocusContext<dynamic> _columnFocusContext({
    required _FdcGridFocusSnapshot target,
    required _FdcGridFocusSnapshot from,
    required _FdcGridFocusSnapshot to,
    required int? rowIndex,
    required FdcGridRowContext? row,
    required FdcFieldFocusChangeReason reason,
  }) {
    return _fieldFocusContext(
      target: target,
      from: from,
      to: to,
      rowIndex: rowIndex,
      row: row,
      reason: reason,
    );
  }

  FdcFieldFocusContext<dynamic> _cellFocusContext({
    required _FdcGridFocusSnapshot target,
    required _FdcGridFocusSnapshot from,
    required _FdcGridFocusSnapshot to,
    required FdcFieldFocusChangeReason reason,
  }) {
    return _fieldFocusContext(
      target: target,
      from: from,
      to: to,
      reason: reason,
    );
  }

  FdcFieldFocusContext<dynamic> _fieldFocusContext({
    required _FdcGridFocusSnapshot target,
    required _FdcGridFocusSnapshot from,
    required _FdcGridFocusSnapshot to,
    required FdcFieldFocusChangeReason reason,
    int? rowIndex,
    FdcGridRowContext? row,
    int? columnIndex,
    FdcGridColumn<dynamic>? column,
    String? fieldName,
  }) {
    final resolvedRow = row ?? target.row;
    final resolvedColumn = column ?? target.column;
    final resolvedFieldName = fieldName ?? target.fieldName;
    return FdcFieldFocusContext<dynamic>(
      dataSet: widget.dataSet,
      host: FdcFieldEventHost.grid,
      rowIndex: rowIndex ?? target.rowIndex,
      columnIndex: columnIndex ?? target.columnIndex,
      row: resolvedRow,
      column: resolvedColumn,
      fieldName: resolvedFieldName,
      field:
          resolvedFieldName == null ||
              !widget.dataSet.hasField(resolvedFieldName)
          ? null
          : widget.dataSet.fieldDef<FdcFieldDef>(resolvedFieldName),
      value: resolvedRow == null || resolvedFieldName == null
          ? null
          : resolvedRow.valueOf(resolvedFieldName),
      rawValue: resolvedRow == null || resolvedFieldName == null
          ? null
          : resolvedRow.valueOf(resolvedFieldName),
      fromRowIndex: from.rowIndex,
      toRowIndex: to.rowIndex,
      fromColumnIndex: from.columnIndex,
      toColumnIndex: to.columnIndex,
      fromFieldName: from.fieldName,
      toFieldName: to.fieldName,
      reason: reason,
      valueOf: resolvedRow?.valueOf,
    );
  }
}
