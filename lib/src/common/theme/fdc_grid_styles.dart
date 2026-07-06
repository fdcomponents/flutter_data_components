// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../grid/widgets/fdc_grid_header_metrics.dart';

/// Colors and state styling for grid popup and column menus.
class FdcGridPopupMenuStyle {
  /// Creates a [FdcGridPopupMenuStyle].
  const FdcGridPopupMenuStyle({
    this.backgroundColor,
    this.borderColor,
    this.shadowColor,
    this.textColor,
    this.secondaryTextColor,
    this.iconColor,
    this.disabledTextColor,
    this.disabledIconColor,
    this.hoverColor,
    this.selectedItemColor,
    this.pressedColor,
    this.separatorColor,
  });

  /// Built-in popup and column-menu palette used when no menu style overrides
  /// are supplied.
  static const FdcGridPopupMenuStyle defaults = FdcGridPopupMenuStyle(
    backgroundColor: Color(0xFFFAFAF7),
    borderColor: Color(0xFFD6D3C8),
    shadowColor: Color(0x29000000),
    textColor: Color(0xFF111827),
    secondaryTextColor: Color(0xFF4B5563),
    iconColor: Color(0xFF374151),
    disabledTextColor: Color(0xFF9CA3AF),
    disabledIconColor: Color(0xFF9CA3AF),
    hoverColor: Color(0xFFF3F4F0),
    selectedItemColor: Color(0xFFE5E7E2),
    pressedColor: Color(0xFFDADDD6),
    separatorColor: Color(0xFFE1DED3),
  );

  /// Menu surface background color.
  final Color? backgroundColor;

  /// Border color around the menu surface.
  final Color? borderColor;

  /// Shadow color used by the menu elevation effect.
  final Color? shadowColor;

  /// Primary menu item text color.
  final Color? textColor;

  /// Secondary and shortcut-label text color.
  final Color? secondaryTextColor;

  /// Color used for enabled menu item icons.
  final Color? iconColor;

  /// Text color used for disabled menu entries.
  final Color? disabledTextColor;

  /// Icon color used for disabled menu entries.
  final Color? disabledIconColor;

  /// Background overlay color for hovered menu entries.
  final Color? hoverColor;

  /// Background color used for selected or checked entries.
  final Color? selectedItemColor;

  /// Background overlay color while a menu entry is pressed.
  final Color? pressedColor;

  /// Color of divider lines between menu groups.
  final Color? separatorColor;

  /// Creates a copy with selected values replaced.
  FdcGridPopupMenuStyle copyWith({
    Color? backgroundColor,
    Color? borderColor,
    Color? shadowColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? iconColor,
    Color? disabledTextColor,
    Color? disabledIconColor,
    Color? hoverColor,
    Color? selectedItemColor,
    Color? pressedColor,
    Color? separatorColor,
  }) {
    return FdcGridPopupMenuStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      iconColor: iconColor ?? this.iconColor,
      disabledTextColor: disabledTextColor ?? this.disabledTextColor,
      disabledIconColor: disabledIconColor ?? this.disabledIconColor,
      hoverColor: hoverColor ?? this.hoverColor,
      selectedItemColor: selectedItemColor ?? this.selectedItemColor,
      pressedColor: pressedColor ?? this.pressedColor,
      separatorColor: separatorColor ?? this.separatorColor,
    );
  }

  /// Returns this style with non-null values from [override] applied.
  FdcGridPopupMenuStyle merge(FdcGridPopupMenuStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcGridPopupMenuStyle(
      backgroundColor: override.backgroundColor ?? backgroundColor,
      borderColor: override.borderColor ?? borderColor,
      shadowColor: override.shadowColor ?? shadowColor,
      textColor: override.textColor ?? textColor,
      secondaryTextColor: override.secondaryTextColor ?? secondaryTextColor,
      iconColor: override.iconColor ?? iconColor,
      disabledTextColor: override.disabledTextColor ?? disabledTextColor,
      disabledIconColor: override.disabledIconColor ?? disabledIconColor,
      hoverColor: override.hoverColor ?? hoverColor,
      selectedItemColor: override.selectedItemColor ?? selectedItemColor,
      pressedColor: override.pressedColor ?? pressedColor,
      separatorColor: override.separatorColor ?? separatorColor,
    );
  }

  /// Interpolates between two styles for animated theme transitions.
  FdcGridPopupMenuStyle lerp(FdcGridPopupMenuStyle other, double t) {
    return FdcGridPopupMenuStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t),
      textColor: Color.lerp(textColor, other.textColor, t),
      secondaryTextColor: Color.lerp(
        secondaryTextColor,
        other.secondaryTextColor,
        t,
      ),
      iconColor: Color.lerp(iconColor, other.iconColor, t),
      disabledTextColor: Color.lerp(
        disabledTextColor,
        other.disabledTextColor,
        t,
      ),
      disabledIconColor: Color.lerp(
        disabledIconColor,
        other.disabledIconColor,
        t,
      ),
      hoverColor: Color.lerp(hoverColor, other.hoverColor, t),
      selectedItemColor: Color.lerp(
        selectedItemColor,
        other.selectedItemColor,
        t,
      ),
      pressedColor: Color.lerp(pressedColor, other.pressedColor, t),
      separatorColor: Color.lerp(separatorColor, other.separatorColor, t),
    );
  }

  /// Resolves nullable style values against the supplied fallback style.
  FdcGridPopupMenuStyle resolve() {
    return FdcGridPopupMenuStyle.defaults.merge(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridPopupMenuStyle &&
            backgroundColor == other.backgroundColor &&
            borderColor == other.borderColor &&
            shadowColor == other.shadowColor &&
            textColor == other.textColor &&
            secondaryTextColor == other.secondaryTextColor &&
            iconColor == other.iconColor &&
            disabledTextColor == other.disabledTextColor &&
            disabledIconColor == other.disabledIconColor &&
            hoverColor == other.hoverColor &&
            selectedItemColor == other.selectedItemColor &&
            pressedColor == other.pressedColor &&
            separatorColor == other.separatorColor;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    borderColor,
    shadowColor,
    textColor,
    secondaryTextColor,
    iconColor,
    disabledTextColor,
    disabledIconColor,
    hoverColor,
    selectedItemColor,
    pressedColor,
    separatorColor,
  ]);
}

/// Controls which vertical separators are drawn between grid regions and cells.
enum FdcGridVerticalLines {
  /// Draw vertical column separators through the complete grid viewport.
  fullHeight,

  /// Draw vertical column separators only through the header and currently
  /// visible data rows. Empty viewport space below the last row stays clean.
  rowsOnly,
}

/// Controls which horizontal and vertical cell grid lines are rendered.
enum FdcGridLines {
  /// Do not draw grid lines.
  none,

  /// Draw horizontal row separators only.
  horizontal,

  /// Draw vertical column separators only.
  vertical,

  /// Draw both horizontal and vertical grid lines.
  both,
}

/// Selects when the active-cell indicator is shown for editable and read-only cells.
enum FdcGridCellIndicatorMode {
  /// Highlight the active cell with a line indicator.
  line,

  /// Highlight the active cell with an outline.
  outline,
}

/// Shared visual metrics and colors for grid-owned buttons and compact controls.
class FdcGridControlsStyle {
  /// Creates a [FdcGridControlsStyle].
  const FdcGridControlsStyle({
    this.iconColor,
    this.disabledIconColor,
    this.activeIconColor,
    this.checkboxFillColor,
    this.checkboxCheckColor,
    this.checkboxBorderColor,
    this.checkboxDisabledFillColor,
    this.checkboxDisabledCheckColor,
    this.checkboxDisabledBorderColor,
    this.switchThumbColor,
    this.switchTrackColor,
    this.switchDisabledThumbColor,
    this.switchDisabledTrackColor,
  });

