import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validating one field clears only that field error', () async {
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

    expect(dataSet.errors.messages.count, 2);
    expect(dataSet.errors.messageForField('qty'), isNotNull);
    expect(dataSet.errors.messageForField('price'), isNotNull);

    FdcDataSetInternal.validateFieldValueAndEmit(dataSet, 'qty', 2);

    expect(dataSet.errors.messages.count, 1);
    expect(dataSet.errors.messageForField('qty'), isNull);
    expect(dataSet.errors.messageForField('price'), isNotNull);
  });
}
