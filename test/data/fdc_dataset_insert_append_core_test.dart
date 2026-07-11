import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
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
  assert(dataSet.state == FdcDataSetState.insert);
  dataSet.setFieldValue('id', 3);
  dataSet.setFieldValue('name', 'Charlie');
  dataSet.post();

  assert(dataSet.recordCount == 3);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 2, 'name') == 'Charlie');

  dataSet.moveToRecord(2);
  dataSet.insert();
  assert(dataSet.state == FdcDataSetState.insert);
  dataSet.setFieldValue('id', 4);
  dataSet.setFieldValue('name', 'Inserted');
  dataSet.post();

  assert(dataSet.recordCount == 4);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Alpha');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name') == 'Inserted');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 2, 'name') == 'Bravo');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 3, 'name') == 'Charlie');

  assert(
    eventLog.join(',') ==
        'beforeInsert,onNewRecord,afterInsert,'
            'beforeInsert,onNewRecord,afterInsert',
  );

  await duplicateInsertAppendNoopSmokeTest();
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

  assert(dataSet.state == FdcDataSetState.insert);
  assert(dataSet.recordCount == 2);
  assert(dataSet.fieldByName('id').value == 2);
  assert(dataSet.fieldByName('name').value == 'Bravo');
  assert(eventLog.join(',') == 'beforeInsert,onNewRecord,afterInsert');

  dataSet.post();
  assert(dataSet.recordCount == 2);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name') == 'Bravo');
}