  /// Built-in control palette used by grid icons, checkboxes, and switches when
  /// no control style overrides are supplied.
  static const FdcGridControlsStyle defaults = FdcGridControlsStyle(
    iconColor: Color(0xFF374151),
    disabledIconColor: Color(0xFF9CA3AF),
    activeIconColor: Color(0xFF2563EB),
    checkboxFillColor: Color(0xFF2563EB),
    checkboxCheckColor: Colors.white,
    checkboxBorderColor: Color(0xFF6B7280),
    checkboxDisabledFillColor: Color(0xFFE5E7EB),
    checkboxDisabledCheckColor: Color(0xFF9CA3AF),
    checkboxDisabledBorderColor: Color(0xFFD1D5DB),
    switchThumbColor: Color(0xFF2563EB),
    switchTrackColor: Color(0x662563EB),
    switchDisabledThumbColor: Color(0xFF9CA3AF),
    switchDisabledTrackColor: Color(0xFFE5E7EB),
  );

  /// Default icon color used by built-in grid controls.
  final Color? iconColor;

  /// Icon color used when a built-in grid control is disabled.
  final Color? disabledIconColor;

  /// Icon color used by active built-in grid controls.
  final Color? activeIconColor;

  /// Fill color used by selected grid checkboxes.
  final Color? checkboxFillColor;

  /// Check mark color used by selected grid checkboxes.
  final Color? checkboxCheckColor;

  /// Border color used by unselected grid checkboxes.
  final Color? checkboxBorderColor;

  /// Fill color used by disabled grid checkboxes.
  final Color? checkboxDisabledFillColor;

  /// Check mark color used by disabled selected grid checkboxes.
  final Color? checkboxDisabledCheckColor;

  /// Border color used by disabled grid checkboxes.
  final Color? checkboxDisabledBorderColor;

  /// Thumb color used by enabled active grid switches.
  final Color? switchThumbColor;

  /// Track color used by enabled active grid switches.
  final Color? switchTrackColor;

  /// Thumb color used by disabled grid switches.
  final Color? switchDisabledThumbColor;

  /// Track color used by disabled grid switches.
  final Color? switchDisabledTrackColor;

  /// Creates a copy with selected values replaced.
  FdcGridControlsStyle copyWith({
    Color? iconColor,
    Color? disabledIconColor,
    Color? activeIconColor,
    Color? checkboxFillColor,
    Color? checkboxCheckColor,
    Color? checkboxBorderColor,
    Color? checkboxDisabledFillColor,
    Color? checkboxDisabledCheckColor,
    Color? checkboxDisabledBorderColor,
    Color? switchThumbColor,
    Color? switchTrackColor,
    Color? switchDisabledThumbColor,
    Color? switchDisabledTrackColor,
  }) {
    return FdcGridControlsStyle(
      iconColor: iconColor ?? this.iconColor,
      disabledIconColor: disabledIconColor ?? this.disabledIconColor,
      activeIconColor: activeIconColor ?? this.activeIconColor,
      checkboxFillColor: checkboxFillColor ?? this.checkboxFillColor,
      checkboxCheckColor: checkboxCheckColor ?? this.checkboxCheckColor,
      checkboxBorderColor: checkboxBorderColor ?? this.checkboxBorderColor,
      checkboxDisabledFillColor:
          checkboxDisabledFillColor ?? this.checkboxDisabledFillColor,
      checkboxDisabledCheckColor:
          checkboxDisabledCheckColor ?? this.checkboxDisabledCheckColor,
      checkboxDisabledBorderColor:
          checkboxDisabledBorderColor ?? this.checkboxDisabledBorderColor,
      switchThumbColor: switchThumbColor ?? this.switchThumbColor,
      switchTrackColor: switchTrackColor ?? this.switchTrackColor,
      switchDisabledThumbColor:
          switchDisabledThumbColor ?? this.switchDisabledThumbColor,
      switchDisabledTrackColor:
          switchDisabledTrackColor ?? this.switchDisabledTrackColor,
    );
  }

  /// Returns this style with non-null values from [override] applied.
  FdcGridControlsStyle merge(FdcGridControlsStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcGridControlsStyle(
      iconColor: override.iconColor ?? iconColor,
      disabledIconColor: override.disabledIconColor ?? disabledIconColor,
      activeIconColor: override.activeIconColor ?? activeIconColor,
      checkboxFillColor: override.checkboxFillColor ?? checkboxFillColor,
      checkboxCheckColor: override.checkboxCheckColor ?? checkboxCheckColor,
      checkboxBorderColor: override.checkboxBorderColor ?? checkboxBorderColor,
      checkboxDisabledFillColor:
          override.checkboxDisabledFillColor ?? checkboxDisabledFillColor,
      checkboxDisabledCheckColor:
          override.checkboxDisabledCheckColor ?? checkboxDisabledCheckColor,
      checkboxDisabledBorderColor:
          override.checkboxDisabledBorderColor ?? checkboxDisabledBorderColor,
      switchThumbColor: override.switchThumbColor ?? switchThumbColor,
      switchTrackColor: override.switchTrackColor ?? switchTrackColor,
      switchDisabledThumbColor:
          override.switchDisabledThumbColor ?? switchDisabledThumbColor,
      switchDisabledTrackColor:
          override.switchDisabledTrackColor ?? switchDisabledTrackColor,
    );
  }

  /// Interpolates between two styles for animated theme transitions.
  FdcGridControlsStyle lerp(FdcGridControlsStyle other, double t) {
    return FdcGridControlsStyle(
      iconColor: Color.lerp(iconColor, other.iconColor, t),
      disabledIconColor: Color.lerp(
        disabledIconColor,
        other.disabledIconColor,
        t,
      ),
      activeIconColor: Color.lerp(activeIconColor, other.activeIconColor, t),
      checkboxFillColor: Color.lerp(
        checkboxFillColor,
        other.checkboxFillColor,
        t,
      ),
      checkboxCheckColor: Color.lerp(
        checkboxCheckColor,
        other.checkboxCheckColor,
        t,
      ),
      checkboxBorderColor: Color.lerp(
        checkboxBorderColor,
        other.checkboxBorderColor,
        t,
      ),
      checkboxDisabledFillColor: Color.lerp(
        checkboxDisabledFillColor,
        other.checkboxDisabledFillColor,
        t,
      ),
      checkboxDisabledCheckColor: Color.lerp(
        checkboxDisabledCheckColor,
        other.checkboxDisabledCheckColor,
        t,
      ),
      checkboxDisabledBorderColor: Color.lerp(
        checkboxDisabledBorderColor,
        other.checkboxDisabledBorderColor,
        t,
      ),
      switchThumbColor: Color.lerp(switchThumbColor, other.switchThumbColor, t),
      switchTrackColor: Color.lerp(switchTrackColor, other.switchTrackColor, t),
      switchDisabledThumbColor: Color.lerp(
        switchDisabledThumbColor,
        other.switchDisabledThumbColor,
        t,
      ),
      switchDisabledTrackColor: Color.lerp(
        switchDisabledTrackColor,
        other.switchDisabledTrackColor,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridControlsStyle &&
            iconColor == other.iconColor &&
            disabledIconColor == other.disabledIconColor &&
            activeIconColor == other.activeIconColor &&
            checkboxFillColor == other.checkboxFillColor &&
            checkboxCheckColor == other.checkboxCheckColor &&
            checkboxBorderColor == other.checkboxBorderColor &&
            checkboxDisabledFillColor == other.checkboxDisabledFillColor &&
            checkboxDisabledCheckColor == other.checkboxDisabledCheckColor &&
            checkboxDisabledBorderColor == other.checkboxDisabledBorderColor &&
            switchThumbColor == other.switchThumbColor &&
            switchTrackColor == other.switchTrackColor &&
            switchDisabledThumbColor == other.switchDisabledThumbColor &&
            switchDisabledTrackColor == other.switchDisabledTrackColor;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    iconColor,
    disabledIconColor,
    activeIconColor,
    checkboxFillColor,
    checkboxCheckColor,
    checkboxBorderColor,
    checkboxDisabledFillColor,
    checkboxDisabledCheckColor,
    checkboxDisabledBorderColor,
    switchThumbColor,
    switchTrackColor,
    switchDisabledThumbColor,
    switchDisabledTrackColor,
  ]);
}

/// Placement and text presentation options for dataset progress shown by a grid.
class FdcGridProgressStyle {
  /// Creates a [FdcGridProgressStyle].
  const FdcGridProgressStyle({
    this.color,
    this.backgroundColor,
    this.showText,
    this.textStyle,
    this.height,
    this.borderRadius,
    this.border,
  });

