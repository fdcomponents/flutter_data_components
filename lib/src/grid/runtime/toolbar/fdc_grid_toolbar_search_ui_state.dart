// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Owns transient toolbar-search async generation state.
///
/// The search controller itself is a durable runtime service owned by
/// `_FdcGridRuntimeController`; this holder only tracks short-lived async
/// generation guards for search/clear requests.
class _FdcGridToolbarSearchUiState {
  int generation = 0;

  // Serializes async toolbar-search applies so rapid typing/clearing cannot
  // overlap adapter-backed page loads. If input changes while an apply is
  // active, only the latest pending operation is replayed after the current
  // one finishes.
  bool applyInFlight = false;
  Future<void> Function()? queuedApply;

  void dispose() {
    applyInFlight = false;
    queuedApply = null;
  }
}
