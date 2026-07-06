// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HardwareKeyboard;

import '../../app/fdc_app.dart';
import '../../common/codecs/fdc_value_codec.dart';
import '../../common/events/fdc_field_events.dart';
import '../../common/format/fdc_format_settings.dart';
import '../../common/input/fdc_focus_traversal.dart';
import '../../common/input/fdc_input_decoration.dart';
import '../../common/input/fdc_input_state.dart';
import '../../common/input/fdc_keyboard_shortcut.dart';
import '../../common/input/fdc_keyboard_shortcut_internal.dart';
import '../../common/input/fdc_picker_button.dart';
import '../../common/input/fdc_value_picker.dart';
import '../../common/lookup/fdc_lookup_result.dart';
import '../../common/theme/fdc_editor_theme.dart';
import '../../common/validation/fdc_validation_message_formatter.dart';
import '../../common/widgets/counter/fdc_counter_overlay.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';
import '../../data/fdc_dataset.dart';
import '../../data/fdc_field_def.dart';
import '../../dialogs/fdc_message_dialog.dart';
import '../../i18n/fdc_translations.dart';
import '../input/fdc_editor_commit_behavior.dart';
import '../input/fdc_editor_keyboard_handler.dart';
import '../input/fdc_editor_value_codec_config.dart';
import '../widgets/fdc_error_indicator_frame.dart';
import 'fdc_edit_types.dart';
import 'fdc_editor_commit_result.dart';
import 'fdc_editor_descriptor.dart';
import 'fdc_editor_text_session.dart';

/// One configurable edit control driven by form field metadata.
class FdcEditorCore<T> extends StatefulWidget {
  /// Creates an editor core widget.
  const FdcEditorCore({
    super.key,
    required this.field,
    this.value,
    this.onCommit,
    this.valueValidator,
    this.nonBlockingValueValidator,
    this.decoration,
    this.theme,
    this.style = const FdcEditorInputStyle(),
    this.enabled,
    this.readOnly = false,
    this.focusOrder,
    this.tabStop,
    this.autofocus = false,
    this.showLabel = true,
    this.showPicker,
    this.selectAllOnFocus = false,
    this.errorIndicator = const FdcErrorIndicatorOptions(),
    this.validationErrorText,
    this.initialText,
    this.valueIdentity,
    this.valueSyncIdentity,
    this.formatSettings,
    this.dataSet,
    this.fieldDef,
    this.rowIndex,
    this.onEnter,
    this.onExit,
    this.onValueChanging,
    this.onValueChanged,
    this.onLookup,
    this.lookupIcon = Icons.more_horiz,
    this.lookupShortcut = FdcKeyboardShortcut.f4,
  });

  /// Descriptor that defines the editor type and metadata.
  final FdcEditorDescriptor<T> field;

  /// Current typed value displayed by the editor.
  final T? value;

  /// Callback invoked when the editor commits a value.
  final FdcValueCommitter<T>? onCommit;

  /// Synchronous validator for committed typed values.
  final String? Function(T? value)? valueValidator;

  /// Validator that reports errors without blocking commit.
  final String? Function(T? value)? nonBlockingValueValidator;

  /// Optional input decoration override.
  final InputDecoration? decoration;

  /// Optional editor theme override.
  final FdcEditorThemeData? theme;

  /// Input text and decoration style override.
  final FdcEditorInputStyle style;

  /// Optional enabled-state override.
  final bool? enabled;

  /// Whether the editor prevents user edits.
  final bool readOnly;

  /// Optional focus traversal order override.
  final int? focusOrder;

  /// Optional keyboard tab traversal override.
  final bool? tabStop;

  /// Whether the editor requests focus when first built.
  final bool autofocus;

  /// Whether the descriptor label is shown.
  final bool showLabel;

  /// Optional picker button visibility override.
  final bool? showPicker;

  /// Whether editor text is selected when focus enters.
  final bool selectAllOnFocus;

  /// Validation error presentation options.
  final FdcErrorIndicatorOptions errorIndicator;

  /// External validation error text displayed by the editor.
  final String? validationErrorText;

  /// Optional initial raw text before typed value synchronization.
  final String? initialText;

  /// Optional app/subtree format settings resolved by parent widgets.
  ///
  /// Bound editors pass these explicitly so the first controller text and all
  /// subsequent codec rebuilds use the same locale-aware settings as the grid.
  final FdcFormatSettings? formatSettings;

  /// Optional dataset bound to this editor.
  final FdcDataSet? dataSet;

  /// Optional dataset field definition bound to this editor.
  final FdcFieldDef? fieldDef;

  /// Optional source row index for data-bound editor events.
  final int? rowIndex;

  /// Callback invoked when focus enters the editor.
  final FdcFieldFocusCallback<T>? onEnter;

  /// Callback invoked when focus exits the editor.
  final FdcFieldFocusCallback<T>? onExit;