  /// Fallback progress-track height used when [height] is not provided.
  static const double defaultHeight = 22;

  /// Fallback corner radius used when [borderRadius] is not provided.
  static const double defaultBorderRadius = 4;

  /// Built-in progress-indicator geometry and label policy used before caller
  /// overrides are merged.
  static const FdcGridProgressStyle defaults = FdcGridProgressStyle(
    showText: true,
    height: defaultHeight,
    borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadius)),
  );

  /// Filled color for the progress value.
  final Color? color;

  /// Track color behind the progress value.
  final Color? backgroundColor;

  /// Whether textual progress information is rendered with the indicator.
  final bool? showText;

  /// Text style used for the progress label.
  final TextStyle? textStyle;

  /// Height of the progress track.
  final double? height;

  /// Border radius applied to the track and filled region.
  final BorderRadiusGeometry? borderRadius;

  /// Optional border around the progress track.
  final BoxBorder? border;

  /// Creates a copy with selected values replaced.
  FdcGridProgressStyle copyWith({
    Color? color,
    Color? backgroundColor,
    bool? showText,
    TextStyle? textStyle,
    double? height,
    BorderRadiusGeometry? borderRadius,
    BoxBorder? border,
  }) {
    return FdcGridProgressStyle(
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showText: showText ?? this.showText,
      textStyle: textStyle ?? this.textStyle,
      height: height ?? this.height,
      borderRadius: borderRadius ?? this.borderRadius,
      border: border ?? this.border,
    );
  }

  /// Returns this style with non-null values from [override] applied.
  FdcGridProgressStyle merge(FdcGridProgressStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcGridProgressStyle(
      color: override.color ?? color,
      backgroundColor: override.backgroundColor ?? backgroundColor,
      showText: override.showText ?? showText,
      textStyle: textStyle?.merge(override.textStyle) ?? override.textStyle,
      height: override.height ?? height,
      borderRadius: override.borderRadius ?? borderRadius,
      border: override.border ?? border,
    );
  }

  /// Interpolates between two styles for animated theme transitions.
  FdcGridProgressStyle lerp(FdcGridProgressStyle other, double t) {
    return FdcGridProgressStyle(
      color: Color.lerp(color, other.color, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      showText: t < 0.5 ? showText : other.showText,
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      height: lerpDouble(height, other.height, t),
      borderRadius: BorderRadiusGeometry.lerp(
        borderRadius,
        other.borderRadius,
        t,
      ),
      border: t < 0.5 ? border : other.border,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridProgressStyle &&
            color == other.color &&
            backgroundColor == other.backgroundColor &&
            showText == other.showText &&
            textStyle == other.textStyle &&
            height == other.height &&
            borderRadius == other.borderRadius &&
            border == other.border;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    color,
    backgroundColor,
    showText,
    textStyle,
    height,
    borderRadius,
    border,
  ]);
}

/// Fully resolved paint values for the active-cell indicator border.
class FdcGridResolvedCellIndicatorStyle {
  /// Creates a [FdcGridResolvedCellIndicatorStyle].
  const FdcGridResolvedCellIndicatorStyle({
    required this.color,
    required this.thickness,
    this.borderRadius,
  });

  /// The color.
  final Color color;

  /// The thickness.
  final double thickness;

  /// The border radius.
  final BorderRadius? borderRadius;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridResolvedCellIndicatorStyle &&
            color == other.color &&
            thickness == other.thickness &&
            borderRadius == other.borderRadius;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[color, thickness, borderRadius]);
}

/// Configures active-cell indicator colors and geometry for grid interaction states.
class FdcGridCellIndicatorStyle {
  /// Creates a [FdcGridCellIndicatorStyle].
  const FdcGridCellIndicatorStyle({
    this.readOnlyColor,
    this.editableColor,
    this.editingColor,
    this.thickness,
    this.borderRadius,
  });

  /// Built-in active-cell indicator colors and geometry used when no
  /// cell-indicator overrides are supplied.
  static const FdcGridCellIndicatorStyle defaults = FdcGridCellIndicatorStyle(
    readOnlyColor: Color(0xFFFF0000),
    editableColor: Color(0xFF00C853),
    editingColor: Color(0xFF0000FF),
    thickness: 1,
    borderRadius: BorderRadius.all(Radius.circular(2)),
  );

  /// Indicator color for the active cell when it is read-only.
  final Color? readOnlyColor;

  /// Indicator color for an editable active cell outside edit mode.
  final Color? editableColor;

  /// Indicator color while the active cell editor is open.
  final Color? editingColor;

  /// The thickness.
  final double? thickness;

  /// The border radius.
  final BorderRadius? borderRadius;

