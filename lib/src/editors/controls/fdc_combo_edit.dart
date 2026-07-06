// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/fdc_app.dart';
import '../../common/events/fdc_field_events.dart';
import '../../common/fdc_option.dart';
import '../../common/input/fdc_focus_traversal.dart';
import '../../common/input/fdc_input_decoration.dart';
import '../../common/input/fdc_input_state.dart';
import '../../common/input/fdc_key_utils.dart';
import '../../common/theme/fdc_editor_theme.dart';
import '../../common/widgets/combo/fdc_combo_field.dart';
import '../../common/widgets/combo/fdc_combo_search_options.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';
import '../../data/bindings/fdc_field_binding.dart';
import '../../data/fdc_dataset.dart';
import '../../data/fdc_field_def.dart';
import '../../data/fields/fdc_boolean_field.dart';
import '../../data/fields/fdc_decimal_field.dart';
import '../../data/fields/fdc_integer_field.dart';
import '../../data/fields/fdc_object_field.dart';
import '../../data/fields/fdc_string_field.dart';
import '../../dialogs/fdc_message_dialog.dart';
import '../core/fdc_bound_editor.dart';
import '../core/fdc_editor_commit_result.dart';
import '../widgets/fdc_editor_control_theme.dart';
import '../widgets/fdc_error_indicator_frame.dart';