  /// Callback invoked before a value is committed.
  final FdcFieldValueChangingCallback<T>? onValueChanging;

  /// Callback invoked after a value is committed.
  final FdcFieldValueChangedCallback<T>? onValueChanged;

  /// Optional lookup callback invoked by the picker button or shortcut.
  final Future<bool> Function(String? editorText, T? value, FdcLookupMode mode)?
  onLookup;

  /// Icon displayed by the lookup button.
  final IconData lookupIcon;

  /// Optional keyboard shortcut that opens lookup.
  final FdcKeyboardShortcut? lookupShortcut;

  /// Optional identity for the logical value source represented by this editor.
  ///
  /// Data-aware editors pass the current dataset record id here. When the
  /// identity changes, local edit text/error state must be discarded even if
  /// the control still has focus or its typed value compares equal to the next
  /// record value.
  final Object? valueIdentity;

  /// Optional fingerprint for the current bound value within [valueIdentity].
  ///
  /// Bound editors keep their widget key record-scoped so focus traversal stays
  /// stable when another component reports validation for the same field. This
  /// separate sync identity lets the editor still detect same-record external
  /// value changes and refresh its controller in place without replacing the
  /// underlying FocusNode.
  final Object? valueSyncIdentity;

  @override
  State<FdcEditorCore<T>> createState() => _FdcEditorCoreState<T>();
}

class _FdcEditorCoreState<T> extends State<FdcEditorCore<T>> {
  final _formFieldKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  FdcFormatSettings _formatSettings = const FdcFormatSettings();
  FdcValidationTranslations _validationTranslations =
      const FdcValidationTranslations();
  FdcEditorThemeData _editorTheme = FdcEditorThemes.light;
  FdcEditorInputStyle _inputStyle = FdcEditorInputStyle.defaults;
  late FdcEditorCommitBehavior _commitBehavior;
  late FdcEditorKeyboardHandler _keyboardHandler;
  late FdcValueCodec<T> _valueCodec;
  bool _handlingFocusMove = false;
  bool _loadedDependencies = false;
  bool _dirty = false;
  bool _committing = false;
  String? _localErrorText;
  bool _localErrorBlocksCommit = false;
  String _textBeforeEdit = '';
  TextEditingValue? _pendingControllerValue;
  bool _controllerSyncScheduled = false;
  bool _hasPendingCommittedValue = false;
  T? _pendingCommittedValue;
  bool _showingValidationErrorDialog = false;
  bool _suppressNextResolveLookup = false;
  bool _lookupResolveInProgress = false;
  bool _preserveDirtyOnNextFocus = false;
  bool _suppressNextBlurCommitAfterLookupFailure = false;

  bool get _isEnabled => (widget.enabled ?? true) && widget.field.enabled;

  bool get _isReadOnly => widget.readOnly || widget.field.readOnly;

  FdcInputState get _inputState =>
      FdcInputState(enabled: _isEnabled, readOnly: _isReadOnly);

  bool get _canEdit => _inputState.canEdit;

  bool get _effectiveTabStop => widget.tabStop ?? widget.field.tabStop;

  int? get _effectiveFocusOrder => widget.focusOrder ?? widget.field.focusOrder;

  @override
  void initState() {
    super.initState();
    // Build the initial controller text with the same local formatting that
    // `didChangeDependencies` will use. Data-aware editors are often recreated
    // during dataset cursor movement; using the default format settings for the
    // first controller value can leave date/time editors briefly or
    // persistently show the wrong representation after scroll/position changes.
    _formatSettings =
        widget.formatSettings ?? FdcApp.formatsOfNonListening(context);
    _validationTranslations = FdcApp.translationsOfNonListening(
      context,
    ).validation;
    _rebuildInputHelpers();
    final initialText = widget.initialText ?? _controllerTextFromWidget();
    _controller = TextEditingController.fromValue(
      TextEditingValue(
        text: initialText,
        selection: TextSelection.collapsed(offset: initialText.length),
      ),
    );
    if (widget.autofocus && widget.selectAllOnFocus) {
      _scheduleSelectAllText();
    }
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent)
      ..addListener(_handleFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextSettings = widget.formatSettings ?? FdcApp.formatsOf(context);
    final nextValidationTranslations = FdcApp.translationsOf(
      context,
    ).validation;
    final nextTheme = FdcEditorTheme.resolveData(context, widget.theme);
    final nextInputStyle = FdcEditorTheme.resolveInputStyle(
      context,
      localTheme: widget.theme,
      localStyle: widget.style,
    );
    final styleChanged =
        !_loadedDependencies ||
        nextTheme != _editorTheme ||
        nextInputStyle != _inputStyle;
    if (!_loadedDependencies ||
        nextSettings != _formatSettings ||
        nextValidationTranslations != _validationTranslations ||
        styleChanged) {
      _loadedDependencies = true;
      _formatSettings = nextSettings;
      _validationTranslations = nextValidationTranslations;
      _editorTheme = nextTheme;
      _inputStyle = nextInputStyle;
      _rebuildInputHelpers();
      _syncControllerTextFromWidget(resetLocalEditState: true);
    }
  }