  /// Creates a copy with selected values replaced.
  FdcGridCellIndicatorStyle copyWith({
    Color? readOnlyColor,
    Color? editableColor,
    Color? editingColor,
    double? thickness,
    BorderRadius? borderRadius,
  }) {
    return FdcGridCellIndicatorStyle(
      readOnlyColor: readOnlyColor ?? this.readOnlyColor,
      editableColor: editableColor ?? this.editableColor,
      editingColor: editingColor ?? this.editingColor,
      thickness: thickness ?? this.thickness,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  /// Returns this style with non-null values from [override] applied.
  FdcGridCellIndicatorStyle merge(FdcGridCellIndicatorStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcGridCellIndicatorStyle(
      readOnlyColor: override.readOnlyColor ?? readOnlyColor,
      editableColor: override.editableColor ?? editableColor,
      editingColor: override.editingColor ?? editingColor,
      thickness: override.thickness ?? thickness,
      borderRadius: override.borderRadius ?? borderRadius,
    );
  }

  /// Interpolates between two styles for animated theme transitions.
  FdcGridCellIndicatorStyle lerp(FdcGridCellIndicatorStyle other, double t) {
    return FdcGridCellIndicatorStyle(
      readOnlyColor: Color.lerp(readOnlyColor, other.readOnlyColor, t),
      editableColor: Color.lerp(editableColor, other.editableColor, t),
      editingColor: Color.lerp(editingColor, other.editingColor, t),
      thickness: lerpDouble(thickness, other.thickness, t),
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridCellIndicatorStyle &&
            readOnlyColor == other.readOnlyColor &&
            editableColor == other.editableColor &&
            editingColor == other.editingColor &&
            thickness == other.thickness &&
            borderRadius == other.borderRadius;
  }

  @override
  int get hashCode => Object.hash(
    readOnlyColor,
    editableColor,
    editingColor,
    thickness,
    borderRadius,
  );
}

/// Visual configuration for the optional filter row below grid headers.
class FdcGridHeaderFilterStyle {
  /// Creates a [FdcGridHeaderFilterStyle].
  const FdcGridHeaderFilterStyle({
    this.backgroundColor,
    this.height,
    this.focusedBorderColor,
    this.unfocusedBorderColor,
    this.focusedBorderWidth,
    this.unfocusedBorderWidth,
    this.focusedLabelColor,
    this.unfocusedLabelColor,
    this.labelTextStyle,
    this.filterIconColor,
    this.activeFilterIconColor,
    this.clearIconColor,
  });

  /// Built-in header-filter geometry and border treatment used before caller
  /// overrides are merged.
  static const FdcGridHeaderFilterStyle defaults = FdcGridHeaderFilterStyle(
    height: FdcGridHeaderMetrics.filterFieldControlHeight,
    unfocusedBorderColor: FdcGridStyle.defaultGridLineColor,
    focusedBorderWidth: 2,
    unfocusedBorderWidth: 1,
  );

  /// Background color used by embedded header filter controls.
  ///
  /// When omitted, the filter control inherits the header background color.
  final Color? backgroundColor;

  /// Height of the embedded header filter control.
  ///
  /// When omitted, the grid uses the built-in default filter control height.
  final double? height;

  /// Border color used when the header filter control has focus.
  final Color? focusedBorderColor;

  /// Border color used when the header filter control does not have focus.
  final Color? unfocusedBorderColor;

  /// Border width used when the header filter control has focus.
  final double? focusedBorderWidth;

  /// Border width used when the header filter control does not have focus.
  final double? unfocusedBorderWidth;

  /// Floating label color used when the header filter control has focus.
  final Color? focusedLabelColor;

  /// Floating label color used when the header filter control does not have
  /// focus.
  final Color? unfocusedLabelColor;

  /// Text style used by the floating label.
  ///
  /// Focused and unfocused label colors are applied over this style.
  final TextStyle? labelTextStyle;

  /// Color used by the inactive header filter operator icon.
  final Color? filterIconColor;

  /// Color used by the active header filter operator icon.
  final Color? activeFilterIconColor;

  /// Color used by the clear-filter icon inside the filter control.
  final Color? clearIconColor;

  /// Creates a copy with selected values replaced.
  FdcGridHeaderFilterStyle copyWith({
    Color? backgroundColor,
    double? height,
    Color? focusedBorderColor,
    Color? unfocusedBorderColor,
    double? focusedBorderWidth,
    double? unfocusedBorderWidth,
    Color? focusedLabelColor,
    Color? unfocusedLabelColor,
    TextStyle? labelTextStyle,
    Color? filterIconColor,
    Color? activeFilterIconColor,
    Color? clearIconColor,
  }) {
    return FdcGridHeaderFilterStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      height: height ?? this.height,
      focusedBorderColor: focusedBorderColor ?? this.focusedBorderColor,
      unfocusedBorderColor: unfocusedBorderColor ?? this.unfocusedBorderColor,
      focusedBorderWidth: focusedBorderWidth ?? this.focusedBorderWidth,
      unfocusedBorderWidth: unfocusedBorderWidth ?? this.unfocusedBorderWidth,
      focusedLabelColor: focusedLabelColor ?? this.focusedLabelColor,
      unfocusedLabelColor: unfocusedLabelColor ?? this.unfocusedLabelColor,
      labelTextStyle: labelTextStyle ?? this.labelTextStyle,
      filterIconColor: filterIconColor ?? this.filterIconColor,
      activeFilterIconColor:
          activeFilterIconColor ?? this.activeFilterIconColor,
      clearIconColor: clearIconColor ?? this.clearIconColor,
    );
  }

  /// Returns this style with non-null values from [override] applied.
  FdcGridHeaderFilterStyle merge(FdcGridHeaderFilterStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcGridHeaderFilterStyle(
      backgroundColor: override.backgroundColor ?? backgroundColor,
      height: override.height ?? height,
      focusedBorderColor: override.focusedBorderColor ?? focusedBorderColor,
      unfocusedBorderColor:
          override.unfocusedBorderColor ?? unfocusedBorderColor,
      focusedBorderWidth: override.focusedBorderWidth ?? focusedBorderWidth,
      unfocusedBorderWidth:
          override.unfocusedBorderWidth ?? unfocusedBorderWidth,
      focusedLabelColor: override.focusedLabelColor ?? focusedLabelColor,
      unfocusedLabelColor: override.unfocusedLabelColor ?? unfocusedLabelColor,
      labelTextStyle: override.labelTextStyle ?? labelTextStyle,
      filterIconColor: override.filterIconColor ?? filterIconColor,
      activeFilterIconColor:
          override.activeFilterIconColor ?? activeFilterIconColor,
      clearIconColor: override.clearIconColor ?? clearIconColor,
    );
  }

  /// Interpolates between two styles for animated theme transitions.
  FdcGridHeaderFilterStyle lerp(FdcGridHeaderFilterStyle other, double t) {
    return FdcGridHeaderFilterStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      height: lerpDouble(height, other.height, t),
      focusedBorderColor: Color.lerp(
        focusedBorderColor,
        other.focusedBorderColor,
        t,
      ),
      unfocusedBorderColor: Color.lerp(
        unfocusedBorderColor,
        other.unfocusedBorderColor,
        t,
      ),
      focusedBorderWidth: lerpDouble(
        focusedBorderWidth,
        other.focusedBorderWidth,
        t,
      ),
      unfocusedBorderWidth: lerpDouble(
        unfocusedBorderWidth,
        other.unfocusedBorderWidth,
        t,
      ),
      focusedLabelColor: Color.lerp(
        focusedLabelColor,
        other.focusedLabelColor,
        t,
      ),
      unfocusedLabelColor: Color.lerp(
        unfocusedLabelColor,
        other.unfocusedLabelColor,
        t,
      ),
      labelTextStyle: TextStyle.lerp(labelTextStyle, other.labelTextStyle, t),
      filterIconColor: Color.lerp(filterIconColor, other.filterIconColor, t),
      activeFilterIconColor: Color.lerp(
        activeFilterIconColor,
        other.activeFilterIconColor,
        t,
      ),
      clearIconColor: Color.lerp(clearIconColor, other.clearIconColor, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridHeaderFilterStyle &&
            backgroundColor == other.backgroundColor &&
            height == other.height &&
            focusedBorderColor == other.focusedBorderColor &&
            unfocusedBorderColor == other.unfocusedBorderColor &&
            focusedBorderWidth == other.focusedBorderWidth &&
            unfocusedBorderWidth == other.unfocusedBorderWidth &&
            focusedLabelColor == other.focusedLabelColor &&
            unfocusedLabelColor == other.unfocusedLabelColor &&
            labelTextStyle == other.labelTextStyle &&
            filterIconColor == other.filterIconColor &&
            activeFilterIconColor == other.activeFilterIconColor &&
            clearIconColor == other.clearIconColor;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    height,
    focusedBorderColor,
    unfocusedBorderColor,
    focusedBorderWidth,
    unfocusedBorderWidth,
    focusedLabelColor,
    unfocusedLabelColor,
    labelTextStyle,
    filterIconColor,
    activeFilterIconColor,
    clearIconColor,
  ]);
}

/// Visual configuration for column headers, separators, and header interaction states.
class FdcGridHeaderStyle {
  /// Creates a [FdcGridHeaderStyle].
  const FdcGridHeaderStyle({
    this.backgroundColor,
    this.textStyle,
    this.groupHeight,
    this.groupBackgroundColor,
    this.groupTextStyle,
    this.groupAlignment,
    this.groupPadding,
    this.groupVerticalSeparatorInset,
    this.verticalSeparatorInset,
  });

  /// Built-in grid-header layout and surface values used when no header-style
  /// overrides are supplied.
  static const FdcGridHeaderStyle defaults = FdcGridHeaderStyle(
    backgroundColor: Colors.white,
    groupHeight: 30,
    groupAlignment: Alignment.center,
    groupPadding: EdgeInsets.symmetric(horizontal: 8),
    verticalSeparatorInset: FdcGridHeaderMetrics.verticalSeparatorInset,
  );

  /// Background color used by the grid header and indicator header.
  final Color? backgroundColor;

  /// Default text style used by grid header labels.
  ///
  /// When omitted, the grid derives the same default from the ambient theme as
  /// before this style grouping: [TextTheme.labelLarge] unchanged.
  final TextStyle? textStyle;

  /// Height of the optional column group header band.
  final double? groupHeight;

  /// Background color used by column group header cells.
  ///
  /// When omitted, the group header uses [backgroundColor].
  final Color? groupBackgroundColor;

  /// Text style used by column group labels.
  final TextStyle? groupTextStyle;

  /// Alignment used for column group labels.
  final Alignment? groupAlignment;

  /// Padding used inside column group header cells.
  final EdgeInsetsGeometry? groupPadding;

  /// Symmetric inset used above and below vertical group header separators.
  ///
  /// When omitted, the group header uses [verticalSeparatorInset]. Set to zero
  /// to render group separators as flat full-height grid lines.
  final double? groupVerticalSeparatorInset;

  /// Symmetric inset used above and below vertical header column separators.
  ///
  /// Set to zero to render header separators as flat full-height grid lines.
  final double? verticalSeparatorInset;

  /// Creates a copy with selected values replaced.
  FdcGridHeaderStyle copyWith({
    Color? backgroundColor,
    TextStyle? textStyle,
    double? groupHeight,
    Color? groupBackgroundColor,
    TextStyle? groupTextStyle,
    Alignment? groupAlignment,
    EdgeInsetsGeometry? groupPadding,
    double? groupVerticalSeparatorInset,
    double? verticalSeparatorInset,
  }) {
    return FdcGridHeaderStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
      groupHeight: groupHeight ?? this.groupHeight,
      groupBackgroundColor: groupBackgroundColor ?? this.groupBackgroundColor,
      groupTextStyle: groupTextStyle ?? this.groupTextStyle,
      groupAlignment: groupAlignment ?? this.groupAlignment,
      groupPadding: groupPadding ?? this.groupPadding,
      groupVerticalSeparatorInset:
          groupVerticalSeparatorInset ?? this.groupVerticalSeparatorInset,
      verticalSeparatorInset:
          verticalSeparatorInset ?? this.verticalSeparatorInset,
    );
  }

  /// Returns this style with non-null values from [override] applied.
  FdcGridHeaderStyle merge(FdcGridHeaderStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcGridHeaderStyle(
      backgroundColor: override.backgroundColor ?? backgroundColor,
      textStyle: override.textStyle ?? textStyle,
      groupHeight: override.groupHeight ?? groupHeight,
      groupBackgroundColor:
          override.groupBackgroundColor ?? groupBackgroundColor,
      groupTextStyle: override.groupTextStyle ?? groupTextStyle,
      groupAlignment: override.groupAlignment ?? groupAlignment,
      groupPadding: override.groupPadding ?? groupPadding,
      groupVerticalSeparatorInset:
          override.groupVerticalSeparatorInset ?? groupVerticalSeparatorInset,
      verticalSeparatorInset:
          override.verticalSeparatorInset ?? verticalSeparatorInset,
    );
  }

  /// Interpolates between two styles for animated theme transitions.
  FdcGridHeaderStyle lerp(FdcGridHeaderStyle other, double t) {
    return FdcGridHeaderStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      groupHeight: lerpDouble(groupHeight, other.groupHeight, t),
      groupBackgroundColor: Color.lerp(
        groupBackgroundColor,
        other.groupBackgroundColor,
        t,
      ),
      groupTextStyle: TextStyle.lerp(groupTextStyle, other.groupTextStyle, t),
      groupAlignment: Alignment.lerp(groupAlignment, other.groupAlignment, t),
      groupPadding: EdgeInsetsGeometry.lerp(
        groupPadding,
        other.groupPadding,
        t,
      ),
      groupVerticalSeparatorInset: lerpDouble(
        groupVerticalSeparatorInset,
        other.groupVerticalSeparatorInset,
        t,
      ),
      verticalSeparatorInset: lerpDouble(
        verticalSeparatorInset,
        other.verticalSeparatorInset,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridHeaderStyle &&
            backgroundColor == other.backgroundColor &&
            textStyle == other.textStyle &&
            groupHeight == other.groupHeight &&
            groupBackgroundColor == other.groupBackgroundColor &&
            groupTextStyle == other.groupTextStyle &&
            groupAlignment == other.groupAlignment &&
            groupPadding == other.groupPadding &&
            groupVerticalSeparatorInset == other.groupVerticalSeparatorInset &&
            verticalSeparatorInset == other.verticalSeparatorInset;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    textStyle,
    groupHeight,
    groupBackgroundColor,
    groupTextStyle,
    groupAlignment,
    groupPadding,
    groupVerticalSeparatorInset,
    verticalSeparatorInset,
  ]);
}

/// Layout and search-control styling for the grid toolbar surface.
class FdcGridToolbarStyle {
  /// Creates a [FdcGridToolbarStyle].
  const FdcGridToolbarStyle({
    this.backgroundColor,
    this.textStyle,
    this.itemTextColor,
    this.itemIconColor,
    this.disabledItemTextColor,
    this.disabledItemIconColor,
    this.height,
    this.padding,
    this.searchExpandedWidth,
    this.searchFieldHeight,
    this.searchFieldBorderRadius,
    this.searchIconColor,
    this.searchClearIconColor,
    this.searchFieldFillColor,
    this.searchFieldBorderColor,
    this.searchFieldFocusedBorderColor,
    this.searchFieldBorderWidth,
    this.searchFieldFocusedBorderWidth,
  });

