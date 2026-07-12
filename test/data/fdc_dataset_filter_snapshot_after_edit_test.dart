import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'post keeps edited record visible until filter is reapplied',
    _testPostKeepsEditedRecordVisibleUntilFilterIsReapplied,
  );
  test(
    'update field keeps edited record visible until filter is reapplied',
    _testUpdateFieldKeepsEditedRecordVisibleUntilFilterIsReapplied,
  );
}

Future<void> _testPostKeepsEditedRecordVisibleUntilFilterIsReapplied() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'status'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active'},
        {'name': 'Beta', 'status': 'inactive'},
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

  expect(dataSet.recordCount, 1);
  expect(dataSet.fieldValue('name'), 'Alpha');

  dataSet.edit();
  dataSet.setFieldValue('status', 'inactive');
  dataSet.post();

  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.recordCount, 1);
  expect(FdcDataSetInternal.activeIndex(dataSet), 0);
  expect(dataSet.fieldValue('name'), 'Alpha');
  expect(dataSet.fieldValue('status'), 'inactive');

  await dataSet.filter.set(const <FdcDataSetFilter>[
    FdcDataSetFilter(
      fieldName: 'status',
      operator: FdcFilterOperator.equals,
      value: 'active',
    ),
  ]);

  expect(dataSet.recordCount, 0);
}

Future<void>
_testUpdateFieldKeepsEditedRecordVisibleUntilFilterIsReapplied() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'status'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active'},
        {'name': 'Beta', 'status': 'inactive'},
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

  expect(dataSet.recordCount, 1);
  dataSet.edit();
  dataSet.setFieldValue('status', 'inactive');
  dataSet.post();

  expect(dataSet.recordCount, 1);
  expect(dataSet.fieldValue('name'), 'Alpha');
  expect(dataSet.fieldValue('status'), 'inactive');

  FdcDataSetInternal.setViewState(
    dataSet,
    filters: const <FdcDataSetFilter>[
      FdcDataSetFilter(
        fieldName: 'status',
        operator: FdcFilterOperator.equals,
        value: 'active',
      ),
    ],
  );

  expect(dataSet.recordCount, 0);
}
