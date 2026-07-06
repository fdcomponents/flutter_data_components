// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../common/events/fdc_field_events.dart';
import '../../common/theme/fdc_editor_theme.dart';
import '../../common/widgets/counter/fdc_counter_style.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';
import '../../data/bindings/fdc_field_binding.dart';
import '../../data/fdc_dataset.dart';
import '../../data/fields/fdc_string_field.dart';
import '../core/fdc_bound_editor.dart';
import '../core/fdc_editor_descriptor.dart';

/// Data-aware multiline editor for long text dataset fields.
///
/// The control binds multiline text input to the current dataset record and
/// participates in the dataset edit lifecycle.
class FdcMemoEdit extends StatelessWidget {
  /// Creates a [FdcMemoEdit].
  const FdcMemoEdit({
    super.key,
    required this.dataSet,
    required this.fieldName,
    this.label,
    this.hint,
    this.enabled,
    this.readOnly = false,
    this.focusOrder,
    this.tabStop = true,
    this.showCounter = false,
    this.counterStyle = const FdcCounterStyle(),
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

  /// Whether to show the field length counter for text input.
  final bool showCounter;

  /// Visual style used by the optional text length counter.
  final FdcCounterStyle counterStyle;

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
  final FdcFieldFocusCallback<String>? onEnter;

  /// Called when focus leaves this bound field.
  final FdcFieldFocusCallback<String>? onExit;

  /// Called before a proposed value change is committed.
  final FdcFieldValueChangingCallback<String>? onValueChanging;

  /// Called after an accepted value change has been applied.
  final FdcFieldValueChangedCallback<String>? onValueChanged;

  @override
  Widget build(BuildContext context) {
    return FdcBoundEditor<String, FdcStringField>(
      dataSet: dataSet,
      fieldName: fieldName,
      resolveBinding: (dataSet, fieldName) =>
          FdcFieldBindingResolver.resolve<FdcStringField>(
            dataSet,
            fieldName,
            ownerName: 'FdcMemoEdit',
          ),
      fieldBuilder: (binding) => FdcMemoEditorDescriptor<String>(
        fieldName: fieldName,
        label: label ?? binding.label,
        hint: hint,
        enabled: enabled ?? true,
        readOnly: readOnly || binding.readOnly,
        required: binding.required,
        focusOrder: focusOrder,
        tabStop: tabStop,
        maxLength: binding.fieldDef.size,
        showCounter: showCounter,
        counterStyle: counterStyle,
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
    );
  }
}
