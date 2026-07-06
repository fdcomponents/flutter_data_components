// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Owns transient column-resize interaction state for one grid.
///
/// The resize runtime still uses the established private `_FdcGridState`
/// accessors. This holder only moves the mutable drag/session values out of
/// the Flutter host while preserving the current resize behavior and grouped
/// resize flow.
class _FdcGridColumnResizeUiState {
  FdcColumnIdentity? runtimeColumnId;
  double columnStartWidth = 0.0;
  double? dragStartGlobalX;
  List<FdcColumnIdentity> groupRuntimeColumnIds = const <FdcColumnIdentity>[];
  List<double> groupStartWidths = const <double>[];
  double? lastAppliedDelta;

  // Live column-resize geometry is intentionally exposed as a narrow
  // listenable instead of flowing through the grid host setState path. This
  // keeps high-frequency drag ticks in the columns runtime domain while the
  // root State remains a thin lifecycle/build host.
  final ValueNotifier<int> liveLayoutRevision = ValueNotifier<int>(0);

  bool _liveLayoutChangeScheduled = false;
  bool _disposed = false;
  int _liveLayoutGeneration = 0;

  void Function(PointerEvent event)? _globalResizePointerRoute;
  void Function(double globalX)? _globalResizeMoveCallback;
  VoidCallback? _globalResizeEndCallback;
  int? _globalResizePointerId;
  double? globalResizeDeltaFactor;

  void armGlobalResizeSession({
    required double deltaFactor,
    required void Function(double globalX) onMove,
    required VoidCallback onEnd,
  }) {
    // A grid can only own one active column-resize gesture. If a rebuilt or
    // virtualized handle disappeared before delivering drag end/cancel, close
    // that stale session before arming the next one.
    final staleEnd = _globalResizeEndCallback;
    if (staleEnd != null) {
      disarmGlobalResizeSession();
      staleEnd();
    }

    _globalResizeMoveCallback = onMove;
    _globalResizeEndCallback = onEnd;
    _globalResizePointerId = null;
    globalResizeDeltaFactor = deltaFactor;
    void route(PointerEvent event) {
      if (event is PointerMoveEvent && event.buttons != 0) {
        _globalResizePointerId ??= event.pointer;
        if (_globalResizePointerId == event.pointer) {
          _globalResizeMoveCallback?.call(event.position.dx);
        }
        return;
      }
      if (event is! PointerUpEvent && event is! PointerCancelEvent) {
        return;
      }
      if (_globalResizePointerId != null &&
          _globalResizePointerId != event.pointer) {
        return;
      }
      final end = _globalResizeEndCallback;
      disarmGlobalResizeSession();
      end?.call();
    }

    _globalResizePointerRoute = route;
    GestureBinding.instance.pointerRouter.addGlobalRoute(route);
  }

  void disarmGlobalResizeSession() {
    final route = _globalResizePointerRoute;
    if (route != null) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(route);
    }
    _globalResizePointerRoute = null;
    _globalResizeMoveCallback = null;
    _globalResizeEndCallback = null;
    _globalResizePointerId = null;
    globalResizeDeltaFactor = null;
  }

  void requestLiveLayoutChanged() {
    if (_disposed) {
      return;
    }
    if (_liveLayoutChangeScheduled) {
      return;
    }

    _liveLayoutChangeScheduled = true;
    final scheduledGeneration = _liveLayoutGeneration;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (_disposed || scheduledGeneration != _liveLayoutGeneration) {
        return;
      }

      _liveLayoutChangeScheduled = false;
      if (runtimeColumnId == null) {
        return;
      }

      // Keep the original counter for continuity with older diagnostics while
      // exposing a more precise name for the actual revision advance.
      liveLayoutRevision.value++;
    });
  }

  void cancelPendingLiveLayoutChange() {
    _liveLayoutGeneration++;
    _liveLayoutChangeScheduled = false;
  }

  void dispose() {
    disarmGlobalResizeSession();
    _disposed = true;
    liveLayoutRevision.dispose();
  }
}
