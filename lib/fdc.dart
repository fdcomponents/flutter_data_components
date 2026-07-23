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
///
/// Canonical API documentation for symbols shared with the focused
/// entrypoints is hosted in this primary library.
/// {@canonicalFor fdc_boolean_control.FdcBooleanControl}
/// {@canonicalFor fdc_boolean_edit.FdcBooleanEdit}
/// {@canonicalFor fdc_combo_edit.FdcComboEdit}
/// {@canonicalFor fdc_combo_search_options.FdcComboSearchMode}
/// {@canonicalFor fdc_combo_search_options.FdcComboSearchOptions}
/// {@canonicalFor fdc_dataset_state.FdcDataSetState}
/// {@canonicalFor fdc_date_edit.FdcDateEdit}
/// {@canonicalFor fdc_date_time_edit.FdcDateTimeEdit}
/// {@canonicalFor fdc_decimal_edit.FdcDecimalEdit}
/// {@canonicalFor fdc_editor_lookup.FdcEditorLookup}
/// {@canonicalFor fdc_editor_styles.FdcEditorComboPopupStyle}
/// {@canonicalFor fdc_editor_styles.FdcEditorControlsStyle}
/// {@canonicalFor fdc_editor_styles.FdcEditorInputStyle}
/// {@canonicalFor fdc_editor_theme.FdcEditorTheme}
/// {@canonicalFor fdc_editor_theme.FdcEditorThemes}
/// {@canonicalFor fdc_editor_theme_data.FdcEditorThemeData}
/// {@canonicalFor fdc_error_indicator.FdcErrorIndicatorMarker}
/// {@canonicalFor fdc_error_indicator.FdcErrorIndicatorMarkerStyle}
/// {@canonicalFor fdc_error_indicator.FdcErrorIndicatorMode}
/// {@canonicalFor fdc_error_indicator.FdcErrorIndicatorOptions}
/// {@canonicalFor fdc_export_column.FdcExportColumn}
/// {@canonicalFor fdc_export_column.FdcExportTextAlignment}
/// {@canonicalFor fdc_export_column.FdcExportValueFormatter}
/// {@canonicalFor fdc_export_format.FdcExportFormat}
/// {@canonicalFor fdc_export_options.FdcExportOptions}
/// {@canonicalFor fdc_export_payload.FdcBinaryExportPayload}
/// {@canonicalFor fdc_export_payload.FdcExportPayload}
/// {@canonicalFor fdc_export_payload.FdcTextExportPayload}
/// {@canonicalFor fdc_export_registry.FdcExportRegistry}
/// {@canonicalFor fdc_export_result.FdcExportResult}
/// {@canonicalFor fdc_export_scope.FdcExportScope}
/// {@canonicalFor fdc_export_style.FdcExportFormatStyle}
/// {@canonicalFor fdc_export_style.FdcExportStyle}
/// {@canonicalFor fdc_export_value_mode.FdcExportValueMode}
/// {@canonicalFor fdc_export_writer.FdcExportWriter}
/// {@canonicalFor fdc_export_writer_context.FdcExportWriterContext}
/// {@canonicalFor fdc_export_writer_options.FdcExportWriterOptions}
/// {@canonicalFor fdc_exporter.FdcExporter}
/// {@canonicalFor fdc_field_events.FdcFieldEventHost}
/// {@canonicalFor fdc_field_events.FdcFieldFocusCallback}
/// {@canonicalFor fdc_field_events.FdcFieldFocusChangeReason}
/// {@canonicalFor fdc_field_events.FdcFieldFocusContext}
/// {@canonicalFor fdc_field_events.FdcFieldValueChangeAccepted}
/// {@canonicalFor fdc_field_events.FdcFieldValueChangeCanceled}
/// {@canonicalFor fdc_field_events.FdcFieldValueChangeReplacement}
/// {@canonicalFor fdc_field_events.FdcFieldValueChangeResult}
/// {@canonicalFor fdc_field_events.FdcFieldValueChangedCallback}
/// {@canonicalFor fdc_field_events.FdcFieldValueChangedContext}
/// {@canonicalFor fdc_field_events.FdcFieldValueChangingCallback}
/// {@canonicalFor fdc_field_events.FdcFieldValueChangingContext}
/// {@canonicalFor fdc_focus.FdcFocusOptions}
/// {@canonicalFor fdc_focus.FdcFocusScope}
/// {@canonicalFor fdc_focus.FdcFocusTraversalPolicy}
/// {@canonicalFor fdc_format_settings.FdcDefaultFormatResolver}
/// {@canonicalFor fdc_format_settings.FdcFormatResolver}
/// {@canonicalFor fdc_format_settings.FdcFormatSettings}
/// {@canonicalFor fdc_grid_theme.FdcGridTheme}
/// {@canonicalFor fdc_grid_theme.FdcGridThemes}
/// {@canonicalFor fdc_integer_edit.FdcIntegerEdit}
/// {@canonicalFor fdc_localizations.FdcLocalizations}
/// {@canonicalFor fdc_localizations.FdcLocalizationsDelegate}
/// {@canonicalFor fdc_lookup_context.FdcLookupContext}
/// {@canonicalFor fdc_lookup_result.FdcLookupMode}
/// {@canonicalFor fdc_lookup_result.FdcLookupResult}
/// {@canonicalFor fdc_memo_edit.FdcMemoEdit}
/// {@canonicalFor fdc_menu_entry.FdcMenuAction}
/// {@canonicalFor fdc_menu_entry.FdcMenuEntry}
/// {@canonicalFor fdc_option.FdcOption}
/// {@canonicalFor fdc_text_edit.FdcTextEdit}
/// {@canonicalFor fdc_theme.FdcTheme}
/// {@canonicalFor fdc_theme_data.FdcThemeData}
/// {@canonicalFor fdc_time_edit.FdcTimeEdit}
/// {@canonicalFor fdc_translations.FdcCommonTranslations}
/// {@canonicalFor fdc_translations.FdcDecimalPrecisionValidationMessageBuilder}
/// {@canonicalFor fdc_translations.FdcDefaultTranslationResolver}
/// {@canonicalFor fdc_translations.FdcDialogTranslations}
/// {@canonicalFor fdc_translations.FdcFieldLimitValidationMessageBuilder}
/// {@canonicalFor fdc_translations.FdcFieldValidationMessageBuilder}
/// {@canonicalFor fdc_translations.FdcFilterOperatorTranslations}
/// {@canonicalFor fdc_translations.FdcGridTranslations}
/// {@canonicalFor fdc_translations.FdcTranslationResolver}
/// {@canonicalFor fdc_translations.FdcTranslations}
/// {@canonicalFor fdc_translations.FdcValidationTranslations}
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
export 'src/common/menu/fdc_menu_overlay.dart' show FdcMenuOverlay;
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
