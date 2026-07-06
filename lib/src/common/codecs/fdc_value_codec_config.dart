// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../i18n/fdc_translations.dart';
import '../format/fdc_format_settings.dart';
import 'fdc_value_codec_kind.dart';

class FdcValueCodecConfig {
  const FdcValueCodecConfig({
    required this.kind,
    required this.sourceName,
    this.label,
    this.required = false,
    this.maxLength,
    this.precision,
    this.scale,
    this.negative = false,
    required this.formatSettings,
    this.validationTranslations = const FdcValidationTranslations(),
  });

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
}
