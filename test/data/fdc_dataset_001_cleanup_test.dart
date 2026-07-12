import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'set view state sort only keeps retained inserted rows',
    _internalSetViewStateSortOnlyKeepsRetainedInsertedRows,
  );
  test(
    'set view state filter and sort clears retained rows by default',
    _internalSetViewStateFilterAndSortClearsRetainedRowsByDefault,
  );
  test(
    'cancel updates abort does not bump data revision',
    _cancelUpdatesAbortDoesNotBumpDataRevision,
  );
  test('sort defaults to ascending', _sortDefaultsToAscending);
  test(
    'sort by api sorts and toggle sort by flips direction',
    _sortByApiSortsAndToggleSortByFlipsDirection,
  );
  test(
    'sort api always moves to first visible record',
    _sortApiAlwaysMovesToFirstVisibleRecord,
  );
  test(
    'sort controller fluent api supports multi sort',
    _sortControllerFluentApiSupportsMultiSort,
  );
  test(
    'sort controller does not apply until apply is called',
    _sortControllerDoesNotApplyUntilApplyIsCalled,
  );
  test(
    'cancel updates no updates does not bump data revision',
    _cancelUpdatesNoUpdatesDoesNotBumpDataRevision,
  );
}

Future<void> _internalSetViewStateSortOnlyKeepsRetainedInsertedRows() async {
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

  expect(dataSet.recordCount, 3);

  FdcDataSetInternal.setViewState(
    dataSet,
    sorts: const <FdcDataSetSort>[FdcDataSetSort(fieldName: 'name')],
  );

  expect(dataSet.recordCount, 3);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Aardvark');
}

Future<void>
_internalSetViewStateFilterAndSortClearsRetainedRowsByDefault() async {
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

  expect(dataSet.recordCount, 3);

  FdcDataSetInternal.setViewState(
    dataSet,
    filters: activeFilter,
    sorts: const <FdcDataSetSort>[FdcDataSetSort(fieldName: 'name')],
  );

  expect(dataSet.recordCount, 2);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Bravo');
}

Future<void> _cancelUpdatesAbortDoesNotBumpDataRevision() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
    beforeCancel: (_) {
      throw const FdcDataSetAbortException.silent();
    },

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();
  dataSet.edit();
  dataSet.setFieldValue('name', 'Changed');

  var notifyCount = 0;
  dataSet.addListener(() {
    notifyCount++;
  });

  dataSet.cancelUpdates();

  expect(notifyCount, 0);
  expect(dataSet.state, FdcDataSetState.edit);
  expect(dataSet.fieldValue('name'), 'Changed');
}

Future<void> _sortDefaultsToAscending() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Charlie'},
        {'name': 'Bravo'},
        {'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  await dataSet.sort.set(const <FdcDataSetSort>[
    FdcDataSetSort(fieldName: 'name'),
  ]);

  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Alpha');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name'), 'Bravo');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 2, 'name'), 'Charlie');
}

Future<void> _sortByApiSortsAndToggleSortByFlipsDirection() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Charlie'},
        {'name': 'Bravo'},
        {'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  await dataSet.sort.sortBy('name').ascending.apply();

  expect(dataSet.sort.items.length, 1);
  expect(dataSet.sort.items.single.fieldName, 'name');
  expect(dataSet.sort.items.single.sortType.isAscending, isTrue);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Alpha');

  await dataSet.sort.toggleBy('NAME');

  expect(dataSet.sort.items.length, 1);
  expect(dataSet.sort.items.single.sortType.isAscending, isFalse);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Charlie');

  await dataSet.sort.clear();

  expect(dataSet.sort.items, isEmpty);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Charlie');
}

Future<void> _sortApiAlwaysMovesToFirstVisibleRecord() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Charlie'},
        {'name': 'Bravo'},
        {'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.last();
  expect(dataSet.recordNumber, 3);

  await dataSet.sort.set(const <FdcDataSetSort>[
    FdcDataSetSort(fieldName: 'name'),
  ]);
  expect(dataSet.recordNumber, 1);
  expect(dataSet.fieldValue('name'), 'Alpha');

  dataSet.last();
  expect(dataSet.recordNumber, 3);

  await dataSet.sort.set(const <FdcDataSetSort>[
    FdcDataSetSort(fieldName: 'name'),
  ]);
  expect(dataSet.recordNumber, 1);
  expect(dataSet.fieldValue('name'), 'Alpha');

  dataSet.last();
  expect(dataSet.recordNumber, 3);

  await dataSet.sort.clear();
  expect(dataSet.recordNumber, 1);
  expect(dataSet.fieldValue('name'), 'Charlie');

  dataSet.last();
  expect(dataSet.recordNumber, 3);

  await dataSet.sort.clear();
  expect(dataSet.recordNumber, 1);
  expect(dataSet.fieldValue('name'), 'Charlie');
}

Future<void> _sortControllerFluentApiSupportsMultiSort() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'group'),
      FdcStringField(size: 255, name: 'name'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'group': 'B', 'name': 'Alpha'},
        {'group': 'A', 'name': 'Charlie'},
        {'group': 'A', 'name': 'Bravo'},
        {'group': 'B', 'name': 'Delta'},
      ],
    ),
  );

  await dataSet.open();

  await dataSet.sort
      .sortBy('group')
      .ascending
      .sortBy('name')
      .descending
      .apply();

  expect(dataSet.sort.items.length, 2);
  expect(dataSet.sort.items.length, 2);
  expect(dataSet.sort.items.first.fieldName, 'group');
  expect(dataSet.sort.items.first.sortType, FdcSortType.ascending);
  expect(dataSet.sort.items.last.fieldName, 'name');
  expect(dataSet.sort.items.last.sortType, FdcSortType.descending);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'group'), 'A');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Charlie');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'group'), 'A');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name'), 'Bravo');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 2, 'group'), 'B');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 2, 'name'), 'Delta');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 3, 'group'), 'B');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 3, 'name'), 'Alpha');
}

Future<void> _sortControllerDoesNotApplyUntilApplyIsCalled() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Charlie'},
        {'name': 'Bravo'},
        {'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  final pendingSort = dataSet.sort.sortBy('name').ascending;

  expect(dataSet.sort.items, isEmpty);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Charlie');

  await pendingSort.apply();

  expect(dataSet.sort.items.length, 1);
  expect(dataSet.sort.items.single.fieldName, 'name');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Alpha');
}

Future<void> _cancelUpdatesNoUpdatesDoesNotBumpDataRevision() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  var notifyCount = 0;
  dataSet.addListener(() {
    notifyCount++;
  });

  dataSet.cancelUpdates();

  expect(notifyCount, 0);
  expect(dataSet.hasUpdates, isFalse);
  expect(dataSet.recordCount, 1);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Alpha');
}
