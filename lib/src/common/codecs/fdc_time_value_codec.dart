// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../data/types/fdc_time.dart';
import 'fdc_date_like_value_codec.dart';

class FdcTimeValueCodec<T> extends FdcDateLikeValueCodec<T> {
  FdcTimeValueCodec({required super.config});

  @override
  Object? parseDateText(String text) {
    return dateFormatter().parseTime(text) ?? FdcTime.tryParse(text);
  }

  @override
  String formatValue(Object? value, {bool forEditing = false}) {
    if (value == null) {
      return '';
    }
    if (value is FdcTime) {
      return dateFormatter().formatTime(value);
    }
    if (value is TimeOfDay) {
      return dateFormatter().formatTime(
        FdcTime(hour: value.hour, minute: value.minute),
      );
    }
    if (value is DateTime) {
      return dateFormatter().formatTime(FdcTime.fromDateTime(value));
    }
    return value.toString();
  }

  @override
  T? valueFromTimePicker(TimeOfDay picked) {
    return FdcTime(hour: picked.hour, minute: picked.minute) as T?;
  }

  @override
  T? valueFromDatePicker(
    DateTime pickedDate, {
    TimeOfDay? pickedTime,
    DateTime? fallbackDateTime,
  }) {
    final time =
        pickedTime ??
        TimeOfDay.fromDateTime(fallbackDateTime ?? DateTime.now());
    return valueFromTimePicker(time);
  }

  @override
  String dateFormatPattern() {
    return config.formatSettings.timeFormat;
  }
}
