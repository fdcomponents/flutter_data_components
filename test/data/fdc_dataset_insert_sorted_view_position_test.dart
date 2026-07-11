import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Bravo'},
        {'id': 2, 'name': 'Charlie'},
        {'id': 3, 'name': 'Delta'},
      ],
    ),
  );

  await dataSet.open();

  await dataSet.sort.set(const <FdcDataSetSort>[
    FdcDataSetSort(fieldName: 'name'),
  ]);

  dataSet.moveToRecord(2); // Charlie is the current visible record.
  assert(dataSet.fieldValue('id') == 2);

  dataSet.insert();
  dataSet.setFieldValue('id', 4);
  dataSet.setFieldValue('name', 'Aardvark');

  assert(dataSet.state == FdcDataSetState.insert);
  assert(dataSet.recordCount == 4);

  // insert() must visually insert before the record that was current when
  // insert() was called, even when the new values would sort elsewhere.
  assert(FdcDataSetInternal.activeIndex(dataSet) == 1);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id') == 1);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'id') == 4);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 2, 'id') == 2);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 3, 'id') == 3);
  assert(dataSet.fieldValue('id') == 4);
  assert(dataSet.fieldValue('name') == 'Aardvark');
}
