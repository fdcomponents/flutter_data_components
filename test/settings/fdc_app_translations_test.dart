import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestTranslationResolver implements FdcTranslationResolver {
  const _TestTranslationResolver();

  @override
  FdcTranslations resolve(Locale locale) {
    return FdcTranslations(
      common: FdcCommonTranslations(search: 'Search ${locale.languageCode}'),
    );
  }
}

void main() {
  test('FdcDefaultTranslationResolver resolves Croatian by language', () {
    final translations = const FdcDefaultTranslationResolver().resolve(
      const Locale('hr', 'HR'),
    );

    expect(translations.common.search, 'Pretraži');
    expect(translations.common.pickDate, 'Odaberi datum');
    expect(translations.grid.clearFilter, 'Očisti filtar');
    expect(translations.grid.searchAnyWord, 'Bilo koja riječ');
    expect(translations.grid.mainMenu, 'Glavni izbornik');
    expect(translations.grid.exportTo('CSV'), 'Izvoz u CSV');
    expect(translations.grid.valueOf('3', '5'), '3 od 5');
    expect(translations.grid.trendNoData, 'Trend: nema podataka');
    expect(translations.grid.insert, 'Unos');
    expect(translations.grid.closed, 'Zatvoreno');
    expect(translations.grid.workPhaseLabel('filter'), 'Filtriranje dataseta');
    expect(translations.grid.aggregateLabel(FdcAggregate.sum), 'Zbroj');
    expect(translations.grid.aggregateLabel(FdcAggregate.avg), 'Prosjek');
    expect(translations.grid.workPhaseLabel('custom'), 'Rad nad datasetom');
    expect(translations.grid.record(3, 10), 'Zapis 3 od 10');
    expect(translations.grid.record(3, null), 'Zapis 3');
    expect(translations.validation.invalidValue, 'Neispravna vrijednost');
  });

  test('FdcDefaultTranslationResolver falls back to English', () {
    final translations = const FdcDefaultTranslationResolver().resolve(
      const Locale('zz', 'ZZ'),
    );

    expect(translations.common.search, 'Search');
    expect(translations.common.pickDate, 'Pick date');
    expect(translations.grid.clearFilter, 'Clear filter');
    expect(translations.grid.searchAnyWord, 'Any word');
    expect(translations.grid.mainMenu, 'Main menu');
    expect(translations.grid.exportTo('CSV'), 'Export to CSV');
    expect(translations.grid.valueOf('3', '5'), '3 of 5');
    expect(translations.grid.trendNoData, 'Trend: No data');
    expect(translations.grid.insert, 'Insert');
    expect(translations.grid.closed, 'Closed');
    expect(translations.grid.workPhaseLabel('filter'), 'Filtering dataset');
    expect(translations.grid.aggregateLabel(FdcAggregate.sum), 'Sum');
    expect(translations.grid.aggregateLabel(FdcAggregate.avg), 'Avg');
    expect(translations.grid.workPhaseLabel('custom'), 'Dataset work');
    expect(translations.grid.record(3, 10), 'Record 3 of 10');
    expect(translations.grid.record(3, null), 'Record 3');
    expect(translations.validation.invalidValue, 'Invalid value');
  });

  testWidgets('FdcApp.translationsOf prefers explicit translations', (
    tester,
  ) async {
    const explicit = FdcTranslations(
      common: FdcCommonTranslations(search: 'Find'),
    );
    late FdcTranslations resolved;

    await tester.pumpWidget(
      FdcApp(
        translations: explicit,
        child: Builder(
          builder: (context) {
            resolved = FdcApp.translationsOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved.common.search, 'Find');
  });

  testWidgets('FdcApp.translationsOf resolves from Flutter Localizations', (
    tester,
  ) async {
    late FdcTranslations resolved;

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('hr', 'HR'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          FdcLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Builder(
          builder: (context) {
            resolved = FdcApp.translationsOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(resolved.common.search, 'Pretraži');
  });

  testWidgets('FdcApp.translationsOf uses custom translation resolver', (
    tester,
  ) async {
    late FdcTranslations resolved;

    await tester.pumpWidget(
      Localizations(
        locale: const Locale('de', 'DE'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultWidgetsLocalizations.delegate,
        ],
        child: FdcApp(
          translationResolver: const _TestTranslationResolver(),
          child: Builder(
            builder: (context) {
              resolved = FdcApp.translationsOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(resolved.common.search, 'Search de');
  });
}
