import 'package:flutter_data_components/fdc.dart';

Object? _total(FdcCalculatedFieldContext context) {
  final quantity = context.numValue('quantity') ?? 0;
  final price = context.numValue('price') ?? 0;
  return quantity * price;
}

Future<void> main() async {
  await _testEditBufferWriteUpdatesCalculatedFieldsAndEvents();
  await _testCurrentRecordWriteUpdatesStateAndCalculatedFields();
  await _testOnNewRecordCanSeedDefaultsButNotCalculatedFields();
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

  assert(dataSet.fieldValue('quantity') == 4);
  assert(dataSet.fieldByName('total').asDecimal == '12.00'.decimal);
  assert(changes.any((change) => change.startsWith('quantity:')));
  assert(changes.any((change) => change.startsWith('total:')));

  dataSet.post();
  assert(dataSet.fieldValue('quantity') == 4);
  assert(dataSet.fieldByName('total').asDecimal == '12.00'.decimal);
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

  assert(!dataSet.hasUpdates);
  dataSet.edit();
  dataSet.setFieldValue('price', 5.0);
  dataSet.post();

  assert(dataSet.fieldByName('price').asDecimal == '5.00'.decimal);
  assert(dataSet.fieldByName('total').asDecimal == '10.00'.decimal);
  assert(dataSet.hasUpdates);
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

  assert(dataSet.fieldValue('code') == 'AUTO');
  assert(dataSet.fieldByName('total').asDecimal == '16.00'.decimal);

  dataSet.setFieldValue('code', 'USER');
  assert(dataSet.fieldValue('code') == 'USER');

  var calculatedBlocked = false;
  try {
    dataSet.setFieldValue('total', 123);
    // ignore: avoid_catching_errors
  } on StateError {
    calculatedBlocked = true;
  }
  assert(calculatedBlocked);
}
