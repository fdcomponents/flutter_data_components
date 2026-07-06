// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/fdc_editor_styles.dart';

@internal
class FdcInputDecoration {
  const FdcInputDecoration._();

  static InputDecoration editor({
    required InputDecoration? decoration,
    required String? labelText,
    required String? hintText,
    required bool showLabel,
    required bool isEnabled,
    required bool isReadOnly,
    required bool isFocused,
    required FdcEditorInputStyle style,
    Widget? suffixIcon,
    String? errorText,
  }) {
    final base = decoration ?? const InputDecoration();
    final baseBorder = base.border;
    final fillColor = _editorFillColor(
      isEnabled: isEnabled,
      isReadOnly: isReadOnly,
      isFocused: isFocused,
      style: style,
    );

    return base.copyWith(
      labelText: showLabel ? base.labelText ?? labelText : null,
      hintText: base.hintText ?? hintText,
      errorText: errorText ?? base.errorText,
      suffixIcon: suffixIcon ?? base.suffixIcon,
      filled: (base.filled ?? false) || fillColor != null,
      fillColor: base.fillColor ?? fillColor,
      labelStyle: base.labelStyle ?? style.labelStyle,
      floatingLabelStyle: base.floatingLabelStyle ?? style.floatingLabelStyle,
      hintStyle: base.hintStyle ?? style.hintStyle,
      errorStyle: base.errorStyle ?? style.errorStyle,
      contentPadding: base.contentPadding ?? style.contentPadding,
      border: baseBorder ?? _border(style),
      enabledBorder:
          base.enabledBorder ??
          baseBorder ??
          _border(
            style,
            color: isReadOnly ? style.readOnlyBorderColor : style.borderColor,
          ),
      focusedBorder:
          base.focusedBorder ??
          baseBorder ??
          _border(
            style,
            color: style.focusedBorderColor,
            width: style.focusedBorderWidth,
          ),
      errorBorder:
          base.errorBorder ??
          baseBorder ??
          _border(
            style,
            color: style.errorBorderColor,
            width: style.errorBorderWidth,
          ),
      focusedErrorBorder:
          base.focusedErrorBorder ??
          baseBorder ??
          _border(
            style,
            color: style.errorBorderColor,
            width: style.focusedBorderWidth,
          ),
      disabledBorder:
          base.disabledBorder ??
          baseBorder ??
          _border(style, color: style.disabledBorderColor),
    );
  }

  static InputDecoration gridCell({
    String? hintText,
    EdgeInsetsGeometry contentPadding = EdgeInsets.zero,
  }) {
    return InputDecoration(
      isDense: true,
      isCollapsed: true,
      hintText: hintText,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: contentPadding,
    );
  }

  static InputDecoration headerFilter({required Color fillColor}) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: fillColor,
      hoverColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 5),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  static InputDecoration headerFilterEmbedded({String? hintText}) {
    return InputDecoration(
      isDense: true,
      isCollapsed: true,
      filled: false,
      fillColor: Colors.transparent,
      hoverColor: Colors.transparent,
      hintText: hintText,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  static InputBorder _border(
    FdcEditorInputStyle style, {
    Color? color,
    double? width,
  }) {
    return OutlineInputBorder(
      borderRadius: _resolveBorderRadius(style.borderRadius),
      borderSide: BorderSide(
        color: color ?? style.borderColor ?? Colors.transparent,
        width: width ?? style.borderWidth ?? 1,
      ),
    );
  }

  static BorderRadius _resolveBorderRadius(BorderRadiusGeometry? borderRadius) {
    return borderRadius?.resolve(TextDirection.ltr) ?? BorderRadius.zero;
  }

  static Color? _editorFillColor({
    required bool isEnabled,
    required bool isReadOnly,
    required bool isFocused,
    required FdcEditorInputStyle style,
  }) {
    if (!isEnabled) {
      return style.disabledFillColor;
    }
    if (isReadOnly) {
      return style.readOnlyFillColor;
    }
    if (isFocused) {
      return style.focusedFillColor ?? style.fillColor;
    }

    return style.fillColor;
  }
}
