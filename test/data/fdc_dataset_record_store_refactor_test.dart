import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'record store keeps identity across insert delete and reload',
    _testRecordStoreKeepsIdentityAcrossInsertDeleteAndReload,
  );
  test(
    'record store lookup survives apply and cancel updates',
    _testRecordStoreLookupSurvivesApplyAndCancelUpdates,
  );
}

Future<void> _testRecordStoreKeepsIdentityAcrossInsertDeleteAndReload() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'status'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active'},
        {'name': 'Charlie', 'status': 'active'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.first();
  dataSet.append();
  dataSet.setFieldValue('name', 'Bravo');
  dataSet.setFieldValue('status', 'draft');
  dataSet.post();

  expect(dataSet.recordCount, 3);
  expect(dataSet.fieldValue('name'), 'Bravo');

  dataSet.delete();

  expect(dataSet.recordCount, 2);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Alpha');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name'), 'Charlie');

  dataSet.close();
  (dataSet.adapter as FdcMemoryDataAdapter).replaceRows(
    const <Map<String, Object?>>[
      {'name': 'Delta', 'status': 'active'},
    ],
  );
  await dataSet.open();

  expect(dataSet.recordCount, 1);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Delta');
}

Future<void> _testRecordStoreLookupSurvivesApplyAndCancelUpdates() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha'},
        {'name': 'Bravo'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();
  dataSet.setFieldValue('name', 'Charlie');
  dataSet.post();
  expect(dataSet.hasUpdates, isTrue);

  dataSet.cancelUpdates();
  expect(dataSet.hasUpdates, isFalse);
  expect(dataSet.recordCount, 2);

  dataSet.last();
  expect(dataSet.fieldValue('name'), 'Bravo');
}