  /// Fallback toolbar height used when [height] is not provided.
  static const double defaultHeight = 44.0;

  /// Width used for the expanded toolbar search control when no explicit width
  /// is configured.
  static const double defaultSearchExpandedWidth = 310.0;

  /// Height used by the toolbar search field when no search-field height is
  /// configured.
  static const double defaultSearchFieldHeight = 32.0;

  /// Corner radius used by the toolbar search field when no radius is configured.
  static const double defaultSearchFieldBorderRadius = 2.0;

  /// Unfocused toolbar search-field border width used when no override is
  /// configured.
  static const double defaultSearchFieldBorderWidth = 1.0;

  /// Focused toolbar search-field border width used when no override is
  /// configured.
  static const double defaultSearchFieldFocusedBorderWidth = 2.0;

  /// Built-in toolbar dimensions and search-control geometry used before caller
  /// overrides are merged.
  static const FdcGridToolbarStyle defaults = FdcGridToolbarStyle(
    height: defaultHeight,
    padding: EdgeInsets.symmetric(horizontal: 8),
    searchExpandedWidth: defaultSearchExpandedWidth,
    searchFieldHeight: defaultSearchFieldHeight,
    searchFieldBorderRadius: defaultSearchFieldBorderRadius,
    searchFieldBorderWidth: defaultSearchFieldBorderWidth,
    searchFieldFocusedBorderWidth: defaultSearchFieldFocusedBorderWidth,
  );

  /// Background color used by the grid toolbar.
  ///
  /// When omitted, the grid resolves this to the header background color so the
  /// toolbar visually belongs to the same grid shell.
  final Color? backgroundColor;

  /// Text style reserved for toolbar labels/actions.
  final TextStyle? textStyle;

