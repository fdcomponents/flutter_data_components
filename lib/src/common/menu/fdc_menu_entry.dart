// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/widgets.dart';

/// Shared internal menu entry model used by FDC controls.
///
/// This model intentionally stays independent from Flutter's concrete menu
/// widgets so grids, editors, toolbars, and future controls can build menus
/// through one consistent abstraction.
abstract class FdcMenuEntry {
  /// Creates a [FdcMenuEntry].
  const FdcMenuEntry();
}

/// A selectable menu entry that invokes an action callback.
///
/// Use actions for commands that should run immediately when the user selects
/// the entry.
class FdcMenuAction extends FdcMenuEntry {
  /// Creates a [FdcMenuAction].
  const FdcMenuAction({
    required this.text,
    this.icon,
    this.shortcutText,
    this.enabled = true,
    this.onPressed,
  });

  /// Text displayed to the user.
  final String text;

  /// Optional icon shown with the item.
  final IconData? icon;

  /// Optional shortcut hint shown next to the item.
  final String? shortcutText;

  /// Whether this feature is enabled.
  final bool enabled;

  /// Callback invoked when the item is activated.
  final VoidCallback? onPressed;
}

/// A checkable menu action with optional custom child content.
///
/// [checked] controls the current check state; [keepOpen] allows toggle-style
/// interactions without dismissing the surrounding menu.
class FdcMenuCheckAction extends FdcMenuEntry {
  /// Creates a [FdcMenuCheckAction].
  const FdcMenuCheckAction({
    required this.text,
    required this.checked,
    this.icon,
    this.shortcutText,
    this.child,
    this.keepOpen = false,
    this.enabled = true,
    this.onPressed,
  });

  /// Text displayed to the user.
  final String text;

  /// Whether the item is currently checked.
  final bool checked;

  /// Optional icon shown with the item.
  final IconData? icon;

  /// Optional shortcut hint shown next to the item.
  final String? shortcutText;

  /// Child widget rendered by this configuration.
  final Widget? child;

  /// Whether the menu should remain open after activation.
  final bool keepOpen;

  /// Whether this feature is enabled.
  final bool enabled;

  /// Callback invoked when the item is activated.
  final VoidCallback? onPressed;
}

/// A non-interactive caption used to label a group of menu entries.
class FdcMenuTitle extends FdcMenuEntry {
  /// Creates a [FdcMenuTitle].
  const FdcMenuTitle({required this.text});

  /// Text displayed to the user.
  final String text;
}

/// A non-interactive separator between logical groups of menu entries.
class FdcMenuSeparator extends FdcMenuEntry {
  /// Creates a [FdcMenuSeparator].
  const FdcMenuSeparator();
}

/// A menu entry that renders arbitrary [child] content without action semantics.
class FdcMenuWidgetEntry extends FdcMenuEntry {
  /// Creates a [FdcMenuWidgetEntry].
  const FdcMenuWidgetEntry({required this.child});

  /// Child widget rendered by this configuration.
  final Widget child;
}

/// A menu entry that opens a nested collection of child entries.
class FdcSubMenu extends FdcMenuEntry {
  /// Creates a [FdcSubMenu].
  const FdcSubMenu({
    required this.text,
    required this.children,
    this.icon,
    this.enabled = true,
  });

  /// Text displayed to the user.
  final String text;

  /// Child entries rendered inside this item.
  final List<FdcMenuEntry> children;

  /// Optional icon shown with the item.
  final IconData? icon;

  /// Whether this feature is enabled.
  final bool enabled;
}
