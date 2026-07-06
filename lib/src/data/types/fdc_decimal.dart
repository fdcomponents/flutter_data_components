// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/format/fdc_decimal_math.dart';

/// Fixed-scale decimal value used by decimal field runtime values.
///
/// The value is stored as an integer scaled by [scale], so decimal input does
/// not lose precision through binary floating point representation. Use
/// [toString] or [toStringAsFixed] for exact text output, and [toNum] only when
/// interoperating with UI/progress/filter code that still expects numeric
/// values.
class FdcDecimal implements Comparable<FdcDecimal> {
  FdcDecimal._(this.scaledValue, this.scale) {
    RangeError.checkValueInInterval(scale, 0, 38, 'scale');
  }

  /// Creates a decimal from an already scaled integer value.
  factory FdcDecimal.fromScaled(BigInt scaledValue, {required int scale}) {
    return FdcDecimal._(scaledValue, scale);
  }

  /// Creates a decimal from a finite Dart number.
  ///
  /// When [scale] is omitted, the scale is inferred from the number's decimal
  /// text representation. Pass [scale] to normalize the value to a field-like
  /// fixed scale.
  factory FdcDecimal.fromNum(num value, {int? scale}) {
    final decimal = tryFromNum(value, scale: scale);
    if (decimal == null) {
      throw ArgumentError.value(value, 'value', 'Expected a finite number.');
    }
    return decimal;
  }

  /// Parses decimal text.
  ///
  /// When [scale] is omitted, the scale is inferred from the parsed text. Pass
  /// [scale] to round and normalize the value to a fixed number of decimals.
  factory FdcDecimal.parse(
    String text, {
    int? scale,
    String decimalSeparator = '.',
    String? thousandSeparator,
    bool negative = true,
    bool allowCommaDecimalFallback = true,
  }) {
    final decimal = tryParse(
      text,
      scale: scale,
      decimalSeparator: decimalSeparator,
      thousandSeparator: thousandSeparator,
      negative: negative,
      allowCommaDecimalFallback: allowCommaDecimalFallback,
    );
    if (decimal == null) {
      throw FormatException('Invalid decimal value.', text);
    }
    return decimal;
  }

  /// Creates a decimal from a normalized numeric text using `.` as decimal
  /// separator. The text may be rounded to [scale] before storage.
  factory FdcDecimal.parseNormalized(
    String normalizedText, {
    required int scale,
  }) {
    final parsed = tryParseNormalized(normalizedText, scale: scale);
    if (parsed == null) {
      throw FormatException('Invalid decimal value.', normalizedText);
    }
    return parsed;
  }

  /// Parses normalized decimal text, returning `null` for invalid input.
  static FdcDecimal? tryParseNormalized(
    String normalizedText, {
    required int scale,
  }) {
    final rounded = FdcDecimalMath.roundNormalizedText(
      normalizedText,
      scale: scale,
    );
    if (rounded == null) {
      return null;
    }
    return _fromRoundedNormalized(rounded, scale: scale);
  }

  /// Parses user text using optional localized separators and stores it at the
  /// requested [scale].
  static FdcDecimal? tryParse(
    String text, {
    int? scale,
    String decimalSeparator = '.',
    String? thousandSeparator,
    bool negative = true,
    bool allowCommaDecimalFallback = true,
  }) {
    final normalized = FdcDecimalMath.normalizeTextForParsing(
      text,
      decimalSeparator: decimalSeparator,
      thousandSeparator: thousandSeparator,
      negative: negative,
      allowCommaDecimalFallback: allowCommaDecimalFallback,
    );
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final effectiveScale = scale ?? _fractionScale(normalized);
    return tryParseNormalized(normalized, scale: effectiveScale);
  }

  /// Converts a finite [num] through its decimal text representation.
  ///
  /// When [scale] is omitted, the scale is inferred from the number's decimal
  /// text representation. Pass [scale] to round and normalize the value to a
  /// fixed number of decimals.
  static FdcDecimal? tryFromNum(num value, {int? scale}) {
    if (!value.isFinite) {
      return null;
    }
    if (scale != null) {
      final normalized = FdcDecimalMath.normalizeNumberForParsing(
        value,
        scale: scale,
      );
      if (normalized == null) {
        return null;
      }
      return tryParseNormalized(normalized, scale: scale);
    }

    final text = _normalizedFiniteNumText(value);
    return tryParseNormalized(text, scale: _fractionScale(text));
  }

