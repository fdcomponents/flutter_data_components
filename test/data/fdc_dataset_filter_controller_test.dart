// This test intentionally verifies synchronous state transitions immediately
// after starting Future-returning dataset operations.
// ignore_for_file: discarded_futures

import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  _testFluentFilterRebuildsSingleDataSetView();
  _testFilterChangeCancelsPendingEdit();
  _testFilterChangeCancelsPendingInsert();
  await _testBeforePostAbortKeepsPreviousFilter();
  _testLegacyFilterApiDelegatesToFilterController();
  _testUnknownFilterFieldThrows();
  _testNullFilterOperatorsWorkForAllFieldTypes();
  _testEmptyFilterOperatorsAreStringOnly();
  _testWhitespaceFilterOperatorsAreStringOnly();
  _testFilterAndSortResetToFirstVisibleRecord();
  _testDatasetFilteredAndSortedInvariants();
  _testDatasetFilteredIncludesSelectedFilterContext();
  _testFilterBuilderExposesFieldItemsAndSelectedFilterSeparately();
  _testFilterContextCopyWithCanClearSelected();
}

void _testFluentFilterRebuildsSingleDataSetView() {
  final dataSet = _createDataSet(
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active', 'amount': 10},
        {'name': 'Beta', 'status': 'inactive', 'amount': 20},
        {'name': 'Gamma', 'status': 'active', 'amount': 30},
      ],
    ),
  );
  dataSet.open();

  dataSet.filter
      .where('status')
      .equals('active')
      .and('amount')
      .greaterThan(10)
      .apply();

  assert(dataSet.filter.fieldItems.length == 2);
  assert(dataSet.filter.items.length == 2);
  assert(dataSet.recordCount == 1);
  assert(dataSet.fieldValue('name') == 'Gamma');

  dataSet.filter.clear();

  assert(dataSet.filter.isEmpty);
  assert(dataSet.recordCount == 3);
}

void _testFilterChangeCancelsPendingEdit() {
  final events = <String>[];
  final dataSet = _createDataSet(
    beforePost: (_) => events.add('beforePost'),
    afterPost: (_) => events.add('afterPost'),

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active', 'amount': 10},
        {'name': 'Beta', 'status': 'inactive', 'amount': 20},
      ],
    ),
  );
  dataSet.open();

  dataSet.edit();
  dataSet.setFieldValue('name', 'Changed');

  dataSet.filter.where('status').equals('inactive').apply();

  assert(events.length == 2);
  assert(events[0] == 'beforePost');
  assert(events[1] == 'afterPost');
  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 1);
  assert(dataSet.fieldValue('name') == 'Beta');

  dataSet.filter.clear();
  dataSet.first();
  assert(dataSet.fieldValue('name') == 'Changed');
}

void _testFilterChangeCancelsPendingInsert() {
  final dataSet = _createDataSet(
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active', 'amount': 10},
      ],
    ),
  );
  dataSet.open();

  dataSet.append();
  dataSet.setFieldValue('name', 'New row');
  dataSet.setFieldValue('status', 'draft');
  assert(dataSet.state == FdcDataSetState.insert);
  assert(dataSet.recordCount == 2);

  dataSet.filter.where('status').equals('active').apply();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 1);
  assert(FdcDataSetInternal.activeIndex(dataSet) == 0);
  assert(dataSet.fieldValue('name') == 'Alpha');
}

Future<void> _testBeforePostAbortKeepsPreviousFilter() async {
  final dataSet = _createDataSet(
    beforePost: (_) => throw const FdcDataSetAbortException.silent(),

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active', 'amount': 10},
        {'name': 'Beta', 'status': 'inactive', 'amount': 20},
      ],
    ),
  );
  dataSet.open();

  dataSet.filter.where('status').equals('active').apply();
  assert(dataSet.recordCount == 1);
  assert(dataSet.fieldValue('name') == 'Alpha');

  dataSet.edit();
  dataSet.setFieldValue('name', 'Changed');

  final changed = await dataSet.filter
      .where('status')
      .equals('inactive')
      .apply();

  assert(changed == false);
  assert(dataSet.state == FdcDataSetState.edit);
  assert(dataSet.filter.fieldItems.single.value == 'active');
  assert(dataSet.recordCount == 1);
  assert(dataSet.fieldValue('name') == 'Changed');
}

