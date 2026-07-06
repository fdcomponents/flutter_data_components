// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../common/theme/fdc_grid_styles.dart';
import '../../common/theme/fdc_grid_theme_data.dart';
import '../../common/widgets/counter/fdc_counter_style.dart';
import '../../common/widgets/progress/fdc_progress_bar_style.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';
import '../../grid/widgets/fdc_grid_header_metrics.dart';

/// High-contrast dark preset with near-black surfaces.
const FdcGridThemeData fdcGridBlackTheme = FdcGridThemeData(
  grid: FdcGridStyle(
    backgroundColor: Color(0xFF000000),
    borderColor: Color(0xFF2A2A2A),
    selectedRowColor: Color(0xFF111111),
    cellTextStyle: TextStyle(color: Color(0xFFE5E7EB)),
    selectedCellBackgroundColor: Color(0x00000000),
    disabledCellBackgroundColor: Color(0x00000000),
    gridLines: FdcGridLines.both,
    gridLineColor: Color(0xFF2A2A2A),
    verticalGridLines: FdcGridVerticalLines.rowsOnly,
  ),
  header: FdcGridHeaderStyle(
    backgroundColor: Color(0xFF0A0A0A),
    textStyle: TextStyle(color: Color(0xFFEDEDED), fontWeight: FontWeight.w600),
    groupBackgroundColor: Color(0xFF0A0A0A),
    groupHeight: 30,
    groupAlignment: Alignment.center,
    groupPadding: EdgeInsets.symmetric(horizontal: 8),
    verticalSeparatorInset: FdcGridHeaderMetrics.verticalSeparatorInset,
  ),
  headerFilters: FdcGridHeaderFilterStyle(
    backgroundColor: Color(0xFF000000),
    focusedBorderColor: Color(0xFF38BDF8),
    unfocusedBorderColor: Color(0xFF333333),
    focusedBorderWidth: 2,
    unfocusedBorderWidth: 1,
    focusedLabelColor: Color(0xFF7DD3FC),
    unfocusedLabelColor: Color(0xFFE5E7EB),
    filterIconColor: Color(0xFFE5E7EB),
    activeFilterIconColor: Color(0xFF38BDF8),
    clearIconColor: Color(0xFFE5E7EB),
  ),
  toolbar: FdcGridToolbarStyle(
    backgroundColor: Color(0xFF0A0A0A),
    textStyle: TextStyle(color: Color(0xFFEDEDED), fontWeight: FontWeight.w600),
    itemTextColor: Color(0xFFEDEDED),
    itemIconColor: Color(0xFFEDEDED),
    disabledItemTextColor: Color(0xFFA3A3A3),
    disabledItemIconColor: Color(0xFFA3A3A3),
    height: FdcGridToolbarStyle.defaultHeight,
    padding: EdgeInsets.symmetric(horizontal: 8),
    searchExpandedWidth: FdcGridToolbarStyle.defaultSearchExpandedWidth,
    searchFieldHeight: FdcGridToolbarStyle.defaultSearchFieldHeight,
    searchFieldBorderRadius: FdcGridToolbarStyle.defaultSearchFieldBorderRadius,
    searchIconColor: Color(0xFFE5E7EB),
    searchClearIconColor: Color(0xFFE5E7EB),
    searchFieldFillColor: Color(0xFF000000),
    searchFieldBorderColor: Color(0xFF333333),
    searchFieldFocusedBorderColor: Color(0xFF38BDF8),
    searchFieldBorderWidth: FdcGridToolbarStyle.defaultSearchFieldBorderWidth,
    searchFieldFocusedBorderWidth:
        FdcGridToolbarStyle.defaultSearchFieldFocusedBorderWidth,
  ),
  controls: FdcGridControlsStyle(
    iconColor: Color(0xFFE5E7EB),
    disabledIconColor: Color(0xFF6B7280),
    activeIconColor: Color(0xFF38BDF8),
    checkboxFillColor: Color(0xFF38BDF8),
    checkboxCheckColor: Color(0xFF000000),
    checkboxBorderColor: Color(0xFFE5E7EB),
    checkboxDisabledFillColor: Color(0xFF262626),
    checkboxDisabledCheckColor: Color(0xFF737373),
    checkboxDisabledBorderColor: Color(0xFF525252),
    switchThumbColor: Color(0xFF38BDF8),
    switchTrackColor: Color(0x6638BDF8),
    switchDisabledThumbColor: Color(0xFF737373),
    switchDisabledTrackColor: Color(0xFF262626),
  ),
  summary: FdcGridSummaryStyle(
    backgroundColor: Color(0xFF000000),
    textStyle: TextStyle(color: Color(0xFFEDEDED), fontWeight: FontWeight.w600),
    padding: EdgeInsets.symmetric(horizontal: 10),
    showTopSeparator: true,
    showVerticalSeparators: true,
    verticalSeparatorInset: FdcGridHeaderMetrics.verticalSeparatorInset,
  ),
  progress: FdcGridProgressStyle(
    color: Color(0xFF38BDF8),
    backgroundColor: Color(0xFF262626),
    textStyle: TextStyle(
      color: Color(0xFFEDEDED),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
  ),
  statusBar: FdcGridStatusBarStyle(
    backgroundColor: Color(0xFF0A0A0A),
    textStyle: TextStyle(color: Color(0xFFEDEDED)),
    height: FdcGridStatusBarStyle.defaultHeight,
    padding: EdgeInsets.symmetric(horizontal: 10),
  ),
  counter: FdcCounterStyle(
    textStyle: TextStyle(color: Color(0xFFEDEDED), fontSize: 11, height: 1),
  ),
  statusBarProgressBar: FdcProgressBarStyle(
    height: 4,
    reserveSpaceWhenIdle: true,
    trackColor: Color(0x33333333),
    valueColor: Color(0xFF38BDF8),
    indeterminateValueColor: Color(0xFF38BDF8),
    animationDuration: Duration.zero,
    visibilityDelay: Duration(milliseconds: 300),
    displayMode: FdcProgressBarDisplayMode.indeterminate,
  ),
  cellIndicator: FdcGridCellIndicatorStyle(
    readOnlyColor: Color(0xFFEF4444),
    editableColor: Color(0xFF22C55E),
    editingColor: Color(0xFF38BDF8),
    thickness: 1,
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  cellErrorIndicator: FdcErrorIndicatorMarkerStyle(
    color: Color(0xFFF87171),
    size: 9,
  ),
);
