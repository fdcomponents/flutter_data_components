// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/fdc_app.dart';
import '../../fdc_option.dart';
import '../../input/fdc_key_utils.dart';
import '../../theme/fdc_editor_styles.dart';
import 'fdc_combo_popup.dart';
import 'fdc_combo_search_options.dart';
import 'fdc_combo_selection.dart';

@internal
class FdcComboField<T> extends StatefulWidget {
  const FdcComboField({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.style,
    this.strutStyle,
    this.hintText,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.showSelectedOptionCheckmark = true,
    this.showNullOptionLabel = true,
    this.search = const FdcComboSearchOptions(),
    this.searchHintText,
    this.maxPopupItems = 8,
    this.tapRegionGroupId,
    this.iconSize = 18,
    this.iconColor,
    this.popupStyle = const FdcEditorComboPopupStyle(),
    this.minPopupWidth = 160,
    this.itemHeight = 44,
    this.maxPopupHeight = 320,
    this.searchFieldHeight = 38,
    this.openOnSpace = true,
    this.openOnEnter = true,
    this.requestFocusOnSelection = true,
    this.onKeyEvent,
    this.onTap,
    this.onOpened,
    this.onDismissed,
    this.optionBuilder,
  });

  final List<FdcOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final FocusNode? focusNode;
  final InputDecoration decoration;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final String? hintText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool showSelectedOptionCheckmark;
  final bool showNullOptionLabel;
  final FdcComboSearchOptions search;
  final String? searchHintText;
  final int maxPopupItems;
  final Object? tapRegionGroupId;
  final double iconSize;
  final Color? iconColor;
  final FdcEditorComboPopupStyle popupStyle;
  final double minPopupWidth;
  final double itemHeight;
  final double maxPopupHeight;
  final double searchFieldHeight;
  final bool openOnSpace;
  final bool openOnEnter;
  final bool requestFocusOnSelection;
  final KeyEventResult Function(FocusNode node, KeyEvent event)? onKeyEvent;
  final VoidCallback? onTap;
  final VoidCallback? onOpened;
  final VoidCallback? onDismissed;
  final Widget Function(BuildContext context, FdcOption<T> option)?
  optionBuilder;

  @override
  State<FdcComboField<T>> createState() => FdcComboFieldState<T>();
}

@internal
class FdcComboFieldState<T> extends State<FdcComboField<T>> {
  bool _dropdownOpen = false;
  T? _valueOverride;
  bool _hasValueOverride = false;

  bool get _canOpen => widget.enabled && !widget.readOnly;

