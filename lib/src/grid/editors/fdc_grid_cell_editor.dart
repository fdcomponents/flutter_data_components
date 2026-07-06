// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart'
    show
        PointerDeviceKind,
        PointerDownEvent,
        PointerUpEvent,
        kPrimaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/fdc_app.dart';
import '../../common/codecs/fdc_value_codec.dart';
import '../../common/format/fdc_format_settings.dart';
import '../../common/input/fdc_input_decoration.dart';
import '../../common/input/fdc_input_state.dart';
import '../../common/input/fdc_key_utils.dart';
import '../../common/input/fdc_keyboard_shortcut_internal.dart';
import '../../common/input/fdc_picker_button.dart';
import '../../common/input/fdc_value_picker.dart';
import '../../common/menu/fdc_menu_entry.dart';
import '../../common/menu/fdc_menu_renderer.dart';
import '../../common/theme/fdc_grid_styles.dart';
import '../../common/widgets/combo/fdc_combo_field.dart';
import '../../common/widgets/counter/fdc_counter_overlay.dart';
import '../../common/widgets/counter/fdc_counter_style.dart';
import '../../data/fdc_data.dart';
import '../../dialogs/fdc_message_dialog.dart';
import '../../editors/core/fdc_editor_text_session.dart';
import '../../i18n/fdc_translations.dart';
import '../columns/fdc_grid_columns.dart';
import '../core/fdc_grid_interaction_tokens.dart';
import '../format/fdc_field_value_codec.dart';
import '../models/fdc_column_identity.dart';
import '../widgets/fdc_grid_control_theme.dart';

class FdcGridCellEditor extends StatefulWidget {
  const FdcGridCellEditor({
    super.key,
    required this.column,
    required this.runtimeColumnId,
    required this.value,
    required this.enabled,
    required this.readOnly,
    required this.selectAllOnFocus,
    required this.placeCursorAtEndOnFocus,
    required this.initialText,
    required this.originalValue,
    required this.originalText,
    required this.updateInitialText,
    required this.counterMaxLength,
    required this.editorMaxLength,
    required this.decimalScale,
    required this.decimalPrecision,
    required this.dataType,
    required this.counterStyle,
    required this.textStyle,
    required this.controlsStyle,
    required this.onChanged,
    this.onLookup,
    this.lookupCommittedText,
    required this.onMoveNext,
    required this.onMovePrevious,
    required this.onMoveNextTab,
    required this.onMovePreviousTab,
    required this.onMoveDown,
    required this.onMoveUp,
    required this.onMovePageDown,
    required this.onMovePageUp,
    required this.onBeginKeyboardMoveScrollGuard,
    required this.onCancelEditing,
  });

  final FdcGridColumn<dynamic> column;
  final FdcColumnIdentity? runtimeColumnId;
  final Object? value;
  final bool enabled;
  final bool readOnly;
  final bool selectAllOnFocus;
  final bool placeCursorAtEndOnFocus;
  final String? initialText;
  final Object? originalValue;
  final String? originalText;
  final bool updateInitialText;
  final int? counterMaxLength;
  final int? editorMaxLength;
  final int? decimalScale;
  final int? decimalPrecision;
  final FdcDataType dataType;
  final FdcCounterStyle counterStyle;
  final TextStyle? textStyle;
  final FdcGridControlsStyle controlsStyle;
  final bool Function(Object? value) onChanged;
  final Future<bool> Function(String? editorText, FdcLookupMode mode)? onLookup;
  final String Function()? lookupCommittedText;
  final VoidCallback onMoveNext;
  final VoidCallback onMovePrevious;
  final VoidCallback onMoveNextTab;
  final VoidCallback onMovePreviousTab;
  final VoidCallback onMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMovePageDown;
  final VoidCallback onMovePageUp;
  final VoidCallback Function() onBeginKeyboardMoveScrollGuard;
  final ValueChanged<Object?> onCancelEditing;

  @override
  State<FdcGridCellEditor> createState() => FdcGridCellEditorState();
}

class FdcGridCellEditorState extends State<FdcGridCellEditor> {
  static const double _pickerButtonWidth = 32;

  late final String? _initialText = widget.initialText;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  FdcFormatSettings _formatSettings = const FdcFormatSettings();
  FdcTranslations _translations = const FdcTranslations();
  Object? _valueBeforeEdit;
  String _textBeforeEdit = '';
  bool _loadedDependencies = false;
  bool _handlingMove = false;
  final GlobalKey<FdcComboFieldState<Object?>> _dropdownKey =
      GlobalKey<FdcComboFieldState<Object?>>();
  bool _replaceAllOnNextTextKey = false;
  int _controllerSyncVersion = 0;
  int? _lastCounterTextLength;
  DateTime? _lastTextEditorPointerUpTime;
  Offset? _lastTextEditorPointerUpPosition;
  bool _textEditorPointerDownWasPrimaryMouse = false;
  bool _showingCommitErrorDialog = false;
  bool _lookupResolveInProgress = false;
  bool _suppressNextImplicitLookupResolve = false;

