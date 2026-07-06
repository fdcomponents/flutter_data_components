// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../common/theme/fdc_grid_styles.dart';

class FdcGridControlTheme {
  const FdcGridControlTheme._();

  static Color iconColor(
    BuildContext context,
    FdcGridControlsStyle style, {
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

  static WidgetStateProperty<Color?> checkboxFillColor(
    FdcGridControlsStyle style,
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

  static Color? checkboxCheckColor(
    BuildContext context,
    FdcGridControlsStyle style, {
    required bool enabled,
  }) {
    if (!enabled) {
      return style.checkboxDisabledCheckColor ??
          Theme.of(context).disabledColor;
    }
    return style.checkboxCheckColor ?? Theme.of(context).colorScheme.onPrimary;
  }

  static WidgetStateBorderSide checkboxSide(
    BuildContext context,
    FdcGridControlsStyle style, {
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

  static WidgetStateProperty<Color?> switchThumbColor(
    FdcGridControlsStyle style,
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

  static WidgetStateProperty<Color?> switchTrackColor(
    FdcGridControlsStyle style,
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
