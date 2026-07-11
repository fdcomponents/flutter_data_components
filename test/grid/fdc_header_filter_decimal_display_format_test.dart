import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/format/fdc_field_value_codec.dart';

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

  final parsed = codec.parseGridText(column, '1234,5', decimalScale: 2);
  assert(parsed == '1234.50'.decimalScale(2));

  final formatted = codec.formatGridValue(column, parsed, decimalScale: 2);
  assert(formatted == '1.234,50');
}