  @override
  void didUpdateWidget(covariant FdcEditorCore<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final fieldChanged = oldWidget.field != widget.field;
    final appSettingsChanged =
        oldWidget.formatSettings != widget.formatSettings ||
        oldWidget.theme != widget.theme ||
        oldWidget.style != widget.style;
    if (appSettingsChanged) {
      final nextSettings = widget.formatSettings ?? FdcApp.formatsOf(context);
      _formatSettings = nextSettings;
      _validationTranslations = FdcApp.translationsOf(context).validation;
      _editorTheme = FdcEditorTheme.resolveData(context, widget.theme);
      _inputStyle = FdcEditorTheme.resolveInputStyle(
        context,
        localTheme: widget.theme,
        localStyle: widget.style,
      );
      _rebuildInputHelpers();
      _syncControllerTextFromWidget(resetLocalEditState: true, force: true);
    } else if (fieldChanged) {
      _rebuildInputHelpers();
    }
    if (oldWidget.initialText != widget.initialText &&
        widget.initialText != null) {
      final nextText = widget.initialText!;
      _setControllerText(nextText);
      _textBeforeEdit = nextText;
      _clearLocalEditState();
      _resetFormFieldState();
      return;
    }

    final validationPresentationChanged =
        oldWidget.validationErrorText != widget.validationErrorText ||
        oldWidget.errorIndicator.mode != widget.errorIndicator.mode;
    if (validationPresentationChanged) {
      _formFieldKey.currentState?.validate();
    }

    final localCommitEcho =
        _hasPendingCommittedValue &&
        _valuesEqual(widget.value, _pendingCommittedValue);
    if (localCommitEcho) {
      _hasPendingCommittedValue = false;
      _pendingCommittedValue = null;
      return;
    }

    final valueIdentityChanged =
        oldWidget.valueIdentity != widget.valueIdentity;
    final valueSyncIdentityChanged =
        oldWidget.valueSyncIdentity != widget.valueSyncIdentity;
    final valueChanged = oldWidget.value != widget.value;
    if (fieldChanged ||
        valueIdentityChanged ||
        valueSyncIdentityChanged ||
        valueChanged) {
      // Same-record value changes can come from a grid cell, another bound
      // editor, calculated-field refresh, or direct dataset writes. Since the
      // editor subtree is now record-keyed to preserve its FocusNode during
      // traversal, do the value synchronization explicitly instead of
      // relying on
      // a value-keyed rebuild. Force only real value changes so validation-only
      // rebuilds keep the user's in-progress local text.
      _syncControllerTextFromWidget(
        resetLocalEditState: true,
        force: valueIdentityChanged || valueSyncIdentityChanged || valueChanged,
        forEditing: valueIdentityChanged && _focusNode.hasFocus,
      );
    }
  }

  void _rebuildInputHelpers() {
    _commitBehavior = FdcEditorCommitBehavior.forKind(widget.field.editType);
    _keyboardHandler = FdcEditorKeyboardHandler(
      kind: widget.field.editType,
      commitBehavior: _commitBehavior,
    );
    _valueCodec = FdcValueCodecResolver.resolve<T>(
      fdcValueCodecConfigFromEditorDescriptor(
        widget.field,
        formatSettings: _formatSettings,
        validationTranslations: _validationTranslations,
      ),
    );
  }

