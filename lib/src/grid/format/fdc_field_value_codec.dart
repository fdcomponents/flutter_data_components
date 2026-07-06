// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:collection';

import 'package:flutter/services.dart';

import '../../common/codecs/fdc_value_codec.dart';
import '../../common/format/fdc_format_settings.dart';
import '../../data/fdc_data_type.dart';
import '../../data/fdc_field_def.dart';
import '../../data/fields/fdc_decimal_field.dart';
import '../../data/fields/fdc_integer_field.dart';
import '../../data/fields/fdc_string_field.dart';
import '../../data/types/fdc_decimal.dart';
import '../../i18n/fdc_translations.dart';
import '../columns/fdc_grid_columns.dart';
import '../models/fdc_column_identity.dart';

const int _maxCachedCodecs = 256;
final LinkedHashMap<_FdcFieldValueCodecCacheKey, FdcValueCodec<Object?>>
_codecCache =
    LinkedHashMap<_FdcFieldValueCodecCacheKey, FdcValueCodec<Object?>>();

class _FdcFieldValueCodecCacheKey {
  const _FdcFieldValueCodecCacheKey({
    required this.kind,
    required this.sourceName,
    required this.label,
    required this.required,
    required this.maxLength,
    required this.precision,
    required this.scale,
    required this.negative,
    required this.formatSettings,
    required this.validationTranslations,
  });

  factory _FdcFieldValueCodecCacheKey.fromConfig(FdcValueCodecConfig config) {
    return _FdcFieldValueCodecCacheKey(
      kind: config.kind,
      sourceName: config.sourceName,
      label: config.label,
      required: config.required,
      maxLength: config.maxLength,
      precision: config.precision,
      scale: config.scale,
      negative: config.negative,
      formatSettings: config.formatSettings,
      validationTranslations: config.validationTranslations,
    );
  }

  final FdcValueCodecKind kind;
  final String sourceName;
  final String? label;
  final bool required;
  final int? maxLength;
  final int? precision;
  final int? scale;
  final bool negative;
  final FdcFormatSettings formatSettings;
  final FdcValidationTranslations validationTranslations;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _FdcFieldValueCodecCacheKey &&
            kind == other.kind &&
            sourceName == other.sourceName &&
            label == other.label &&
            required == other.required &&
            maxLength == other.maxLength &&
            precision == other.precision &&
            scale == other.scale &&
            negative == other.negative &&
            formatSettings == other.formatSettings &&
            validationTranslations == other.validationTranslations;
  }

  @override
  int get hashCode => Object.hash(
    kind,
    sourceName,
    label,
    required,
    maxLength,
    precision,
    scale,
    negative,
    formatSettings,
    validationTranslations,
  );
}

/// Grid-facing value parser/formatter.
///
/// Scalar parse/format/input behavior is delegated to the shared common codec
/// layer so grid cells and standalone editors use the same rules. Grid-specific
/// presentation values, such as badge/progress/combo labels, remain here.
class FdcFieldValueCodec {
  const FdcFieldValueCodec({
    required this.settings,
    this.translations = const FdcTranslations(),
  });

  final FdcFormatSettings settings;
  final FdcTranslations translations;

