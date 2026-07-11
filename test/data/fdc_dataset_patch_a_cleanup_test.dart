import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  await _testHasUpdatesIgnoresNonPersistentModifiedFields();
  await _testHasUpdatesSeesPersistentModifiedFields();
  await _testCloseClearsRecordsAndViewState();
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

  assert(!dataSet.hasUpdates);
  dataSet.edit();
  dataSet.setFieldValue('uiOnly', 'new');
  dataSet.post();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.changeSet.isEmpty);
  assert(!dataSet.hasUpdates);
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

  assert(dataSet.state == FdcDataSetState.browse);
  assert(!dataSet.changeSet.isEmpty);
  assert(dataSet.hasUpdates);
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

  assert(dataSet.recordCount == 1);
  dataSet.close();

  assert(dataSet.state == FdcDataSetState.closed);
  assert(dataSet.recordCount == 0);
  assert(FdcDataSetInternal.activeIndex(dataSet) == -1);
}
