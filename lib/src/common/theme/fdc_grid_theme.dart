// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../themes/black/fdc_grid_black_theme.dart';
import '../../themes/dark/fdc_grid_dark_theme.dart';
import '../../themes/light/fdc_grid_light_theme.dart';
import '../../themes/white/fdc_grid_white_theme.dart';
import 'fdc_grid_styles.dart';
import 'fdc_grid_theme_data.dart';
import 'fdc_theme.dart';

export 'fdc_grid_styles.dart';
export 'fdc_grid_theme_data.dart';

/// Built-in FdcGrid theme presets.
class FdcGridThemes {
  const FdcGridThemes._();

  /// Soft neutral light grid theme with a subtle grey application-surface look.
  static const FdcGridThemeData light = fdcGridLightTheme;

  /// Pure white grid theme preserving the historical FDC light defaults.
  static const FdcGridThemeData white = fdcGridWhiteTheme;

  /// Dark theme preset for grids embedded in dark application surfaces.
  static const FdcGridThemeData dark = fdcGridDarkTheme;

  /// High-contrast dark preset with near-black surfaces.
  static const FdcGridThemeData black = fdcGridBlackTheme;
}

/// Optional Flutter ThemeExtension bridge for FdcGrid.
///
/// Prefer `FdcApp.theme` or [FdcTheme] for app/subtree-level FDC theming.
/// Without an explicit FDC theme, the built-in light/dark preset follows the
/// active Material [ThemeData.brightness]. Local FdcGrid.theme values still
/// override every inherited source.
class FdcGridTheme extends ThemeExtension<FdcGridTheme> {
  /// Creates a [FdcGridTheme].
  const FdcGridTheme({this.data = FdcGridThemes.light, this.style});

  /// Component-level grid theme data exposed through this Material theme extension.
  final FdcGridThemeData data;

  /// Legacy root-grid style override kept for compatibility with the original
  /// narrow [FdcGridTheme] API.
  final FdcGridStyle? style;

  /// Returns the current effective data.
  FdcGridThemeData get effectiveData {
    if (style == null) {
      return data;
    }

    return data.copyWith(grid: data.grid.merge(style));
  }

  /// Resolves grid theme data using local, FDC subtree, Material extension,
  /// and brightness-derived preset precedence, in that order.
  static FdcGridThemeData resolveData(
    BuildContext context,
    FdcGridThemeData? localTheme,
  ) {
    final materialTheme = Theme.of(context);
    return localTheme ??
        FdcTheme.maybeOf(context)?.grid ??
        materialTheme.extension<FdcGridTheme>()?.effectiveData ??
        (materialTheme.brightness == Brightness.dark
            ? FdcGridThemes.dark
            : FdcGridThemes.light);
  }

  /// Resolves the root grid style by merging defaults, inherited theme data,
  /// and the widget-local style override.
  static FdcGridStyle resolveGridStyle(
    BuildContext context,
    FdcGridThemeData? localTheme,
    FdcGridStyle localStyle,
  ) {
    final theme = resolveData(context, localTheme);
    return FdcGridStyle.defaults.merge(theme.grid).merge(localStyle);
  }

  @override
  FdcGridTheme copyWith({FdcGridThemeData? data, FdcGridStyle? style}) {
    return FdcGridTheme(data: data ?? this.data, style: style ?? this.style);
  }

  @override
  FdcGridTheme lerp(ThemeExtension<FdcGridTheme>? other, double t) {
    if (other is! FdcGridTheme) {
      return this;
    }

    return FdcGridTheme(data: effectiveData.lerp(other.effectiveData, t));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridTheme && data == other.data && style == other.style;
  }

  @override
  int get hashCode => Object.hash(data, style);
}