  /// Returns the current zero.
  static FdcDecimal get zero => FdcDecimal.fromScaled(BigInt.zero, scale: 0);

  /// Returns the current one.
  static FdcDecimal get one => FdcDecimal.fromScaled(BigInt.one, scale: 0);

  static FdcDecimal? _fromRoundedNormalized(
    String roundedText, {
    required int scale,
  }) {
    final negative = roundedText.startsWith('-');
    final unsigned = negative ? roundedText.substring(1) : roundedText;
    final parts = unsigned.split('.');
    if (parts.isEmpty || parts.length > 2) {
      return null;
    }

    final integerPart = parts.first.isEmpty ? '0' : parts.first;
    final fractionPart = parts.length == 1 ? '' : parts[1];
    if (!_isDigits(integerPart) || !_isDigits(fractionPart)) {
      return null;
    }

    final paddedFraction = fractionPart.padRight(scale, '0');
    if (paddedFraction.length > scale) {
      return null;
    }

    final digits = '$integerPart$paddedFraction';
    final parsed = BigInt.tryParse(digits.isEmpty ? '0' : digits);
    if (parsed == null) {
      return null;
    }

    final signed = negative && parsed != BigInt.zero ? -parsed : parsed;
    return FdcDecimal._(signed, scale);
  }

  /// Integer value scaled by 10^[scale].
  final BigInt scaledValue;

  /// Number of decimal fraction digits represented by [scaledValue].
  final int scale;

  /// True when the represented decimal value is exactly zero.
  ///
  /// Scale does not affect the result, so zero values with different scales all
  /// report `true`.
  bool get isZero => scaledValue == BigInt.zero;

  /// True when the represented decimal value is less than zero.
  ///
  /// Zero is never negative, regardless of scale.
  bool get isNegative => scaledValue.isNegative;

  /// Converts this decimal to an `int` when exact, otherwise to a `double`.
  num toNum() {
    if (scale == 0) {
      final asInt = scaledValue.toInt();
      if (BigInt.from(asInt) == scaledValue) {
        return asInt;
      }
    }
    return toDouble();
  }

  /// Converts this decimal to a double-precision floating-point value.
  double toDouble() => scaledValue.toDouble() / _pow10(scale).toDouble();

  /// Truncates the fractional part and returns the integer component.
  int toInt() => toNum().toInt();

  /// Adds [other] to this decimal and keeps the larger operand scale.
  FdcDecimal operator +(Object other) {
    final right = _coerceOperand(other, operation: '+');
    final commonScale = scale > right.scale ? scale : right.scale;
    final leftScaled = _rescaleExact(
      scaledValue,
      fromScale: scale,
      toScale: commonScale,
    );
    final rightScaled = _rescaleExact(
      right.scaledValue,
      fromScale: right.scale,
      toScale: commonScale,
    );
    return FdcDecimal.fromScaled(leftScaled + rightScaled, scale: commonScale);
  }

  /// Subtracts [other] from this decimal and keeps the larger operand scale.
  FdcDecimal operator -(Object other) {
    final right = _coerceOperand(other, operation: '-');
    final commonScale = scale > right.scale ? scale : right.scale;
    final leftScaled = _rescaleExact(
      scaledValue,
      fromScale: scale,
      toScale: commonScale,
    );
    final rightScaled = _rescaleExact(
      right.scaledValue,
      fromScale: right.scale,
      toScale: commonScale,
    );
    return FdcDecimal.fromScaled(leftScaled - rightScaled, scale: commonScale);
  }

