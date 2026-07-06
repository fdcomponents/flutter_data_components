// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_editor_theme_data.dart';
import 'fdc_grid_theme_data.dart';

/// Application/subtree-level visual theme for Flutter Data Components.
///
/// Individual widgets may still override their own theme directly. In nested
/// `FdcTheme` scopes, omitted sections inherit from the parent scope before
/// falling back to built-in component defaults.
class FdcThemeData {
  /// Creates a [FdcThemeData].
  const FdcThemeData({this.grid, this.editor});

  /// Grid theme section, or null to inherit from the parent scope/defaults.
  final FdcGridThemeData? grid;

  /// Editor theme section, or null to inherit from the parent scope/defaults.
  final FdcEditorThemeData? editor;

  /// Creates a copy with selected values replaced.
  FdcThemeData copyWith({FdcGridThemeData? grid, FdcEditorThemeData? editor}) {
    return FdcThemeData(grid: grid ?? this.grid, editor: editor ?? this.editor);
  }

  /// Returns this theme with non-null sections from [override] applied.
  FdcThemeData merge(FdcThemeData? override) {
    if (override == null) {
      return this;
    }

    return FdcThemeData(
      grid: override.grid ?? grid,
      editor: override.editor ?? editor,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcThemeData && grid == other.grid && editor == other.editor;
  }

  @override
  int get hashCode => Object.hash(grid, editor);
}