  /// Text/caption color used by built-in and theme-aware toolbar items.
  final Color? itemTextColor;

  /// Icon color used by built-in and theme-aware toolbar items.
  final Color? itemIconColor;

  /// Text/caption color used by disabled built-in and theme-aware toolbar items.
  final Color? disabledItemTextColor;

  /// Icon color used by disabled built-in and theme-aware toolbar items.
  final Color? disabledItemIconColor;

  /// Fixed height of the toolbar shell.
  final double? height;

  /// Internal padding around toolbar content.
  final EdgeInsetsGeometry? padding;

  /// Expanded width of the global search editor inside the toolbar.
  final double? searchExpandedWidth;

  /// Height of the global search editor inside the toolbar.
  final double? searchFieldHeight;

  /// Border radius used by the global search editor.
  final double? searchFieldBorderRadius;

  /// Search action and leading search icon color.
  final Color? searchIconColor;

  /// Clear button icon color inside the search editor.
  final Color? searchClearIconColor;

  /// Fill color used by the search editor.
  final Color? searchFieldFillColor;

  /// Unfocused border color used by the search editor.
  final Color? searchFieldBorderColor;

  /// Focused border color used by the search editor.
  final Color? searchFieldFocusedBorderColor;

  /// Unfocused border width used by the global search editor.
  final double? searchFieldBorderWidth;

  /// Focused border width used by the global search editor.
  final double? searchFieldFocusedBorderWidth;

  /// Creates a copy with selected values replaced.
  FdcGridToolbarStyle copyWith({
    Color? backgroundColor,
    TextStyle? textStyle,
    Color? itemTextColor,
    Color? itemIconColor,
    Color? disabledItemTextColor,
    Color? disabledItemIconColor,
    double? height,
    EdgeInsetsGeometry? padding,
    double? searchExpandedWidth,
    double? searchFieldHeight,
    double? searchFieldBorderRadius,
    Color? searchIconColor,
    Color? searchClearIconColor,
    Color? searchFieldFillColor,
    Color? searchFieldBorderColor,
    Color? searchFieldFocusedBorderColor,
    double? searchFieldBorderWidth,
    double? searchFieldFocusedBorderWidth,
  }) {
    return FdcGridToolbarStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
      itemTextColor: itemTextColor ?? this.itemTextColor,
      itemIconColor: itemIconColor ?? this.itemIconColor,
      disabledItemTextColor:
          disabledItemTextColor ?? this.disabledItemTextColor,
      disabledItemIconColor:
          disabledItemIconColor ?? this.disabledItemIconColor,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      searchExpandedWidth: searchExpandedWidth ?? this.searchExpandedWidth,
      searchFieldHeight: searchFieldHeight ?? this.searchFieldHeight,
      searchFieldBorderRadius:
          searchFieldBorderRadius ?? this.searchFieldBorderRadius,
      searchIconColor: searchIconColor ?? this.searchIconColor,
      searchClearIconColor: searchClearIconColor ?? this.searchClearIconColor,
      searchFieldFillColor: searchFieldFillColor ?? this.searchFieldFillColor,
      searchFieldBorderColor:
          searchFieldBorderColor ?? this.searchFieldBorderColor,
      searchFieldFocusedBorderColor:
          searchFieldFocusedBorderColor ?? this.searchFieldFocusedBorderColor,
      searchFieldBorderWidth:
          searchFieldBorderWidth ?? this.searchFieldBorderWidth,
      searchFieldFocusedBorderWidth:
          searchFieldFocusedBorderWidth ?? this.searchFieldFocusedBorderWidth,
    );
  }

  /// Returns this style with non-null values from [override] applied.
  FdcGridToolbarStyle merge(FdcGridToolbarStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcGridToolbarStyle(
      backgroundColor: override.backgroundColor ?? backgroundColor,
      textStyle: override.textStyle ?? textStyle,
      itemTextColor: override.itemTextColor ?? itemTextColor,
      itemIconColor: override.itemIconColor ?? itemIconColor,
      disabledItemTextColor:
          override.disabledItemTextColor ?? disabledItemTextColor,
      disabledItemIconColor:
          override.disabledItemIconColor ?? disabledItemIconColor,
      height: override.height ?? height,
      padding: override.padding ?? padding,
      searchExpandedWidth: override.searchExpandedWidth ?? searchExpandedWidth,
      searchFieldHeight: override.searchFieldHeight ?? searchFieldHeight,
      searchFieldBorderRadius:
          override.searchFieldBorderRadius ?? searchFieldBorderRadius,
      searchIconColor: override.searchIconColor ?? searchIconColor,
      searchClearIconColor:
          override.searchClearIconColor ?? searchClearIconColor,
      searchFieldFillColor:
          override.searchFieldFillColor ?? searchFieldFillColor,
      searchFieldBorderColor:
          override.searchFieldBorderColor ?? searchFieldBorderColor,
      searchFieldFocusedBorderColor:
          override.searchFieldFocusedBorderColor ??
          searchFieldFocusedBorderColor,
      searchFieldBorderWidth:
          override.searchFieldBorderWidth ?? searchFieldBorderWidth,
      searchFieldFocusedBorderWidth:
          override.searchFieldFocusedBorderWidth ??
          searchFieldFocusedBorderWidth,
    );
  }

  /// Interpolates between two styles for animated theme transitions.
  FdcGridToolbarStyle lerp(FdcGridToolbarStyle other, double t) {
    return FdcGridToolbarStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      itemTextColor: Color.lerp(itemTextColor, other.itemTextColor, t),
      itemIconColor: Color.lerp(itemIconColor, other.itemIconColor, t),
      disabledItemTextColor: Color.lerp(
        disabledItemTextColor,
        other.disabledItemTextColor,
        t,
      ),
      disabledItemIconColor: Color.lerp(
        disabledItemIconColor,
        other.disabledItemIconColor,
        t,
      ),
      height: lerpDouble(height, other.height, t),
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t),
      searchExpandedWidth: lerpDouble(
        searchExpandedWidth,
        other.searchExpandedWidth,
        t,
      ),
      searchFieldHeight: lerpDouble(
        searchFieldHeight,
        other.searchFieldHeight,
        t,
      ),
      searchFieldBorderRadius: lerpDouble(
        searchFieldBorderRadius,
        other.searchFieldBorderRadius,
        t,
      ),
      searchIconColor: Color.lerp(searchIconColor, other.searchIconColor, t),
      searchClearIconColor: Color.lerp(
        searchClearIconColor,
        other.searchClearIconColor,
        t,
      ),
      searchFieldFillColor: Color.lerp(
        searchFieldFillColor,
        other.searchFieldFillColor,
        t,
      ),
      searchFieldBorderColor: Color.lerp(
        searchFieldBorderColor,
        other.searchFieldBorderColor,
        t,
      ),
      searchFieldFocusedBorderColor: Color.lerp(
        searchFieldFocusedBorderColor,
        other.searchFieldFocusedBorderColor,
        t,
      ),
      searchFieldBorderWidth: lerpDouble(
        searchFieldBorderWidth,
        other.searchFieldBorderWidth,
        t,
      ),
      searchFieldFocusedBorderWidth: lerpDouble(
        searchFieldFocusedBorderWidth,
        other.searchFieldFocusedBorderWidth,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridToolbarStyle &&
            backgroundColor == other.backgroundColor &&
            textStyle == other.textStyle &&
            itemTextColor == other.itemTextColor &&
            itemIconColor == other.itemIconColor &&
            disabledItemTextColor == other.disabledItemTextColor &&
            disabledItemIconColor == other.disabledItemIconColor &&
            height == other.height &&
            padding == other.padding &&
            searchExpandedWidth == other.searchExpandedWidth &&
            searchFieldHeight == other.searchFieldHeight &&
            searchFieldBorderRadius == other.searchFieldBorderRadius &&
            searchIconColor == other.searchIconColor &&
            searchClearIconColor == other.searchClearIconColor &&
            searchFieldFillColor == other.searchFieldFillColor &&
            searchFieldBorderColor == other.searchFieldBorderColor &&
            searchFieldFocusedBorderColor ==
                other.searchFieldFocusedBorderColor &&
            searchFieldBorderWidth == other.searchFieldBorderWidth &&
            searchFieldFocusedBorderWidth ==
                other.searchFieldFocusedBorderWidth;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    textStyle,
    itemTextColor,
    itemIconColor,
    disabledItemTextColor,
    disabledItemIconColor,
    height,
    padding,
    searchExpandedWidth,
    searchFieldHeight,
    searchFieldBorderRadius,
    searchIconColor,
    searchClearIconColor,
    searchFieldFillColor,
    searchFieldBorderColor,
    searchFieldFocusedBorderColor,
    searchFieldBorderWidth,
    searchFieldFocusedBorderWidth,
  ]);
}

