// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../common/codecs/fdc_value_codec.dart';
import '../../common/format/fdc_date_format.dart';
import '../../common/format/fdc_format_settings.dart';
import '../../data/fdc_data.dart';
import '../../i18n/fdc_translations.dart';
import '../columns/fdc_grid_columns.dart';
import '../format/fdc_field_value_codec.dart';
import '../models/fdc_column_identity.dart';

class FdcHeaderFilterValueCodec {
  const FdcHeaderFilterValueCodec({
    required this.formatSettings,
    required this.dataTypeOf,
    required this.decimalScaleOf,
    required this.decimalPrecisionOf,
    required this.runtimeColumnIdOf,
    this.translations = const FdcTranslations(),
  });

  final FdcFormatSettings formatSettings;
  final FdcDataType Function(FdcGridColumn<dynamic> column) dataTypeOf;
  final int? Function(FdcGridColumn<dynamic> column) decimalScaleOf;
  final int? Function(FdcGridColumn<dynamic> column) decimalPrecisionOf;
  final FdcColumnIdentity? Function(FdcGridColumn<dynamic> column)
  runtimeColumnIdOf;
  final FdcTranslations translations;

  String formatDisplayValue(
    FdcGridColumn<dynamic> column,
    Object? value, {
    FdcColumnIdentity? runtimeColumnId,
  }) {
    if (value == null) {
      return '';
    }

    final resolvedRuntimeColumnId =
        runtimeColumnId ?? runtimeColumnIdOf(column);
    final codec = FdcFieldValueCodec(
      settings: formatSettings,
      translations: translations,
    );
    if (dataTypeOf(column) == FdcDataType.decimal) {
      final scale = decimalScaleOf(column);
      final parsed = value is FdcDecimal
          ? value
          : value is String && scale != null
          ? _tryParseNormalizedDecimalText(value, scale: scale) ??
                parseValue(
                  column,
                  value,
                  runtimeColumnId: resolvedRuntimeColumnId,
                )
          : parseValue(column, value, runtimeColumnId: resolvedRuntimeColumnId);
      if (parsed != null) {
        return codec.formatDecimal(
          parsed,
          forEditing: false,
          scale: scale,
          formatSettings: column.formatSettings ?? formatSettings,
        );
      }
    }

    return codec.formatGridValue(
      column,
      value,
      runtimeColumnId: resolvedRuntimeColumnId,
      forEditing: true,
      decimalScale: decimalScaleOf(column),
    );
  }

  bool isTextReadyToApply(FdcGridColumn<dynamic> column, String value) {
    if (value.isEmpty) {
      return true;
    }

    final dataType = dataTypeOf(column);

    if (dataType == FdcDataType.integer || dataType == FdcDataType.decimal) {
      return parseValue(column, value) != null;
    }

    if (dataType == FdcDataType.date) {
      return _canParseCompleteDate(value, column);
    }

    if (dataType == FdcDataType.dateTime) {
      return _canParseCompleteDateTime(value, column);
    }

    if (dataType == FdcDataType.time) {
      return _canParseCompleteTime(value, column);
    }

    return true;
  }

  FdcDecimal? _tryParseNormalizedDecimalText(
    String text, {
    required int scale,
  }) {
    final normalized = text.trim();
    if (normalized.isEmpty || normalized.contains(',')) {
      return null;
    }

    final negative = normalized.startsWith('-');
    final unsigned = negative ? normalized.substring(1) : normalized;
    if (unsigned.isEmpty) {
      return null;
    }

    final parts = unsigned.split('.');
    if (parts.isEmpty || parts.length > 2) {
      return null;
    }

    final integerPart = parts.first.isEmpty ? '0' : parts.first;
    final fractionPart = parts.length == 1 ? '' : parts[1];
    if (!_isDigits(integerPart) || !_isDigits(fractionPart)) {
      return null;
    }
    if (fractionPart.length > scale) {
      return FdcDecimal.tryParseNormalized(normalized, scale: scale);
    }

    final paddedFraction = fractionPart.padRight(scale, '0');
    final digits = '$integerPart$paddedFraction';
    final scaled = BigInt.tryParse(digits.isEmpty ? '0' : digits);
    if (scaled == null) {
      return null;
    }

    return FdcDecimal.fromScaled(
      negative && scaled != BigInt.zero ? -scaled : scaled,
      scale: scale,
    );
  }

