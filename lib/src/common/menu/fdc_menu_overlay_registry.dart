// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Tracks open FDC menu overlays and provides a shared dismissal entrypoint.
///
/// The registry is used internally by menu overlays and can also be invoked by
/// application hosts that need to dismiss menus after an interaction outside
/// the Flutter widget tree, such as a click in a surrounding web document.
class FdcMenuOverlayRegistry {
  const FdcMenuOverlayRegistry._();

  static final Set<void Function()> _dismissCallbacks = <void Function()>{};

  /// Dismisses every menu overlay currently registered as open.
  static void dismissAll() {
    for (final dismiss in List<void Function()>.of(_dismissCallbacks)) {
      dismiss();
    }
  }

  /// Registers a callback that dismisses an open menu overlay.
  static void register(void Function() dismiss) {
    _dismissCallbacks.add(dismiss);
  }

  /// Removes a previously registered menu-overlay dismissal callback.
  static void unregister(void Function() dismiss) {
    _dismissCallbacks.remove(dismiss);
  }
}