/// Visual configuration for the aggregate summary row below the viewport.
class FdcGridSummaryStyle {
  /// Creates a [FdcGridSummaryStyle].
  const FdcGridSummaryStyle({
    this.backgroundColor,
    this.showTopSeparator,
    this.textStyle,
    this.height,
    this.padding,
    this.showVerticalSeparators,
    this.verticalSeparatorInset,
  });

  /// Built-in summary-row separators and spacing used when no summary-style
  /// overrides are supplied.
  static const FdcGridSummaryStyle defaults = FdcGridSummaryStyle(
    padding: EdgeInsets.symmetric(horizontal: 10),
    showTopSeparator: true,
    showVerticalSeparators: true,
    verticalSeparatorInset: FdcGridHeaderMetrics.verticalSeparatorInset,
  );

  /// Background color used by the grid summary row panel.
  ///
  /// When omitted, the grid resolves this to the grid viewport background so
  /// the summary row reads as part of the data body.
  final Color? backgroundColor;

  /// Whether the summary row draws a top separator between the grid viewport
  /// and the summary row.
  final bool? showTopSeparator;

  /// Text style reserved for future summary labels/values.
  final TextStyle? textStyle;

  /// Fixed height of the summary row panel.
  ///
  /// When omitted, the grid uses the configured grid row height.
  final double? height;

  /// Internal padding reserved for future summary row content.
  final EdgeInsetsGeometry? padding;

  /// Whether summary aggregate cells draw vertical separator lines.
  ///
  /// This controls only the summary row aggregate cell separators. The row still
  /// respects the grid line visibility, so vertical separators are visible only
  /// when vertical grid lines are enabled globally and this flag is true.
  final bool? showVerticalSeparators;

  /// Symmetric inset used above and below vertical summary cell separators.
  ///
  /// Defaults to the same inset used by header column separators. Set to zero
  /// to render full-height summary separators.
  final double? verticalSeparatorInset;

  /// Creates a copy with selected values replaced.
  FdcGridSummaryStyle copyWith({
    Color? backgroundColor,
    bool? showTopSeparator,
    TextStyle? textStyle,
    double? height,
    EdgeInsetsGeometry? padding,
    bool? showVerticalSeparators,
    double? verticalSeparatorInset,
  }) {
    return FdcGridSummaryStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showTopSeparator: showTopSeparator ?? this.showTopSeparator,
      textStyle: textStyle ?? this.textStyle,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      showVerticalSeparators:
          showVerticalSeparators ?? this.showVerticalSeparators,
      verticalSeparatorInset:
          verticalSeparatorInset ?? this.verticalSeparatorInset,
    );
  }

  /// Returns this style with non-null values from [override] applied.
  FdcGridSummaryStyle merge(FdcGridSummaryStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcGridSummaryStyle(
      backgroundColor: override.backgroundColor ?? backgroundColor,
      showTopSeparator: override.showTopSeparator ?? showTopSeparator,
      textStyle: override.textStyle ?? textStyle,
      height: override.height ?? height,
      padding: override.padding ?? padding,
      showVerticalSeparators:
          override.showVerticalSeparators ?? showVerticalSeparators,
      verticalSeparatorInset:
          override.verticalSeparatorInset ?? verticalSeparatorInset,
    );
  }

  /// Interpolates between two styles for animated theme transitions.
  FdcGridSummaryStyle lerp(FdcGridSummaryStyle other, double t) {
    return FdcGridSummaryStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      showTopSeparator: t < 0.5 ? showTopSeparator : other.showTopSeparator,
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      height: lerpDouble(height, other.height, t),
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t),
      showVerticalSeparators: t < 0.5
          ? showVerticalSeparators
          : other.showVerticalSeparators,
      verticalSeparatorInset: lerpDouble(
        verticalSeparatorInset,
        other.verticalSeparatorInset,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridSummaryStyle &&
            backgroundColor == other.backgroundColor &&
            showTopSeparator == other.showTopSeparator &&
            textStyle == other.textStyle &&
            height == other.height &&
            padding == other.padding &&
            showVerticalSeparators == other.showVerticalSeparators &&
            verticalSeparatorInset == other.verticalSeparatorInset;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    showTopSeparator,
    textStyle,
    height,
    padding,
    showVerticalSeparators,
    verticalSeparatorInset,
  ]);
}

/// Layout and surface styling for the grid status bar and its item zones.
class FdcGridStatusBarStyle {
  /// Creates a [FdcGridStatusBarStyle].
  const FdcGridStatusBarStyle({
    this.backgroundColor,
    this.textStyle,
    this.height,
    this.padding,
  });

  /// Fallback status-bar height used when [height] is not provided.
  static const double defaultHeight = 28.0;

  /// Built-in status-bar height and padding used before caller overrides are
  /// merged.
  static const FdcGridStatusBarStyle defaults = FdcGridStatusBarStyle(
    height: defaultHeight,
    padding: EdgeInsets.symmetric(horizontal: 10),
  );

  /// Background color used by the grid status bar.
  ///
  /// When omitted, the grid resolves this to the header background color so
  /// the footer visually belongs to the same shell as the header.
  final Color? backgroundColor;

  /// Text style used by the status bar content.
  final TextStyle? textStyle;

  /// Fixed height of the status bar.
  final double? height;

  /// Internal padding around the status bar content.
  final EdgeInsetsGeometry? padding;

  /// Creates a copy with selected values replaced.
  FdcGridStatusBarStyle copyWith({
    Color? backgroundColor,
    TextStyle? textStyle,
    double? height,
    EdgeInsetsGeometry? padding,
  }) {
    return FdcGridStatusBarStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
      height: height ?? this.height,
      padding: padding ?? this.padding,
    );
  }

  /// Returns this style with non-null values from [override] applied.
  FdcGridStatusBarStyle merge(FdcGridStatusBarStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcGridStatusBarStyle(
      backgroundColor: override.backgroundColor ?? backgroundColor,
      textStyle: override.textStyle ?? textStyle,
      height: override.height ?? height,
      padding: override.padding ?? padding,
    );
  }

  /// Interpolates between two styles for animated theme transitions.
  FdcGridStatusBarStyle lerp(FdcGridStatusBarStyle other, double t) {
    return FdcGridStatusBarStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      height: lerpDouble(height, other.height, t),
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridStatusBarStyle &&
            backgroundColor == other.backgroundColor &&
            textStyle == other.textStyle &&
            height == other.height &&
            padding == other.padding;
  }

  @override
  int get hashCode =>
      Object.hashAll(<Object?>[backgroundColor, textStyle, height, padding]);
}

