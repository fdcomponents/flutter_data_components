// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcColumnResizeLayoutRuntime on _FdcGridState {
  ValueListenable<int> get _columnResizeLiveLayoutRevision =>
      _ui.columnResize.liveLayoutRevision;

  void _notifyLiveResizeLayoutChanged() {
    _ui.columnResize.requestLiveLayoutChanged();
  }

  void _cancelPendingLiveResizeLayout() {
    _ui.columnResize.cancelPendingLiveLayoutChange();
  }
}
