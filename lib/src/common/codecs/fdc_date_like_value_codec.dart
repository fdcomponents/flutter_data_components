// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/services.dart';

import '../format/fdc_date_format.dart';
import '../format/fdc_date_input_formatter.dart';
import 'fdc_value_codec_base.dart';
import 'fdc_value_parse_result.dart';

abstract class FdcDateLikeValueCodec<T> extends FdcValueCodecBase<T> {
  FdcDateLikeValueCodec({required super.config});

  FdcDateFormat? _dateFormatter;
  String? _dateFormatterPattern;

  @override
  TextInputType? keyboardType() => TextInputType.datetime;

  @override
  List<TextInputFormatter>? inputFormatters() {
    return [FdcDateInputFormatter(dateFormatPattern())];
  }

  @override
  String? validateText(
    String? value, {
    required bool committing,
    String? localErrorText,
  }) {
    final baseError = super.validateText(
      value,
      committing: committing,
      localErrorText: localErrorText,
    );
    if (baseError != null || !committing) {
      return baseError;
    }

    final text = value ?? '';
    if (text.trim().isEmpty) {
      return null;
    }
    return parseForCommit(text).errorText;
  }

  @override
  T? parseText(String text) {
    if (text.isEmpty) {
      return null;
    }
    return parseDateText(text) as T?;
  }

  @override
  FdcValueParseResult<T> parseForCommit(String text) {
    if (text.trim().isEmpty) {
      return const FdcValueParseResult.success(null);
    }
    final parsedValue = parseDateText(text);
    if (parsedValue == null) {
      return const FdcValueParseResult.success(null);
    }
    return FdcValueParseResult<T>.success(parsedValue as T?);
  }

  @override
  bool hasCompleteDateInput(String text) {
    return dateFormatter().hasCompleteInput(text);
  }

  @override
  String completeMissingTrailingYear(String text, int year) {
    return dateFormatter().completeMissingTrailingYear(text, year) ?? text;
  }

  @override
  FdcDateFormat dateFormatter() {
    final pattern = dateFormatPattern();
    final formatter = _dateFormatter;
    if (formatter != null && _dateFormatterPattern == pattern) {
      return formatter;
    }

    final nextFormatter = FdcDateFormat(pattern);
    _dateFormatter = nextFormatter;
    _dateFormatterPattern = pattern;
    return nextFormatter;
  }
}
