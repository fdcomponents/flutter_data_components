// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/theme/fdc_grid_styles.dart';
import '../../data/bindings/fdc_bindings.dart';
import '../../data/fdc_data.dart';
import 'fdc_column_base.dart';

/// Grid column that renders numeric values as compact progress indicators.
class FdcProgressColumn<T> extends FdcGridColumn<T> {
  /// Creates a [FdcProgressColumn].
  const FdcProgressColumn({
    required super.fieldName,
    super.id,
    super.groupId,
    super.label,
    super.hint,
    super.visible,
    super.exportable,
    super.enabled,
    super.readOnly = true,
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
    this.progressMin = 0,
    this.progressMax = 100,
    this.progressTextBuilder,
    this.progressStyle,
  });

  /// Lower bound used to normalize progress values.
  final double progressMin;

  /// Upper bound used to normalize progress values.
  final double progressMax;

  /// Optional callback that derives display text from the progress value.
  final FdcProgressTextBuilder? progressTextBuilder;

  /// Visual style applied to progress indicators in this column.
  final FdcGridProgressStyle? progressStyle;

  @override
  Object? get progressTextBuilderSignatureToken => progressTextBuilder;

  @override
  FdcDataType get dataType => FdcDataType.decimal;

  @override
  FdcEditorType get effectiveEditor => FdcEditorType.progress;

  @override
  bool get isInherentlyReadOnly => true;

  @override
  void validateBinding(FdcDataSet dataSet) {
    FdcFieldBindingResolver.resolveAnyOf(
      dataSet,
      fieldName,
      allowedFieldTypes: const <Type>[FdcIntegerField, FdcDecimalField],
      ownerName: runtimeType.toString(),
    );
  }
}
