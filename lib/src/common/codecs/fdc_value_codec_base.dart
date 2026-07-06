// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/types/fdc_time.dart';
import '../format/fdc_date_format.dart';
import 'fdc_value_codec_config.dart';
import 'fdc_value_codec_kind.dart';
import 'fdc_value_parse_result.dart';

abstract class FdcValueCodec<T> {
  const FdcValueCodec({required this.config});

  final FdcValueCodecConfig config;

  TextInputType? keyboardType();

  List<TextInputFormatter>? inputFormatters();

  String formatInitialText(String text) {
    final formatters = inputFormatters();
    if (formatters == null || formatters.isEmpty) {
      return text;
    }

    var value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    for (final formatter in formatters) {
      value = formatter.formatEditUpdate(TextEditingValue.empty, value);
    }
    return value.text;
  }

  String? validateText(
    String? value, {
    required bool committing,
    String? localErrorText,
  });

  T? parseText(String text);

  FdcValueParseResult<T> parseForCommit(String text);

  String formatValue(Object? value, {bool forEditing = false});

  Object? parseDateText(String text) => null;

  bool isIncompleteDecimalText(String text) => false;

  DateTime? asDateTime(Object? value) => value is DateTime ? value : null;

  TimeOfDay? asTimeOfDay(Object? value) {
    if (value is TimeOfDay) {
      return value;
    }
    if (value is FdcTime) {
      return TimeOfDay(hour: value.hour, minute: value.minute);
    }
    return null;
  }

  T? valueFromTimePicker(TimeOfDay picked) => null;

  T? valueFromDatePicker(
    DateTime pickedDate, {
    TimeOfDay? pickedTime,
    DateTime? fallbackDateTime,
  }) {
    return pickedDate as T?;
  }

  bool hasCompleteDateInput(String text) => true;

  String completeMissingTrailingYear(String text, int year) => text;

  FdcDateFormat dateFormatter() => FdcDateFormat(dateFormatPattern());

  String dateFormatPattern() => config.formatSettings.dateFormat;

  static bool isDateEditor(FdcValueCodecKind editor) {
    return editor == FdcValueCodecKind.date ||
        editor == FdcValueCodecKind.dateTime ||
        editor == FdcValueCodecKind.time;
  }
}

abstract class FdcValueCodecBase<T> extends FdcValueCodec<T> {
  const FdcValueCodecBase({required super.config});

  @override
  TextInputType? keyboardType() => null;

  @override
  List<TextInputFormatter>? inputFormatters() => null;

  @override
  String? validateText(
    String? value, {
    required bool committing,
    String? localErrorText,
  }) {
    if (localErrorText != null) {
      return localErrorText;
    }
    if (!committing) {
      return null;
    }

    // Required is a semantic dataset validation rule, not a syntax rule for
    // editor text. Leaving a required field empty must not block focus
    // traversal; the dataset will still emit onValidationError and post() will
    // reject the record when the operation owner commits it.
    return null;
  }

  @override
  T? parseText(String text) {
    if (text.isEmpty) {
      return null;
    }
    return text as T?;
  }

  @override
  FdcValueParseResult<T> parseForCommit(String text) {
    final error = validateText(text, committing: true);
    if (error != null) {
      return FdcValueParseResult<T>.error(error);
    }
    return FdcValueParseResult<T>.success(parseText(text));
  }

  @override
  String formatValue(Object? value, {bool forEditing = false}) {
    return value?.toString() ?? '';
  }
}
