// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Visual styling for text-like FDC editor inputs.
///
/// All properties are optional so partial styles can be merged over theme
/// defaults or inherited editor theme data.
class FdcEditorInputStyle {
  /// Creates a [FdcEditorInputStyle].
  const FdcEditorInputStyle({
    this.fillColor,
    this.focusedFillColor,
    this.readOnlyFillColor,
    this.disabledFillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.disabledBorderColor,
    this.readOnlyBorderColor,
    this.borderWidth,
    this.focusedBorderWidth,
    this.errorBorderWidth,
    this.borderRadius,
    this.contentPadding,
    this.textStyle,
    this.labelStyle,
    this.floatingLabelStyle,
    this.hintStyle,
    this.errorStyle,
    this.cursorColor,
  });

  /// Fully resolved fallback style used as the base of style merging.
  static const FdcEditorInputStyle defaults = FdcEditorInputStyle(
    fillColor: Color(0xFFFFFFFF),
    focusedFillColor: Color(0xFFFFFFFF),
    readOnlyFillColor: Color(0xFFF3F4F6),
    disabledFillColor: Color(0xFFE5E7EB),
    borderColor: Color(0xFFD1D5DB),
    focusedBorderColor: Color(0xFF2563EB),
    errorBorderColor: Color(0xFFD32F2F),
    disabledBorderColor: Color(0xFFD1D5DB),
    readOnlyBorderColor: Color(0xFFD1D5DB),
    borderWidth: 1,
    focusedBorderWidth: 2,
    errorBorderWidth: 1,
    borderRadius: BorderRadius.all(Radius.circular(4)),
  );

  /// Background fill color for the editor surface.
  final Color? fillColor;

  /// Background fill color while the editor has focus.
  final Color? focusedFillColor;

  /// Background fill color for read-only editors.
  final Color? readOnlyFillColor;

  /// Background fill color for disabled editors.
  final Color? disabledFillColor;

  /// Border color in the normal state.
  final Color? borderColor;

  /// Border color while the editor has focus.
  final Color? focusedBorderColor;

  /// Border color while the editor reports an error.
  final Color? errorBorderColor;

  /// Border color for disabled editors.
  final Color? disabledBorderColor;

  /// Border color for read-only editors.
  final Color? readOnlyBorderColor;

  /// Border width in logical pixels for the normal state.
  final double? borderWidth;

  /// Border width in logical pixels while focused.
  final double? focusedBorderWidth;

  /// Border width in logical pixels while reporting an error.
  final double? errorBorderWidth;

  /// Corner radius of the editor surface.
  final BorderRadiusGeometry? borderRadius;

  /// Padding inside the editor input surface.
  final EdgeInsetsGeometry? contentPadding;

  /// Text style for editor values.
  final TextStyle? textStyle;

  /// Text style for editor labels.
  final TextStyle? labelStyle;

  /// Text style for floating input labels.
  final TextStyle? floatingLabelStyle;

  /// Text style for input hint text.
  final TextStyle? hintStyle;

  /// Text style for inline validation messages.
  final TextStyle? errorStyle;

  /// Text cursor color.
  final Color? cursorColor;

  /// Creates a copy with selected values replaced.
  FdcEditorInputStyle copyWith({
    Color? fillColor,
    Color? focusedFillColor,
    Color? readOnlyFillColor,
    Color? disabledFillColor,
    Color? borderColor,
    Color? focusedBorderColor,
    Color? errorBorderColor,
    Color? disabledBorderColor,
    Color? readOnlyBorderColor,
    double? borderWidth,
    double? focusedBorderWidth,
    double? errorBorderWidth,
    BorderRadiusGeometry? borderRadius,
    EdgeInsetsGeometry? contentPadding,
    TextStyle? textStyle,
    TextStyle? labelStyle,
    TextStyle? floatingLabelStyle,
    TextStyle? hintStyle,
    TextStyle? errorStyle,
    Color? cursorColor,
  }) {
    return FdcEditorInputStyle(
      fillColor: fillColor ?? this.fillColor,
      focusedFillColor: focusedFillColor ?? this.focusedFillColor,
      readOnlyFillColor: readOnlyFillColor ?? this.readOnlyFillColor,
      disabledFillColor: disabledFillColor ?? this.disabledFillColor,
      borderColor: borderColor ?? this.borderColor,
      focusedBorderColor: focusedBorderColor ?? this.focusedBorderColor,
      errorBorderColor: errorBorderColor ?? this.errorBorderColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      readOnlyBorderColor: readOnlyBorderColor ?? this.readOnlyBorderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      focusedBorderWidth: focusedBorderWidth ?? this.focusedBorderWidth,
      errorBorderWidth: errorBorderWidth ?? this.errorBorderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      contentPadding: contentPadding ?? this.contentPadding,
      textStyle: textStyle ?? this.textStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      floatingLabelStyle: floatingLabelStyle ?? this.floatingLabelStyle,
      hintStyle: hintStyle ?? this.hintStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      cursorColor: cursorColor ?? this.cursorColor,
    );
  }

