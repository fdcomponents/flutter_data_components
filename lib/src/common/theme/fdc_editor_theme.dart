// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../themes/black/fdc_editor_black_theme.dart';
import '../../themes/dark/fdc_editor_dark_theme.dart';
import '../../themes/light/fdc_editor_light_theme.dart';
import '../../themes/white/fdc_editor_white_theme.dart';
import 'fdc_editor_styles.dart';
import 'fdc_editor_theme_data.dart';
import 'fdc_theme.dart';

export 'fdc_editor_styles.dart';
export 'fdc_editor_theme_data.dart';

/// Built-in editor theme presets supplied by FDC.
class FdcEditorThemes {
  const FdcEditorThemes._();

  /// Light preset for standard Material surfaces.
  static const FdcEditorThemeData light = fdcEditorLightTheme;

  /// High-contrast white preset with neutral surface chrome.
  static const FdcEditorThemeData white = fdcEditorWhiteTheme;

  /// Dark preset for dark application surfaces.
  static const FdcEditorThemeData dark = fdcEditorDarkTheme;

  /// Near-black preset for maximum-dark editor surfaces.
  static const FdcEditorThemeData black = fdcEditorBlackTheme;
}

/// Optional Flutter ThemeExtension bridge for FDC editors.
///
/// Without an explicit FDC editor theme, the built-in light/dark preset
/// follows the active Material [ThemeData.brightness].
class FdcEditorTheme extends ThemeExtension<FdcEditorTheme> {
  /// Creates a [FdcEditorTheme].
  const FdcEditorTheme({this.data = FdcEditorThemes.light, this.style});

  /// Base editor theme data provided by this ThemeExtension.
  final FdcEditorThemeData data;

  /// Optional root editor input style override merged over `data.input`.
  final FdcEditorInputStyle? style;

  /// Theme data after merging the optional root [style] override.
  FdcEditorThemeData get effectiveData {
    if (style == null) {
      return data;
    }

    return data.copyWith(input: data.input.merge(style));
  }

  /// Resolves editor theme data using local, FDC subtree, Material bridge, and built-in fallbacks.
  static FdcEditorThemeData resolveData(
    BuildContext context,
    FdcEditorThemeData? localTheme,
  ) {
    final materialTheme = Theme.of(context);
    return localTheme ??
        FdcTheme.maybeOf(context)?.editor ??
        materialTheme.extension<FdcEditorTheme>()?.effectiveData ??
        (materialTheme.brightness == Brightness.dark
            ? FdcEditorThemes.dark
            : FdcEditorThemes.light);
  }

  /// Resolves the effective text-input style for an editor.
  static FdcEditorInputStyle resolveInputStyle(
    BuildContext context, {
    FdcEditorThemeData? localTheme,
    FdcEditorInputStyle? localStyle,
  }) {
    final theme = resolveData(context, localTheme);
    return FdcEditorInputStyle.defaults.merge(theme.input).merge(localStyle);
  }

  /// Resolves the effective non-text control style for an editor.
  static FdcEditorControlsStyle resolveControlsStyle(
    BuildContext context, {
    FdcEditorThemeData? localTheme,
    FdcEditorControlsStyle? localStyle,
  }) {
    final theme = resolveData(context, localTheme);
    return FdcEditorControlsStyle.defaults
        .merge(theme.controls)
        .merge(localStyle);
  }

  /// Resolves the effective combo-popup style for an editor.
  static FdcEditorComboPopupStyle resolveComboPopupStyle(
    BuildContext context, {
    FdcEditorThemeData? localTheme,
    FdcEditorComboPopupStyle? localStyle,
  }) {
    final theme = resolveData(context, localTheme);
    return FdcEditorComboPopupStyle.defaults
        .merge(theme.comboPopup)
        .merge(localStyle);
  }

  @override
  FdcEditorTheme copyWith({
    FdcEditorThemeData? data,
    FdcEditorInputStyle? style,
  }) {
    return FdcEditorTheme(data: data ?? this.data, style: style ?? this.style);
  }

  @override
  FdcEditorTheme lerp(ThemeExtension<FdcEditorTheme>? other, double t) {
    if (other is! FdcEditorTheme) {
      return this;
    }

    return FdcEditorTheme(data: effectiveData.lerp(other.effectiveData, t));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcEditorTheme && data == other.data && style == other.style;
  }

  @override
  int get hashCode => Object.hash(data, style);
}
