import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/common/codecs/fdc_value_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FdcValueCodec<DateTime> dateTimeCodec() {
    return FdcValueCodecResolver.resolve<DateTime>(
      const FdcValueCodecConfig(
        kind: FdcValueCodecKind.dateTime,
        sourceName: 'created_at',
        label: 'Created at',
        formatSettings: FdcFormatSettings(
          dateFormat: 'dd/MM/yyyy',
          dateTimeFormat: 'dd/MM/yyyy HH:mm',
        ),
      ),
    );
  }

  test('dateTime codec normalizes date-only commit text to midnight', () {
    final result = dateTimeCodec().parseForCommit('31/12/2029');

    expect(result.errorText, isNull);
    expect(result.value, DateTime(2029, 12, 31));
    expect(result.normalizedText, '31/12/2029 00:00');
  });

  test('dateTime codec still preserves explicit time on commit', () {
    final result = dateTimeCodec().parseForCommit('31/12/2029 14:30');

    expect(result.errorText, isNull);
    expect(result.value, DateTime(2029, 12, 31, 14, 30));
    expect(result.normalizedText, isNull);
  });
}
