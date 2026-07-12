import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/format/fdc_field_value_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const codec = FdcFieldValueCodec(settings: FdcFormatSettings());
  const column = FdcDecimalColumn<dynamic>(
    fieldName: 'ratio',
    formatSettings: FdcFormatSettings(),
  );

  test('formats positive infinity as an empty decimal grid value', () {
    expect(codec.formatGridValue(column, double.infinity, decimalScale: 2), '');
  });

  test('formats NaN as an empty decimal grid value', () {
    expect(codec.formatGridValue(column, double.nan, decimalScale: 2), '');
  });
}
