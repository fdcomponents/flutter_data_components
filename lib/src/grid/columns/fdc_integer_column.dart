// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../data/bindings/fdc_bindings.dart';
import '../../data/fdc_data.dart';
import 'fdc_column_base.dart';

/// Grid column for integer fields with numeric editing and display affixes.
///
/// The column binds to an `FdcIntegerField`, uses the integer editor, and can
/// optionally reject negative input. [prefixText] and [suffixText] affect
/// display only and never participate in parsing, filtering, sorting, or
/// aggregate calculations.
class FdcIntegerColumn<T> extends FdcGridColumn<T> {
  /// Creates a [FdcIntegerColumn].
  const FdcIntegerColumn({
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
    this.allowNegative = true,
    this.prefixText,
    this.suffixText,
  });

  /// Whether the editor accepts negative values.
  final bool allowNegative;

  /// Text displayed before the formatted integer value in read-only grid cells.
  ///
  /// This is presentation-only metadata. It does not affect parsing, editing,
  /// sorting, filtering, validation, storage, or aggregate calculations.
  final String? prefixText;

  /// Text displayed after the formatted integer value in read-only grid cells.
  ///
  /// This is presentation-only metadata. It does not affect parsing, editing,
  /// sorting, filtering, validation, storage, or aggregate calculations.
  final String? suffixText;

  @override
  FdcDataType get dataType => FdcDataType.integer;

  @override
  FdcEditorType get effectiveEditor => FdcEditorType.integer;

  @override
  void validateBinding(FdcDataSet dataSet) {
    FdcFieldBindingResolver.resolve<FdcIntegerField>(
      dataSet,
      fieldName,
      ownerName: runtimeType.toString(),
    );
  }
}
