import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'has updates ignores non persistent modified fields',
    _testHasUpdatesIgnoresNonPersistentModifiedFields,
  );
  test(
    'has updates sees persistent modified fields',
    _testHasUpdatesSeesPersistentModifiedFields,
  );
  test(
    'close clears records and view state',
    _testCloseClearsRecordsAndViewState,
  );
}

Future<void> _testHasUpdatesIgnoresNonPersistentModifiedFields() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'uiOnly', persistent: false),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'uiOnly': 'old'},
      ],
    ),
  );

  await dataSet.open();

  expect(dataSet.hasUpdates, isFalse);
  dataSet.edit();
  dataSet.setFieldValue('uiOnly', 'new');
  dataSet.post();

  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.changeSet, isEmpty);
  expect(dataSet.hasUpdates, isFalse);
}

Future<void> _testHasUpdatesSeesPersistentModifiedFields() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'uiOnly', persistent: false),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'uiOnly': 'old'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.edit();
  dataSet.setFieldValue('name', 'Beta');
  dataSet.post();

  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.changeSet.isEmpty, isFalse);
  expect(dataSet.hasUpdates, isTrue);
}

Future<void> _testCloseClearsRecordsAndViewState() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'status'),
    ],

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
  dataSet.edit();
  dataSet.setFieldValue('status', 'inactive');
  dataSet.post();

  expect(dataSet.recordCount, 1);
  dataSet.close();

  expect(dataSet.state, FdcDataSetState.closed);
  expect(dataSet.recordCount, 0);
  expect(FdcDataSetInternal.activeIndex(dataSet), -1);
}
