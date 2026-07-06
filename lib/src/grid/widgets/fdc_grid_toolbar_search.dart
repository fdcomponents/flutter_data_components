// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../app/fdc_app.dart';
import '../../common/menu/fdc_menu.dart';
import '../../common/theme/fdc_grid_styles.dart';
import '../../data/fdc_dataset_search.dart';
import '../controllers/fdc_debounce_controller.dart';
import '../core/fdc_grid_core.dart';

class FdcGridToolbarSearchController {
  FdcGridToolbarSearchController();
  FdcGridToolbarSearchState? _state;

  bool get isAttached => _state != null;

  bool get hasFocus => _state?._focusNode.hasFocus ?? false;

  bool openAndFocus({VoidCallback? onClosedByEscape}) {
    final state = _state;
    if (state == null) {
      return false;
    }

    state.openAndFocus(onClosedByEscape: onClosedByEscape);
    return true;
  }

  bool clearSilently({bool collapse = true}) {
    final state = _state;
    if (state == null) {
      return false;
    }

    state.clearSilently(collapse: collapse);
    return true;
  }

  void _attach(FdcGridToolbarSearchState state) {
    _state = state;
  }

  void _detach(FdcGridToolbarSearchState state) {
    if (identical(_state, state)) {
      _state = null;
    }
  }
}

class FdcGridToolbarSearch extends StatefulWidget {
  const FdcGridToolbarSearch({
    super.key,
    required this.style,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.mode,
    required this.matchMode,
    required this.caseSensitive,
    required this.debounceDuration,
    required this.debouncePolicy,
    required this.recordCountProvider,
    required this.enabled,
    this.controller,
  });

  final FdcGridToolbarStyle style;
  final void Function(
    String text, {
    required FdcSearchMode mode,
    required bool caseSensitive,
  })
  onSearchChanged;
  final VoidCallback onSearchCleared;
  final FdcGridSearchBarMode mode;
  final FdcSearchMode matchMode;
  final bool caseSensitive;
  final Duration debounceDuration;
  final FdcDebouncePolicy debouncePolicy;
  final int Function() recordCountProvider;
  final bool enabled;
  final FdcGridToolbarSearchController? controller;

  @override
  State<FdcGridToolbarSearch> createState() => FdcGridToolbarSearchState();
}

