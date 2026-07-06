// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Keyboard keys supported by [FdcKeyboardShortcut].
enum FdcKeyboardKey {
  /// F1 option.
  f1,

  /// F2 option.
  f2,

  /// F3 option.
  f3,

  /// F4 option.
  f4,

  /// F5 option.
  f5,

  /// F6 option.
  f6,

  /// F7 option.
  f7,

  /// F8 option.
  f8,

  /// F9 option.
  f9,

  /// F10 option.
  f10,

  /// F11 option.
  f11,

  /// F12 option.
  f12,

  /// Enter option.
  enter,

  /// Space option.
  space,

  /// Escape option.
  escape,

  /// Tab option.
  tab,

  /// Arrow up option.
  arrowUp,

  /// Arrow down option.
  arrowDown,

  /// Arrow left option.
  arrowLeft,

  /// Arrow right option.
  arrowRight,

  /// Home option.
  home,

  /// End option.
  end,

  /// Page up option.
  pageUp,

  /// Page down option.
  pageDown,

  /// Insert option.
  insert,

  /// Delete option.
  delete,

  /// Backspace option.
  backspace,

  /// Digit0 option.
  digit0,

  /// Digit1 option.
  digit1,

  /// Digit2 option.
  digit2,

  /// Digit3 option.
  digit3,

  /// Digit4 option.
  digit4,

  /// Digit5 option.
  digit5,

  /// Digit6 option.
  digit6,

  /// Digit7 option.
  digit7,

  /// Digit8 option.
  digit8,

  /// Digit9 option.
  digit9,

  /// Key a option.
  keyA,

  /// Key b option.
  keyB,

  /// Key c option.
  keyC,

  /// Key d option.
  keyD,

  /// Key e option.
  keyE,

  /// Key f option.
  keyF,

  /// Key g option.
  keyG,

  /// Key h option.
  keyH,

  /// Key i option.
  keyI,

  /// Key j option.
  keyJ,

  /// Key k option.
  keyK,

  /// Key l option.
  keyL,

  /// Key m option.
  keyM,

  /// Key n option.
  keyN,

  /// Key o option.
  keyO,

  /// Key p option.
  keyP,

  /// Key q option.
  keyQ,

  /// Key r option.
  keyR,

  /// Key s option.
  keyS,

  /// Key t option.
  keyT,

  /// Key u option.
  keyU,

  /// Key v option.
  keyV,

  /// Key w option.
  keyW,

  /// Key x option.
  keyX,

  /// Key y option.
  keyY,

  /// Key z option.
  keyZ,
}

/// Framework-neutral keyboard shortcut used by FDC public APIs.
final class FdcKeyboardShortcut {
  /// Creates a [FdcKeyboardShortcut].
  const FdcKeyboardShortcut(
    this.key, {
    this.control = false,
    this.alt = false,
    this.shift = false,
    this.meta = false,
  });

  /// Default value for f2.
  static const FdcKeyboardShortcut f2 = FdcKeyboardShortcut(FdcKeyboardKey.f2);

  /// Default value for f4.
  static const FdcKeyboardShortcut f4 = FdcKeyboardShortcut(FdcKeyboardKey.f4);

  /// Keyboard key associated with this shortcut.
  final FdcKeyboardKey key;

  /// Whether the Control modifier is required.
  final bool control;

  /// Whether the Alt modifier is required.
  final bool alt;

  /// Whether the Shift modifier is required.
  final bool shift;

  /// Whether the Meta modifier is required.
  final bool meta;

  /// Human-readable shortcut label suitable for tooltips and menus.
  String get displayLabel {
    final parts = <String>[
      if (control) 'Ctrl',
      if (alt) 'Alt',
      if (shift) 'Shift',
      if (meta) 'Meta',
      _keyLabel(key),
    ];
    return parts.join(' + ');
  }

  static String _keyLabel(FdcKeyboardKey key) {
    return switch (key) {
      FdcKeyboardKey.f1 => 'F1',
      FdcKeyboardKey.f2 => 'F2',
      FdcKeyboardKey.f3 => 'F3',
      FdcKeyboardKey.f4 => 'F4',
      FdcKeyboardKey.f5 => 'F5',
      FdcKeyboardKey.f6 => 'F6',
      FdcKeyboardKey.f7 => 'F7',
      FdcKeyboardKey.f8 => 'F8',
      FdcKeyboardKey.f9 => 'F9',
      FdcKeyboardKey.f10 => 'F10',
      FdcKeyboardKey.f11 => 'F11',
      FdcKeyboardKey.f12 => 'F12',
      FdcKeyboardKey.enter => 'Enter',
      FdcKeyboardKey.space => 'Space',
      FdcKeyboardKey.escape => 'Escape',
      FdcKeyboardKey.tab => 'Tab',
      FdcKeyboardKey.arrowUp => 'Arrow Up',
      FdcKeyboardKey.arrowDown => 'Arrow Down',
      FdcKeyboardKey.arrowLeft => 'Arrow Left',
      FdcKeyboardKey.arrowRight => 'Arrow Right',
      FdcKeyboardKey.home => 'Home',
      FdcKeyboardKey.end => 'End',
      FdcKeyboardKey.pageUp => 'Page Up',
      FdcKeyboardKey.pageDown => 'Page Down',
      FdcKeyboardKey.insert => 'Insert',
      FdcKeyboardKey.delete => 'Delete',
      FdcKeyboardKey.backspace => 'Backspace',
      FdcKeyboardKey.digit0 => '0',
      FdcKeyboardKey.digit1 => '1',
      FdcKeyboardKey.digit2 => '2',
      FdcKeyboardKey.digit3 => '3',
      FdcKeyboardKey.digit4 => '4',
      FdcKeyboardKey.digit5 => '5',
      FdcKeyboardKey.digit6 => '6',
      FdcKeyboardKey.digit7 => '7',
      FdcKeyboardKey.digit8 => '8',
      FdcKeyboardKey.digit9 => '9',
      FdcKeyboardKey.keyA => 'A',
      FdcKeyboardKey.keyB => 'B',
      FdcKeyboardKey.keyC => 'C',
      FdcKeyboardKey.keyD => 'D',
      FdcKeyboardKey.keyE => 'E',
      FdcKeyboardKey.keyF => 'F',
      FdcKeyboardKey.keyG => 'G',
      FdcKeyboardKey.keyH => 'H',
      FdcKeyboardKey.keyI => 'I',
      FdcKeyboardKey.keyJ => 'J',
      FdcKeyboardKey.keyK => 'K',
      FdcKeyboardKey.keyL => 'L',
      FdcKeyboardKey.keyM => 'M',
      FdcKeyboardKey.keyN => 'N',
      FdcKeyboardKey.keyO => 'O',
      FdcKeyboardKey.keyP => 'P',
      FdcKeyboardKey.keyQ => 'Q',
      FdcKeyboardKey.keyR => 'R',
      FdcKeyboardKey.keyS => 'S',
      FdcKeyboardKey.keyT => 'T',
      FdcKeyboardKey.keyU => 'U',
      FdcKeyboardKey.keyV => 'V',
      FdcKeyboardKey.keyW => 'W',
      FdcKeyboardKey.keyX => 'X',
      FdcKeyboardKey.keyY => 'Y',
      FdcKeyboardKey.keyZ => 'Z',
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcKeyboardShortcut &&
            other.key == key &&
            other.control == control &&
            other.alt == alt &&
            other.shift == shift &&
            other.meta == meta;
  }

  @override
  int get hashCode => Object.hash(key, control, alt, shift, meta);
}
