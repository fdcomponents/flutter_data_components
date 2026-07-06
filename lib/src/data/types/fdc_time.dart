// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Time-of-day value used by FdcDataSet time fields.
///
/// The value is date-less, timezone-less, immutable and comparable. Internally
/// it stores 100ns ticks since midnight, matching SQL Server `time(7)` scale.
class FdcTime implements Comparable<FdcTime> {
  /// Creates a [FdcTime].
  factory FdcTime({
    required int hour,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
    int tick100ns = 0,
  }) {
    _checkRange(hour, 0, 23, 'hour');
    _checkRange(minute, 0, 59, 'minute');
    _checkRange(second, 0, 59, 'second');
    _checkRange(millisecond, 0, 999, 'millisecond');
    _checkRange(microsecond, 0, 999, 'microsecond');
    _checkRange(tick100ns, 0, 9, 'tick100ns');

    return FdcTime._(
      hour * ticksPerHour +
          minute * ticksPerMinute +
          second * ticksPerSecond +
          millisecond * ticksPerMillisecond +
          microsecond * ticksPerMicrosecond +
          tick100ns,
    );
  }

  const FdcTime._(this.ticksSinceMidnight);

  /// Creates a [FdcTime].
  factory FdcTime.fromDateTime(DateTime value) {
    return FdcTime(
      hour: value.hour,
      minute: value.minute,
      second: value.second,
      millisecond: value.millisecond,
      microsecond: value.microsecond,
    );
  }

  /// Creates a [FdcTime].
  factory FdcTime.fromTicksSinceMidnight(int ticksSinceMidnight) {
    _checkRange(ticksSinceMidnight, 0, ticksPerDay - 1, 'ticksSinceMidnight');
    return FdcTime._(ticksSinceMidnight);
  }

  /// Parses a time-of-day string, returning `null` when the text is invalid.
  static FdcTime? tryParse(String text) {
    try {
      return parse(text);
    } on FormatException {
      return null;
      // ignore: avoid_catching_errors
    } on RangeError {
      return null;
    }
  }

  /// Parses `HH:mm`, `HH:mm:ss`, or `HH:mm:ss.fffffff`.
  ///
  /// Fractional seconds accept 1..7 digits and are right-padded to SQL Server
  /// `time(7)` 100ns precision.
  static FdcTime parse(String text) {
    final trimmed = text.trim();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2})(?:\.(\d{1,7}))?)?$',
    ).firstMatch(trimmed);
    if (match == null) {
      throw FormatException('Invalid FdcTime value.', text);
    }

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final second = int.parse(match.group(3) ?? '0');
    final fractionText = (match.group(4) ?? '').padRight(7, '0');
    final fractionTicks = fractionText.isEmpty ? 0 : int.parse(fractionText);

    _checkRange(hour, 0, 23, 'hour');
    _checkRange(minute, 0, 59, 'minute');
    _checkRange(second, 0, 59, 'second');

    return FdcTime._(
      hour * ticksPerHour +
          minute * ticksPerMinute +
          second * ticksPerSecond +
          fractionTicks,
    );
  }

  /// Default value for ticks per microsecond.
  static const int ticksPerMicrosecond = 10;

  /// Default value for ticks per millisecond.
  static const int ticksPerMillisecond = 10000;

  /// Default value for ticks per second.
  static const int ticksPerSecond = 10000000;

  /// Default value for ticks per minute.
  static const int ticksPerMinute = 60 * ticksPerSecond;

  /// Default value for ticks per hour.
  static const int ticksPerHour = 60 * ticksPerMinute;

  /// Default value for ticks per day.
  static const int ticksPerDay = 24 * ticksPerHour;

  /// 100ns ticks since midnight. Range: `0..863999999999`.
  final int ticksSinceMidnight;

  /// Returns the current hour.
  int get hour => ticksSinceMidnight ~/ ticksPerHour;

  /// Returns the current minute.
  int get minute => (ticksSinceMidnight % ticksPerHour) ~/ ticksPerMinute;

  /// Returns the current second.
  int get second => (ticksSinceMidnight % ticksPerMinute) ~/ ticksPerSecond;

  /// Returns the current fraction ticks.
  int get fractionTicks => ticksSinceMidnight % ticksPerSecond;

  /// Returns the current millisecond.
  int get millisecond => fractionTicks ~/ ticksPerMillisecond;

  /// Returns the current microsecond.
  int get microsecond =>
      (fractionTicks % ticksPerMillisecond) ~/ ticksPerMicrosecond;

  /// Returns the current tick100ns.
  int get tick100ns => fractionTicks % ticksPerMicrosecond;

  /// Returns this time rounded to fractional-second [scale] precision.
  FdcTime roundedToScale(int scale) {
    _checkRange(scale, 0, 7, 'scale');

    final divisor = _scaleDivisor(scale);
    if (divisor == 1) {
      return this;
    }

    final roundedTicks = _roundToNearestTick(ticksSinceMidnight, divisor);
    return FdcTime._(
      roundedTicks >= ticksPerDay ? ticksPerDay - 1 : roundedTicks,
    );
  }

  /// Formats this value as a SQL-compatible time literal with [scale] precision.
  String toSqlString({int scale = 7}) {
    _checkRange(scale, 0, 7, 'scale');

    final rounded = roundedToScale(scale);
    final base =
        '${rounded.hour.toString().padLeft(2, '0')}:'
        '${rounded.minute.toString().padLeft(2, '0')}:'
        '${rounded.second.toString().padLeft(2, '0')}';
    if (scale == 0) {
      return base;
    }

    final fraction = rounded.fractionTicks.toString().padLeft(7, '0');
    return '$base.${fraction.substring(0, scale)}';
  }

  @override
  int compareTo(FdcTime other) =>
      ticksSinceMidnight.compareTo(other.ticksSinceMidnight);

  @override
  bool operator ==(Object other) =>
      other is FdcTime && other.ticksSinceMidnight == ticksSinceMidnight;

  @override
  int get hashCode => ticksSinceMidnight.hashCode;

  @override
  String toString() => toSqlString();

  static int _scaleDivisor(int scale) {
    var divisor = 1;
    for (var i = 0; i < 7 - scale; i++) {
      divisor *= 10;
    }
    return divisor;
  }

  static int _roundToNearestTick(int value, int divisor) {
    final half = divisor ~/ 2;
    return ((value + half) ~/ divisor) * divisor;
  }

  static void _checkRange(int value, int min, int max, String name) {
    if (value < min || value > max) {
      throw RangeError.range(value, min, max, name);
    }
  }
}
