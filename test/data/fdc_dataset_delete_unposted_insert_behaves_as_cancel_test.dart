import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  await _testAppendDeleteSilentlyDiscardsWithoutDeleteOrCancelEvents();
  await _testInsertDeleteSilentlyDiscardsOnlyActiveUnpostedRecord();
  await _testBeforeCancelAbortDoesNotBlockDeleteOfUnpostedInsert();
}

Future<void>
_testAppendDeleteSilentlyDiscardsWithoutDeleteOrCancelEvents() async {
  final eventLog = <String>[];

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforeDelete: (dataSet) {
      eventLog.add('beforeDelete');
      throw FdcDataSetAbortException(
        'Delete must not run for unposted insert.',
      );
    },
    afterDelete: (dataSet) {
      eventLog.add('afterDelete');
    },
    beforeCancel: (dataSet) {
      eventLog.add('beforeCancel');
      throw FdcDataSetAbortException('Cancel must not run for delete insert.');
    },
    afterCancel: (dataSet) {
      eventLog.add('afterCancel');
    },

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();
  dataSet.setFieldValue('id', 2);
  dataSet.setFieldValue('name', 'Unposted append');

  dataSet.delete();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 1);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id') == 1);
  assert(dataSet.errors.messages.isEmpty);
  assert(eventLog.isEmpty);
}

Future<void> _testInsertDeleteSilentlyDiscardsOnlyActiveUnpostedRecord() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha'},
        {'id': 3, 'name': 'Gamma'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.moveToRecord(2);
  dataSet.insert();
  dataSet.setFieldValue('id', 2);
  dataSet.setFieldValue('name', 'Unposted insert');

  dataSet.delete();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 2);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id') == 1);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'id') == 3);
  assert(dataSet.changeSet.inserts.isEmpty);
  assert(dataSet.changeSet.deletes.isEmpty);
}

Future<void> _testBeforeCancelAbortDoesNotBlockDeleteOfUnpostedInsert() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforeCancel: (dataSet) {
      throw FdcDataSetAbortException('Cancel is blocked.');
    },

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();
  dataSet.setFieldValue('id', 2);
  dataSet.setFieldValue('name', 'Unposted append');

  dataSet.delete();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 1);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id') == 1);
  assert(dataSet.errors.messages.isEmpty);
}
