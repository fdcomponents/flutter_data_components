// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/widgets/counter/fdc_counter_style.dart';
import '../../common/widgets/progress/fdc_progress_bar_style.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';
import 'fdc_grid_styles.dart';

/// Complete visual theme preset for FdcGrid.
///
/// The data is intentionally grouped by grid component instead of exposing a
/// flat list of colors. Runtime configuration such as visibility and behavior
/// remains on FdcGrid, FdcGridHeader, FdcGridToolbar, and related
/// component configuration objects; this class only carries visual defaults.
class FdcGridThemeData {
  /// Creates a [FdcGridThemeData].
  const FdcGridThemeData({
    this.grid = const FdcGridStyle(),
    this.header = const FdcGridHeaderStyle(),
    this.headerFilters = const FdcGridHeaderFilterStyle(),
    this.toolbar = const FdcGridToolbarStyle(),
    this.popupMenu = const FdcGridPopupMenuStyle(),
    this.controls = const FdcGridControlsStyle(),
    this.summary = const FdcGridSummaryStyle(),
    this.progress = const FdcGridProgressStyle(),
    this.statusBar = const FdcGridStatusBarStyle(),
    this.statusBarProgressBar = const FdcProgressBarStyle(),
    this.counter = const FdcCounterStyle(),
    this.cellIndicator = const FdcGridCellIndicatorStyle(),
    this.cellErrorIndicator = const FdcErrorIndicatorMarkerStyle(),
  });

  /// Root grid surface, rows, selection, lines, and cell styling.
  final FdcGridStyle grid;

  /// Column header surface, typography, and interaction styling.
  final FdcGridHeaderStyle header;

  /// Header filter-row input and operator-control styling.
  final FdcGridHeaderFilterStyle headerFilters;

  /// Grid toolbar layout, surface, and search-field styling.
  final FdcGridToolbarStyle toolbar;

  /// Popup and column-menu surface and interaction styling.
  final FdcGridPopupMenuStyle popupMenu;

  /// Shared styling for grid-owned buttons and compact controls.
  final FdcGridControlsStyle controls;

  /// Aggregate summary-row presentation and separator styling.
  final FdcGridSummaryStyle summary;

  /// Grid-level dataset progress presentation options.
  final FdcGridProgressStyle progress;

  /// Status-bar surface, sizing, and zone presentation styling.
  final FdcGridStatusBarStyle statusBar;

  /// Progress-bar style used when progress is rendered in the status bar.
  final FdcProgressBarStyle statusBarProgressBar;

  /// Counter/badge style shared by grid surfaces that display counts.
  final FdcCounterStyle counter;

  /// Active-cell indicator styling for read-only, editable, and editing states.
  final FdcGridCellIndicatorStyle cellIndicator;

  /// Validation marker styling used for cells with field errors.
  final FdcErrorIndicatorMarkerStyle cellErrorIndicator;

  /// Creates a copy with selected values replaced.
  FdcGridThemeData copyWith({
    FdcGridStyle? grid,
    FdcGridHeaderStyle? header,
    FdcGridHeaderFilterStyle? headerFilters,
    FdcGridToolbarStyle? toolbar,
    FdcGridPopupMenuStyle? popupMenu,
    FdcGridControlsStyle? controls,
    FdcGridSummaryStyle? summary,
    FdcGridProgressStyle? progress,
    FdcGridStatusBarStyle? statusBar,
    FdcProgressBarStyle? statusBarProgressBar,
    FdcCounterStyle? counter,
    FdcGridCellIndicatorStyle? cellIndicator,
    FdcErrorIndicatorMarkerStyle? cellErrorIndicator,
  }) {
    return FdcGridThemeData(
      grid: grid ?? this.grid,
      header: header ?? this.header,
      headerFilters: headerFilters ?? this.headerFilters,
      toolbar: toolbar ?? this.toolbar,
      popupMenu: popupMenu ?? this.popupMenu,
      controls: controls ?? this.controls,
      summary: summary ?? this.summary,
      progress: progress ?? this.progress,
      statusBar: statusBar ?? this.statusBar,
      statusBarProgressBar: statusBarProgressBar ?? this.statusBarProgressBar,
      counter: counter ?? this.counter,
      cellIndicator: cellIndicator ?? this.cellIndicator,
      cellErrorIndicator: cellErrorIndicator ?? this.cellErrorIndicator,
    );
  }

  /// Returns this value with non-null values from [override] applied.
  FdcGridThemeData merge(FdcGridThemeData? override) {
    if (override == null) {
      return this;
    }

    return FdcGridThemeData(
      grid: grid.merge(override.grid),
      header: header.merge(override.header),
      headerFilters: headerFilters.merge(override.headerFilters),
      toolbar: toolbar.merge(override.toolbar),
      popupMenu: popupMenu.merge(override.popupMenu),
      controls: controls.merge(override.controls),
      summary: summary.merge(override.summary),
      progress: progress.merge(override.progress),
      statusBar: statusBar.merge(override.statusBar),
      statusBarProgressBar: statusBarProgressBar.merge(
        override.statusBarProgressBar,
      ),
      counter: counter.merge(override.counter),
      cellIndicator: cellIndicator.merge(override.cellIndicator),
      cellErrorIndicator: cellErrorIndicator.merge(override.cellErrorIndicator),
    );
  }

  /// Interpolates between two values for animated theme transitions.
  FdcGridThemeData lerp(FdcGridThemeData other, double t) {
    return FdcGridThemeData(
      grid: grid.lerp(other.grid, t),
      header: header.lerp(other.header, t),
      headerFilters: headerFilters.lerp(other.headerFilters, t),
      toolbar: toolbar.lerp(other.toolbar, t),
      popupMenu: popupMenu.lerp(other.popupMenu, t),
      controls: controls.lerp(other.controls, t),
      summary: summary.lerp(other.summary, t),
      progress: progress.lerp(other.progress, t),
      statusBar: statusBar.lerp(other.statusBar, t),
      statusBarProgressBar: FdcProgressBarStyle.lerp(
        statusBarProgressBar,
        other.statusBarProgressBar,
        t,
      ),
      counter: counter.lerp(other.counter, t),
      cellIndicator: cellIndicator.lerp(other.cellIndicator, t),
      cellErrorIndicator: cellErrorIndicator.lerp(other.cellErrorIndicator, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridThemeData &&
            grid == other.grid &&
            header == other.header &&
            headerFilters == other.headerFilters &&
            toolbar == other.toolbar &&
            popupMenu == other.popupMenu &&
            controls == other.controls &&
            summary == other.summary &&
            progress == other.progress &&
            statusBar == other.statusBar &&
            statusBarProgressBar == other.statusBarProgressBar &&
            counter == other.counter &&
            cellIndicator == other.cellIndicator &&
            cellErrorIndicator == other.cellErrorIndicator;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    grid,
    header,
    headerFilters,
    toolbar,
    popupMenu,
    controls,
    summary,
    progress,
    statusBar,
    statusBarProgressBar,
    counter,
    cellIndicator,
    cellErrorIndicator,
  ]);
}
