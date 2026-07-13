// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_menu_overlay_registry.dart';

/// Controls transient menus created by FD Components.
///
/// Host applications can call [dismissAll] when an interaction happens outside
/// Flutter's pointer event boundary, such as a click in a parent page around an
/// embedded Flutter Web iframe.
class FdcMenuOverlay {
  const FdcMenuOverlay._();

  /// Closes every currently mounted FD Components menu anchor.
  static void dismissAll() {
    FdcMenuOverlayRegistry.dismissAll();
  }
}