void _testLegacyFilterApiDelegatesToFilterController() {
  final dataSet = _createDataSet(
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active', 'amount': 10},
        {'name': 'Beta', 'status': 'inactive', 'amount': 20},
      ],
    ),
  );
  dataSet.open();

  dataSet.filter.set(const <FdcDataSetFilter>[
    FdcDataSetFilter(
      fieldName: 'status',
      operator: FdcFilterOperator.equals,
      value: 'active',
    ),
  ]);

  assert(dataSet.filter.fieldItems.length == 1);
  assert(dataSet.recordCount == 1);
  assert(dataSet.fieldValue('name') == 'Alpha');

  dataSet.filter.clear();

  assert(dataSet.filter.isEmpty);
  assert(dataSet.recordCount == 2);
}

void _testUnknownFilterFieldThrows() {
  final dataSet = _createDataSet(
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active', 'amount': 10},
      ],
    ),
  );
  dataSet.open();

  Object? error;
  try {
    dataSet.filter.where('name222').endsWith('c').apply();
  } on Object catch (e) {
    error = e;
  }

  assert(error is FdcDataSetException);
  assert(
    error.toString().contains(
      'Unknown filter field "name222" in dataset FdcDataSet.',
    ),
  );
  assert(dataSet.filter.isEmpty);
  assert(dataSet.recordCount == 1);
}

void _testNullFilterOperatorsWorkForAllFieldTypes() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcIntegerField(name: 'amount'),
      FdcBooleanField(name: 'active'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': null, 'amount': null, 'active': null},
        {'name': 'Beta', 'amount': 20, 'active': true},
        {'name': 'Gamma', 'amount': null, 'active': false},
      ],
    ),
  );
  dataSet.open();

  dataSet.filter.where('amount').isNull().apply();
  assert(dataSet.recordCount == 2);

  dataSet.filter.where('active').isNotNull().apply();
  assert(dataSet.recordCount == 2);

  dataSet.filter.where('name').isNull().apply();
  assert(dataSet.recordCount == 1);
  assert(dataSet.fieldValue('amount') == null);
}

void _testEmptyFilterOperatorsAreStringOnly() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcIntegerField(name: 'amount'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': null, 'amount': 1},
        {'name': '', 'amount': 2},
        {'name': '   ', 'amount': 3},
        {'name': 'Alpha', 'amount': 4},
      ],
    ),
  );
  dataSet.open();

  dataSet.filter.where('name').isEmpty().apply();
  assert(dataSet.recordCount == 2);

  dataSet.filter.where('name').isNotEmpty().apply();
  assert(dataSet.recordCount == 2);

  Object? error;
  try {
    dataSet.filter.where('amount').isEmpty().apply();
  } on Object catch (e) {
    error = e;
  }

  assert(error is FdcDataSetException);
  assert(
    error.toString().contains(
      'Filter operator isEmpty can only be used with string fields. Field "amount" is integer.',
    ),
  );
}

void _testWhitespaceFilterOperatorsAreStringOnly() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcIntegerField(name: 'amount'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': null, 'amount': 1},
        {'name': '', 'amount': 2},
        {'name': '   ', 'amount': 3},
        {'name': 'Alpha', 'amount': 4},
      ],
    ),
  );
  dataSet.open();

  dataSet.filter.where('name').isNullOrWhitespace().apply();
  assert(dataSet.recordCount == 3);

  dataSet.filter.where('name').isNotNullOrWhitespace().apply();
  assert(dataSet.recordCount == 1);
  assert(dataSet.fieldValue('name') == 'Alpha');

  Object? error;
  try {
    dataSet.filter.where('amount').isNullOrWhitespace().apply();
  } on Object catch (e) {
    error = e;
  }

  assert(error is FdcDataSetException);
  assert(
    error.toString().contains(
      'Filter operator isNullOrWhitespace can only be used with string fields. Field "amount" is integer.',
    ),
  );
}

FdcDataSet _createDataSet({
  IFdcDataAdapter? adapter,
  FdcDataSetBeforeCancel? beforeCancel,
  FdcDataSetAfterCancel? afterCancel,
  FdcDataSetBeforePost? beforePost,
  FdcDataSetAfterPost? afterPost,
}) {
  return FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'status'),
      FdcIntegerField(name: 'amount'),
    ],
    beforeCancel: beforeCancel,
    afterCancel: afterCancel,
    beforePost: beforePost,
    afterPost: afterPost,

    adapter:
        adapter ?? FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );
}