  bool _isDigits(String text) {
    for (var i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code < 48 || code > 57) {
        return false;
      }
    }
    return true;
  }

  Object? parseValue(
    FdcGridColumn<dynamic> column,
    Object? value, {
    FdcColumnIdentity? runtimeColumnId,
  }) {
    if (value == null) {
      return null;
    }

    final dataType = dataTypeOf(column);

    if (value is Iterable<Object?>) {
      return [
        for (final item in value)
          parseValue(column, item, runtimeColumnId: runtimeColumnId),
      ].where((item) => item != null).toList();
    }

    if (value is Iterable) {
      return [
        for (final item in value.cast<Object?>())
          parseValue(column, item, runtimeColumnId: runtimeColumnId),
      ].where((item) => item != null).toList();
    }

    if (dataType == FdcDataType.decimal && value is FdcDecimal) {
      return value;
    }

    if ((dataType == FdcDataType.date || dataType == FdcDataType.dateTime) &&
        value is DateTime) {
      return value;
    }

    if (dataType == FdcDataType.time && value is FdcTime) {
      return value;
    }

    if (value is num &&
        (dataType == FdcDataType.integer || dataType == FdcDataType.decimal)) {
      return value;
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    if (dataType == FdcDataType.integer || dataType == FdcDataType.decimal) {
      if (column.effectiveEditor == FdcEditorType.custom) {
        return _parseScalarTextByDataType(column, dataType, text);
      }

      final codec = FdcFieldValueCodec(
        settings: formatSettings,
        translations: translations,
      );
      return codec.parseGridText(
        column,
        text,
        runtimeColumnId: runtimeColumnId ?? runtimeColumnIdOf(column),
        decimalScale: decimalScaleOf(column),
        decimalPrecision: decimalPrecisionOf(column),
      );
    }

    if (dataType == FdcDataType.date ||
        dataType == FdcDataType.dateTime ||
        dataType == FdcDataType.time) {
      final codec = FdcFieldValueCodec(
        settings: formatSettings,
        translations: translations,
      );
      return codec.parseDateText(
        column,
        text,
        runtimeColumnId: runtimeColumnId ?? runtimeColumnIdOf(column),
      );
    }

    return value;
  }

  Object? _parseScalarTextByDataType(
    FdcGridColumn<dynamic> column,
    FdcDataType dataType,
    String text,
  ) {
    final kind = dataType == FdcDataType.decimal
        ? FdcValueCodecKind.decimal
        : FdcValueCodecKind.integer;
    return FdcValueCodecResolver.resolve<Object?>(
      FdcValueCodecConfig(
        kind: kind,
        sourceName: column.label ?? column.fieldName,
        scale: decimalScaleOf(column),
        negative: column.allowNegative,
        formatSettings: column.formatSettings ?? formatSettings,
        validationTranslations: translations.validation,
      ),
    ).parseText(text);
  }

  bool _canParseCompleteDate(String value, FdcGridColumn<dynamic> column) {
    final effectiveFormatSettings = column.formatSettings ?? formatSettings;
    final pattern = effectiveFormatSettings.dateFormat;
    final formatter = FdcDateFormat(pattern);
    return formatter.hasCompleteInput(value) &&
        formatter.parseDate(value) != null;
  }

  bool _canParseCompleteDateTime(String value, FdcGridColumn<dynamic> column) {
    final effectiveFormatSettings = column.formatSettings ?? formatSettings;
    final dateTimePattern = effectiveFormatSettings.effectiveDateTimeFormat;
    final dateTimeFormatter = FdcDateFormat(dateTimePattern);
    if (dateTimeFormatter.hasCompleteInput(value) &&
        dateTimeFormatter.parseDate(value) != null) {
      return true;
    }

    final datePattern = effectiveFormatSettings.dateFormat;
    final dateFormatter = FdcDateFormat(datePattern);
    if (!dateFormatter.hasCompleteInput(value)) {
      return false;
    }

    return dateFormatter.parseDate(value) != null;
  }

  bool _canParseCompleteTime(String value, FdcGridColumn<dynamic> column) {
    final effectiveFormatSettings = column.formatSettings ?? formatSettings;
    final pattern = effectiveFormatSettings.timeFormat;
    final formatter = FdcDateFormat(pattern);
    return formatter.hasCompleteInput(value) &&
        formatter.parseTime(value) != null;
  }
}
