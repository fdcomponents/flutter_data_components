// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/widgets/counter/fdc_counter_style.dart';
import '../../data/bindings/fdc_bindings.dart';
import '../../data/fdc_data.dart';
import 'fdc_column_base.dart';

/// Grid column for text dataset fields.
///
/// It provides text display, editing, sorting, filtering, and column-level
/// formatting behavior.
class FdcTextColumn<T> extends FdcGridColumn<T> {
  /// Creates a [FdcTextColumn].
  const FdcTextColumn({
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
    super.onLookup,
    super.lookupIcon,
    super.lookupShortcut,
    super.onValueChanged,
    super.cellStyle,
    super.pin,
    super.summary,
    super.menuBuilder,
    this.showCounter = false,
    this.counterStyle = const FdcCounterStyle(),
  });

  /// Shows a character counter in the text editor.
  final bool showCounter;

  /// Optional text style used by the character counter.
  final FdcCounterStyle counterStyle;

  @override
  FdcDataType get dataType => FdcDataType.string;

  @override
  FdcEditorType get effectiveEditor => FdcEditorType.text;

  @override
  void validateBinding(FdcDataSet dataSet) {
    FdcFieldBindingResolver.resolveAnyOf(
      dataSet,
      fieldName,
      allowedFieldTypes: const [FdcStringField, FdcGuidField],
      ownerName: runtimeType.toString(),
    );
  }
}
