// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Owns short-lived header interaction state for a concrete grid instance.
///
/// This keeps drag/drop and header-drag scrolling flags out of the Flutter
/// `State` host while preserving the existing private runtime accessors used by
/// the current extension-based grid runtime.
class _FdcGridHeaderInteractionUiState {
  int? draggingColumnIndex;
  FdcColumnIdentity? liveSwapBlockedTargetRuntimeColumnId;
  Timer? liveSwapBlockedTargetTimer;
  FdcColumnIdentity? pendingSwapTargetColumnId;
  bool liveSwapLocked = false;
  Timer? liveSwapLockTimer;
  bool invalidColumnDropTargetHovering = false;
  final ValueNotifier<bool> invalidDropTargetHoverNotifier =
      ValueNotifier<bool>(false);
  bool horizontalDragScrolling = false;

  void lockLiveSwap(Duration duration, {required VoidCallback onUnlocked}) {
    liveSwapLocked = true;
    liveSwapLockTimer?.cancel();
    liveSwapLockTimer = Timer(duration, () {
      liveSwapLocked = false;
      liveSwapLockTimer = null;
      onUnlocked();
    });
  }

  void blockLiveSwapTarget(
    FdcColumnIdentity runtimeColumnId,
    Duration duration,
  ) {
    liveSwapBlockedTargetRuntimeColumnId = runtimeColumnId;
    liveSwapBlockedTargetTimer?.cancel();
    liveSwapBlockedTargetTimer = Timer(duration, () {
      if (liveSwapBlockedTargetRuntimeColumnId == runtimeColumnId) {
        liveSwapBlockedTargetRuntimeColumnId = null;
      }
      liveSwapBlockedTargetTimer = null;
    });
  }

  void clearLiveSwapTargetBlock() {
    liveSwapBlockedTargetRuntimeColumnId = null;
    liveSwapBlockedTargetTimer?.cancel();
    liveSwapBlockedTargetTimer = null;
  }

  void clearLiveSwapLock() {
    liveSwapLocked = false;
    liveSwapLockTimer?.cancel();
    liveSwapLockTimer = null;
    pendingSwapTargetColumnId = null;
  }

  void dispose() {
    clearLiveSwapLock();
    clearLiveSwapTargetBlock();
    invalidDropTargetHoverNotifier.dispose();
  }
}
