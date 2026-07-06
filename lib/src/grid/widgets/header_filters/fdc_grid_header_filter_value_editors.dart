// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../app/fdc_app.dart';
import '../../../common/codecs/fdc_value_codec.dart';
import '../../../common/input/fdc_input_decoration.dart';
import '../../../common/input/fdc_picker_button.dart';
import '../../../common/input/fdc_value_picker.dart';
import '../../../common/menu/fdc_menu.dart';
import '../../../common/theme/fdc_grid_theme.dart';
import '../../../common/widgets/combo/fdc_combo_field.dart';
import '../../../data/fdc_data.dart';
import '../../../i18n/fdc_translations.dart';
import '../../columns/fdc_grid_columns.dart';
import '../../controllers/fdc_text_input_autorepeat_guard.dart';
import '../../core/fdc_grid_core.dart';
import '../../core/fdc_grid_interaction_tokens.dart';
import '../../filtering/fdc_header_filter_input_behavior.dart';
import '../../format/fdc_field_value_codec.dart';
import '../../models/fdc_grid_internal_models.dart';
import '../fdc_grid_control_theme.dart';
import '../fdc_grid_header_metrics.dart';
import 'fdc_grid_header_filter_menu_builder.dart';
import 'fdc_grid_header_filter_shell.dart';

const Size _headerFilterPopupActionMinimumSize = Size(76, 36);
const EdgeInsets _headerFilterPopupCancelPadding = EdgeInsets.symmetric(
  horizontal: 14,
  vertical: 10,
);
const EdgeInsets _headerFilterPopupApplyPadding = EdgeInsets.symmetric(
  horizontal: 18,
  vertical: 10,
);
const BorderRadius _headerFilterPopupActionRadius = BorderRadius.all(
  Radius.circular(4),
);
const Color _headerFilterRangeInputFillColor = Colors.white;
const Color _headerFilterRangeInputBorderColor = Color(0xFF64748B);

const double _headerFilterPickerButtonWidth = 24;
const double _minimumWidthForPicker = 72;
const double _headerFilterMinimumReadableTextWidth = 18;

double _headerFilterCompactHorizontalPadding(double width) {
  if (width < 16) {
    return 0;
  }
  if (width < 28) {
    return 2;
  }
  if (width < 40) {
    return 4;
  }
  return FdcGridHeaderMetrics.filterFieldHorizontalPadding;
}

class _FdcHeaderFilterOverflowText extends StatelessWidget {
  const _FdcHeaderFilterOverflowText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final trimmedText = text.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : double.infinity;
        final direction = Directionality.of(context);
        final fullTextPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: direction,
        )..layout();
        final overflows =
            maxWidth.isFinite &&
            trimmedText.isNotEmpty &&
            fullTextPainter.width > maxWidth;

        final Widget child;
        if (overflows && maxWidth < _headerFilterMinimumReadableTextWidth) {
          child = Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '…',
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
                semanticsLabel: trimmedText.isEmpty ? null : text,
                style: style,
              ),
            ),
          );
        } else {
          child = Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            semanticsLabel: trimmedText.isEmpty ? null : text,
            style: style,
          );
        }

        final hitTarget = SizedBox(
          width: maxWidth.isFinite ? maxWidth : double.infinity,
          child: child,
        );

        return hitTarget;
      },
    );
  }
}

ButtonStyle _headerFilterPopupCancelButtonStyle() => TextButton.styleFrom(
  minimumSize: _headerFilterPopupActionMinimumSize,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  padding: _headerFilterPopupCancelPadding,
  shape: const RoundedRectangleBorder(
    borderRadius: _headerFilterPopupActionRadius,
  ),
);

ButtonStyle _headerFilterPopupApplyButtonStyle() => FilledButton.styleFrom(
  minimumSize: _headerFilterPopupActionMinimumSize,
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  padding: _headerFilterPopupApplyPadding,
  shape: const RoundedRectangleBorder(
    borderRadius: _headerFilterPopupActionRadius,
  ),
);

class FdcGridHeaderTextFilterEditor extends StatelessWidget {
  const FdcGridHeaderTextFilterEditor({
    super.key,
    required this.model,
    required this.callbacks,
    required this.column,
    required this.runtimeColumnId,
    required this.fillColor,
    required this.style,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final FdcGridColumn<dynamic> column;
  final FdcColumnIdentity runtimeColumnId;
  final Color fillColor;
  final FdcGridHeaderFilterStyle style;

  @override
  Widget build(BuildContext context) {
    final focusNode = callbacks.headerFilterFocusNodeOf(
      column,
      runtimeColumnId,
    );
    final operator = callbacks.headerFilterOperatorOf(column, runtimeColumnId);
    final operatorLabel = callbacks.filterOperatorLabel(operator);
    final dataType = callbacks.dataTypeOf(column);
    final isBooleanFilter = dataType == FdcDataType.boolean;
    final inputBehavior = FdcHeaderFilterInputBehavior.resolve(
      column: column,
      dataType: dataType,
      operator: operator,
      canOpenFilterMenu: callbacks.canOpenFilterMenu(),
    );
    final operatorIgnoresValue = inputBehavior.operatorDisplayOnly;
    final hasFilterState = _hasFilterState;
    final rawValue = model.headerFilterValues[runtimeColumnId];
    final hasFilterValue =
        rawValue != null && (rawValue is! String || rawValue.trim().isNotEmpty);
    final showClearButton = isBooleanFilter || !inputBehavior.acceptsValueInput
        ? hasFilterState
        : hasFilterValue;
    final canEditFilter = inputBehavior.acceptsTextInput;
    final translations = FdcApp.translationsOf(context);
    final booleanDisplayValue = isBooleanFilter
        ? (!hasFilterState ? translations.common.all : operatorLabel)
        : null;
    final displayValue =
        booleanDisplayValue ??
        (operatorIgnoresValue
            ? operatorLabel
            : _headerFilterTextForFocusState(
                context,
                rawValue,
                focused: focusNode.hasFocus,
              ));

    final textStyle = callbacks.headerFilterTextStyleOf(context);
    Widget editor = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) {
        if (canEditFilter && !focusNode.hasFocus) {
          callbacks.onFocusHeaderFilterField(column, runtimeColumnId);
        }
      },
      child: IgnorePointer(
        ignoring: !canEditFilter,
        child: KeyedSubtree(
          key: ValueKey(
            'fdc-filter-reset-$runtimeColumnId-${model.headerFilterResetGeneration}',
          ),
          child: FdcGridHeaderTextFilterInput(
            key: ValueKey('fdc-filter-$runtimeColumnId'),
            value: displayValue,
            focusNode: focusNode,
            style: textStyle,
            enabled: canEditFilter,
            keyboardType: operatorIgnoresValue
                ? null
                : _headerFilterKeyboardType(),
            inputFormatters: operatorIgnoresValue
                ? null
                : _headerFilterInputFormatters(context),
            onPickValue: _showsHeaderFilterPicker
                ? (pickerContext, currentText) =>
                      _pickHeaderFilterValue(pickerContext, currentText)
                : null,
            reserveClearButtonSpace: showClearButton,
            collapsedDisplayText: booleanDisplayValue,
            debouncePolicy: model.filterOptions.debouncePolicy,
            onDeferredChanged: callbacks.onCancelHeaderFilterDebounce,
            onChanged: (value) => callbacks.onSetHeaderFilterTextValue(
              column,
              runtimeColumnId,
              value,
              submitted: false,
            ),
            onSubmitted: (value) => callbacks.onSetHeaderFilterTextValue(
              column,
              runtimeColumnId,
              value,
              submitted: true,
            ),
          ),
        ),
      ),
    );

    if (isBooleanFilter &&
        operatorIgnoresValue &&
        callbacks.canOpenFilterMenu()) {
      final menuBuilder = FdcGridHeaderFilterMenuBuilder(
        callbacks: callbacks,
        column: column,
        runtimeColumnId: runtimeColumnId,
        translations: translations,
      );
      editor = FdcMenuAnchor(
        openOnTap: true,
        openOnSecondaryTap: false,
        consumeSecondaryTap: false,
        openAtAnchor: true,
        canOpen: callbacks.onOpenFilterMenu,
        onOpen: callbacks.onClearFocusedCell,
        entries: menuBuilder.buildEntries(),
        child: editor,
      );
    }

    return FdcGridHeaderFilterShell(
      label: operatorIgnoresValue || isBooleanFilter ? '' : operatorLabel,
      focusNode: focusNode,
      fillColor: fillColor,
      style: style,
      showClearButton: showClearButton,
      onClear: () => callbacks.onClearHeaderFilter(column, runtimeColumnId),
      overflowTooltipText: displayValue,
      overflowTooltipTextStyle: textStyle,
      overflowTooltipReservedWidth: _showsHeaderFilterPicker
          ? _headerFilterPickerButtonWidth
          : 0,
      child: editor,
    );
  }

