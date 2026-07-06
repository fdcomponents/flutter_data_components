// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// High-performance RAD data components for Flutter data applications.
///
/// This is the primary Community entrypoint. It exposes datasets, data-aware
/// editors, grids, filtering, sorting, searching, aggregates, export support,
/// localization, focus management, and shared theme APIs through one stable
/// import:
///
/// ```dart
/// import 'package:flutter_data_components/fdc.dart';
/// ```
///
/// A typical application defines an `FdcDataSet`, binds an `FdcGrid` or editor
/// controls to it, and optionally uses an adapter when data must be loaded or
/// applied through an external source. Lightweight entrypoints are also
/// available for app configuration, editors, and export-only integrations.
library;

export 'fdc_app.dart';
export 'fdc_edit.dart';
export 'fdc_export.dart';
export 'src/common/fdc_aggregate.dart' show FdcAggregate;
export 'src/common/fdc_option.dart' show FdcOption;
export 'src/common/focus/fdc_focus.dart'
    show FdcFocusOptions, FdcFocusScope, FdcFocusTraversalPolicy;
export 'src/common/lookup/fdc_lookup_context.dart' show FdcLookupContext;
export 'src/common/lookup/fdc_lookup_result.dart'
    show FdcLookupMode, FdcLookupResult;
export 'src/common/theme/fdc_theme.dart' show FdcTheme, FdcThemeData;
export 'src/common/widgets/counter/fdc_counter_style.dart' show FdcCounterStyle;
export 'src/common/widgets/progress/fdc_progress_widgets.dart'
    show FdcProgressBar, FdcProgressBarDisplayMode, FdcProgressBarStyle;
export 'src/data/fdc_data.dart';
export 'src/dialogs/fdc_confirmation_dialog.dart'
    show
        FdcConfirmationDefaultButton,
        FdcConfirmationDialog,
        showFdcConfirmationDialog;
export 'src/dialogs/fdc_message_dialog.dart'
    show FdcMessageDialog, showFdcMessageDialog;
export 'src/grid/fdc_grid.dart';
