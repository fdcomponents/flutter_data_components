// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../data/types/fdc_time.dart';

class FdcDateFormat {
  factory FdcDateFormat(String pattern) {
    final tokens = _parseTokens(pattern);
    return FdcDateFormat._(
      pattern,
      tokens,
      _buildParseRegex(pattern),
      tokens.fold(0, (sum, token) => sum + token.length),
    );
  }

  const FdcDateFormat._(
    this.pattern,
    this._tokens,
    this._parseRegex,
    this.maxDigits,
  );

  final String pattern;
  final List<String> _tokens;
  final RegExp _parseRegex;
  final int maxDigits;

  bool hasCompleteInput(String text) {
    return _digitCount(text) >= maxDigits;
  }

  String formatDate(DateTime value) {
    return _formatParts({
      'yyyy': value.year.toString().padLeft(4, '0'),
      'MM': value.month.toString().padLeft(2, '0'),
      'dd': value.day.toString().padLeft(2, '0'),
      'HH': value.hour.toString().padLeft(2, '0'),
      'mm': value.minute.toString().padLeft(2, '0'),
    });
  }

  String formatTime(FdcTime value) {
    return _formatParts({
      'HH': value.hour.toString().padLeft(2, '0'),
      'mm': value.minute.toString().padLeft(2, '0'),
      'ss': value.second.toString().padLeft(2, '0'),
    });
  }

  DateTime? parseDate(String text) {
    final parts = _parseParts(text);
    if (parts == null) {
      return null;
    }

    final year = parts['yyyy'];
    final month = parts['MM'];
    final day = parts['dd'];
    if (year == null || month == null || day == null) {
      return null;
    }

    final hour = parts['HH'] ?? 0;
    final minute = parts['mm'] ?? 0;
    final value = DateTime(year, month, day, hour, minute);
    if (value.year != year || value.month != month || value.day != day) {
      return null;
    }
    if (value.hour != hour || value.minute != minute) {
      return null;
    }
    return value;
  }

  FdcTime? parseTime(String text) {
    final parts = _parseParts(text);
    if (parts == null) {
      return null;
    }

    final hour = parts['HH'];
    final minute = parts['mm'];
    if (hour == null || minute == null) {
      return null;
    }
    try {
      return FdcTime(hour: hour, minute: minute, second: parts['ss'] ?? 0);
      // ignore: avoid_catching_errors
    } on RangeError {
      return null;
    }
  }

  String? completeMissingTrailingYear(String text, int year) {
    if (_tokens.isEmpty || _tokens.last != 'yyyy') {
      return null;
    }

    final digits = _digitsOnly(text);
    final prefixTokens = _tokens.take(_tokens.length - 1);
    final prefixLength = prefixTokens.fold(
      0,
      (sum, token) => sum + token.length,
    );
    if (digits.length != prefixLength) {
      return null;
    }

    final values = <String, int>{'yyyy': year};
    var digitIndex = 0;
    for (final token in prefixTokens) {
      final nextIndex = digitIndex + token.length;
      final value = int.tryParse(digits.substring(digitIndex, nextIndex));
      if (value == null) {
        return null;
      }
      values[token] = value;
      digitIndex = nextIndex;
    }

    final formatted = _formatParts({
      'yyyy': (values['yyyy'] ?? year).toString().padLeft(4, '0'),
      'MM': (values['MM'] ?? 1).toString().padLeft(2, '0'),
      'dd': (values['dd'] ?? 1).toString().padLeft(2, '0'),
      'HH': (values['HH'] ?? 0).toString().padLeft(2, '0'),
      'mm': (values['mm'] ?? 0).toString().padLeft(2, '0'),
    });

    return parseDate(formatted) == null ? null : formatted;
  }

  String _formatParts(Map<String, String> values) {
    var result = pattern;
    for (final entry in values.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  Map<String, int>? _parseParts(String text) {
    final match = _parseRegex.firstMatch(text.trim());
    if (match == null) {
      return null;
    }

    final values = <String, int>{};
    for (var i = 0; i < _tokens.length; i++) {
      final value = int.tryParse(match.group(i + 1) ?? '');
      if (value == null) {
        return null;
      }
      values[_tokens[i]] = value;
    }
    return values;
  }

  static List<String> _parseTokens(String pattern) {
    final tokens = <String>[];
    var index = 0;
    while (index < pattern.length) {
      final token = _tokenAt(pattern, index);
      if (token != null) {
        tokens.add(token);
        index += token.length;
        continue;
      }
      index++;
    }
    return tokens;
  }

  static RegExp _buildParseRegex(String pattern) {
    final regex = StringBuffer('^');
    var index = 0;
    while (index < pattern.length) {
      final token = _tokenAt(pattern, index);
      if (token != null) {
        regex.write(token == 'yyyy' ? r'(\d{4})' : r'(\d{1,2})');
        index += token.length;
        continue;
      }

      regex.write(RegExp.escape(pattern[index]));
      index++;
    }

    regex.write(r'$');
    return RegExp(regex.toString());
  }

  static int _digitCount(String text) {
    var count = 0;
    for (var i = 0; i < text.length; i++) {
      if (_isDigit(text[i])) {
        count++;
      }
    }
    return count;
  }

  static String _digitsOnly(String text) {
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (_isDigit(char)) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  static bool _isDigit(String char) {
    return char.compareTo('0') >= 0 && char.compareTo('9') <= 0;
  }

  static String? _tokenAt(String value, int index) {
    for (final token in const ['yyyy', 'MM', 'dd', 'HH', 'mm', 'ss']) {
      if (value.startsWith(token, index)) {
        return token;
      }
    }
    return null;
  }
}
