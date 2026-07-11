import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestFormatResolver implements FdcFormatResolver {
  const _TestFormatResolver();

  @override
  FdcFormatSettings resolve(Locale locale) {
    return FdcFormatSettings(
      locale: '${locale.languageCode}_TEST',
      dateFormat: 'dd/MM/yyyy',
      dateTimeFormat: 'dd/MM/yyyy HH:mm',
      decimalSeparator: ',',
      thousandSeparator: ' ',
    );
  }
}

void main() {
  test('FdcFormatSettings.fromLocale uses built-in locale registry', () {
    final settings = FdcFormatSettings.fromLocale(const Locale('hr', 'HR'));

    expect(settings.locale, 'hr_HR');
    expect(settings.dateFormat, 'dd.MM.yyyy');
    expect(settings.timeFormat, 'HH:mm');
    expect(settings.effectiveDateTimeFormat, 'dd.MM.yyyy HH:mm');
    expect(settings.decimalSeparator, ',');
    expect(settings.thousandSeparator, '.');
  });

  test('FdcFormatSettings.fromLocale falls back to neutral English format', () {
    final settings = FdcFormatSettings.fromLocale(const Locale('zz', 'ZZ'));

    expect(settings.locale, 'zz_ZZ');
    expect(settings.dateFormat, 'yyyy-MM-dd');
    expect(settings.timeFormat, 'HH:mm');
    expect(settings.effectiveDateTimeFormat, 'yyyy-MM-dd HH:mm');
    expect(settings.decimalSeparator, '.');
    expect(settings.thousandSeparator, ',');
  });

  test(
    'FdcFormatSettings.fromLocale falls back by language for curated presets',
    () {
      final settings = FdcFormatSettings.fromLocale(const Locale('en', 'NZ'));

      expect(settings.locale, 'en_US');
      expect(settings.dateFormat, 'MM/dd/yyyy');
      expect(settings.decimalSeparator, '.');
      expect(settings.thousandSeparator, ',');
    },
  );

  test('FdcFormatSettings.copyWith can clear nullable values', () {
    const settings = FdcFormatSettings(
      locale: 'hr_HR',
      dateFormat: 'dd.MM.yyyy',
      dateTimeFormat: 'dd.MM.yyyy HH:mm',
      decimalSeparator: ',',
      thousandSeparator: '.',
    );

    final copied = settings.copyWith(locale: null, dateTimeFormat: null);

    expect(copied.locale, isNull);
    expect(copied.dateTimeFormat, isNull);
    expect(copied.dateFormat, 'dd.MM.yyyy');
    expect(copied.timeFormat, 'HH:mm');
    expect(copied.decimalSeparator, ',');
    expect(copied.thousandSeparator, '.');
  });

  test('FdcFormatSettings.copyWith keeps nullable values when omitted', () {
    const settings = FdcFormatSettings(
      locale: 'hr_HR',
      dateTimeFormat: 'dd.MM.yyyy HH:mm',
    );

    final copied = settings.copyWith(dateFormat: 'yyyy/MM/dd');

    expect(copied.locale, 'hr_HR');
    expect(copied.dateTimeFormat, 'dd.MM.yyyy HH:mm');
    expect(copied.dateFormat, 'yyyy/MM/dd');
  });

  testWidgets('FdcApp.formatsOf resolves active locale when not explicit', (
    tester,
  ) async {
    late FdcFormatSettings resolved;

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('hr', 'HR'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Builder(
          builder: (context) {
            resolved = FdcApp.formatsOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved.locale, 'hr_HR');
    expect(resolved.dateFormat, 'dd.MM.yyyy');
    expect(resolved.decimalSeparator, ',');
  });

  testWidgets('FdcApp.formatsOf prefers explicit format settings', (
    tester,
  ) async {
    const explicit = FdcFormatSettings(
      locale: 'hr_HR',
      dateFormat: 'dd.MM.yyyy',
      dateTimeFormat: 'dd.MM.yyyy HH:mm',
      decimalSeparator: ',',
      thousandSeparator: '.',
    );
    late FdcFormatSettings resolved;

    await tester.pumpWidget(
      FdcApp(
        formatSettings: explicit,
        child: Builder(
          builder: (context) {
            resolved = FdcApp.formatsOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved, explicit);
  });

  testWidgets('FdcApp.formatSettings locale-only shorthand resolves preset', (
    tester,
  ) async {
    late FdcFormatSettings resolved;

    await tester.pumpWidget(
      FdcApp(
        formatSettings: const FdcFormatSettings(locale: 'hr_HR'),
        child: Builder(
          builder: (context) {
            resolved = FdcApp.formatsOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved.locale, 'hr_HR');
    expect(resolved.dateFormat, 'dd.MM.yyyy');
    expect(resolved.timeFormat, 'HH:mm');
    expect(resolved.effectiveDateTimeFormat, 'dd.MM.yyyy HH:mm');
    expect(resolved.decimalSeparator, ',');
    expect(resolved.thousandSeparator, '.');
  });

  testWidgets(
    'FdcApp.formatSettings with concrete values stays authoritative',
    (tester) async {
      const explicit = FdcFormatSettings(
        locale: 'hr_HR',
        dateFormat: 'yyyy/MM/dd',
        timeFormat: 'HH.mm',
        dateTimeFormat: 'yyyy/MM/dd HH.mm',
        thousandSeparator: ' ',
      );
      late FdcFormatSettings resolved;

      await tester.pumpWidget(
        FdcApp(
          formatSettings: explicit,
          child: Builder(
            builder: (context) {
              resolved = FdcApp.formatsOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, explicit);
    },
  );

  testWidgets('FdcApp.formatsOf uses custom format resolver', (tester) async {
    late FdcFormatSettings resolved;

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('fr', 'FR'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultWidgetsLocalizations.delegate,
        ],
        child: FdcApp(
          formatResolver: const _TestFormatResolver(),
          child: Builder(
            builder: (context) {
              resolved = FdcApp.formatsOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(resolved.locale, 'fr_TEST');
    expect(resolved.decimalSeparator, ',');
    expect(resolved.thousandSeparator, ' ');
  });
}
