import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/format/fdc_field_value_codec.dart';

void main() {
  const codec = FdcFieldValueCodec(settings: FdcFormatSettings());
  const column = FdcDecimalColumn<dynamic>(
    fieldName: 'ratio',
    formatSettings: FdcFormatSettings(),
  );

  assert(codec.formatGridValue(column, double.infinity, decimalScale: 2) == '');
  assert(codec.formatGridValue(column, double.nan, decimalScale: 2) == '');
}
