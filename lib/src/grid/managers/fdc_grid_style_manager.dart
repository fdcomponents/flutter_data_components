// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../common/theme/fdc_grid_styles.dart';
import '../../common/theme/fdc_grid_theme_data.dart';
import '../../common/widgets/counter/fdc_counter_style.dart';
import '../../common/widgets/progress/fdc_progress_widgets.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';
import '../columns/fdc_grid_columns.dart';
import '../core/fdc_grid_core.dart';
import '../widgets/fdc_grid_header_metrics.dart';

class FdcGridStyleManager {
  FdcGridResolvedCellIndicatorStyle? cellIndicatorStyle({
    required FdcGridThemeData theme,
    required FdcGridCellIndicator indicator,
    required bool selected,
    required bool editing,
    required bool canEdit,
  }) {
    if (!indicator.visible || (!selected && !editing)) {
      return null;
    }

    final style = FdcGridCellIndicatorStyle.defaults
        .merge(theme.cellIndicator)
        .merge(indicator.style);
    final color = editing
        ? style.editingColor ?? FdcGridCellIndicatorStyle.defaults.editingColor
        : canEdit
        ? style.editableColor ??
              FdcGridCellIndicatorStyle.defaults.editableColor
        : style.readOnlyColor ??
              FdcGridCellIndicatorStyle.defaults.readOnlyColor;

    return FdcGridResolvedCellIndicatorStyle(
      color: color ?? const Color(0xFFFF0000),
      thickness: style.thickness ?? 1,
      borderRadius: style.borderRadius,
    );
  }

  Color gridBackgroundColor({required FdcGridStyle style}) {
    return style.backgroundColor ??
        FdcGridStyle.defaults.backgroundColor ??
        Colors.white;
  }

  Color? selectedRowBackgroundColor(FdcGridStyle style) {
    return style.selectedRowColor;
  }

  Color rowIndicatorBackgroundColor(FdcGridStyle style) {
    return style.rowIndicatorBackgroundColor ??
        gridBackgroundColor(style: style);
  }

  Color? cellBackgroundColor({
    required FdcGridColumn<dynamic> column,
    required bool selected,
    required FdcGridStyle style,
  }) {
    if (selected) {
      return style.selectedCellBackgroundColor ?? Colors.transparent;
    }

    final columnBackground = column.cellStyle?.backgroundColor;
    if (columnBackground != null) {
      return columnBackground;
    }

    if (!column.enabled) {
      return style.disabledCellBackgroundColor ??
          FdcGridStyle.defaults.disabledCellBackgroundColor ??
          FdcGridStyle.defaultGridLineColor;
    }

    return null;
  }

  FdcGridLines gridLines(FdcGridStyle style) {
    return style.gridLines ??
        FdcGridStyle.defaults.gridLines ??
        FdcGridLines.both;
  }

  Color gridLineColor(FdcGridStyle style) {
    return style.gridLineColor ??
        FdcGridStyle.defaults.gridLineColor ??
        FdcGridStyle.defaultGridLineColor;
  }

  Color horizontalGridLineColor(FdcGridStyle style) {
    return gridLineColor(style);
  }

  Color verticalGridLineColor(FdcGridStyle style) {
    return gridLineColor(style);
  }

  bool showVerticalGridLines(FdcGridStyle style) {
    final lines = gridLines(style);
    return lines == FdcGridLines.vertical || lines == FdcGridLines.both;
  }

  Color headerBackgroundColor(FdcGridHeaderStyle style) {
    return style.backgroundColor ??
        FdcGridHeaderStyle.defaults.backgroundColor ??
        gridBackgroundColor(style: FdcGridStyle.defaults);
  }

  Color headerSeparatorColor(
    FdcGridStyle gridStyle,
    FdcGridHeaderStyle headerStyle,
  ) {
    return horizontalGridLineColor(gridStyle);
  }

  Color columnGroupHeaderBackgroundColor(FdcGridHeaderStyle style) {
    return style.groupBackgroundColor ?? headerBackgroundColor(style);
  }

  Color columnGroupHeaderBottomSeparatorColor(
    FdcGridStyle gridStyle,
    FdcGridHeaderStyle headerStyle,
  ) {
    return horizontalGridLineColor(gridStyle);
  }

  Color groupHeaderVerticalSeparatorColor(
    FdcGridStyle gridStyle,
    FdcGridHeaderStyle headerStyle,
  ) {
    return showVerticalGridLines(gridStyle)
        ? verticalGridLineColor(gridStyle)
        : Colors.transparent;
  }

  FdcErrorIndicatorMarkerStyle cellErrorIndicatorStyle({
    required FdcGridThemeData theme,
    required FdcGridCellIndicator indicator,
  }) {
    return FdcErrorIndicatorMarkerStyle.defaults
        .merge(theme.cellErrorIndicator)
        .merge(indicator.errorIndicator.markerStyle);
  }

