import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  await _testRecordStoreKeepsIdentityAcrossInsertDeleteAndReload();
  await _testRecordStoreLookupSurvivesApplyAndCancelUpdates();
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

  assert(dataSet.recordCount == 3);
  assert(dataSet.fieldValue('name') == 'Bravo');

  dataSet.delete();

  assert(dataSet.recordCount == 2);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Alpha');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name') == 'Charlie');

  dataSet.close();
  (dataSet.adapter as FdcMemoryDataAdapter).replaceRows(
    const <Map<String, Object?>>[
      {'name': 'Delta', 'status': 'active'},
    ],
  );
  await dataSet.open();

  assert(dataSet.recordCount == 1);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Delta');
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
  assert(dataSet.hasUpdates);

  dataSet.cancelUpdates();
  assert(!dataSet.hasUpdates);
  assert(dataSet.recordCount == 2);

  dataSet.last();
  assert(dataSet.fieldValue('name') == 'Bravo');
}
