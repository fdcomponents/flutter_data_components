// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Owns transient scroll-domain UI state for one concrete grid instance.
///
/// Durable scroll services live in `_FdcGridRuntimeDomains.scroll`. This holder
/// groups short-lived viewport and gesture/session state used by scroll,
/// reveal, layout, and navigation runtime extensions.
class _FdcGridScrollUiState {
  final _FdcGridScrollViewportUiState viewport =
      _FdcGridScrollViewportUiState();
}
