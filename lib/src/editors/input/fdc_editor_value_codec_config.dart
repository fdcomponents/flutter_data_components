// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/codecs/fdc_value_codec.dart';
import '../../common/format/fdc_format_settings.dart';
import '../../i18n/fdc_translations.dart';
import '../core/fdc_editor_descriptor.dart';

/// Creates value codec configuration from an editor descriptor.
FdcValueCodecConfig fdcValueCodecConfigFromEditorDescriptor<T>(
  FdcEditorDescriptor<T> descriptor, {
  required FdcFormatSettings formatSettings,
  FdcValidationTranslations validationTranslations =
      const FdcValidationTranslations(),
}) {
  return FdcValueCodecConfig(
    kind: _kindFromEditorKind(descriptor.editType),
    sourceName: descriptor.fieldName,
    label: descriptor.label,
    required: descriptor.required,
    maxLength: descriptor.maxLength,
    precision: descriptor.precision,
    scale: descriptor.scale,
    negative: descriptor.allowNegative,
    formatSettings: formatSettings,
    validationTranslations: validationTranslations,
  );
}

FdcValueCodecKind _kindFromEditorKind(FdcEditorKind kind) {
  return switch (kind) {
    FdcEditorKind.text => FdcValueCodecKind.text,
    FdcEditorKind.memo => FdcValueCodecKind.memo,
    FdcEditorKind.integer => FdcValueCodecKind.integer,
    FdcEditorKind.decimal => FdcValueCodecKind.decimal,
    FdcEditorKind.date => FdcValueCodecKind.date,
    FdcEditorKind.dateTime => FdcValueCodecKind.dateTime,
    FdcEditorKind.time => FdcValueCodecKind.time,
  };
}