  String _headerFilterTextForFocusState(
    BuildContext context,
    Object? rawValue, {
    required bool focused,
  }) {
    if (rawValue == null) {
      return '';
    }

    if (focused && callbacks.dataTypeOf(column) == FdcDataType.decimal) {
      final parsed = callbacks.parseHeaderFilterValue(
        column,
        runtimeColumnId,
        rawValue,
      );
      if (parsed != null) {
        final codec = FdcFieldValueCodec(
          settings: FdcApp.formatsOf(context),
          translations: FdcApp.translationsOf(context),
        );
        return codec.formatGridValue(
          column,
          parsed,
          runtimeColumnId: runtimeColumnId,
          forEditing: true,
          decimalScale: callbacks.decimalScaleOf(column),
        );
      }
    }

    return callbacks.formatHeaderFilterValue(column, runtimeColumnId, rawValue);
  }

  bool get _hasFilterState =>
      callbacks.hasHeaderFilterStateForColumn(column, runtimeColumnId);

  TextInputType? _headerFilterKeyboardType() {
    return switch (callbacks.dataTypeOf(column)) {
      FdcDataType.integer || FdcDataType.decimal =>
        const TextInputType.numberWithOptions(decimal: true, signed: true),
      FdcDataType.date ||
      FdcDataType.dateTime ||
      FdcDataType.time => TextInputType.datetime,
      _ => null,
    };
  }

  List<TextInputFormatter>? _headerFilterInputFormatters(BuildContext context) {
    final codec = FdcFieldValueCodec(
      settings: FdcApp.formatsOf(context),
      translations: FdcApp.translationsOf(context),
    );
    return codec.inputFormattersForGridColumn(
      column,
      runtimeColumnId: runtimeColumnId,
      decimalScale: callbacks.decimalScaleOf(column),
      decimalPrecision: callbacks.decimalPrecisionOf(column),
    );
  }

  bool get _showsHeaderFilterPicker => column.showPicker && _pickerKind != null;

  FdcValueCodecKind? get _pickerKind {
    return switch (callbacks.dataTypeOf(column)) {
      FdcDataType.date => FdcValueCodecKind.date,
      FdcDataType.dateTime => FdcValueCodecKind.dateTime,
      FdcDataType.time => FdcValueCodecKind.time,
      _ => null,
    };
  }

  Future<String?> _pickHeaderFilterValue(
    BuildContext context,
    String currentText,
  ) async {
    final kind = _pickerKind;
    if (kind == null) {
      return null;
    }

    final codec = FdcFieldValueCodec(
      settings: FdcApp.formatsOf(context),
      translations: FdcApp.translationsOf(context),
    );
    final currentValue = currentText.trim().isEmpty
        ? null
        : codec.parseGridText(
            column,
            currentText.trim(),
            runtimeColumnId: runtimeColumnId,
            decimalScale: callbacks.decimalScaleOf(column),
            decimalPrecision: callbacks.decimalPrecisionOf(column),
          );
    final pickedValue = await FdcValuePicker.pick(
      context: context,
      kind: kind,
      currentValue: currentValue,
    );
    if (!context.mounted || pickedValue == null) {
      return null;
    }

    return codec.formatGridValue(
      column,
      pickedValue,
      runtimeColumnId: runtimeColumnId,
      forEditing: true,
      decimalScale: callbacks.decimalScaleOf(column),
    );
  }
}

class FdcGridHeaderTextFilterInput extends StatefulWidget {
  const FdcGridHeaderTextFilterInput({
    super.key,
    required this.value,
    required this.focusNode,
    required this.style,
    required this.onChanged,
    required this.onSubmitted,
    required this.debouncePolicy,
    required this.onDeferredChanged,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.onPickValue,
    this.reserveClearButtonSpace = false,
    this.collapsedDisplayText,
  });

  final String value;
  final FocusNode focusNode;
  final TextStyle style;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final FdcDebouncePolicy debouncePolicy;
  final VoidCallback onDeferredChanged;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Future<String?> Function(BuildContext context, String currentText)?
  onPickValue;
  final bool reserveClearButtonSpace;
  final String? collapsedDisplayText;

  @override
  State<FdcGridHeaderTextFilterInput> createState() =>
      FdcGridHeaderTextFilterInputState();
}

