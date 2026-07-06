// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:ui' show Locale, PlatformDispatcher;

part '../../locales/hr_hr.dart';
part '../../locales/en_us.dart';
part '../../locales/en_gb.dart';
part '../../locales/en_ca.dart';
part '../../locales/en_au.dart';
part '../../locales/en_in.dart';
part '../../locales/de_de.dart';
part '../../locales/de_at.dart';
part '../../locales/de_ch.dart';
part '../../locales/fr_fr.dart';
part '../../locales/fr_ca.dart';
part '../../locales/it_it.dart';
part '../../locales/es_es.dart';
part '../../locales/es_mx.dart';
part '../../locales/pt_pt.dart';
part '../../locales/pt_br.dart';
part '../../locales/nl_nl.dart';
part '../../locales/nl_be.dart';
part '../../locales/pl_pl.dart';
part '../../locales/cs_cz.dart';
part '../../locales/sk_sk.dart';
part '../../locales/sl_si.dart';
part '../../locales/hu_hu.dart';
part '../../locales/ro_ro.dart';
part '../../locales/bg_bg.dart';
part '../../locales/sr_rs.dart';
part '../../locales/bs_ba.dart';
part '../../locales/mk_mk.dart';
part '../../locales/sq_al.dart';
part '../../locales/el_gr.dart';
part '../../locales/tr_tr.dart';
part '../../locales/uk_ua.dart';
part '../../locales/ru_ru.dart';
part '../../locales/da_dk.dart';
part '../../locales/sv_se.dart';
part '../../locales/nb_no.dart';
part '../../locales/fi_fi.dart';
part '../../locales/et_ee.dart';
part '../../locales/lv_lv.dart';
part '../../locales/lt_lt.dart';
part '../../locales/ja_jp.dart';
part '../../locales/ko_kr.dart';
part '../../locales/zh_cn.dart';
part '../../locales/zh_tw.dart';
part '../../locales/hi_in.dart';
part '../../locales/ar_sa.dart';
part '../../locales/he_il.dart';
part '../../locales/id_id.dart';
part '../../locales/th_th.dart';
part '../../locales/vi_vn.dart';
part '../../locales/ms_my.dart';

const _neutralDateFormat = 'yyyy-MM-dd';
const _neutralTimeFormat = 'HH:mm';
const _neutralDecimalSeparator = '.';
const _neutralThousandSeparator = ',';
const _neutralShowThousandSeparator = true;

class _FdcUnsetFormatSettingsValue {
  const _FdcUnsetFormatSettingsValue();
}

const Object _fdcUnsetFormatSettingsValue = _FdcUnsetFormatSettingsValue();

/// Formatting settings applied to `flutter_data_components` widgets.
///
/// The default const constructor is the neutral technical fallback for
/// headless/test scenarios and locales that are not covered by the built-in
/// curated FDC locale registry. Application-level settings supplied through
/// `FdcApp.formatSettings` always remain authoritative.
class FdcFormatSettings {
  /// Creates a [FdcFormatSettings].
  const FdcFormatSettings({
    this.locale,
    this.dateFormat = _neutralDateFormat,
    this.timeFormat = _neutralTimeFormat,
    this.dateTimeFormat,
    this.decimalSeparator = _neutralDecimalSeparator,
    this.thousandSeparator = _neutralThousandSeparator,
    this.showThousandSeparator = _neutralShowThousandSeparator,
  });

  /// Creates FDC format settings for the supplied locale.
  ///
  /// This uses the curated built-in FDC locale registry when a preset exists and
  /// falls back to neutral English-style technical defaults otherwise. It never
  /// uses `intl` and never needs asynchronous locale-data initialization.
  factory FdcFormatSettings.fromLocale(Locale locale) {
    final preset = _FdcBuiltInLocaleFormats.tryResolve(locale);
    return preset ?? FdcFormatSettings(locale: canonicalLocaleName(locale));
  }

