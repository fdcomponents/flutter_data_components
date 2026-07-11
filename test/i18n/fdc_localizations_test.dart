import 'package:flutter/widgets.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default resolver resolves built-in European locales', () {
    const resolver = FdcDefaultTranslationResolver();

    expect(resolver.resolve(const Locale('it', 'IT')).common.yes, 'Sì');
    expect(resolver.resolve(const Locale('de', 'DE')).common.yes, 'Ja');
    expect(resolver.resolve(const Locale('fr', 'FR')).common.yes, 'Oui');
    expect(resolver.resolve(const Locale('es', 'ES')).common.yes, 'Sí');
  });

  test('localizations delegate supports built-in European locales', () {
    const delegate = FdcLocalizations.delegate;

    expect(delegate.isSupported(const Locale('it', 'IT')), isTrue);
    expect(delegate.isSupported(const Locale('de', 'DE')), isTrue);
    expect(delegate.isSupported(const Locale('fr', 'FR')), isTrue);
    expect(delegate.isSupported(const Locale('es', 'ES')), isTrue);
  });

  test('supported locales include built-in European locales', () {
    expect(
      FdcLocalizations.supportedLocales,
      containsAll(const <Locale>[
        Locale('it', 'IT'),
        Locale('de', 'DE'),
        Locale('fr', 'FR'),
        Locale('es', 'ES'),
      ]),
    );
  });
}
