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

/// Dark theme preset for grids embedded in dark application surfaces.
const FdcGridThemeData fdcGridDarkTheme = FdcGridThemeData(
  grid: FdcGridStyle(
    backgroundColor: Color(0xFF111827),
    rowIndicatorBackgroundColor: Color(0xFF1F2937),
    borderColor: Color(0xFF374151),
    selectedRowColor: Color(0xFF1F2937),
    cellTextStyle: TextStyle(color: Color(0xFFE5E7EB)),
    selectedCellBackgroundColor: Color(0x00000000),
    disabledCellBackgroundColor: Color(0x00000000),
    gridLines: FdcGridLines.both,
    gridLineColor: Color(0xFF374151),
    verticalGridLines: FdcGridVerticalLines.rowsOnly,
  ),
  header: FdcGridHeaderStyle(
    backgroundColor: Color(0xFF1F2937),
    textStyle: TextStyle(color: Color(0xFFE5E7EB), fontWeight: FontWeight.w600),
    groupBackgroundColor: Color(0xFF1F2937),
    groupHeight: 30,
    groupAlignment: Alignment.center,
    groupPadding: EdgeInsets.symmetric(horizontal: 8),
    verticalSeparatorInset: FdcGridHeaderMetrics.verticalSeparatorInset,
  ),
  headerFilters: FdcGridHeaderFilterStyle(
    backgroundColor: Color(0xFF111827),
    focusedBorderColor: Color(0xFF60A5FA),
    unfocusedBorderColor: Color(0xFF4B5563),
    focusedBorderWidth: 2,
    unfocusedBorderWidth: 1,
    focusedLabelColor: Color(0xFF93C5FD),
    unfocusedLabelColor: Color(0xFFD1D5DB),
    filterIconColor: Color(0xFFD1D5DB),
    activeFilterIconColor: Color(0xFF60A5FA),
    clearIconColor: Color(0xFFD1D5DB),
  ),
  toolbar: FdcGridToolbarStyle(
    backgroundColor: Color(0xFF1F2937),
    textStyle: TextStyle(color: Color(0xFFD1D5DB), fontWeight: FontWeight.w600),
    itemTextColor: Color(0xFFD1D5DB),
    itemIconColor: Color(0xFFD1D5DB),
    disabledItemTextColor: Color(0xFF9CA3AF),
    disabledItemIconColor: Color(0xFF9CA3AF),
    height: FdcGridToolbarStyle.defaultHeight,
    padding: EdgeInsets.symmetric(horizontal: 8),
    searchExpandedWidth: FdcGridToolbarStyle.defaultSearchExpandedWidth,
    searchFieldHeight: FdcGridToolbarStyle.defaultSearchFieldHeight,
    searchFieldBorderRadius: FdcGridToolbarStyle.defaultSearchFieldBorderRadius,
    searchIconColor: Color(0xFFD1D5DB),
    searchClearIconColor: Color(0xFFD1D5DB),
    searchFieldFillColor: Color(0xFF111827),
    searchFieldBorderColor: Color(0xFF4B5563),
    searchFieldFocusedBorderColor: Color(0xFF60A5FA),
    searchFieldBorderWidth: FdcGridToolbarStyle.defaultSearchFieldBorderWidth,
    searchFieldFocusedBorderWidth:
        FdcGridToolbarStyle.defaultSearchFieldFocusedBorderWidth,
  ),
  controls: FdcGridControlsStyle(
    iconColor: Color(0xFFD1D5DB),
    disabledIconColor: Color(0xFF6B7280),
    activeIconColor: Color(0xFF60A5FA),
    checkboxFillColor: Color(0xFF60A5FA),
    checkboxCheckColor: Color(0xFF111827),
    checkboxBorderColor: Color(0xFFD1D5DB),
    checkboxDisabledFillColor: Color(0xFF374151),
    checkboxDisabledCheckColor: Color(0xFF9CA3AF),
    checkboxDisabledBorderColor: Color(0xFF6B7280),
    switchThumbColor: Color(0xFF60A5FA),
    switchTrackColor: Color(0x664B9FFF),
    switchDisabledThumbColor: Color(0xFF6B7280),
    switchDisabledTrackColor: Color(0xFF374151),
  ),
  summary: FdcGridSummaryStyle(
    backgroundColor: Color(0xFF111827),
    textStyle: TextStyle(color: Color(0xFFD1D5DB), fontWeight: FontWeight.w600),
    padding: EdgeInsets.symmetric(horizontal: 10),
    showTopSeparator: true,
    showVerticalSeparators: true,
    verticalSeparatorInset: FdcGridHeaderMetrics.verticalSeparatorInset,
  ),
  progress: FdcGridProgressStyle(
    color: Color(0xFF60A5FA),
    backgroundColor: Color(0xFF374151),
    textStyle: TextStyle(
      color: Color(0xFFE5E7EB),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
  ),
  statusBar: FdcGridStatusBarStyle(
    backgroundColor: Color(0xFF1F2937),
    textStyle: TextStyle(color: Color(0xFFD1D5DB)),
    height: FdcGridStatusBarStyle.defaultHeight,
    padding: EdgeInsets.symmetric(horizontal: 10),
  ),
  counter: FdcCounterStyle(
    textStyle: TextStyle(color: Color(0xFFD1D5DB), fontSize: 11, height: 1),
  ),
  statusBarProgressBar: FdcProgressBarStyle(
    height: 4,
    reserveSpaceWhenIdle: true,
    trackColor: Color(0x334B5563),
    valueColor: Color(0xFF60A5FA),
    indeterminateValueColor: Color(0xFF60A5FA),
    animationDuration: Duration.zero,
    visibilityDelay: Duration(milliseconds: 300),
    displayMode: FdcProgressBarDisplayMode.indeterminate,
  ),
  cellIndicator: FdcGridCellIndicatorStyle(
    readOnlyColor: Color(0xFFEF4444),
    editableColor: Color(0xFF22C55E),
    editingColor: Color(0xFF60A5FA),
    thickness: 1,
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  cellErrorIndicator: FdcErrorIndicatorMarkerStyle(
    color: Color(0xFFF87171),
    size: 9,
  ),
);