  /// Creates FDC format settings for the current platform locale.
  factory FdcFormatSettings.system() {
    return FdcFormatSettings.fromLocale(PlatformDispatcher.instance.locale);
  }

  /// Returns locale preset settings when this instance only carries a locale.
  ///
  /// `FdcFormatSettings(locale: 'hr_HR')` is intentionally treated as a
  /// shorthand for the built-in locale preset when all other format values are
  /// left at their neutral constructor defaults. If any concrete format value
  /// is supplied, this instance remains authoritative and is returned as-is.
  FdcFormatSettings resolveLocaleOnlyPreset() {
    if (!_isLocaleOnlyPresetRequest) {
      return this;
    }

    final resolvedLocale = parseFdcLocaleName(locale!);
    final preset = _FdcBuiltInLocaleFormats.tryResolve(resolvedLocale);
    return preset ?? this;
  }

  bool get _isLocaleOnlyPresetRequest {
    return locale != null &&
        locale!.trim().isNotEmpty &&
        dateFormat == _neutralDateFormat &&
        timeFormat == _neutralTimeFormat &&
        dateTimeFormat == null &&
        decimalSeparator == _neutralDecimalSeparator &&
        thousandSeparator == _neutralThousandSeparator &&
        showThousandSeparator == _neutralShowThousandSeparator;
  }

  /// Locale associated with these settings.
  final String? locale;

  /// Pattern used to format date values.
  final String dateFormat;

  /// Pattern used to format time values.
  final String timeFormat;

  /// Pattern used to format date-time values.
  final String? dateTimeFormat;

  /// Character used as the decimal separator.
  final String decimalSeparator;

  /// Character used as the thousands separator.
  final String thousandSeparator;

  /// Whether show thousand separator.
  final bool showThousandSeparator;

  /// Returns the current effective date time format.
  String get effectiveDateTimeFormat =>
      dateTimeFormat ?? '$dateFormat $timeFormat';

  /// Returns a copy with changed format settings.
  ///
  /// `locale` and `dateTimeFormat` intentionally use sentinel parameters so
  /// `copyWith()` keeps the current nullable values, while
  /// `copyWith(locale: null)` or `copyWith(dateTimeFormat: null)` clears them.
  /// Passing non-null values for those parameters must still use `String`.
  FdcFormatSettings copyWith({
    Object? locale = _fdcUnsetFormatSettingsValue,
    String? dateFormat,
    String? timeFormat,
    Object? dateTimeFormat = _fdcUnsetFormatSettingsValue,
    String? decimalSeparator,
    String? thousandSeparator,
    bool? showThousandSeparator,
  }) {
    if (!identical(locale, _fdcUnsetFormatSettingsValue) &&
        locale != null &&
        locale is! String) {
      throw ArgumentError.value(
        locale,
        'locale',
        'Expected String, null, or omitted value.',
      );
    }

    if (!identical(dateTimeFormat, _fdcUnsetFormatSettingsValue) &&
        dateTimeFormat != null &&
        dateTimeFormat is! String) {
      throw ArgumentError.value(
        dateTimeFormat,
        'dateTimeFormat',
        'Expected String, null, or omitted value.',
      );
    }

    return FdcFormatSettings(
      locale: identical(locale, _fdcUnsetFormatSettingsValue)
          ? this.locale
          : locale as String?,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      dateTimeFormat: identical(dateTimeFormat, _fdcUnsetFormatSettingsValue)
          ? this.dateTimeFormat
          : dateTimeFormat as String?,
      decimalSeparator: decimalSeparator ?? this.decimalSeparator,
      thousandSeparator: thousandSeparator ?? this.thousandSeparator,
      showThousandSeparator:
          showThousandSeparator ?? this.showThousandSeparator,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcFormatSettings &&
            locale == other.locale &&
            dateFormat == other.dateFormat &&
            timeFormat == other.timeFormat &&
            dateTimeFormat == other.dateTimeFormat &&
            decimalSeparator == other.decimalSeparator &&
            thousandSeparator == other.thousandSeparator &&
            showThousandSeparator == other.showThousandSeparator;
  }

  @override
  int get hashCode => Object.hash(
    locale,
    dateFormat,
    timeFormat,
    dateTimeFormat,
    decimalSeparator,
    thousandSeparator,
    showThousandSeparator,
  );
}

/// Resolves FDC data-entry formats from a Flutter locale.
///
/// Implementations should be deterministic and synchronous. They should not
/// depend on asynchronous locale initialization.
abstract interface class FdcFormatResolver {
  /// Resolves format settings for [locale].
  FdcFormatSettings resolve(Locale locale);
}

/// Default FDC format resolver.
///
/// It uses the built-in locale registry first and falls back to neutral
/// English-style technical settings when FDC has no preset for the locale.
class FdcDefaultFormatResolver implements FdcFormatResolver {
  /// Creates a [FdcDefaultFormatResolver].
  const FdcDefaultFormatResolver();