  /// Merges non-null properties from [override] over this style.
  FdcEditorInputStyle merge(FdcEditorInputStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcEditorInputStyle(
      fillColor: override.fillColor ?? fillColor,
      focusedFillColor: override.focusedFillColor ?? focusedFillColor,
      readOnlyFillColor: override.readOnlyFillColor ?? readOnlyFillColor,
      disabledFillColor: override.disabledFillColor ?? disabledFillColor,
      borderColor: override.borderColor ?? borderColor,
      focusedBorderColor: override.focusedBorderColor ?? focusedBorderColor,
      errorBorderColor: override.errorBorderColor ?? errorBorderColor,
      disabledBorderColor: override.disabledBorderColor ?? disabledBorderColor,
      readOnlyBorderColor: override.readOnlyBorderColor ?? readOnlyBorderColor,
      borderWidth: override.borderWidth ?? borderWidth,
      focusedBorderWidth: override.focusedBorderWidth ?? focusedBorderWidth,
      errorBorderWidth: override.errorBorderWidth ?? errorBorderWidth,
      borderRadius: override.borderRadius ?? borderRadius,
      contentPadding: override.contentPadding ?? contentPadding,
      textStyle: textStyle?.merge(override.textStyle) ?? override.textStyle,
      labelStyle: labelStyle?.merge(override.labelStyle) ?? override.labelStyle,
      floatingLabelStyle:
          floatingLabelStyle?.merge(override.floatingLabelStyle) ??
          override.floatingLabelStyle,
      hintStyle: hintStyle?.merge(override.hintStyle) ?? override.hintStyle,
      errorStyle: errorStyle?.merge(override.errorStyle) ?? override.errorStyle,
      cursorColor: override.cursorColor ?? cursorColor,
    );
  }

