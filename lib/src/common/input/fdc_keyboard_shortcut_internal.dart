// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show ShortcutActivator, SingleActivator;

import 'fdc_keyboard_shortcut.dart';

ShortcutActivator fdcKeyboardShortcutActivator(FdcKeyboardShortcut shortcut) {
  return SingleActivator(
    _logicalKey(shortcut.key),
    control: shortcut.control,
    alt: shortcut.alt,
    shift: shortcut.shift,
    meta: shortcut.meta,
  );
}

bool fdcKeyboardShortcutAccepts(
  FdcKeyboardShortcut shortcut,
  KeyEvent event,
  HardwareKeyboard keyboard,
) {
  return fdcKeyboardShortcutActivator(shortcut).accepts(event, keyboard);
}

LogicalKeyboardKey _logicalKey(FdcKeyboardKey key) {
  return switch (key) {
    FdcKeyboardKey.f1 => LogicalKeyboardKey.f1,
    FdcKeyboardKey.f2 => LogicalKeyboardKey.f2,
    FdcKeyboardKey.f3 => LogicalKeyboardKey.f3,
    FdcKeyboardKey.f4 => LogicalKeyboardKey.f4,
    FdcKeyboardKey.f5 => LogicalKeyboardKey.f5,
    FdcKeyboardKey.f6 => LogicalKeyboardKey.f6,
    FdcKeyboardKey.f7 => LogicalKeyboardKey.f7,
    FdcKeyboardKey.f8 => LogicalKeyboardKey.f8,
    FdcKeyboardKey.f9 => LogicalKeyboardKey.f9,
    FdcKeyboardKey.f10 => LogicalKeyboardKey.f10,
    FdcKeyboardKey.f11 => LogicalKeyboardKey.f11,
    FdcKeyboardKey.f12 => LogicalKeyboardKey.f12,
    FdcKeyboardKey.enter => LogicalKeyboardKey.enter,
    FdcKeyboardKey.space => LogicalKeyboardKey.space,
    FdcKeyboardKey.escape => LogicalKeyboardKey.escape,
    FdcKeyboardKey.tab => LogicalKeyboardKey.tab,
    FdcKeyboardKey.arrowUp => LogicalKeyboardKey.arrowUp,
    FdcKeyboardKey.arrowDown => LogicalKeyboardKey.arrowDown,
    FdcKeyboardKey.arrowLeft => LogicalKeyboardKey.arrowLeft,
    FdcKeyboardKey.arrowRight => LogicalKeyboardKey.arrowRight,
    FdcKeyboardKey.home => LogicalKeyboardKey.home,
    FdcKeyboardKey.end => LogicalKeyboardKey.end,
    FdcKeyboardKey.pageUp => LogicalKeyboardKey.pageUp,
    FdcKeyboardKey.pageDown => LogicalKeyboardKey.pageDown,
    FdcKeyboardKey.insert => LogicalKeyboardKey.insert,
    FdcKeyboardKey.delete => LogicalKeyboardKey.delete,
    FdcKeyboardKey.backspace => LogicalKeyboardKey.backspace,
    FdcKeyboardKey.digit0 => LogicalKeyboardKey.digit0,
    FdcKeyboardKey.digit1 => LogicalKeyboardKey.digit1,
    FdcKeyboardKey.digit2 => LogicalKeyboardKey.digit2,
    FdcKeyboardKey.digit3 => LogicalKeyboardKey.digit3,
    FdcKeyboardKey.digit4 => LogicalKeyboardKey.digit4,
    FdcKeyboardKey.digit5 => LogicalKeyboardKey.digit5,
    FdcKeyboardKey.digit6 => LogicalKeyboardKey.digit6,
    FdcKeyboardKey.digit7 => LogicalKeyboardKey.digit7,
    FdcKeyboardKey.digit8 => LogicalKeyboardKey.digit8,
    FdcKeyboardKey.digit9 => LogicalKeyboardKey.digit9,
    FdcKeyboardKey.keyA => LogicalKeyboardKey.keyA,
    FdcKeyboardKey.keyB => LogicalKeyboardKey.keyB,
    FdcKeyboardKey.keyC => LogicalKeyboardKey.keyC,
    FdcKeyboardKey.keyD => LogicalKeyboardKey.keyD,
    FdcKeyboardKey.keyE => LogicalKeyboardKey.keyE,
    FdcKeyboardKey.keyF => LogicalKeyboardKey.keyF,
    FdcKeyboardKey.keyG => LogicalKeyboardKey.keyG,
    FdcKeyboardKey.keyH => LogicalKeyboardKey.keyH,
    FdcKeyboardKey.keyI => LogicalKeyboardKey.keyI,
    FdcKeyboardKey.keyJ => LogicalKeyboardKey.keyJ,
    FdcKeyboardKey.keyK => LogicalKeyboardKey.keyK,
    FdcKeyboardKey.keyL => LogicalKeyboardKey.keyL,
    FdcKeyboardKey.keyM => LogicalKeyboardKey.keyM,
    FdcKeyboardKey.keyN => LogicalKeyboardKey.keyN,
    FdcKeyboardKey.keyO => LogicalKeyboardKey.keyO,
    FdcKeyboardKey.keyP => LogicalKeyboardKey.keyP,
    FdcKeyboardKey.keyQ => LogicalKeyboardKey.keyQ,
    FdcKeyboardKey.keyR => LogicalKeyboardKey.keyR,
    FdcKeyboardKey.keyS => LogicalKeyboardKey.keyS,
    FdcKeyboardKey.keyT => LogicalKeyboardKey.keyT,
    FdcKeyboardKey.keyU => LogicalKeyboardKey.keyU,
    FdcKeyboardKey.keyV => LogicalKeyboardKey.keyV,
    FdcKeyboardKey.keyW => LogicalKeyboardKey.keyW,
    FdcKeyboardKey.keyX => LogicalKeyboardKey.keyX,
    FdcKeyboardKey.keyY => LogicalKeyboardKey.keyY,
    FdcKeyboardKey.keyZ => LogicalKeyboardKey.keyZ,
  };
}
