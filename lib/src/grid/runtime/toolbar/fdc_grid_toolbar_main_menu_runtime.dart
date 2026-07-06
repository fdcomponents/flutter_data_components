// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridToolbarMainMenuRuntime on _FdcGridState {
  bool _showsToolbarMainMenu() {
    if (!widget.toolbar.visible) {
      return false;
    }

    for (final item in widget.toolbar.items) {
      if (item is FdcGridMainMenuButton) {
        return item.visible;
      }
    }
    return false;
  }
}
