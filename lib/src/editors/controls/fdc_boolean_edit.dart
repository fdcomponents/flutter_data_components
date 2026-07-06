// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/fdc_app.dart';
import '../../common/events/fdc_field_events.dart';
import '../../common/input/fdc_boolean_control.dart';
import '../../common/input/fdc_focus_traversal.dart';
import '../../common/input/fdc_input_state.dart';
import '../../common/input/fdc_key_utils.dart';
import '../../common/theme/fdc_editor_theme.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';
import '../../data/bindings/fdc_field_binding.dart';
import '../../data/fdc_dataset.dart';
import '../../data/fields/fdc_boolean_field.dart';
import '../../dialogs/fdc_message_dialog.dart';
import '../core/fdc_bound_editor.dart';
import '../core/fdc_editor_commit_result.dart';
import '../widgets/fdc_editor_control_theme.dart';
import '../widgets/fdc_error_indicator_frame.dart';

/// Data-aware editor for boolean dataset fields.
///
/// The control reads the current field value and writes user changes through
/// the dataset edit lifecycle.
class FdcBooleanEdit extends StatefulWidget {
  /// Creates a [FdcBooleanEdit].
  const FdcBooleanEdit({
    super.key,
    required this.dataSet,
    required this.fieldName,
    this.label,
    this.showLabel = true,
    this.enabled,
    this.readOnly = false,
    this.focusOrder,
    this.tabStop = true,
    this.control = FdcBooleanControl.checkbox,
    this.theme,
    this.controlsStyle = const FdcEditorControlsStyle(),
    this.autofocus = false,
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

  /// Whether the editor renders its label.
  final bool showLabel;

  /// Optional enabled-state override; `null` leaves enablement to the binding.
  final bool? enabled;

  /// Whether user input is blocked even when the bound field is writable.
  final bool readOnly;

  /// Optional numeric order used by FDC focus traversal.
  final int? focusOrder;

  /// Whether the editor participates in keyboard focus traversal.
  final bool tabStop;

  /// Visual boolean control rendered by the editor.
  final FdcBooleanControl control;

  /// Optional local editor theme override for this control.
  final FdcEditorThemeData? theme;

  /// Local control-chrome style merged over the resolved editor theme.
  final FdcEditorControlsStyle controlsStyle;

  /// Whether this editor requests focus when first built.
  final bool autofocus;

  /// Configures how validation errors are presented by this editor.
  final FdcErrorIndicatorOptions errorIndicator;

  /// Called when focus enters this bound field.
  final FdcFieldFocusCallback<bool>? onEnter;

  /// Called when focus leaves this bound field.
  final FdcFieldFocusCallback<bool>? onExit;

  /// Called before a proposed value change is committed.
  final FdcFieldValueChangingCallback<bool>? onValueChanging;

  /// Called after an accepted value change has been applied.
  final FdcFieldValueChangedCallback<bool>? onValueChanged;

  @override
  State<FdcBooleanEdit> createState() => _FdcBooleanEditState();
}

class _FdcBooleanEditState extends State<FdcBooleanEdit> {
  late final FocusNode _focusNode;
  int? _snapshotRecordId;
  bool? _valueBeforeEdit;
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
    return FdcBoundEditor<bool, FdcBooleanField>(
      dataSet: widget.dataSet,
      fieldName: widget.fieldName,
      resolveBinding: (dataSet, fieldName) =>
          FdcFieldBindingResolver.resolve<FdcBooleanField>(
            dataSet,
            fieldName,
            ownerName: 'FdcBooleanEdit',
          ),
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      theme: widget.theme,
      errorIndicator: widget.errorIndicator,
      onEnter: widget.onEnter,
      onExit: widget.onExit,
      onValueChanging: widget.onValueChanging,
      onValueChanged: widget.onValueChanged,
      builder: _buildBooleanEditor,
    );
  }

  Widget _buildBooleanEditor(
    BuildContext context,
    FdcBoundEditorContext<bool, FdcBooleanField> editor,
  ) {
    final inputState = FdcInputState(
      enabled: editor.isEnabled,
      readOnly: editor.isReadOnly,
    );
    final controlsStyle = FdcEditorTheme.resolveControlsStyle(
      context,
      localTheme: widget.theme,
      localStyle: widget.controlsStyle,
    );

    _focusNode
      ..canRequestFocus = widget.tabStop && inputState.enabled
      ..skipTraversal = !widget.tabStop || !inputState.enabled;

    Widget result = FormField<bool>(
      key: ValueKey<Object?>(editor.value),
      initialValue: _checkboxValue(editor.value),
      validator: (value) {
        // Checkbox/switch controls do not render inline validation messages,
        // but they should still participate in explicit Flutter Form.validate()
        // calls. This remains non-blocking for normal focus traversal.
        if (editor.binding.required && value != true) {
          return '${editor.binding.label} is required';
        }
        return null;
      },
      builder: (state) {
        final control = widget.control == FdcBooleanControl.switchControl
            ? Switch(
                value: state.value == true,
                focusNode: _focusNode,
                thumbColor: FdcEditorControlTheme.switchThumbColor(
                  controlsStyle,
                ),
                trackColor: FdcEditorControlTheme.switchTrackColor(
                  controlsStyle,
                ),
                autofocus: widget.autofocus,
                onChanged: inputState.canEdit
                    ? (value) {
                        _ensureEditSnapshot(editor);
                        final error = editor.commit(value);
                        if (error == null) {
                          state.didChange(value);
                        } else if (!fdcIsEditorCommitCanceled(error)) {
                          _showValidationErrorDialog(error);
                        }
                      }
                    : null,
              )
            : Checkbox(
                value: state.value,
                tristate: true,
                focusNode: _focusNode,
                fillColor: FdcEditorControlTheme.checkboxFillColor(
                  controlsStyle,
                ),
                checkColor: FdcEditorControlTheme.checkboxCheckColor(
                  context,
                  controlsStyle,
                  enabled: inputState.canEdit,
                ),
                side: FdcEditorControlTheme.checkboxSide(
                  context,
                  controlsStyle,
                  enabled: inputState.canEdit,
                ),
                autofocus: widget.autofocus,
                onChanged: inputState.canEdit
                    ? (_) {
                        _ensureEditSnapshot(editor);
                        final next = _nextCheckboxValue(
                          state.value,
                          isRequired: editor.binding.required,
                        );
                        final error = editor.commit(next);
                        if (error == null) {
                          state.didChange(next);
                        } else if (!fdcIsEditorCommitCanceled(error)) {
                          _showValidationErrorDialog(error);
                        }
                      }
                    : null,
              );

        final labelText = widget.label ?? editor.binding.label;
        if (!widget.showLabel || labelText.isEmpty) {
          return Align(alignment: Alignment.centerLeft, child: control);
        }

        final baseTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: inputState.canEdit ? null : Theme.of(context).disabledColor,
        );
        final labelOverride = inputState.canEdit
            ? controlsStyle.labelStyle
            : controlsStyle.disabledLabelStyle ?? controlsStyle.labelStyle;
        final textStyle = baseTextStyle?.merge(labelOverride) ?? labelOverride;

        return LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 2.0;
            final minimumControlWidth =
                widget.control == FdcBooleanControl.switchControl ? 56.0 : 48.0;

            if (!constraints.hasBoundedWidth) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    control,
                    const SizedBox(width: spacing),
                    Text(
                      labelText,
                      style: textStyle,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }

            if (constraints.maxWidth <= minimumControlWidth + spacing) {
              return ClipRect(
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Align(alignment: Alignment.centerLeft, child: control),
                ),
              );
            }

            return ClipRect(
              child: SizedBox(
                width: constraints.maxWidth,
                child: Row(
                  children: [
                    control,
                    const SizedBox(width: spacing),
                    Flexible(
                      child: Text(
                        labelText,
                        style: textStyle,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    result = FdcErrorIndicatorFrame(
      errorIndicator: widget.errorIndicator,
      errorMessage: editor.validationErrorText,
      child: result,
    );

    return FdcFocusTraversal.wrap(
      focusOrder: widget.focusOrder,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (node, event) =>
            _handleKeyEvent(context, node, event, editor),
        child: result,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(
    BuildContext context,
    FocusNode node,
    KeyEvent event,
    FdcBoundEditorContext<bool, FdcBooleanField> editor,
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
      final error = editor.commit(_valueBeforeEdit);
      if (error != null && !fdcIsEditorCommitCanceled(error)) {
        _showValidationErrorDialog(error);
      }
      if (error == null) {
        setState(() {});
      }
      return KeyEventResult.handled;
    }

    _clearEditSnapshot();
    return KeyEventResult.handled;
  }

  void _ensureEditSnapshot(
    FdcBoundEditorContext<bool, FdcBooleanField> editor,
  ) {
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

  bool? _checkboxValue(bool? value) {
    return value == true
        ? true
        : value == false
        ? false
        : null;
  }

  bool? _nextCheckboxValue(bool? value, {required bool isRequired}) {
    if (isRequired) {
      return value == true ? false : true;
    }

    return switch (value) {
      null => true,
      true => false,
      false => null,
    };
  }
}
