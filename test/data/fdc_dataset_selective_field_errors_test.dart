import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'qty', label: 'Quantity', minValue: 1),
      FdcDecimalField(
        name: 'price',
        precision: 12,
        scale: 2,
        label: 'Price',
        minValue: 1,
      ),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'qty': 5, 'price': 5.0},
      ],
    ),
  );

  await dataSet.open();
  dataSet.edit();

  FdcDataSetInternal.validateFieldValueAndEmit(dataSet, 'qty', 0);
  FdcDataSetInternal.validateFieldValueAndEmit(dataSet, 'price', 0);

  assert(dataSet.errors.messages.count == 2);
  assert(dataSet.errors.messageForField('qty') != null);
  assert(dataSet.errors.messageForField('price') != null);

  FdcDataSetInternal.validateFieldValueAndEmit(dataSet, 'qty', 2);

  assert(dataSet.errors.messages.count == 1);
  assert(dataSet.errors.messageForField('qty') == null);
  assert(dataSet.errors.messageForField('price') != null);
}
