// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/services.dart';

import '../../data/types/fdc_decimal.dart';
import '../format/fdc_decimal_input_formatter.dart';
import '../format/fdc_decimal_math.dart';
import 'fdc_value_codec_base.dart';
import 'fdc_value_parse_result.dart';

class FdcDecimalValueCodec<T> extends FdcValueCodecBase<T> {
  const FdcDecimalValueCodec({required super.config});

  @override
  TextInputType? keyboardType() {
    return const TextInputType.numberWithOptions(decimal: true, signed: true);
  }

  @override
  List<TextInputFormatter>? inputFormatters() {
    return [
      FdcDecimalInputFormatter(
        decimalSeparator: decimalSeparator(),
        thousandSeparator: config.formatSettings.showThousandSeparator
            ? thousandSeparator()
            : null,
        precision: config.precision,
        scale: config.scale,
        negative: config.negative,
      ),
    ];
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
    return switch (_parseDecimalForCommit(text)) {
      _DecimalParseSuccess() => null,
      _DecimalParseError(:final errorText) => errorText,
    };
  }

  @override
  T? parseText(String text) {
    if (text.isEmpty) {
      return null;
    }
    return parseDecimalText(text) as T?;
  }

  @override
  FdcValueParseResult<T> parseForCommit(String text) {
    if (text.trim().isEmpty || isIncompleteDecimalText(text)) {
      return const FdcValueParseResult.success(null, normalizedText: '');
    }

    return switch (_parseDecimalForCommit(text)) {
      _DecimalParseSuccess(:final value, :final normalizedText) =>
        FdcValueParseResult<T>.success(
          value as T?,
          normalizedText: normalizedText,
        ),
      _DecimalParseError(:final errorText) => FdcValueParseResult<T>.error(
        errorText,
      ),
    };
  }

  @override
  String formatValue(Object? value, {bool forEditing = false}) {
    if (value == null) {
      return '';
    }
    if (value is FdcDecimal) {
      return formatDecimal(value, forEditing: forEditing);
    }
    if (value is num) {
      final decimal = FdcDecimal.tryFromNum(value, scale: config.scale ?? 18);
      return decimal == null
          ? ''
          : formatDecimal(decimal, forEditing: forEditing);
    }
    return value.toString();
  }

  @override
  bool isIncompleteDecimalText(String text) {
    return text.trim() == '-';
  }

  String formatDecimal(FdcDecimal value, {required bool forEditing}) {
    final scale = config.scale;
    final fixed = scale == null
        ? value.toString()
        : value.toStringAsFixed(scale);
    final normalized = fixed.replaceAll('.', decimalSeparator());

    if (forEditing || !(config.formatSettings.showThousandSeparator)) {
      return normalized;
    }

    final sign = normalized.startsWith('-') ? '-' : '';
    final unsigned = sign.isEmpty ? normalized : normalized.substring(1);
    final separatorIndex = unsigned.indexOf(decimalSeparator());
    final integerPart = separatorIndex == -1
        ? unsigned
        : unsigned.substring(0, separatorIndex);
    final decimalPart = separatorIndex == -1
        ? ''
        : unsigned.substring(separatorIndex);

    final grouped = StringBuffer();
    for (var i = 0; i < integerPart.length; i++) {
      final remaining = integerPart.length - i;
      grouped.write(integerPart[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        grouped.write(thousandSeparator());
      }
    }

    return '$sign$grouped$decimalPart';
  }

  FdcDecimal? parseDecimalText(String text) {
    return switch (_parseDecimalForCommit(text)) {
      _DecimalParseSuccess(:final value) => value,
      _DecimalParseError() => null,
    };
  }

  _DecimalParseResult _parseDecimalForCommit(String text) {
    final normalized = FdcDecimalMath.normalizeTextForParsing(
      text,
      decimalSeparator: decimalSeparator(),
      thousandSeparator: thousandSeparator(),
      negative: config.negative,
    );
    if (normalized == null) {
      return _DecimalParseResult.error(
        config.validationTranslations.enterValidDecimal,
      );
    }

    final roundedText = FdcDecimalMath.roundNormalizedText(
      normalized,
      scale: config.scale,
    );
    if (roundedText == null) {
      return _DecimalParseResult.error(
        config.validationTranslations.enterValidDecimal,
      );
    }

    if (!_fitsPrecision(roundedText)) {
      final precision = config.precision;
      final scale = config.scale;
      return _DecimalParseResult.error(
        config.validationTranslations.decimalPrecisionExceeded(
          precision,
          scale,
        ),
      );
    }

    final value = FdcDecimal.tryParseNormalized(
      roundedText,
      scale: config.scale ?? 18,
    );
    if (value == null) {
      return _DecimalParseResult.error(
        config.validationTranslations.enterValidDecimal,
      );
    }

    return _DecimalParseResult.success(
      value,
      normalizedText: roundedText.replaceAll('.', decimalSeparator()),
    );
  }

  bool _fitsPrecision(String roundedText) {
    final precision = config.precision;
    final scale = config.scale;
    if (precision == null || scale == null) {
      return true;
    }
    return FdcDecimalMath.fitsPrecision(roundedText, precision, scale);
  }

  String decimalSeparator() {
    return config.formatSettings.decimalSeparator;
  }

  String thousandSeparator() {
    return config.formatSettings.thousandSeparator;
  }
}

sealed class _DecimalParseResult {
  const _DecimalParseResult._();

  const factory _DecimalParseResult.success(
    FdcDecimal value, {
    String? normalizedText,
  }) = _DecimalParseSuccess;

  const factory _DecimalParseResult.error(String errorText) =
      _DecimalParseError;
}

final class _DecimalParseSuccess extends _DecimalParseResult {
  const _DecimalParseSuccess(this.value, {this.normalizedText}) : super._();

  final FdcDecimal value;
  final String? normalizedText;
}

final class _DecimalParseError extends _DecimalParseResult {
  const _DecimalParseError(this.errorText) : super._();

  final String errorText;
}