  /// Multiplies this decimal by [other]. The exact result scale is the sum of
  /// the operand scales. When that would exceed the supported decimal scale
  /// range, the result is rounded back to scale 38 instead of throwing for two
  /// otherwise valid decimal operands.
  FdcDecimal operator *(Object other) {
    final right = _coerceOperand(other, operation: '*');
    final resultScale = scale + right.scale;
    final resultValue = scaledValue * right.scaledValue;
    if (resultScale <= 38) {
      return FdcDecimal.fromScaled(resultValue, scale: resultScale);
    }
    return FdcDecimal.fromScaled(
      _rescaleRounded(resultValue, fromScale: resultScale, toScale: 38),
      scale: 38,
    );
  }

  /// Divides this decimal by [other]. Division by zero returns a non-finite
  /// numeric value so calculated field validation can report the error instead
  /// of failing during calculation.
  dynamic operator /(Object other) {
    final right = _coerceOperand(other, operation: '/');
    if (right.scaledValue == BigInt.zero) {
      if (scaledValue == BigInt.zero) {
        return double.nan;
      }
      return scaledValue.isNegative ? double.negativeInfinity : double.infinity;
    }

    final resultScale = _max3(scale, right.scale, 12);
    final numerator = scaledValue * _pow10(right.scale + resultScale);
    final denominator = right.scaledValue * _pow10(scale);
    final negative =
        (numerator.isNegative && !denominator.isNegative) ||
        (!numerator.isNegative && denominator.isNegative);
    final absNumerator = numerator.abs();
    final absDenominator = denominator.abs();
    final quotient = absNumerator ~/ absDenominator;
    final remainder = absNumerator % absDenominator;
    final rounded = remainder * BigInt.from(2) >= absDenominator
        ? quotient + BigInt.one
        : quotient;
    return FdcDecimal.fromScaled(
      negative ? -rounded : rounded,
      scale: resultScale,
    );
  }

  /// Returns the remainder after dividing this decimal by [other].
  FdcDecimal operator %(Object other) {
    final right = _coerceOperand(other, operation: '%');
    if (right.scaledValue == BigInt.zero) {
      throw UnsupportedError('Division by zero');
    }

    final commonScale = scale > right.scale ? scale : right.scale;
    final leftScaled = _rescaleExact(
      scaledValue,
      fromScale: scale,
      toScale: commonScale,
    );
    final rightScaled = _rescaleExact(
      right.scaledValue,
      fromScale: right.scale,
      toScale: commonScale,
    );
    return FdcDecimal.fromScaled(leftScaled % rightScaled, scale: commonScale);
  }

  /// Integer division using decimal-safe operands.
  int operator ~/(Object other) {
    final right = _coerceOperand(other, operation: '~/');
    if (right.scaledValue == BigInt.zero) {
      throw UnsupportedError('Division by zero');
    }

    final commonScale = scale > right.scale ? scale : right.scale;
    final leftScaled = _rescaleExact(
      scaledValue,
      fromScale: scale,
      toScale: commonScale,
    );
    final rightScaled = _rescaleExact(
      right.scaledValue,
      fromScale: right.scale,
      toScale: commonScale,
    );
    return (leftScaled ~/ rightScaled).toInt();
  }

  /// Returns whether this decimal is less than [other].
  bool operator <(Object other) => _compareObject(other, operation: '<') < 0;

  /// Returns whether this decimal is less than or equal to [other].
  bool operator <=(Object other) => _compareObject(other, operation: '<=') <= 0;

  /// Returns whether this decimal is greater than [other].
  bool operator >(Object other) => _compareObject(other, operation: '>') > 0;

  /// Returns whether this decimal is greater than or equal to [other].
  bool operator >=(Object other) => _compareObject(other, operation: '>=') >= 0;

  /// Returns this decimal with the sign inverted.
  FdcDecimal operator -() => FdcDecimal.fromScaled(-scaledValue, scale: scale);

  /// Returns the absolute value.
  FdcDecimal abs() => isNegative ? -this : this;

  /// Rounds to the nearest integer value.
  int round() => _roundToInteger().toInt();

  /// Returns the greatest integer value not greater than this value.
  int floor() => _floorToInteger().toInt();

  /// Returns the smallest integer value not less than this value.
  int ceil() => _ceilToInteger().toInt();

  /// Removes the fractional part toward zero.
  int truncate() => _truncateToInteger().toInt();

