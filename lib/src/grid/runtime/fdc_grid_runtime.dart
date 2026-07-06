// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable, debugPrint;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart';

import '../../app/fdc_app.dart';
import '../../common/codecs/fdc_value_codec.dart';
import '../../common/format/fdc_date_format.dart';
import '../../common/format/fdc_format_settings.dart';
import '../../common/input/fdc_key_utils.dart';
import '../../common/input/fdc_keyboard_shortcut_internal.dart';
import '../../common/input/fdc_value_picker.dart';
import '../../common/menu/fdc_menu_entry.dart';
import '../../common/theme/fdc_grid_theme.dart';
import '../../common/validation/fdc_validation_message_formatter.dart';
import '../../common/widgets/counter/fdc_counter_style.dart';
import '../../data/fdc_data.dart';
import '../../data/fdc_dataset.dart' show FdcDataSetInternal;
import '../../data/fdc_field_name.dart';
import '../../data/filtering/fdc_dataset_filter_change.dart';
import '../../dialogs/fdc_dialogs.dart';
import '../../exports/fdc_export.dart';
import '../../i18n/fdc_translations.dart';
import '../columns/fdc_grid_columns.dart';
import '../controllers/fdc_debounce_controller.dart';
import '../core/fdc_grid_core.dart';
import '../core/fdc_grid_interaction_tokens.dart';
import '../core/fdc_grid_runtime_constants.dart';
import '../editors/fdc_grid_cell_editor.dart';
import '../filtering/fdc_header_filter_input_behavior.dart';
import '../filtering/fdc_header_filter_operator_policy.dart';
import '../filtering/fdc_header_filter_options_resolver.dart';
import '../filtering/fdc_header_filter_state.dart';
import '../filtering/fdc_header_filter_value_codec.dart';
import '../format/fdc_field_value_codec.dart';
import '../format/fdc_value_formatter.dart';
import '../managers/fdc_grid_cell_manager.dart';
import '../managers/fdc_grid_column_manager.dart';
import '../managers/fdc_grid_column_sizing_manager.dart';
import '../managers/fdc_grid_editor_key_manager.dart';
import '../managers/fdc_grid_navigation_manager.dart';
import '../managers/fdc_grid_row_indicator_manager.dart';
import '../managers/fdc_grid_scroll_coordinator.dart';
import '../managers/fdc_grid_scroll_manager.dart';
import '../managers/fdc_grid_sort_manager.dart';
import '../managers/fdc_grid_style_manager.dart';
import '../managers/fdc_grid_typing_manager.dart';
import '../models/fdc_column_identity.dart';
import '../models/fdc_grid_cell_models.dart';
import '../models/fdc_grid_cell_ref.dart';
import '../models/fdc_grid_controller_feature.dart';
import '../models/fdc_grid_detail_row_feature.dart';
import '../models/fdc_grid_field_metadata.dart';
import '../models/fdc_grid_header_models.dart';
import '../models/fdc_grid_layout_models.dart';
import '../models/fdc_grid_layout_persistence_feature.dart';
import '../models/fdc_grid_layout_snapshot.dart';
import '../models/fdc_grid_range_selection_feature.dart';
import '../models/fdc_grid_row_context.dart';
import '../models/fdc_grid_row_indicator_models.dart';
import '../models/fdc_grid_state_models.dart';
import '../models/fdc_grid_viewport_models.dart';
import '../widgets/fdc_grid_header.dart';
import '../widgets/fdc_grid_header_metrics.dart';
import '../widgets/fdc_grid_row.dart';
import '../widgets/fdc_grid_row_indicator_header.dart';
import '../widgets/fdc_grid_status_bar.dart';
import '../widgets/fdc_grid_summary_row.dart';
import '../widgets/fdc_grid_toolbar.dart';
import '../widgets/fdc_grid_viewport.dart';
import 'data/fdc_grid_row_source.dart';

export '../../common/theme/fdc_grid_styles.dart';
export '../../common/theme/fdc_grid_theme.dart';
export '../core/fdc_grid_core.dart';
export '../widgets/fdc_grid_items.dart';
export '../widgets/fdc_grid_status_bar_items.dart';
export '../widgets/fdc_grid_toolbar_items.dart';

