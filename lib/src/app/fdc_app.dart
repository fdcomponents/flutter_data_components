// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import '../common/focus/fdc_focus.dart';
import '../common/format/fdc_format_settings.dart';
import '../common/theme/fdc_theme.dart';
import '../exports/fdc_export_style.dart';
import '../i18n/fdc_localizations.dart';
import '../i18n/fdc_translations.dart';

/// App/subtree-level settings scope for Flutter Data Components.
///
/// `FdcApp` is optional. Components that are not wrapped in it resolve
/// [FdcFormatSettings] from the active Flutter locale through
/// [FdcDefaultFormatResolver], falling back to English-style technical
/// defaults when FDC has no built-in preset for that locale.
///
/// [formatSettings] and [translations] remain authoritative when provided.
/// [theme] provides the app-level visual theme for FDC components.
/// [exportStyle] provides defaults
/// for generated export formats. [focus] provides app-level focus
/// traversal defaults for FDC forms/screens. Individual grids/editors may still
/// override their own theme locally, and [FdcFocusScope] may override focus
/// behavior for a subtree.
class FdcApp extends StatelessWidget {
  /// Creates a [FdcApp].
  const FdcApp({
    super.key,
    this.formatSettings,
    this.formatResolver = const FdcDefaultFormatResolver(),
    this.translations,
    this.translationResolver = const FdcDefaultTranslationResolver(),
    this.theme,
    this.exportStyle = const FdcExportStyle(),
    this.focus = const FdcFocusOptions(),
    required this.child,
  });

  /// Explicit format settings for descendant FDC controls.
  ///
  /// When null, settings are resolved from the active locale through
  /// [formatResolver].
  final FdcFormatSettings? formatSettings;

  /// Locale resolver used when [formatSettings] is not supplied.
  final FdcFormatResolver formatResolver;

  /// Explicit translation bundle for descendant FDC controls.
  ///
  /// When null, translations are resolved through Flutter localization state
  /// and [translationResolver].
  final FdcTranslations? translations;

  /// Locale resolver used when [translations] is not supplied.
  final FdcTranslationResolver translationResolver;

  /// FDC theme data applied to descendant controls.
  final FdcThemeData? theme;

  /// App/subtree-level defaults for generated export formats.
  final FdcExportStyle exportStyle;

  /// Focus behavior applied to descendant controls.
  final FdcFocusOptions focus;

  /// Child widget rendered by this configuration.
  final Widget child;

  /// Returns the translations configured for the nearest [FdcApp], the
  /// Flutter [Localizations] tree, or English defaults.
  static FdcTranslations translationsOf(BuildContext context) {
    final explicit = _scopeOf(context)?.translations;
    if (explicit != null) {
      return explicit;
    }
    final localized = FdcLocalizations.maybeOf(context)?.translations;
    if (localized != null) {
      return localized;
    }
    return _translationsFromContext(context);
  }

  /// Reads translations without subscribing this element to inherited widget
  /// updates.
  static FdcTranslations translationsOfNonListening(BuildContext context) {
    final widget = _scopeOfNonListening(context);
    final explicit = widget?.translations;
    if (explicit != null) {
      return explicit;
    }
    final locale = PlatformDispatcher.instance.locale;
    return (widget?.translationResolver ??
            const FdcDefaultTranslationResolver())
        .resolve(locale);
  }

  /// Returns the export style configured for the nearest [FdcApp].
  static FdcExportStyle exportStyleOf(BuildContext context) {
    return _scopeOf(context)?.exportStyle ?? const FdcExportStyle();
  }

  /// Returns the nearest export style without subscribing to updates.
  static FdcExportStyle exportStyleOfNonListening(BuildContext context) {
    return _scopeOfNonListening(context)?.exportStyle ?? const FdcExportStyle();
  }

  /// Resolves the effective format settings for this build context.
  ///
  /// An explicit [formatSettings] value wins. Otherwise the active locale is
  /// resolved through the nearest [formatResolver] or the default resolver.
  static FdcFormatSettings formatsOf(BuildContext context) {
    final explicit = _scopeOf(context)?.formatSettings;
    return explicit?.resolveLocaleOnlyPreset() ?? _formatsFromContext(context);
  }

  /// Reads format settings without subscribing this element to inherited
  /// widget updates.
  ///
  /// This is intended for `State.initState` paths that need to create an
  /// initial controller value with the same formatting that will be used by
  /// `didChangeDependencies`. Regular build/update code should use
  /// [formatsOf] so it reacts to app settings changes.
  static FdcFormatSettings formatsOfNonListening(BuildContext context) {
    final widget = _scopeOfNonListening(context);
    // Do not call Localizations.maybeLocaleOf here: even with the
    // non-listening FdcApp lookup, Localizations itself is an inherited widget
    // and Flutter forbids registering that dependency from State.initState.
    // initState callers only need a safe initial value; didChangeDependencies
    // immediately refreshes it with the context-aware locale/app settings.
    final explicit = widget?.formatSettings;
    if (explicit != null) {
      return explicit.resolveLocaleOnlyPreset();
    }
    final locale = PlatformDispatcher.instance.locale;
    return (widget?.formatResolver ?? const FdcDefaultFormatResolver()).resolve(
      locale,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget scopedChild = child;

    if (theme != null) {
      scopedChild = FdcTheme(data: theme!, child: scopedChild);
    }

    scopedChild = FdcFocusScope(options: focus, child: scopedChild);

    return _FdcAppScope(
      formatSettings: formatSettings,
      formatResolver: formatResolver,
      translations: translations,
      translationResolver: translationResolver,
      exportStyle: exportStyle,
      child: scopedChild,
    );
  }

  static _FdcAppScope? _scopeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_FdcAppScope>();
  }

  static _FdcAppScope? _scopeOfNonListening(BuildContext context) {
    final appElement = context
        .getElementForInheritedWidgetOfExactType<_FdcAppScope>();
    final appWidget = appElement?.widget;
    return appWidget is _FdcAppScope ? appWidget : null;
  }

  static FdcTranslations _translationsFromContext(BuildContext context) {
    final locale =
        Localizations.maybeLocaleOf(context) ??
        PlatformDispatcher.instance.locale;
    final resolver =
        _scopeOf(context)?.translationResolver ??
        const FdcDefaultTranslationResolver();
    return resolver.resolve(locale);
  }

  static FdcFormatSettings _formatsFromContext(BuildContext context) {
    final locale =
        Localizations.maybeLocaleOf(context) ??
        PlatformDispatcher.instance.locale;
    final resolver =
        _scopeOf(context)?.formatResolver ?? const FdcDefaultFormatResolver();
    return resolver.resolve(locale);
  }
}

class _FdcAppScope extends InheritedWidget {
  const _FdcAppScope({
    required this.formatSettings,
    required this.formatResolver,
    required this.translations,
    required this.translationResolver,
    required this.exportStyle,
    required super.child,
  });

  final FdcFormatSettings? formatSettings;
  final FdcFormatResolver formatResolver;
  final FdcTranslations? translations;
  final FdcTranslationResolver translationResolver;
  final FdcExportStyle exportStyle;

  @override
  bool updateShouldNotify(_FdcAppScope oldWidget) {
    return formatSettings != oldWidget.formatSettings ||
        formatResolver != oldWidget.formatResolver ||
        translations != oldWidget.translations ||
        translationResolver != oldWidget.translationResolver ||
        exportStyle != oldWidget.exportStyle;
  }
}
