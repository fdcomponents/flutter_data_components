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

/// Soft neutral light grid theme with a subtle grey application-surface look.
const FdcGridThemeData fdcGridLightTheme = FdcGridThemeData(
  grid: FdcGridStyle(
    backgroundColor: Color(0xFFF9FAFB),
    rowIndicatorBackgroundColor: Color(0xFFF3F4F6),
    borderColor: Color(0xFFD1D5DB),
    selectedRowColor: Color(0xFFEFF6FF),
    cellTextStyle: TextStyle(color: Color(0xFF111827)),
    selectedCellBackgroundColor: Color(0x00000000),
    disabledCellBackgroundColor: Color(0x00000000),
    gridLines: FdcGridLines.both,
    gridLineColor: Color(0xFFD1D5DB),
    verticalGridLines: FdcGridVerticalLines.rowsOnly,
  ),
  header: FdcGridHeaderStyle(
    backgroundColor: Color(0xFFF3F4F6),
    textStyle: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600),
    groupBackgroundColor: Color(0xFFF3F4F6),
    groupHeight: 30,
    groupAlignment: Alignment.center,
    groupPadding: EdgeInsets.symmetric(horizontal: 8),
    verticalSeparatorInset: FdcGridHeaderMetrics.verticalSeparatorInset,
  ),
  headerFilters: FdcGridHeaderFilterStyle(
    backgroundColor: Color(0xFFF9FAFB),
    focusedBorderColor: Color(0xFF2563EB),
    unfocusedBorderColor: Color(0xFFD1D5DB),
    focusedBorderWidth: 2,
    unfocusedBorderWidth: 1,
    focusedLabelColor: Color(0xFF2563EB),
    unfocusedLabelColor: Color(0xFF4B5563),
    filterIconColor: Color(0xFF4B5563),
    activeFilterIconColor: Color(0xFF2563EB),
    clearIconColor: Color(0xFF4B5563),
  ),
  toolbar: FdcGridToolbarStyle(
    backgroundColor: Color(0xFFF3F4F6),
    textStyle: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600),
    itemTextColor: Color(0xFF111827),
    itemIconColor: Color(0xFF111827),
    disabledItemTextColor: Color(0xFF9CA3AF),
    disabledItemIconColor: Color(0xFF9CA3AF),
    height: FdcGridToolbarStyle.defaultHeight,
    padding: EdgeInsets.symmetric(horizontal: 8),
    searchExpandedWidth: FdcGridToolbarStyle.defaultSearchExpandedWidth,
    searchFieldHeight: FdcGridToolbarStyle.defaultSearchFieldHeight,
    searchFieldBorderRadius: FdcGridToolbarStyle.defaultSearchFieldBorderRadius,
    searchIconColor: Color(0xFF4B5563),
    searchClearIconColor: Color(0xFF4B5563),
    searchFieldFillColor: Color(0xFFFFFFFF),
    searchFieldBorderColor: Color(0xFFD1D5DB),
    searchFieldFocusedBorderColor: Color(0xFF2563EB),
    searchFieldBorderWidth: FdcGridToolbarStyle.defaultSearchFieldBorderWidth,
    searchFieldFocusedBorderWidth:
        FdcGridToolbarStyle.defaultSearchFieldFocusedBorderWidth,
  ),
  controls: FdcGridControlsStyle(
    iconColor: Color(0xFF374151),
    disabledIconColor: Color(0xFF9CA3AF),
    activeIconColor: Color(0xFF000000),
    checkboxFillColor: Color(0x00000000),
    checkboxCheckColor: Color(0xFF000000),
    checkboxBorderColor: Color(0xFF9CA3AF),
    checkboxDisabledFillColor: Color(0xFFE5E7EB),
    checkboxDisabledCheckColor: Color(0xFF9CA3AF),
    checkboxDisabledBorderColor: Color(0xFF9CA3AF),
    switchThumbColor: Color(0xFF2563EB),
    switchTrackColor: Color(0x662563EB),
    switchDisabledThumbColor: Color(0xFF9CA3AF),
    switchDisabledTrackColor: Color(0xFFE5E7EB),
  ),
  summary: FdcGridSummaryStyle(
    backgroundColor: Color(0xFFF9FAFB),
    textStyle: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w600),
    padding: EdgeInsets.symmetric(horizontal: 10),
    showTopSeparator: true,
    showVerticalSeparators: true,
    verticalSeparatorInset: FdcGridHeaderMetrics.verticalSeparatorInset,
  ),
  progress: FdcGridProgressStyle(
    color: Color(0xFF2563EB),
    backgroundColor: Color(0xFF9CA3AF),
    textStyle: TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
  ),
  statusBar: FdcGridStatusBarStyle(
    backgroundColor: Color(0xFFF3F4F6),
    textStyle: TextStyle(color: Color(0xFF374151)),
    height: FdcGridStatusBarStyle.defaultHeight,
    padding: EdgeInsets.symmetric(horizontal: 10),
  ),
  counter: FdcCounterStyle(
    textStyle: TextStyle(color: Color(0xFF374151), fontSize: 11, height: 1),
  ),
  statusBarProgressBar: FdcProgressBarStyle(
    height: 4,
    reserveSpaceWhenIdle: true,
    trackColor: Color(0x33000000),
    valueColor: Color(0xFF2563EB),
    indeterminateValueColor: Color(0xFF2563EB),
    animationDuration: Duration.zero,
    visibilityDelay: Duration(milliseconds: 300),
    displayMode: FdcProgressBarDisplayMode.indeterminate,
  ),
  cellIndicator: FdcGridCellIndicatorStyle(
    readOnlyColor: Color(0xFFEF4444),
    editableColor: Color(0xFF22C55E),
    editingColor: Color(0xFF2563EB),
    thickness: 1,
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
  cellErrorIndicator: FdcErrorIndicatorMarkerStyle(
    color: Color(0xFFDC2626),
    size: 9,
  ),
);
