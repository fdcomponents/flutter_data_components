// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';

import '../columns/fdc_grid_columns.dart';
import '../editors/fdc_grid_cell_editor.dart';
import '../models/fdc_grid_cell_ref.dart';

class FdcGridEditorKeyManager {
  final Map<String, GlobalKey<FdcGridCellEditorState>> _cellEditorKeys = {};

  GlobalKey<FdcGridCellEditorState> keyForCell(FdcGridCellRef cell) {
    final key = cell.hasCellIdentity
        ? '${cell.recordId}::${cell.runtimeColumnId}'
        : '${cell.rowIndex}::${cell.columnIndex}';
    return _cellEditorKeys.putIfAbsent(
      key,
      GlobalKey<FdcGridCellEditorState>.new,
    );
  }

  FdcGridCellEditorState? activeEditorState({
    required FdcGridCellRef? editingCell,
    required int rowCount,
    required List<FdcGridColumn<dynamic>> columns,
  }) {
    final cell = editingCell;
    if (cell == null ||
        cell.rowIndex < 0 ||
        cell.rowIndex >= rowCount ||
        cell.columnIndex < 0 ||
        cell.columnIndex >= columns.length) {
      return null;
    }

    return keyForCell(cell).currentState;
  }
}
