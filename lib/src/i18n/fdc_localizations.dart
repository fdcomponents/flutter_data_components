// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';

import 'fdc_translations.dart';

/// Flutter [Localizations] integration for FDC components.
class FdcLocalizations {
  /// Creates FDC localizations for [locale].
  const FdcLocalizations(this.locale, this.translations);

  /// Locale used to resolve [translations].
  final Locale locale;

  /// Resolved FDC translations.
  final FdcTranslations translations;

  /// Built-in FDC locales.
  static const supportedLocales = <Locale>[
    Locale('en', 'US'),
    Locale('hr', 'HR'),
    Locale('it', 'IT'),
    Locale('de', 'DE'),
    Locale('fr', 'FR'),
    Locale('es', 'ES'),
  ];

  /// Default FDC localization delegate.
  static const LocalizationsDelegate<FdcLocalizations> delegate =
      FdcLocalizationsDelegate();

  /// Returns FDC localizations from the nearest [Localizations] widget.
  static FdcLocalizations of(BuildContext context) {
    return Localizations.of<FdcLocalizations>(context, FdcLocalizations)!;
  }

  /// Returns FDC localizations, or null when the app did not register the FDC
  /// delegate.
  static FdcLocalizations? maybeOf(BuildContext context) {
    return Localizations.of<FdcLocalizations>(context, FdcLocalizations);
  }
}

/// Default [LocalizationsDelegate] for [FdcLocalizations].
class FdcLocalizationsDelegate extends LocalizationsDelegate<FdcLocalizations> {
  /// Creates a FDC localizations delegate.
  const FdcLocalizationsDelegate({
    this.resolver = const FdcDefaultTranslationResolver(),
  });

  /// Translation resolver used by this delegate.
  final FdcTranslationResolver resolver;

  @override
  bool isSupported(Locale locale) {
    switch (locale.languageCode.toLowerCase()) {
      case 'en':
      case 'hr':
      case 'it':
      case 'de':
      case 'fr':
      case 'es':
        return true;
    }
    return false;
  }

  @override
  Future<FdcLocalizations> load(Locale locale) {
    return SynchronousFuture<FdcLocalizations>(
      FdcLocalizations(locale, resolver.resolve(locale)),
    );
  }

  @override
  bool shouldReload(covariant FdcLocalizationsDelegate old) {
    return resolver != old.resolver;
  }
}
