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
      rows: <Map<String, Object?>>[
        for (var index = 0; index < 50; index++)
          {'id': index + 1, 'name': 'Row ${index + 1}'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.last();
  dataSet.append();
  assert(FdcDataSetInternal.activeIndex(dataSet) == 50);
  assert(dataSet.recordCount == 51);

  dataSet.delete();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 50);
  assert(FdcDataSetInternal.activeIndex(dataSet) == 49);
  assert(
    FdcDataSetInternal.fieldValueAt(
          dataSet,
          FdcDataSetInternal.activeIndex(dataSet),
          'id',
        ) ==
        50,
  );
}
