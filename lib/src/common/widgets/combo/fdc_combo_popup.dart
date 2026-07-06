// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/fdc_app.dart';
import '../../fdc_option.dart';
import '../../input/fdc_key_utils.dart';
import '../../theme/fdc_editor_styles.dart';
import 'fdc_combo_entry.dart';
import 'fdc_combo_search_options.dart';

@visibleForTesting
List<FdcComboEntry<T>> fdcFilterComboEntriesForSearch<T>(
  List<FdcOption<T>> options,
  String searchText, {
  FdcComboSearchMode mode = FdcComboSearchMode.startsWith,
}) {
  final query = searchText.trim().toLowerCase();
  final entries = <FdcComboEntry<T>>[];
  for (var index = 0; index < options.length; index++) {
    final option = options[index];
    final label = option.label.toLowerCase();
    final matches = switch (mode) {
      FdcComboSearchMode.startsWith => label.startsWith(query),
      FdcComboSearchMode.contains => label.contains(query),
    };
    if (query.isEmpty || matches) {
      entries.add(FdcComboEntry<T>(index: index, option: option));
    }
  }
  return entries;
}

@visibleForTesting
int? fdcNextComboPopupHighlightIndex<T>(
  List<FdcComboEntry<T>> entries,
  int start,
  int offset,
) {
  if (entries.isEmpty || offset == 0) {
    return null;
  }

  final step = offset.isNegative ? -1 : 1;
  var index = start;
  if (start < 0) {
    index = step > 0 ? -1 : entries.length;
  } else if (start >= entries.length) {
    index = entries.length - 1;
  }

  index += step;
  if (index < 0 || index >= entries.length) {
    return null;
  }
  return index;
}

@visibleForTesting
int? fdcComboPopupBoundaryHighlightIndex<T>(
  List<FdcComboEntry<T>> entries, {
  required bool last,
}) {
  if (entries.isEmpty) {
    return null;
  }

  return last ? entries.length - 1 : 0;
}

@visibleForTesting
int? fdcComboPopupPageHighlightIndex<T>(
  List<FdcComboEntry<T>> entries,
  int start,
  int direction,
  int pageSize,
) {
  if (entries.isEmpty || direction == 0 || pageSize <= 0) {
    return null;
  }

  final lastIndex = entries.length - 1;
  final effectiveStart = start.clamp(0, lastIndex).toInt();
  final signedPage = direction.isNegative ? -pageSize : pageSize;
  final target = (effectiveStart + signedPage).clamp(0, lastIndex).toInt();

  return target;
}

@visibleForTesting
bool fdcComboPopupAbsorbsTraversalKey(KeyEvent event) {
  return FdcKeyUtils.isKeyDownOrRepeat(event) && FdcKeyUtils.isTab(event);
}

@visibleForTesting
bool fdcComboPopupKeepsSearchNavigationLocal(KeyEvent event) {
  if (!FdcKeyUtils.isKeyDownOrRepeat(event)) {
    return false;
  }
  return FdcKeyUtils.isHome(event) ||
      FdcKeyUtils.isEnd(event) ||
      FdcKeyUtils.isPageUp(event) ||
      FdcKeyUtils.isPageDown(event);
}

@visibleForTesting
String? fdcComboPopupInlineSearchCharacter(KeyEvent event) {
  if (!FdcKeyUtils.isKeyDownOrRepeat(event)) {
    return null;
  }

  // Keep this helper pure/test-friendly. Runtime modifier-state checks are
  // handled by the popup key handler, where Flutter bindings are initialized.
  final character = switch (event) {
    final KeyDownEvent event => event.character,
    final KeyRepeatEvent event => event.character,
    _ => null,
  };
  if (character == null || character.isEmpty) {
    return null;
  }

  final runes = character.runes.toList(growable: false);
  if (runes.length != 1) {
    return null;
  }

  final value = String.fromCharCode(runes.single);
  if (value == ' ') {
    return value;
  }
  if (value.trim().isEmpty) {
    return null;
  }

  return value;
}

@internal
class FdcComboPopup<T> extends StatefulWidget {
  const FdcComboPopup({
    super.key,
    required this.options,
    required this.rect,
    required this.overlaySize,
    required this.selectedValue,
    required this.initialIndex,
    required this.showSelectedOptionCheckmark,
    required this.search,
    required this.searchHintText,
    required this.emptyResultText,
    required this.maxPopupItems,
    required this.minWidth,
    required this.itemHeight,
    required this.maxHeight,
    required this.searchFieldHeight,
    required this.style,
    required this.onSelected,
    required this.onDismissed,
    this.optionBuilder,
  });

