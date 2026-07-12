import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

Object? _total(FdcCalculatedFieldContext context) {
  final quantity = context.numValue('quantity') ?? 0;
  final price = context.numValue('price') ?? 0;
  return quantity * price;
}

void main() {
  test(
    'edit buffer write updates calculated fields and events',
    _testEditBufferWriteUpdatesCalculatedFieldsAndEvents,
  );
  test(
    'current record write updates state and calculated fields',
    _testCurrentRecordWriteUpdatesStateAndCalculatedFields,
  );
  test(
    'on new record can seed defaults but not calculated fields',
    _testOnNewRecordCanSeedDefaultsButNotCalculatedFields,
  );
}

Future<void> _testEditBufferWriteUpdatesCalculatedFieldsAndEvents() async {
  final changes = <String>[];
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'quantity'),
      FdcDecimalField(name: 'price', precision: 12, scale: 2),
      FdcDecimalField(
        name: 'total',
        precision: 12,
        scale: 2,
        calculatedValue: _total,
      ),
    ],
    onFieldChanged: (dataSet, field, oldValue, newValue) {
      changes.add('${field.name}:$oldValue->$newValue');
    },

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'quantity': 2, 'price': 3.0},
      ],
    ),
  );

  await dataSet.open();

  dataSet.edit();
  dataSet.setFieldValue('quantity', 4);

  expect(dataSet.fieldValue('quantity'), 4);
  expect(dataSet.fieldByName('total').asDecimal, '12.00'.decimal);
  expect(changes.any((change) => change.startsWith('quantity:')), isTrue);
  expect(changes.any((change) => change.startsWith('total:')), isTrue);

  dataSet.post();
  expect(dataSet.fieldValue('quantity'), 4);
  expect(dataSet.fieldByName('total').asDecimal, '12.00'.decimal);
}

Future<void> _testCurrentRecordWriteUpdatesStateAndCalculatedFields() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
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
        {'quantity': 2, 'price': 3.0},
      ],
    ),
  );

  await dataSet.open();

  expect(dataSet.hasUpdates, isFalse);
  dataSet.edit();
  dataSet.setFieldValue('price', 5.0);
  dataSet.post();

  expect(dataSet.fieldByName('price').asDecimal, '5.00'.decimal);
  expect(dataSet.fieldByName('total').asDecimal, '10.00'.decimal);
  expect(dataSet.hasUpdates, isTrue);
}

Future<void> _testOnNewRecordCanSeedDefaultsButNotCalculatedFields() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'code'),
      FdcIntegerField(name: 'quantity'),
      FdcDecimalField(name: 'price', precision: 12, scale: 2),
      FdcDecimalField(
        name: 'total',
        precision: 12,
        scale: 2,
        calculatedValue: _total,
      ),
    ],
    onNewRecord: (dataSet) {
      dataSet.setFieldValue('code', 'AUTO');
      dataSet.setFieldValue('quantity', 2);
      dataSet.setFieldValue('price', 8.0);
    },

    adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );

  await dataSet.open();
  dataSet.append();

  expect(dataSet.fieldValue('code'), 'AUTO');
  expect(dataSet.fieldByName('total').asDecimal, '16.00'.decimal);

  dataSet.setFieldValue('code', 'USER');
  expect(dataSet.fieldValue('code'), 'USER');

  expect(() => dataSet.setFieldValue('total', 123), throwsStateError);
}
