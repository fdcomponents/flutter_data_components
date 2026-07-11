import 'package:flutter_data_components/fdc.dart';

Object? _lineTotal(FdcCalculatedFieldContext context) {
  final quantity = context.numValue('quantity') ?? 0;
  final price = context.numValue('price') ?? 0;
  return quantity * price;
}

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'quantity', defaultValue: 0),
      FdcDecimalField(
        name: 'price',
        precision: 12,
        scale: 2,
        defaultValue: 0.0,
      ),
      FdcDecimalField(
        name: 'total',
        precision: 12,
        scale: 2,
        calculatedValue: _lineTotal,
      ),
    ],

    adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );

  await dataSet.open();
  dataSet.append();
  assert(
    (dataSet.fieldByName('total').asDecimal ?? FdcDecimal.zero) ==
        FdcDecimal.zero,
  );

  dataSet.setFieldValue('quantity', 3);
  dataSet.setFieldValue('price', 7.5);
  assert(dataSet.fieldByName('total').asDecimal == '22.50'.decimal);

  dataSet.post();
  assert(dataSet.fieldByName('total').asDecimal == '22.50'.decimal);

  dataSet.edit();
  dataSet.setFieldValue('quantity', 4);
  assert(dataSet.fieldByName('total').asDecimal == '30.00'.decimal);

  var readOnlyThrown = false;
  try {
    dataSet.setFieldValue('total', 123);
    // ignore: avoid_catching_errors
  } on StateError {
    readOnlyThrown = true;
  }
  assert(readOnlyThrown);
}