/// Visual style configuration for an `FdcGrid`.
///
/// The style controls grid presentation without changing dataset behavior or
/// interaction semantics.
class FdcGridStyle {
  /// Creates a [FdcGridStyle].
  const FdcGridStyle({
    this.gridLines,
    this.gridLineColor,
    this.pinnedSeparatorInset,
    this.verticalGridLines,
    this.borderColor,
    this.backgroundColor,
    this.rowIndicatorBackgroundColor,
    this.cellTextStyle,
    this.disabledCellBackgroundColor,
    this.selectedCellBackgroundColor,
    this.selectedRowColor,
  });

  /// Fallback line and border color used by the built-in grid style.
  static const Color defaultGridLineColor = Color(0xFFE5E7EB);

  /// Built-in grid surface, line, border, and selection treatment used before
  /// caller overrides are merged.
  static const FdcGridStyle defaults = FdcGridStyle(
    backgroundColor: Colors.white,
    disabledCellBackgroundColor: Colors.transparent,
    selectedCellBackgroundColor: Colors.transparent,
    gridLines: FdcGridLines.both,
    gridLineColor: defaultGridLineColor,
    verticalGridLines: FdcGridVerticalLines.rowsOnly,
    borderColor: defaultGridLineColor,
    selectedRowColor: Colors.transparent,
  );

  /// Controls which internal grid lines are rendered.
  final FdcGridLines? gridLines;

  /// Color used for all internal grid lines and shell separators.
  final Color? gridLineColor;

  /// Empty space above and below pinned-region separators.
  ///
  /// Defaults to zero, preserving the full-height pinned divider.
  final double? pinnedSeparatorInset;

  /// Controls whether vertical grid lines stop at rendered rows or continue
  /// through the full viewport height.
  final FdcGridVerticalLines? verticalGridLines;

  /// Color used for the outer border around the grid control.
  ///
  /// Defaults to the same system light gray used by internal grid lines.
  final Color? borderColor;

  /// Background color used for the grid viewport surface, including the empty
  /// body area below the last rendered data row.
  final Color? backgroundColor;

  /// Background color used by the leading row indicator body region.
  ///
  /// When omitted, the row indicator body uses [backgroundColor]. The row
  /// indicator header continues to use the header background color.
  final Color? rowIndicatorBackgroundColor;

  /// Default text style used by grid cells.
  ///
  /// Column-level cell text styles are merged over this style.
  final TextStyle? cellTextStyle;

  /// Background color used by disabled/read-only grid cells when the grid
  /// renders a disabled column.
  ///
  /// Defaults to transparent so read-only state is communicated by the cell
  /// indicator instead of a separate cell fill. Set this explicitly when an
  /// application wants disabled cells to have a visual background.
  final Color? disabledCellBackgroundColor;

  /// Background color used by the active/current grid cell.
  ///
  /// Defaults to transparent so the active cell does not introduce a fill
  /// color unless the grid style/theme explicitly asks for one.
  final Color? selectedCellBackgroundColor;

  /// Background color applied to selected grid rows.
  final Color? selectedRowColor;

  /// Creates a copy with selected values replaced.
  FdcGridStyle copyWith({
    FdcGridLines? gridLines,
    Color? gridLineColor,
    double? pinnedSeparatorInset,
    FdcGridVerticalLines? verticalGridLines,
    Color? borderColor,
    Color? backgroundColor,
    Color? rowIndicatorBackgroundColor,
    TextStyle? cellTextStyle,
    Color? disabledCellBackgroundColor,
    Color? selectedCellBackgroundColor,
    Color? selectedRowColor,
  }) {
    return FdcGridStyle(
      gridLines: gridLines ?? this.gridLines,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      pinnedSeparatorInset: pinnedSeparatorInset ?? this.pinnedSeparatorInset,
      verticalGridLines: verticalGridLines ?? this.verticalGridLines,
      borderColor: borderColor ?? this.borderColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      rowIndicatorBackgroundColor:
          rowIndicatorBackgroundColor ?? this.rowIndicatorBackgroundColor,
      cellTextStyle: cellTextStyle ?? this.cellTextStyle,
      disabledCellBackgroundColor:
          disabledCellBackgroundColor ?? this.disabledCellBackgroundColor,
      selectedCellBackgroundColor:
          selectedCellBackgroundColor ?? this.selectedCellBackgroundColor,
      selectedRowColor: selectedRowColor ?? this.selectedRowColor,
    );
  }

  /// Returns this style with non-null values from [override] applied.
  FdcGridStyle merge(FdcGridStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcGridStyle(
      gridLines: override.gridLines ?? gridLines,
      gridLineColor: override.gridLineColor ?? gridLineColor,
      pinnedSeparatorInset:
          override.pinnedSeparatorInset ?? pinnedSeparatorInset,
      verticalGridLines: override.verticalGridLines ?? verticalGridLines,
      borderColor: override.borderColor ?? borderColor,
      backgroundColor: override.backgroundColor ?? backgroundColor,
      rowIndicatorBackgroundColor:
          override.rowIndicatorBackgroundColor ?? rowIndicatorBackgroundColor,
      cellTextStyle: override.cellTextStyle ?? cellTextStyle,
      disabledCellBackgroundColor:
          override.disabledCellBackgroundColor ?? disabledCellBackgroundColor,
      selectedCellBackgroundColor:
          override.selectedCellBackgroundColor ?? selectedCellBackgroundColor,
      selectedRowColor: override.selectedRowColor ?? selectedRowColor,
    );
  }

  /// Interpolates between two styles for animated theme transitions.
  FdcGridStyle lerp(FdcGridStyle other, double t) {
    return FdcGridStyle(
      gridLines: t < 0.5 ? gridLines : other.gridLines,
      gridLineColor: Color.lerp(gridLineColor, other.gridLineColor, t),
      pinnedSeparatorInset: lerpDouble(
        pinnedSeparatorInset,
        other.pinnedSeparatorInset,
        t,
      ),
      verticalGridLines: t < 0.5 ? verticalGridLines : other.verticalGridLines,
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      rowIndicatorBackgroundColor: Color.lerp(
        rowIndicatorBackgroundColor,
        other.rowIndicatorBackgroundColor,
        t,
      ),
      cellTextStyle: TextStyle.lerp(cellTextStyle, other.cellTextStyle, t),
      disabledCellBackgroundColor: Color.lerp(
        disabledCellBackgroundColor,
        other.disabledCellBackgroundColor,
        t,
      ),
      selectedCellBackgroundColor: Color.lerp(
        selectedCellBackgroundColor,
        other.selectedCellBackgroundColor,
        t,
      ),
      selectedRowColor: Color.lerp(selectedRowColor, other.selectedRowColor, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridStyle &&
            gridLines == other.gridLines &&
            gridLineColor == other.gridLineColor &&
            pinnedSeparatorInset == other.pinnedSeparatorInset &&
            verticalGridLines == other.verticalGridLines &&
            borderColor == other.borderColor &&
            backgroundColor == other.backgroundColor &&
            rowIndicatorBackgroundColor == other.rowIndicatorBackgroundColor &&
            cellTextStyle == other.cellTextStyle &&
            disabledCellBackgroundColor == other.disabledCellBackgroundColor &&
            selectedCellBackgroundColor == other.selectedCellBackgroundColor &&
            selectedRowColor == other.selectedRowColor;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    gridLines,
    gridLineColor,
    pinnedSeparatorInset,
    verticalGridLines,
    borderColor,
    backgroundColor,
    rowIndicatorBackgroundColor,
    cellTextStyle,
    disabledCellBackgroundColor,
    selectedCellBackgroundColor,
    selectedRowColor,
  ]);
}
