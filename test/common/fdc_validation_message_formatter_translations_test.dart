import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/common/validation/fdc_validation_message_formatter.dart';

void main() {
  const validation = FdcValidationTranslations(
    validationError: 'Greška validacije',
    validationFailed: 'Validacija nije uspjela.',
  );

  final message = FdcValidationMessageFormatter.fromObject(
    const FdcDataSetValidationException(<FdcValidationError>[]),
    translations: validation,
  );

  assert(message == 'Validacija nije uspjela.');
  assert(
    FdcValidationMessageFormatter.defaultMessage(validation) ==
        'Greška validacije',
  );
}