part 'core/fdc_grid_runtime_controller.dart';
part 'core/fdc_grid_runtime_domains.dart';
part 'core/fdc_grid_ui_state.dart';
part 'core/fdc_grid_state.dart';
part 'data/fdc_grid_data_ui_state.dart';
part 'data/fdc_grid_data_operation_ui_state.dart';
part 'data/fdc_grid_dataset_filter_runtime.dart';
part 'data/fdc_grid_dataset_event_runtime.dart';
part 'data/fdc_grid_dataset_operation_runtime.dart';
part 'columns/fdc_grid_column_resize_ui_state.dart';
part 'columns/fdc_grid_column_resize_runtime.dart';
part 'columns/fdc_grid_column_resize_layout_runtime.dart';
part 'columns/fdc_grid_column_layout_runtime.dart';
part 'columns/fdc_grid_layout_state_runtime.dart';
part 'columns/fdc_grid_column_cache_runtime.dart';
part 'columns/fdc_grid_column_sizing_runtime.dart';
part 'scroll/fdc_grid_scroll_viewport_ui_state.dart';
part 'scroll/fdc_grid_scroll_ui_state.dart';
part 'scroll/fdc_grid_record_scroll_runtime.dart';
part 'scroll/fdc_grid_scroll_reveal_runtime.dart';
part 'header/fdc_grid_header_filter_ui_state.dart';
part 'header/fdc_grid_header_interaction_ui_state.dart';
part 'header/fdc_grid_header_ui_state.dart';
part 'header/fdc_grid_header_filter_runtime.dart';
part 'navigation/fdc_grid_navigation_ui_state.dart';
part 'navigation/fdc_grid_keyboard_runtime.dart';
part 'navigation/fdc_grid_clipboard_runtime.dart';
part 'navigation/fdc_grid_range_selection_runtime.dart';
part 'navigation/fdc_grid_cell_movement_runtime.dart';
part 'navigation/fdc_grid_cell_traversal_runtime.dart';
part 'navigation/fdc_grid_cell_activation_runtime.dart';
part 'editing/fdc_grid_cell_write_runtime.dart';
part 'editing/fdc_grid_cell_editing_runtime.dart';
part 'summary/fdc_grid_summary_runtime.dart';
part 'header/fdc_grid_header_sort_runtime.dart';
part 'header/fdc_grid_header_action_runtime.dart';
part 'header/fdc_grid_header_model_runtime.dart';
part 'toolbar/fdc_grid_toolbar_search_ui_state.dart';
part 'toolbar/fdc_grid_toolbar_search_runtime.dart';
part 'toolbar/fdc_grid_toolbar_export_runtime.dart';
part 'toolbar/fdc_grid_toolbar_main_menu_runtime.dart';
part 'cells/fdc_grid_cell_ui_state.dart';
part 'cells/fdc_grid_cell_interaction_ui_state.dart';
part 'cells/fdc_grid_cell_state_runtime.dart';
part 'cells/fdc_grid_cell_model_runtime.dart';
part 'cells/fdc_grid_cell_pointer_runtime.dart';
part 'rows/fdc_grid_row_indicator_runtime.dart';
part 'rows/fdc_grid_row_build_runtime.dart';
part 'rows/fdc_grid_detail_row_runtime.dart';
part 'core/fdc_grid_identity_runtime.dart';
part 'core/fdc_grid_interaction_runtime.dart';
part 'core/fdc_grid_focus_event_runtime.dart';
part 'core/fdc_grid_style_runtime.dart';
part 'core/fdc_grid_layout_runtime.dart';
part 'core/fdc_grid_dataset_lifecycle_runtime.dart';
part 'core/fdc_grid_widget_lifecycle_runtime.dart';
part 'core/fdc_grid_view_builder_runtime.dart';
part 'core/fdc_grid_shell_layout_runtime.dart';
part 'core/fdc_grid_build_runtime.dart';

// Tracks live grid focus roots so nested grids can establish keyboard ownership.
// A parent grid may retain selected-cell state, but it must not process key
// events while a nested grid or one of its editors owns primary focus.
final Set<FocusNode> _fdcGridKeyboardFocusRoots = <FocusNode>{};

