// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/fdc_app.dart';
import '../../common/events/fdc_field_events.dart';
import '../../common/format/fdc_format_settings.dart';
import '../../common/input/fdc_input_state.dart';
import '../../common/input/fdc_keyboard_shortcut.dart';
import '../../common/lookup/fdc_lookup_context.dart';
import '../../common/lookup/fdc_lookup_result.dart';
import '../../common/theme/fdc_editor_theme.dart';
import '../../common/validation/fdc_validation_message_formatter.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';
import '../../data/bindings/fdc_field_binding.dart';
import '../../data/fdc_data_errors.dart';
import '../../data/fdc_dataset.dart';
import '../../data/fdc_dataset_state.dart';
import '../../data/fdc_field_def.dart';
import '../../data/fdc_field_name.dart';
import '../../dialogs/fdc_message_dialog.dart';
import 'fdc_editor_commit_result.dart';
import 'fdc_editor_core.dart';
import 'fdc_editor_descriptor.dart';
import 'fdc_editor_lookup.dart';

@internal
typedef FdcEditorDescriptorBuilder<TValue, TField extends FdcFieldDef> =
    FdcEditorDescriptor<TValue> Function(FdcFieldBinding<TField> binding);

@internal
typedef FdcEditorBindingResolver<TField extends FdcFieldDef> =
    FdcFieldBinding<TField> Function(FdcDataSet dataSet, String fieldName);

@internal
typedef FdcBoundEditorBuilder<TValue, TField extends FdcFieldDef> =
    Widget Function(
      BuildContext context,
      FdcBoundEditorContext<TValue, TField> editor,
    );

@internal
class FdcBoundEditorContext<TValue, TField extends FdcFieldDef> {
  const FdcBoundEditorContext({
    required this.binding,
    required this.recordId,
    required this.value,
    required this.isEnabled,
    required this.isReadOnly,
    required this.canEdit,
    required this.validationErrorText,
    required this.commit,
    required this.lookup,
    required this.hasLookup,
  });

  final FdcFieldBinding<TField> binding;
  final int? recordId;
  final TValue? value;
  final bool isEnabled;
  final bool isReadOnly;
  final bool canEdit;
  final String? validationErrorText;
  final String? Function(TValue? value) commit;
  final Future<bool> Function(
    String? editorText,
    TValue? value,
    FdcLookupMode mode,
  )
  lookup;
  final bool hasLookup;
}

@internal
class FdcBoundEditor<TValue, TField extends FdcFieldDef>
    extends StatefulWidget {
  const FdcBoundEditor({
    super.key,
    required this.dataSet,
    required this.fieldName,
    required this.resolveBinding,
    this.fieldBuilder,
    this.builder,
    this.decoration,
    this.theme,
    this.style = const FdcEditorInputStyle(),
    this.enabled,
    this.readOnly = false,
    this.autofocus = false,
    this.showLabel = true,
    this.showPicker,
    this.selectAllOnFocus = false,
    this.errorIndicator = const FdcErrorIndicatorOptions(),
    this.formatSettings,
    this.onEnter,
    this.onExit,
    this.onValueChanging,
    this.onValueChanged,
    this.onLookup,
    this.lookupIcon = Icons.more_horiz,
    this.lookupShortcut = FdcKeyboardShortcut.f4,
  }) : assert(
         fieldBuilder != null || builder != null,
         'FdcBoundEditor requires either fieldBuilder or builder.',
       );

  final FdcDataSet dataSet;
  final String fieldName;
  final FdcEditorBindingResolver<TField> resolveBinding;
  final FdcEditorDescriptorBuilder<TValue, TField>? fieldBuilder;
  final FdcBoundEditorBuilder<TValue, TField>? builder;
  final InputDecoration? decoration;
  final FdcEditorThemeData? theme;
  final FdcEditorInputStyle style;
  final bool? enabled;
  final bool readOnly;
  final bool autofocus;
  final bool showLabel;
  final bool? showPicker;
  final bool selectAllOnFocus;
  final FdcErrorIndicatorOptions errorIndicator;
  final FdcFormatSettings? formatSettings;
  final FdcFieldFocusCallback<TValue>? onEnter;
  final FdcFieldFocusCallback<TValue>? onExit;
  final FdcFieldValueChangingCallback<TValue>? onValueChanging;
  final FdcFieldValueChangedCallback<TValue>? onValueChanged;
  final FdcEditorLookup<TValue>? onLookup;
  final IconData lookupIcon;
  final FdcKeyboardShortcut? lookupShortcut;

  @override
  State<FdcBoundEditor<TValue, TField>> createState() =>
      _FdcBoundEditorState<TValue, TField>();
}