class FdcGridHeaderTextFilterInputState
    extends State<FdcGridHeaderTextFilterInput> {
  late final TextEditingController _controller;
  late final FdcTextInputAutorepeatGuard _autorepeatGuard;

  String _lastObservedText = '';
  bool _pickerInteractionInProgress = false;

  bool get _showPicker =>
      widget.enabled &&
      widget.onPickValue != null &&
      (widget.focusNode.hasFocus || _pickerInteractionInProgress);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _lastObservedText = widget.value;
    widget.focusNode.addListener(_handleFocusChanged);
    _autorepeatGuard = FdcTextInputAutorepeatGuard(
      focusNode: widget.focusNode,
      onDeferredTextChangeReady: _flushDeferredTextChange,
      onDeferredTextChangeMarked: widget.onDeferredChanged,
      shouldSubmitOnEnter: () =>
          widget.debouncePolicy == FdcDebouncePolicy.disabled,
      onSubmit: _handleSubmitted,
    );
  }

  @override
  void didUpdateWidget(FdcGridHeaderTextFilterInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
    if (!widget.focusNode.hasFocus && !_pickerInteractionInProgress) {
      _syncControllerText(widget.value);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    _autorepeatGuard.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
    if (widget.focusNode.hasFocus) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.focusNode.hasFocus) {
          return;
        }
        _syncControllerText(widget.value);
      });
      return;
    }

    if (!_pickerInteractionInProgress) {
      _syncControllerText(widget.value);
    }
  }

  void _syncControllerText(String value) {
    if (value == _controller.text) {
      _lastObservedText = value;
      return;
    }

    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _lastObservedText = value;
  }

  String get _collapsedDisplayText {
    if (!widget.enabled) {
      final displayText = widget.collapsedDisplayText;
      if (displayText != null) {
        return displayText;
      }
    }

    final text = _controller.text;
    if (text.trim().isNotEmpty) {
      return text;
    }
    return widget.collapsedDisplayText ?? '';
  }

  bool get _showCollapsedDisplayText =>
      !widget.focusNode.hasFocus &&
      !_pickerInteractionInProgress &&
      _collapsedDisplayText.trim().isNotEmpty;

  TextStyle get _effectiveTextFieldStyle => _showCollapsedDisplayText
      ? widget.style.copyWith(color: Colors.transparent)
      : widget.style;

  Widget _withCollapsedDisplayText(Widget child) {
    if (!_showCollapsedDisplayText) {
      return child;
    }

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: _FdcHeaderFilterOverflowText(
                      text: _collapsedDisplayText,
                      style: widget.style,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _handleChanged(String value) {
    if (value == _lastObservedText) {
      return;
    }

    _lastObservedText = value;
    if (_autorepeatGuard.shouldDeferTextChange) {
      _autorepeatGuard.markDeferredTextChange();
      return;
    }

    widget.onChanged(value);
  }

  void _flushDeferredTextChange() {
    widget.onChanged(_controller.text);
  }

  void _handleSubmitted() {
    _autorepeatGuard.clear();
    widget.onSubmitted(_controller.text);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.focusNode.requestFocus();
    });
  }

  void _handlePickerPointerDown(BuildContext context) {
    if (_pickerInteractionInProgress) {
      return;
    }

    _pickerInteractionInProgress = true;
    setState(() {});
    widget.focusNode.requestFocus();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_pickValue(context));
    });
  }

  Future<void> _pickValue(BuildContext context) async {
    final onPickValue = widget.onPickValue;
    if (onPickValue == null) {
      _pickerInteractionInProgress = false;
      return;
    }

    var pickedApplied = false;
    try {
      final pickedText = await onPickValue(context, _controller.text);
      if (!mounted || pickedText == null) {
        return;
      }

      pickedApplied = true;
      _syncControllerText(pickedText);
      widget.onSubmitted(pickedText);
      widget.focusNode.requestFocus();
    } finally {
      if (mounted) {
        _pickerInteractionInProgress = false;
        if (!pickedApplied && !widget.focusNode.hasFocus) {
          _syncControllerText(widget.value);
        }
        setState(() {});
      } else {
        _pickerInteractionInProgress = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final reserveInlineClear =
              widget.reserveClearButtonSpace &&
              constraints.maxWidth >=
                  FdcGridHeaderMetrics.filterInlineClearMinimumWidth;
          final rightPadding = reserveInlineClear
              ? FdcGridHeaderMetrics.filterFieldHorizontalPadding +
                    FdcGridHeaderMetrics.filterClearButtonWidth +
                    FdcGridHeaderMetrics.filterClearButtonGap
              : FdcGridHeaderMetrics.filterFieldHorizontalPadding;

          return Padding(
            padding: EdgeInsets.only(
              left: FdcGridHeaderMetrics.filterFieldHorizontalPadding,
              right: rightPadding,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: double.infinity,
                child: _buildTextFieldWithPicker(context, colorScheme),
              ),
            ),
          );
        },
      ),
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

  Widget _buildTextFieldWithPicker(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final textField = TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      style: _effectiveTextFieldStyle,
      enabled: widget.enabled,
      cursorColor: colorScheme.primary,
      decoration: null,
      dragStartBehavior: DragStartBehavior.down,
      scrollPhysics: const NeverScrollableScrollPhysics(),
      showCursor: widget.enabled,
      enableInteractiveSelection: widget.enabled,
      selectionControls: materialTextSelectionControls,
      mouseCursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textInputAction: TextInputAction.search,
      groupId: fdcGridTapRegionGroup,
      contextMenuBuilder: _buildTextContextMenu,
      onChanged: _handleChanged,
      onEditingComplete: () {
        if (widget.debouncePolicy != FdcDebouncePolicy.disabled) {
          _handleSubmitted();
        }
      },
      onSubmitted: (_) => _handleSubmitted(),
    );

    if (widget.onPickValue == null) {
      final child = _withCollapsedDisplayText(textField);
      return child;
    }

    // Keep the pickable header filter editor in a stable Stack even before the
    // field has focus. The picker affordance becomes visible on focus, but the
    // TextField itself must not be replaced during the initial pointer gesture;
    // otherwise Flutter can focus the field without placing the caret until the
    // second click.
    return LayoutBuilder(
      builder: (context, constraints) {
        final showPicker =
            _showPicker && constraints.maxWidth >= _minimumWidthForPicker;
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Padding(
              padding: EdgeInsets.only(
                right: showPicker ? _headerFilterPickerButtonWidth : 0,
              ),
              child: _withCollapsedDisplayText(textField),
            ),
            if (showPicker)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: _headerFilterPickerButtonWidth,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (_) => _handlePickerPointerDown(context),
                      child: AbsorbPointer(
                        child: FdcPickerButton(
                          onPressed: () {},
                          compact: true,
                          compactSize: _headerFilterPickerButtonWidth,
                          compactIconSize: 16,
                          compactSplashRadius: 13,
                          iconColor: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
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

class FdcGridHeaderComboFilterEditor extends StatelessWidget {
  const FdcGridHeaderComboFilterEditor({
    super.key,
    required this.model,
    required this.callbacks,
    required this.column,
    required this.runtimeColumnId,
    required this.fillColor,
    required this.style,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final FdcGridColumn<dynamic> column;
  final FdcColumnIdentity runtimeColumnId;
  final Color fillColor;
  final FdcGridHeaderFilterStyle style;

  @override
  Widget build(BuildContext context) {
    final translations = FdcApp.translationsOf(context);
    final value = model.headerFilterValues[runtimeColumnId];
    final options = <FdcOption<Object?>>[
      FdcOption<Object?>(value: null, label: translations.common.all),
      ...callbacks.headerFilterOptions(context, column),
    ];
    FdcOption<Object?>? selectedOption;
    for (final option in options) {
      if (option.value == value) {
        selectedOption = option;
        break;
      }
    }
    final hasValue = value != null && selectedOption != null;
    final displayLabel = hasValue
        ? selectedOption.label
        : translations.common.all;
    final focusNode = callbacks.headerFilterFocusNodeOf(
      column,
      runtimeColumnId,
    );
    final enabled = callbacks.canOpenFilterMenu();
    final textStyle = callbacks.headerFilterTextStyleOf(context);
    final comboDisplay = FdcComboField<Object?>(
      key: ValueKey(
        'fdc-filter-combo-$runtimeColumnId-${model.headerFilterResetGeneration}',
      ),
      value: value,
      options: options,
      focusNode: focusNode,
      enabled: enabled,
      decoration: _headerFilterInputDecoration(context),
      style: textStyle,
      strutStyle: _headerFilterStrutStyle(context),
      iconColor: FdcGridControlTheme.iconColor(
        context,
        model.controlsStyle,
        enabled: enabled,
      ),
      search: FdcComboSearchOptions(
        searchable: column.filterConfig?.comboSearchable ?? false,
      ),
      searchHintText:
          column.filterConfig?.comboSearchHintText ??
          translations.common.search,
      maxPopupItems: column.filterConfig?.comboMaxPopupItems ?? 8,
      optionBuilder: column.filterConfig?.comboOptionBuilder,
      openOnEnter: false,
      tapRegionGroupId: fdcGridTapRegionGroup,
      onTap: enabled
          ? () {
              callbacks.onClearFocusedCell();
              callbacks.onFocusHeaderFilterField(column, runtimeColumnId);
            }
          : null,
      onChanged: (value) {
        if (!enabled) {
          return;
        }
        callbacks.onSetHeaderFilterValue(column, runtimeColumnId, value);
      },
    );

    return FdcGridHeaderFilterShell(
      label: _label,
      focusNode: focusNode,
      fillColor: fillColor,
      style: style,
      overflowTooltipText: displayLabel,
      overflowTooltipTextStyle: textStyle,
      overflowTooltipReservedWidth: FdcGridHeaderMetrics.filterDropdownIconSize,
      child: comboDisplay,
    );
  }

  String get _label => callbacks.filterOperatorLabel(
    callbacks.headerFilterOperatorOf(column, runtimeColumnId),
  );

  InputDecoration _headerFilterInputDecoration(BuildContext context) {
    return FdcInputDecoration.headerFilterEmbedded(
      hintText: FdcApp.translationsOf(context).common.all,
    );
  }

  StrutStyle _headerFilterStrutStyle(BuildContext context) {
    final style = callbacks.headerFilterTextStyleOf(context);
    return StrutStyle(
      fontSize: style.fontSize,
      height: style.height ?? 1.0,
      forceStrutHeight: true,
    );
  }
}

class FdcGridHeaderListFilterEditor extends StatefulWidget {
  const FdcGridHeaderListFilterEditor({
    super.key,
    required this.model,
    required this.callbacks,
    required this.column,
    required this.runtimeColumnId,
    required this.fillColor,
    required this.style,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final FdcGridColumn<dynamic> column;
  final FdcColumnIdentity runtimeColumnId;
  final Color fillColor;
  final FdcGridHeaderFilterStyle style;

  @override
  State<FdcGridHeaderListFilterEditor> createState() =>
      _FdcGridHeaderListFilterEditorState();
}

class _FdcGridHeaderListFilterEditorState
    extends State<FdcGridHeaderListFilterEditor> {
  static const double _listPanelWidth = 220;
  static const double _listPanelMaxOptionsHeight = 260;
  static const double _listItemHeight = 34;
  static const double _listIconSlotWidth = 22;
  static const double _listIconSize = 18;

  late List<Object?> _draftValues;
  bool _editingDraft = false;

  @override
  void initState() {
    super.initState();
    _draftValues = _selectedValuesFromModel();
  }

  @override
  void didUpdateWidget(FdcGridHeaderListFilterEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editingDraft || oldWidget.runtimeColumnId != widget.runtimeColumnId) {
      _draftValues = _selectedValuesFromModel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final translations = FdcApp.translationsOf(context);
    final selectedValues = _selectedValuesFromModel();
    final selectedCount = selectedValues.length;
    final active = selectedCount > 0;
    final label = active
        ? translations.grid.selected(selectedCount)
        : translations.common.all;
    final enabled = widget.callbacks.canOpenFilterMenu();
    final textStyle = widget.callbacks.headerFilterTextStyleOf(context);

    final focusNode = widget.callbacks.headerFilterFocusNodeOf(
      widget.column,
      widget.runtimeColumnId,
    );
    return FdcGridHeaderFilterShell(
      label: _label,
      focusNode: focusNode,
      fillColor: widget.fillColor,
      style: widget.style,
      overflowTooltipText: label,
      overflowTooltipTextStyle: textStyle,
      overflowTooltipReservedWidth: FdcGridHeaderMetrics.filterDropdownIconSize,
      child: FdcMenuAnchor(
        openOnTap: enabled,
        openOnSecondaryTap: false,
        consumeSecondaryTap: false,
        openAtAnchor: true,
        canOpen: widget.callbacks.onOpenFilterMenu,
        onOpen: () {
          _editingDraft = true;
          _resetDraftFromCommitted();
          widget.callbacks.onFocusHeaderFilterField(
            widget.column,
            widget.runtimeColumnId,
          );
        },
        onClose: () {
          _editingDraft = false;
          _resetDraftFromCommitted();
        },
        entries: [FdcMenuWidgetEntry(child: _buildListPanel(context))],
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FdcGridHeaderMetrics.filterFieldHorizontalPadding,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showDropdownIcon =
                    constraints.maxWidth >=
                    FdcGridHeaderMetrics.filterDropdownIconSize + 28;
                return Row(
                  children: [
                    Expanded(
                      child: _FdcHeaderFilterOverflowText(
                        text: label,
                        style: textStyle,
                      ),
                    ),
                    if (showDropdownIcon)
                      Icon(
                        Icons.arrow_drop_down,
                        size: FdcGridHeaderMetrics.filterDropdownIconSize,
                        color: FdcGridControlTheme.iconColor(
                          context,
                          widget.model.controlsStyle,
                          enabled: enabled,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String get _label => widget.callbacks.filterOperatorLabel(
    widget.callbacks.headerFilterOperatorOf(
      widget.column,
      widget.runtimeColumnId,
    ),
  );

  List<Object?> _selectedValuesFromModel() {
    final value = widget.model.headerFilterValues[widget.runtimeColumnId];
    if (value is Iterable<Object?>) {
      return value.toList();
    }
    if (value is Iterable) {
      return value.cast<Object?>().toList();
    }
    if (value == null) {
      return const <Object?>[];
    }
    return <Object?>[value];
  }

  void _resetDraftFromCommitted() {
    final next = _selectedValuesFromModel();
    if (!mounted) {
      _draftValues = next;
      return;
    }
    setState(() {
      _draftValues = next;
    });
  }

  bool _draftContains(Object? value) {
    return _draftValues.any((draftValue) => draftValue == value);
  }

  void _toggleDraftOption(FdcOption<Object?> option) {
    setState(() {
      final exists = _draftContains(option.value);
      _draftValues = exists
          ? _draftValues.where((value) => value != option.value).toList()
          : <Object?>[..._draftValues, option.value];
    });
  }

  bool get _hasDraftChanges {
    final committedValues = _selectedValuesFromModel();
    if (_draftValues.length != committedValues.length) {
      return true;
    }
    for (final value in _draftValues) {
      if (!committedValues.any((committedValue) => committedValue == value)) {
        return true;
      }
    }
    return false;
  }

  void _clearAndApply(BuildContext menuContext) {
    _editingDraft = false;
    _draftValues = const <Object?>[];
    widget.callbacks.onSetHeaderFilterValue(
      widget.column,
      widget.runtimeColumnId,
      null,
    );
    MenuController.maybeOf(menuContext)?.close();
  }

  void _apply(BuildContext menuContext) {
    if (!_hasDraftChanges) {
      return;
    }
    final operator = widget.callbacks.headerFilterOperatorOf(
      widget.column,
      widget.runtimeColumnId,
    );
    if (operator != FdcFilterOperator.inList &&
        operator != FdcFilterOperator.notInList) {
      widget.callbacks.onSetHeaderFilterOperator(
        widget.column,
        widget.runtimeColumnId,
        FdcFilterOperator.inList,
      );
    }
    _editingDraft = false;
    widget.callbacks.onSetHeaderFilterValue(
      widget.column,
      widget.runtimeColumnId,
      _draftValues.isEmpty ? null : List<Object?>.of(_draftValues),
    );
    MenuController.maybeOf(menuContext)?.close();
  }

  void _cancel(BuildContext menuContext) {
    _editingDraft = false;
    _resetDraftFromCommitted();
    MenuController.maybeOf(menuContext)?.close();
  }

  KeyEventResult _handleListPanelKeyEvent(
    BuildContext menuContext,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancel(menuContext);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_hasDraftChanges) {
        _apply(menuContext);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildListPanel(BuildContext context) {
    final options = widget.callbacks.headerFilterOptions(
      context,
      widget.column,
    );
    final popupStyle = FdcGridTheme.resolveData(
      context,
      null,
    ).popupMenu.resolve();
    final enabled = widget.callbacks.canOpenFilterMenu();
    final translations = FdcApp.translationsOf(context);

    return Builder(
      builder: (menuContext) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) => _handleListPanelKeyEvent(menuContext, event),
        child: SizedBox(
          width: _listPanelWidth,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: _listPanelMaxOptionsHeight,
                  ),
                  child: SingleChildScrollView(
                    primary: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildListOptionRow(
                          context,
                          text: translations.common.all,
                          checked: _draftValues.isEmpty,
                          enabled: enabled,
                          onPressed: () => _clearAndApply(menuContext),
                        ),
                        if (options.isNotEmpty)
                          Divider(
                            height: 10,
                            thickness: 1,
                            color: popupStyle.separatorColor!,
                          ),
                        for (final option in options)
                          _buildListOptionRow(
                            context,
                            text: option.label,
                            child: widget
                                .column
                                .filterConfig
                                ?.comboOptionBuilder
                                ?.call(context, option),
                            checked: _draftContains(option.value),
                            enabled: enabled,
                            onPressed: () => _toggleDraftOption(option),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      TextButton(
                        style: _headerFilterPopupCancelButtonStyle(),
                        onPressed: () => _cancel(menuContext),
                        child: Text(translations.common.cancel),
                      ),
                      FilledButton(
                        style: _headerFilterPopupApplyButtonStyle(),
                        onPressed: enabled && _hasDraftChanges
                            ? () => _apply(menuContext)
                            : null,
                        child: Text(translations.common.apply),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListOptionRow(
    BuildContext context, {
    required String text,
    required bool checked,
    required bool enabled,
    required VoidCallback onPressed,
    Widget? child,
  }) {
    final popupStyle = FdcGridTheme.resolveData(
      context,
      null,
    ).popupMenu.resolve();
    final textStyle = widget.callbacks
        .headerFilterTextStyleOf(context)
        .copyWith(
          color: enabled ? popupStyle.textColor : popupStyle.disabledTextColor,
          fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
        );
    final iconColor = enabled
        ? popupStyle.iconColor
        : popupStyle.disabledIconColor;

    return SizedBox(
      height: _listItemHeight,
      child: Material(
        type: MaterialType.transparency,
        color: checked ? popupStyle.selectedItemColor : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          hoverColor: popupStyle.hoverColor,
          focusColor: popupStyle.hoverColor,
          splashColor: popupStyle.pressedColor,
          highlightColor: popupStyle.pressedColor,
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                SizedBox(
                  width: _listIconSlotWidth,
                  child: checked
                      ? Icon(Icons.check, size: _listIconSize, color: iconColor)
                      : null,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: child ?? Text(text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FdcGridHeaderRangeFilterEditor extends StatefulWidget {
  const FdcGridHeaderRangeFilterEditor({
    super.key,
    required this.model,
    required this.callbacks,
    required this.column,
    required this.runtimeColumnId,
    required this.fillColor,
    required this.style,
    this.deferredAnchorChild,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final FdcGridColumn<dynamic> column;
  final FdcColumnIdentity runtimeColumnId;
  final Color fillColor;
  final FdcGridHeaderFilterStyle style;
  final Widget? deferredAnchorChild;

  @override
  State<FdcGridHeaderRangeFilterEditor> createState() =>
      _FdcGridHeaderRangeFilterEditorState();
}

class _FdcGridHeaderRangeFilterEditorState
    extends State<FdcGridHeaderRangeFilterEditor> {
  static const double _rangePanelWidth = 220;
  static const double _rangeInputHeight = 38;
  static const double _rangePickerWidth = 36;
  static const double _rangeErrorLineHeight = 14;

  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final FocusNode _fromFocusNode;
  late final FocusNode _toFocusNode;
  bool _editingDraft = false;
  String? _fromErrorText;
  String? _toErrorText;

  @override
  void initState() {
    super.initState();
    final range = _range;
    _fromController = TextEditingController(text: _textOf(range?.from));
    _toController = TextEditingController(text: _textOf(range?.to));
    _fromFocusNode = FocusNode(debugLabel: 'FdcGrid header range filter from');
    _toFocusNode = FocusNode(debugLabel: 'FdcGrid header range filter to');
    _fromFocusNode.addListener(_handleFromFocusChanged);
    _toFocusNode.addListener(_handleToFocusChanged);
  }

  @override
  void didUpdateWidget(FdcGridHeaderRangeFilterEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editingDraft) {
      _resetDraftFromCommitted();
    }
  }

  @override
  void dispose() {
    _fromFocusNode.removeListener(_handleFromFocusChanged);
    _toFocusNode.removeListener(_handleToFocusChanged);
    _fromController.dispose();
    _toController.dispose();
    _fromFocusNode.dispose();
    _toFocusNode.dispose();
    super.dispose();
  }

  bool get _deferredOperatorPopup => widget.deferredAnchorChild != null;

  FdcFilterRangeValue? get _range {
    final value = widget.model.headerFilterValues[widget.runtimeColumnId];
    return value is FdcFilterRangeValue ? value : null;
  }

  String _textOf(Object? value) {
    if (value == null) {
      return '';
    }
    return widget.callbacks.formatHeaderFilterValue(
      widget.column,
      widget.runtimeColumnId,
      value,
    );
  }

  void _syncController(TextEditingController controller, String text) {
    if (controller.text == text) {
      return;
    }
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _resetDraftFromCommitted() {
    final range = _range;
    _syncController(_fromController, _textOf(range?.from));
    _syncController(_toController, _textOf(range?.to));
    _fromErrorText = null;
    _toErrorText = null;
  }

  void _handleFromFocusChanged() {
    if (_fromFocusNode.hasFocus) {
      _normalizeDraftFieldForEditing(from: true);
    } else {
      _normalizeDraftField(from: true);
    }
  }

  void _handleToFocusChanged() {
    if (_toFocusNode.hasFocus) {
      _normalizeDraftFieldForEditing(from: false);
    } else {
      _normalizeDraftField(from: false);
    }
  }

  void _normalizeDraftFieldForEditing({required bool from}) {
    if (!mounted ||
        widget.callbacks.dataTypeOf(widget.column) != FdcDataType.decimal) {
      return;
    }

    final controller = from ? _fromController : _toController;
    final parsed = _parseDraftTextForEdit(context, controller.text.trim());
    if (parsed.invalid) {
      return;
    }

    _syncController(controller, parsed.normalizedText);
  }

  void _normalizeDraftField({required bool from}) {
    if (!mounted) {
      return;
    }

    final controller = from ? _fromController : _toController;
    final parsed = _parseDraftTextForCommit(context, controller.text.trim());
    final nextErrorText = parsed.invalid
        ? FdcApp.translationsOf(context).validation.invalidValue
        : null;

    if (!parsed.invalid) {
      _syncController(controller, parsed.normalizedText);
    }

    final currentErrorText = from ? _fromErrorText : _toErrorText;
    if (currentErrorText == nextErrorText) {
      return;
    }

    setState(() {
      if (from) {
        _fromErrorText = nextErrorText;
      } else {
        _toErrorText = nextErrorText;
      }
    });
  }

  void _apply(BuildContext menuContext) {
    final parsed = _validateDraft(menuContext);
    if (parsed == null) {
      return;
    }

    final (:from, :to, :fromText, :toText) = parsed;
    _syncController(_fromController, fromText);
    _syncController(_toController, toText);
    _editingDraft = false;
    widget.callbacks.onSetHeaderFilterValue(
      widget.column,
      widget.runtimeColumnId,
      FdcFilterRangeValue(from: from, to: to),
    );
    MenuController.maybeOf(menuContext)?.close();
  }

  bool _canApplyDraft(BuildContext context) {
    final fromText = _fromController.text.trim();
    final toText = _toController.text.trim();
    if (fromText.isEmpty || toText.isEmpty) {
      return false;
    }

    return !_parseDraftTextForCommit(context, fromText).invalid &&
        !_parseDraftTextForCommit(context, toText).invalid;
  }

  ({Object? from, Object? to, String fromText, String toText})? _validateDraft(
    BuildContext context,
  ) {
    final fromText = _fromController.text.trim();
    final toText = _toController.text.trim();
    final fromMissing = fromText.isEmpty;
    final toMissing = toText.isEmpty;
    final from = fromMissing
        ? (value: null, normalizedText: '', invalid: true)
        : _parseDraftTextForCommit(context, fromText);
    final to = toMissing
        ? (value: null, normalizedText: '', invalid: true)
        : _parseDraftTextForCommit(context, toText);
    final fromInvalid = fromMissing || from.invalid;
    final toInvalid = toMissing || to.invalid;

    setState(() {
      final validation = FdcApp.translationsOf(context).validation;
      _fromErrorText = fromMissing
          ? validation.requiredValue
          : from.invalid
          ? validation.invalidValue
          : null;
      _toErrorText = toMissing
          ? validation.requiredValue
          : to.invalid
          ? validation.invalidValue
          : null;
    });

    if (fromInvalid || toInvalid) {
      return null;
    }
    return (
      from: from.value,
      to: to.value,
      fromText: from.normalizedText,
      toText: to.normalizedText,
    );
  }

  ({Object? value, String normalizedText, bool invalid}) _parseDraftTextForEdit(
    BuildContext context,
    String text,
  ) {
    if (text.isEmpty) {
      return (value: null, normalizedText: '', invalid: false);
    }

    final codec = FdcFieldValueCodec(
      settings: FdcApp.formatsOf(context),
      translations: FdcApp.translationsOf(context),
    );
    final value = codec.parseGridText(
      widget.column,
      text,
      runtimeColumnId: widget.runtimeColumnId,
      decimalScale: widget.callbacks.decimalScaleOf(widget.column),
      decimalPrecision: widget.callbacks.decimalPrecisionOf(widget.column),
    );
    final invalid = value == null;
    return (
      value: value,
      normalizedText: invalid
          ? text
          : codec.formatGridValue(
              widget.column,
              value,
              runtimeColumnId: widget.runtimeColumnId,
              forEditing: true,
              decimalScale: widget.callbacks.decimalScaleOf(widget.column),
            ),
      invalid: invalid,
    );
  }

  ({Object? value, String normalizedText, bool invalid})
  _parseDraftTextForCommit(BuildContext context, String text) {
    if (text.isEmpty) {
      return (value: null, normalizedText: '', invalid: false);
    }

    final codec = FdcFieldValueCodec(
      settings: FdcApp.formatsOf(context),
      translations: FdcApp.translationsOf(context),
    );
    final result = codec.parseGridTextForCommit(
      widget.column,
      text,
      runtimeColumnId: widget.runtimeColumnId,
      decimalScale: widget.callbacks.decimalScaleOf(widget.column),
      decimalPrecision: widget.callbacks.decimalPrecisionOf(widget.column),
    );
    final invalid = result.errorText != null || result.value == null;
    final normalizedText = invalid
        ? result.normalizedText ?? text
        : _formatDraftCommitDisplayText(
            context,
            codec,
            result.value,
            result.normalizedText ?? text,
          );
    return (
      value: result.value,
      normalizedText: normalizedText,
      invalid: invalid,
    );
  }

  String _formatDraftCommitDisplayText(
    BuildContext context,
    FdcFieldValueCodec codec,
    Object? value,
    String fallbackText,
  ) {
    if (value == null ||
        widget.callbacks.dataTypeOf(widget.column) != FdcDataType.decimal) {
      return fallbackText;
    }

    return codec.formatDecimal(
      value,
      forEditing: false,
      scale: widget.callbacks.decimalScaleOf(widget.column),
      formatSettings: widget.column.formatSettings ?? FdcApp.formatsOf(context),
    );
  }

  bool get _showsRangePicker => widget.column.showPicker && _pickerKind != null;

  FdcValueCodecKind? get _pickerKind {
    return switch (widget.callbacks.dataTypeOf(widget.column)) {
      FdcDataType.date => FdcValueCodecKind.date,
      FdcDataType.dateTime => FdcValueCodecKind.dateTime,
      FdcDataType.time => FdcValueCodecKind.time,
      _ => null,
    };
  }

  Future<void> _pickRangeValue(
    BuildContext context, {
    required bool from,
  }) async {
    final kind = _pickerKind;
    if (kind == null) {
      return;
    }

    final controller = from ? _fromController : _toController;
    final codec = FdcFieldValueCodec(
      settings: FdcApp.formatsOf(context),
      translations: FdcApp.translationsOf(context),
    );
    final currentText = controller.text.trim();
    final currentValue = currentText.isEmpty
        ? null
        : codec.parseGridText(
            widget.column,
            currentText,
            runtimeColumnId: widget.runtimeColumnId,
            decimalScale: widget.callbacks.decimalScaleOf(widget.column),
            decimalPrecision: widget.callbacks.decimalPrecisionOf(
              widget.column,
            ),
          );
    final pickedValue = await FdcValuePicker.pick(
      context: context,
      kind: kind,
      currentValue: currentValue,
    );
    if (!mounted || pickedValue == null) {
      return;
    }

    _syncController(
      controller,
      codec.formatGridValue(
        widget.column,
        pickedValue,
        runtimeColumnId: widget.runtimeColumnId,
        forEditing: true,
        decimalScale: widget.callbacks.decimalScaleOf(widget.column),
      ),
    );
    _clearDraftError(from: from);
    (from ? _fromFocusNode : _toFocusNode).requestFocus();
  }

  void _clearDraftError({required bool from}) {
    if (from && _fromErrorText == null) {
      return;
    }
    if (!from && _toErrorText == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      if (from) {
        _fromErrorText = null;
      } else {
        _toErrorText = null;
      }
    });
  }

  void _handleDraftTextChanged({required bool from}) {
    if (!mounted) {
      return;
    }
    setState(() {
      if (from) {
        _fromErrorText = null;
      } else {
        _toErrorText = null;
      }
    });
  }

  void _cancel(BuildContext menuContext) {
    _editingDraft = false;
    widget.callbacks.onCancelHeaderFilterRangeEdit(
      widget.column,
      widget.runtimeColumnId,
    );
    if (_deferredOperatorPopup) {
      widget.callbacks.onRangeAutoOpenHandled(widget.runtimeColumnId);
    }
    _resetDraftFromCommitted();
    MenuController.maybeOf(menuContext)?.close();
  }

  void _clear() {
    _fromController.clear();
    _toController.clear();
    _fromErrorText = null;
    _toErrorText = null;
    widget.callbacks.onClearHeaderFilter(widget.column, widget.runtimeColumnId);
    if (mounted) {
      setState(() {});
    }
  }

  KeyEventResult _handleRangePanelKeyEvent(
    BuildContext menuContext,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.tab) {
      _moveRangeFieldFocus(forward: !HardwareKeyboard.instance.isShiftPressed);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _handleRangeEnterKey(menuContext);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _cancel(menuContext);
      return KeyEventResult.handled;
    }
    if (_handleRangeTextNavigationKey(key)) {
      return KeyEventResult.handled;
    }

    // Do not handle printable/text-editing keys here. Desktop TextField input
    // depends on those key events remaining available to the focused editable.
    // The panel only traps grid-navigation commands that should never move the
    // grid while the floating range editor is open.
    return KeyEventResult.ignored;
  }

  bool _handleRangeTextNavigationKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowLeft) {
      return _moveRangeTextCaret(-1);
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      return _moveRangeTextCaret(1);
    }
    if (key == LogicalKeyboardKey.home) {
      return _moveRangeTextCaretTo(0);
    }
    if (key == LogicalKeyboardKey.end) {
      final controller = _focusedRangeController;
      if (controller == null) {
        return false;
      }
      return _moveRangeTextCaretTo(controller.text.length);
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      return _moveRangeFieldFocusVertically(forward: true);
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      return _moveRangeFieldFocusVertically(forward: false);
    }
    if (key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      return true;
    }
    return false;
  }

  TextEditingController? get _focusedRangeController {
    if (_fromFocusNode.hasFocus) {
      return _fromController;
    }
    if (_toFocusNode.hasFocus) {
      return _toController;
    }
    return null;
  }

  bool _moveRangeTextCaret(int delta) {
    final controller = _focusedRangeController;
    if (controller == null) {
      return false;
    }
    final selection = controller.selection;
    final currentOffset = selection.isValid
        ? selection.extentOffset
        : controller.text.length;
    final nextOffset = (currentOffset + delta)
        .clamp(0, controller.text.length)
        .toInt();
    return _moveRangeTextCaretTo(nextOffset);
  }

  bool _moveRangeTextCaretTo(int offset) {
    final controller = _focusedRangeController;
    if (controller == null) {
      return false;
    }
    final nextOffset = offset.clamp(0, controller.text.length).toInt();
    controller.selection = TextSelection.collapsed(offset: nextOffset);
    return true;
  }

  void _moveRangeFieldFocus({required bool forward}) {
    if (forward) {
      if (_fromFocusNode.hasFocus) {
        _normalizeDraftField(from: true);
        _toFocusNode.requestFocus();
      } else {
        _toFocusNode.requestFocus();
      }
      return;
    }

    if (_toFocusNode.hasFocus) {
      _normalizeDraftField(from: false);
      _fromFocusNode.requestFocus();
    } else {
      _fromFocusNode.requestFocus();
    }
  }

  bool _moveRangeFieldFocusVertically({required bool forward}) {
    if (forward) {
      if (_fromFocusNode.hasFocus) {
        _normalizeDraftField(from: true);
        _toFocusNode.requestFocus();
      }
      return true;
    }

    if (_toFocusNode.hasFocus) {
      _normalizeDraftField(from: false);
      _fromFocusNode.requestFocus();
    }
    return true;
  }

  void _handleRangeEnterKey(BuildContext menuContext) {
    if (_fromFocusNode.hasFocus) {
      _normalizeDraftField(from: true);
      _toFocusNode.requestFocus();
      return;
    }

    if (_toFocusNode.hasFocus) {
      _apply(menuContext);
      return;
    }

    _fromFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final callbacks = widget.callbacks;
    final translations = FdcApp.translationsOf(context);
    final summaryTooltipText = _summaryTooltipText(translations);
    final enabled = callbacks.canOpenFilterMenu();
    final focusNode = callbacks.headerFilterFocusNodeOf(
      widget.column,
      widget.runtimeColumnId,
    );
    final textStyle = callbacks.headerFilterTextStyleOf(context);
    final hasState = callbacks.hasHeaderFilterStateForColumn(
      widget.column,
      widget.runtimeColumnId,
    );
    final autoOpenToken =
        widget.model.rangeAutoOpenColumnId == widget.runtimeColumnId
        ? widget.model.headerFilterRangeAutoOpenGeneration
        : null;

    final rangeMenu = FdcMenuAnchor(
      openOnTap: enabled && !_deferredOperatorPopup,
      openOnSecondaryTap: false,
      consumeSecondaryTap: false,
      openAtAnchor: true,
      openRequestToken: autoOpenToken,
      canOpen: callbacks.onOpenFilterMenu,
      onOpen: () {
        _editingDraft = true;
        _resetDraftFromCommitted();
        if (!_deferredOperatorPopup) {
          callbacks.onRangeAutoOpenHandled(widget.runtimeColumnId);
        }
        callbacks.onClearFocusedCell();
        callbacks.onFocusHeaderFilterField(
          widget.column,
          widget.runtimeColumnId,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _fromFocusNode.requestFocus();
          }
        });
      },
      onClose: () {
        if (_editingDraft) {
          widget.callbacks.onCancelHeaderFilterRangeEdit(
            widget.column,
            widget.runtimeColumnId,
          );
        }
        if (_deferredOperatorPopup) {
          widget.callbacks.onRangeAutoOpenHandled(widget.runtimeColumnId);
        }
        _editingDraft = false;
      },
      entries: [FdcMenuWidgetEntry(child: _buildRangePanel(context))],
      child:
          widget.deferredAnchorChild ??
          SizedBox.expand(
            child: Padding(
              padding: EdgeInsets.only(
                left: FdcGridHeaderMetrics.filterFieldHorizontalPadding,
                right: hasState
                    ? FdcGridHeaderMetrics.filterFieldHorizontalPadding +
                          FdcGridHeaderMetrics.filterClearButtonWidth +
                          FdcGridHeaderMetrics.filterClearButtonGap
                    : FdcGridHeaderMetrics.filterFieldHorizontalPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _FdcHeaderFilterOverflowText(
                      text: summaryTooltipText,
                      style: textStyle,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: FdcGridHeaderMetrics.filterDropdownIconSize,
                    color: FdcGridControlTheme.iconColor(
                      context,
                      widget.model.controlsStyle,
                      enabled: enabled,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (_deferredOperatorPopup) {
      return rangeMenu;
    }

    return FdcGridHeaderFilterShell(
      label: callbacks.filterOperatorLabel(FdcFilterOperator.between),
      focusNode: focusNode,
      fillColor: widget.fillColor,
      style: widget.style,
      showClearButton: hasState,
      onClear: _clear,
      overflowTooltipText: summaryTooltipText,
      overflowTooltipTextStyle: textStyle,
      overflowTooltipReservedWidth: FdcGridHeaderMetrics.filterDropdownIconSize,
      child: rangeMenu,
    );
  }

  InputDecoration _rangeInputDecoration(
    BuildContext context, {
    required bool from,
    required ColorScheme colorScheme,
    required bool showPicker,
  }) {
    const border = OutlineInputBorder(
      borderSide: BorderSide(color: _headerFilterRangeInputBorderColor),
    );
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: _headerFilterRangeInputFillColor,
      hoverColor: _headerFilterRangeInputFillColor,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      errorBorder: border.copyWith(
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: colorScheme.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      constraints: const BoxConstraints.tightFor(height: _rangeInputHeight),
      suffixIcon: SizedBox(
        width: _rangePickerWidth,
        height: _rangeInputHeight,
        child: showPicker
            ? Center(
                child: FdcPickerButton(
                  onPressed: () => _pickRangeValue(context, from: from),
                  compact: true,
                  compactSplashRadius: 14,
                  iconColor: colorScheme.primary,
                ),
              )
            : const SizedBox.shrink(),
      ),
      suffixIconConstraints: const BoxConstraints.tightFor(
        width: _rangePickerWidth,
        height: _rangeInputHeight,
      ),
    );
  }

  Widget _buildRangeFormField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required TextStyle textStyle,
    required TextInputType? keyboardType,
    required List<TextInputFormatter>? inputFormatters,
    required TextInputAction action,
    required String? errorText,
    required bool from,
    required VoidCallback onChanged,
    required ValueChanged<String>? onSubmitted,
    required ColorScheme colorScheme,
  }) {
    final errorStyle =
        Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.error) ??
        TextStyle(color: colorScheme.error, fontSize: 12);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        _buildRangeTextFieldWithPicker(
          context,
          controller: controller,
          focusNode: focusNode,
          textStyle: textStyle,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          action: action,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          from: from,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: _rangeErrorLineHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: errorText == null
                ? const SizedBox.shrink()
                : Text(
                    errorText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: errorStyle,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRangePanel(BuildContext context) {
    final callbacks = widget.callbacks;
    final translations = FdcApp.translationsOf(context);
    final textStyle = callbacks.headerFilterTextStyleOf(context);
    final colorScheme = Theme.of(context).colorScheme;
    final popupStyle = FdcGridTheme.resolveData(
      context,
      null,
    ).popupMenu.resolve();
    final codec = FdcFieldValueCodec(
      settings: FdcApp.formatsOf(context),
      translations: FdcApp.translationsOf(context),
    );
    final inputFormatters = codec.inputFormattersForGridColumn(
      widget.column,
      runtimeColumnId: widget.runtimeColumnId,
      decimalScale: callbacks.decimalScaleOf(widget.column),
      decimalPrecision: callbacks.decimalPrecisionOf(widget.column),
    );
    final keyboardType = codec.keyboardTypeForGridColumn(
      widget.column,
      runtimeColumnId: widget.runtimeColumnId,
    );

    return Builder(
      builder: (menuContext) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) => _handleRangePanelKeyEvent(menuContext, event),
        child: FocusTraversalGroup(
          child: SizedBox(
            width: _rangePanelWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRangeFormField(
                    context,
                    label: FdcApp.translationsOf(context).grid.rangeFrom,
                    controller: _fromController,
                    focusNode: _fromFocusNode,
                    textStyle: textStyle.copyWith(color: popupStyle.textColor),
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    action: TextInputAction.next,
                    errorText: _fromErrorText,
                    from: true,
                    onChanged: () => _handleDraftTextChanged(from: true),
                    onSubmitted: (_) {
                      _normalizeDraftField(from: true);
                      _toFocusNode.requestFocus();
                    },
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 2),
                  _buildRangeFormField(
                    context,
                    label: FdcApp.translationsOf(context).grid.rangeTo,
                    controller: _toController,
                    focusNode: _toFocusNode,
                    textStyle: textStyle.copyWith(color: popupStyle.textColor),
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    action: TextInputAction.done,
                    errorText: _toErrorText,
                    from: false,
                    onChanged: () => _handleDraftTextChanged(from: false),
                    onSubmitted: (_) => _apply(menuContext),
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        TextButton(
                          style: _headerFilterPopupCancelButtonStyle(),
                          onPressed: () => _cancel(menuContext),
                          child: Text(translations.common.cancel),
                        ),
                        FilledButton(
                          style: _headerFilterPopupApplyButtonStyle(),
                          onPressed: _canApplyDraft(context)
                              ? () => _apply(menuContext)
                              : null,
                          child: Text(translations.common.apply),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeTextFieldWithPicker(
    BuildContext context, {
    required TextEditingController controller,
    required FocusNode focusNode,
    required TextStyle textStyle,
    required TextInputType? keyboardType,
    required List<TextInputFormatter>? inputFormatters,
    required TextInputAction action,
    required VoidCallback onChanged,
    required ValueChanged<String>? onSubmitted,
    required bool from,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      height: _rangeInputHeight,
      child: TextSelectionTheme(
        data: TextSelectionTheme.of(context).copyWith(
          cursorColor: colorScheme.primary,
          selectionColor: colorScheme.primary.withAlpha(56),
          selectionHandleColor: colorScheme.primary,
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          cursorColor: colorScheme.primary,
          dragStartBehavior: DragStartBehavior.down,
          scrollPhysics: const NeverScrollableScrollPhysics(),
          textAlignVertical: TextAlignVertical.center,
          textInputAction: action,
          decoration: _rangeInputDecoration(
            context,
            from: from,
            colorScheme: colorScheme,
            showPicker: _showsRangePicker,
          ),
          onChanged: (_) => onChanged(),
          onSubmitted: onSubmitted,
        ),
      ),
    );
  }

  String _summaryText(FdcTranslations translations) {
    final range = _range;
    final from = _textOf(range?.from).trim();
    final to = _textOf(range?.to).trim();
    if (from.isEmpty && to.isEmpty) {
      return translations.common.all;
    }
    if (from.isEmpty) {
      return '≤ $to';
    }
    if (to.isEmpty) {
      return '≥ $from';
    }
    return '$from – $to';
  }

  String _summaryTooltipText(FdcTranslations translations) {
    final text = _summaryText(translations);
    return text == translations.common.all
        ? translations.grid.noRangeFilter
        : text;
  }
}

class FdcGridHeaderCheckboxFilterEditor extends StatelessWidget {
  const FdcGridHeaderCheckboxFilterEditor({
    super.key,
    required this.model,
    required this.callbacks,
    required this.column,
    required this.runtimeColumnId,
    required this.fillColor,
    required this.style,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final FdcGridColumn<dynamic> column;
  final FdcColumnIdentity runtimeColumnId;
  final Color fillColor;
  final FdcGridHeaderFilterStyle style;

  @override
  Widget build(BuildContext context) {
    final translations = FdcApp.translationsOf(context);
    final operator = callbacks.headerFilterOperatorOf(column, runtimeColumnId);
    final active = callbacks.isHeaderFilterActive(column, runtimeColumnId);
    final displayText = !active
        ? translations.common.all
        : callbacks.filterOperatorLabel(operator);
    final focusNode = callbacks.headerFilterFocusNodeOf(
      column,
      runtimeColumnId,
    );
    final enabled = callbacks.canOpenFilterMenu();
    final textStyle = callbacks.headerFilterTextStyleOf(context);
    final menuBuilder = FdcGridHeaderFilterMenuBuilder(
      callbacks: callbacks,
      column: column,
      runtimeColumnId: runtimeColumnId,
      translations: translations,
    );

    return FdcGridHeaderFilterShell(
      label: '',
      focusNode: focusNode,
      fillColor: fillColor,
      style: style,
      showClearButton: active,
      onClear: () => callbacks.onClearHeaderFilter(column, runtimeColumnId),
      overflowTooltipText: displayText,
      overflowTooltipTextStyle: textStyle,
      child: FdcMenuAnchor(
        openOnTap: enabled,
        openOnSecondaryTap: false,
        consumeSecondaryTap: false,
        openAtAnchor: true,
        canOpen: callbacks.onOpenFilterMenu,
        onOpen: () {
          callbacks.onClearFocusedCell();
          callbacks.onFocusHeaderFilterField(column, runtimeColumnId);
        },
        entries: menuBuilder.buildEntries(),
        child: SizedBox.expand(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = _headerFilterCompactHorizontalPadding(
                constraints.maxWidth,
              );

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: double.infinity,
                    child: _FdcHeaderFilterOverflowText(
                      text: displayText,
                      style: textStyle,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
