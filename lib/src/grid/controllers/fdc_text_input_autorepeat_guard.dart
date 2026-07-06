// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FdcTextInputAutorepeatGuard {
  FdcTextInputAutorepeatGuard({
    required FocusNode focusNode,
    required VoidCallback onDeferredTextChangeReady,
    VoidCallback? onDeferredTextChangeMarked,
    bool Function()? shouldSubmitOnEnter,
    VoidCallback? onSubmit,
  }) : _focusNode = focusNode,
       _onDeferredTextChangeReady = onDeferredTextChangeReady,
       _onDeferredTextChangeMarked = onDeferredTextChangeMarked,
       _shouldSubmitOnEnter = shouldSubmitOnEnter,
       _onSubmit = onSubmit {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  final FocusNode _focusNode;
  final VoidCallback _onDeferredTextChangeReady;
  final VoidCallback? _onDeferredTextChangeMarked;
  final bool Function()? _shouldSubmitOnEnter;
  final VoidCallback? _onSubmit;

  final Set<LogicalKeyboardKey> _pressedTextEditingKeys =
      <LogicalKeyboardKey>{};
  bool _hasDeferredTextChange = false;
  bool _repeatTextEditingInProgress = false;
  bool _disposed = false;

  /// Whether the current text change belongs to a hardware key-repeat burst.
  ///
  /// The initial key-down must still propagate immediately. Only subsequent
  /// [KeyRepeatEvent] changes are deferred until key-up so a rebuild or focus
  /// change cannot swallow an ordinary edit such as a single Backspace.
  bool get shouldDeferTextChange => _repeatTextEditingInProgress;

  void markDeferredTextChange() {
    _hasDeferredTextChange = true;
    _onDeferredTextChangeMarked?.call();
  }

  void clear() {
    _pressedTextEditingKeys.clear();
    _hasDeferredTextChange = false;
    _repeatTextEditingInProgress = false;
  }

  void flushDeferredTextChange() {
    if (!_hasDeferredTextChange) {
      return;
    }

    _hasDeferredTextChange = false;
    _onDeferredTextChangeReady();
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    clear();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (_disposed || !_focusNode.hasFocus) {
      return false;
    }

    if (event is KeyUpEvent) {
      _handleKeyUp(event.logicalKey);
      return false;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    if (_isSubmitKey(event.logicalKey) &&
        (_shouldSubmitOnEnter?.call() ?? false)) {
      if (event is KeyRepeatEvent) {
        return true;
      }

      _onSubmit?.call();
      return true;
    }

    if (_isTextEditingKeyEvent(event)) {
      _pressedTextEditingKeys.add(event.logicalKey);
      if (event is KeyRepeatEvent) {
        _repeatTextEditingInProgress = true;
        markDeferredTextChange();
      }
    }

    return false;
  }

  void _handleKeyUp(LogicalKeyboardKey key) {
    if (!_pressedTextEditingKeys.remove(key) ||
        _pressedTextEditingKeys.isNotEmpty) {
      return;
    }

    _repeatTextEditingInProgress = false;
    flushDeferredTextChange();
  }

  bool _isSubmitKey(LogicalKeyboardKey key) {
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
}
