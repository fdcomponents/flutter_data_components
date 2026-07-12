import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'move to keeps active insert when post validation fails',
    _testMoveToKeepsActiveInsertWhenPostValidationFails,
  );
  test(
    'clean insert is canceled before navigation',
    _testCleanInsertIsCanceledBeforeNavigation,
  );
  test(
    'dirty edit is posted before navigation',
    _testDirtyEditIsPostedBeforeNavigation,
  );
  test(
    'dirty edit blocks sort when post fails',
    _testDirtyEditBlocksSortWhenPostFails,
  );
  test(
    'clean insert is canceled before sort',
    _testCleanInsertIsCanceledBeforeSort,
  );
  test(
    'cancel inserted record selects nearest remaining row',
    _testCancelInsertedRecordSelectsNearestRemainingRow,
  );
}

Future<void> _testMoveToKeepsActiveInsertWhenPostValidationFails() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id', required: true),
      FdcStringField(size: 255, name: 'name'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha'},
        {'id': 2, 'name': 'Bravo'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();
  dataSet.setFieldValue('name', 'Invalid draft');
  final insertIndex = FdcDataSetInternal.activeIndex(dataSet);

  expect(
    () => dataSet.moveToRecord(2),
    throwsA(isA<FdcDataSetValidationException>()),
    reason: 'Navigation must not discard an insert that fails validation.',
  );

  expect(dataSet.state, FdcDataSetState.insert);
  expect(FdcDataSetInternal.activeIndex(dataSet), insertIndex);
  expect(dataSet.recordCount, 3);
  expect(dataSet.fieldValue('name'), 'Invalid draft');
  expect(dataSet.errors.message, isNotEmpty);
}

Future<void> _testCleanInsertIsCanceledBeforeNavigation() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha'},
        {'id': 2, 'name': 'Bravo'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();
  expect(dataSet.state, FdcDataSetState.insert);

  dataSet.first();

  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.recordCount, 2);
  expect(dataSet.recordNumber, 1);
  expect(dataSet.fieldValue('name'), 'Alpha');
}

Future<void> _testDirtyEditIsPostedBeforeNavigation() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha'},
        {'id': 2, 'name': 'Bravo'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.edit();
  dataSet.setFieldValue('name', 'Alpha edited');

  dataSet.next();

  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.recordNumber, 2);
  dataSet.first();
  expect(dataSet.fieldValue('name'), 'Alpha edited');
}

Future<void> _testDirtyEditBlocksSortWhenPostFails() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforePost: (_) => throw const FdcDataSetAbortException.silent(),

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 2, 'name': 'Bravo'},
        {'id': 1, 'name': 'Alpha'},
      ],
    ),
  );

  dataSet.open();

  dataSet.edit();
  dataSet.setFieldValue('name', 'Blocked edit');

  final sorted = await Future<bool>.value(
    dataSet.sort.sortBy('id').ascending.apply(),
  );

  expect(sorted, isFalse);
  expect(dataSet.state, FdcDataSetState.edit);
  expect(dataSet.recordNumber, 1);
  expect(dataSet.fieldValue('name'), 'Blocked edit');
  expect(dataSet.sort.items, isEmpty);
}

Future<void> _testCleanInsertIsCanceledBeforeSort() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 2, 'name': 'Bravo'},
        {'id': 1, 'name': 'Alpha'},
      ],
    ),
  );

  dataSet.open();

  dataSet.append();
  expect(dataSet.state, FdcDataSetState.insert);

  final sorted = await Future<bool>.value(
    dataSet.sort.sortBy('id').ascending.apply(),
  );

  expect(sorted, isTrue);
  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.recordCount, 2);
  expect(dataSet.recordNumber, 1);
  expect(dataSet.fieldValue('name'), 'Alpha');
}

Future<void> _testCancelInsertedRecordSelectsNearestRemainingRow() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha'},
        {'id': 3, 'name': 'Gamma'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.moveToRecord(2);
  dataSet.insert();
  dataSet.setFieldValue('id', 2);
  dataSet.setFieldValue('name', 'Draft');

  dataSet.cancel();

  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.recordCount, 2);
  expect(FdcDataSetInternal.activeIndex(dataSet), 1);
  expect(dataSet.fieldValue('name'), 'Gamma');
}