  Color gridBorderColor(FdcGridStyle style) {
    return style.borderColor ??
        FdcGridStyle.defaults.borderColor ??
        horizontalGridLineColor(style);
  }

  FdcGridHeaderStyle headerStyle(
    BuildContext context,
    FdcGridHeader header, {
    required FdcGridThemeData theme,
  }) {
    return FdcGridHeaderStyle.defaults.merge(theme.header).merge(header.style);
  }

  TextStyle? headerTextStyle(
    BuildContext context,
    FdcGridHeaderStyle headerStyle,
  ) {
    return headerStyle.textStyle ?? Theme.of(context).textTheme.labelLarge;
  }

  FdcGridHeaderFilterStyle headerFilterStyle(
    BuildContext context,
    FdcGridHeaderFilters filters, {
    required FdcGridThemeData theme,
    required Color gridBackgroundColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaults = FdcGridHeaderFilterStyle.defaults.merge(
      FdcGridHeaderFilterStyle(
        backgroundColor: gridBackgroundColor,
        focusedBorderColor: colorScheme.primary,
        unfocusedBorderColor: horizontalGridLineColor(theme.grid),
        focusedLabelColor: colorScheme.primary,
        unfocusedLabelColor: colorScheme.onSurfaceVariant,
        filterIconColor: colorScheme.onSurfaceVariant,
        activeFilterIconColor: colorScheme.primary,
        clearIconColor: colorScheme.onSurfaceVariant,
      ),
    );

    return defaults.merge(theme.headerFilters).merge(filters.style);
  }

  FdcGridControlsStyle controlsStyle(
    BuildContext context, {
    required FdcGridThemeData theme,
  }) {
    final materialTheme = Theme.of(context);
    final colorScheme = materialTheme.colorScheme;
    final defaults = FdcGridControlsStyle.defaults.merge(
      FdcGridControlsStyle(
        iconColor: colorScheme.onSurfaceVariant,
        disabledIconColor: materialTheme.disabledColor,
        activeIconColor: colorScheme.primary,
        checkboxFillColor: colorScheme.primary,
        checkboxCheckColor: colorScheme.onPrimary,
        checkboxBorderColor: colorScheme.onSurfaceVariant,
        checkboxDisabledFillColor: materialTheme.disabledColor.withValues(
          alpha: 0.12,
        ),
        checkboxDisabledCheckColor: materialTheme.disabledColor,
        checkboxDisabledBorderColor: materialTheme.disabledColor,
        switchThumbColor: colorScheme.primary,
        switchTrackColor: colorScheme.primary.withValues(alpha: 0.42),
        switchDisabledThumbColor: materialTheme.disabledColor,
        switchDisabledTrackColor: materialTheme.disabledColor.withValues(
          alpha: 0.24,
        ),
      ),
    );

    return defaults.merge(theme.controls);
  }

  FdcGridToolbarStyle toolbarStyle(
    BuildContext context,
    FdcGridStyle style,
    FdcGridToolbar toolbar,
    FdcGridHeader header,
    FdcGridHeaderStyle headerStyle, {
    required FdcGridThemeData theme,
  }) {
    final materialTheme = Theme.of(context);
    final colorScheme = materialTheme.colorScheme;
    final headerBackground = headerBackgroundColor(headerStyle);
    final headerFilter = headerFilterStyle(
      context,
      header.filters,
      theme: theme,
      gridBackgroundColor: gridBackgroundColor(style: style),
    );
    final textStyle = materialTheme.textTheme.labelMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    final defaults = FdcGridToolbarStyle.defaults.merge(
      FdcGridToolbarStyle(
        backgroundColor: headerBackground,
        textStyle: textStyle,
        itemTextColor: colorScheme.onSurfaceVariant,
        itemIconColor: colorScheme.onSurfaceVariant,
        disabledItemTextColor: materialTheme.disabledColor,
        disabledItemIconColor: materialTheme.disabledColor,
        searchIconColor: colorScheme.onSurfaceVariant,
        searchClearIconColor: colorScheme.onSurfaceVariant,
        searchFieldFillColor: gridBackgroundColor(style: style),
        searchFieldBorderColor: headerFilter.unfocusedBorderColor,
        searchFieldFocusedBorderColor: headerFilter.focusedBorderColor,
        searchFieldBorderWidth: headerFilter.unfocusedBorderWidth,
        searchFieldFocusedBorderWidth: headerFilter.focusedBorderWidth,
        searchFieldBorderRadius: FdcGridHeaderMetrics.filterFieldBorderRadius,
      ),
    );

    return defaults.merge(theme.toolbar).merge(toolbar.style);
  }

  FdcGridSummaryStyle summaryRowStyle(
    BuildContext context,
    FdcGridStyle style,
    FdcGridSummary summary, {
    required FdcGridThemeData theme,
    required double rowHeight,
  }) {
    final materialTheme = Theme.of(context);
    final colorScheme = materialTheme.colorScheme;
    final backgroundColor = gridBackgroundColor(style: style);
    final textStyle = materialTheme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    final defaults = FdcGridSummaryStyle.defaults.merge(
      FdcGridSummaryStyle(
        backgroundColor: backgroundColor,
        textStyle: textStyle,
        height: rowHeight,
      ),
    );

    return defaults.merge(theme.summary).merge(summary.style);
  }

  FdcGridStatusBarStyle statusBarStyle(
    BuildContext context,
    FdcGridStyle style,
    FdcGridHeader header,
    FdcGridHeaderStyle headerStyle,
    FdcGridStatusBar statusBar, {
    required FdcGridThemeData theme,
  }) {
    final materialTheme = Theme.of(context);
    final colorScheme = materialTheme.colorScheme;
    final headerBackground = headerBackgroundColor(headerStyle);
    final textStyle = materialTheme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    final defaults = FdcGridStatusBarStyle.defaults.merge(
      FdcGridStatusBarStyle(
        backgroundColor: headerBackground,
        textStyle: textStyle,
      ),
    );

    final resolved = defaults.merge(theme.statusBar).merge(statusBar.style);

    if (statusBar.style.backgroundColor == null &&
        header.style.backgroundColor != null) {
      return FdcGridStatusBarStyle(
        backgroundColor: headerBackground,
        textStyle: resolved.textStyle,
        height: resolved.height,
        padding: resolved.padding,
      );
    }

    return resolved;
  }

  FdcCounterStyle counterStyle(
    BuildContext context,
    FdcCounterStyle columnStyle, {
    required FdcGridThemeData theme,
  }) {
    final materialTheme = Theme.of(context);
    final defaults = FdcCounterStyle(
      textStyle: materialTheme.textTheme.labelSmall?.copyWith(
        color: materialTheme.colorScheme.onSurfaceVariant,
        fontSize: 11,
        height: 1,
      ),
    );

    const columnDefaults = FdcCounterStyle();
    final themed = defaults.merge(theme.counter);
    return themed.copyWith(
      textStyle: columnStyle.textStyle ?? themed.textStyle,
      alignment: columnStyle.alignment == columnDefaults.alignment
          ? themed.alignment
          : columnStyle.alignment,
      offset: columnStyle.offset == columnDefaults.offset
          ? themed.offset
          : columnStyle.offset,
      height: columnStyle.height == columnDefaults.height
          ? themed.height
          : columnStyle.height,
    );
  }

  FdcGridProgressStyle progressStyle(
    BuildContext context,
    FdcGridProgressStyle? columnStyle, {
    required FdcGridThemeData theme,
  }) {
    final materialTheme = Theme.of(context);
    final colorScheme = materialTheme.colorScheme;
    final labelStyle =
        materialTheme.textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    final defaults = FdcGridProgressStyle.defaults.merge(
      FdcGridProgressStyle(
        color: colorScheme.primary,
        backgroundColor: colorScheme.surfaceContainerHighest,
        textStyle: labelStyle.copyWith(
          color: labelStyle.color ?? colorScheme.onSurface,
          fontWeight: labelStyle.fontWeight ?? FontWeight.w700,
        ),
      ),
    );

    return defaults.merge(theme.progress).merge(columnStyle);
  }

  FdcProgressBarStyle statusBarProgressBarStyle(
    BuildContext context,
    FdcGridStatusBar statusBar, {
    required FdcGridThemeData theme,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaults = FdcProgressBarStyle.defaults.merge(
      FdcProgressBarStyle(
        height: 4,
        reserveSpaceWhenIdle: true,
        trackColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.16),
        valueColor: colorScheme.primary,
        indeterminateValueColor: colorScheme.primary,
        animationDuration: Duration.zero,
        visibilityDelay: const Duration(milliseconds: 300),
        displayMode: FdcProgressBarDisplayMode.indeterminate,
      ),
    );

    return defaults.merge(theme.statusBarProgressBar);
  }

  TextStyle? cellTextStyle(BuildContext context, FdcGridStyle style) {
    final configured = style.cellTextStyle;
    if (configured != null) {
      return DefaultTextStyle.of(context).style.merge(configured);
    }

    return Theme.of(context).textTheme.bodyMedium;
  }

  TextStyle? effectiveCellTextStyle(
    BuildContext context, {
    required FdcGridStyle style,
    required FdcGridColumn<dynamic> column,
  }) {
    final baseStyle = cellTextStyle(context, style);
    final columnStyle = column.cellStyle?.textStyle;
    if (columnStyle == null) {
      return baseStyle;
    }
    return baseStyle?.merge(columnStyle) ?? columnStyle;
  }
}
