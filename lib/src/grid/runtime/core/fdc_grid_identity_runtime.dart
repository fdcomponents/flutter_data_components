// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridIdentityRuntime on _FdcGridState {
  List<FdcGridColumn<dynamic>> get _visibleColumns {
    return _visibleColumnsCache;
  }

  FdcGridFieldMetadata _fieldMetadata(String fieldName) {
    return _fieldMetadataCache.putIfAbsent(
      fieldName,
      () => FdcGridFieldMetadata.fromDataSet(widget.dataSet, fieldName),
    );
  }

  void _clearFieldMetadataCache() {
    _fieldMetadataCache.clear();
    _columnCellRenderInfoCache.clear();
  }

  FdcDataType _fieldDataTypeFor(FdcGridColumn<dynamic> column) {
    if (!column.isDataBound) {
      return column.dataType;
    }
    return _fieldMetadata(column.fieldName).dataType ?? column.dataType;
  }

  FdcGridColumnPin _effectiveColumnPin(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  ) {
    if (_isGroupedColumn(column)) {
      return FdcGridColumnPin.none;
    }
    return _runtimeColumnPinOverrides[runtimeColumnId] ?? column.pin;
  }

  bool _isGroupedColumn(FdcGridColumn<dynamic> column) {
    return column.groupId != null;
  }

  String _columnLabel(FdcGridColumn<dynamic> column) {
    final columnLabel = column.label;
    if (columnLabel != null && columnLabel.isNotEmpty) {
      return columnLabel;
    }

    if (column.isDataBound) {
      final fieldLabel = _fieldMetadata(column.fieldName).label;
      if (fieldLabel != null && fieldLabel.isNotEmpty) {
        return fieldLabel;
      }
    }

    return _runtime.domains.columns.columns.columnLabel(column);
  }

  FdcGridColumn<dynamic>? _columnByRuntimeColumnId(
    FdcColumnIdentity runtimeColumnId,
  ) {
    final columnIndex = _visibleRuntimeColumnIdsCache.indexOf(runtimeColumnId);
    if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
      return null;
    }
    return _visibleColumns[columnIndex];
  }

  FdcColumnIdentity _columnIdentityForKey(FdcColumnIdentityKey key) {
    return _columnIdentitiesByKey.putIfAbsent(
      key,
      () => FdcColumnIdentity(_nextGridColumnIdentityValue++),
    );
  }

  FdcColumnIdentity? _runtimeColumnIdAt(int columnIndex) {
    if (columnIndex < 0 ||
        columnIndex >= _visibleRuntimeColumnIdsCache.length) {
      return null;
    }
    return _visibleRuntimeColumnIdsCache[columnIndex];
  }

  FdcColumnIdentity? _runtimeColumnIdForColumn(FdcGridColumn<dynamic> column) {
    final columnIndex = _visibleColumnsCache.indexOf(column);
    return columnIndex == -1 ? null : _runtimeColumnIdAt(columnIndex);
  }

  int? _recordIdForGridRow(int rowIndex) {
    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null) {
      return null;
    }
    return FdcDataSetInternal.recordIdAt(widget.dataSet, sourceIndex);
  }

  FdcGridCellRef _cellRef(int rowIndex, int columnIndex) {
    return FdcGridCellRef(
      rowIndex,
      columnIndex,
      recordId: _recordIdForGridRow(rowIndex),
      runtimeColumnId: _runtimeColumnIdAt(columnIndex),
    );
  }

  FdcGridCellRef? _enrichCellRef(FdcGridCellRef? cell) {
    if (cell == null) {
      return null;
    }
    return _cellRef(cell.rowIndex, cell.columnIndex);
  }

  FdcGridCellRef? _resolveCellRef(FdcGridCellRef? cell) {
    if (cell == null) {
      return null;
    }

    if (cell.hasCellIdentity) {
      final columnIndex = _visibleRuntimeColumnIdsCache.indexOf(
        cell.runtimeColumnId!,
      );
      if (columnIndex == -1) {
        return null;
      }

      for (var rowIndex = 0; rowIndex < _rows.length; rowIndex++) {
        if (_recordIdForGridRow(rowIndex) == cell.recordId) {
          return _cellRef(rowIndex, columnIndex);
        }
      }
      return null;
    }

    if (!_cells.isValidCell(
      cell,
      rowCount: _rows.length,
      columnCount: _visibleColumns.length,
    )) {
      return null;
    }
    return _enrichCellRef(cell);
  }
}