/// Extension-facing host interface for integrating optional grid features.
///
/// Add-on packages use the host to attach feature behavior without exposing the
/// grid runtime implementation as public API.
class FdcGridHost extends StatefulWidget {
  /// Creates a [FdcGridHost].
  const FdcGridHost({
    super.key,
    this.columns = const <FdcGridColumn<dynamic>>[],
    required this.dataSet,
    this.options = const FdcGridOptions(),
    this.header = const FdcGridHeader(),
    this.rowIndicator = const FdcGridRowIndicator(),
    this.cellIndicator = const FdcGridCellIndicator(),
    this.toolbar = const FdcGridToolbar(),
    this.summary = const FdcGridSummary(),
    this.statusBar = const FdcGridStatusBar(),
    this.theme,
    this.style = const FdcGridStyle(),
    this.formatSettings,
    this.columnGroups = const <FdcGridColumnGroup>[],
    this.pinning = const FdcGridColumnPinning(),
    this.onCellChanged,
    this.onCellTapDown,
    this.onCellDoubleTap,
    this.onRowExit,
    this.onRowEnter,
    this.onColumnExit,
    this.onColumnEnter,
    this.onCellExit,
    this.onCellEnter,
    this.canEditRow,
    this.canEditColumn,
    this.menuBuilder,
    this.detailRow,
    this.controller,
    this.layoutPersistence,
    this.rangeSelection,
  });

  /// Ordered column definitions rendered by the grid.
  final List<FdcGridColumn<dynamic>> columns;

  /// Dataset associated with this object.
  final FdcDataSet dataSet;

  /// Options used by this configuration.
  final FdcGridOptions options;

  /// Header component configuration.
  ///
  /// The header is visible by default. Its height, filter row visibility,
  /// filter debounce behavior, and visual style are owned by this component.
  final FdcGridHeader header;

  /// Row indicator component configuration.
  ///
  /// The row indicator is visible by default and can show record status, row
  /// numbers, row selection, and the main grid menu.
  final FdcGridRowIndicator rowIndicator;

  /// Active cell indicator component configuration.
  ///
  /// The cell indicator is visible by default and marks the current cell with
  /// either a bottom line or an outline. Column-level `showIndicator: false`
  /// suppresses this indicator for that column.
  final FdcGridCellIndicator cellIndicator;

  /// Toolbar component configuration.
  ///
  /// The toolbar is visible by default and renders its default search item.
  /// Provide a custom [FdcGridToolbar.items] list for full control over built-in
  /// and custom toolbar command ordering, or set [FdcGridToolbar.visible] to
  /// false to hide the shell.
  final FdcGridToolbar toolbar;

  /// Summary component configuration.
  ///
  /// The summary is enabled by default, but the panel is rendered only when at
  /// least one visible column has an active summary aggregate. Set
  /// [FdcGridSummary.visible] to `false` to disable it explicitly.
  final FdcGridSummary summary;

  /// Status bar component configuration.
  ///
  /// The status bar is hidden by default. Enable it with
  /// `statusBar: const FdcGridStatusBar(visible: true)`.
  final FdcGridStatusBar statusBar;

  /// Optional complete visual theme preset for this grid.
  ///
  /// When omitted, the grid resolves `FdcThemeData.grid` from the nearest
  /// the nearest FDC theme or app scope, then falls back to the light grid theme.
  /// Component-level styles and [style] remain local overrides.
  final FdcGridThemeData? theme;

  /// Grid-level visual style overrides applied on top of the resolved theme.
  final FdcGridStyle style;

  /// Optional explicit format settings for this grid.
  ///
  /// When omitted, the grid resolves formats from [FdcApp] if present, or from
  /// Flutter's active locale through FDC's built-in locale resolver.
  final FdcFormatSettings? formatSettings;

  /// Optional visual column groups rendered as an additional header row.
  ///
  /// Column groups are layout-only metadata. Columns join a group through
  /// [FdcGridColumn.groupId], which must match a unique
  /// [FdcGridColumnGroup.id]. Groups do not affect dataset schema, sorting,
  /// filtering, editing, or summary aggregation. Grouped columns are treated
  /// as normal scrollable columns; pin actions are hidden for them and
  /// programmatic pinning is ignored while the column belongs to a group.
  final List<FdcGridColumnGroup> columnGroups;

