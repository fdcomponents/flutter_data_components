import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fdc dataset insert append core', () async {
    final eventLog = <String>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(size: 255, name: 'name'),
      ],
      beforeInsert: (dataSet) => eventLog.add('beforeInsert'),
      onNewRecord: (dataSet) => eventLog.add('onNewRecord'),
      afterInsert: (dataSet) => eventLog.add('afterInsert'),

      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Alpha'},
          <String, Object?>{'id': 2, 'name': 'Bravo'},
        ],
      ),
    );

    await dataSet.open();

    dataSet.append();
    expect(dataSet.state, FdcDataSetState.insert);
    dataSet.setFieldValue('id', 3);
    dataSet.setFieldValue('name', 'Charlie');
    dataSet.post();

    expect(dataSet.recordCount, 3);
    expect(FdcDataSetInternal.fieldValueAt(dataSet, 2, 'name'), 'Charlie');

    dataSet.moveToRecord(2);
    dataSet.insert();
    expect(dataSet.state, FdcDataSetState.insert);
    dataSet.setFieldValue('id', 4);
    dataSet.setFieldValue('name', 'Inserted');
    dataSet.post();

    expect(dataSet.recordCount, 4);
    expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Alpha');
    expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name'), 'Inserted');
    expect(FdcDataSetInternal.fieldValueAt(dataSet, 2, 'name'), 'Bravo');
    expect(FdcDataSetInternal.fieldValueAt(dataSet, 3, 'name'), 'Charlie');

    expect(
      eventLog.join(','),
      'beforeInsert,onNewRecord,afterInsert,'
      'beforeInsert,onNewRecord,afterInsert',
    );

    await duplicateInsertAppendNoopSmokeTest();
  });
}

Future<void> duplicateInsertAppendNoopSmokeTest() async {
  final eventLog = <String>[];

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforeInsert: (dataSet) => eventLog.add('beforeInsert'),
    onNewRecord: (dataSet) => eventLog.add('onNewRecord'),
    afterInsert: (dataSet) => eventLog.add('afterInsert'),

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();
  dataSet.setFieldValue('id', 2);
  dataSet.setFieldValue('name', 'Bravo');

  dataSet.append();
  dataSet.insert();

  expect(dataSet.state, FdcDataSetState.insert);
  expect(dataSet.recordCount, 2);
  expect(dataSet.fieldByName('id').value, 2);
  expect(dataSet.fieldByName('name').value, 'Bravo');
  expect(eventLog.join(','), 'beforeInsert,onNewRecord,afterInsert');

  dataSet.post();
  expect(dataSet.recordCount, 2);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name'), 'Bravo');
}
