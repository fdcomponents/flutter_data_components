// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

class _FdcGridScrollViewportUiState {
  int visibleRowCount = 1;
  double visibleRowsViewportHeight = 0.0;
  int? pendingScrollbarSelectionRowIndex;
  double bodyVerticalDragDistance = 0.0;
  double bodyVerticalDragStartOffset = 0.0;
  int verticalSettleGeneration = 0;
  int verticalOffsetRestoreGeneration = 0;
}
