// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/services.dart';

import '../format/fdc_integer_input_formatter.dart';
import 'fdc_value_codec_base.dart';
import 'fdc_value_parse_result.dart';

class FdcIntegerValueCodec<T> extends FdcValueCodecBase<T> {
  const FdcIntegerValueCodec({required super.config});

  @override
  TextInputType? keyboardType() => TextInputType.number;

  @override
  List<TextInputFormatter>? inputFormatters() {
    return [FdcIntegerInputFormatter(negative: config.negative)];
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
    final errorText = _integerParseError(text);
    if (errorText != null) {
      return errorText;
    }
    return null;
  }

  @override
  T? parseText(String text) {
    if (text.isEmpty) {
      return null;
    }
    final value = _parseIntegerValue(text);
    return _tryCastValue(value);
  }

  @override
  FdcValueParseResult<T> parseForCommit(String text) {
    if (text.isEmpty) {
      return FdcValueParseResult<T>.success(null);
    }
    final errorText = _integerParseError(text);
    if (errorText != null) {
      return FdcValueParseResult<T>.error(errorText);
    }
    final value = _parseIntegerValue(text);
    final typedValue = _tryCastValue(value);
    if (value != null && typedValue == null) {
      return FdcValueParseResult<T>.error(
        config.validationTranslations.enterValidInteger,
      );
    }
    return FdcValueParseResult<T>.success(typedValue);
  }

  Object? _parseIntegerValue(String text) {
    final intValue = int.tryParse(text);
    if (intValue != null) {
      return intValue;
    }
    return BigInt.tryParse(text);
  }

  T? _tryCastValue(Object? value) {
    if (value == null) {
      return null;
    }
    try {
      return value as T?;
      // ignore: avoid_catching_errors
    } on TypeError {
      return null;
    }
  }

  String? _integerParseError(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final digits = trimmed.startsWith('-') || trimmed.startsWith('+')
        ? trimmed.substring(1)
        : trimmed;
    final isPlainInteger =
        digits.isNotEmpty &&
        digits.runes.every((rune) => rune >= 0x30 && rune <= 0x39);
    if (!isPlainInteger) {
      return config.validationTranslations.enterValidInteger;
    }

    if (BigInt.tryParse(trimmed) == null) {
      return config.validationTranslations.enterValidInteger;
    }

    return null;
  }
}