  @override
  FdcFormatSettings resolve(Locale locale) {
    return _FdcBuiltInLocaleFormats.resolve(locale);
  }
}

/// Curated built-in FDC locale registry.
class _FdcBuiltInLocaleFormats {
  const _FdcBuiltInLocaleFormats._();

  static FdcFormatSettings resolve(Locale locale) {
    return tryResolve(locale) ??
        FdcFormatSettings(locale: canonicalLocaleName(locale));
  }

  static FdcFormatSettings? tryResolve(Locale locale) {
    final canonical = canonicalLocaleName(locale);
    final language = locale.languageCode.toLowerCase();
    final country = locale.countryCode?.toUpperCase();

    final exact = _byLocale[canonical];
    if (exact != null) {
      return exact;
    }

    if (country == null || country.isEmpty) {
      return _byLanguage[language];
    }

    return _byLocale['${language}_$country'] ?? _byLanguage[language];
  }

  static final Map<String, FdcFormatSettings> _byLocale = {
    hrHrFormatSettings.locale!: hrHrFormatSettings,
    enUsFormatSettings.locale!: enUsFormatSettings,
    enGbFormatSettings.locale!: enGbFormatSettings,
    enCaFormatSettings.locale!: enCaFormatSettings,
    enAuFormatSettings.locale!: enAuFormatSettings,
    enInFormatSettings.locale!: enInFormatSettings,
    deDeFormatSettings.locale!: deDeFormatSettings,
    deAtFormatSettings.locale!: deAtFormatSettings,
    deChFormatSettings.locale!: deChFormatSettings,
    frFrFormatSettings.locale!: frFrFormatSettings,
    frCaFormatSettings.locale!: frCaFormatSettings,
    itItFormatSettings.locale!: itItFormatSettings,
    esEsFormatSettings.locale!: esEsFormatSettings,
    esMxFormatSettings.locale!: esMxFormatSettings,
    ptPtFormatSettings.locale!: ptPtFormatSettings,
    ptBrFormatSettings.locale!: ptBrFormatSettings,
    nlNlFormatSettings.locale!: nlNlFormatSettings,
    nlBeFormatSettings.locale!: nlBeFormatSettings,
    plPlFormatSettings.locale!: plPlFormatSettings,
    csCzFormatSettings.locale!: csCzFormatSettings,
    skSkFormatSettings.locale!: skSkFormatSettings,
    slSiFormatSettings.locale!: slSiFormatSettings,
    huHuFormatSettings.locale!: huHuFormatSettings,
    roRoFormatSettings.locale!: roRoFormatSettings,
    bgBgFormatSettings.locale!: bgBgFormatSettings,
    srRsFormatSettings.locale!: srRsFormatSettings,
    bsBaFormatSettings.locale!: bsBaFormatSettings,
    mkMkFormatSettings.locale!: mkMkFormatSettings,
    sqAlFormatSettings.locale!: sqAlFormatSettings,
    elGrFormatSettings.locale!: elGrFormatSettings,
    trTrFormatSettings.locale!: trTrFormatSettings,
    ukUaFormatSettings.locale!: ukUaFormatSettings,
    ruRuFormatSettings.locale!: ruRuFormatSettings,
    daDkFormatSettings.locale!: daDkFormatSettings,
    svSeFormatSettings.locale!: svSeFormatSettings,
    nbNoFormatSettings.locale!: nbNoFormatSettings,
    fiFiFormatSettings.locale!: fiFiFormatSettings,
    etEeFormatSettings.locale!: etEeFormatSettings,
    lvLvFormatSettings.locale!: lvLvFormatSettings,
    ltLtFormatSettings.locale!: ltLtFormatSettings,
    jaJpFormatSettings.locale!: jaJpFormatSettings,
    koKrFormatSettings.locale!: koKrFormatSettings,
    zhCnFormatSettings.locale!: zhCnFormatSettings,
    zhTwFormatSettings.locale!: zhTwFormatSettings,
    hiInFormatSettings.locale!: hiInFormatSettings,
    arSaFormatSettings.locale!: arSaFormatSettings,
    heIlFormatSettings.locale!: heIlFormatSettings,
    idIdFormatSettings.locale!: idIdFormatSettings,
    thThFormatSettings.locale!: thThFormatSettings,
    viVnFormatSettings.locale!: viVnFormatSettings,
    msMyFormatSettings.locale!: msMyFormatSettings,
  };

