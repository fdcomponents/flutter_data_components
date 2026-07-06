// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/input/fdc_boolean_control.dart';
import '../../data/bindings/fdc_bindings.dart';
import '../../data/fdc_data.dart';
import 'fdc_column_base.dart';

/// Grid column for boolean fields with checkbox or switch-style interaction.
class FdcBooleanColumn<T> extends FdcGridColumn<T> {
  /// Creates a [FdcBooleanColumn].
  const FdcBooleanColumn({
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
    this.control = FdcBooleanControl.checkbox,
  });

  /// Whether the Control modifier is required.
  final FdcBooleanControl control;

  @override
  FdcDataType get dataType => FdcDataType.boolean;

  @override
  FdcEditorType get effectiveEditor {
    return control == FdcBooleanControl.switchControl
        ? FdcEditorType.switcher
        : FdcEditorType.checkbox;
  }

  @override
  void validateBinding(FdcDataSet dataSet) {
    FdcFieldBindingResolver.resolve<FdcBooleanField>(
      dataSet,
      fieldName,
      ownerName: runtimeType.toString(),
    );
  }
}