  T? get _effectiveValue => _hasValueOverride ? _valueOverride : widget.value;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant FdcComboField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChanged);
      widget.focusNode?.addListener(_handleFocusChanged);
    }
    if (oldWidget.value != widget.value) {
      _hasValueOverride = false;
      _valueOverride = null;
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        cursor: _canOpen ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _canOpen ? _handleTap : null,
          child: InputDecorator(
            decoration: widget.decoration,
            isFocused: widget.focusNode?.hasFocus ?? false,
            isEmpty: _selectedOption() == null,
            child: _buildFieldContent(context),
          ),
        ),
      ),
    );

    if (widget.tapRegionGroupId == null) {
      return field;
    }

    return TapRegion(groupId: widget.tapRegionGroupId, child: field);
  }

  Widget _buildFieldContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final showDropdownIcon = availableWidth >= widget.iconSize;
        return Row(
          children: [
            Expanded(child: _buildSelectedContent(context)),
            if (showDropdownIcon)
              Icon(
                Icons.arrow_drop_down,
                size: widget.iconSize,
                color: widget.iconColor,
              ),
          ],
        );
      },
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!FdcKeyUtils.isKeyDownOrRepeat(event)) {
      return KeyEventResult.ignored;
    }

    final shouldOpen =
        (widget.openOnSpace && FdcKeyUtils.isSpace(event)) ||
        widget.openOnEnter && FdcKeyUtils.isEnter(event);

    if (shouldOpen) {
      unawaited(openDropdownMenu());
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isEscape(event) && _dropdownOpen) {
      return KeyEventResult.handled;
    }

    return widget.onKeyEvent?.call(node, event) ?? KeyEventResult.ignored;
  }

  void _handleTap() {
    widget.onTap?.call();
    widget.focusNode?.requestFocus();
    unawaited(openDropdownMenu());
  }

  FdcOption<T>? _selectedOption() {
    final value = _effectiveValue;
    if (value == null && !widget.showNullOptionLabel) {
      return null;
    }
    for (final option in widget.options) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }

  Widget _buildSelectedContent(BuildContext context) {
    final option = _selectedOption();
    if (option != null && widget.optionBuilder != null) {
      return widget.optionBuilder!(context, option);
    }
    return Text(
      _label(),
      overflow: TextOverflow.ellipsis,
      style: widget.style,
      strutStyle: widget.strutStyle,
    );
  }

  String _label() {
    final option = _selectedOption();
    if (option != null) {
      return option.label;
    }
    return widget.hintText ?? '';
  }

  Future<void> openDropdownMenu() async {
    if (_dropdownOpen || !_canOpen) {
      return;
    }

    final renderBox = context.findRenderObject() as RenderBox?;
    final overlayState = Overlay.maybeOf(context);
    final overlay = overlayState?.context.findRenderObject() as RenderBox?;
    if (renderBox == null ||
        overlayState == null ||
        overlay == null ||
        !renderBox.hasSize) {
      return;
    }

    final topLeft = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = topLeft & renderBox.size;
    _dropdownOpen = true;
    widget.onOpened?.call();

    try {
      final selectedValue = _effectiveValue;
      final initialIndex = widget.options.indexWhere(
        (option) => option.value == selectedValue,
      );
      final selection = await _showDropdownPopup(
        overlayState: overlayState,
        rect: rect,
        overlaySize: overlay.size,
        selectedValue: selectedValue,
        initialIndex: initialIndex < 0 ? 0 : initialIndex,
      );
      if (selection != null && mounted) {
        _hasValueOverride = true;
        _valueOverride = selection.value;
        setState(() {});
        widget.onChanged(selection.value);
        if (widget.requestFocusOnSelection) {
          widget.focusNode?.requestFocus();
        }
      }
    } finally {
      _dropdownOpen = false;
      widget.onDismissed?.call();
    }
  }

  Future<FdcComboSelection<T>?> _showDropdownPopup({
    required OverlayState overlayState,
    required Rect rect,
    required Size overlaySize,
    required T? selectedValue,
    required int initialIndex,
  }) {
    final completer = Completer<FdcComboSelection<T>?>();
    late final OverlayEntry entry;
    var removed = false;

    void close(FdcComboSelection<T>? value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
      if (!removed) {
        removed = true;
        entry.remove();
      }
    }

    entry = OverlayEntry(
      builder: (context) {
        final popup = FdcComboPopup<T>(
          options: widget.options,
          rect: rect,
          overlaySize: overlaySize,
          selectedValue: selectedValue,
          initialIndex: initialIndex,
          showSelectedOptionCheckmark: widget.showSelectedOptionCheckmark,
          search: widget.search,
          searchHintText:
              widget.searchHintText ??
              FdcApp.translationsOf(context).common.search,
          emptyResultText: FdcApp.translationsOf(context).common.noResults,
          maxPopupItems: widget.maxPopupItems,
          minWidth: widget.minPopupWidth,
          itemHeight: widget.itemHeight,
          maxHeight: widget.maxPopupHeight,
          searchFieldHeight: widget.searchFieldHeight,
          style: widget.popupStyle,
          onSelected: (value) => close(FdcComboSelection<T>(value)),
          onDismissed: () => close(null),
          optionBuilder: widget.optionBuilder,
        );

        if (widget.tapRegionGroupId == null) {
          return popup;
        }

        return TapRegion(groupId: widget.tapRegionGroupId, child: popup);
      },
    );

    overlayState.insert(entry);
    return completer.future;
  }
}
