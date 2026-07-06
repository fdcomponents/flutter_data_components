// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/format/fdc_format_settings.dart';
import '../../data/bindings/fdc_bindings.dart';
import '../../data/fdc_data.dart';
import 'fdc_column_base.dart';

/// Grid column specialized for date-only dataset fields.
///
/// It provides date-aware display formatting, editing, sorting, and filtering.
class FdcDateColumn<T> extends FdcGridColumn<T> {
  /// Creates a [FdcDateColumn].
  const FdcDateColumn({
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
    this.formatSettings,
    this.showPicker = true,
  });

  /// Format settings applied to FDC controls.
  final FdcFormatSettings? formatSettings;

  /// Shows the built-in date picker affordance in the editor.
  final bool showPicker;

  @override
  FdcDataType get dataType => FdcDataType.date;

  @override
  FdcEditorType get effectiveEditor => FdcEditorType.date;

  @override
  void validateBinding(FdcDataSet dataSet) {
    FdcFieldBindingResolver.resolve<FdcDateField>(
      dataSet,
      fieldName,
      ownerName: runtimeType.toString(),
    );
  }
}
