// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/widgets.dart';

/// Built-in focus traversal policy presets for FDC app/subtree scopes.
///
/// The enum keeps the public FDC app configuration serializable and stable
/// while still mapping to Flutter's native [FocusTraversalPolicy] classes.
enum FdcFocusTraversalPolicy {
  /// Traverse focusable widgets in widget/layout order.
  ///
  /// This is the default because it matches ordinary form layout and does not
  /// require explicit [FocusTraversalOrder] wrappers around every editor.
  widgetOrder,

  /// Traverse focusable widgets in reading order.
  readingOrder,

  /// Traverse by explicit [FocusTraversalOrder] values.
  ordered,
}

/// App/subtree-level focus behavior defaults for Flutter Data Components.
///
/// `FdcApp.focus` is the preferred place to configure suite-level focus
/// behavior. Use [FdcFocusScope] for a local form/panel override.
class FdcFocusOptions {
  /// Creates a [FdcFocusOptions].
  const FdcFocusOptions({
    this.wrapTraversalGroup = true,
    this.traversalPolicy = FdcFocusTraversalPolicy.widgetOrder,
  });

  /// When true, the FDC scope wraps its child in a Flutter
  /// [FocusTraversalGroup].
  ///
  /// Disable this only when the host app already owns focus traversal for the
  /// subtree and FDC should not insert another traversal boundary.
  final bool wrapTraversalGroup;

  /// Traversal policy used by the generated [FocusTraversalGroup].
  final FdcFocusTraversalPolicy traversalPolicy;

  /// Creates a copy with selected values replaced.
  FdcFocusOptions copyWith({
    bool? wrapTraversalGroup,
    FdcFocusTraversalPolicy? traversalPolicy,
  }) {
    return FdcFocusOptions(
      wrapTraversalGroup: wrapTraversalGroup ?? this.wrapTraversalGroup,
      traversalPolicy: traversalPolicy ?? this.traversalPolicy,
    );
  }

  /// Creates the Flutter traversal policy represented by [traversalPolicy].
  FocusTraversalPolicy createTraversalPolicy() {
    return switch (traversalPolicy) {
      FdcFocusTraversalPolicy.widgetOrder => WidgetOrderTraversalPolicy(),
      FdcFocusTraversalPolicy.readingOrder => ReadingOrderTraversalPolicy(),
      FdcFocusTraversalPolicy.ordered => OrderedTraversalPolicy(),
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcFocusOptions &&
            wrapTraversalGroup == other.wrapTraversalGroup &&
            traversalPolicy == other.traversalPolicy;
  }

  @override
  int get hashCode => Object.hash(wrapTraversalGroup, traversalPolicy);
}

/// Subtree-level FDC focus options provider.
///
/// Use `FdcApp.focus` for app-wide defaults. Use `FdcFocusScope` around a
/// specific form or panel when it needs different focus traversal behavior.
class FdcFocusScope extends StatelessWidget {
  /// Creates a [FdcFocusScope].
  const FdcFocusScope({
    super.key,
    this.options = const FdcFocusOptions(),
    required this.child,
  });

  /// Options used by this configuration.
  final FdcFocusOptions options;

  /// Child widget rendered by this configuration.
  final Widget child;

  /// Returns the nearest scoped focus options, or suite defaults when no scope exists.
  static FdcFocusOptions of(BuildContext context) {
    return maybeOf(context) ?? const FdcFocusOptions();
  }

  /// Returns the nearest scoped focus options and subscribes to scope changes.
  static FdcFocusOptions? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_FdcFocusScope>()
        ?.options;
  }

  /// Returns the nearest scoped focus options without subscribing to updates.
  static FdcFocusOptions? maybeOfNonListening(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<_FdcFocusScope>();
    final widget = element?.widget;
    return widget is _FdcFocusScope ? widget.options : null;
  }

  @override
  Widget build(BuildContext context) {
    final scopedChild = _FdcFocusScope(options: options, child: child);

    if (!options.wrapTraversalGroup) {
      return scopedChild;
    }

    return FocusTraversalGroup(
      policy: options.createTraversalPolicy(),
      child: scopedChild,
    );
  }
}

class _FdcFocusScope extends InheritedWidget {
  const _FdcFocusScope({required this.options, required super.child});

  final FdcFocusOptions options;

  @override
  bool updateShouldNotify(_FdcFocusScope oldWidget) {
    return options != oldWidget.options;
  }
}
