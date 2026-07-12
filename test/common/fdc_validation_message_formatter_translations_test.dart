import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/common/validation/fdc_validation_message_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validation = FdcValidationTranslations(
    validationError: 'Greška validacije',
    validationFailed: 'Validacija nije uspjela.',
  );

  test(
    'formats an empty dataset validation exception with translated text',
    () {
      final message = FdcValidationMessageFormatter.fromObject(
        const FdcDataSetValidationException(<FdcValidationError>[]),
        translations: validation,
      );

      expect(message, 'Validacija nije uspjela.');
    },
  );

  test('returns the translated default validation error message', () {
    expect(
      FdcValidationMessageFormatter.defaultMessage(validation),
      'Greška validacije',
    );
  });
}