  /// Clamps this value to the inclusive range from [lowerLimit] to [upperLimit].
  FdcDecimal clamp(Object lowerLimit, Object upperLimit) {
    final lower = _coerceOperand(lowerLimit, operation: 'clamp');
    final upper = _coerceOperand(upperLimit, operation: 'clamp');
    if (lower > upper) {
      throw ArgumentError.value(
        upperLimit,
        'upperLimit',
        'Must be greater than or equal to lowerLimit.',
      );
    }
    if (this < lower) {
      return lower;
    }
    if (this > upper) {
      return upper;
    }
    return this;
  }

  /// Formats with exactly [fractionDigits] digits after the decimal point.
  String toStringAsFixed([int? fractionDigits]) {
    final targetScale = fractionDigits ?? scale;
    RangeError.checkValueInInterval(targetScale, 0, 38, 'fractionDigits');

    final value = targetScale == scale
        ? scaledValue
        : _rescaleRounded(scaledValue, fromScale: scale, toScale: targetScale);

    final negative = value.isNegative;
    var digits = value.abs().toString();
    if (targetScale == 0) {
      return '${negative && value != BigInt.zero ? '-' : ''}$digits';
    }

    digits = digits.padLeft(targetScale + 1, '0');
    final split = digits.length - targetScale;
    final integerPart = digits.substring(0, split);
    final fractionPart = digits.substring(split);
    final sign = negative && value != BigInt.zero ? '-' : '';
    return '$sign$integerPart.$fractionPart';
  }

  @override
  String toString() => toStringAsFixed(scale);

  @override
  int compareTo(FdcDecimal other) {
    if (scale == other.scale) {
      return scaledValue.compareTo(other.scaledValue);
    }
    final commonScale = scale > other.scale ? scale : other.scale;
    final left = _rescaleExact(
      scaledValue,
      fromScale: scale,
      toScale: commonScale,
    );
    final right = _rescaleExact(
      other.scaledValue,
      fromScale: other.scale,
      toScale: commonScale,
    );
    return left.compareTo(right);
  }

  @override
  bool operator ==(Object other) {
    // Equality is intentionally restricted to FdcDecimal values. Accepting
    // Dart num here would make equality asymmetric because int/double do not
    // know how to compare themselves back to FdcDecimal, and it would also
    // break the ==/hashCode contract for Set/Map keys. Use comparison
    // operators or convert the literal with `.decimal` for numeric checks.
    return other is FdcDecimal && compareTo(other) == 0;
  }

  @override
  int get hashCode {
    final canonical = _canonicalScaledValueAndScale();
    return Object.hash(canonical.$1, canonical.$2);
  }

  int _compareObject(Object other, {required String operation}) {
    return compareTo(_coerceOperand(other, operation: operation));
  }

  (BigInt, int) _canonicalScaledValueAndScale() {
    if (scaledValue == BigInt.zero) {
      return (BigInt.zero, 0);
    }

    var value = scaledValue;
    var canonicalScale = scale;
    while (canonicalScale > 0 && value % BigInt.from(10) == BigInt.zero) {
      value ~/= BigInt.from(10);
      canonicalScale--;
    }
    return (value, canonicalScale);
  }

  BigInt _truncateToInteger() {
    if (scale == 0) {
      return scaledValue;
    }
    return scaledValue ~/ _pow10(scale);
  }

  BigInt _floorToInteger() {
    if (scale == 0) {
      return scaledValue;
    }

    final divisor = _pow10(scale);
    final quotient = scaledValue ~/ divisor;
    final remainder = scaledValue.abs() % divisor;
    if (scaledValue.isNegative && remainder != BigInt.zero) {
      return quotient - BigInt.one;
    }
    return quotient;
  }

  BigInt _ceilToInteger() {
    if (scale == 0) {
      return scaledValue;
    }

    final divisor = _pow10(scale);
    final quotient = scaledValue ~/ divisor;
    final remainder = scaledValue.abs() % divisor;
    if (!scaledValue.isNegative && remainder != BigInt.zero) {
      return quotient + BigInt.one;
    }
    return quotient;
  }

