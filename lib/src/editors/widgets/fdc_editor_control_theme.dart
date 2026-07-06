// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../common/theme/fdc_editor_styles.dart';

/// Resolves shared colors and widget states for editor control widgets.
class FdcEditorControlTheme {
  const FdcEditorControlTheme._();

  /// Resolves the icon color for editor auxiliary controls.
  static Color iconColor(
    BuildContext context,
    FdcEditorControlsStyle style, {
    bool enabled = true,
    bool active = false,
  }) {
    if (!enabled) {
      return style.disabledIconColor ?? Theme.of(context).disabledColor;
    }
    if (active) {
      return style.activeIconColor ?? Theme.of(context).colorScheme.primary;
    }
    return style.iconColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// Resolves checkbox fill colors for enabled, disabled and selected states.
  static WidgetStateProperty<Color?> checkboxFillColor(
    FdcEditorControlsStyle style,
  ) {
    return WidgetStateProperty.resolveWith<Color?>((states) {
      final disabled = states.contains(WidgetState.disabled);
      final selected = states.contains(WidgetState.selected);

      if (disabled && selected) {
        return style.checkboxDisabledFillColor;
      }
      if (selected) {
        return style.checkboxFillColor;
      }
      return Colors.transparent;
    });
  }

  /// Resolves the checkbox check mark color.
  static Color? checkboxCheckColor(
    BuildContext context,
    FdcEditorControlsStyle style, {
    required bool enabled,
  }) {
    if (!enabled) {
      return style.checkboxDisabledCheckColor ??
          Theme.of(context).disabledColor;
    }
    return style.checkboxCheckColor ?? Theme.of(context).colorScheme.onPrimary;
  }

  /// Resolves the checkbox border side.
  static WidgetStateBorderSide checkboxSide(
    BuildContext context,
    FdcEditorControlsStyle style, {
    required bool enabled,
  }) {
    return WidgetStateBorderSide.resolveWith((states) {
      final disabled = !enabled || states.contains(WidgetState.disabled);
      final color = disabled
          ? style.checkboxDisabledBorderColor ?? Theme.of(context).disabledColor
          : style.checkboxBorderColor ??
                Theme.of(context).colorScheme.onSurfaceVariant;
      return BorderSide(color: color);
    });
  }

  /// Resolves switch thumb colors for editor switches.
  static WidgetStateProperty<Color?> switchThumbColor(
    FdcEditorControlsStyle style,
  ) {
    return WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return style.switchDisabledThumbColor;
      }
      if (states.contains(WidgetState.selected)) {
        return style.switchThumbColor;
      }
      return style.iconColor;
    });
  }

  /// Resolves switch track colors for editor switches.
  static WidgetStateProperty<Color?> switchTrackColor(
    FdcEditorControlsStyle style,
  ) {
    return WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.disabled)) {
        return style.switchDisabledTrackColor;
      }
      if (states.contains(WidgetState.selected)) {
        return style.switchTrackColor;
      }
      return style.checkboxBorderColor?.withValues(alpha: 0.32);
    });
  }
}
