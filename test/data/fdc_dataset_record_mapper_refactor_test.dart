import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

Object? _total(FdcCalculatedFieldContext context) {
  final quantity = context.numValue('quantity') ?? 0;
  final price = context.numValue('price') ?? 0;
  return quantity * price;
}

void main() {
  test(
    'loaded rows do not use defaults but still calculate values',
    _testLoadedRowsDoNotUseDefaultsButStillCalculateValues,
  );
  test(
    'record projection uses active edit buffer',
    _testRecordProjectionUsesActiveEditBuffer,
  );
  test(
    'inserted record projection uses defaults and calculated values',
    _testInsertedRecordProjectionUsesDefaultsAndCalculatedValues,
  );
}

Future<void> _testLoadedRowsDoNotUseDefaultsButStillCalculateValues() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'status', defaultValue: 'new'),
      FdcIntegerField(name: 'quantity', defaultValue: 2),
      FdcDecimalField(
        name: 'price',
        precision: 12,
        scale: 2,
        defaultValue: 5.0,
      ),
      FdcDecimalField(
        name: 'total',
        precision: 12,
        scale: 2,
        calculatedValue: _total,
      ),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  expect(dataSet.fieldValue('name'), 'Alpha');
  expect(dataSet.fieldValue('status'), null);
  expect(dataSet.fieldValue('quantity'), null);
  expect(dataSet.fieldValue('price'), null);
  expect(dataSet.fieldByName('total').asDecimal, '0.00'.decimal);
}

Future<void> _testRecordProjectionUsesActiveEditBuffer() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcIntegerField(name: 'quantity'),
      FdcDecimalField(name: 'price', precision: 12, scale: 2),
      FdcDecimalField(
        name: 'total',
        precision: 12,
        scale: 2,
        calculatedValue: _total,
      ),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'quantity': 1, 'price': 2.0},
      ],
    ),
  );

  await dataSet.open();

  dataSet.edit();
  dataSet.setFieldValue('quantity', 3);

  expect(dataSet.fieldValue('quantity'), 3);
  expect(dataSet.fieldByName('total').asDecimal, '6.00'.decimal);

  dataSet.cancel();
  expect(dataSet.fieldValue('quantity'), 1);
  expect(dataSet.fieldByName('total').asDecimal, '2.00'.decimal);
}

Future<void>
_testInsertedRecordProjectionUsesDefaultsAndCalculatedValues() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'quantity', defaultValue: 4),
      FdcDecimalField(
        name: 'price',
        defaultValue: 2.5,
        precision: 12,
        scale: 2,
      ),
      FdcDecimalField(
        name: 'total',
        precision: 12,
        scale: 2,
        calculatedValue: _total,
      ),
    ],

    adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );

  await dataSet.open();
  dataSet.append();

  expect(dataSet.fieldValue('quantity'), 4);
  expect(dataSet.fieldByName('price').asDecimal, '2.50'.decimal);
  expect(dataSet.fieldByName('total').asDecimal, '10.00'.decimal);
}