class FdcGridToolbarSearchState extends State<FdcGridToolbarSearch>
    with SingleTickerProviderStateMixin {
  static const Duration _expandDuration = Duration(milliseconds: 240);
  static const Curve _expandCurve = Curves.easeOutCubic;
  static const Curve _collapseCurve = Curves.easeInOutCubic;

  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode;
  late final FdcDebounceController _debounce;
  late final AnimationController _widthController;
  late FdcSearchMode _matchMode;
  late bool _caseSensitive;
  late FdcDebouncePolicy _debouncePolicy;

  String _lastObservedText = '';
  String _lastSubmittedText = '';
  VoidCallback? _onClosedByEscape;

  final Set<LogicalKeyboardKey> _pressedTextEditingKeys =
      <LogicalKeyboardKey>{};
  bool _hasDeferredTextChange = false;

  bool _expanded = false;
  bool _showExpandedField = false;
  bool _searchOptionsMenuOpen = false;
  bool _searchOptionsCloseSettling = false;
  bool _searchOptionsKeepFocusAfterClose = false;
  bool _suppressNextTextChange = false;

  bool get _showAdvancedControls =>
      widget.mode == FdcGridSearchBarMode.advanced;

  double get _trailingActionsWidth {
    final clearWidth = _controller.text.isNotEmpty ? 28.0 : 0.0;
    final advancedWidth = _showAdvancedControls ? 56.0 : 0.0;
    return clearWidth + advancedWidth;
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(onKeyEvent: _handleKeyEvent);
    _widthController = AnimationController(
      vsync: this,
      duration: _expandDuration,
      reverseDuration: _expandDuration,
    )..addStatusListener(_handleWidthAnimationStatus);
    _matchMode = widget.matchMode;
    _caseSensitive = widget.caseSensitive;
    _debouncePolicy = widget.debouncePolicy;
    _debounce = FdcDebounceController(
      policy: _debouncePolicy,
      baseDelay: widget.debounceDuration,
      recordCountProvider: widget.recordCountProvider,
    );
    _controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant FdcGridToolbarSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    final searchConfigChanged =
        oldWidget.matchMode != widget.matchMode ||
        oldWidget.caseSensitive != widget.caseSensitive;
    if (oldWidget.matchMode != widget.matchMode) {
      _matchMode = widget.matchMode;
    }
    if (oldWidget.caseSensitive != widget.caseSensitive) {
      _caseSensitive = widget.caseSensitive;
    }
    if (oldWidget.debouncePolicy != widget.debouncePolicy) {
      _debouncePolicy = widget.debouncePolicy;
    }

    _debounce.update(
      policy: _debouncePolicy,
      baseDelay: widget.debounceDuration,
      recordCountProvider: widget.recordCountProvider,
    );

    if (searchConfigChanged) {
      _resubmitSearchWithCurrentOptions(restoreFocus: false);
    }

    if (!identical(widget.controller, oldWidget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }

    if (!widget.enabled && oldWidget.enabled) {
      _debounce.cancel();
      _pressedTextEditingKeys.clear();
      _hasDeferredTextChange = false;
      _focusNode.unfocus();
      if (_controller.text.isEmpty && (_expanded || _showExpandedField)) {
        _expanded = false;
        _showExpandedField = true;
        unawaited(_widthController.reverse());
      }
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _debounce.dispose();
    _focusNode.removeListener(_handleFocusChanged);
    _controller.removeListener(_handleTextChanged);
    _widthController
      ..removeStatusListener(_handleWidthAnimationStatus)
      ..dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    final text = _controller.text;

    if (_suppressNextTextChange) {
      _suppressNextTextChange = false;
      _lastObservedText = text;
      return;
    }

    if (text == _lastObservedText) {
      return;
    }

    _lastObservedText = text;
    if (_pressedTextEditingKeys.isNotEmpty) {
      _hasDeferredTextChange = true;
      _debounce.cancel();
    } else if (_debouncePolicy != FdcDebouncePolicy.disabled) {
      _scheduleSearchChange(text);
    } else {
      _debounce.cancel();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _scheduleSearchChange(String text) {
    _submitOrScheduleSearchChange(text, submitImmediately: false);
  }

  void _submitSearchChange(String text, {bool force = false}) {
    _submitOrScheduleSearchChange(text, submitImmediately: true, force: force);
  }

  void _handleSearchSubmitted() {
    if (!widget.enabled) {
      return;
    }

    _submitSearchChange(_controller.text);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusNode.requestFocus();
    });
  }

  void _submitOrScheduleSearchChange(
    String text, {
    required bool submitImmediately,
    bool force = false,
  }) {
    _debounce.cancel();

    if (!widget.enabled) {
      return;
    }

    if (text.trim().isEmpty) {
      if (_lastSubmittedText.isEmpty) {
        return;
      }

      _lastSubmittedText = '';
      widget.onSearchCleared();
      return;
    }

    void submit() {
      if (!mounted || (!force && text == _lastSubmittedText)) {
        return;
      }

      _lastSubmittedText = text;
      widget.onSearchChanged(
        text,
        mode: _matchMode,
        caseSensitive: _caseSensitive,
      );
    }

    if (submitImmediately) {
      _debounce.submit(submit);
    } else {
      _debounce.schedule(submit, inputText: text);
    }
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _flushDeferredTextChange();
      _pressedTextEditingKeys.clear();
      if (!_searchOptionsMenuOpen) {
        _collapseIfEmpty();
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) {
      _handleTextEditingKeyUp(event.logicalKey);
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _pressedTextEditingKeys.clear();
      _hasDeferredTextChange = false;
      _handleEscape();
      return KeyEventResult.handled;
    }

    if (_debouncePolicy == FdcDebouncePolicy.disabled &&
        _isSearchSubmitKey(event.logicalKey)) {
      if (event is KeyRepeatEvent) {
        return KeyEventResult.handled;
      }

      _handleSearchSubmitted();
      return KeyEventResult.handled;
    }

    if (_isTextEditingKeyEvent(event)) {
      _pressedTextEditingKeys.add(event.logicalKey);
      if (event is KeyRepeatEvent) {
        _hasDeferredTextChange = true;
        _debounce.cancel();
      }
    }

    return KeyEventResult.ignored;
  }

  void _handleTextEditingKeyUp(LogicalKeyboardKey key) {
    if (!_pressedTextEditingKeys.remove(key) ||
        _pressedTextEditingKeys.isNotEmpty) {
      return;
    }

    _flushDeferredTextChange();
  }

  void _flushDeferredTextChange() {
    if (!_hasDeferredTextChange) {
      return;
    }

    _hasDeferredTextChange = false;
    final text = _controller.text;
    if (_debouncePolicy != FdcDebouncePolicy.disabled) {
      _scheduleSearchChange(text);
    } else {
      _debounce.cancel();
    }
  }

  bool _isSearchSubmitKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
  }

  bool _isTextEditingKeyEvent(KeyEvent event) {
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.space) {
      return true;
    }

    final character = event.character;
    return character != null && character.isNotEmpty;
  }

  void _handleWidthAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed ||
        _expanded ||
        !_showExpandedField) {
      return;
    }
    if (!mounted) {
      _showExpandedField = false;
      return;
    }
    setState(() {
      _showExpandedField = false;
    });
  }

  void _expandSearchField() {
    if (_expanded && _showExpandedField) {
      return;
    }
    setState(() {
      _showExpandedField = true;
      _expanded = true;
    });
    unawaited(_widthController.forward());
  }

  void _collapseSearchField() {
    if (!_expanded && !_showExpandedField) {
      return;
    }

    setState(() {
      _expanded = false;
      _showExpandedField = true;
    });
    unawaited(_widthController.reverse());
  }

  void _collapseSearchFieldImmediately() {
    _widthController.value = 0;
    if (!mounted) {
      _expanded = false;
      _showExpandedField = false;
      return;
    }
    setState(() {
      _expanded = false;
      _showExpandedField = false;
    });
  }

  bool get _isCollapsingSearchField =>
      _showExpandedField && !_expanded && _widthController.value > 0;

  bool get _showActiveSearchBorder =>
      _focusNode.hasFocus ||
      _searchOptionsMenuOpen ||
      _searchOptionsCloseSettling ||
      _isCollapsingSearchField;

  BorderRadius _searchFieldBorderRadius() {
    return BorderRadius.circular(widget.style.searchFieldBorderRadius ?? 2);
  }

  BorderSide _searchFieldBorderSide({required bool active}) {
    final borderWidth = widget.style.searchFieldBorderWidth ?? 1;
    final focusedBorderWidth =
        widget.style.searchFieldFocusedBorderWidth ?? borderWidth + 1;
    final searchBorderColor =
        widget.style.searchFieldBorderColor ??
        FdcGridStyle.defaultGridLineColor;
    final focusedSearchBorderColor =
        widget.style.searchFieldFocusedBorderColor ?? searchBorderColor;

    if (active) {
      return BorderSide(
        color: focusedSearchBorderColor,
        width: focusedBorderWidth,
      );
    }

    return BorderSide(color: searchBorderColor, width: borderWidth);
  }

  Widget _buildAnimatedSearchOutline() {
    return IgnorePointer(
      child: DecoratedBox(
        key: const ValueKey('fdc_grid_toolbar_search_animated_outline'),
        decoration: BoxDecoration(
          border: Border.fromBorderSide(
            _searchFieldBorderSide(active: _showActiveSearchBorder),
          ),
          borderRadius: _searchFieldBorderRadius(),
        ),
      ),
    );
  }

  double _trailingActionsVisibility(double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    if (_searchOptionsMenuOpen || _searchOptionsCloseSettling) {
      return 1;
    }
    if (!_showExpandedField) {
      return 0;
    }
    if (_expanded) {
      return ((clampedProgress - 0.50) / 0.50).clamp(0.0, 1.0).toDouble();
    }
    return ((clampedProgress - 0.72) / 0.28).clamp(0.0, 1.0).toDouble();
  }

  void _collapseIfEmpty() {
    if (!_expanded ||
        _searchOptionsMenuOpen ||
        _searchOptionsCloseSettling ||
        _controller.text.isNotEmpty) {
      return;
    }

    _collapseSearchField();
  }

  void openAndFocus({VoidCallback? onClosedByEscape}) {
    if (!widget.enabled) {
      return;
    }

    _onClosedByEscape = onClosedByEscape;

    if (!_expanded || !_showExpandedField) {
      _expandSearchField();
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _focusNode.requestFocus();
    });
  }

  void _clear() {
    if (!widget.enabled) {
      return;
    }

    _debounce.cancel();
    _pressedTextEditingKeys.clear();
    _hasDeferredTextChange = false;
    _suppressNextTextChange = true;
    _lastObservedText = '';
    _lastSubmittedText = '';
    _controller.clear();
    widget.onSearchCleared();
    if (mounted) {
      setState(() {});
    }
    _focusNode.requestFocus();
  }

  void clearSilently({bool collapse = true}) {
    _debounce.cancel();
    _pressedTextEditingKeys.clear();
    _hasDeferredTextChange = false;
    _suppressNextTextChange = true;
    _lastObservedText = '';
    _lastSubmittedText = '';
    _onClosedByEscape = null;
    _searchOptionsMenuOpen = false;
    _searchOptionsCloseSettling = false;
    _searchOptionsKeepFocusAfterClose = false;
    if (!collapse) {
      _showExpandedField = true;
    }
    _controller.clear();
    _focusNode.unfocus();
    if (collapse) {
      _collapseSearchFieldImmediately();
    } else if (mounted) {
      setState(() {});
    }
  }

  void _handleEscape() {
    if (_controller.text.isNotEmpty) {
      _clear();
      return;
    }

    if (!_expanded) {
      return;
    }

    _collapseSearchField();
    _focusNode.unfocus();
    final onClosedByEscape = _onClosedByEscape;
    _onClosedByEscape = null;
    if (onClosedByEscape != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          onClosedByEscape();
        }
      });
    }
  }

  void _toggleFromIcon() {
    if (!widget.enabled) {
      return;
    }

    if (!_expanded) {
      openAndFocus();
      return;
    }

    _focusNode.unfocus();
    _collapseIfEmpty();
  }

  void _setSearchMode(FdcSearchMode mode) {
    if (!widget.enabled) {
      return;
    }

    _searchOptionsKeepFocusAfterClose = true;
    if (mode == _matchMode) {
      return;
    }

    setState(() {
      _expanded = true;
      _showExpandedField = true;
      _matchMode = mode;
    });
    _resubmitSearchWithCurrentOptions();
  }

  void _handleSearchOptionsMenuOpened() {
    if (_searchOptionsMenuOpen) {
      return;
    }
    setState(() {
      _expanded = true;
      _showExpandedField = true;
      _searchOptionsMenuOpen = true;
      _searchOptionsCloseSettling = false;
    });
  }

  void _handleSearchOptionsMenuClosed() {
    if (!mounted || !_searchOptionsMenuOpen) {
      return;
    }
    setState(() {
      _searchOptionsMenuOpen = false;
      _searchOptionsCloseSettling = true;
    });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _searchOptionsMenuOpen) {
          return;
        }
        final keepFocus = _searchOptionsKeepFocusAfterClose;
        _searchOptionsKeepFocusAfterClose = false;
        if (keepFocus && _expanded) {
          _focusNode.requestFocus();
        }
        setState(() {
          _searchOptionsCloseSettling = false;
        });
        if (!_focusNode.hasFocus) {
          _collapseIfEmpty();
        }
      });
    });
  }

  void _toggleCaseSensitive() {
    if (!widget.enabled) {
      return;
    }

    setState(() {
      _caseSensitive = !_caseSensitive;
    });
    _resubmitSearchWithCurrentOptions();
  }

  void _resubmitSearchWithCurrentOptions({bool restoreFocus = true}) {
    if (_controller.text.trim().isNotEmpty) {
      _submitSearchChange(_controller.text, force: true);
    }
    if (!restoreFocus) {
      return;
    }
    if (mounted && _expanded) {
      _focusNode.requestFocus();
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _expanded) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final collapsedWidth = widget.style.searchFieldHeight ?? 32;
    final expandedWidth =
        widget.style.searchExpandedWidth ??
        FdcGridToolbarStyle.defaultSearchExpandedWidth;

    // Flutter can produce duplicate semantics children while this animated
    // search subtree switches between its collapsed IconButton and expanded
    // TextField states. Keep the animated subtree excluded until it can be
    // represented by a stable, dedicated semantics node.
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _widthController,
        builder: (context, child) {
          final progressCurve = _expanded ? _expandCurve : _collapseCurve;
          final progress = progressCurve.transform(_widthController.value);
          final width =
              collapsedWidth + (expandedWidth - collapsedWidth) * progress;

          return SizedBox(
            width: width,
            height: widget.style.searchFieldHeight ?? 32,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1,
                    child: _showExpandedField
                        ? OverflowBox(
                            alignment: Alignment.centerLeft,
                            minWidth: 0,
                            maxWidth: expandedWidth,
                            child: SizedBox(
                              width: expandedWidth,
                              child: _buildField(
                                context,
                                trailingActionsVisibility:
                                    _trailingActionsVisibility(progress),
                              ),
                            ),
                          )
                        : _buildButton(),
                  ),
                ),
                if (_showExpandedField && _widthController.value < 1)
                  _buildAnimatedSearchOutline(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildButton() {
    final enabledColor =
        widget.style.searchIconColor ?? IconTheme.of(context).color;
    final disabledColor = (enabledColor ?? Colors.black).withValues(
      alpha: 0.38,
    );

    final button = IconButton(
      key: const ValueKey('fdc_grid_toolbar_search_button'),
      icon: const Icon(Icons.search),
      iconSize: 16,
      color: widget.enabled ? enabledColor : disabledColor,
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      constraints: BoxConstraints.tightFor(
        width: widget.style.searchFieldHeight ?? 32,
        height: widget.style.searchFieldHeight ?? 32,
      ),
      onPressed: widget.enabled ? _toggleFromIcon : null,
    );

    return Tooltip(
      message: FdcApp.translationsOf(context).common.search,
      excludeFromSemantics: true,
      child: button,
    );
  }

  Widget _buildField(
    BuildContext context, {
    required double trailingActionsVisibility,
  }) {
    final theme = Theme.of(context);
    final borderRadius = _searchFieldBorderRadius();
    final borderSide = _searchFieldBorderSide(active: false);
    final focusedBorderSide = _searchFieldBorderSide(active: true);
    final enabledBorderSide = _showActiveSearchBorder
        ? focusedBorderSide
        : borderSide;
    final searchBorderColor = borderSide.color;

    final enabledIconColor =
        widget.style.searchIconColor ??
        IconTheme.of(context).color ??
        searchBorderColor;
    final enabledClearIconColor =
        widget.style.searchClearIconColor ?? enabledIconColor;
    final disabledIconColor = enabledIconColor.withValues(alpha: 0.38);
    final disabledClearIconColor = enabledClearIconColor.withValues(
      alpha: 0.38,
    );
    final baseTextStyle =
        widget.style.textStyle ??
        theme.textTheme.bodyMedium ??
        const TextStyle();
    final baseFontSize = baseTextStyle.fontSize ?? 14.0;
    final searchTextStyle = baseTextStyle.copyWith(
      fontSize: baseFontSize,
      fontWeight: FontWeight.w400,
    );

    return SizedBox(
      height: widget.style.searchFieldHeight ?? 32,
      child: TextField(
        key: const ValueKey('fdc_grid_toolbar_search_field'),
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        style: searchTextStyle,
        textInputAction: TextInputAction.search,
        onEditingComplete: () {
          if (_debouncePolicy != FdcDebouncePolicy.disabled) {
            _handleSearchSubmitted();
          }
        },
        onSubmitted: (_) => _handleSearchSubmitted(),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: widget.style.searchFieldFillColor,
          hintText: FdcApp.translationsOf(context).grid.searchHint,
          hintStyle: searchTextStyle.copyWith(color: enabledIconColor),
          prefixIcon: FdcGridToolbarSearchIconButton(
            key: const ValueKey('fdc_grid_toolbar_search_icon_button'),
            width: 30,
            height: 32,
            icon: Icons.search,
            iconSize: 14,
            color: widget.enabled ? enabledIconColor : disabledIconColor,
            onPressed: widget.enabled ? _toggleFromIcon : null,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 32,
          ),
          suffixIcon: _trailingActionsWidth > 0
              ? _buildTrailingActions(
                  enabledClearIconColor: enabledClearIconColor,
                  disabledClearIconColor: disabledClearIconColor,
                  enabledIconColor: enabledIconColor,
                  disabledIconColor: disabledIconColor,
                  visibility: trailingActionsVisibility,
                )
              : null,
          suffixIconConstraints: _trailingActionsWidth > 0
              ? BoxConstraints(minWidth: _trailingActionsWidth, minHeight: 32)
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: borderSide,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: enabledBorderSide,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: focusedBorderSide,
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingActions({
    required Color enabledClearIconColor,
    required Color disabledClearIconColor,
    required Color enabledIconColor,
    required Color disabledIconColor,
    required double visibility,
  }) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final activeBackground = activeColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10,
    );
    final iconColor = widget.enabled ? enabledIconColor : disabledIconColor;
    final actionWidth = _trailingActionsWidth;

    return SizedBox(
      width: actionWidth,
      height: 32,
      child: IgnorePointer(
        ignoring: visibility < 0.99,
        child: Opacity(
          key: const ValueKey('fdc_grid_toolbar_search_trailing_actions'),
          opacity: visibility,
          child: Transform.translate(
            offset: Offset(6 * (1 - visibility), 0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_controller.text.isNotEmpty)
                    FdcGridToolbarSearchIconButton(
                      key: const ValueKey(
                        'fdc_grid_toolbar_search_clear_button',
                      ),
                      tooltip: FdcApp.translationsOf(context).grid.clearSearch,
                      width: 28,
                      height: 32,
                      icon: Icons.close,
                      iconSize: 11,
                      color: widget.enabled
                          ? enabledClearIconColor
                          : disabledClearIconColor,
                      onPressed: widget.enabled ? _clear : null,
                    ),
                  if (_showAdvancedControls)
                    FdcGridToolbarSearchIconButton(
                      key: const ValueKey(
                        'fdc_grid_toolbar_search_case_button',
                      ),
                      tooltip: _caseSensitive
                          ? FdcApp.translationsOf(
                              context,
                            ).grid.caseSensitiveSearchOn
                          : FdcApp.translationsOf(
                              context,
                            ).grid.caseSensitiveSearchOff,
                      width: 28,
                      height: 32,
                      icon: Icons.text_fields,
                      iconSize: 14,
                      color: widget.enabled && _caseSensitive
                          ? activeColor
                          : iconColor,
                      backgroundColor: widget.enabled && _caseSensitive
                          ? activeBackground
                          : null,
                      onPressed: widget.enabled ? _toggleCaseSensitive : null,
                    ),
                  if (_showAdvancedControls)
                    FdcGridToolbarSearchMenuButton(
                      key: const ValueKey(
                        'fdc_grid_toolbar_search_options_button',
                      ),
                      tooltip: FdcApp.translationsOf(
                        context,
                      ).grid.searchOptions,
                      width: 28,
                      height: 32,
                      icon: Icons.tune,
                      iconSize: 14,
                      color: iconColor,
                      enabled: widget.enabled,
                      entries: _buildSearchOptionsMenuEntries(),
                      onOpen: _handleSearchOptionsMenuOpened,
                      onClose: _handleSearchOptionsMenuClosed,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<FdcMenuEntry> _buildSearchOptionsMenuEntries() {
    return <FdcMenuEntry>[
      FdcMenuCheckAction(
        text: FdcApp.translationsOf(context).grid.searchAnyWord,
        icon: Icons.filter_alt_outlined,
        checked: _matchMode == FdcSearchMode.anyWord,
        onPressed: () => _setSearchMode(FdcSearchMode.anyWord),
      ),
      FdcMenuCheckAction(
        text: FdcApp.translationsOf(context).grid.searchAllWords,
        icon: Icons.done_all,
        checked: _matchMode == FdcSearchMode.allWords,
        onPressed: () => _setSearchMode(FdcSearchMode.allWords),
      ),
      FdcMenuCheckAction(
        text: FdcApp.translationsOf(context).grid.containsPhrase,
        icon: Icons.short_text,
        checked: _matchMode == FdcSearchMode.phrase,
        onPressed: () => _setSearchMode(FdcSearchMode.phrase),
      ),
      FdcMenuCheckAction(
        text: FdcApp.translationsOf(context).grid.searchExactPhrase,
        icon: Icons.format_quote,
        checked: _matchMode == FdcSearchMode.exactPhrase,
        onPressed: () => _setSearchMode(FdcSearchMode.exactPhrase),
      ),
      FdcMenuCheckAction(
        text: FdcApp.translationsOf(context).grid.startsWith,
        icon: Icons.first_page,
        checked: _matchMode == FdcSearchMode.startsWith,
        onPressed: () => _setSearchMode(FdcSearchMode.startsWith),
      ),
    ];
  }
}

class FdcGridToolbarSearchIconButton extends StatelessWidget {
  const FdcGridToolbarSearchIconButton({
    super.key,
    required this.width,
    required this.height,
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor,
  });

  final double width;
  final double height;
  final IconData icon;
  final double iconSize;
  final Color color;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      cursor: onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: width,
          height: height,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(icon, size: iconSize, color: color),
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip == null) {
      return button;
    }
    return Tooltip(
      message: tooltip!,
      excludeFromSemantics: true,
      child: button,
    );
  }
}

class FdcGridToolbarSearchMenuButton extends StatelessWidget {
  const FdcGridToolbarSearchMenuButton({
    super.key,
    required this.width,
    required this.height,
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.entries,
    required this.enabled,
    this.tooltip,
    this.onOpen,
    this.onClose,
  });

  final double width;
  final double height;
  final IconData icon;
  final double iconSize;
  final Color color;
  final List<FdcMenuEntry> entries;
  final bool enabled;
  final String? tooltip;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Icon(icon, size: iconSize, color: color),
        ),
      ),
    );
    final wrappedButton = tooltip == null
        ? button
        : Tooltip(message: tooltip!, excludeFromSemantics: true, child: button);

    if (!enabled) {
      return wrappedButton;
    }

    return FdcMenuAnchor(
      entries: entries,
      openOnTap: true,
      openOnSecondaryTap: false,
      consumeSecondaryTap: false,
      onOpen: onOpen,
      onClose: onClose,
      child: wrappedButton,
    );
  }
}
