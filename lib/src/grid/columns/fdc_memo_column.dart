// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_column_base.dart';
import 'fdc_text_column.dart';

/// Grid column specialized for long or multiline text fields.
///
/// It keeps normal dataset binding while providing memo-oriented cell editing
/// and display behavior.
class FdcMemoColumn<T> extends FdcTextColumn<T> {
  /// Creates a [FdcMemoColumn].
  const FdcMemoColumn({
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
    super.showCounter,
    super.counterStyle,
  });

  @override
  FdcEditorType get effectiveEditor => FdcEditorType.memo;
}
