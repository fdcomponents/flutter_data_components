// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Public FDC grid API barrel.
///
/// This barrel groups the public grid surface by semantic area. Internal
/// runtime/build models remain private and are not exported from here.
library;

// Main grid widget.
// Public grid exports.
export '../common/fdc_aggregate.dart';
export '../common/fdc_option.dart';
export '../common/input/fdc_boolean_control.dart';
export '../common/input/fdc_keyboard_shortcut.dart';
export '../common/lookup/fdc_lookup_context.dart';
export '../common/lookup/fdc_lookup_result.dart';
export '../common/menu/fdc_menu_entry.dart';
export '../common/theme/fdc_grid_styles.dart';
export '../common/theme/fdc_grid_theme.dart';
export '../common/theme/fdc_theme.dart';
export '../common/widgets/combo/fdc_combo_search_options.dart';
export '../common/widgets/validation/fdc_error_indicator.dart';
export '../data/fdc_dataset_search.dart' show FdcSearchMode;
export '../exports/fdc_export.dart'
    show
        FdcExportColumn,
        FdcExportFormat,
        FdcExportOptions,
        FdcExportResult,
        FdcExportScope,
        FdcExportValueMode;
export 'columns/fdc_action_column.dart'
    show
        FdcActionColumn,
        FdcRowAction,
        FdcRowActionCallback,
        FdcRowActionContext,
        FdcRowActionPredicate;
export 'columns/fdc_badge_column.dart' show FdcBadgeColumn;
export 'columns/fdc_boolean_column.dart' show FdcBooleanColumn;
export 'columns/fdc_column_base.dart'
    hide
        FdcGridLookupApplyResult,
        FdcGridLookupApplyAccepted,
        FdcGridLookupApplyCanceled;
export 'columns/fdc_combo_column.dart' show FdcComboColumn;
export 'columns/fdc_custom_column.dart'
    show
        FdcCellContext,
        FdcCellValueFormatter,
        FdcCustomCellBuilder,
        FdcCustomColumn,
        FdcFieldContext,
        FdcFieldValueFormatter;
export 'columns/fdc_date_column.dart' show FdcDateColumn;
export 'columns/fdc_datetime_column.dart' show FdcDateTimeColumn;
export 'columns/fdc_decimal_column.dart' show FdcDecimalColumn;
export 'columns/fdc_integer_column.dart' show FdcIntegerColumn;
export 'columns/fdc_memo_column.dart' show FdcMemoColumn;
export 'columns/fdc_progress_column.dart' show FdcProgressColumn;
export 'columns/fdc_text_column.dart' show FdcTextColumn;
export 'columns/fdc_time_column.dart' show FdcTimeColumn;
export 'controllers/fdc_grid_controller.dart' show FdcGridController;
export 'core/fdc_grid_core.dart';
export 'models/fdc_grid_row_context.dart' show FdcGridRowContext;
export 'runtime/fdc_grid_runtime.dart' show FdcGrid;
export 'widgets/fdc_grid_button.dart' show FdcGridButton;
export 'widgets/fdc_grid_items.dart' hide FdcGridItemTheme;
export 'widgets/fdc_grid_status_bar_items.dart'
    show FdcGridProgressBar, FdcGridStatusText;
export 'widgets/fdc_grid_toolbar_items.dart';
