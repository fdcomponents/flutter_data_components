import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'status'),
    ],
    onNewRecord: (dataSet) {
      dataSet.setFieldValue('status', 'draft');
    },

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();

  assert(dataSet.state == FdcDataSetState.insert);
  assert(dataSet.recordCount == 2);
  assert(dataSet.fieldValue('status') == 'draft');

  dataSet.cancel();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 1);
  assert(dataSet.fieldValue('name') == 'Alpha');

  dataSet.append();
  dataSet.setFieldValue('name', 'Beta');
  dataSet.post();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 2);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name') == 'Beta');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'status') == 'draft');
}
