// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Owns transient navigation guard state for one grid instance.
///
/// Durable navigation rules live in `FdcGridNavigationManager` and the
/// navigation runtime extensions. This holder only prevents overlapping
/// grid-move execution during a single event-loop turn.
class _FdcGridNavigationUiState {
  bool handlingGridMove = false;
}
