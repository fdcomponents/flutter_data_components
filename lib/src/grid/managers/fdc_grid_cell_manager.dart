// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../models/fdc_column_identity.dart';
import '../models/fdc_grid_cell_ref.dart';

class FdcGridCellManager {
  FdcColumnIdentity? runtimeColumnIdForCell(
    FdcGridCellRef? cell,
    List<FdcColumnIdentity> runtimeColumnIds,
  ) {
    if (cell == null) {
      return null;
    }
    if (cell.runtimeColumnId != null) {
      return cell.runtimeColumnId;
    }
    if (cell.columnIndex < 0 || cell.columnIndex >= runtimeColumnIds.length) {
      return null;
    }
    return runtimeColumnIds[cell.columnIndex];
  }

  FdcGridCellRef? cellForRuntimeColumnId(
    FdcGridCellRef? cell,
    FdcColumnIdentity? runtimeColumnId,
    List<FdcColumnIdentity> runtimeColumnIds,
  ) {
    if (cell == null || runtimeColumnId == null) {
      return cell;
    }
    final columnIndex = runtimeColumnIds.indexOf(runtimeColumnId);
    if (columnIndex == -1) {
      return null;
    }
    return FdcGridCellRef(
      cell.rowIndex,
      columnIndex,
      recordId: cell.recordId,
      runtimeColumnId: runtimeColumnId,
    );
  }

  bool isValidCell(
    FdcGridCellRef? cell, {
    required int rowCount,
    required int columnCount,
  }) {
    return cell != null &&
        cell.rowIndex >= 0 &&
        cell.rowIndex < rowCount &&
        cell.columnIndex >= 0 &&
        cell.columnIndex < columnCount;
  }
}
