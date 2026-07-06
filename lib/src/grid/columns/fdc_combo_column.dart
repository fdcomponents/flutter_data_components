// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/fdc_option.dart';
import '../../common/widgets/combo/fdc_combo_search_options.dart';
import '../../data/bindings/fdc_bindings.dart';
import '../../data/fdc_data.dart';
import 'fdc_column_base.dart';
import 'fdc_text_column.dart';

/// Grid column for fields whose values come from a predefined option set.
///
/// The column maps stored values to display labels and uses combo-style editing
/// for writable cells.
class FdcComboColumn<T> extends FdcTextColumn<T> {
  /// Creates a [FdcComboColumn].
  const FdcComboColumn({
    required super.fieldName,
    super.id,
    super.groupId,
    required this.options,
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
    this.showSelectedOptionCheckmark = true,
    this.search = const FdcComboSearchOptions(),
    this.searchHintText,
    this.maxPopupItems = 8,
  });

  /// Options used by this configuration.
  final List<FdcOption<T>> options;

  /// Shows a check mark beside the currently selected combo option.
  final bool showSelectedOptionCheckmark;

  /// Configures optional search inside the combo popup.
  final FdcComboSearchOptions search;

  /// Optional hint shown in the combo popup search field.
  final String? searchHintText;

  /// Maximum number of options shown before the combo popup scrolls.
  final int maxPopupItems;

  @override
  FdcEditorType get effectiveEditor => FdcEditorType.combo;

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
