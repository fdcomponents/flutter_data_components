import 'dart:async';

import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  await _testMoveToKeepsActiveInsertWhenPostValidationFails();
  await _testCleanInsertIsCanceledBeforeNavigation();
  await _testDirtyEditIsPostedBeforeNavigation();
  await _testDirtyEditBlocksSortWhenPostFails();
  await _testCleanInsertIsCanceledBeforeSort();
  await _testCancelInsertedRecordSelectsNearestRemainingRow();
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

  try {
    dataSet.moveToRecord(2);
    assert(
      false,
      'moveToRecord must not succeed when active insert cannot post.',
    );
  } on FdcDataSetValidationException {
    // Expected.
  }

  assert(dataSet.state == FdcDataSetState.insert);
  assert(FdcDataSetInternal.activeIndex(dataSet) == insertIndex);
  assert(dataSet.recordCount == 3);
  assert(dataSet.fieldValue('name') == 'Invalid draft');
  assert(dataSet.errors.messages.isNotEmpty);
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
  assert(dataSet.state == FdcDataSetState.insert);

  dataSet.first();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 2);
  assert(dataSet.recordNumber == 1);
  assert(dataSet.fieldValue('name') == 'Alpha');
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

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordNumber == 2);
  dataSet.first();
  assert(dataSet.fieldValue('name') == 'Alpha edited');
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

  assert(!sorted);
  assert(dataSet.state == FdcDataSetState.edit);
  assert(dataSet.recordNumber == 1);
  assert(dataSet.fieldValue('name') == 'Blocked edit');
  assert(dataSet.sort.items.isEmpty);
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
  assert(dataSet.state == FdcDataSetState.insert);

  final sorted = await Future<bool>.value(
    dataSet.sort.sortBy('id').ascending.apply(),
  );

  assert(sorted);
  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 2);
  assert(dataSet.recordNumber == 1);
  assert(dataSet.fieldValue('name') == 'Alpha');
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

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 2);
  assert(FdcDataSetInternal.activeIndex(dataSet) == 1);
  assert(dataSet.fieldValue('name') == 'Gamma');
}