class _FdcBoundEditorState<TValue, TField extends FdcFieldDef>
    extends State<FdcBoundEditor<TValue, TField>> {
  bool _showingLookupErrorDialog = false;
  Future<void>? _lookupErrorDialogFuture;
  bool _lookupInProgress = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.dataSet,
      builder: (context, _) {
        final formatSettings =
            widget.formatSettings ?? FdcApp.formatsOf(context);
        final binding = widget.resolveBinding(widget.dataSet, widget.fieldName);
        final hasCurrentRecord = binding.hasCurrentRecord;
        final isEnabled = (widget.enabled ?? true) && hasCurrentRecord;
        final isReadOnly = widget.readOnly || binding.readOnly;
        final inputState = FdcInputState(
          enabled: isEnabled,
          readOnly: isReadOnly,
        );
        final editorContext = FdcBoundEditorContext<TValue, TField>(
          binding: binding,
          recordId: binding.recordId,
          value: binding.valueOrNull as TValue?,
          isEnabled: inputState.enabled,
          isReadOnly: inputState.readOnly,
          canEdit: inputState.canEdit,
          validationErrorText: _validationErrorText(binding),
          commit: (value) => _commitBoundValue(binding, value),
          lookup: (editorText, value, mode) =>
              _invokeLookup(context, binding, editorText, value, mode),
          hasLookup: widget.onLookup != null,
        );

        final recordIdentity = binding.recordId;
        final valueSyncIdentity = _FdcBoundEditorValueSyncIdentity(
          recordId: binding.recordId,
          value: editorContext.value,
        );
        final editorIdentity = _FdcBoundEditorIdentity(
          dataSet: widget.dataSet,
          fieldName: widget.fieldName,
          recordId: binding.recordId,
        );

        final customBuilder = widget.builder;
        if (customBuilder != null) {
          return KeyedSubtree(
            key: ValueKey<_FdcBoundEditorIdentity>(editorIdentity),
            child: _FdcBoundEditorFocusEventBridge(
              onFocusChange: (hasFocus) => _emitFocusEvent(
                context,
                binding,
                hasFocus ? widget.onEnter : widget.onExit,
              ),
              child: customBuilder(context, editorContext),
            ),
          );
        }

        final field = widget.fieldBuilder!(binding);
        return FdcEditorCore<TValue>(
          key: ValueKey<_FdcBoundEditorIdentity>(editorIdentity),
          field: field,
          value: editorContext.value,
          valueIdentity: recordIdentity,
          valueSyncIdentity: valueSyncIdentity,
          dataSet: widget.dataSet,
          fieldDef: binding.fieldDef,
          rowIndex: FdcDataSetInternal.activeIndex(widget.dataSet),
          onEnter: widget.onEnter,
          onExit: widget.onExit,
          onValueChanging: widget.onValueChanging,
          onValueChanged: widget.onValueChanged,
          onLookup: widget.onLookup == null
              ? null
              : (editorText, value, mode) =>
                    _invokeLookup(context, binding, editorText, value, mode),
          lookupIcon: widget.lookupIcon,
          lookupShortcut: widget.lookupShortcut,
          onCommit: (value) => _setBoundValue(binding, value),
          nonBlockingValueValidator: (value) =>
              _validateBoundValueAndEmit(binding, value),
          decoration: widget.decoration,
          theme: widget.theme,
          style: widget.style,
          enabled: isEnabled,
          readOnly: widget.readOnly || binding.readOnly,
          autofocus: widget.autofocus,
          showLabel: widget.showLabel,
          showPicker: widget.showPicker,
          selectAllOnFocus: widget.selectAllOnFocus,
          errorIndicator: widget.errorIndicator,
          validationErrorText: _validationErrorText(binding),
          formatSettings: formatSettings,
        );
      },
    );
  }

  Future<bool> _invokeLookup(
    BuildContext context,
    FdcFieldBinding<TField> binding,
    String? editorText,
    TValue? value,
    FdcLookupMode mode,
  ) async {
    final callback = widget.onLookup;
    if (callback == null ||
        _lookupInProgress ||
        !binding.hasCurrentRecord ||
        binding.readOnly ||
        widget.readOnly ||
        (widget.enabled ?? true) == false) {
      return true;
    }

    final lookupRecordId = binding.recordId;
    _lookupInProgress = true;

    final lookup = FdcLookupContext(
      buildContext: context,
      dataSet: widget.dataSet,
      fieldName: binding.fieldName,
      lookupText: editorText,
      lookupMode: mode,
    );
    final validationTranslations = FdcApp.translationsOf(context).validation;
    final lookupFailedMessage = validationTranslations.lookupFailed;

    try {
      final result = await callback(lookup);
      if (!mounted ||
          result == null ||
          lookupRecordId == null ||
          FdcDataSetInternal.currentRecordId(widget.dataSet) !=
              lookupRecordId) {
        return true;
      }
      binding.ensureCurrentRecordStillBound();

      final lookupValues = Map<String, Object?>.of(result.values);

      final normalizedPrimaryFieldName = FdcFieldName.normalize(
        binding.fieldName,
      );
      String? primaryLookupFieldName;
      Object? primaryLookupValue;
      for (final entry in lookupValues.entries) {
        if (FdcFieldName.normalize(entry.key) == normalizedPrimaryFieldName) {
          primaryLookupFieldName = entry.key;
          primaryLookupValue = entry.value;
          break;
        }
      }

      final oldValue = binding.valueOrNull as TValue?;
      TValue? acceptedValue = oldValue;
      Map<String, Object?> valueChangingAdditionalValues =
          const <String, Object?>{};
      var primaryChanged = false;
      final hasResolveValueFallback =
          mode == FdcLookupMode.resolve && primaryLookupFieldName == null;
      if (lookupValues.isEmpty && !hasResolveValueFallback) {
        return true;
      }
      if (primaryLookupFieldName != null || hasResolveValueFallback) {
        final typedPrimaryLookupValue = primaryLookupFieldName != null
            ? primaryLookupValue as TValue?
            : value;
        final change = _applyValueChanging(
          binding,
          oldValue,
          typedPrimaryLookupValue,
        );
        if (!change.accepted) {
          return false;
        }
        acceptedValue = change.hasReplacement
            ? change.value
            : typedPrimaryLookupValue;
        valueChangingAdditionalValues = change.additionalValues;
        primaryChanged = oldValue != acceptedValue;
        if (primaryLookupFieldName != null) {
          lookupValues.remove(primaryLookupFieldName);
        }
      }

      final editError = _beginBoundEdit(binding);
      if (editError != null) {
        await _showLookupErrorDialog(editError);
        return false;
      }

      _applyBoundLookupWrites(binding, acceptedValue, <String, Object?>{
        ...lookupValues,
        ...valueChangingAdditionalValues,
      });

      if (primaryChanged) {
        _validateBoundValueAndEmit(binding, acceptedValue);
        _emitValueChanged(binding, oldValue, acceptedValue);
      }
      return true;
    } on Object catch (error) {
      await _showLookupErrorDialog(
        FdcValidationMessageFormatter.fromObject(
          error,
          fallbackMessage: lookupFailedMessage,
          translations: validationTranslations,
        ),
      );
      return false;
    } finally {
      _lookupInProgress = false;
    }
  }

  void _applyBoundLookupWrites(
    FdcFieldBinding<TField> binding,
    Object? primaryValue,
    Map<String, Object?> additionalValues,
  ) {
    final normalizedPrimaryFieldName = FdcFieldName.normalize(
      binding.fieldName,
    );
    final writes = <String, Object?>{binding.fieldName: primaryValue};
    final normalizedWriteNames = <String, String>{
      normalizedPrimaryFieldName: binding.fieldName,
    };

    for (final entry in additionalValues.entries) {
      final normalizedFieldName = FdcFieldName.normalize(entry.key);
      if (normalizedFieldName == normalizedPrimaryFieldName) {
        continue;
      }
      final previousFieldName = normalizedWriteNames[normalizedFieldName];
      if (previousFieldName != null) {
        writes.remove(previousFieldName);
      }
      if (!widget.dataSet.hasField(entry.key)) {
        throw ArgumentError.value(entry.key, 'fieldName', 'Unknown field.');
      }
      normalizedWriteNames[normalizedFieldName] = entry.key;
      writes[entry.key] = entry.value;
    }

    final oldValues = <String, Object?>{};
    for (final fieldName in writes.keys) {
      oldValues[fieldName] = fieldName == binding.fieldName
          ? binding.valueOrNull
          : widget.dataSet.fieldValue(fieldName);
    }

    final changedFieldNames = <String>[];
    try {
      for (final entry in writes.entries) {
        if (oldValues[entry.key] == entry.value) {
          continue;
        }
        widget.dataSet.setFieldValue(entry.key, entry.value);
        changedFieldNames.add(entry.key);
      }
    } on Object catch (_) {
      for (final fieldName in changedFieldNames.reversed) {
        try {
          widget.dataSet.setFieldValue(fieldName, oldValues[fieldName]);
        } on Object {
          // Best-effort rollback. The original lookup failure is rethrown.
        }
      }
      rethrow;
    }
  }

  Future<void> _showLookupErrorDialog(String message) {
    final normalizedMessage = message.trim();
    if (!mounted || normalizedMessage.isEmpty) {
      return Future<void>.value();
    }
    if (_showingLookupErrorDialog) {
      return _lookupErrorDialogFuture ?? Future<void>.value();
    }

    _showingLookupErrorDialog = true;
    final future =
        showFdcMessageDialog(
              context,
              title: FdcApp.translationsOf(context).validation.validationError,
              message: normalizedMessage,
            )
            .catchError((_) {
              // Dialog presentation must not turn the original lookup failure into
              // another unhandled asynchronous exception.
            })
            .whenComplete(() {
              _showingLookupErrorDialog = false;
              _lookupErrorDialogFuture = null;
            });
    _lookupErrorDialogFuture = future;
    return future;
  }

  String? _commitBoundValue(FdcFieldBinding<TField> binding, TValue? value) {
    final oldValue = binding.valueOrNull as TValue?;
    final change = _applyValueChanging(binding, oldValue, value);
    if (!change.accepted) {
      return fdcEditorCommitCanceled;
    }

    final acceptedValue = change.hasReplacement ? change.value : value;
    final error = _setBoundValue(binding, acceptedValue);
    if (error != null) {
      return error;
    }

    _validateBoundValueAndEmit(binding, acceptedValue);
    _emitValueChanged(binding, oldValue, acceptedValue);
    return null;
  }

  FdcFieldValueChangeResult<TValue> _applyValueChanging(
    FdcFieldBinding<TField> binding,
    TValue? oldValue,
    TValue? newValue,
  ) {
    final listener = widget.onValueChanging;
    if (listener == null) {
      return FdcFieldValueChangeResult<TValue>.accept();
    }

    final context = FdcFieldValueChangingContext<TValue>(
      dataSet: widget.dataSet,
      host: FdcFieldEventHost.editor,
      fieldName: binding.fieldName,
      field: binding.fieldDef,
      rowIndex: FdcDataSetInternal.activeIndex(widget.dataSet),
      oldValue: oldValue,
      newValue: newValue,
      oldRawValue: oldValue,
      newRawValue: newValue,
      valueOf: widget.dataSet.fieldValue,
    );
    final result = listener(context) ?? context.accept();
    return result.withAdditionalValues(context.additionalValueSnapshot);
  }

  void _emitFocusEvent(
    BuildContext context,
    FdcFieldBinding<TField> binding,
    FdcFieldFocusCallback<TValue>? listener,
  ) {
    if (listener == null) {
      return;
    }

    listener(
      FdcFieldFocusContext<TValue>(
        buildContext: context,
        dataSet: widget.dataSet,
        host: FdcFieldEventHost.editor,
        fieldName: binding.fieldName,
        field: binding.fieldDef,
        rowIndex: FdcDataSetInternal.activeIndex(widget.dataSet),
        value: binding.valueOrNull as TValue?,
        rawValue: binding.valueOrNull,
      ),
    );
  }

  void _emitValueChanged(
    FdcFieldBinding<TField> binding,
    TValue? oldValue,
    TValue? value,
  ) {
    final listener = widget.onValueChanged;
    if (listener == null) {
      return;
    }

    listener(
      FdcFieldValueChangedContext<TValue>(
        dataSet: widget.dataSet,
        host: FdcFieldEventHost.editor,
        fieldName: binding.fieldName,
        field: binding.fieldDef,
        rowIndex: FdcDataSetInternal.activeIndex(widget.dataSet),
        oldValue: oldValue,
        value: value,
        oldRawValue: oldValue,
        rawValue: value,
      ),
    );
  }

  String? _beginBoundEdit(FdcFieldBinding<TField> binding) {
    if ((widget.enabled ?? true) == false ||
        widget.readOnly ||
        binding.readOnly) {
      return null;
    }

    try {
      binding.ensureCurrentRecordStillBound();
    } on Object catch (error) {
      return _dataSetErrorMessage(error);
    }

    if (widget.dataSet.state == FdcDataSetState.browse) {
      try {
        widget.dataSet.edit();
      } on Object catch (error) {
        return _dataSetErrorMessage(error);
      }
    }

    if (widget.dataSet.state != FdcDataSetState.edit &&
        widget.dataSet.state != FdcDataSetState.insert) {
      return _dataSetErrorMessage(null, fallbackMessage: 'Edit was canceled.');
    }

    return null;
  }

  String? _setBoundValue(FdcFieldBinding<TField> binding, TValue? value) {
    if ((widget.enabled ?? true) == false ||
        widget.readOnly ||
        binding.readOnly) {
      return null;
    }

    try {
      final editError = _beginBoundEdit(binding);
      if (editError != null) {
        return editError;
      }

      binding.setValue(value);
      return null;
    } on Object catch (error) {
      return _dataSetErrorMessage(error);
    }
  }

  String? _validateBoundValueAndEmit(
    FdcFieldBinding<TField> binding,
    TValue? value,
  ) {
    if ((widget.enabled ?? true) == false ||
        widget.readOnly ||
        binding.readOnly) {
      return null;
    }

    try {
      // Field-level validation is non-blocking for data-aware editors. The
      // dataset still emits onValidationError and updates its validation state;
      // the editor decides whether to show nothing, inline text, or the corner
      // indicator through one mutually exclusive validation presentation mode.
      final errors = binding.validateValueAndEmit(value);
      if (errors.isEmpty) {
        return null;
      }
      return errors.first.message;
    } on Object catch (error) {
      return _dataSetErrorMessage(error);
    }
  }

  String? _validationErrorText(FdcFieldBinding<TField> binding) {
    final recordId = binding.recordId;
    if (recordId == null || widget.dataSet.errors.messages.isEmpty) {
      return null;
    }

    final fieldName = FdcFieldName.normalize(binding.fieldName);
    final messages = <String>[];
    for (final error in FdcDataSetInternal.errorDetails(widget.dataSet)) {
      final errorFieldName = error.fieldName;
      if (errorFieldName == null ||
          FdcFieldName.normalize(errorFieldName) != fieldName) {
        continue;
      }

      final errorRecordId = error.recordId;
      if (errorRecordId != null && errorRecordId != recordId) {
        continue;
      }

      if (error.message.isNotEmpty) {
        messages.add(error.message);
      }
    }

    if (messages.isEmpty) {
      return null;
    }
    return messages.join('\n');
  }

  String? _dataSetErrorMessage(Object? error, {String? fallbackMessage}) {
    if (error is FdcDataSetAbortException && error.isSilent) {
      return fallbackMessage ?? 'Operation was canceled.';
    }

    if (error is FdcDataSetException) {
      if (error.errors.isNotEmpty) {
        return error.errors.map((item) => item.message).join('\n');
      }
      if (error.message.isNotEmpty) {
        return error.message;
      }
    }

    if (widget.dataSet.errors.messages.isNotEmpty) {
      return widget.dataSet.errors.message;
    }

    if (error == null) {
      return fallbackMessage;
    }

    final text = error.toString();
    const exceptionPrefix = 'Exception: ';
    if (text.startsWith(exceptionPrefix)) {
      return text.substring(exceptionPrefix.length);
    }
    return text.isEmpty ? fallbackMessage : text;
  }
}

