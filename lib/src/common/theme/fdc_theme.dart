// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/widgets.dart';

import 'fdc_theme_data.dart';

export 'fdc_theme_data.dart';

/// Subtree-level FDC visual theme provider.
///
/// Use `FdcApp.theme` for the root application theme. Use `FdcTheme` when a
/// specific subtree needs a different grid/editor visual preset.
class FdcTheme extends StatelessWidget {
  /// Creates a [FdcTheme].
  const FdcTheme({super.key, required this.data, required this.child});

  /// Theme sections contributed by this subtree scope.
  final FdcThemeData data;

  /// Child widget rendered by this configuration.
  final Widget child;

  /// Returns the nearest effective FDC theme and subscribes to scope changes.
  static FdcThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_FdcThemeScope>()?.data;
  }

  /// Returns the nearest effective FDC theme without subscribing to updates.
  static FdcThemeData? maybeOfNonListening(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<_FdcThemeScope>();
    final widget = element?.widget;
    return widget is _FdcThemeScope ? widget.data : null;
  }

  @override
  Widget build(BuildContext context) {
    final parent = maybeOf(context);
    final effectiveData = parent == null ? data : parent.merge(data);

    return _FdcThemeScope(data: effectiveData, child: child);
  }
}

class _FdcThemeScope extends InheritedWidget {
  const _FdcThemeScope({required this.data, required super.child});

  final FdcThemeData data;

  @override
  bool updateShouldNotify(_FdcThemeScope oldWidget) {
    return data != oldWidget.data;
  }
}
