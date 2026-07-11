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
        {'name': 'Zulu', 'status': 'inactive'},
      ],
    ),
  );

  await dataSet.open();

  await dataSet.filter.set(const <FdcDataSetFilter>[
    FdcDataSetFilter(
      fieldName: 'status',
      operator: FdcFilterOperator.equals,
      value: 'active',
    ),
  ]);

  assert(dataSet.recordCount == 2);

  dataSet.append();
  dataSet.setFieldValue('name', 'Aardvark');
  dataSet.setFieldValue('status', 'draft');
  dataSet.post();

  assert(dataSet.recordCount == 3);
  assert(dataSet.fieldValue('name') == 'Aardvark');

  await dataSet.sort.set(const <FdcDataSetSort>[
    FdcDataSetSort(fieldName: 'name'),
  ]);

  assert(dataSet.recordCount == 3);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Aardvark');

  await dataSet.sort.clear();

  assert(dataSet.recordCount == 3);

  // A real filter apply is still the explicit action that rebuilds membership.
  await dataSet.filter.set(const <FdcDataSetFilter>[
    FdcDataSetFilter(
      fieldName: 'status',
      operator: FdcFilterOperator.equals,
      value: 'active',
    ),
  ]);

  assert(dataSet.recordCount == 2);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Bravo');
}
