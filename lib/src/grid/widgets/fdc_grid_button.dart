// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import 'fdc_grid_items.dart';

/// Standard action button that can be placed in a grid toolbar or status bar.
///
/// The API follows Flutter button conventions: when [onPressed] is null the
/// button is disabled.
class FdcGridButton extends FdcGridItem {
  /// Creates a [FdcGridButton].
  const FdcGridButton({
    super.id,
    super.visible,
    super.placement,
    required this.icon,
    this.label,
    this.tooltip,
    this.onPressed,
  });

  /// Optional icon shown with the item.
  final IconData icon;

  /// Display label shown to the user.
  final String? label;

  /// Tooltip shown for this grid toolbar button.
  final String? tooltip;

  /// Callback invoked when the item is activated.
  final VoidCallback? onPressed;

  /// Builds the button using the item theme provided by its host bar.
  @override
  Widget buildItem(BuildContext context) {
    final label = this.label;
    final key = id == null ? null : ValueKey<String>('fdc-grid-button-$id');
    final itemTheme = FdcGridItemTheme.maybeOf(context);
    final enabled = onPressed != null;
    final iconColor = enabled
        ? itemTheme?.iconColor
        : itemTheme?.disabledIconColor;
    final textColor = enabled
        ? itemTheme?.textColor
        : itemTheme?.disabledTextColor;
    final textStyle = itemTheme?.textStyle.copyWith(color: textColor);

    final child = label == null
        ? IconButton(
            key: key,
            icon: Icon(icon, color: iconColor),
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            splashRadius: 18,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            onPressed: onPressed,
          )
        : TextButton.icon(
            key: key,
            icon: Icon(icon, size: 16, color: iconColor),
            label: Text(label, style: textStyle),
            style: TextButton.styleFrom(
              foregroundColor: textColor,
              disabledForegroundColor: itemTheme?.disabledTextColor,
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: onPressed,
          );

    if (tooltip == null) {
      return child;
    }

    return Tooltip(message: tooltip!, excludeFromSemantics: true, child: child);
  }
}
