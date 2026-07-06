// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../columns/fdc_column_base.dart';
import '../core/fdc_grid_events.dart';
import '../core/fdc_grid_options.dart';
import '../models/fdc_grid_cell_ref.dart';
import '../models/fdc_grid_layout_models.dart';
import '../models/fdc_grid_row_context.dart';
import '../runtime/data/fdc_grid_row_source.dart';

class FdcGridNavigationManager {
  FdcGridCellRef? findVerticalCell({
    required int rowOffset,
    required int rowCount,
    required List<FdcGridColumn<dynamic>> columns,
    required FdcGridCellRef? editingCell,
    required FdcGridCellRef? selectedCell,
  }) {
    final current = editingCell ?? selectedCell;
    if (current == null || columns.isEmpty) {
      return null;
    }

    final nextRowIndex = current.rowIndex + rowOffset;
    if (nextRowIndex < 0 || nextRowIndex >= rowCount) {
      return null;
    }

    final columnIndex = _nearestNavigableColumnIndex(
      columns,
      current.columnIndex,
    );
    if (columnIndex == null) {
      return null;
    }

    return FdcGridCellRef(nextRowIndex, columnIndex);
  }

  FdcGridCellRef? findPageCell({
    required int rowOffset,
    required int rowCount,
    required List<FdcGridColumn<dynamic>> columns,
    required FdcGridCellRef? editingCell,
    required FdcGridCellRef? selectedCell,
  }) {
    final current = editingCell ?? selectedCell;
    if (current == null || columns.isEmpty) {
      return null;
    }

    final targetRowIndex = (current.rowIndex + rowOffset)
        .clamp(0, rowCount - 1)
        .toInt();
    final columnIndex = _nearestNavigableColumnIndex(
      columns,
      current.columnIndex,
    );
    if (columnIndex == null) {
      return null;
    }

    return FdcGridCellRef(targetRowIndex, columnIndex);
  }

  List<int> visualColumnIndexes({
    required List<FdcGridColumn<dynamic>> columns,
    required FdcGridColumnBands bands,
  }) {
    final order = <int>[
      ...bands.pinnedLeft.columnIndexes,
      ...bands.scrollable.columnIndexes,
      ...bands.pinnedRight.columnIndexes,
    ];
    return [
      for (final columnIndex in order)
        if (_isNavigableColumnIndex(columns, columnIndex)) columnIndex,
    ];
  }