/// Data-aware selection editor backed by a predefined set of options.
///
/// The control maps display labels to field values and participates in the
/// dataset edit lifecycle.
class FdcComboEdit<T> extends StatefulWidget {
  /// Creates a [FdcComboEdit].
  const FdcComboEdit({
    super.key,
    required this.dataSet,
    required this.fieldName,
    required this.options,
    this.label,
    this.hint,
    this.enabled,
    this.readOnly = false,
    this.focusOrder,
    this.tabStop = true,
    this.decoration,
    this.theme,
    this.style = const FdcEditorInputStyle(),
    this.controlsStyle = const FdcEditorControlsStyle(),
    this.popupStyle = const FdcEditorComboPopupStyle(),
    this.autofocus = false,
    this.showLabel = true,
    this.showSelectedOptionCheckmark = true,
    this.search = const FdcComboSearchOptions(),
    this.searchHintText,
    this.maxPopupItems = 8,
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

  /// Available value/label pairs presented by the combo popup.
  final List<FdcOption<T>> options;

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

  /// Optional Flutter input decoration override.
  final InputDecoration? decoration;

  /// Optional local editor theme override for this control.
  final FdcEditorThemeData? theme;

  /// Local text-input style merged over the resolved editor theme.
  final FdcEditorInputStyle style;

  /// Local control-chrome style merged over the resolved editor theme.
  final FdcEditorControlsStyle controlsStyle;

  /// Local combo-popup style merged over the resolved editor theme.
  final FdcEditorComboPopupStyle popupStyle;

  /// Whether this editor requests focus when first built.
  final bool autofocus;

  /// Whether the editor renders its label.
  final bool showLabel;

  /// Whether the popup marks the currently selected option.
  final bool showSelectedOptionCheckmark;

  /// Search behavior used by the combo popup.
  final FdcComboSearchOptions search;

  /// Optional hint displayed in the combo popup search field.
  final String? searchHintText;

  /// Maximum number of option rows visible before the popup scrolls.
  final int maxPopupItems;

  /// Configures how validation errors are presented by this editor.
  final FdcErrorIndicatorOptions errorIndicator;

  /// Called when focus enters this bound field.
  final FdcFieldFocusCallback<T>? onEnter;

  /// Called when focus leaves this bound field.
  final FdcFieldFocusCallback<T>? onExit;

  /// Called before a proposed value change is committed.
  final FdcFieldValueChangingCallback<T>? onValueChanging;

  /// Called after an accepted value change has been applied.
  final FdcFieldValueChangedCallback<T>? onValueChanged;

  @override
  State<FdcComboEdit<T>> createState() => _FdcComboEditState<T>();
}

class _FdcComboEditState<T> extends State<FdcComboEdit<T>> {
  late final FocusNode _focusNode;
  int? _snapshotRecordId;
  T? _valueBeforeEdit;
  bool _hasEditSnapshot = false;
  bool _showingValidationErrorDialog = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  void _showValidationErrorDialog(String message) {
    final normalizedMessage = message.trim();
    if (!mounted ||
        normalizedMessage.isEmpty ||
        _showingValidationErrorDialog) {
      return;
    }

    _showingValidationErrorDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _showingValidationErrorDialog = false;
        return;
      }
      unawaited(
        showFdcMessageDialog(
          context,
          title: FdcApp.translationsOf(context).validation.validationError,
          message: normalizedMessage,
        ).catchError((_) {}).whenComplete(() {
          _showingValidationErrorDialog = false;
          if (mounted) {
            _focusNode.requestFocus();
          }
        }),
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _clearEditSnapshot();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FdcBoundEditor<T, FdcFieldDef>(
      dataSet: widget.dataSet,
      fieldName: widget.fieldName,
      resolveBinding: (dataSet, fieldName) =>
          FdcFieldBindingResolver.resolveAnyOf(
            dataSet,
            fieldName,
            allowedFieldTypes: const <Type>[
              FdcStringField,
              FdcIntegerField,
              FdcDecimalField,
              FdcBooleanField,
              FdcObjectField,
            ],
            ownerName: 'FdcComboEdit',
          ),
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      theme: widget.theme,
      errorIndicator: widget.errorIndicator,
      onEnter: widget.onEnter,
      onExit: widget.onExit,
      onValueChanging: widget.onValueChanging,
      onValueChanged: widget.onValueChanged,
      builder: _buildComboEditor,
    );
  }

  Widget _buildComboEditor(
    BuildContext context,
    FdcBoundEditorContext<T, FdcFieldDef> editor,
  ) {
    final inputState = FdcInputState(
      enabled: editor.isEnabled,
      readOnly: editor.isReadOnly,
    );

    _focusNode
      ..canRequestFocus = widget.tabStop && inputState.enabled
      ..skipTraversal = !widget.tabStop || !inputState.enabled;

    final inputStyle = FdcEditorTheme.resolveInputStyle(
      context,
      localTheme: widget.theme,
      localStyle: widget.style,
    );
    final controlsStyle = FdcEditorTheme.resolveControlsStyle(
      context,
      localTheme: widget.theme,
      localStyle: widget.controlsStyle,
    );
    final popupStyle = FdcEditorTheme.resolveComboPopupStyle(
      context,
      localTheme: widget.theme,
      localStyle: widget.popupStyle,
    );
    final decoration = FdcInputDecoration.editor(
      decoration: widget.decoration,
      labelText: widget.label ?? editor.binding.label,
      hintText: widget.hint,
      showLabel: widget.showLabel,
      isEnabled: inputState.enabled,
      isReadOnly: inputState.readOnly,
      isFocused: _focusNode.hasFocus,
      style: inputStyle,
    );

    Widget result = FdcComboField<T>(
      key: ValueKey<Object?>(editor.value),
      value: editor.value,
      options: widget.options,
      onChanged: inputState.canEdit
          ? (value) {
              _ensureEditSnapshot(editor);
              _commitValue(editor, value);
            }
          : (_) {},
      focusNode: _focusNode,
      decoration: decoration,
      style:
          Theme.of(context).textTheme.bodyMedium?.merge(inputStyle.textStyle) ??
          inputStyle.textStyle,
      hintText: widget.hint,
      enabled: inputState.enabled,
      readOnly: inputState.readOnly,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) =>
          _handleKeyEvent(context, node, event, editor),
      iconColor: FdcEditorControlTheme.iconColor(
        context,
        controlsStyle,
        enabled: inputState.canEdit,
        active: _focusNode.hasFocus,
      ),
      popupStyle: popupStyle,
      onTap: () => _ensureEditSnapshot(editor),
      showSelectedOptionCheckmark: widget.showSelectedOptionCheckmark,
      search: widget.search,
      searchHintText: widget.searchHintText,
      maxPopupItems: widget.maxPopupItems,
      openOnEnter: false,
    );

    result = FdcErrorIndicatorFrame(
      errorIndicator: widget.errorIndicator,
      errorMessage: editor.validationErrorText,
      child: result,
    );

    return FdcFocusTraversal.wrap(focusOrder: widget.focusOrder, child: result);
  }

  KeyEventResult _handleKeyEvent(
    BuildContext context,
    FocusNode node,
    KeyEvent event,
    FdcBoundEditorContext<T, FdcFieldDef> editor,
  ) {
    if (!FdcKeyUtils.isKeyDownOrRepeat(event)) {
      return KeyEventResult.ignored;
    }

    if (FdcKeyUtils.isEnter(event)) {
      FocusScope.of(context).nextFocus();
      return KeyEventResult.handled;
    }

    if (!FdcKeyUtils.isEscape(event)) {
      return KeyEventResult.ignored;
    }

    if (_snapshotRecordId != editor.recordId) {
      _clearEditSnapshot();
    }

    if (_hasEditSnapshot && editor.value != _valueBeforeEdit) {
      _commitValue(editor, _valueBeforeEdit);
      return KeyEventResult.handled;
    }

    _clearEditSnapshot();
    return KeyEventResult.handled;
  }

  void _ensureEditSnapshot(FdcBoundEditorContext<T, FdcFieldDef> editor) {
    if (_hasEditSnapshot && _snapshotRecordId == editor.recordId) {
      return;
    }
    _snapshotRecordId = editor.recordId;
    _valueBeforeEdit = editor.value;
    _hasEditSnapshot = true;
  }

  void _clearEditSnapshot() {
    _snapshotRecordId = null;
    _valueBeforeEdit = null;
    _hasEditSnapshot = false;
  }

  String? _commitValue(FdcBoundEditorContext<T, FdcFieldDef> editor, T? value) {
    // Required is handled as non-blocking dataset validation. The combo editor
    // must accept an empty value and let post() enforce required fields.
    final error = editor.commit(value);
    if (error != null && !fdcIsEditorCommitCanceled(error)) {
      _showValidationErrorDialog(error);
    }
    return error;
  }
}