  static const Duration _textEditorDoubleClickInterval = Duration(
    milliseconds: 500,
  );
  static const double _textEditorDoubleClickDistance = 8;

  bool get _isEnabled => widget.enabled && !widget.column.isEffectivelyReadOnly;

  bool get _isReadOnly =>
      widget.readOnly || widget.column.isEffectivelyReadOnly;

  FdcInputState get _inputState =>
      FdcInputState(enabled: _isEnabled, readOnly: _isReadOnly);

  bool get _canEdit => _inputState.canEdit;

  bool get _effectiveShowPicker => widget.column.showPicker;

  @override
  void initState() {
    super.initState();
    final text = widget.initialText ?? '';
    _valueBeforeEdit = widget.originalValue;
    _textBeforeEdit = widget.originalText ?? text;
    _controller = TextEditingController.fromValue(
      FdcEditorTextSession.collapsedValue(text),
    );
    _replaceAllOnNextTextKey = widget.selectAllOnFocus;
    _controller.addListener(_handleControllerSelectionChange);
    _controller.addListener(_handleControllerTextChange);
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent)
      ..addListener(_handleFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = FdcApp.formatsOf(context);
    final translations = FdcApp.translationsOf(context);
    if (!_loadedDependencies ||
        settings != _formatSettings ||
        translations != _translations) {
      final loadedBefore = _loadedDependencies;
      _loadedDependencies = true;
      _formatSettings = settings;
      _translations = translations;
      _syncControllerFromWidget(
        defer: loadedBefore,
        updateEditBaseline: !_focusNode.hasFocus,
      );
    }
  }

