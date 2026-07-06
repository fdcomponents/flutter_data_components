// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

class FdcDecimalMath {
  const FdcDecimalMath._();

  static String? normalizeTextForParsing(
    String text, {
    required String decimalSeparator,
    String? thousandSeparator,
    bool negative = true,
    bool allowCommaDecimalFallback = true,
  }) {
    var normalized = text.trim();
    if (normalized.isEmpty) {
      return '';
    }

    final sign = normalized.startsWith('-') ? '-' : '';
    if (sign.isNotEmpty) {
      if (!negative) {
        return null;
      }
      normalized = normalized.substring(1);
    }

    final groupSeparator = thousandSeparator;
    final useGroupSeparator =
        groupSeparator != null &&
        groupSeparator.isNotEmpty &&
        groupSeparator != decimalSeparator &&
        _looksLikeGroupedInteger(
          normalized,
          groupSeparator: groupSeparator,
          decimalSeparator: decimalSeparator,
        );
    if (useGroupSeparator) {
      normalized = normalized.replaceAll(groupSeparator, '');
    }

    if (decimalSeparator != '.') {
      normalized = normalized.replaceAll(decimalSeparator, '.');
    } else if (allowCommaDecimalFallback &&
        (groupSeparator == null || groupSeparator != ',')) {
      normalized = normalized.replaceAll(',', '.');
    }

    if (normalized.isEmpty || normalized == '.') {
      return null;
    }

    if (normalized.indexOf('.') != normalized.lastIndexOf('.')) {
      return null;
    }

    final parts = normalized.split('.');
    final integerPart = parts.first;
    final decimalPart = parts.length == 1 ? '' : parts[1];

    if (!_isDigits(integerPart) || !_isDigits(decimalPart)) {
      return null;
    }

    final effectiveInteger = integerPart.isEmpty ? '0' : integerPart;
    if (decimalPart.isEmpty && parts.length == 1) {
      return '$sign$effectiveInteger';
    }
    return '$sign$effectiveInteger.$decimalPart';
  }

  static bool _looksLikeGroupedInteger(
    String text, {
    required String groupSeparator,
    required String decimalSeparator,
  }) {
    if (!text.contains(groupSeparator)) {
      return false;
    }

    var integerText = text;
    if (decimalSeparator.isNotEmpty && text.contains(decimalSeparator)) {
      if (text.indexOf(decimalSeparator) !=
          text.lastIndexOf(decimalSeparator)) {
        return false;
      }
      final decimalIndex = text.indexOf(decimalSeparator);
      integerText = text.substring(0, decimalIndex);
      final fractionText = text.substring(
        decimalIndex + decimalSeparator.length,
      );
      if (!_isDigits(fractionText)) {
        return false;
      }
    }

    final parts = integerText.split(groupSeparator);
    if (parts.length < 2 || parts.first.isEmpty || !_isDigits(parts.first)) {
      return false;
    }
    return parts.skip(1).every((part) => part.length == 3 && _isDigits(part));
  }

  static String? normalizeNumberForParsing(num value, {int? scale}) {
    if (!value.isFinite) {
      return null;
    }
    var text = value.toString();
    if (text.contains('e') || text.contains('E')) {
      var fractionDigits = (scale ?? 12) + 6;
      if (fractionDigits < 6) {
        fractionDigits = 6;
      }
      if (fractionDigits > 20) {
        fractionDigits = 20;
      }
      text = value.toStringAsFixed(fractionDigits);
    }
    return normalizeTextForParsing(text, decimalSeparator: '.');
  }

  static String? roundNormalizedText(String normalized, {required int? scale}) {
    if (normalized.isEmpty) {
      return null;
    }

    if (scale == null) {
      return normalized;
    }

    if (scale < 0 || scale > 38) {
      throw RangeError.range(scale, 0, 38, 'scale');
    }

    final negative = normalized.startsWith('-');
    final unsigned = negative ? normalized.substring(1) : normalized;
    if (unsigned.isEmpty || unsigned == '.') {
      return null;
    }
    final parts = unsigned.split('.');
    if (parts.isEmpty || parts.length > 2) {
      return null;
    }

    final integerDigits = parts.first.isEmpty ? <int>[0] : _digits(parts.first);
    final fractionDigits = parts.length == 1 ? <int>[] : _digits(parts[1]);
    if (integerDigits.isEmpty ||
        integerDigits.contains(-1) ||
        fractionDigits.contains(-1)) {
      return null;
    }

    while (fractionDigits.length <= scale) {
      fractionDigits.add(0);
    }

    final roundDigit = fractionDigits[scale];
    final keptFraction = fractionDigits.take(scale).toList();

    if (roundDigit >= 5) {
      var carry = 1;
      for (var i = keptFraction.length - 1; i >= 0; i--) {
        final sum = keptFraction[i] + carry;
        keptFraction[i] = sum % 10;
        carry = sum ~/ 10;
        if (carry == 0) {
          break;
        }
      }
      if (carry != 0) {
        for (var i = integerDigits.length - 1; i >= 0; i--) {
          final sum = integerDigits[i] + carry;
          integerDigits[i] = sum % 10;
          carry = sum ~/ 10;
          if (carry == 0) {
            break;
          }
        }
        if (carry != 0) {
          integerDigits.insert(0, carry);
        }
      }
    }

    final integerPart = _trimLeadingZeroDigits(integerDigits).join();
    final fractionPart = keptFraction.join();
    final sign = negative && !_isZeroDigits(integerDigits, keptFraction)
        ? '-'
        : '';
    if (scale == 0) {
      return '$sign$integerPart';
    }
    return '$sign$integerPart.$fractionPart';
  }

  static bool fitsPrecision(String roundedText, int precision, int scale) {
    if (precision < 1 || precision > 38) {
      throw RangeError.range(precision, 1, 38, 'precision');
    }
    if (scale < 0 || scale > precision) {
      throw RangeError.range(scale, 0, precision, 'scale');
    }

    final unsigned = roundedText.startsWith('-')
        ? roundedText.substring(1)
        : roundedText;
    final integerPart = unsigned.split('.').first;
    final integerDigitsAllowed = precision - scale;
    final integerDigits = integerPart.replaceFirst(RegExp(r'^0+'), '').length;
    // Significant integer digits are zero for values between -1 and 1. This is
    // important for schemas such as decimal(2, 2), where 0.99 is valid even
    // though no non-zero integer digit is allowed.
    return integerDigits <= integerDigitsAllowed;
  }

  static bool _isDigits(String value) {
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (code < 48 || code > 57) {
        return false;
      }
    }
    return true;
  }

  static List<int> _digits(String value) {
    final result = <int>[];
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      if (code < 48 || code > 57) {
        return const [-1];
      }
      result.add(code - 48);
    }
    return result;
  }

  static List<int> _trimLeadingZeroDigits(List<int> digits) {
    var firstNonZero = 0;
    while (firstNonZero < digits.length - 1 && digits[firstNonZero] == 0) {
      firstNonZero++;
    }
    return digits.sublist(firstNonZero);
  }

  static bool _isZeroDigits(List<int> integerDigits, List<int> fractionDigits) {
    return integerDigits.every((digit) => digit == 0) &&
        fractionDigits.every((digit) => digit == 0);
  }
}