  void _syncControllerTextFromWidget({
    bool resetLocalEditState = false,
    bool force = false,
    bool forEditing = false,
    bool immediate = false,
  }) {
    if (!force && _focusNode.hasFocus && _dirty) {
      return;
    }

    final nextText = _controllerTextFromWidget(forEditing: forEditing);
    if (_controller.text != nextText) {
      _setControllerText(nextText, immediate: immediate);
    }
    if (resetLocalEditState) {
      _textBeforeEdit = nextText;
      _clearLocalEditState();
      _refreshFormFieldValidation();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _focusNode
      ..canRequestFocus = _effectiveTabStop && _isEnabled
      ..skipTraversal = !_effectiveTabStop || !_isEnabled;

    final editor = switch (widget.field.editType) {
      FdcEditorKind.date ||
      FdcEditorKind.dateTime ||
      FdcEditorKind.time => _buildPicker(context),
      FdcEditorKind.memo => _buildTextField(context, maxLines: 4),
      FdcEditorKind.text ||
      FdcEditorKind.integer ||
      FdcEditorKind.decimal => _buildTextField(context),
    };

    return _buildFocusTraversal(editor);
  }

  Widget _buildTextField(BuildContext context, {int maxLines = 1}) {
    final editorKind = widget.field.editType;

    final textField = TextFormField(
      key: _formFieldKey,
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      enabled: _isEnabled,
      readOnly: _isReadOnly,
      maxLines: maxLines,
      maxLength: widget.field.maxLength,
      buildCounter: _hideCounter,
      style: _textStyle(context),
      cursorColor: _inputStyle.cursorColor,
      autovalidateMode: AutovalidateMode.disabled,
      decoration: _decoration(suffixIcon: _lookupIcon(context)),
      keyboardType: _valueCodec.keyboardType(),
      textInputAction: editorKind == FdcEditorKind.memo
          ? TextInputAction.newline
          : TextInputAction.next,
      inputFormatters: _valueCodec.inputFormatters(),
      validator: _validateText,
      onTap: widget.selectAllOnFocus ? _scheduleSelectAllText : null,
      onChanged: _handleTextChanged,
      onEditingComplete: () {},
      onFieldSubmitted: (_) => _moveFocusNext(),
    );

    final maxLength = widget.field.maxLength;
    final content = !widget.field.showCounter || maxLength == null
        ? textField
        : FdcCounterOverlay(
            visible: _focusNode.hasFocus,
            textListenable: _controller,
            maxLength: maxLength,
            style: _editorTheme.counter.merge(widget.field.counterStyle),
            child: textField,
          );

    return _buildErrorIndicatorFrame(content);
  }

  Widget _buildPicker(BuildContext context) {
    final picker = TextFormField(
      key: _formFieldKey,
      controller: _controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      enabled: _isEnabled,
      readOnly: _isReadOnly,
      autovalidateMode: AutovalidateMode.disabled,
      style: _textStyle(context),
      cursorColor: _inputStyle.cursorColor,
      decoration: _decoration(suffixIcon: _suffixActions(context)),
      keyboardType: TextInputType.datetime,
      textInputAction: TextInputAction.next,
      inputFormatters: _valueCodec.inputFormatters(),
      validator: _validateText,
      onTap: widget.selectAllOnFocus ? _scheduleSelectAllText : null,
      onChanged: _handleTextChanged,
      onEditingComplete: () {},
      onFieldSubmitted: (_) => _moveFocusNext(),
    );

    return _buildErrorIndicatorFrame(picker);
  }

  Widget _buildErrorIndicatorFrame(Widget child) {
    return FdcErrorIndicatorFrame(
      errorIndicator: widget.errorIndicator,
      errorMessage: _effectiveValidationErrorText,
      inlineHandledByChild: true,
      child: child,
    );
  }

  Widget _buildFocusTraversal(Widget child) {
    return FdcFocusTraversal.wrap(
      focusOrder: _effectiveFocusOrder,
      child: child,
    );
  }

  Future<void> _moveFocusNext() async {
    if (_handlingFocusMove) {
      return;
    }

    if (!await _commitBeforeFocusMove()) {
      if (mounted && _isEnabled) {
        _focusNode.requestFocus();
      }
      return;
    }
    if (!mounted) {
      return;
    }
    _handlingFocusMove = true;
    FocusScope.of(context).nextFocus();
    _unlockFocusMoveSoon();
  }

  Future<void> _moveFocusPrevious() async {
    if (_handlingFocusMove) {
      return;
    }

    if (!await _commitBeforeFocusMove()) {
      if (mounted && _isEnabled) {
        _focusNode.requestFocus();
      }
      return;
    }
    if (!mounted) {
      return;
    }
    _handlingFocusMove = true;
    FocusScope.of(context).previousFocus();
    _unlockFocusMoveSoon();
  }

  Future<bool> _commitBeforeFocusMove() {
    return _commitEditing(updateState: true);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final lookupShortcut = widget.lookupShortcut;
    if (widget.onLookup != null &&
        lookupShortcut != null &&
        fdcKeyboardShortcutAccepts(
          lookupShortcut,
          event,
          HardwareKeyboard.instance,
        )) {
      unawaited(_invokeLookup(mode: FdcLookupMode.search));
      return KeyEventResult.handled;
    }

    final action = _keyboardHandler.handle(event);
    switch (action) {
      case FdcEditorKeyboardAction.block:
        return KeyEventResult.handled;
      case FdcEditorKeyboardAction.moveNext:
        unawaited(_moveFocusNext());
        return KeyEventResult.handled;
      case FdcEditorKeyboardAction.movePrevious:
        unawaited(_moveFocusPrevious());
        return KeyEventResult.handled;
      case FdcEditorKeyboardAction.revert:
        _handleEscape();
        return KeyEventResult.handled;
      case FdcEditorKeyboardAction.none:
        return KeyEventResult.ignored;
    }
  }

  void _unlockFocusMoveSoon() {
    unawaited(
      Future<void>.microtask(() {
        if (mounted) {
          _handlingFocusMove = false;
        }
      }),
    );
  }

  void _handleEscape() {
    if (_hasLocalEditToRevert) {
      _undoEdit();
    }
  }

  bool get _hasLocalEditToRevert => FdcEditorTextSession.hasLocalEditToRevert(
    dirty: _dirty,
    localErrorText: _localErrorText,
    controllerText: _controller.text,
    baselineText: _textBeforeEdit,
  );

  void _undoEdit() {
    _controller.value = FdcEditorTextSession.collapsedValue(_textBeforeEdit);
    _clearLocalEditState();
    _formFieldKey.currentState?.reset();
    setState(() {});
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      if (widget.field.editType == FdcEditorKind.decimal) {
        // When a decimal editor receives focus we switch from display text to
        // edit text (for example, removing thousands separators). Use the
        // bound value as the source of truth instead of reparsing the current
        // controller text. Re-parsing display text is ambiguous across locales:
        // with decimalSeparator=',' and thousandSeparator='.', a display value
        // such as `887.70` would be interpreted as grouped integer text and
        // converted to `88770,00` on focus.
        final editText = widget.value == null
            ? _valueCodec.formatValue(
                _valueCodec.parseText(_controller.text),
                forEditing: true,
              )
            : _valueCodec.formatValue(widget.value, forEditing: true);
        if (_controller.text != editText) {
          _controller.value = FdcEditorTextSession.collapsedValue(editText);
        }
      }

      // Focus-time normalization is presentation only. In particular, decimal
      // editors can replace display text with edit text as soon as they receive
      // focus. Treat that normalized text as the clean baseline so a plain
      // focus-in/focus-out cycle never promotes the dataset to edit mode.
      //
      // A failed lookup resolve is different: focus is intentionally restored
      // to let the user retry the same typed value. In that case, preserving
      // the dirty baseline is what makes the next explicit commit retry lookup
      // instead of treating the failed text as clean.
      if (_preserveDirtyOnNextFocus) {
        _preserveDirtyOnNextFocus = false;
      } else {
        _textBeforeEdit = _controller.text;
        _clearLocalEditState();
      }

      _emitFocusEvent(widget.onEnter);

      if (widget.selectAllOnFocus) {
        _scheduleSelectAllText();
      }
      setState(() {});
      return;
    }

    if (_suppressNextBlurCommitAfterLookupFailure) {
      _suppressNextBlurCommitAfterLookupFailure = false;
      _emitFocusEvent(widget.onExit);
      return;
    }

    if (_commitBehavior.commitOnBlur) {
      unawaited(_commitEditing(updateState: true));
    }
    _emitFocusEvent(widget.onExit);
  }

