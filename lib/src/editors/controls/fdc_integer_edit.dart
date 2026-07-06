// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../common/events/fdc_field_events.dart';
import '../../common/input/fdc_keyboard_shortcut.dart';
import '../../common/theme/fdc_editor_theme.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';
import '../../data/bindings/fdc_field_binding.dart';
import '../../data/fdc_dataset.dart';
import '../../data/fields/fdc_integer_field.dart';
import '../core/fdc_bound_editor.dart';
import '../core/fdc_editor_descriptor.dart';
import '../core/fdc_editor_lookup.dart';

/// Data-aware editor for integer dataset fields.
///
/// The editor parses integer input, applies field normalization and validation,
/// and can invoke an optional lookup callback before committing through the
/// dataset edit lifecycle.
class FdcIntegerEdit extends StatelessWidget {
  /// Creates a [FdcIntegerEdit].
  const FdcIntegerEdit({
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
    this.onLookup,
    this.lookupIcon = Icons.more_horiz,
    this.lookupShortcut = FdcKeyboardShortcut.f4,
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

  /// Optional asynchronous lookup invoked by the lookup button or shortcut.
  final FdcEditorLookup<int>? onLookup;

  /// Icon displayed by the lookup affordance.
  final IconData lookupIcon;

  /// Keyboard shortcut that invokes [onLookup], or `null` to disable it.
  final FdcKeyboardShortcut? lookupShortcut;

  /// Called when focus enters this bound field.
  final FdcFieldFocusCallback<int>? onEnter;

  /// Called when focus leaves this bound field.
  final FdcFieldFocusCallback<int>? onExit;

  /// Called before a proposed value change is committed.
  final FdcFieldValueChangingCallback<int>? onValueChanging;

  /// Called after an accepted value change has been applied.
  final FdcFieldValueChangedCallback<int>? onValueChanged;

  @override
  Widget build(BuildContext context) {
    return FdcBoundEditor<int, FdcIntegerField>(
      dataSet: dataSet,
      fieldName: fieldName,
      resolveBinding: (dataSet, fieldName) =>
          FdcFieldBindingResolver.resolve<FdcIntegerField>(
            dataSet,
            fieldName,
            ownerName: 'FdcIntegerEdit',
          ),
      fieldBuilder: (binding) => FdcIntegerEditorDescriptor<int>(
        fieldName: fieldName,
        label: label ?? binding.label,
        hint: hint,
        enabled: enabled ?? true,
        readOnly: readOnly || binding.readOnly,
        required: binding.required,
        focusOrder: focusOrder,
        tabStop: tabStop,
        allowNegative: allowNegative,
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
      onLookup: onLookup,
      lookupIcon: lookupIcon,
      lookupShortcut: lookupShortcut,
      onEnter: onEnter,
      onExit: onExit,
      onValueChanging: onValueChanging,
      onValueChanged: onValueChanged,
    );
  }
}
