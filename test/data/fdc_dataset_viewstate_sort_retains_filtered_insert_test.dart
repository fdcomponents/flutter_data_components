import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'status'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Bravo', 'status': 'active'},
        {'name': 'Charlie', 'status': 'active'},
      ],
    ),
  );

  const activeFilter = <FdcDataSetFilter>[
    FdcDataSetFilter(
      fieldName: 'status',
      operator: FdcFilterOperator.equals,
      value: 'active',
    ),
  ];

  await dataSet.open();

  await dataSet.filter.set(activeFilter);
  dataSet.append();
  dataSet.setFieldValue('name', 'Aardvark');
  dataSet.setFieldValue('status', 'draft');
  dataSet.post();

  assert(dataSet.recordCount == 3);

  FdcDataSetInternal.setViewState(
    dataSet,
    filters: activeFilter,
    sorts: const <FdcDataSetSort>[FdcDataSetSort(fieldName: 'name')],
    clearRetainedVisibleRecords: false,
  );

  assert(dataSet.recordCount == 3);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Aardvark');

  FdcDataSetInternal.setViewState(
    dataSet,
    filters: activeFilter,
    sorts: const <FdcDataSetSort>[FdcDataSetSort(fieldName: 'name')],
  );

  assert(dataSet.recordCount == 2);
}
