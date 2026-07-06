// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart' show Color, EdgeInsets, TextStyle;

import '../../common/theme/fdc_grid_styles.dart';
import '../../common/theme/fdc_grid_theme_data.dart';
import '../../common/widgets/progress/fdc_progress_bar_style.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';

/// Pure white grid theme. This intentionally preserves the historical FDC
/// light grid defaults.
const FdcGridThemeData fdcGridWhiteTheme = FdcGridThemeData(
  grid: FdcGridStyle.defaults,
  header: FdcGridHeaderStyle.defaults,
  headerFilters: FdcGridHeaderFilterStyle.defaults,
  toolbar: FdcGridToolbarStyle(
    itemTextColor: Color(0xFF111827),
    itemIconColor: Color(0xFF111827),
    disabledItemTextColor: Color(0xFF9CA3AF),
    disabledItemIconColor: Color(0xFF9CA3AF),
    height: FdcGridToolbarStyle.defaultHeight,
    padding: EdgeInsets.symmetric(horizontal: 8),
    searchExpandedWidth: FdcGridToolbarStyle.defaultSearchExpandedWidth,
    searchFieldHeight: FdcGridToolbarStyle.defaultSearchFieldHeight,
    searchFieldBorderRadius: FdcGridToolbarStyle.defaultSearchFieldBorderRadius,
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
  summary: FdcGridSummaryStyle.defaults,
  progress: FdcGridProgressStyle(
    backgroundColor: Color(0xFF9CA3AF),
    textStyle: TextStyle(color: Color(0xFFFFFFFF)),
  ),
  statusBar: FdcGridStatusBarStyle.defaults,
  statusBarProgressBar: FdcProgressBarStyle.defaults,
  cellIndicator: FdcGridCellIndicatorStyle.defaults,
  cellErrorIndicator: FdcErrorIndicatorMarkerStyle.defaults,
);