  List<int> tabTraversalColumnIndexes({
    required List<FdcGridColumn<dynamic>> columns,
    required FdcGridColumnBands bands,
  }) {
    final visualOrder = visualColumnIndexes(columns: columns, bands: bands);
    final entries = <FdcGridTabColumn>[];
    for (var visualIndex = 0; visualIndex < visualOrder.length; visualIndex++) {
      final columnIndex = visualOrder[visualIndex];
      final column = columns[columnIndex];
      if (!column.tabStop) {
        continue;
      }
      entries.add(
        FdcGridTabColumn(
          columnIndex: columnIndex,
          order: column.focusOrder ?? visualIndex,
          visualOrder: visualIndex,
        ),
      );
    }
    entries.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      if (byOrder != 0) {
        return byOrder;
      }
      return a.visualOrder.compareTo(b.visualOrder);
    });
    return [for (final entry in entries) entry.columnIndex];
  }

  int? boundaryColumnIndex(List<int> columnOrder, {required bool forward}) {
    if (columnOrder.isEmpty) {
      return null;
    }
    return forward ? columnOrder.first : columnOrder.last;
  }

  int? adjacentColumnIndex({
    required List<int> columnOrder,
    required int fromColumnIndex,
    required int columnOffset,
  }) {
    if (columnOrder.isEmpty) {
      return null;
    }

    final orderIndex = columnOrder.indexOf(fromColumnIndex);
    if (orderIndex < 0) {
      return _adjacentColumnIndexFromGap(
        columnOrder,
        fromColumnIndex: fromColumnIndex,
        columnOffset: columnOffset,
      );
    }

    final nextOrderIndex = orderIndex + columnOffset;
    if (nextOrderIndex < 0 || nextOrderIndex >= columnOrder.length) {
      return null;
    }
    return columnOrder[nextOrderIndex];
  }

  int? _adjacentColumnIndexFromGap(
    List<int> columnOrder, {
    required int fromColumnIndex,
    required int columnOffset,
  }) {
    if (columnOffset > 0) {
      for (final columnIndex in columnOrder) {
        if (columnIndex > fromColumnIndex) {
          return columnIndex;
        }
      }
      return null;
    }

    if (columnOffset < 0) {
      for (final columnIndex in columnOrder.reversed) {
        if (columnIndex < fromColumnIndex) {
          return columnIndex;
        }
      }
    }

    return null;
  }

  FdcGridCellRef? findNextCellInOrder({
    required int rowCount,
    required List<int> columnOrder,
    required FdcGridCellRef? current,
    required int fallbackRowIndex,
    required bool forward,
    required bool Function(int rowIndex, int columnIndex) canUseCell,
  }) {
    if (rowCount <= 0 || columnOrder.isEmpty) {
      return null;
    }

    final fallbackColumnIndex = forward ? -1 : columnOrder.length;
    final resolvedCurrent =
        current ?? FdcGridCellRef(fallbackRowIndex, fallbackColumnIndex);
    var rowIndex = resolvedCurrent.rowIndex;
    var orderIndex = columnOrder.indexOf(resolvedCurrent.columnIndex);

    if (orderIndex < 0) {
      orderIndex = forward ? -1 : columnOrder.length;
    }

    while (true) {
      if (forward) {
        orderIndex++;
        if (orderIndex >= columnOrder.length) {
          orderIndex = 0;
          rowIndex++;
        }
      } else {
        orderIndex--;
        if (orderIndex < 0) {
          orderIndex = columnOrder.length - 1;
          rowIndex--;
        }
      }

      if (rowIndex < 0 || rowIndex >= rowCount) {
        return null;
      }

      final columnIndex = columnOrder[orderIndex];
      if (canUseCell(rowIndex, columnIndex)) {
        return FdcGridCellRef(rowIndex, columnIndex);
      }
    }
  }

  bool hasLaterCellInOrder({
    required List<int> columnOrder,
    required int fromColumnIndex,
    required bool Function(int columnIndex) canUseColumn,
  }) {
    final orderIndex = columnOrder.indexOf(fromColumnIndex);
    if (orderIndex < 0) {
      return false;
    }

    for (var i = orderIndex + 1; i < columnOrder.length; i++) {
      if (canUseColumn(columnOrder[i])) {
        return true;
      }
    }
    return false;
  }

  bool _isNavigableColumnIndex(
    List<FdcGridColumn<dynamic>> columns,
    int columnIndex,
  ) {
    return columnIndex >= 0 &&
        columnIndex < columns.length &&
        columns[columnIndex].visible &&
        columns[columnIndex].showIndicator &&
        columns[columnIndex].isDataBound;
  }

  int? _nearestNavigableColumnIndex(
    List<FdcGridColumn<dynamic>> columns,
    int fromColumnIndex,
  ) {
    if (_isNavigableColumnIndex(columns, fromColumnIndex)) {
      return fromColumnIndex;
    }

    for (var distance = 1; distance <= columns.length; distance++) {
      final left = fromColumnIndex - distance;
      if (_isNavigableColumnIndex(columns, left)) {
        return left;
      }

      final right = fromColumnIndex + distance;
      if (_isNavigableColumnIndex(columns, right)) {
        return right;
      }
    }

    return null;
  }

  bool isCellEditable({
    required IFdcGridRowSource rows,
    required FdcGridOptions options,
    required FdcGridColumn<dynamic> column,
    required int rowIndex,
    required FdcGridCanEditRow? canEditRow,
    required FdcGridCanEditColumn? canEditColumn,
  }) {
    if (rowIndex < 0 || rowIndex >= rows.length) {
      return false;
    }

    return isCellEditableForRow(
      options: options,
      column: column,
      rowIndex: rowIndex,
      row: rows[rowIndex],
      canEditRow: canEditRow,
      canEditColumn: canEditColumn,
    );
  }

  bool isCellEditableForRow({
    required FdcGridOptions options,
    required FdcGridColumn<dynamic> column,
    required int rowIndex,
    required FdcGridRowContext row,
    required FdcGridCanEditRow? canEditRow,
    required FdcGridCanEditColumn? canEditColumn,
  }) {
    return !options.readOnly &&
        column.visible &&
        column.enabled &&
        column.isDataBound &&
        row.containsField(column.fieldName) &&
        !column.isEffectivelyReadOnly &&
        canEditCell(
          rowIndex: rowIndex,
          column: column,
          row: row,
          canEditRow: canEditRow,
          canEditColumn: canEditColumn,
        );
  }

  bool canEditCell({
    required int rowIndex,
    required FdcGridColumn<dynamic> column,
    required FdcGridRowContext row,
    required FdcGridCanEditRow? canEditRow,
    required FdcGridCanEditColumn? canEditColumn,
  }) {
    if (canEditRow == null && canEditColumn == null) {
      return true;
    }

    return (canEditRow?.call(rowIndex, row) ?? true) &&
        (canEditColumn?.call(rowIndex, column, row) ?? true);
  }
}

class FdcGridTabColumn {
  const FdcGridTabColumn({
    required this.columnIndex,
    required this.order,
    required this.visualOrder,
  });

  final int columnIndex;
  final int order;
  final int visualOrder;
}