  @override
  void didUpdateWidget(covariant FdcGridCellEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.updateInitialText &&
        oldWidget.initialText != widget.initialText) {
      _resetLookupResolveState();
      _scheduleControllerText(widget.initialText ?? '');
      return;
    }
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _resetLookupResolveState();
      _valueBeforeEdit = widget.originalValue;
      _syncControllerFromWidget(defer: true, updateEditBaseline: true);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.removeListener(_handleControllerTextChange);
    _controller.removeListener(_handleControllerSelectionChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = switch (widget.column.effectiveEditor) {
      FdcEditorType.combo => _buildDropdown(),
      FdcEditorType.date ||
      FdcEditorType.dateTime ||
      FdcEditorType.time => _buildDateTextField(context),
      FdcEditorType.memo => _buildTextField(
        keyboardType: TextInputType.multiline,
        inputFormatters: _inputFormatters(),
        maxLines: 4,
      ),
      _ => _buildTextField(
        keyboardType: _codec.keyboardTypeForGridColumn(widget.column),
        inputFormatters: _inputFormatters(),
      ),
    };

    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.f2): focusAndMoveCursorToEnd,
    };
    final lookupShortcut = widget.column.lookupShortcut;
    if (widget.onLookup != null && lookupShortcut != null) {
      shortcuts[fdcKeyboardShortcutActivator(lookupShortcut)] = _invokeLookup;
    }

    return CallbackShortcuts(bindings: shortcuts, child: editor);
  }

  bool _suppressNextResolveLookup = false;
  bool _externalLookupSearchInProgress = false;

  Future<void> _invokeLookup() async {
    final callback = widget.onLookup;
    if (callback == null || !_canEdit || _lookupResolveInProgress) {
      return;
    }
    beginExternalLookupSearch();
    final accepted = await callback(
      _editorTextForLookup(),
      FdcLookupMode.search,
    );
    if (!mounted) {
      return;
    }
    endExternalLookupSearch(
      accepted: accepted,
      acceptedText: accepted ? widget.lookupCommittedText?.call() : null,
    );
  }

  /// Prepares an editor-owned lookup button/search interaction that is
  /// initiated outside the text field focus node.
  ///
  /// Pointer down on the lookup button can move focus before the button's
  /// `onPressed` callback invokes search lookup. Without this guard, that
  /// intermediate focus loss can incorrectly finalize the typed search text as
  /// a resolve lookup. Treat the current text as clean and suppress the next
  /// resolve until the search callback reports whether it accepted a value.
  void beginExternalLookupSearch() {
    if (!_canEdit || _lookupResolveInProgress) {
      return;
    }
    _resetLookupResolveState();
    _externalLookupSearchInProgress = true;
    _suppressNextResolveLookup = true;
    _suppressNextImplicitLookupResolve = false;
  }

  void endExternalLookupSearch({required bool accepted, String? acceptedText}) {
    if (!mounted) {
      return;
    }
    _externalLookupSearchInProgress = false;
    if (accepted) {
      // Search lookup already applied its values through the grid runtime. If
      // it did not change the edited primary field, no parent rebuild may be
      // scheduled for this active editor. In that case, replace the transient
      // search query text with the current committed primary display text so
      // the editor cannot keep the lookup query as its clean baseline.
      if (acceptedText != null) {
        _setControllerText(acceptedText);
        _textBeforeEdit = acceptedText;
      } else {
        _textBeforeEdit = _controller.text;
      }
      _suppressNextResolveLookup = true;
      _suppressNextImplicitLookupResolve = false;
    } else {
      _resetLookupResolveState();
      requestTextFocus();
    }
  }

  String? get lookupEditorText => _editorTextForLookup();

  String? _editorTextForLookup() {
    return switch (widget.column.effectiveEditor) {
      FdcEditorType.checkbox ||
      FdcEditorType.switcher ||
      FdcEditorType.custom ||
      FdcEditorType.action => null,
      _ => _controller.text,
    };
  }

  TextStyle _editorTextStyle(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final resolvedStyle = widget.textStyle == null
        ? defaultStyle
        : defaultStyle.merge(widget.textStyle);
    return resolvedStyle.copyWith(
      inherit: false,
      fontSize:
          resolvedStyle.fontSize ??
          Theme.of(context).textTheme.bodyMedium?.fontSize ??
          14.0,
      textBaseline: resolvedStyle.textBaseline ?? TextBaseline.alphabetic,
    );
  }

  StrutStyle _editorStrutStyle(BuildContext context) {
    return StrutStyle.fromTextStyle(
      _editorTextStyle(context),
      forceStrutHeight: true,
    );
  }

  Widget _buildTextField({
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    final textField = maxLines == 1
        ? _buildSingleLineTextField(
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
          )
        : _withoutEditorScrollbars(
            _wrapForDoubleClickSelectAll(
              TextFormField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                enabled: _isEnabled,
                readOnly: _isReadOnly,
                scrollPadding: EdgeInsets.zero,
                maxLines: maxLines,
                buildCounter: _hideCounter,
                decoration: _decoration(),
                keyboardType: keyboardType,
                textAlign: _textAlign(),
                groupId: fdcGridTapRegionGroup,
                style: _editorTextStyle(context),
                strutStyle: _editorStrutStyle(context),
                textInputAction: TextInputAction.next,
                inputFormatters: inputFormatters,
                enableInteractiveSelection: true,
                contextMenuBuilder: _buildTextContextMenu,
                onChanged: _handleTextChanged,
                onEditingComplete: () {},
                onFieldSubmitted: (_) => _moveNext(),
              ),
            ),
          );

    if (widget.counterMaxLength == null) {
      return textField;
    }

    return FdcCounterOverlay(
      visible: true,
      textListenable: _controller,
      maxLength: widget.counterMaxLength,
      style: widget.counterStyle,
      fit: StackFit.expand,
      counterPadding: EdgeInsets.zero,
      child: textField,
    );
  }

  Widget _buildSingleLineTextField({
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final style = _editorTextStyle(context);
    final hintText = widget.column.hint;
    final readOnly = _isReadOnly || !_isEnabled;

    final textField = TextField(
      controller: _controller,
      focusNode: _focusNode,
      autofocus: true,
      enabled: _isEnabled,
      readOnly: readOnly,
      scrollPadding: EdgeInsets.zero,
      keyboardType: keyboardType,
      textAlign: _textAlign(),
      groupId: fdcGridTapRegionGroup,
      style: style,
      strutStyle: StrutStyle.fromTextStyle(style, forceStrutHeight: true),
      cursorColor: Theme.of(context).colorScheme.primary,
      textInputAction: TextInputAction.next,
      inputFormatters: inputFormatters,
      decoration: null,
      showCursor: _canEdit,
      enableInteractiveSelection: true,
      contextMenuBuilder: _buildTextContextMenu,
      mouseCursor: _canEdit ? SystemMouseCursors.text : MouseCursor.defer,
      onChanged: _handleTextChanged,
      onEditingComplete: () {},
      onSubmitted: (_) => _moveNext(),
    );
    final editable = _withoutEditorScrollbars(
      _wrapForDoubleClickSelectAll(textField),
    );

    return SizedBox.expand(
      child: Align(
        alignment: _editableAlignment(),
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: _editableAlignment(),
            children: [
              if (hintText != null)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    if (value.text.isNotEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IgnorePointer(
                      child: Text(
                        hintText,
                        overflow: TextOverflow.ellipsis,
                        textAlign: _textAlign(),
                        style: style.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    );
                  },
                ),
              editable,
            ],
          ),
        ),
      ),
    );
  }

  Widget _wrapForDoubleClickSelectAll(Widget child) {
    return Listener(
      onPointerDown: _handleTextEditorPointerDown,
      onPointerUp: _handleTextEditorPointerUp,
      child: child,
    );
  }

  Widget _withoutEditorScrollbars(Widget child) {
    final behavior = ScrollConfiguration.of(context);
    return ScrollConfiguration(
      behavior: behavior.copyWith(scrollbars: false),
      child: child,
    );
  }

  Widget _buildTextContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final entries = _textMenuEntries(context, editableTextState);
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    // The grid itself is a TapRegion. Text-selection menus are rendered in an
    // overlay outside the grid subtree; the shared group keeps the in-place
    // editor alive while an FDC menu action is activated. Flutter still owns
    // the edit command callbacks, selection rules, and clipboard behavior.
    final anchors = editableTextState.contextMenuAnchors;
    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: anchors.primaryAnchor,
        anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      ),
      child: ExcludeFocus(
        child: TapRegion(
          groupId: fdcGridTapRegionGroup,
          child: FdcMenuPanel(entries: entries),
        ),
      ),
    );
  }

  List<FdcMenuEntry> _textMenuEntries(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final localizations = MaterialLocalizations.of(context);
    final entries = <FdcMenuEntry>[];

    for (final item in editableTextState.contextMenuButtonItems) {
      final presentation = _textMenuPresentation(item.type, localizations);
      if (presentation == null) {
        continue;
      }
      entries.add(
        FdcMenuAction(
          text: presentation.text,
          icon: presentation.icon,
          shortcutText: presentation.shortcutText,
          enabled: item.onPressed != null,
          onPressed: item.onPressed,
        ),
      );
    }

    return entries;
  }

  _FdcTextMenuPresentation? _textMenuPresentation(
    ContextMenuButtonType type,
    MaterialLocalizations localizations,
  ) {
    if (type == ContextMenuButtonType.cut) {
      return _FdcTextMenuPresentation(
        text: localizations.cutButtonLabel,
        icon: Icons.content_cut,
        shortcutText: _textMenuShortcut('X'),
      );
    }
    if (type == ContextMenuButtonType.copy) {
      return _FdcTextMenuPresentation(
        text: localizations.copyButtonLabel,
        icon: Icons.content_copy,
        shortcutText: _textMenuShortcut('C'),
      );
    }
    if (type == ContextMenuButtonType.paste) {
      return _FdcTextMenuPresentation(
        text: localizations.pasteButtonLabel,
        icon: Icons.content_paste,
        shortcutText: _textMenuShortcut('V'),
      );
    }
    if (type == ContextMenuButtonType.selectAll) {
      return _FdcTextMenuPresentation(
        text: localizations.selectAllButtonLabel,
        icon: Icons.select_all,
        shortcutText: _textMenuShortcut('A'),
      );
    }
    return null;
  }

  String _textMenuShortcut(String key) {
    return defaultTargetPlatform == TargetPlatform.macOS
        ? '⌘$key'
        : 'Ctrl+$key';
  }

  void _handleTextEditorPointerDown(PointerDownEvent event) {
    _textEditorPointerDownWasPrimaryMouse =
        event.kind == PointerDeviceKind.mouse &&
        event.buttons == kPrimaryMouseButton;
  }

  void _handleTextEditorPointerUp(PointerUpEvent event) {
    if (!_textEditorPointerDownWasPrimaryMouse || !_canEdit) {
      _resetTextEditorDoubleClickTracking();
      return;
    }

    final now = DateTime.now();
    final lastTime = _lastTextEditorPointerUpTime;
    final lastPosition = _lastTextEditorPointerUpPosition;
    final isDoubleClick =
        lastTime != null &&
        now.difference(lastTime) <= _textEditorDoubleClickInterval &&
        lastPosition != null &&
        (event.position - lastPosition).distance <=
            _textEditorDoubleClickDistance;

    _textEditorPointerDownWasPrimaryMouse = false;
    _lastTextEditorPointerUpTime = now;
    _lastTextEditorPointerUpPosition = event.position;

    if (isDoubleClick) {
      _resetTextEditorDoubleClickTracking();
      _selectAllAfterPointerSettles();
    }
  }

  void _resetTextEditorDoubleClickTracking() {
    _textEditorPointerDownWasPrimaryMouse = false;
    _lastTextEditorPointerUpTime = null;
    _lastTextEditorPointerUpPosition = null;
  }

  void _selectAllAfterPointerSettles() {
    Future<void>.delayed(Duration.zero, () {
      if (!mounted || !_canEdit) {
        return;
      }
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  Alignment _editableAlignment() {
    return _isNumericEditor ? Alignment.centerRight : Alignment.centerLeft;
  }

  Widget _buildDateTextField(BuildContext context) {
    final picker = _pickerButton(context);
    final textField = _buildTextField(
      keyboardType: TextInputType.datetime,
      inputFormatters: _inputFormatters(),
    );
    if (picker == null) {
      return textField;
    }

    return SizedBox.expand(
      child: Row(
        children: [
          Expanded(child: textField),
          SizedBox(
            width: _pickerButtonWidth,
            child: Center(child: picker),
          ),
        ],
      ),
    );
  }

  TextAlign _textAlign() {
    return _isNumericEditor ? TextAlign.right : TextAlign.left;
  }

  bool get _isNumericEditor {
    return widget.dataType == FdcDataType.integer ||
        widget.dataType == FdcDataType.decimal;
  }

  Widget _buildDropdown() {
    return FdcComboField<Object?>(
      key: _dropdownKey,
      options: [
        for (final option in widget.column.options)
          FdcOption<Object?>(value: option.value, label: option.label),
      ],
      value: widget.value,
      onChanged: widget.onChanged,
      focusNode: _focusNode,
      decoration: _decoration(),
      style: _editorTextStyle(context),
      hintText: widget.column.hint,
      enabled: _isEnabled,
      readOnly: _isReadOnly,
      autofocus: true,
      showSelectedOptionCheckmark: widget.column.showSelectedOptionCheckmark,
      search: widget.column.comboSearch,
      searchHintText: widget.column.comboSearchHintText,
      maxPopupItems: widget.column.comboMaxPopupItems,
      iconColor: FdcGridControlTheme.iconColor(
        context,
        widget.controlsStyle,
        enabled: _canEdit && _isEnabled,
      ),
      tapRegionGroupId: fdcGridTapRegionGroup,
      openOnEnter: false,
      requestFocusOnSelection: false,
      onKeyEvent: (_, event) => _handleDropdownKeyEvent(event),
    );
  }

  InputDecoration _decoration() {
    // Grid in-place editors intentionally do not render inline validation
    // messages. A grid cell has no natural vertical space for Flutter
    // errorText without causing row-height jumps and poor keyboard UX.
    // Field-level semantic validation is emitted through the dataset and
    // modal presentation is reserved for grid-owned post() operations.
    return FdcInputDecoration.gridCell(hintText: widget.column.hint);
  }

  Widget? _hideCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    return null;
  }

  Widget? _pickerButton(BuildContext context) {
    if (!_effectiveShowPicker || !_canEdit) {
      return null;
    }

    return FdcPickerButton(
      onPressed: () => _pickValue(context),
      compact: true,
      iconColor: FdcGridControlTheme.iconColor(
        context,
        widget.controlsStyle,
        enabled: _canEdit && _isEnabled,
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!FdcKeyUtils.isKeyDownOrRepeat(event)) {
      return KeyEventResult.ignored;
    }

    if (_isDropdownEditor) {
      return _handleDropdownKeyEvent(event);
    }

    if (FdcKeyUtils.isF2(event)) {
      moveCursorToEnd();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isEnter(event)) {
      _moveNext();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isTab(event) && !FdcKeyUtils.isShiftPressed) {
      _moveNextTab();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isTab(event) && FdcKeyUtils.isShiftPressed) {
      _movePreviousTab();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isArrowDown(event)) {
      if (FdcKeyUtils.isShiftPressed) {
        return KeyEventResult.ignored;
      }
      _move(widget.onMoveDown);
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isArrowUp(event)) {
      if (FdcKeyUtils.isShiftPressed) {
        return KeyEventResult.ignored;
      }
      _move(widget.onMoveUp);
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isPageDown(event)) {
      _move(widget.onMovePageDown);
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isPageUp(event)) {
      _move(widget.onMovePageUp);
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isEscape(event)) {
      final oldValue = cancelEditing();
      widget.onCancelEditing(oldValue);
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isBackspaceOrDelete(event)) {
      if (_clearSelectedTextValue()) {
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleDropdownKeyEvent(KeyEvent event) {
    if (FdcKeyUtils.isSpace(event)) {
      activateDropdown();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isEnter(event)) {
      _moveNext();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isTab(event) && FdcKeyUtils.isShiftPressed) {
      _movePreviousTab();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isTab(event)) {
      _moveNextTab();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isEscape(event)) {
      final oldValue = cancelEditing();
      widget.onCancelEditing(oldValue);
      return KeyEventResult.handled;
    }

    if (_isTextKeyEvent(event)) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void moveCursorToEnd() {
    _replaceAllOnNextTextKey = false;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  void focusAndMoveCursorToEnd() {
    _focusTextEditor(shouldMoveCursorToEnd: true);
  }

  void activateDropdown() {
    if (!_isDropdownEditor) {
      return;
    }
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusNode.requestFocus();
      unawaited(_dropdownKey.currentState?.openDropdownMenu());
    });
  }

  void requestTextFocus() {
    _focusTextEditor();
  }

  void _focusTextEditor({bool shouldMoveCursorToEnd = false}) {
    _focusNode.requestFocus();
    if (shouldMoveCursorToEnd) {
      moveCursorToEnd();
    }
    _requestTextFieldFocusAfterLayout(
      shouldMoveCursorToEnd: shouldMoveCursorToEnd,
    );
  }

  void _requestTextFieldFocusAfterLayout({bool shouldMoveCursorToEnd = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
      if (shouldMoveCursorToEnd) {
        moveCursorToEnd();
      }
    });
  }

  bool _clearSelectedTextValue() {
    if (!_selectsWholeText) {
      _replaceAllOnNextTextKey = false;
      return false;
    }

    _replaceAllOnNextTextKey = false;
    _setControllerText('');
    return true;
  }

  bool get _isDropdownEditor {
    return widget.column.effectiveEditor == FdcEditorType.combo;
  }

  bool get _selectsWholeText {
    final selection = _controller.selection;
    return selection.isValid &&
        !selection.isCollapsed &&
        selection.start == 0 &&
        selection.end == _controller.text.length;
  }

  bool _isTextKeyEvent(KeyEvent event) {
    if (!FdcKeyUtils.isKeyDown(event)) {
      return false;
    }
    final text = event.character;
    return text != null && text.isNotEmpty && !_isControlCharacter(text);
  }

  bool _isControlCharacter(String text) {
    return text.runes.any((rune) => rune < 0x20 || rune == 0x7F);
  }

  void _moveCursorToEndAfterSettle() {
    _replaceAllOnNextTextKey = false;
    moveCursorToEnd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      moveCursorToEnd();
      unawaited(
        Future<void>.microtask(() {
          if (mounted) {
            moveCursorToEnd();
          }
        }),
      );
    });
  }

  Object? cancelEditing() {
    _replaceAllOnNextTextKey = false;
    _resetLookupResolveState();
    final oldValue = _valueBeforeEdit;
    _setControllerText(_textBeforeEdit);
    _controller.selection = TextSelection.collapsed(
      offset: _textBeforeEdit.length,
    );
    return oldValue;
  }

  bool finalizeEditing() {
    return _finalizeEditing();
  }

  void _handleTextChanged(String text) {
    final endScrollGuard = widget.onBeginKeyboardMoveScrollGuard();
    try {
      _replaceAllOnNextTextKey = false;
      _suppressNextImplicitLookupResolve = false;
      _controllerSyncVersion++;
    } finally {
      endScrollGuard();
    }
  }

  void _moveNext() {
    _move(widget.onMoveNext);
  }

  void _moveNextTab() {
    _move(widget.onMoveNextTab);
  }

  void _movePreviousTab() {
    _move(widget.onMovePreviousTab);
  }

  void _move(VoidCallback callback) {
    if (_handlingMove) {
      return;
    }

    final endScrollGuard = widget.onBeginKeyboardMoveScrollGuard();
    void moveAfterAccepted() {
      if (!mounted || _handlingMove) {
        return;
      }
      _handlingMove = true;
      callback();
      unawaited(
        Future<void>.microtask(() {
          if (mounted) {
            _handlingMove = false;
          }
        }),
      );
    }

    try {
      if (!_finalizeEditing(onAccepted: moveAfterAccepted)) {
        if (!_lookupResolveInProgress) {
          requestTextFocus();
        }
        return;
      }
      moveAfterAccepted();
    } finally {
      endScrollGuard();
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      if (widget.placeCursorAtEndOnFocus) {
        _replaceAllOnNextTextKey = false;
        _moveCursorToEndAfterSettle();
      } else if (widget.selectAllOnFocus) {
        _replaceAllOnNextTextKey = true;
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
        _requestTextFieldFocusAfterLayout();
      } else {
        _requestTextFieldFocusAfterLayout();
      }
      return;
    }
    if (_lookupResolveInProgress) {
      return;
    }
    final allowLookupResolve = !_suppressNextImplicitLookupResolve;
    if (!allowLookupResolve) {
      _suppressNextImplicitLookupResolve = false;
    }
    if (!_finalizeEditing(allowLookupResolve: allowLookupResolve)) {
      if (_lookupResolveInProgress) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          requestTextFocus();
        }
      });
    }
  }

  void _handleControllerTextChange() {
    if (widget.counterMaxLength == null || !mounted) {
      return;
    }

    final length = _controller.text.length;
    if (_lastCounterTextLength == length) {
      return;
    }

    _lastCounterTextLength = length;
    setState(() {});
  }

  void _handleControllerSelectionChange() {
    if (!_replaceAllOnNextTextKey) {
      return;
    }

    if (!_selectsWholeText) {
      _replaceAllOnNextTextKey = false;
    }
  }

  bool _finalizeEditing({
    VoidCallback? onAccepted,
    bool allowLookupResolve = true,
  }) {
    final editor = widget.column.effectiveEditor;
    if (editor == FdcEditorType.combo || !_hasUncommittedTextEdit) {
      return true;
    }

    final parseResult = _parseTextForCommit(_controller.text);
    final errorText = parseResult.errorText;
    if (errorText != null) {
      unawaited(_showCommitError(errorText));
      return false;
    }

    final value = parseResult.value;
    final controllerText =
        parseResult.normalizedText ?? _formatValue(value, forEditing: true);

    return _commitEditedValue(
      value,
      controllerText: controllerText,
      onAccepted: onAccepted,
      allowLookupResolve: allowLookupResolve,
    );
  }

  void _resetLookupResolveState() {
    _lookupResolveInProgress = false;
    _suppressNextResolveLookup = false;
    _suppressNextImplicitLookupResolve = false;
    _externalLookupSearchInProgress = false;
  }

  void _suppressImplicitLookupResolveUntilFocusSettles() {
    _suppressNextImplicitLookupResolve = true;
  }

  void _clearImplicitLookupResolveSuppressionAfterFocusSettles() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _suppressNextImplicitLookupResolve = false;
        }
      });
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _showCommitError(String message) {
    if (!mounted || _showingCommitErrorDialog) {
      return Future<void>.value();
    }

    final completer = Completer<void>();
    _showingCommitErrorDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _showingCommitErrorDialog = false;
        if (!completer.isCompleted) {
          completer.complete();
        }
        return;
      }

      unawaited(
        showFdcMessageDialog(
              context,
              title: FdcApp.translationsOf(context).validation.validationError,
              message: message,
            )
            .catchError((_) {
              // Dialog presentation must not turn an editor parse failure into an
              // unhandled async exception.
            })
            .whenComplete(() {
              _showingCommitErrorDialog = false;
              if (mounted) {
                requestTextFocus();
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

  bool get _hasUncommittedTextEdit => FdcEditorTextSession.hasLocalEditToRevert(
    dirty: false,
    localErrorText: null,
    controllerText: _controller.text,
    baselineText: _textBeforeEdit,
  );

  bool _commitEditedValue(
    Object? value, {
    String? controllerText,
    VoidCallback? onAccepted,
    bool allowLookupResolve = true,
  }) {
    if (controllerText != null && controllerText != _controller.text) {
      _setControllerText(controllerText);
    }
    final committedText = controllerText ?? _controller.text;
    final lookup = widget.onLookup;
    if (lookup != null && !allowLookupResolve) {
      return false;
    }
    if (lookup != null && !_suppressNextResolveLookup) {
      if (_lookupResolveInProgress) {
        return false;
      }
      unawaited(
        _resolveLookupBeforeLeavingEditor(
          lookup,
          committedText: committedText,
          parsedValue: value,
          onAccepted: onAccepted,
        ),
      );
      return false;
    }
    if (_suppressNextResolveLookup) {
      if (_externalLookupSearchInProgress) {
        return false;
      }
      _resetLookupResolveState();
      return false;
    }

    final accepted = widget.onChanged(value);
    if (!accepted) {
      return false;
    }

    _valueBeforeEdit = value;
    _textBeforeEdit = committedText;
    return true;
  }

  Future<void> _resolveLookupBeforeLeavingEditor(
    Future<bool> Function(String? editorText, FdcLookupMode mode) lookup, {
    required String committedText,
    required Object? parsedValue,
    VoidCallback? onAccepted,
  }) async {
    if (_lookupResolveInProgress) {
      return;
    }

    _lookupResolveInProgress = true;
    var accepted = false;
    try {
      accepted = await lookup(committedText, FdcLookupMode.resolve);
      if (!mounted) {
        return;
      }
      if (!accepted) {
        _suppressImplicitLookupResolveUntilFocusSettles();
        requestTextFocus();
        _clearImplicitLookupResolveSuppressionAfterFocusSettles();
        return;
      }

      _suppressNextImplicitLookupResolve = false;
      _valueBeforeEdit = parsedValue;
      _textBeforeEdit = committedText;
      onAccepted?.call();
    } on Object catch (error) {
      if (mounted) {
        _suppressImplicitLookupResolveUntilFocusSettles();
        await _showCommitError(error.toString());
        requestTextFocus();
        _clearImplicitLookupResolveSuppressionAfterFocusSettles();
      }
    } finally {
      if (mounted) {
        _lookupResolveInProgress = false;
      }
    }
  }

  void _syncControllerFromWidget({
    bool defer = false,
    bool updateEditBaseline = false,
  }) {
    final text = widget.updateInitialText
        ? widget.initialText ?? ''
        : _initialText ?? _formatValue(widget.value, forEditing: true);
    if (updateEditBaseline) {
      _valueBeforeEdit = widget.originalValue;
      _textBeforeEdit =
          widget.originalText ??
          _formatValue(widget.originalValue, forEditing: true);
    }
    if (defer) {
      _scheduleControllerText(text);
    } else {
      _setControllerText(text);
    }
  }

  void _scheduleControllerText(String text) {
    final version = ++_controllerSyncVersion;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || version != _controllerSyncVersion) {
        return;
      }
      _setControllerTextNow(text);
    });
  }

  void _setControllerText(String text) {
    _controllerSyncVersion++;
    _setControllerTextNow(text);
  }

  void _setControllerTextNow(String text) {
    if (_controller.text == text) {
      return;
    }
    _controller.value = FdcEditorTextSession.collapsedValue(text);
  }

  FdcFieldValueCodec get _codec => FdcFieldValueCodec(
    settings: _formatSettings,
    translations: _translations,
  );

  FdcValueParseResult<Object?> _parseTextForCommit(String text) {
    return _codec.parseGridTextForCommit(
      widget.column,
      text,
      runtimeColumnId: widget.runtimeColumnId,
      decimalScale: widget.decimalScale,
      decimalPrecision: widget.decimalPrecision,
    );
  }

  String _formatValue(Object? value, {bool forEditing = false}) {
    return _codec.formatGridValue(
      widget.column,
      value,
      runtimeColumnId: widget.runtimeColumnId,
      forEditing: forEditing,
      decimalScale: widget.decimalScale,
    );
  }

  List<TextInputFormatter>? _inputFormatters() {
    final formatters = <TextInputFormatter>[
      ...?_codec.inputFormattersForGridColumn(
        widget.column,
        runtimeColumnId: widget.runtimeColumnId,
        decimalScale: widget.decimalScale,
        decimalPrecision: widget.decimalPrecision,
      ),
    ];

    final maxLength = widget.editorMaxLength;
    if (maxLength != null) {
      formatters.add(LengthLimitingTextInputFormatter(maxLength));
    }

    return formatters.isEmpty ? null : formatters;
  }

  Future<void> _pickValue(BuildContext context) async {
    final pickedValue = await FdcValuePicker.pick(
      context: context,
      kind: _pickerKindForEditor(widget.column.effectiveEditor),
      currentValue: widget.value,
    );
    if (!mounted || pickedValue == null) {
      return;
    }
    _acceptPickedValue(pickedValue);
  }

  FdcValueCodecKind _pickerKindForEditor(FdcEditorType editor) {
    return switch (editor) {
      FdcEditorType.time => FdcValueCodecKind.time,
      FdcEditorType.dateTime => FdcValueCodecKind.dateTime,
      _ => FdcValueCodecKind.date,
    };
  }

  void _acceptPickedValue(Object value) {
    _setControllerText(_formatValue(value, forEditing: true));
    widget.onChanged(value);
    _focusNode.requestFocus();
  }
}

class _FdcTextMenuPresentation {
  const _FdcTextMenuPresentation({
    required this.text,
    required this.icon,
    required this.shortcutText,
  });

  final String text;
  final IconData icon;
  final String shortcutText;
}
