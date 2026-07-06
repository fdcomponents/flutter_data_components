// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../common/format/fdc_format_settings.dart';
import '../../data/fdc_field_def.dart';
import '../../i18n/fdc_translations.dart';
import '../columns/fdc_grid_columns.dart';
import '../models/fdc_column_identity.dart';
import 'fdc_field_value_codec.dart';

typedef FdcDecimalScaleResolver =
    int? Function(
      FdcGridColumn<dynamic> column, {
      FdcColumnIdentity? runtimeColumnId,
    });

class FdcValueFormatter {
  FdcValueFormatter({
    required this.settings,
    this.decimalScaleResolver,
    this.translations = const FdcTranslations(),
  }) : _codec = FdcFieldValueCodec(
         settings: settings,
         translations: translations,
       );

  final FdcFormatSettings settings;
  final FdcDecimalScaleResolver? decimalScaleResolver;
  final FdcTranslations translations;
  final FdcFieldValueCodec _codec;

  String format(
    FdcGridColumn<dynamic> column,
    Object? value, {
    FdcColumnIdentity? runtimeColumnId,
    bool forEditing = false,
  }) {
    return _codec.formatGridValue(
      column,
      value,
      runtimeColumnId: runtimeColumnId,
      forEditing: forEditing,
      decimalScale: decimalScaleResolver?.call(
        column,
        runtimeColumnId: runtimeColumnId,
      ),
    );
  }

  /// Formats a raw dataset field value from schema metadata.
  ///
  /// Unlike [format], this does not require a visible grid column and is
  /// therefore suitable for secondary values read by a custom cell.
  String formatField(FdcFieldDef field, Object? value) {
    return _codec.formatFieldValue(field, value);
  }
}
