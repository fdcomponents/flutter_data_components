// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Owns transient cell selection/editing interaction state for one grid.
///
/// The values remain exposed through `_FdcGridState` private accessors while the
/// extension-based runtime is still being stabilized. Keeping the storage in a
/// dedicated holder makes the Flutter host less state-heavy without changing
/// cell navigation, editing, keyboard, or pointer behavior.
class _FdcGridCellInteractionUiState {
  String? pendingEditText;
  FdcGridCellRef? pendingEditCell;
  int? selectedRowIndex;
  FdcGridCellRef? selectedCell;
  FdcGridCellRef? editingCell;
  FdcGridCellRef? editAtEndCell;
  FdcGridCellRef? editingOriginalCell;
  Object? editingOriginalValue;
  bool hasEditingOriginalValue = false;
  FdcGridCellRef? lastTappedCell;
  DateTime? lastCellTapTime;
  _FdcGridCellControlPointerViewport? cellControlPointerViewport;
  bool suppressKeyboardColumnReveal = false;
}

class _FdcGridCellControlPointerViewport {
  const _FdcGridCellControlPointerViewport({
    required this.rowIndex,
    required this.columnIndex,
    required this.horizontalOffset,
    required this.verticalOffset,
    required this.capturedAt,
  });

  final int rowIndex;
  final int columnIndex;
  final double horizontalOffset;
  final double verticalOffset;
  final DateTime capturedAt;
}
