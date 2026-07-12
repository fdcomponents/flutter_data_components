import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/format/fdc_field_value_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const column = FdcDecimalColumn<dynamic>(
    fieldName: 'amount',
    formatSettings: FdcFormatSettings(
      decimalSeparator: ',',
      thousandSeparator: '.',
    ),
  );
  const codec = FdcFieldValueCodec(
    settings: FdcFormatSettings(decimalSeparator: ',', thousandSeparator: '.'),
  );

  test('parses localized decimal header-filter text at the field scale', () {
    final parsed = codec.parseGridText(column, '1234,5', decimalScale: 2);

    expect(parsed, '1234.50'.decimalScale(2));
  });

  test('formats a decimal header-filter value with localized separators', () {
    final value = '1234.50'.decimalScale(2);

    expect(codec.formatGridValue(column, value, decimalScale: 2), '1.234,50');
  });
}