  /// Linearly interpolates this style toward [other] by [t].
  FdcEditorInputStyle lerp(FdcEditorInputStyle other, double t) {
    return FdcEditorInputStyle(
      fillColor: Color.lerp(fillColor, other.fillColor, t),
      focusedFillColor: Color.lerp(focusedFillColor, other.focusedFillColor, t),
      readOnlyFillColor: Color.lerp(
        readOnlyFillColor,
        other.readOnlyFillColor,
        t,
      ),
      disabledFillColor: Color.lerp(
        disabledFillColor,
        other.disabledFillColor,
        t,
      ),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      focusedBorderColor: Color.lerp(
        focusedBorderColor,
        other.focusedBorderColor,
        t,
      ),
      errorBorderColor: Color.lerp(errorBorderColor, other.errorBorderColor, t),
      disabledBorderColor: Color.lerp(
        disabledBorderColor,
        other.disabledBorderColor,
        t,
      ),
      readOnlyBorderColor: Color.lerp(
        readOnlyBorderColor,
        other.readOnlyBorderColor,
        t,
      ),
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t),
      focusedBorderWidth: lerpDouble(
        focusedBorderWidth,
        other.focusedBorderWidth,
        t,
      ),
      errorBorderWidth: lerpDouble(errorBorderWidth, other.errorBorderWidth, t),
      borderRadius: BorderRadiusGeometry.lerp(
        borderRadius,
        other.borderRadius,
        t,
      ),
      contentPadding: EdgeInsetsGeometry.lerp(
        contentPadding,
        other.contentPadding,
        t,
      ),
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      floatingLabelStyle: TextStyle.lerp(
        floatingLabelStyle,
        other.floatingLabelStyle,
        t,
      ),
      hintStyle: TextStyle.lerp(hintStyle, other.hintStyle, t),
      errorStyle: TextStyle.lerp(errorStyle, other.errorStyle, t),
      cursorColor: Color.lerp(cursorColor, other.cursorColor, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcEditorInputStyle &&
            fillColor == other.fillColor &&
            focusedFillColor == other.focusedFillColor &&
            readOnlyFillColor == other.readOnlyFillColor &&
            disabledFillColor == other.disabledFillColor &&
            borderColor == other.borderColor &&
            focusedBorderColor == other.focusedBorderColor &&
            errorBorderColor == other.errorBorderColor &&
            disabledBorderColor == other.disabledBorderColor &&
            readOnlyBorderColor == other.readOnlyBorderColor &&
            borderWidth == other.borderWidth &&
            focusedBorderWidth == other.focusedBorderWidth &&
            errorBorderWidth == other.errorBorderWidth &&
            borderRadius == other.borderRadius &&
            contentPadding == other.contentPadding &&
            textStyle == other.textStyle &&
            labelStyle == other.labelStyle &&
            floatingLabelStyle == other.floatingLabelStyle &&
            hintStyle == other.hintStyle &&
            errorStyle == other.errorStyle &&
            cursorColor == other.cursorColor;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    fillColor,
    focusedFillColor,
    readOnlyFillColor,
    disabledFillColor,
    borderColor,
    focusedBorderColor,
    errorBorderColor,
    disabledBorderColor,
    readOnlyBorderColor,
    borderWidth,
    focusedBorderWidth,
    errorBorderWidth,
    borderRadius,
    contentPadding,
    textStyle,
    labelStyle,
    floatingLabelStyle,
    hintStyle,
    errorStyle,
    cursorColor,
  ]);
}

/// Visual styling for non-text editor controls such as boolean and combo UI.
///
/// Partial styles can be merged over the resolved editor theme.
class FdcEditorControlsStyle {
  /// Creates a [FdcEditorControlsStyle].
  const FdcEditorControlsStyle({
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
    this.labelStyle,
    this.disabledLabelStyle,
  });

