// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Owns transient dataset-operation dialog/focus state for the grid.
///
/// Dataset data remains owned by `FdcDataSet`; this holder only tracks
/// short-lived UI guards around delete confirmation and validation/error
/// dialogs opened by grid-driven dataset operations.
class _FdcGridDataOperationUiState {
  bool showingGridOperationErrorDialog = false;
  Future<void>? gridOperationErrorDialogFuture;
  bool focusActiveEditorAfterGridErrorDialog = false;
  bool showingDeleteConfirmDialog = false;
  String? lastShownGridOperationErrorSignature;
  bool pendingAppendAfterImmediatePost = false;
  bool pendingAppendUsesTabOrder = false;
  FdcGridCellRef? pendingCellMoveAfterImmediatePost;
  bool pendingCellMoveEditIfPossible = false;
  bool preferLeadingColumnForPendingMove = false;
  FdcGridFocusChangeReason pendingCellMoveFocusReason =
      FdcGridFocusChangeReason.keyboard;
  bool suppressRevealForPendingMove = false;
  bool pendingCellMoveHasValueWrite = false;
  Object? pendingCellMoveValueWrite;
}
