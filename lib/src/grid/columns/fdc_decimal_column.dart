// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/format/fdc_format_settings.dart';
import '../../data/bindings/fdc_bindings.dart';
import '../../data/fdc_data.dart';
import 'fdc_column_base.dart';

/// Grid column for fixed-precision decimal fields with numeric formatting and editing.
class FdcDecimalColumn<T> extends FdcGridColumn<T> {
  /// Creates a [FdcDecimalColumn].
  const FdcDecimalColumn({
    required super.fieldName,
    super.id,
    super.groupId,
    super.label,
    super.hint,
    super.visible,
    super.exportable,
    super.enabled,
    super.readOnly,
    super.focusOrder,
    super.tabStop,
    super.width,
    super.minWidth,
    super.maxWidth,
    super.autoSizeMode,
    super.allowSort,
    super.filterConfig,
    super.allowResize,
    super.horizontalAlignment,
    super.showIndicator,
    super.onValueChanging,
    super.onValueChanged,
    super.cellStyle,
    super.pin,
    super.summary,
    super.menuBuilder,
    this.allowNegative = true,
    this.formatSettings,
    this.prefixText,
    this.suffixText,
  });

  /// Whether the editor accepts negative values.
  final bool allowNegative;

  /// Format settings applied to FDC controls.
  final FdcFormatSettings? formatSettings;

  /// Text displayed before the formatted decimal value in read-only grid cells.
  ///
  /// This is presentation-only metadata. It does not affect parsing, editing,
  /// sorting, filtering, validation, storage, or aggregate calculations.
  final String? prefixText;

  /// Text displayed after the formatted decimal value in read-only grid cells.
  ///
  /// This is presentation-only metadata. It does not affect parsing, editing,
  /// sorting, filtering, validation, storage, or aggregate calculations.
  final String? suffixText;

  @override
  FdcDataType get dataType => FdcDataType.decimal;

  @override
  FdcEditorType get effectiveEditor => FdcEditorType.decimal;

  @override
  void validateBinding(FdcDataSet dataSet) {
    FdcFieldBindingResolver.resolve<FdcDecimalField>(
      dataSet,
      fieldName,
      ownerName: runtimeType.toString(),
    );
  }
}