  Object? parseGridText(
    FdcGridColumn<dynamic> column,
    String text, {
    FdcColumnIdentity? runtimeColumnId,
    bool requireCompleteDateInput = true,
    int? decimalScale,
    int? decimalPrecision,
  }) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return null;
    }

    if (_isScalarGridColumn(column)) {
      if (requireCompleteDateInput && isDateLikeGridColumn(column)) {
        final codec = _scalarCodec(
          column,
          runtimeColumnId: runtimeColumnId,
          decimalScale: decimalScale,
          decimalPrecision: decimalPrecision,
        );
        if (!codec.hasCompleteDateInput(normalizedText)) {
          return null;
        }
      }

      return _scalarCodec(
        column,
        runtimeColumnId: runtimeColumnId,
        decimalScale: decimalScale,
        decimalPrecision: decimalPrecision,
      ).parseText(_isTextLikeGridColumn(column) ? text : normalizedText);
    }

    return text;
  }

  FdcValueParseResult<Object?> parseGridTextForCommit(
    FdcGridColumn<dynamic> column,
    String text, {
    FdcColumnIdentity? runtimeColumnId,
    int? decimalScale,
    int? decimalPrecision,
  }) {
    final normalizedText = _removeDisplayTextAffixes(column, text.trim());
    if (normalizedText.isEmpty) {
      return const FdcValueParseResult<Object?>.success(
        null,
        normalizedText: '',
      );
    }

    if (!_isScalarGridColumn(column)) {
      return FdcValueParseResult<Object?>.success(text);
    }

    final codec = _scalarCodec(
      column,
      runtimeColumnId: runtimeColumnId,
      decimalScale: decimalScale,
      decimalPrecision: decimalPrecision,
    );

    return codec.parseForCommit(
      _isTextLikeGridColumn(column) ? text : normalizedText,
    );
  }

  String _removeDisplayTextAffixes(FdcGridColumn<dynamic> column, String text) {
    var result = text;
    final prefix = column.prefixText;
    final suffix = column.suffixText;

    if (prefix != null && prefix.isNotEmpty && result.startsWith(prefix)) {
      result = result.substring(prefix.length).trimLeft();
    }
    if (suffix != null && suffix.isNotEmpty && result.endsWith(suffix)) {
      result = result.substring(0, result.length - suffix.length).trimRight();
    }
    return result;
  }

  Object? parseDateText(
    FdcGridColumn<dynamic> column,
    String text, {
    FdcColumnIdentity? runtimeColumnId,
    bool requireCompleteInput = true,
  }) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty || !isDateLikeGridColumn(column)) {
      return null;
    }

    final codec = _scalarCodec(column, runtimeColumnId: runtimeColumnId);
    if (requireCompleteInput && !codec.hasCompleteDateInput(normalizedText)) {
      return null;
    }
    return codec.parseDateText(normalizedText);
  }

  FdcDecimal? parseDecimalText(
    String text, {
    int? scale,
    FdcFormatSettings? formatSettings,
  }) {
    return _codecForConfig(
          FdcValueCodecConfig(
            kind: FdcValueCodecKind.decimal,
            sourceName: '',
            scale: scale,
            formatSettings: formatSettings ?? settings,
            validationTranslations: translations.validation,
          ),
        ).parseText(text)
        as FdcDecimal?;
  }

  String formatGridValue(
    FdcGridColumn<dynamic> column,
    Object? value, {
    FdcColumnIdentity? runtimeColumnId,
    bool forEditing = false,
    int? decimalScale,
  }) {
    if (value == null) {
      return '';
    }

    if (value is FdcBadgeValue) {
      return value.text;
    }

    if (value is FdcProgressValue) {
      return value.text ?? _formatProgress(column, value.value);
    }

    if (column.effectiveEditor == FdcEditorType.progress) {
      if (value is FdcDecimal) {
        return _formatProgress(column, value.toNum());
      }
      if (value is num) {
        return _formatProgress(column, value);
      }
    }

    if (_isScalarGridColumn(column)) {
      final formatted = _scalarCodec(
        column,
        runtimeColumnId: runtimeColumnId,
        decimalScale: decimalScale,
      ).formatValue(value, forEditing: forEditing);
      return applyDisplayTextAffixes(column, formatted, forEditing: forEditing);
    }

    if (value is bool) {
      return value ? translations.common.yes : translations.common.no;
    }

    final option = column.options.where((option) => option.value == value);
    if (option.isNotEmpty) {
      return option.first.label;
    }

    return value.toString();
  }

  /// Formats a raw dataset field value using field schema metadata and the
  /// active grid format settings.
  ///
  /// This is intended for custom cells that read secondary fields which do
  /// not necessarily have their own visible grid column.
  String formatFieldValue(FdcFieldDef field, Object? value) {
    if (value == null) {
      return '';
    }
    final kind = switch (field.dataType) {
      FdcDataType.string => FdcValueCodecKind.text,
      FdcDataType.integer => FdcValueCodecKind.integer,
      FdcDataType.decimal => FdcValueCodecKind.decimal,
      FdcDataType.date => FdcValueCodecKind.date,
      FdcDataType.dateTime => FdcValueCodecKind.dateTime,
      FdcDataType.time => FdcValueCodecKind.time,
      FdcDataType.boolean || FdcDataType.guid || FdcDataType.object => null,
    };
    if (kind == null) {
      if (value is bool) {
        return value ? translations.common.yes : translations.common.no;
      }
      return value.toString();
    }
    final decimalField = field is FdcDecimalField ? field : null;
    final stringField = field is FdcStringField ? field : null;
    return _codecForConfig(
      FdcValueCodecConfig(
        kind: kind,
        sourceName: field.name,
        label: field.label,
        required: field.required,
        maxLength: stringField?.size,
        precision: decimalField?.precision,
        scale: decimalField?.scale,
        negative: switch (field) {
          FdcDecimalField(:final minValue) => minValue == null || minValue < 0,
          FdcIntegerField(:final minValue) => minValue == null || minValue < 0,
          _ => false,
        },
        formatSettings: settings,
        validationTranslations: translations.validation,
      ),
    ).formatValue(value);
  }

  String formatDecimal(
    Object value, {
    required bool forEditing,
    int? scale,
    FdcFormatSettings? formatSettings,
  }) {
    return _codecForConfig(
      FdcValueCodecConfig(
        kind: FdcValueCodecKind.decimal,
        sourceName: '',
        scale: scale,
        formatSettings: formatSettings ?? settings,
        validationTranslations: translations.validation,
      ),
    ).formatValue(value, forEditing: forEditing);
  }

  String applyDisplayTextAffixes(
    FdcGridColumn<dynamic> column,
    String text, {
    bool forEditing = false,
  }) {
    if (forEditing || text.isEmpty) {
      return text;
    }

    final prefix = column.prefixText;
    final suffix = column.suffixText;
    if ((prefix == null || prefix.isEmpty) &&
        (suffix == null || suffix.isEmpty)) {
      return text;
    }

    return '${prefix ?? ''}$text${suffix ?? ''}';
  }

  bool isDateLikeGridColumn(FdcGridColumn<dynamic> column) {
    return column.effectiveEditor == FdcEditorType.date ||
        column.effectiveEditor == FdcEditorType.dateTime ||
        column.effectiveEditor == FdcEditorType.time;
  }

  TextInputType? keyboardTypeForGridColumn(
    FdcGridColumn<dynamic> column, {
    FdcColumnIdentity? runtimeColumnId,
  }) {
    if (!_isScalarGridColumn(column)) {
      return null;
    }
    return _scalarCodec(
      column,
      runtimeColumnId: runtimeColumnId,
    ).keyboardType();
  }

  List<TextInputFormatter>? inputFormattersForGridColumn(
    FdcGridColumn<dynamic> column, {
    FdcColumnIdentity? runtimeColumnId,
    int? decimalScale,
    int? decimalPrecision,
  }) {
    if (!_isScalarGridColumn(column)) {
      return null;
    }
    return _scalarCodec(
      column,
      runtimeColumnId: runtimeColumnId,
      decimalScale: decimalScale,
      decimalPrecision: decimalPrecision,
    ).inputFormatters();
  }

  TextInputFormatter? typedTextFormatterForGridColumn(
    FdcGridColumn<dynamic> column, {
    FdcColumnIdentity? runtimeColumnId,
    int? decimalScale,
    int? decimalPrecision,
  }) {
    final formatters = inputFormattersForGridColumn(
      column,
      runtimeColumnId: runtimeColumnId,
      decimalScale: decimalScale,
      decimalPrecision: decimalPrecision,
    );
    return formatters == null || formatters.isEmpty ? null : formatters.first;
  }

  String dateFormatPattern(
    FdcGridColumn<dynamic> column, {
    FdcColumnIdentity? runtimeColumnId,
  }) {
    return _scalarCodec(
      column,
      runtimeColumnId: runtimeColumnId,
    ).dateFormatPattern();
  }

  FdcValueCodec<Object?> _scalarCodec(
    FdcGridColumn<dynamic> column, {
    FdcColumnIdentity? runtimeColumnId,
    int? decimalScale,
    int? decimalPrecision,
  }) {
    return _codecForConfig(
      _configForGridColumn(
        column,
        runtimeColumnId: runtimeColumnId,
        decimalScale: decimalScale,
        decimalPrecision: decimalPrecision,
      ),
    );
  }

  FdcValueCodec<Object?> _codecForConfig(FdcValueCodecConfig config) {
    final key = _FdcFieldValueCodecCacheKey.fromConfig(config);
    final cached = _codecCache.remove(key);
    if (cached != null) {
      _codecCache[key] = cached;
      return cached;
    }

    final codec = FdcValueCodecResolver.resolve<Object?>(config);
    if (_codecCache.length >= _maxCachedCodecs) {
      _codecCache.remove(_codecCache.keys.first);
    }
    _codecCache[key] = codec;
    return codec;
  }

  FdcValueCodecConfig _configForGridColumn(
    FdcGridColumn<dynamic> column, {
    FdcColumnIdentity? runtimeColumnId,
    int? decimalScale,
    int? decimalPrecision,
  }) {
    return FdcValueCodecConfig(
      kind: _kindForGridColumn(column),
      sourceName: _sourceNameForGridColumn(column, runtimeColumnId),
      label: column.label,
      precision: decimalPrecision,
      scale: decimalScale,
      negative: column.allowNegative,
      formatSettings: column.formatSettings ?? settings,
      validationTranslations: translations.validation,
    );
  }

  String _sourceNameForGridColumn(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity? runtimeColumnId,
  ) {
    if (runtimeColumnId != null) {
      return 'gridRuntimeColumn:$runtimeColumnId';
    }
    return column.label ?? column.runtimeType.toString();
  }

  FdcValueCodecKind _kindForGridColumn(FdcGridColumn<dynamic> column) {
    return switch (column.effectiveEditor) {
      FdcEditorType.memo => FdcValueCodecKind.memo,
      FdcEditorType.integer => FdcValueCodecKind.integer,
      FdcEditorType.decimal => FdcValueCodecKind.decimal,
      FdcEditorType.date => FdcValueCodecKind.date,
      FdcEditorType.dateTime => FdcValueCodecKind.dateTime,
      FdcEditorType.time => FdcValueCodecKind.time,
      _ => FdcValueCodecKind.text,
    };
  }

  bool _isTextLikeGridColumn(FdcGridColumn<dynamic> column) {
    return column.effectiveEditor == FdcEditorType.text ||
        column.effectiveEditor == FdcEditorType.memo;
  }

  bool _isScalarGridColumn(FdcGridColumn<dynamic> column) {
    return switch (column.effectiveEditor) {
      FdcEditorType.text ||
      FdcEditorType.memo ||
      FdcEditorType.integer ||
      FdcEditorType.decimal ||
      FdcEditorType.date ||
      FdcEditorType.dateTime ||
      FdcEditorType.time => true,
      _ => false,
    };
  }

  String _formatProgress(FdcGridColumn<dynamic> column, num value) {
    final range = column.progressMax - column.progressMin;
    final normalized = range == 0
        ? 0.0
        : ((value.toDouble() - column.progressMin) / range).clamp(0.0, 1.0);
    return column.progressTextBuilder?.call(value) ??
        '${(normalized * 100).round()}%';
  }
}
