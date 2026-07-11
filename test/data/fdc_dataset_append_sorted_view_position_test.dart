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

  dataSet.append();
  dataSet.setFieldValue('id', 4);
  dataSet.setFieldValue('name', 'Aardvark');

  assert(dataSet.state == FdcDataSetState.insert);
  assert(dataSet.recordCount == 4);
  assert(FdcDataSetInternal.activeIndex(dataSet) == dataSet.recordCount - 1);
  assert(
    FdcDataSetInternal.fieldValueAt(dataSet, dataSet.recordCount - 1, 'id') ==
        4,
  );
  assert(dataSet.fieldValue('id') == 4);
  assert(dataSet.fieldValue('name') == 'Aardvark');

  dataSet.post();

  // Post keeps the active view stable. The next explicit sort rebuild may place
  // the posted row according to sort order; append itself must not open the new
  // unposted row at the first visible position just because sorted values say so.
  assert(dataSet.state == FdcDataSetState.browse);
  assert(
    FdcDataSetInternal.fieldValueAt(dataSet, dataSet.recordCount - 1, 'id') ==
        4,
  );
}
