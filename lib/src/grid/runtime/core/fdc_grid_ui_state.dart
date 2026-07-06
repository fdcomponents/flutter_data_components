// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Owns short-lived mutable UI state for one concrete grid instance.
///
/// Durable runtime collaborators live in `_FdcGridRuntimeController`. This
/// holder groups transient interaction/session state that is still exposed
/// through private `_FdcGridState` compatibility accessors while the
/// extension-based runtime is stabilized.
class _FdcGridUiState {
  final _FdcGridHeaderUiState header = _FdcGridHeaderUiState();
  final _FdcGridCellUiState cells = _FdcGridCellUiState();
  final _FdcGridScrollUiState scroll = _FdcGridScrollUiState();
  final _FdcGridColumnResizeUiState columnResize =
      _FdcGridColumnResizeUiState();
  final _FdcGridToolbarSearchUiState toolbarSearch =
      _FdcGridToolbarSearchUiState();
  final _FdcGridDataUiState data = _FdcGridDataUiState();
  final _FdcGridNavigationUiState navigation = _FdcGridNavigationUiState();

  void dispose() {
    header.dispose();
    columnResize.dispose();
    toolbarSearch.dispose();
  }
}
