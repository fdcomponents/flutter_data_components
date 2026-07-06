// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:math';

/// Immutable GUID/UUID value used by GUID field runtime values.
///
/// The value is stored as four unsigned 32-bit words, not as canonical text.
/// This keeps equality, hashing, comparison, sorting, and key-style
/// from string storage while still exposing canonical text for display/export.
///
/// Accepted input forms are canonical GUID text, braced canonical GUID text,
/// and compact 32-hex-character text.
class FdcGuid implements Comparable<FdcGuid> {
  /// Parses GUID text into a GUID value.
  ///
  /// Accepted input forms are canonical GUID text, braced canonical GUID text,
  /// and compact 32-hex-character text.
  factory FdcGuid(String value) => parse(value);

  const FdcGuid._(this._a, this._b, this._c, this._d);

  /// Creates a [FdcGuid].
  factory FdcGuid.fromBytes(List<int> bytes) {
    if (bytes.length != 16) {
      throw ArgumentError.value(
        bytes,
        'bytes',
        'FdcGuid requires exactly 16 bytes.',
      );
    }
    return FdcGuid._(
      _wordFromBytes(bytes, 0),
      _wordFromBytes(bytes, 4),
      _wordFromBytes(bytes, 8),
      _wordFromBytes(bytes, 12),
    );
  }

  /// Creates a new random RFC 4122 version 4 GUID value immediately.
  ///
  /// For GUID field defaults, pass the function tear-off so it is evaluated
  /// once per newly inserted/appended record:
  ///
  /// ```dart
  /// FdcGuidField(name: 'id', defaultValue: FdcGuid.newGuid)
  /// ```
  ///
  /// Avoid using `FdcGuid.newGuid()` directly as a GUID field default. That
  /// creates one immediate value before any records are inserted, so
  /// GUID fields reject static GUID defaults during new-record
  /// materialization to prevent duplicate primary-key defaults.
  factory FdcGuid.newGuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));

    // RFC 4122 version 4 and variant bits.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    return FdcGuid.fromBytes(bytes);
  }

  /// Parses a canonical GUID string.
  ///
  /// Throws [FormatException] when [text] is not a valid GUID.
  static FdcGuid parse(String text) {
    final parsed = tryParse(text);
    if (parsed == null) {
      throw FormatException('Invalid FdcGuid value.', text);
    }
    return parsed;
  }

  /// Parses [text], returning `null` instead of throwing for invalid text.
  static FdcGuid? tryParse(String? text) {
    if (text == null) {
      return null;
    }

    final compact = _compactHex(text);
    if (compact == null) {
      return null;
    }

    return FdcGuid._(
      int.parse(compact.substring(0, 8), radix: 16),
      int.parse(compact.substring(8, 16), radix: 16),
      int.parse(compact.substring(16, 24), radix: 16),
      int.parse(compact.substring(24, 32), radix: 16),
    );
  }

  final int _a;
  final int _b;
  final int _c;
  final int _d;

  /// Lowercase canonical GUID text.
  ///
  /// Generated on demand from the internal 16-byte value. Core equality,
  /// hashCode, and compareTo do not use this string.
  String get value => _formatCanonical();

  /// Returns the current bytes.
  List<int> get bytes => <int>[
    (_a >> 24) & 0xff,
    (_a >> 16) & 0xff,
    (_a >> 8) & 0xff,
    _a & 0xff,
    (_b >> 24) & 0xff,
    (_b >> 16) & 0xff,
    (_b >> 8) & 0xff,
    _b & 0xff,
    (_c >> 24) & 0xff,
    (_c >> 16) & 0xff,
    (_c >> 8) & 0xff,
    _c & 0xff,
    (_d >> 24) & 0xff,
    (_d >> 16) & 0xff,
    (_d >> 8) & 0xff,
    _d & 0xff,
  ];

  /// Whether all 128 bits are zero.
  bool get isEmpty => this == empty;

  /// Default value for empty.
  static const FdcGuid empty = FdcGuid._(0, 0, 0, 0);

  static final Random _random = Random.secure();

  @override
  int compareTo(FdcGuid other) {
    var result = _a.compareTo(other._a);
    if (result != 0) {
      return result;
    }
    result = _b.compareTo(other._b);
    if (result != 0) {
      return result;
    }
    result = _c.compareTo(other._c);
    if (result != 0) {
      return result;
    }
    return _d.compareTo(other._d);
  }

  @override
  bool operator ==(Object other) {
    return other is FdcGuid &&
        other._a == _a &&
        other._b == _b &&
        other._c == _c &&
        other._d == _d;
  }

  @override
  int get hashCode => Object.hash(_a, _b, _c, _d);

  @override
  String toString() => value;

  String _formatCanonical() {
    final compact = _hexWord(_a) + _hexWord(_b) + _hexWord(_c) + _hexWord(_d);
    return '${compact.substring(0, 8)}-'
        '${compact.substring(8, 12)}-'
        '${compact.substring(12, 16)}-'
        '${compact.substring(16, 20)}-'
        '${compact.substring(20)}';
  }

  static String? _compactHex(String text) {
    var trimmed = text.trim().toLowerCase();
    if (trimmed.length >= 2 &&
        trimmed.startsWith('{') &&
        trimmed.endsWith('}')) {
      trimmed = trimmed.substring(1, trimmed.length - 1).trim();
    }

    final compact = trimmed.replaceAll('-', '');
    if (compact.length != 32 || !_isLowerHex32(compact)) {
      return null;
    }

    // If hyphens were present, require canonical positions instead of silently
    // accepting malformed grouped text.
    if (trimmed.contains('-') && !_hasCanonicalHyphenLayout(trimmed)) {
      return null;
    }

    return compact;
  }

  static bool _hasCanonicalHyphenLayout(String text) {
    return text.length == 36 &&
        text.codeUnitAt(8) == 0x2d &&
        text.codeUnitAt(13) == 0x2d &&
        text.codeUnitAt(18) == 0x2d &&
        text.codeUnitAt(23) == 0x2d &&
        _isLowerHexRange(text, 0, 8) &&
        _isLowerHexRange(text, 9, 13) &&
        _isLowerHexRange(text, 14, 18) &&
        _isLowerHexRange(text, 19, 23) &&
        _isLowerHexRange(text, 24, 36);
  }

  static bool _isLowerHex32(String text) =>
      _isLowerHexRange(text, 0, text.length);

  static bool _isLowerHexRange(String text, int start, int end) {
    for (var i = start; i < end; i++) {
      final code = text.codeUnitAt(i);
      final isDigit = code >= 0x30 && code <= 0x39;
      final isHexLetter = code >= 0x61 && code <= 0x66;
      if (!isDigit && !isHexLetter) {
        return false;
      }
    }
    return true;
  }

  static int _wordFromBytes(List<int> bytes, int offset) {
    int byteAt(int index) {
      final value = bytes[index];
      if (value < 0 || value > 0xff) {
        throw ArgumentError.value(
          bytes,
          'bytes',
          'FdcGuid bytes must be in range 0..255.',
        );
      }
      return value;
    }

    return (byteAt(offset) << 24) |
        (byteAt(offset + 1) << 16) |
        (byteAt(offset + 2) << 8) |
        byteAt(offset + 3);
  }

  static String _hexWord(int value) => value.toRadixString(16).padLeft(8, '0');
}
