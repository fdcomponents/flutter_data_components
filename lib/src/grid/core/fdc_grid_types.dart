// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart'
    show Alignment, Color, EdgeInsetsGeometry, TextStyle;

/// Defines the available grid vertical scroll mode values.
enum FdcGridVerticalScrollMode {
  /// Pixel-based scrolling. The grid does not snap to row boundaries and
  /// scrolling does not change the current dataset record.
  smooth,

  /// Record-oriented scrolling. Vertical scrolling snaps to row boundaries
  /// and the first visible row becomes the current dataset record.
  recordScroll,
}

/// Defines the available grid horizontal scroll mode values.
enum FdcGridHorizontalScrollMode {
  /// Smooth pixel-based horizontal scrolling without column boundary snapping.
  smooth,

  /// Horizontal scrolling settles to the nearest column boundary when the
  /// scroll interaction ends.
  columnSnap,
}

/// Defines the available grid scrollbars values.
enum FdcGridScrollbars {
  /// Render both vertical and horizontal scrollbar thumbs.
  both,

  /// Render only the vertical scrollbar thumb.
  vertical,

  /// Render only the horizontal scrollbar thumb.
  horizontal,

  /// Do not render scrollbar thumbs. Pointer, wheel, drag, and keyboard
  /// scrolling remain enabled.
  none,
}

/// Visual styling for a single [FdcGridColumnGroup] header cell.
///
/// Values are optional and override the shared group styling from
/// the shared grid header group style only for the group that owns this style object.
class FdcGridColumnGroupStyle {
  /// Creates a [FdcGridColumnGroupStyle].
  const FdcGridColumnGroupStyle({
    this.backgroundColor,
    this.textStyle,
    this.alignment,
    this.padding,
    this.bottomSeparatorColor,
    this.verticalSeparatorColor,
    this.verticalSeparatorInset,
  });

  /// Background color used by this group header cell.
  final Color? backgroundColor;

  /// Text style used by this group header label.
  final TextStyle? textStyle;

  /// Alignment used by this group header label.
  final Alignment? alignment;

  /// Padding used inside this group header cell.
  final EdgeInsetsGeometry? padding;

  /// Bottom separator color used by this group header cell.
  final Color? bottomSeparatorColor;

  /// Trailing vertical separator color used by this group header cell.
  final Color? verticalSeparatorColor;

  /// Symmetric inset used above and below this group's trailing separator.
  final double? verticalSeparatorInset;

  /// Creates a copy with selected values replaced.
  FdcGridColumnGroupStyle copyWith({
    Color? backgroundColor,
    TextStyle? textStyle,
    Alignment? alignment,
    EdgeInsetsGeometry? padding,
    Color? bottomSeparatorColor,
    Color? verticalSeparatorColor,
    double? verticalSeparatorInset,
  }) {
    return FdcGridColumnGroupStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
      alignment: alignment ?? this.alignment,
      padding: padding ?? this.padding,
      bottomSeparatorColor: bottomSeparatorColor ?? this.bottomSeparatorColor,
      verticalSeparatorColor:
          verticalSeparatorColor ?? this.verticalSeparatorColor,
      verticalSeparatorInset:
          verticalSeparatorInset ?? this.verticalSeparatorInset,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridColumnGroupStyle &&
            backgroundColor == other.backgroundColor &&
            textStyle == other.textStyle &&
            alignment == other.alignment &&
            padding == other.padding &&
            bottomSeparatorColor == other.bottomSeparatorColor &&
            verticalSeparatorColor == other.verticalSeparatorColor &&
            verticalSeparatorInset == other.verticalSeparatorInset;
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    textStyle,
    alignment,
    padding,
    bottomSeparatorColor,
    verticalSeparatorColor,
    verticalSeparatorInset,
  );
}

/// Visual definition for a column group rendered in the grid header.
///
/// Groups are intentionally lightweight: they only add a visual header band
/// above leaf columns that reference [id] through `FdcGridColumn.groupId`.
/// They do not change dataset schema, sorting, filtering, editing, summaries,
/// or row layout. Grouped columns cannot be pinned; pin actions are hidden for
/// them and programmatic pinning is ignored while the column belongs to a group.
class FdcGridColumnGroup {
  /// Creates a [FdcGridColumnGroup].
  const FdcGridColumnGroup({
    required this.id,
    required this.label,
    this.style = const FdcGridColumnGroupStyle(),
  });

  /// Stable unique identifier used by `FdcGridColumn.groupId`.
  final String id;

  /// Text displayed in the group header cell.
  final String label;

  /// Visual styling applied to this specific group header cell.
  final FdcGridColumnGroupStyle style;

  /// Creates a copy with selected values replaced.
  FdcGridColumnGroup copyWith({
    String? id,
    String? label,
    FdcGridColumnGroupStyle? style,
  }) {
    return FdcGridColumnGroup(
      id: id ?? this.id,
      label: label ?? this.label,
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridColumnGroup &&
            id == other.id &&
            label == other.label &&
            style == other.style;
  }

  @override
  int get hashCode => Object.hash(id, label, style);
}

/// Defines the available debounce policy values.
enum FdcDebouncePolicy {
  /// Do not automatically apply text input changes.
  ///
  /// Search/filter text is applied only when the input is explicitly
  /// submitted, for example with Enter/Search.
  disabled,

  /// Always use the configured debounce duration as-is.
  fixed,

  /// Use the configured debounce duration as the base/minimum and let FDC
  /// increase the effective delay internally for larger datasets.
  adaptive,
}
