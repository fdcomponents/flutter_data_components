// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/material.dart';

import '../../data/types/fdc_time.dart';
import '../codecs/fdc_value_codec.dart';

@internal
class FdcValuePicker {
  const FdcValuePicker._();

  static Future<Object?> pick({
    required BuildContext context,
    required FdcValueCodecKind kind,
    required Object? currentValue,
    FdcValueCodec<Object?>? codec,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return switch (kind) {
      FdcValueCodecKind.time => _pickTime(
        context: context,
        currentValue: currentValue,
        codec: codec,
      ),
      FdcValueCodecKind.date => _pickDate(
        context: context,
        currentValue: currentValue,
        codec: codec,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
      FdcValueCodecKind.dateTime => _pickDateTime(
        context: context,
        currentValue: currentValue,
        codec: codec,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
      _ => null,
    };
  }

  static Future<Object?> _pickTime({
    required BuildContext context,
    required Object? currentValue,
    required FdcValueCodec<Object?>? codec,
  }) async {
    final initialTime =
        codec?.asTimeOfDay(currentValue) ??
        _timeOfDayFromValue(currentValue) ??
        TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null) {
      return null;
    }

    return codec?.valueFromTimePicker(picked) ??
        FdcTime(hour: picked.hour, minute: picked.minute);
  }

  static Future<Object?> _pickDate({
    required BuildContext context,
    required Object? currentValue,
    required FdcValueCodec<Object?>? codec,
    required DateTime? firstDate,
    required DateTime? lastDate,
  }) async {
    final initialDate =
        codec?.asDateTime(currentValue) ??
        _dateTimeFromValue(currentValue) ??
        DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
    );
    if (pickedDate == null) {
      return null;
    }

    return codec?.valueFromDatePicker(pickedDate) ?? pickedDate;
  }

  static Future<Object?> _pickDateTime({
    required BuildContext context,
    required Object? currentValue,
    required FdcValueCodec<Object?>? codec,
    required DateTime? firstDate,
    required DateTime? lastDate,
  }) async {
    final initialDate =
        codec?.asDateTime(currentValue) ??
        _dateTimeFromValue(currentValue) ??
        DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
    );
    if (pickedDate == null) {
      return null;
    }

    if (!context.mounted) {
      return null;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null) {
      return null;
    }

    return codec?.valueFromDatePicker(
          pickedDate,
          pickedTime: pickedTime,
          fallbackDateTime: initialDate,
        ) ??
        DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
  }

  static DateTime? _dateTimeFromValue(Object? value) {
    return value is DateTime ? value : null;
  }

  static TimeOfDay? _timeOfDayFromValue(Object? value) {
    if (value is TimeOfDay) {
      return value;
    }
    if (value is FdcTime) {
      return TimeOfDay(hour: value.hour, minute: value.minute);
    }
    if (value is DateTime) {
      return TimeOfDay.fromDateTime(value);
    }
    return null;
  }
}
