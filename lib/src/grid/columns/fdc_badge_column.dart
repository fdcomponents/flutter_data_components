// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../common/fdc_option.dart';
import '../../data/bindings/fdc_bindings.dart';
import '../../data/fdc_data.dart';
import 'fdc_column_base.dart';

/// Grid column that renders field values as compact badge labels.
///
/// Badge appearance can be derived from the cell value while the column keeps
/// normal field binding, sorting, and filtering behavior.
class FdcBadgeColumn<T> extends FdcGridColumn<T> {
  /// Creates a [FdcBadgeColumn].
  const FdcBadgeColumn({
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
    this.options = const [],
    this.badgeText,
    this.badgeColor,
    this.badgeTextBuilder,
    this.badgeColorBuilder,
    this.badgeTextStyle,
  });

  /// Options used by this configuration.
  final List<FdcOption<T>> options;

  /// Static badge text used when [badgeTextBuilder] is not provided.
  final String? badgeText;

  /// Static badge color used when [badgeColorBuilder] is not provided.
  final Color? badgeColor;

  /// Optional callback that derives badge text from the cell value.
  final FdcBadgeTextBuilder<T>? badgeTextBuilder;

  /// Optional callback that derives badge color from the cell value.
  final FdcBadgeColorBuilder<T>? badgeColorBuilder;

  /// Optional text style applied to badge labels.
  final TextStyle? badgeTextStyle;

  @override
  Object? get badgeTextBuilderSignatureToken => badgeTextBuilder;

  @override
  Object? get badgeColorBuilderSignatureToken => badgeColorBuilder;

  @override
  FdcDataType get dataType => FdcDataType.object;

  @override
  FdcEditorType get effectiveEditor => FdcEditorType.badge;

  @override
  bool get isInherentlyReadOnly => true;

  @override
  void validateBinding(FdcDataSet dataSet) {
    FdcFieldBindingResolver.resolveAnyOf(
      dataSet,
      fieldName,
      allowedFieldTypes: const <Type>[
        FdcStringField,
        FdcIntegerField,
        FdcDecimalField,
        FdcBooleanField,
        FdcObjectField,
      ],
      ownerName: runtimeType.toString(),
    );
  }
}
