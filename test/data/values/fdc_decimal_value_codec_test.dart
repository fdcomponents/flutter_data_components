import 'package:flutter/services.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/common/codecs/fdc_value_codec.dart';
import 'package:flutter_data_components/src/common/format/fdc_decimal_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FdcValueCodec<FdcDecimal> decimalCodec({
    int precision = 5,
    int scale = 2,
    bool negative = true,
    FdcFormatSettings formatSettings = const FdcFormatSettings(),
  }) {
    return FdcValueCodecResolver.resolve<FdcDecimal>(
      FdcValueCodecConfig(
        kind: FdcValueCodecKind.decimal,
        sourceName: 'amount',
        label: 'Amount',
        precision: precision,
        scale: scale,
        negative: negative,
        formatSettings: formatSettings,
      ),
    );
  }

  test('decimal codec rounds scale on commit', () {
    final result = decimalCodec().parseForCommit('123.675');

    expect(result.errorText, isNull);
    expect(result.value?.toString(), '123.68');
    expect(result.normalizedText, '123.68');
  });

  test('decimal codec rounds half away from zero at exact half boundary', () {
    final positive = decimalCodec(precision: 6).parseForCommit('1.005');
    final negative = decimalCodec(precision: 6).parseForCommit('-1.005');

    expect(positive.errorText, isNull);
    expect(positive.value?.toString(), '1.01');
    expect(positive.normalizedText, '1.01');
    expect(negative.errorText, isNull);
    expect(negative.value?.toString(), '-1.01');
    expect(negative.normalizedText, '-1.01');
  });

  test('decimal codec rounds scale zero half away from zero', () {
    final positive = decimalCodec(scale: 0).parseForCommit('123.5');
    final negative = decimalCodec(scale: 0).parseForCommit('-123.5');

    expect(positive.errorText, isNull);
    expect(positive.value?.toString(), '124');
    expect(positive.normalizedText, '124');
    expect(negative.errorText, isNull);
    expect(negative.value?.toString(), '-124');
    expect(negative.normalizedText, '-124');
  });

  test('decimal codec handles zero rounding without negative zero', () {
    final result = decimalCodec().parseForCommit('-0.004');

    expect(result.errorText, isNull);
    expect(result.value?.toString(), '0.00');
    expect(result.normalizedText, '0.00');
  });

  test('decimal codec rejects negative values when not allowed', () {
    final result = decimalCodec(negative: false).parseForCommit('-1.23');

    expect(result.value, isNull);
    expect(result.errorText, contains('valid decimal'));
  });

  test('decimal codec parses localized thousands and decimal separators', () {
    final codec = FdcValueCodecResolver.resolve<FdcDecimal>(
      const FdcValueCodecConfig(
        kind: FdcValueCodecKind.decimal,
        sourceName: 'amount',
        label: 'Amount',
        precision: 10,
        scale: 2,
        formatSettings: FdcFormatSettings(
          decimalSeparator: ',',
          thousandSeparator: '.',
        ),
      ),
    );

    final result = codec.parseForCommit('1.234,565');

    expect(result.errorText, isNull);
    expect(result.value?.toString(), '1234.57');
    expect(result.normalizedText, '1234,57');
  });

  test('localized decimal codec accepts dot decimal clipboard text', () {
    final codec = decimalCodec(
      precision: 6,
      formatSettings: const FdcFormatSettings(
        decimalSeparator: ',',
        thousandSeparator: '.',
      ),
    );

    final result = codec.parseForCommit('1300.21');

    expect(result.errorText, isNull);
    expect(result.value?.toString(), '1300.21');
    expect(result.normalizedText, '1300,21');
  });

  test('localized decimal codec still accepts valid grouped integer text', () {
    final codec = decimalCodec(
      precision: 6,
      formatSettings: const FdcFormatSettings(
        decimalSeparator: ',',
        thousandSeparator: '.',
      ),
    );

    final result = codec.parseForCommit('1.300');

    expect(result.errorText, isNull);
    expect(result.value?.toString(), '1300.00');
    expect(result.normalizedText, '1300,00');
  });

  test('decimal codec rejects precision overflow', () {
    final result = decimalCodec().parseForCommit('12345.67');

    expect(result.value, isNull);
    expect(result.errorText, contains('precision 5 and scale 2'));
  });

  test('decimal codec accepts maximum value within precision', () {
    final result = decimalCodec().parseForCommit('999.99');

    expect(result.errorText, isNull);
    expect(result.value?.toString(), '999.99');
    expect(result.normalizedText, '999.99');
  });

  test('decimal codec rejects overflow caused by rounding', () {
    final result = decimalCodec().parseForCommit('999.995');

    expect(result.value, isNull);
    expect(result.errorText, contains('precision 5 and scale 2'));
  });

  test('decimal codec rounds negative values', () {
    final result = decimalCodec().parseForCommit('-123.456');

    expect(result.errorText, isNull);
    expect(result.value?.toString(), '-123.46');
    expect(result.normalizedText, '-123.46');
  });

  test('decimal input formatter keeps edit text ungrouped while editing', () {
    final formatter = FdcDecimalInputFormatter(
      decimalSeparator: '.',
      thousandSeparator: ',',
      scale: 2,
    );

    const oldValue = TextEditingValue(
      text: '1500.2',
      selection: TextSelection.collapsed(offset: 6),
    );
    const newValue = TextEditingValue(
      text: '1500.21',
      selection: TextSelection.collapsed(offset: 7),
    );

    final result = formatter.formatEditUpdate(oldValue, newValue);

    expect(result.text, '1500.21');
    expect(result.selection.extentOffset, 7);
  });

  test('decimal input formatter keeps localized edit text ungrouped', () {
    final formatter = FdcDecimalInputFormatter(
      decimalSeparator: ',',
      thousandSeparator: '.',
      scale: 2,
    );

    const oldValue = TextEditingValue(
      text: '1500,2',
      selection: TextSelection.collapsed(offset: 6),
    );
    const newValue = TextEditingValue(
      text: '1500,25',
      selection: TextSelection.collapsed(offset: 7),
    );

    final result = formatter.formatEditUpdate(oldValue, newValue);

    expect(result.text, '1500,25');
    expect(result.selection.extentOffset, 7);
  });

  test('decimal input formatter rejects integer precision overflow', () {
    final formatter = FdcDecimalInputFormatter(
      decimalSeparator: '.',
      thousandSeparator: ',',
      precision: 5,
      scale: 2,
    );
    const oldValue = TextEditingValue(
      text: '123',
      selection: TextSelection.collapsed(offset: 3),
    );
    const newValue = TextEditingValue(
      text: '1234',
      selection: TextSelection.collapsed(offset: 4),
    );

    expect(formatter.formatEditUpdate(oldValue, newValue), oldValue);
  });

  test('decimal input formatter rejects fractional scale overflow', () {
    final formatter = FdcDecimalInputFormatter(
      decimalSeparator: '.',
      thousandSeparator: ',',
      precision: 5,
      scale: 2,
    );
    const oldValue = TextEditingValue(
      text: '123.67',
      selection: TextSelection.collapsed(offset: 6),
    );
    const newValue = TextEditingValue(
      text: '123.675',
      selection: TextSelection.collapsed(offset: 7),
    );

    expect(formatter.formatEditUpdate(oldValue, newValue), oldValue);
  });
}