  Future<bool> _commitEditing({required bool updateState}) async {
    if (FdcEditorTextSession.isCleanForCommit(
      dirty: _dirty,
      localErrorText: _localErrorText,
      localErrorBlocksCommit: _localErrorBlocksCommit,
    )) {
      // Keyboard traversal commits before moving focus. The focus-loss callback
      // then runs while the parent AnimatedBuilder may still carry the old
      // widget value. Reformatting from widget.value in that small window makes
      // the editor briefly flash the previous value. During an active focus
      // move, keep the already committed controller text and let the next
      // dataset rebuild confirm it.
      if (!_handlingFocusMove) {
        _formatDisplayTextAfterEdit(widget.value);
      }
      if (updateState) {
        setState(() {});
      }
      return true;
    }

    if (!_validateForCommit(updateState: updateState)) {
      unawaited(
        _showValidationErrorDialog(
          _validateText(_controller.text) ??
              widget.validationErrorText ??
              FdcValidationMessageFormatter.defaultMessage(
                FdcApp.translationsOf(context).validation,
              ),
        ),
      );
      return false;
    }

    final parseResult = _valueCodec.parseForCommit(_controller.text);
    if (parseResult.errorText != null) {
      _localErrorText = parseResult.errorText;
      _localErrorBlocksCommit = true;
      if (updateState) {
        _formFieldKey.currentState?.validate();
        setState(() {});
      }
      _showValidationErrorDialog(parseResult.errorText!);
      return false;
    }

    final normalizedText = parseResult.normalizedText;
    if (normalizedText != null && normalizedText != _controller.text) {
      _controller.value = FdcEditorTextSession.collapsedValue(normalizedText);
    }

    final value = parseResult.value;
    if (widget.onLookup != null) {
      if (_suppressNextResolveLookup) {
        _suppressNextResolveLookup = false;
        _formatDisplayTextAfterEdit(widget.value);
        _textBeforeEdit = _controller.text;
        _clearLocalEditState();
        if (updateState) {
          _formFieldKey.currentState?.validate();
          setState(() {});
        }
        return true;
      }

      if (_lookupResolveInProgress) {
        return false;
      }

      _lookupResolveInProgress = true;
      try {
        final accepted = await _invokeLookup(
          mode: FdcLookupMode.resolve,
          value: value,
          hasExplicitValue: true,
        );
        if (!mounted) {
          return false;
        }
        if (accepted) {
          _textBeforeEdit = _controller.text;
          _clearLocalEditState();
          if (updateState) {
            _formFieldKey.currentState?.validate();
            setState(() {});
          }
        }
        return accepted;
      } finally {
        if (mounted) {
          _lookupResolveInProgress = false;
        }
      }
    }

    if (_valuesEqual(value, widget.value)) {
      _formatDisplayTextAfterEdit(value);
      _textBeforeEdit = _controller.text;
      _clearLocalEditState();
      if (updateState) {
        _formFieldKey.currentState?.validate();
        setState(() {});
      }
      return true;
    }

    final error = _commitValue(value);
    if (error == null) {
      final committedValue = _hasPendingCommittedValue
          ? _pendingCommittedValue
          : value;
      _formatDisplayTextAfterEdit(committedValue);
      _textBeforeEdit = _controller.text;
    }
    if (updateState) {
      _formFieldKey.currentState?.validate();
      setState(() {});
    }
    if (error != null && !fdcIsEditorCommitCanceled(error)) {
      unawaited(_showValidationErrorDialog(error));
    }
    return error == null;
  }

