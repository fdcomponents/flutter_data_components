// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../common/fdc_option.dart';
import '../../common/format/fdc_format_settings.dart';
import '../../common/theme/fdc_grid_styles.dart';
import '../../common/widgets/combo/fdc_combo_search_options.dart';
import '../../common/widgets/counter/fdc_counter_style.dart';
import 'fdc_badge_column.dart';
import 'fdc_column_base.dart';
import 'fdc_combo_column.dart';
import 'fdc_date_column.dart';
import 'fdc_datetime_column.dart';
import 'fdc_decimal_column.dart';
import 'fdc_integer_column.dart';
import 'fdc_progress_column.dart';
import 'fdc_text_column.dart';
import 'fdc_time_column.dart';

/// Adds column details convenience APIs.
extension FdcColumnDetails<T> on FdcGridColumn<T> {
  /// Whether show counter.
  bool get showCounter => switch (this) {
    final FdcTextColumn<T> column => column.showCounter,
    _ => false,
  };

  /// Returns the current counter style.
  FdcCounterStyle get counterStyle => switch (this) {
    final FdcTextColumn<T> column => column.counterStyle,
    _ => const FdcCounterStyle(),
  };

  /// Whether allow negative.
  bool get allowNegative => switch (this) {
    final FdcIntegerColumn<T> column => column.allowNegative,
    final FdcDecimalColumn<T> column => column.allowNegative,
    _ => true,
  };

  /// Returns the current format settings.
  FdcFormatSettings? get formatSettings => switch (this) {
    final FdcDecimalColumn<T> column => column.formatSettings,
    final FdcDateColumn<T> column => column.formatSettings,
    final FdcDateTimeColumn<T> column => column.formatSettings,
    final FdcTimeColumn<T> column => column.formatSettings,
    _ => null,
  };

  /// Returns the current prefix text.
  String? get prefixText => switch (this) {
    final FdcIntegerColumn<T> column => column.prefixText,
    final FdcDecimalColumn<T> column => column.prefixText,
    _ => null,
  };

  /// Returns the current suffix text.
  String? get suffixText => switch (this) {
    final FdcIntegerColumn<T> column => column.suffixText,
    final FdcDecimalColumn<T> column => column.suffixText,
    _ => null,
  };

  /// Whether show picker.
  bool get showPicker => switch (this) {
    final FdcDateColumn<T> column => column.showPicker,
    final FdcDateTimeColumn<T> column => column.showPicker,
    final FdcTimeColumn<T> column => column.showPicker,
    _ => true,
  };

  /// Returns the current options.
  List<FdcOption<T>> get options => switch (this) {
    final FdcComboColumn<T> column => column.options,
    final FdcBadgeColumn<T> column => column.options,
    _ => const [],
  };

  /// Whether show selected option checkmark.
  bool get showSelectedOptionCheckmark => switch (this) {
    final FdcComboColumn<T> column => column.showSelectedOptionCheckmark,
    _ => true,
  };

  /// Returns the current combo search.
  FdcComboSearchOptions get comboSearch => switch (this) {
    final FdcComboColumn<T> column => column.search,
    _ => const FdcComboSearchOptions(),
  };

  /// Returns the current combo search hint text.
  String? get comboSearchHintText => switch (this) {
    final FdcComboColumn<T> column => column.searchHintText,
    _ => null,
  };

  /// Returns the current combo max popup items.
  int get comboMaxPopupItems => switch (this) {
    final FdcComboColumn<T> column => column.maxPopupItems,
    _ => 8,
  };

  /// Returns the current badge text.
  String? get badgeText => switch (this) {
    final FdcBadgeColumn<T> column => column.badgeText,
    _ => null,
  };

  /// Returns the current badge color.
  Color? get badgeColor => switch (this) {
    final FdcBadgeColumn<T> column => column.badgeColor,
    _ => null,
  };

  /// Returns the current badge text builder.
  FdcBadgeTextBuilder<T>? get badgeTextBuilder => switch (this) {
    final FdcBadgeColumn<T> column => column.badgeTextBuilder,
    _ => null,
  };

  /// Returns the current badge color builder.
  FdcBadgeColorBuilder<T>? get badgeColorBuilder => switch (this) {
    final FdcBadgeColumn<T> column => column.badgeColorBuilder,
    _ => null,
  };

  /// Returns the current badge text style.
  TextStyle? get badgeTextStyle => switch (this) {
    final FdcBadgeColumn<T> column => column.badgeTextStyle,
    _ => null,
  };

  /// Returns the current progress min.
  double get progressMin => switch (this) {
    final FdcProgressColumn<T> column => column.progressMin,
    _ => 0,
  };

  /// Returns the current progress max.
  double get progressMax => switch (this) {
    final FdcProgressColumn<T> column => column.progressMax,
    _ => 100,
  };

  /// Returns the current progress text builder.
  FdcProgressTextBuilder? get progressTextBuilder => switch (this) {
    final FdcProgressColumn<T> column => column.progressTextBuilder,
    _ => null,
  };

  /// Returns the current progress style.
  FdcGridProgressStyle? get progressStyle => switch (this) {
    final FdcProgressColumn<T> column => column.progressStyle,
    _ => null,
  };
}