  final List<FdcOption<T>> options;
  final Rect rect;
  final Size overlaySize;
  final T? selectedValue;
  final int initialIndex;
  final bool showSelectedOptionCheckmark;
  final FdcComboSearchOptions search;
  final String searchHintText;
  final String emptyResultText;
  final int maxPopupItems;
  final double minWidth;
  final double itemHeight;
  final double maxHeight;
  final double searchFieldHeight;
  final FdcEditorComboPopupStyle style;
  final ValueChanged<T?> onSelected;
  final VoidCallback onDismissed;
  final Widget Function(BuildContext context, FdcOption<T> option)?
  optionBuilder;

  @override
  State<FdcComboPopup<T>> createState() => _FdcComboPopupState<T>();
}

class _FdcComboPopupState<T> extends State<FdcComboPopup<T>> {
  late final FocusNode _popupFocusNode;
  late final FocusNode _searchFocusNode;
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  late int _highlightIndex;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _popupFocusNode = FocusNode(onKeyEvent: _handlePopupKeyEvent);
    _searchFocusNode = FocusNode(onKeyEvent: _handleSearchKeyEvent);
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _searchFocusNode.addListener(_handleFocusChanged);
    _popupFocusNode.addListener(_handleFocusChanged);
    _highlightIndex = _initialHighlightIndex(_visibleEntries);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _popupFocusNode.requestFocus();
      _scrollHighlightedIntoView();
    });
  }

  @override
  void dispose() {
    _popupFocusNode.removeListener(_handleFocusChanged);
    _searchFocusNode.removeListener(_handleFocusChanged);
    _popupFocusNode.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<FdcComboEntry<T>> get _visibleEntries => fdcFilterComboEntriesForSearch(
    widget.options,
    _searchText,
    mode: widget.search.mode,
  );

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries;
    final availableBelow = widget.overlaySize.height - widget.rect.bottom - 8;
    final maxPopupItems = math.max(1, widget.maxPopupItems);
    final visibleItemCount = math.max(
      1,
      math.min(maxPopupItems, entries.length),
    );
    final searchHeight = widget.search.searchable
        ? widget.searchFieldHeight
        : 0.0;
    final preferredListHeight = visibleItemCount * widget.itemHeight;
    final hasScrollableItems = entries.length > maxPopupItems;
    final preferredHeight = math.min(
      widget.maxHeight,
      searchHeight + preferredListHeight,
    );
    final openAbove =
        availableBelow < math.min(preferredHeight, widget.itemHeight * 2) &&
        widget.rect.top > availableBelow;
    final availableHeight = openAbove ? widget.rect.top - 8 : availableBelow;
    final height = math.max(0.0, math.min(preferredHeight, availableHeight));
    final top = openAbove
        ? math.max(8.0, widget.rect.top - height)
        : widget.rect.bottom;
    final listHeight = math.max(0.0, height - searchHeight);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismissed,
          ),
        ),
        Positioned(
          left: widget.rect.left,
          top: top,
          width: math.max(widget.rect.width, widget.minWidth),
          child: Focus(
            focusNode: _popupFocusNode,
            child: Material(
              elevation: widget.style.elevation ?? 8,
              color: widget.style.backgroundColor,
              surfaceTintColor: widget.style.surfaceTintColor,
              shadowColor: widget.style.shadowColor,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius:
                    widget.style.borderRadius ?? BorderRadius.circular(4),
                side: BorderSide(
                  color: widget.style.borderColor ?? Colors.transparent,
                ),
              ),
              child: SizedBox(
                height: height,
                child: Column(
                  children: [
                    if (widget.search.searchable) _buildSearchBox(context),
                    SizedBox(
                      height: listHeight,
                      child: entries.isEmpty
                          ? _buildEmptyResult(context)
                          : Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: hasScrollableItems,
                              trackVisibility: hasScrollableItems,
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.zero,
                                itemExtent: widget.itemHeight,
                                itemCount: entries.length,
                                itemBuilder: (context, index) =>
                                    _buildItem(context, entries, index),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadiusGeometry =
        widget.style.searchBorderRadius ?? BorderRadius.circular(4);
    final borderRadius = borderRadiusGeometry.resolve(
      Directionality.of(context),
    );
    final enabledBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color:
            widget.style.searchBorderColor ??
            theme.colorScheme.outlineVariant.withValues(alpha: 0.70),
        width: widget.style.searchBorderWidth ?? 0.8,
      ),
    );
    return SizedBox(
      height: widget.searchFieldHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 5, 8, 3),
        child: TextField(
          focusNode: _searchFocusNode,
          controller: _searchController,
          style:
              theme.textTheme.bodySmall?.merge(widget.style.searchTextStyle) ??
              widget.style.searchTextStyle,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.searchHintText,
            hintStyle:
                theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor)
                    .merge(widget.style.searchHintStyle) ??
                widget.style.searchHintStyle,
            prefixIcon: Icon(
              Icons.search,
              size: 16,
              color:
                  widget.style.searchIconColor ??
                  theme.colorScheme.onSurfaceVariant,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 28,
            ),
            filled: widget.style.searchFillColor != null,
            fillColor: widget.style.searchFillColor,
            suffixIcon: _searchText.isEmpty
                ? null
                : IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 15,
                      color: widget.style.searchClearIconColor,
                    ),
                    tooltip: FdcApp.translationsOf(context).common.clear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _clearSearchText(syncController: false);
                      _searchFocusNode.requestFocus();
                    },
                  ),
            border: enabledBorder,
            enabledBorder: enabledBorder,
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(
                color:
                    widget.style.searchFocusedBorderColor ??
                    theme.colorScheme.primary.withValues(alpha: 0.75),
                width: widget.style.searchFocusedBorderWidth ?? 0.9,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 6,
            ),
          ),
          onChanged: _setSearchText,
        ),
      ),
    );
  }

  Widget _buildEmptyResult(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: widget.itemHeight,
      child: Center(
        child: Text(
          widget.emptyResultText,
          style:
              theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.disabledColor)
                  .merge(widget.style.emptyTextStyle) ??
              widget.style.emptyTextStyle,
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    List<FdcComboEntry<T>> entries,
    int index,
  ) {
    final option = entries[index].option;
    final theme = Theme.of(context);
    final highlighted = _showItemFocusHighlight && index == _highlightIndex;
    final selected = option.value == widget.selectedValue;
    final textStyle =
        theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurface)
            .merge(widget.style.itemTextStyle) ??
        widget.style.itemTextStyle;
    final textColor =
        textStyle?.color ??
        widget.style.selectedIconColor ??
        theme.colorScheme.onSurface;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (_highlightIndex != index) {
          setState(() => _highlightIndex = index);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelected(option.value),
        child: Container(
          color: highlighted
              ? widget.style.highlightedItemColor ??
                    theme.colorScheme.primary.withValues(alpha: 0.10)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              SizedBox(
                width: widget.showSelectedOptionCheckmark ? 24 : 0,
                child: widget.showSelectedOptionCheckmark && selected
                    ? Icon(
                        Icons.check,
                        size: 18,
                        color: widget.style.selectedIconColor ?? textColor,
                      )
                    : null,
              ),
              Expanded(
                child:
                    widget.optionBuilder?.call(context, option) ??
                    Text(
                      option.label,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _showItemFocusHighlight => !_searchFocusNode.hasFocus;

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setSearchText(String value) {
    _setSearchTextInternal(value, syncController: false);
  }

  void _setSearchTextInternal(String value, {required bool syncController}) {
    setState(() {
      _searchText = value;
      _highlightIndex = _initialHighlightIndex(_visibleEntries);
    });
    if (syncController && _searchController.text != value) {
      _searchController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    _scrollHighlightedIntoView();
  }

  void _clearSearchText({required bool syncController}) {
    _setSearchTextInternal('', syncController: syncController);
  }

  int _initialHighlightIndex(List<FdcComboEntry<T>> entries) {
    if (entries.isEmpty) {
      return -1;
    }

    final selectedVisibleIndex = entries.indexWhere(
      (entry) => entry.option.value == widget.selectedValue,
    );
    if (selectedVisibleIndex >= 0) {
      return selectedVisibleIndex;
    }

    final clampedInitial = widget.initialIndex.clamp(
      0,
      widget.options.length - 1,
    );
    final initialVisibleIndex = entries.indexWhere(
      (entry) => entry.index == clampedInitial,
    );
    if (initialVisibleIndex >= 0) {
      return initialVisibleIndex;
    }

    return 0;
  }

  KeyEventResult _handlePopupKeyEvent(FocusNode node, KeyEvent event) {
    if (fdcComboPopupAbsorbsTraversalKey(event)) {
      return KeyEventResult.handled;
    }

    if (_searchFocusNode.hasFocus &&
        fdcComboPopupKeepsSearchNavigationLocal(event)) {
      return KeyEventResult.handled;
    }

    return _handleListKeyEvent(event);
  }

  KeyEventResult _handleSearchKeyEvent(FocusNode node, KeyEvent event) {
    if (fdcComboPopupAbsorbsTraversalKey(event)) {
      return KeyEventResult.handled;
    }

    if (!FdcKeyUtils.isKeyDownOrRepeat(event)) {
      return KeyEventResult.ignored;
    }

    if (FdcKeyUtils.isArrowDown(event)) {
      _focusFirstPopupItem();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isEnter(event) || FdcKeyUtils.isEscape(event)) {
      return _handleListKeyEvent(event);
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleListKeyEvent(KeyEvent event) {
    if (fdcComboPopupAbsorbsTraversalKey(event)) {
      return KeyEventResult.handled;
    }

    if (!FdcKeyUtils.isKeyDownOrRepeat(event)) {
      return KeyEventResult.ignored;
    }

    if (FdcKeyUtils.isArrowDown(event)) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isArrowUp(event)) {
      if (_focusSearchFromFirstItem()) {
        return KeyEventResult.handled;
      }
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isHome(event)) {
      _moveHighlightToBoundary(last: false);
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isEnd(event)) {
      _moveHighlightToBoundary(last: true);
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isPageDown(event)) {
      _moveHighlightPage(1);
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isPageUp(event)) {
      _moveHighlightPage(-1);
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isEnter(event)) {
      _selectHighlighted();
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isSpace(event)) {
      if (_handleInlineSearchKey(event)) {
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    if (FdcKeyUtils.isEscape(event)) {
      widget.onDismissed();
      return KeyEventResult.handled;
    }

    if (_handleInlineSearchKey(event)) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  String _removeLastSearchChar(String value) {
    final runes = value.runes.toList(growable: false);
    if (runes.isEmpty) {
      return '';
    }
    return String.fromCharCodes(runes.take(runes.length - 1));
  }

  bool _handleInlineSearchKey(KeyEvent event) {
    if (!widget.search.searchableInline) {
      return false;
    }

    if (event is KeyDownEvent &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isAltPressed)) {
      return false;
    }

    if (event is KeyDownEvent && FdcKeyUtils.isBackspace(event)) {
      if (_searchText.isEmpty) {
        return false;
      }
      _setSearchTextInternal(
        _removeLastSearchChar(_searchText),
        syncController: widget.search.searchable,
      );
      return true;
    }

    final character = fdcComboPopupInlineSearchCharacter(event);
    if (character == null) {
      return false;
    }

    _setSearchTextInternal(
      '$_searchText$character',
      syncController: widget.search.searchable,
    );
    return true;
  }

  void _moveHighlight(int offset) {
    final entries = _visibleEntries;
    final next = _nextOptionIndex(entries, _highlightIndex, offset);
    _setHighlightIndex(next);
  }

  void _moveHighlightToBoundary({required bool last}) {
    final next = fdcComboPopupBoundaryHighlightIndex(
      _visibleEntries,
      last: last,
    );
    _setHighlightIndex(next);
  }

  void _moveHighlightPage(int direction) {
    final next = fdcComboPopupPageHighlightIndex(
      _visibleEntries,
      _highlightIndex,
      direction,
      math.max(1, widget.maxPopupItems),
    );
    _setHighlightIndex(next);
  }

  void _setHighlightIndex(int? next) {
    if (next == null || next == _highlightIndex) {
      return;
    }
    setState(() => _highlightIndex = next);
    _scrollHighlightedIntoView();
  }

  void _focusFirstPopupItem() {
    final entries = _visibleEntries;
    final firstOption = _firstOptionIndex(entries);
    if (firstOption == null) {
      return;
    }
    _popupFocusNode.requestFocus();
    if (_highlightIndex != firstOption) {
      setState(() => _highlightIndex = firstOption);
    }
    _scrollHighlightedIntoView();
  }

  bool _focusSearchFromFirstItem() {
    if (!widget.search.searchable || !_popupFocusNode.hasPrimaryFocus) {
      return false;
    }

    final firstOption = _firstOptionIndex(_visibleEntries);
    if (firstOption == null || _highlightIndex != firstOption) {
      return false;
    }

    _searchFocusNode.requestFocus();
    return true;
  }

  int? _firstOptionIndex(List<FdcComboEntry<T>> entries) {
    return entries.isEmpty ? null : 0;
  }

  int? _nextOptionIndex(
    List<FdcComboEntry<T>> entries,
    int start,
    int offset,
  ) => fdcNextComboPopupHighlightIndex(entries, start, offset);

  void _selectHighlighted() {
    final entries = _visibleEntries;
    if (_highlightIndex < 0 || _highlightIndex >= entries.length) {
      return;
    }
    widget.onSelected(entries[_highlightIndex].option.value);
  }

  void _scrollHighlightedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients || _highlightIndex < 0) {
        return;
      }
      final position = _scrollController.position;
      final itemTop = _highlightIndex * widget.itemHeight;
      final itemBottom = itemTop + widget.itemHeight;
      final viewportTop = position.pixels;
      final viewportBottom = viewportTop + position.viewportDimension;
      var target = viewportTop;

      if (itemTop < viewportTop) {
        target = itemTop;
      } else if (itemBottom > viewportBottom) {
        target = itemBottom - position.viewportDimension;
      } else {
        return;
      }

      _scrollController.jumpTo(
        target
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble(),
      );
    });
  }
}
