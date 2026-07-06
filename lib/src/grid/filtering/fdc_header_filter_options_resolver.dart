// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../common/format/fdc_format_settings.dart';
import '../../data/fdc_data.dart';
import '../../data/fdc_dataset.dart' show FdcDataSetInternal;
import '../../i18n/fdc_translations.dart';
import '../columns/fdc_grid_columns.dart';
import '../models/fdc_column_identity.dart';
import 'fdc_header_filter_value_codec.dart';

class FdcHeaderFilterOptionsResolver {
  const FdcHeaderFilterOptionsResolver({
    required this.dataSet,
    required this.formatSettings,
    required this.runtimeColumnIdOf,
    required this.decimalScaleOf,
    required this.decimalPrecisionOf,
    this.translations = const FdcTranslations(),
  });

  final FdcDataSet dataSet;
  final FdcFormatSettings formatSettings;
  final FdcColumnIdentity? Function(FdcGridColumn<dynamic> column)
  runtimeColumnIdOf;
  final int? Function(FdcGridColumn<dynamic> column) decimalScaleOf;
  final int? Function(FdcGridColumn<dynamic> column) decimalPrecisionOf;
  final FdcTranslations translations;

  List<FdcOption<Object?>> resolve(FdcGridColumn<dynamic> column) {
    final configured = column.filterConfig?.values;
    if (configured != null) {
      return _copyOptions(configured);
    }

    if (column.effectiveEditor == FdcEditorType.combo) {
      return _copyOptions(column.options);
    }

    return _distinctDataSetOptions(column);
  }

  List<FdcOption<Object?>> _copyOptions(List<FdcOption<Object?>> options) {
    if (options.isEmpty) {
      return const <FdcOption<Object?>>[];
    }

    return [
      for (final option in options)
        FdcOption<Object?>(value: option.value, label: option.label),
    ];
  }

  List<FdcOption<Object?>> _distinctDataSetOptions(
    FdcGridColumn<dynamic> column,
  ) {
    final formatter = FdcHeaderFilterValueCodec(
      formatSettings: formatSettings,
      dataTypeOf: (column) => column.dataType,
      decimalScaleOf: decimalScaleOf,
      decimalPrecisionOf: decimalPrecisionOf,
      runtimeColumnIdOf: runtimeColumnIdOf,
      translations: translations,
    );
    final runtimeColumnId = runtimeColumnIdOf(column);
    final values = <Object?>[];
    for (var rowIndex = 0; rowIndex < dataSet.recordCount; rowIndex++) {
      final Object? value;
      try {
        value = FdcDataSetInternal.fieldValueAt(
          dataSet,
          rowIndex,
          column.fieldName,
        );
        // ignore: avoid_catching_errors
      } on ArgumentError {
        // The grid can contain UX-only columns or columns prepared before the
        // dataset schema is extended. Such columns have no dataset-backed
        // values, so they simply have no distinct filter values.
        continue;
      }
      if (value == null || values.any((item) => item == value)) {
        continue;
      }
      values.add(value);
    }
    String labelOf(Object? value) {
      return formatter.formatDisplayValue(
        column,
        value,
        runtimeColumnId: runtimeColumnId,
      );
    }

    values.sort((left, right) => labelOf(left).compareTo(labelOf(right)));
    return [
      for (final value in values)
        FdcOption<Object?>(value: value, label: labelOf(value)),
    ];
  }
}