  Future<void> _showValidationErrorDialog(String message) {
    final normalizedMessage = message.trim();
    if (!mounted ||
        normalizedMessage.isEmpty ||
        _showingValidationErrorDialog) {
      return Future<void>.value();
    }

    final completer = Completer<void>();
    _showingValidationErrorDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _showingValidationErrorDialog = false;
        if (!completer.isCompleted) {
          completer.complete();
        }
        return;
      }

      unawaited(
        showFdcMessageDialog(
              context,
              title: FdcApp.translationsOf(context).validation.validationError,
              message: normalizedMessage,
            )
            .catchError((_) {
              // Dialog presentation must not turn the original validation failure
              // into an unhandled asynchronous exception.
            })
            .whenComplete(() {
              _showingValidationErrorDialog = false;
              if (mounted && _isEnabled) {
                _focusNode.requestFocus();
              }
              if (!completer.isCompleted) {
                completer.complete();
              }
            }),
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
    return completer.future;
  }

  bool _validateForCommit({required bool updateState}) {
    if (_localErrorText != null && !_localErrorBlocksCommit) {
      return true;
    }

    _committing = true;
    try {
      final isValid = _formFieldKey.currentState?.validate() ?? true;
      if (!isValid && updateState) {
        setState(() {});
      }
      return isValid;
    } finally {
      _committing = false;
    }
  }

  void _formatDisplayTextAfterEdit(Object? value) {
    final displayText = _valueCodec.formatValue(value);
    if (_controller.text != displayText) {
      _controller.value = FdcEditorTextSession.collapsedValue(displayText);
    }
  }

