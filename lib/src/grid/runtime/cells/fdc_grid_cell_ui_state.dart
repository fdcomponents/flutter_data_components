// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Groups transient cell/editing UI state for one concrete grid instance.
///
/// Durable cell/editing collaborators live in `_FdcGridRuntimeDomains.cells`
/// and `_FdcGridRuntimeDomains.editing`. This holder keeps short-lived
/// selection, pending edit, active edit, and tap-session state together so the
/// root UI state follows the same domain shape as the durable runtime map.
class _FdcGridCellUiState {
  final _FdcGridCellInteractionUiState interaction =
      _FdcGridCellInteractionUiState();
}