@immutable
class _FdcBoundEditorFocusEventBridge extends StatelessWidget {
  const _FdcBoundEditorFocusEventBridge({
    required this.onFocusChange,
    required this.child,
  });

  final ValueChanged<bool> onFocusChange;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: onFocusChange,
      child: child,
    );
  }
}

@immutable
class _FdcBoundEditorValueSyncIdentity {
  _FdcBoundEditorValueSyncIdentity({
    required this.recordId,
    required Object? value,
  }) : valueType = value.runtimeType,
       valueText = value?.toString(),
       _value = value;

  final int? recordId;
  final Type valueType;
  final String? valueText;
  final Object? _value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FdcBoundEditorValueSyncIdentity &&
          other.recordId == recordId &&
          other.valueType == valueType &&
          other.valueText == valueText &&
          other._value == _value;

  @override
  int get hashCode => Object.hash(recordId, valueType, valueText, _value);
}

class _FdcBoundEditorIdentity {
  const _FdcBoundEditorIdentity({
    required this.dataSet,
    required this.fieldName,
    required this.recordId,
  });

  final FdcDataSet dataSet;
  final String fieldName;

  /// Record-scoped identity for the generated editor subtree. Same-record value
  /// changes can arrive from the grid, another editor, calculated fields, or
  /// user code, but they must not replace the editor FocusNode while a keyboard
  /// traversal request is trying to move into the editor. The editor core still
  /// receives the changed value and synchronizes its controller in place.
  final int? recordId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _FdcBoundEditorIdentity &&
            identical(dataSet, other.dataSet) &&
            fieldName == other.fieldName &&
            recordId == other.recordId;
  }

  @override
  int get hashCode =>
      Object.hash(identityHashCode(dataSet), fieldName, recordId);
}
