// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/services.dart';

/// Low-level keyboard predicates shared by grid/editor input handlers.
///
/// This class intentionally contains no UX policy. It only identifies keys and
/// modifier state so grid and editor keyboard handlers can keep their own
/// behavior rules while sharing the same key definitions.
class FdcKeyUtils {
  const FdcKeyUtils._();

  static bool isKeyDownOrRepeat(KeyEvent event) {
    return event is KeyDownEvent || event is KeyRepeatEvent;
  }

  static bool isKeyDown(KeyEvent event) {
    return event is KeyDownEvent;
  }

  static bool isEnter(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
  }

  static bool isEscape(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.escape;
  }

  static bool isTab(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.tab;
  }

  static bool isSpace(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.space;
  }

  static bool isBackspace(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.backspace;
  }

  static bool isDelete(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.delete;
  }

  static bool isBackspaceOrDelete(KeyEvent event) {
    return isBackspace(event) || isDelete(event);
  }

  static bool isF2(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.f2;
  }

  static bool isInsert(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.insert;
  }

  static bool isFindShortcut(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.keyF &&
        hasControlOrMetaPressed &&
        !isShiftPressed &&
        !HardwareKeyboard.instance.isAltPressed;
  }

  static bool isCopyShortcut(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.keyC &&
        hasControlOrMetaPressed &&
        !isShiftPressed &&
        !HardwareKeyboard.instance.isAltPressed;
  }

  static bool isPasteShortcut(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.keyV &&
        hasControlOrMetaPressed &&
        !isShiftPressed &&
        !HardwareKeyboard.instance.isAltPressed;
  }

  static bool isHome(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.home;
  }

  static bool isEnd(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.end;
  }

  static bool isArrowLeft(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.arrowLeft;
  }

  static bool isArrowRight(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.arrowRight;
  }

  static bool isArrowUp(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.arrowUp;
  }

  static bool isArrowDown(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.arrowDown;
  }

  static bool isHorizontalArrow(KeyEvent event) {
    return isArrowLeft(event) || isArrowRight(event);
  }

  static bool isVerticalArrow(KeyEvent event) {
    return isArrowUp(event) || isArrowDown(event);
  }

  static bool isArrow(KeyEvent event) {
    return isHorizontalArrow(event) || isVerticalArrow(event);
  }

  static bool isPageUp(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.pageUp;
  }

  static bool isPageDown(KeyEvent event) {
    return event.logicalKey == LogicalKeyboardKey.pageDown;
  }

  static bool isPageKey(KeyEvent event) {
    return isPageUp(event) || isPageDown(event);
  }

  static bool get isShiftPressed {
    return HardwareKeyboard.instance.isShiftPressed;
  }

  static bool get isControlPressed {
    return HardwareKeyboard.instance.isControlPressed;
  }

  static bool get isMetaPressed {
    return HardwareKeyboard.instance.isMetaPressed;
  }

  static bool get hasControlOrMetaPressed {
    return isControlPressed || isMetaPressed;
  }
}
