// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/services.dart';

class FdcDateInputFormatter extends TextInputFormatter {
  FdcDateInputFormatter(this.pattern)
    : _segments = _DateInputPattern.parse(pattern);

  final String pattern;
  final _DateInputPattern _segments;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_deletedSeparator(oldValue, newValue)) {
      return newValue;
    }

    if (_deletedDigit(oldValue, newValue)) {
      return newValue;
    }

    final rawSelectionOffset = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final digitsBeforeSelection = _digitCount(
      newValue.text.substring(0, rawSelectionOffset),
    );
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = _segments.apply(digits);
    final selectionOffset = _selectionOffsetForDigitCount(
      text,
      digitsBeforeSelection,
    );

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }

  bool _deletedSeparator(TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.text.length != newValue.text.length + 1) {
      return false;
    }

    final deletedIndex = newValue.selection.extentOffset;
    if (deletedIndex < 0 || deletedIndex >= oldValue.text.length) {
      return false;
    }

    final deletedCharacter = oldValue.text[deletedIndex];
    if (RegExp(r'\d').hasMatch(deletedCharacter)) {
      return false;
    }

    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    final newDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    return oldDigits == newDigits;
  }

  bool _deletedDigit(TextEditingValue oldValue, TextEditingValue newValue) {
    if (oldValue.text.length != newValue.text.length + 1) {
      return false;
    }

    final deletedIndex = newValue.selection.extentOffset;
    if (deletedIndex < 0 || deletedIndex >= oldValue.text.length) {
      return false;
    }

    final deletedCharacter = oldValue.text[deletedIndex];
    if (!_isDigit(deletedCharacter)) {
      return false;
    }

    final rebuiltNewValue = oldValue.text.replaceRange(
      deletedIndex,
      deletedIndex + 1,
      '',
    );
    return rebuiltNewValue == newValue.text;
  }

  int _digitCount(String text) {
    var count = 0;
    for (var i = 0; i < text.length; i++) {
      if (_isDigit(text[i])) {
        count++;
      }
    }
    return count;
  }

  int _selectionOffsetForDigitCount(String text, int digitCount) {
    if (digitCount <= 0) {
      return 0;
    }

    var seenDigits = 0;
    for (var i = 0; i < text.length; i++) {
      if (!_isDigit(text[i])) {
        continue;
      }

      seenDigits++;
      if (seenDigits == digitCount) {
        var offset = i + 1;
        while (offset < text.length && !_isDigit(text[offset])) {
          offset++;
        }
        return offset;
      }
    }
    return text.length;
  }

  bool _isDigit(String char) {
    return char.compareTo('0') >= 0 && char.compareTo('9') <= 0;
  }
}

class _DateInputPattern {
  _DateInputPattern(this.parts);

  final List<_DateInputPart> parts;

  int get maxDigits {
    return parts.fold(0, (sum, part) => sum + part.length);
  }

  static _DateInputPattern parse(String pattern) {
    final parts = <_DateInputPart>[];
    var index = 0;

    while (index < pattern.length) {
      final token = _tokenAt(pattern, index);
      if (token == null) {
        index++;
        continue;
      }

      final literal = StringBuffer();
      var literalIndex = index + token.length;
      while (literalIndex < pattern.length) {
        if (_tokenAt(pattern, literalIndex) != null) {
          break;
        }
        literal.write(pattern[literalIndex]);
        literalIndex++;
      }

      parts.add(
        _DateInputPart(
          tokenLength: token.length,
          nextLiteral: literal.toString(),
        ),
      );
      index = literalIndex;
    }

    return _DateInputPattern(parts);
  }

  String apply(String rawDigits) {
    final digits = rawDigits.length > maxDigits
        ? rawDigits.substring(0, maxDigits)
        : rawDigits;
    final result = StringBuffer();
    var digitIndex = 0;

    for (var partIndex = 0; partIndex < parts.length; partIndex++) {
      final part = parts[partIndex];
      final remaining = digits.length - digitIndex;
      if (remaining <= 0) {
        break;
      }

      final take = remaining > part.length ? part.length : remaining;
      result.write(digits.substring(digitIndex, digitIndex + take));
      digitIndex += take;

      final hasMoreParts = partIndex < parts.length - 1;
      final groupIsComplete = take == part.length;
      if (hasMoreParts && groupIsComplete) {
        result.write(part.nextLiteral);
      }
    }

    return result.toString();
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

class _DateInputPart {
  const _DateInputPart({required this.tokenLength, required this.nextLiteral});

  final int tokenLength;
  final String nextLiteral;

  int get length => tokenLength;
}