  /// Column pinning behavior and optional pinned-band group labels.
  final FdcGridColumnPinning pinning;

  /// Called after a grid-originated field write has been accepted locally.
  final FdcGridCellChanged? onCellChanged;

  /// Called when a pointer goes down on a body cell.
  final FdcGridCellPointerEvent? onCellTapDown;

  /// Called when a body cell is double-clicked or double-tapped.
  ///
  /// The callback is emitted before the grid starts its built-in edit action.
  final FdcGridCellPointerEvent? onCellDoubleTap;

  /// Called when grid focus leaves a visual row.
  ///
  /// This is a grid/view notification, not a dataset lifecycle event. Use
  /// dataset `beforeScroll`/`afterScroll` for record-level data workflows.
  final FdcGridRowFocusEvent? onRowExit;

  /// Called when grid focus enters a visual row.
  ///
  /// This is a grid/view notification, not a dataset lifecycle event. Use
  /// dataset `beforeScroll`/`afterScroll` for record-level data workflows.
  final FdcGridRowFocusEvent? onRowEnter;

  /// Called when grid focus leaves a visual column.
  final FdcGridColumnFocusEvent? onColumnExit;

  /// Called when grid focus enters a visual column.
  final FdcGridColumnFocusEvent? onColumnEnter;

  /// Called when grid focus leaves a visual cell.
  final FdcGridCellFocusEvent? onCellExit;

  /// Called when grid focus enters a visual cell.
  final FdcGridCellFocusEvent? onCellEnter;

  /// Optional runtime predicate that can veto editing for a visual row.
  final FdcGridCanEditRow? canEditRow;

  /// Optional runtime predicate that can veto editing for a row/column pair.
  final FdcGridCanEditColumn? canEditColumn;

  /// Default body-cell context menu builder. Column-level builders override it.
  final FdcGridMenuBuilder? menuBuilder;

  /// Optional expandable detail-row integration.
  final FdcGridDetailRowFeature? detailRow;

  /// Optional grid controller integration.
  final FdcGridControllerFeature? controller;

  /// Optional grid layout persistence integration.
  final FdcGridLayoutPersistenceFeature? layoutPersistence;

  /// Optional range-selection configuration.
  final FdcGridRangeSelectionFeature? rangeSelection;

  @override
  State<FdcGridHost> createState() => _FdcGridState();
}

/// High-performance data grid widget from the Community package.
///
/// The grid renders and edits an [FdcDataSet] through configured columns while
/// providing navigation, filtering, sorting, paging, and selection behavior.
///
/// Pro-only features such as range selection, expandable detail rows, and
/// layout persistence are intentionally not exposed by this constructor. Use
/// `FdcProGrid` from `package:flutter_data_components_pro/fdc_pro.dart` when
/// those features are required.
class FdcGrid extends FdcGridHost {
  /// Creates a [FdcGrid].
  const FdcGrid({
    super.key,
    super.columns = const <FdcGridColumn<dynamic>>[],
    required super.dataSet,
    super.options = const FdcGridOptions(),
    super.header = const FdcGridHeader(),
    super.rowIndicator = const FdcGridRowIndicator(),
    super.cellIndicator = const FdcGridCellIndicator(),
    super.toolbar = const FdcGridToolbar(),
    super.summary = const FdcGridSummary(),
    super.statusBar = const FdcGridStatusBar(),
    super.theme,
    super.style = const FdcGridStyle(),
    super.formatSettings,
    super.columnGroups = const <FdcGridColumnGroup>[],
    super.pinning = const FdcGridColumnPinning(),
    super.onCellChanged,
    super.onCellTapDown,
    super.onCellDoubleTap,
    super.onRowExit,
    super.onRowEnter,
    super.onColumnExit,
    super.onColumnEnter,
    super.onCellExit,
    super.onCellEnter,
    super.canEditRow,
    super.canEditColumn,
    super.menuBuilder,
    super.controller,
  }) : super(detailRow: null, layoutPersistence: null, rangeSelection: null);
}
