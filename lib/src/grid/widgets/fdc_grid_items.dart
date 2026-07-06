// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

/// Resolved visual theme for items built inside a grid toolbar or status bar.
class FdcGridItemTheme extends InheritedWidget {
  /// Creates a [FdcGridItemTheme].
  const FdcGridItemTheme({
    super.key,
    required this.textStyle,
    required this.textColor,
    required this.iconColor,
    required this.disabledTextColor,
    required this.disabledIconColor,
    required super.child,
  });

  /// Text style resolved for item labels in this host region.
  final TextStyle textStyle;

  /// Default foreground color for enabled item text.
  final Color textColor;

  /// Default foreground color for enabled item icons.
  final Color iconColor;

  /// Foreground color used for disabled item text.
  final Color disabledTextColor;

  /// Foreground color used for disabled item icons.
  final Color disabledIconColor;

  /// Returns the nearest grid item theme, or `null` when none is available.
  static FdcGridItemTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FdcGridItemTheme>();
  }

  /// Returns the nearest grid item theme and throws when no theme is available.
  static FdcGridItemTheme of(BuildContext context) {
    final theme = maybeOf(context);
    if (theme == null) {
      throw FlutterError('No FdcGridItemTheme found in context.');
    }
    return theme;
  }

  @override
  bool updateShouldNotify(FdcGridItemTheme oldWidget) {
    return textStyle != oldWidget.textStyle ||
        textColor != oldWidget.textColor ||
        iconColor != oldWidget.iconColor ||
        disabledTextColor != oldWidget.disabledTextColor ||
        disabledIconColor != oldWidget.disabledIconColor;
  }
}

/// Placement zone used by shared grid items inside toolbars and status bars.
enum FdcGridItemPlacement {
  /// Places the item at the leading edge of its container.
  start,

  /// Places the item in the center zone of its container.
  center,

  /// Places the item at the trailing edge of its container.
  end,
}

/// Base class for items rendered inside a grid toolbar or status bar.
class FdcGridItem {
  /// Creates a [FdcGridItem].
  const FdcGridItem({
    this.id,
    this.visible = true,
    this.placement = FdcGridItemPlacement.end,
  });

  /// Optional stable identifier for locating or customizing this item.
  final String? id;

  /// Whether this item participates in the host toolbar or status bar.
  final bool visible;

  /// Placement zone used by the host when arranging this item.
  final FdcGridItemPlacement placement;

  /// Builds a host-independent item.
  ///
  /// Grid-runtime items such as search, export, status text, progress, and
  /// paging are dispatched by their host shell before this fallback is used.
  Widget buildItem(BuildContext context) => const SizedBox.shrink();
}

/// Fully custom widget item for a grid toolbar or status bar.
class FdcGridCustomItem extends FdcGridItem {
  /// Creates a [FdcGridCustomItem].
  const FdcGridCustomItem({
    super.id,
    super.visible,
    super.placement,
    required this.builder,
  });

  /// Builds the custom widget rendered for this item.
  final WidgetBuilder builder;

  @override
  Widget buildItem(BuildContext context) => builder(context);
}

/// Fixed horizontal spacing for a grid toolbar or status bar.
class FdcGridSpacer extends FdcGridItem {
  /// Creates a [FdcGridSpacer].
  FdcGridSpacer({super.id, super.visible, super.placement, this.width = 12}) {
    if (!width.isFinite || width < 0) {
      throw RangeError.value(
        width,
        'width',
        'Must be a finite value greater than or equal to zero.',
      );
    }
  }

  /// Horizontal space reserved by this item.
  final double width;

  @override
  Widget buildItem(BuildContext context) => SizedBox(width: width);
}

/// Vertical separator for a grid toolbar or status bar.
class FdcGridSeparator extends FdcGridItem {
  /// Creates a [FdcGridSeparator].
  FdcGridSeparator({
    super.id,
    super.visible,
    super.placement,
    this.width = 13,
    this.height = 18,
    this.thickness = 1,
    this.color,
  }) {
    if (!width.isFinite || width < 0) {
      throw RangeError.value(
        width,
        'width',
        'Must be a finite value greater than or equal to zero.',
      );
    }
    if (!height.isFinite || height < 0) {
      throw RangeError.value(
        height,
        'height',
        'Must be a finite value greater than or equal to zero.',
      );
    }
    if (!thickness.isFinite || thickness <= 0) {
      throw RangeError.value(
        thickness,
        'thickness',
        'Must be a finite value greater than zero.',
      );
    }
  }

  /// Horizontal space reserved by this item.
  final double width;

  /// Height of the separator line.
  final double height;

  /// Thickness of the separator line.
  final double thickness;

  /// Optional separator color; defaults to the ambient divider color.
  final Color? color;

  @override
  Widget buildItem(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: Container(
          width: thickness,
          height: height,
          color: color ?? Theme.of(context).dividerColor,
        ),
      ),
    );
  }
}
