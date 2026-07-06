// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../common/events/fdc_field_events.dart';
import '../../common/format/fdc_format_settings.dart';
import '../../common/theme/fdc_editor_theme.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';
import '../../data/bindings/fdc_field_binding.dart';
import '../../data/fdc_dataset.dart';
import '../../data/fields/fdc_decimal_field.dart';
import '../../data/types/fdc_decimal.dart';
import '../core/fdc_bound_editor.dart';
import '../core/fdc_editor_descriptor.dart';

/// Data-aware editor for decimal dataset fields.
///
/// The control applies FDC decimal parsing and formatting while preserving
/// exact decimal semantics through the dataset edit lifecycle.
class FdcDecimalEdit extends StatelessWidget {
  /// Creates a [FdcDecimalEdit].
  const FdcDecimalEdit({
    super.key,
    required this.dataSet,
    required this.fieldName,
    this.label,
    this.hint,
    this.enabled,
    this.readOnly = false,
    this.focusOrder,
    this.tabStop = true,
    this.allowNegative = true,
    this.decoration,
    this.theme,
    this.style = const FdcEditorInputStyle(),
    this.autofocus = false,
    this.showLabel = true,
    this.selectAllOnFocus = false,
    this.errorIndicator = const FdcErrorIndicatorOptions(),
    this.onEnter,
    this.onExit,
    this.onValueChanging,
    this.onValueChanged,
    this.formatSettings,
  });

  /// Dataset whose current record and edit buffer are bound to this editor.
  final FdcDataSet dataSet;

  /// Name of the dataset field bound to this editor.
  final String fieldName;

  /// Optional label displayed for the editor.
  final String? label;

  /// Optional hint shown when the editor has no input text.
  final String? hint;

  /// Optional enabled-state override; `null` leaves enablement to the binding.
  final bool? enabled;

  /// Whether user input is blocked even when the bound field is writable.
  final bool readOnly;

  /// Optional numeric order used by FDC focus traversal.
  final int? focusOrder;

  /// Whether the editor participates in keyboard focus traversal.
  final bool tabStop;

  /// Whether the input accepts negative numeric values.
  final bool allowNegative;

  /// Optional Flutter input decoration override.
  final InputDecoration? decoration;

  /// Optional local editor theme override for this control.
  final FdcEditorThemeData? theme;

  /// Local text-input style merged over the resolved editor theme.
  final FdcEditorInputStyle style;

  /// Whether this editor requests focus when first built.
  final bool autofocus;

  /// Whether the editor renders its label.
  final bool showLabel;

  /// Whether entering the editor selects all current text.
  final bool selectAllOnFocus;

  /// Configures how validation errors are presented by this editor.
  final FdcErrorIndicatorOptions errorIndicator;

  /// Called when focus enters this bound field.
  final FdcFieldFocusCallback<FdcDecimal>? onEnter;

  /// Called when focus leaves this bound field.
  final FdcFieldFocusCallback<FdcDecimal>? onExit;

  /// Called before a proposed value change is committed.
  final FdcFieldValueChangingCallback<FdcDecimal>? onValueChanging;

  /// Called after an accepted value change has been applied.
  final FdcFieldValueChangedCallback<FdcDecimal>? onValueChanged;

  /// Optional parsing and display format override for this editor.
  final FdcFormatSettings? formatSettings;

  @override
  Widget build(BuildContext context) {
    return FdcBoundEditor<FdcDecimal, FdcDecimalField>(
      dataSet: dataSet,
      fieldName: fieldName,
      resolveBinding: (dataSet, fieldName) =>
          FdcFieldBindingResolver.resolve<FdcDecimalField>(
            dataSet,
            fieldName,
            ownerName: 'FdcDecimalEdit',
          ),
      fieldBuilder: (binding) => FdcDecimalEditorDescriptor<FdcDecimal>(
        fieldName: fieldName,
        label: label ?? binding.label,
        hint: hint,
        enabled: enabled ?? true,
        readOnly: readOnly || binding.readOnly,
        required: binding.required,
        focusOrder: focusOrder,
        tabStop: tabStop,
        allowNegative: allowNegative,
        precision: binding.fieldDef.precision,
        scale: binding.fieldDef.scale,
      ),
      decoration: decoration,
      theme: theme,
      style: style,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      showLabel: showLabel,
      selectAllOnFocus: selectAllOnFocus,
      errorIndicator: errorIndicator,
      onEnter: onEnter,
      onExit: onExit,
      onValueChanging: onValueChanging,
      onValueChanged: onValueChanged,
      formatSettings: formatSettings,
    );
  }
}
