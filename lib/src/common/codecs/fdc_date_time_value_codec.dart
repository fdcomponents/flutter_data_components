// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../format/fdc_date_format.dart';
import 'fdc_date_like_value_codec.dart';
import 'fdc_value_parse_result.dart';

class FdcDateTimeValueCodec<T> extends FdcDateLikeValueCodec<T> {
  FdcDateTimeValueCodec({required super.config});

  FdcDateFormat? _dateOnlyFormatter;
  String? _dateOnlyFormatterPattern;

  @override
  Object? parseDateText(String text) {
    final parsedDateTime = dateFormatter().parseDate(text);
    if (parsedDateTime != null) {
      return parsedDateTime;
    }

    final parsedDate = _dateOnlyFormatterForDateTime().parseDate(text);
    if (parsedDate == null) {
      return null;
    }

    return DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
  }

  @override
  FdcValueParseResult<T> parseForCommit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const FdcValueParseResult.success(null);
    }

    final parsedDateTime = dateFormatter().parseDate(trimmed);
    if (parsedDateTime != null) {
      return FdcValueParseResult<T>.success(parsedDateTime as T?);
    }

    final parsedDate = _dateOnlyFormatterForDateTime().parseDate(trimmed);
    if (parsedDate == null) {
      return const FdcValueParseResult.success(null);
    }

    final normalizedValue = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
    );
    return FdcValueParseResult<T>.success(
      normalizedValue as T?,
      normalizedText: dateFormatter().formatDate(normalizedValue),
    );
  }

  @override
  bool hasCompleteDateInput(String text) {
    final trimmed = text.trim();
    return dateFormatter().hasCompleteInput(trimmed) ||
        _dateOnlyFormatterForDateTime().hasCompleteInput(trimmed);
  }

  @override
  String formatValue(Object? value, {bool forEditing = false}) {
    if (value == null) {
      return '';
    }
    if (value is DateTime) {
      return dateFormatter().formatDate(value);
    }
    return value.toString();
  }

  @override
  T? valueFromDatePicker(
    DateTime pickedDate, {
    TimeOfDay? pickedTime,
    DateTime? fallbackDateTime,
  }) {
    final fallback = fallbackDateTime ?? DateTime.now();
    return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime?.hour ?? fallback.hour,
          pickedTime?.minute ?? fallback.minute,
        )
        as T?;
  }

  @override
  String dateFormatPattern() {
    return config.formatSettings.effectiveDateTimeFormat;
  }

  FdcDateFormat _dateOnlyFormatterForDateTime() {
    final pattern = config.formatSettings.dateFormat;
    final formatter = _dateOnlyFormatter;
    if (formatter != null && _dateOnlyFormatterPattern == pattern) {
      return formatter;
    }

    final nextFormatter = FdcDateFormat(pattern);
    _dateOnlyFormatter = nextFormatter;
    _dateOnlyFormatterPattern = pattern;
    return nextFormatter;
  }
}