void _testFilterAndSortResetToFirstVisibleRecord() {
  final dataSet = _createDataSet(
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Charlie', 'status': 'active', 'amount': 30},
        {'name': 'Alpha', 'status': 'active', 'amount': 10},
        {'name': 'Bravo', 'status': 'inactive', 'amount': 20},
      ],
    ),
  );
  dataSet.open();

  dataSet.last();
  assert(dataSet.fieldValue('name') == 'Bravo');

  dataSet.filter.where('status').equals('active').apply();

  assert(FdcDataSetInternal.activeIndex(dataSet) == 0);
  assert(dataSet.fieldValue('name') == 'Charlie');

  dataSet.last();
  assert(dataSet.fieldValue('name') == 'Alpha');

  dataSet.sort.set(const <FdcDataSetSort>[FdcDataSetSort(fieldName: 'name')]);

  assert(FdcDataSetInternal.activeIndex(dataSet) == 0);
  assert(dataSet.fieldValue('name') == 'Alpha');
}

void _testDatasetFilteredIncludesSelectedFilterContext() {
  final dataSet = _createDataSet(
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active', 'amount': 10},
        {'name': 'Bravo', 'status': 'inactive', 'amount': 20},
      ],
    ),
  );
  dataSet.open();

  dataSet.selection.setSelectedAt(0, true);

  assert(!dataSet.filter.active);
  assert(!dataSet.filter.active);

  dataSet.filter.selected(true).apply();

  assert(dataSet.filter.fieldItems.isEmpty);
  assert(dataSet.filter.selectedFilter == true);
  assert(dataSet.filter.context.selected == true);
  assert(dataSet.filter.active);
  assert(dataSet.filter.active);
  assert(dataSet.recordCount == 1);
  assert(dataSet.fieldValue('name') == 'Alpha');

  dataSet.filter.clear();

  assert(dataSet.filter.fieldItems.isEmpty);
  assert(dataSet.filter.selectedFilter == null);
  assert(dataSet.filter.context.selected == null);
  assert(!dataSet.filter.active);
  assert(!dataSet.filter.active);
  assert(dataSet.recordCount == 2);
}

void _testFilterBuilderExposesFieldItemsAndSelectedFilterSeparately() {
  final dataSet = _createDataSet(
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha', 'status': 'active', 'amount': 10},
        {'name': 'Bravo', 'status': 'inactive', 'amount': 20},
      ],
    ),
  );
  dataSet.open();

  final builder = dataSet.filter.selected(true);

  assert(builder.fieldItems.isEmpty);
  assert(builder.selectedFilter == true);
  assert(builder.context.selected == true);

  final updatedBuilder = builder.where('status').equals('active');

  assert(identical(updatedBuilder, builder));
  assert(builder.fieldItems.length == 1);
  assert(builder.fieldItems.single.fieldName == 'status');
  assert(builder.selectedFilter == true);
}

void _testFilterContextCopyWithCanClearSelected() {
  const base = FdcDataSetFilterContext(selected: true);

  final retained = base.copyWith();
  assert(retained.selected == true);

  final cleared = base.copyWith(selected: null);
  assert(cleared.selected == null);

  final changed = base.copyWith(selected: false);
  assert(changed.selected == false);

  Object? error;
  try {
    base.copyWith(selected: 'invalid');
  } on Object catch (e) {
    error = e;
  }
  assert(error is ArgumentError);
}

void _testDatasetFilteredAndSortedInvariants() {
  final dataSet = _createDataSet(
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Charlie', 'status': 'active', 'amount': 30},
        {'name': 'Alpha', 'status': 'active', 'amount': 10},
        {'name': 'Bravo', 'status': 'inactive', 'amount': 20},
      ],
    ),
  );
  dataSet.open();

  assert(!dataSet.filter.active);
  assert(!dataSet.sort.active);
  assert(!dataSet.filter.active);
  assert(!dataSet.sort.active);

  dataSet.filter.where('status').equals('active').apply();

  assert(dataSet.filter.active);
  assert(dataSet.filter.active);
  assert(!dataSet.sort.active);

  dataSet.sort.set(const <FdcDataSetSort>[FdcDataSetSort(fieldName: 'name')]);

  assert(dataSet.filter.active);
  assert(dataSet.sort.active);
  assert(dataSet.sort.active);

  dataSet.filter.clear();

  assert(!dataSet.filter.active);
  assert(dataSet.sort.active);

  dataSet.sort.clear();

  assert(!dataSet.filter.active);
  assert(!dataSet.sort.active);
}