  void _scheduleSelectAllText() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus || !widget.selectAllOnFocus) {
        return;
      }
      _selectAllText();
    });
  }

  void _selectAllText() {
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _refreshFormFieldValidation() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _formFieldKey.currentState?.validate();
        }
      });
      return;
    }

    _formFieldKey.currentState?.validate();
  }

  void _resetFormFieldState() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _formFieldKey.currentState?.reset();
        }
      });
      return;
    }

    _formFieldKey.currentState?.reset();
  }

  void _setControllerText(String text, {bool immediate = false}) {
    final value = FdcEditorTextSession.collapsedValue(text);
    _setControllerValue(value, immediate: immediate);
  }

  void _setControllerValue(TextEditingValue value, {bool immediate = false}) {
    if (_controller.value == value) {
      return;
    }

    if (immediate) {
      _pendingControllerValue = null;
      _controllerSyncScheduled = false;
      _controller.value = value;
      return;
    }

    if (_isInFrameworkBuildPhase) {
      _scheduleControllerValue(value);
      return;
    }

    _controller.value = value;
  }

  bool get _isInFrameworkBuildPhase =>
      SchedulerBinding.instance.schedulerPhase ==
      SchedulerPhase.persistentCallbacks;

  void _scheduleControllerValue(TextEditingValue value) {
    _pendingControllerValue = value;
    if (_controllerSyncScheduled) {
      return;
    }

    _controllerSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllerSyncScheduled = false;
      final pendingValue = _pendingControllerValue;
      _pendingControllerValue = null;
      if (!mounted ||
          pendingValue == null ||
          _controller.value == pendingValue) {
        return;
      }
      _controller.value = pendingValue;
    });
  }

  Future<void> _pickValue(BuildContext context) async {
    final value = await FdcValuePicker.pick(
      context: context,
      kind: _valueCodec.config.kind,
      currentValue: widget.value,
      codec: _valueCodec,
    );
    if (!mounted || value == null) {
      return;
    }

    final error = _commitValue(value as T?);
    if (error == null) {
      _formatDisplayTextAfterEdit(value);
      _textBeforeEdit = _controller.text;
      _formFieldKey.currentState?.validate();
      if (mounted) {
        setState(() {});
      }
    } else if (!fdcIsEditorCommitCanceled(error)) {
      unawaited(_showValidationErrorDialog(error));
    }
  }

  InputDecoration _decoration({Widget? suffixIcon}) {
    return FdcInputDecoration.editor(
      decoration: widget.decoration,
      labelText: widget.field.label,
      hintText: widget.field.hint,
      showLabel: widget.showLabel,
      isEnabled: _inputState.enabled,
      isReadOnly: _inputState.readOnly,
      isFocused: _focusNode.hasFocus,
      style: _inputStyle,
      suffixIcon: suffixIcon,
    );
  }

  Widget? _hideCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    return null;
  }

  Widget? _suffixActions(BuildContext context) {
    final actions = <Widget>[?_pickerIcon(context), ?_lookupIcon(context)];
    if (actions.isEmpty) {
      return null;
    }
    if (actions.length == 1) {
      return actions.single;
    }
    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  Widget? _lookupIcon(BuildContext context) {
    if (widget.onLookup == null || !_canEdit) {
      return null;
    }
    final shortcut = widget.lookupShortcut;
    return ExcludeFocus(
      child: IconButton(
        onPressed: () => unawaited(_invokeLookup(mode: FdcLookupMode.search)),
        icon: Icon(widget.lookupIcon, color: _pickerIconColor(context)),
        iconSize: 18,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        splashRadius: 16,
        padding: EdgeInsets.zero,
        tooltip: shortcut == null
            ? FdcApp.translationsOf(context).common.lookup
            : '${FdcApp.translationsOf(context).common.lookup} '
                  '(${shortcut.displayLabel})',
      ),
    );
  }

  Future<bool> _invokeLookup({
    FdcLookupMode mode = FdcLookupMode.search,
    T? value,
    bool hasExplicitValue = false,
  }) async {
    final callback = widget.onLookup;
    if (callback == null || !_canEdit) {
      return true;
    }
    var lookupValue = hasExplicitValue ? value : widget.value;
    if (!hasExplicitValue) {
      final parsed = _valueCodec.parseForCommit(_controller.text);
      if (parsed.errorText == null) {
        lookupValue = parsed.value;
      }
    }
    final validationTranslations = FdcApp.translationsOf(context).validation;
    final lookupFailedMessage = validationTranslations.lookupFailed;
    var accepted = false;
    try {
      accepted = await callback(_controller.text, lookupValue, mode);
    } on Object catch (error) {
      await _showValidationErrorDialog(
        FdcValidationMessageFormatter.fromObject(
          error,
          fallbackMessage: lookupFailedMessage,
          translations: validationTranslations,
        ),
      );
      accepted = false;
    }
    if (accepted && mode == FdcLookupMode.search && mounted) {
      _suppressNextResolveLookup = true;
    }
    if (!accepted && mounted && _isEnabled) {
      _preserveDirtyOnNextFocus = true;
      _suppressNextBlurCommitAfterLookupFailure = true;
      _focusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isEnabled) {
          _preserveDirtyOnNextFocus = true;
          _focusNode.requestFocus();
        }
      });
    }
    return accepted;
  }

  Widget? _pickerIcon(BuildContext context) {
    if (!_effectiveShowPicker || !_canEdit) {
      return null;
    }

    return FdcPickerButton(
      onPressed: () => _pickValue(context),
      compact: true,
      iconColor: _pickerIconColor(context),
    );
  }

  TextStyle? _textStyle(BuildContext context) {
    return Theme.of(
          context,
        ).textTheme.bodyMedium?.merge(_inputStyle.textStyle) ??
        _inputStyle.textStyle;
  }

  Color? _pickerIconColor(BuildContext context) {
    if (!_canEdit) {
      return _editorTheme.controls.disabledIconColor ??
          Theme.of(context).disabledColor;
    }
    return _editorTheme.controls.iconColor ??
        Theme.of(context).colorScheme.onSurfaceVariant;
  }

  String _controllerTextFromWidget({bool forEditing = false}) {
    final initialText = widget.initialText;
    if (initialText != null && !forEditing) {
      // `initialText` is caller-supplied presentation text, not a raw value to
      // reparse/reformat with the current locale. Keep it stable until the
      // editor explicitly switches into edit mode, where the bound value is the
      // source of truth.
      return initialText;
    }
    return _valueCodec.formatValue(widget.value, forEditing: forEditing);
  }

  String? _validateText(String? value) {
    final errorText = _valueCodec.validateText(
      value,
      committing: _committing,
      localErrorText: _localErrorText,
    );
    if (widget.errorIndicator.showsInline) {
      return errorText ?? widget.validationErrorText;
    }
    return null;
  }

  String? get _effectiveValidationErrorText {
    final localError = _localErrorText;
    if (localError != null && localError.isNotEmpty) {
      return localError;
    }

    final externalError = widget.validationErrorText;
    if (externalError != null && externalError.isNotEmpty) {
      return externalError;
    }

    return null;
  }

  void _clearLocalEditState() {
    _dirty = false;
    _preserveDirtyOnNextFocus = false;
    _suppressNextBlurCommitAfterLookupFailure = false;
    _clearLocalErrorState();
  }

  void _clearLocalErrorState() {
    _localErrorText = null;
    _localErrorBlocksCommit = false;
  }

  void _handleTextChanged(String _) {
    _suppressNextBlurCommitAfterLookupFailure = false;
    _dirty = _controller.text != _textBeforeEdit;
    if (_localErrorText != null) {
      _clearLocalErrorState();
      setState(() {});
    }
  }

  bool _valuesEqual(Object? left, Object? right) => left == right;

  String? _commitValue(T? value) {
    if (!_isEnabled || _isReadOnly) {
      return null;
    }

    final oldValue = widget.value;
    final change = _applyValueChanging(value);
    if (!change.accepted) {
      // Event cancellation is a control-flow decision, not a validation
      // failure. Do not retain the callback message as a blocking editor error
      // and do not route it through the UX dialog pipeline.
      _clearLocalEditState();
      _formatDisplayTextAfterEdit(oldValue);
      return fdcEditorCommitCanceled;
    }

    final acceptedValue = change.hasReplacement ? change.value : value;
    final blockingError =
        widget.valueValidator?.call(acceptedValue) ??
        widget.onCommit?.call(acceptedValue);

    if (blockingError != null) {
      _localErrorText = blockingError;
      _localErrorBlocksCommit = true;
      _formFieldKey.currentState?.validate();
      return blockingError;
    }

    _hasPendingCommittedValue = true;
    _pendingCommittedValue = acceptedValue;

    _localErrorText = widget.nonBlockingValueValidator?.call(acceptedValue);
    _localErrorBlocksCommit = false;
    if (_localErrorText != null) {
      _formFieldKey.currentState?.validate();
    }

    _dirty = false;
    _textBeforeEdit = _controller.text;
    _emitValueChanged(oldValue, acceptedValue);
    return null;
  }

  FdcFieldValueChangeResult<T> _applyValueChanging(T? value) {
    final listener = widget.onValueChanging;
    if (listener == null) {
      return FdcFieldValueChangeResult<T>.accept();
    }

    final fieldContext = FdcFieldValueChangingContext<T>(
      buildContext: context,
      dataSet: widget.dataSet ?? _standaloneDataSetFallback,
      host: FdcFieldEventHost.editor,
      fieldName: widget.field.fieldName,
      field: widget.fieldDef,
      rowIndex: widget.rowIndex ?? -1,
      oldValue: widget.value,
      newValue: value,
      oldRawValue: widget.value,
      newRawValue: value,
    );
    return listener(fieldContext) ?? fieldContext.accept();
  }

  void _emitValueChanged(T? oldValue, T? value) {
    final listener = widget.onValueChanged;
    final dataSet = widget.dataSet;
    if (listener == null || dataSet == null) {
      return;
    }

    listener(
      FdcFieldValueChangedContext<T>(
        buildContext: context,
        dataSet: dataSet,
        host: FdcFieldEventHost.editor,
        fieldName: widget.field.fieldName,
        field: widget.fieldDef,
        rowIndex: widget.rowIndex ?? -1,
        oldValue: oldValue,
        value: value,
        oldRawValue: oldValue,
        rawValue: value,
      ),
    );
  }

  void _emitFocusEvent(FdcFieldFocusCallback<T>? listener) {
    final dataSet = widget.dataSet;
    if (listener == null || dataSet == null) {
      return;
    }

    listener(
      FdcFieldFocusContext<T>(
        buildContext: context,
        dataSet: dataSet,
        host: FdcFieldEventHost.editor,
        fieldName: widget.field.fieldName,
        field: widget.fieldDef,
        rowIndex: widget.rowIndex ?? -1,
        value: widget.value,
        rawValue: widget.value,
        reason: _handlingFocusMove
            ? FdcFieldFocusChangeReason.focusTraversal
            : FdcFieldFocusChangeReason.programmatic,
      ),
    );
  }

  FdcDataSet get _standaloneDataSetFallback =>
      throw StateError('FdcEditorCore value events require a bound dataSet.');

  bool get _effectiveShowPicker => widget.showPicker ?? widget.field.showPicker;
}
