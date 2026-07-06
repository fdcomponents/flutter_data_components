// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Lightweight entrypoint for application-wide FDC configuration.
///
/// Use this library when the application root needs `FdcApp`, localization,
/// format resolution, focus policy, or suite theme configuration without
/// importing the full dataset and grid API surface.
///
/// ```dart
/// import 'package:flutter_data_components/fdc_app.dart';
/// ```
library;

export 'src/app/fdc_app.dart' show FdcApp;
export 'src/common/focus/fdc_focus.dart'
    show FdcFocusOptions, FdcFocusScope, FdcFocusTraversalPolicy;
export 'src/common/format/fdc_format_settings.dart'
    show FdcDefaultFormatResolver, FdcFormatResolver, FdcFormatSettings;
export 'src/common/theme/fdc_editor_theme.dart'
    show FdcEditorTheme, FdcEditorThemes;
export 'src/common/theme/fdc_grid_theme.dart' show FdcGridTheme, FdcGridThemes;
export 'src/common/theme/fdc_theme.dart' show FdcTheme;
export 'src/i18n/fdc_localizations.dart'
    show FdcLocalizations, FdcLocalizationsDelegate;
export 'src/i18n/fdc_translations.dart'
    show
        FdcCommonTranslations,
        FdcDecimalPrecisionValidationMessageBuilder,
        FdcDefaultTranslationResolver,
        FdcDialogTranslations,
        FdcFieldLimitValidationMessageBuilder,
        FdcFieldValidationMessageBuilder,
        FdcFilterOperatorTranslations,
        FdcGridTranslations,
        FdcTranslationResolver,
        FdcTranslations,
        FdcValidationTranslations;