  BigInt _roundToInteger() {
    if (scale == 0) {
      return scaledValue;
    }

    final divisor = _pow10(scale);
    final negative = scaledValue.isNegative;
    final abs = scaledValue.abs();
    final quotient = abs ~/ divisor;
    final remainder = abs % divisor;
    final rounded = remainder * BigInt.from(2) >= divisor
        ? quotient + BigInt.one
        : quotient;
    return negative ? -rounded : rounded;
  }

  static FdcDecimal _coerceOperand(Object other, {required String operation}) {
    if (other is FdcDecimal) {
      return other;
    }
    if (other is int) {
      return FdcDecimal.fromScaled(BigInt.from(other), scale: 0);
    }
    if (other is num && other.isFinite) {
      final text = _normalizedFiniteNumText(other);
      final operandScale = _fractionScale(text);
      final decimal = FdcDecimal.tryParseNormalized(text, scale: operandScale);
      if (decimal != null) {
        return decimal;
      }
    }
    throw ArgumentError.value(
      other,
      'other',
      'Unsupported operand for FdcDecimal $operation. '
          'Expected finite num or FdcDecimal.',
    );
  }

  static String _normalizedFiniteNumText(num value) {
    var text = value.toString();
    if (text.contains('e') || text.contains('E')) {
      text = value.toStringAsFixed(20);
    }
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      if (text.endsWith('.')) {
        text = text.substring(0, text.length - 1);
      }
    }
    return text == '-0' ? '0' : text;
  }

  static int _fractionScale(String normalizedText) {
    final dot = normalizedText.indexOf('.');
    return dot < 0 ? 0 : normalizedText.length - dot - 1;
  }

  static int _max3(int a, int b, int c) {
    final ab = a > b ? a : b;
    return ab > c ? ab : c;
  }

  static BigInt _rescaleExact(
    BigInt value, {
    required int fromScale,
    required int toScale,
  }) {
    if (toScale == fromScale) {
      return value;
    }
    if (toScale > fromScale) {
      return value * _pow10(toScale - fromScale);
    }
    return value ~/ _pow10(fromScale - toScale);
  }

  static BigInt _rescaleRounded(
    BigInt value, {
    required int fromScale,
    required int toScale,
  }) {
    if (toScale >= fromScale) {
      return _rescaleExact(value, fromScale: fromScale, toScale: toScale);
    }

    final divisor = _pow10(fromScale - toScale);
    final negative = value.isNegative;
    final abs = value.abs();
    final quotient = abs ~/ divisor;
    final remainder = abs % divisor;
    final shouldRound = remainder * BigInt.from(2) >= divisor;
    final rounded = shouldRound ? quotient + BigInt.one : quotient;
    return negative ? -rounded : rounded;
  }

  static BigInt _pow10(int exponent) {
    var result = BigInt.one;
    for (var i = 0; i < exponent; i++) {
      result *= BigInt.from(10);
    }
    return result;
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
}

/// Convenience conversion from Dart numeric literals to [FdcDecimal].
///
/// Examples:
///
/// ```dart
/// final amount = 100.decimal;
///
/// final taxRate = 0.25.decimal;
///
/// final fixed = 100.decimalScale(2); // 100.00
/// ```
extension FdcDecimalNumExtension on num {
  /// Converts this numeric value to [FdcDecimal] using its inferred decimal scale.
  FdcDecimal get decimal => FdcDecimal.fromNum(this);

  /// Converts this value to [FdcDecimal] using exactly [scale] fractional digits.
  FdcDecimal decimalScale(int scale) => FdcDecimal.fromNum(this, scale: scale);
}

/// Convenience conversion from decimal text to [FdcDecimal].
///
/// String parsing is useful when the exact decimal text matters more than a
/// Dart numeric literal's binary floating point representation.
extension FdcDecimalStringExtension on String {
  /// Converts this numeric value to [FdcDecimal] using its inferred decimal scale.
  FdcDecimal get decimal => FdcDecimal.parse(this);

  /// Converts this value to [FdcDecimal] using exactly [scale] fractional digits.
  FdcDecimal decimalScale(int scale) => FdcDecimal.parse(this, scale: scale);
}
