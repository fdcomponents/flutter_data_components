// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Groups all short-lived mutable header UI state for one grid instance.
///
/// Header filter state and header interaction state are kept separate inside
/// this holder because their lifecycles differ, but exposing them through one
/// header UI boundary keeps the root grid UI-state map aligned with the runtime
/// domain structure.
class _FdcGridHeaderUiState {
  final _FdcGridHeaderFilterUiState filter = _FdcGridHeaderFilterUiState();
  final _FdcGridHeaderInteractionUiState interaction =
      _FdcGridHeaderInteractionUiState();

  void dispose() {
    filter.dispose();
    interaction.dispose();
  }
}