  /// Fully resolved fallback style used as the base of style merging.
  static const FdcEditorControlsStyle defaults = FdcEditorControlsStyle(
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

  /// Color of enabled control icons.
  final Color? iconColor;

  /// Color of disabled control icons.
  final Color? disabledIconColor;

  /// Color of active or selected control icons.
  final Color? activeIconColor;

  /// Fill color of enabled checkboxes.
  final Color? checkboxFillColor;

  /// Checkmark color of enabled checkboxes.
  final Color? checkboxCheckColor;

  /// Border color of enabled checkboxes.
  final Color? checkboxBorderColor;

  /// Fill color of disabled checkboxes.
  final Color? checkboxDisabledFillColor;

  /// Checkmark color of disabled checkboxes.
  final Color? checkboxDisabledCheckColor;

  /// Border color of disabled checkboxes.
  final Color? checkboxDisabledBorderColor;

  /// Thumb color of enabled switches.
  final Color? switchThumbColor;

  /// Track color of enabled switches.
  final Color? switchTrackColor;

  /// Thumb color of disabled switches.
  final Color? switchDisabledThumbColor;

  /// Track color of disabled switches.
  final Color? switchDisabledTrackColor;

  /// Text style for editor labels.
  final TextStyle? labelStyle;

  /// Text style for labels of disabled controls.
  final TextStyle? disabledLabelStyle;

  /// Creates a copy with selected values replaced.
  FdcEditorControlsStyle copyWith({
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
    TextStyle? labelStyle,
    TextStyle? disabledLabelStyle,
  }) {
    return FdcEditorControlsStyle(
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
      labelStyle: labelStyle ?? this.labelStyle,
      disabledLabelStyle: disabledLabelStyle ?? this.disabledLabelStyle,
    );
  }

  /// Merges non-null properties from [override] over this style.
  FdcEditorControlsStyle merge(FdcEditorControlsStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcEditorControlsStyle(
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
      labelStyle: labelStyle?.merge(override.labelStyle) ?? override.labelStyle,
      disabledLabelStyle:
          disabledLabelStyle?.merge(override.disabledLabelStyle) ??
          override.disabledLabelStyle,
    );
  }

  /// Linearly interpolates this style toward [other] by [t].
  FdcEditorControlsStyle lerp(FdcEditorControlsStyle other, double t) {
    return FdcEditorControlsStyle(
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
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      disabledLabelStyle: TextStyle.lerp(
        disabledLabelStyle,
        other.disabledLabelStyle,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcEditorControlsStyle &&
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
            switchDisabledTrackColor == other.switchDisabledTrackColor &&
            labelStyle == other.labelStyle &&
            disabledLabelStyle == other.disabledLabelStyle;
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
    labelStyle,
    disabledLabelStyle,
  ]);
}

/// Visual styling for combo-editor popup surfaces, search UI, and option rows.
///
/// Partial styles can be merged over the resolved editor theme.
class FdcEditorComboPopupStyle {
  /// Creates a [FdcEditorComboPopupStyle].
  const FdcEditorComboPopupStyle({
    this.backgroundColor,
    this.surfaceTintColor,
    this.shadowColor,
    this.borderColor,
    this.elevation,
    this.borderRadius,
    this.itemTextStyle,
    this.highlightedItemColor,
    this.selectedIconColor,
    this.emptyTextStyle,
    this.searchFillColor,
    this.searchTextStyle,
    this.searchHintStyle,
    this.searchIconColor,
    this.searchClearIconColor,
    this.searchBorderColor,
    this.searchFocusedBorderColor,
    this.searchBorderWidth,
    this.searchFocusedBorderWidth,
    this.searchBorderRadius,
  });

  /// Fully resolved fallback style used as the base of style merging.
  static const FdcEditorComboPopupStyle defaults = FdcEditorComboPopupStyle(
    backgroundColor: Color(0xFFFFFFFF),
    surfaceTintColor: Colors.transparent,
    shadowColor: Color(0x33000000),
    borderColor: Color(0x00000000),
    elevation: 8,
    borderRadius: BorderRadius.all(Radius.circular(4)),
    highlightedItemColor: Color(0x1A2563EB),
    selectedIconColor: Color(0xFF111827),
    searchFillColor: Color(0xFFFFFFFF),
    searchIconColor: Color(0xFF4B5563),
    searchClearIconColor: Color(0xFF4B5563),
    searchBorderColor: Color(0xB3D1D5DB),
    searchFocusedBorderColor: Color(0xBF2563EB),
    searchBorderWidth: 0.8,
    searchFocusedBorderWidth: 0.9,
    searchBorderRadius: BorderRadius.all(Radius.circular(4)),
  );

  /// Background color of the combo popup surface.
  final Color? backgroundColor;

  /// Material surface tint applied to the combo popup.
  final Color? surfaceTintColor;

  /// Shadow color of the combo popup.
  final Color? shadowColor;

  /// Border color in the normal state.
  final Color? borderColor;

  /// Elevation of the combo popup surface.
  final double? elevation;

  /// Corner radius of the editor surface.
  final BorderRadiusGeometry? borderRadius;

  /// Text style used for combo option labels.
  final TextStyle? itemTextStyle;

  /// Background color of the currently highlighted option.
  final Color? highlightedItemColor;

  /// Color of the selected-option indicator icon.
  final Color? selectedIconColor;

  /// Text style used when no combo options match.
  final TextStyle? emptyTextStyle;

  /// Background fill color of the combo search field.
  final Color? searchFillColor;

  /// Text style of combo search input.
  final TextStyle? searchTextStyle;

  /// Text style of combo search hint text.
  final TextStyle? searchHintStyle;

  /// Color of the combo search icon.
  final Color? searchIconColor;

  /// Color of the combo search clear icon.
  final Color? searchClearIconColor;

  /// Border color of the combo search field.
  final Color? searchBorderColor;

  /// Border color of the combo search field while focused.
  final Color? searchFocusedBorderColor;

  /// Border width of the combo search field.
  final double? searchBorderWidth;

  /// Border width of the focused combo search field.
  final double? searchFocusedBorderWidth;

  /// Corner radius of the combo search field.
  final BorderRadiusGeometry? searchBorderRadius;

  /// Creates a copy with selected values replaced.
  FdcEditorComboPopupStyle copyWith({
    Color? backgroundColor,
    Color? surfaceTintColor,
    Color? shadowColor,
    Color? borderColor,
    double? elevation,
    BorderRadiusGeometry? borderRadius,
    TextStyle? itemTextStyle,
    Color? highlightedItemColor,
    Color? selectedIconColor,
    TextStyle? emptyTextStyle,
    Color? searchFillColor,
    TextStyle? searchTextStyle,
    TextStyle? searchHintStyle,
    Color? searchIconColor,
    Color? searchClearIconColor,
    Color? searchBorderColor,
    Color? searchFocusedBorderColor,
    double? searchBorderWidth,
    double? searchFocusedBorderWidth,
    BorderRadiusGeometry? searchBorderRadius,
  }) {
    return FdcEditorComboPopupStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceTintColor: surfaceTintColor ?? this.surfaceTintColor,
      shadowColor: shadowColor ?? this.shadowColor,
      borderColor: borderColor ?? this.borderColor,
      elevation: elevation ?? this.elevation,
      borderRadius: borderRadius ?? this.borderRadius,
      itemTextStyle: itemTextStyle ?? this.itemTextStyle,
      highlightedItemColor: highlightedItemColor ?? this.highlightedItemColor,
      selectedIconColor: selectedIconColor ?? this.selectedIconColor,
      emptyTextStyle: emptyTextStyle ?? this.emptyTextStyle,
      searchFillColor: searchFillColor ?? this.searchFillColor,
      searchTextStyle: searchTextStyle ?? this.searchTextStyle,
      searchHintStyle: searchHintStyle ?? this.searchHintStyle,
      searchIconColor: searchIconColor ?? this.searchIconColor,
      searchClearIconColor: searchClearIconColor ?? this.searchClearIconColor,
      searchBorderColor: searchBorderColor ?? this.searchBorderColor,
      searchFocusedBorderColor:
          searchFocusedBorderColor ?? this.searchFocusedBorderColor,
      searchBorderWidth: searchBorderWidth ?? this.searchBorderWidth,
      searchFocusedBorderWidth:
          searchFocusedBorderWidth ?? this.searchFocusedBorderWidth,
      searchBorderRadius: searchBorderRadius ?? this.searchBorderRadius,
    );
  }

  /// Merges non-null properties from [override] over this style.
  FdcEditorComboPopupStyle merge(FdcEditorComboPopupStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcEditorComboPopupStyle(
      backgroundColor: override.backgroundColor ?? backgroundColor,
      surfaceTintColor: override.surfaceTintColor ?? surfaceTintColor,
      shadowColor: override.shadowColor ?? shadowColor,
      borderColor: override.borderColor ?? borderColor,
      elevation: override.elevation ?? elevation,
      borderRadius: override.borderRadius ?? borderRadius,
      itemTextStyle:
          itemTextStyle?.merge(override.itemTextStyle) ??
          override.itemTextStyle,
      highlightedItemColor:
          override.highlightedItemColor ?? highlightedItemColor,
      selectedIconColor: override.selectedIconColor ?? selectedIconColor,
      emptyTextStyle:
          emptyTextStyle?.merge(override.emptyTextStyle) ??
          override.emptyTextStyle,
      searchFillColor: override.searchFillColor ?? searchFillColor,
      searchTextStyle:
          searchTextStyle?.merge(override.searchTextStyle) ??
          override.searchTextStyle,
      searchHintStyle:
          searchHintStyle?.merge(override.searchHintStyle) ??
          override.searchHintStyle,
      searchIconColor: override.searchIconColor ?? searchIconColor,
      searchClearIconColor:
          override.searchClearIconColor ?? searchClearIconColor,
      searchBorderColor: override.searchBorderColor ?? searchBorderColor,
      searchFocusedBorderColor:
          override.searchFocusedBorderColor ?? searchFocusedBorderColor,
      searchBorderWidth: override.searchBorderWidth ?? searchBorderWidth,
      searchFocusedBorderWidth:
          override.searchFocusedBorderWidth ?? searchFocusedBorderWidth,
      searchBorderRadius: override.searchBorderRadius ?? searchBorderRadius,
    );
  }

  /// Linearly interpolates this style toward [other] by [t].
  FdcEditorComboPopupStyle lerp(FdcEditorComboPopupStyle other, double t) {
    return FdcEditorComboPopupStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      surfaceTintColor: Color.lerp(surfaceTintColor, other.surfaceTintColor, t),
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      elevation: lerpDouble(elevation, other.elevation, t),
      borderRadius: BorderRadiusGeometry.lerp(
        borderRadius,
        other.borderRadius,
        t,
      ),
      itemTextStyle: TextStyle.lerp(itemTextStyle, other.itemTextStyle, t),
      highlightedItemColor: Color.lerp(
        highlightedItemColor,
        other.highlightedItemColor,
        t,
      ),
      selectedIconColor: Color.lerp(
        selectedIconColor,
        other.selectedIconColor,
        t,
      ),
      emptyTextStyle: TextStyle.lerp(emptyTextStyle, other.emptyTextStyle, t),
      searchFillColor: Color.lerp(searchFillColor, other.searchFillColor, t),
      searchTextStyle: TextStyle.lerp(
        searchTextStyle,
        other.searchTextStyle,
        t,
      ),
      searchHintStyle: TextStyle.lerp(
        searchHintStyle,
        other.searchHintStyle,
        t,
      ),
      searchIconColor: Color.lerp(searchIconColor, other.searchIconColor, t),
      searchClearIconColor: Color.lerp(
        searchClearIconColor,
        other.searchClearIconColor,
        t,
      ),
      searchBorderColor: Color.lerp(
        searchBorderColor,
        other.searchBorderColor,
        t,
      ),
      searchFocusedBorderColor: Color.lerp(
        searchFocusedBorderColor,
        other.searchFocusedBorderColor,
        t,
      ),
      searchBorderWidth: lerpDouble(
        searchBorderWidth,
        other.searchBorderWidth,
        t,
      ),
      searchFocusedBorderWidth: lerpDouble(
        searchFocusedBorderWidth,
        other.searchFocusedBorderWidth,
        t,
      ),
      searchBorderRadius: BorderRadiusGeometry.lerp(
        searchBorderRadius,
        other.searchBorderRadius,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcEditorComboPopupStyle &&
            backgroundColor == other.backgroundColor &&
            surfaceTintColor == other.surfaceTintColor &&
            shadowColor == other.shadowColor &&
            borderColor == other.borderColor &&
            elevation == other.elevation &&
            borderRadius == other.borderRadius &&
            itemTextStyle == other.itemTextStyle &&
            highlightedItemColor == other.highlightedItemColor &&
            selectedIconColor == other.selectedIconColor &&
            emptyTextStyle == other.emptyTextStyle &&
            searchFillColor == other.searchFillColor &&
            searchTextStyle == other.searchTextStyle &&
            searchHintStyle == other.searchHintStyle &&
            searchIconColor == other.searchIconColor &&
            searchClearIconColor == other.searchClearIconColor &&
            searchBorderColor == other.searchBorderColor &&
            searchFocusedBorderColor == other.searchFocusedBorderColor &&
            searchBorderWidth == other.searchBorderWidth &&
            searchFocusedBorderWidth == other.searchFocusedBorderWidth &&
            searchBorderRadius == other.searchBorderRadius;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    surfaceTintColor,
    shadowColor,
    borderColor,
    elevation,
    borderRadius,
    itemTextStyle,
    highlightedItemColor,
    selectedIconColor,
    emptyTextStyle,
    searchFillColor,
    searchTextStyle,
    searchHintStyle,
    searchIconColor,
    searchClearIconColor,
    searchBorderColor,
    searchFocusedBorderColor,
    searchBorderWidth,
    searchFocusedBorderWidth,
    searchBorderRadius,
  ]);
}
