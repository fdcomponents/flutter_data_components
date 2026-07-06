// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/services.dart';

class FdcDecimalInputFormatter extends TextInputFormatter {
  FdcDecimalInputFormatter({
    required this.decimalSeparator,
    this.thousandSeparator,
    this.precision,
    this.scale,
    this.negative = true,
  });

  final String decimalSeparator;
  final String? thousandSeparator;
  final int? precision;
  final int? scale;
  final bool negative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!negative && newValue.text.contains('-')) {
      return oldValue;
    }

    final buffer = StringBuffer();
    var hasDecimalSeparator = false;
    var integerDigits = 0;
    var fractionalDigits = 0;
    var integerOverflow = false;
    var fractionalOverflow = false;
    final effectiveScale = scale ?? (precision == null ? null : 0);
    final integerDigitsLimit = precision == null
        ? null
        : (precision! - (effectiveScale ?? 0)).clamp(0, precision!);
    int? selectionOffset;
    final rawSelectionOffset = newValue.selection.extentOffset;

    for (var i = 0; i < newValue.text.length; i++) {
      if (i == rawSelectionOffset) {
        selectionOffset = buffer.length;
      }

      final char = newValue.text[i];
      if (_isDigit(char)) {
        if (hasDecimalSeparator) {
          if (effectiveScale != null && fractionalDigits >= effectiveScale) {
            fractionalOverflow = true;
            continue;
          }
          buffer.write(char);
          fractionalDigits++;
          continue;
        }

        if (integerDigitsLimit != null && integerDigits >= integerDigitsLimit) {
          integerOverflow = true;
          continue;
        }
        buffer.write(char);
        integerDigits++;
        continue;
      }

      if (negative &&
          char == '-' &&
          buffer.isEmpty &&
          !newValue.text.startsWith('--')) {
        buffer.write(char);
        continue;
      }

      if (_isExistingThousandSeparator(newValue.text, i)) {
        continue;
      }

      if ((char == '.' || char == ',') &&
          !hasDecimalSeparator &&
          effectiveScale != 0) {
        buffer.write(decimalSeparator);
        hasDecimalSeparator = true;
      }
    }

    if (rawSelectionOffset >= newValue.text.length) {
      selectionOffset = buffer.length;
    }

    if (integerOverflow || fractionalOverflow) {
      return oldValue;
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: selectionOffset ?? text.length,
      ),
    );
  }

  bool _isExistingThousandSeparator(String text, int index) {
    final separator = thousandSeparator;
    if (separator == null ||
        separator.isEmpty ||
        separator == decimalSeparator ||
        !text.startsWith(separator, index)) {
      return false;
    }

    if (index == 0 || !_isDigit(text[index - 1])) {
      return false;
    }

    final afterStart = index + separator.length;
    if (text.length - afterStart < 3) {
      return false;
    }

    final decimalIndex = _decimalSeparatorIndex(text, afterStart);
    if (decimalIndex == -1) {
      return false;
    }

    return decimalIndex - afterStart == 3 &&
        _isThreeDigits(text, afterStart, decimalIndex);
  }

  int _decimalSeparatorIndex(String text, int start) {
    for (var i = start; i < text.length; i++) {
      final char = text[i];
      if (char == '.' || char == ',') {
        return i;
      }
    }
    return -1;
  }

  bool _isDigit(String char) {
    return char.compareTo('0') >= 0 && char.compareTo('9') <= 0;
  }

  bool _isThreeDigits(String text, int start, int end) {
    if (end - start != 3) {
      return false;
    }
    for (var i = start; i < end; i++) {
      if (!_isDigit(text[i])) {
        return false;
      }
    }
    return true;
  }
}
