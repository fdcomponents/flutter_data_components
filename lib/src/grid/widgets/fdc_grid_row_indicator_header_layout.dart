// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../core/fdc_grid_core.dart';
import 'fdc_grid_header_metrics.dart';

class FdcGridRowIndicatorHeaderLayout {
  const FdcGridRowIndicatorHeaderLayout({
    required this.selectAllLeft,
    required this.mainMenuLeft,
    required this.showSelectAllInLabelRow,
    required this.showSelectAllInFilterRow,
    required this.centerMainMenuInHeaderLabel,
    required this.centerMainMenuInRowNumberSlot,
  });

  factory FdcGridRowIndicatorHeaderLayout.resolve({
    required FdcGridRowIndicatorOptions options,
    required bool showsFilterRow,
  }) {
    final selectAllLeft = FdcGridHeaderMetrics.rowIndicatorSelectLeadingWidth(
      showRecordStatus: options.showRecordStatus,
      showRowSelect: options.showRowSelect,
      showRowNumbers: options.showRowNumbers,
    );
    final mainMenuLeft = FdcGridHeaderMetrics.rowIndicatorNumberLeadingWidth(
      showRecordStatus: options.showRecordStatus,
      showRowSelect: options.showRowSelect,
      showRowNumbers: options.showRowNumbers,
    );

    return FdcGridRowIndicatorHeaderLayout(
      selectAllLeft: selectAllLeft,
      mainMenuLeft: mainMenuLeft,
      showSelectAllInLabelRow: options.showRowSelect && !showsFilterRow,
      showSelectAllInFilterRow: options.showRowSelect && showsFilterRow,
      centerMainMenuInHeaderLabel: showsFilterRow,
      centerMainMenuInRowNumberSlot: options.showRowNumbers && !showsFilterRow,
    );
  }

  final double selectAllLeft;
  final double mainMenuLeft;
  final bool showSelectAllInLabelRow;
  final bool showSelectAllInFilterRow;
  final bool centerMainMenuInHeaderLabel;
  final bool centerMainMenuInRowNumberSlot;
}
