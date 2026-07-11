import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  await _internalSetViewStateSortOnlyKeepsRetainedInsertedRows();
  await _internalSetViewStateFilterAndSortClearsRetainedRowsByDefault();
  await _cancelUpdatesAbortDoesNotBumpDataRevision();
  await _sortDefaultsToAscending();
  await _sortByApiSortsAndToggleSortByFlipsDirection();
  await _sortApiAlwaysMovesToFirstVisibleRecord();
  await _sortControllerFluentApiSupportsMultiSort();
  await _sortControllerDoesNotApplyUntilApplyIsCalled();
  await _cancelUpdatesNoUpdatesDoesNotBumpDataRevision();
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

  assert(dataSet.recordCount == 3);

  FdcDataSetInternal.setViewState(
    dataSet,
    sorts: const <FdcDataSetSort>[FdcDataSetSort(fieldName: 'name')],
  );

  assert(dataSet.recordCount == 3);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Aardvark');
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

  assert(dataSet.recordCount == 3);

  FdcDataSetInternal.setViewState(
    dataSet,
    filters: activeFilter,
    sorts: const <FdcDataSetSort>[FdcDataSetSort(fieldName: 'name')],
  );

  assert(dataSet.recordCount == 2);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Bravo');
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

  assert(notifyCount == 0);
  assert(dataSet.state == FdcDataSetState.edit);
  assert(dataSet.fieldValue('name') == 'Changed');
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

  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Alpha');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name') == 'Bravo');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 2, 'name') == 'Charlie');
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

  assert(dataSet.sort.items.length == 1);
  assert(dataSet.sort.items.single.fieldName == 'name');
  assert(dataSet.sort.items.single.sortType.isAscending);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Alpha');

  await dataSet.sort.toggleBy('NAME');

  assert(dataSet.sort.items.length == 1);
  assert(!dataSet.sort.items.single.sortType.isAscending);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Charlie');

  await dataSet.sort.clear();

  assert(dataSet.sort.items.isEmpty);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Charlie');
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
  assert(dataSet.recordNumber == 3);

  await dataSet.sort.set(const <FdcDataSetSort>[
    FdcDataSetSort(fieldName: 'name'),
  ]);
  assert(dataSet.recordNumber == 1);
  assert(dataSet.fieldValue('name') == 'Alpha');

  dataSet.last();
  assert(dataSet.recordNumber == 3);

  await dataSet.sort.set(const <FdcDataSetSort>[
    FdcDataSetSort(fieldName: 'name'),
  ]);
  assert(dataSet.recordNumber == 1);
  assert(dataSet.fieldValue('name') == 'Alpha');

  dataSet.last();
  assert(dataSet.recordNumber == 3);

  await dataSet.sort.clear();
  assert(dataSet.recordNumber == 1);
  assert(dataSet.fieldValue('name') == 'Charlie');

  dataSet.last();
  assert(dataSet.recordNumber == 3);

  await dataSet.sort.clear();
  assert(dataSet.recordNumber == 1);
  assert(dataSet.fieldValue('name') == 'Charlie');
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

  assert(dataSet.sort.items.length == 2);
  assert(dataSet.sort.items.length == 2);
  assert(dataSet.sort.items.first.fieldName == 'group');
  assert(dataSet.sort.items.first.sortType == FdcSortType.ascending);
  assert(dataSet.sort.items.last.fieldName == 'name');
  assert(dataSet.sort.items.last.sortType == FdcSortType.descending);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'group') == 'A');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Charlie');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'group') == 'A');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name') == 'Bravo');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 2, 'group') == 'B');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 2, 'name') == 'Delta');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 3, 'group') == 'B');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 3, 'name') == 'Alpha');
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

  assert(dataSet.sort.items.isEmpty);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Charlie');

  await pendingSort.apply();

  assert(dataSet.sort.items.length == 1);
  assert(dataSet.sort.items.single.fieldName == 'name');
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Alpha');
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

  assert(notifyCount == 0);
  assert(!dataSet.hasUpdates);
  assert(dataSet.recordCount == 1);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Alpha');
}