  static final Map<String, FdcFormatSettings> _byLanguage = {
    'hr': hrHrFormatSettings,
    'en': enUsFormatSettings,
    'de': deDeFormatSettings,
    'fr': frFrFormatSettings,
    'it': itItFormatSettings,
    'es': esEsFormatSettings,
    'pt': ptBrFormatSettings,
    'nl': nlNlFormatSettings,
    'pl': plPlFormatSettings,
    'cs': csCzFormatSettings,
    'sk': skSkFormatSettings,
    'sl': slSiFormatSettings,
    'hu': huHuFormatSettings,
    'ro': roRoFormatSettings,
    'bg': bgBgFormatSettings,
    'sr': srRsFormatSettings,
    'bs': bsBaFormatSettings,
    'mk': mkMkFormatSettings,
    'sq': sqAlFormatSettings,
    'el': elGrFormatSettings,
    'tr': trTrFormatSettings,
    'uk': ukUaFormatSettings,
    'ru': ruRuFormatSettings,
    'da': daDkFormatSettings,
    'sv': svSeFormatSettings,
    'nb': nbNoFormatSettings,
    'fi': fiFiFormatSettings,
    'et': etEeFormatSettings,
    'lv': lvLvFormatSettings,
    'lt': ltLtFormatSettings,
    'ja': jaJpFormatSettings,
    'ko': koKrFormatSettings,
    'zh': zhCnFormatSettings,
    'hi': hiInFormatSettings,
    'ar': arSaFormatSettings,
    'he': heIlFormatSettings,
    'id': idIdFormatSettings,
    'th': thThFormatSettings,
    'vi': viVnFormatSettings,
    'ms': msMyFormatSettings,
  };
}

/// Returns the canonical locale name used by FDC format resolution.
String canonicalLocaleName(Locale locale) {
  final language = locale.languageCode.toLowerCase();
  final countryCode = locale.countryCode;
  return countryCode == null || countryCode.isEmpty
      ? language
      : '${language}_${countryCode.toUpperCase()}';
}

/// Parses an FDC locale name into a [Locale].
Locale parseFdcLocaleName(String locale) {
  final normalized = locale.trim().replaceAll('-', '_');
  final parts = normalized.split('_').where((part) => part.isNotEmpty).toList();

  if (parts.isEmpty) {
    return const Locale('en', 'US');
  }

  final language = parts[0].toLowerCase();
  final country = parts.length >= 2 ? parts[1].toUpperCase() : null;
  return country == null || country.isEmpty
      ? Locale(language)
      : Locale(language, country);
}
