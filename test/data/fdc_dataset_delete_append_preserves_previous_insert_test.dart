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
        {'id': 1, 'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();
  dataSet.setFieldValue('id', 2);
  dataSet.setFieldValue('name', 'Inserted');
  dataSet.post();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 2);
  assert(dataSet.changeSet.inserts.length == 1);

  dataSet.append();
  dataSet.setFieldValue('id', 3);
  dataSet.setFieldValue('name', 'Appended');

  assert(dataSet.state == FdcDataSetState.insert);
  assert(dataSet.recordCount == 3);

  dataSet.delete();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 2);
  assert(dataSet.changeSet.inserts.length == 1);

  final ids = <Object?>[
    for (var rowIndex = 0; rowIndex < dataSet.recordCount; rowIndex++)
      FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, 'id'),
  ];

  assert(ids.contains(1));
  assert(ids.contains(2));
  assert(!ids.contains(3));
}
