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
      dataSet.setFieldValue('name', 'New row');
      dataSet.setFieldValue('status', 'draft');
    },

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active'},
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

  assert(dataSet.recordCount == 1);
  dataSet.append();

  assert(dataSet.state == FdcDataSetState.insert);
  assert(dataSet.recordCount == 2);
  assert(FdcDataSetInternal.activeIndex(dataSet) == 1);
  assert(dataSet.fieldValue('name') == 'New row');
  assert(dataSet.fieldValue('status') == 'draft');

  dataSet.post();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 2);
  assert(FdcDataSetInternal.activeIndex(dataSet) == 1);
  assert(dataSet.fieldValue('name') == 'New row');
  assert(dataSet.fieldValue('status') == 'draft');

  await dataSet.filter.set(const <FdcDataSetFilter>[
    FdcDataSetFilter(
      fieldName: 'status',
      operator: FdcFilterOperator.equals,
      value: 'active',
    ),
  ]);

  assert(dataSet.recordCount == 1);
  assert(dataSet.fieldValue('name') == 'Alpha');
}
