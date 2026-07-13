// This test intentionally verifies synchronous state transitions immediately
// after starting Future-returning dataset operations.
// ignore_for_file: discarded_futures

import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'fluent filter rebuilds single data set view',
    _testFluentFilterRebuildsSingleDataSetView,
  );
  test(
    'filter change cancels pending edit',
    _testFilterChangeCancelsPendingEdit,
  );
  test(
    'filter change cancels pending insert',
    _testFilterChangeCancelsPendingInsert,
  );
  test(
    'before post abort keeps previous filter',
    _testBeforePostAbortKeepsPreviousFilter,
  );
  test(
    'legacy filter api delegates to filter controller',
    _testLegacyFilterApiDelegatesToFilterController,
  );
  test('unknown filter field throws', _testUnknownFilterFieldThrows);
  test(
    'null filter operators work for all field types',
    _testNullFilterOperatorsWorkForAllFieldTypes,
  );
  test(
    'empty filter operators are string only',
    _testEmptyFilterOperatorsAreStringOnly,
  );
  test(
    'whitespace filter operators are string only',
    _testWhitespaceFilterOperatorsAreStringOnly,
  );
  test(
    'filter and sort reset to first visible record',
    _testFilterAndSortResetToFirstVisibleRecord,
  );
  test(
    'dataset filtered and sorted invariants',
    _testDatasetFilteredAndSortedInvariants,
  );
  test(
    'dataset filtered includes selected filter context',
    _testDatasetFilteredIncludesSelectedFilterContext,
  );
  test(
    'filter builder exposes field items and selected filter separately',
    _testFilterBuilderExposesFieldItemsAndSelectedFilterSeparately,
  );
  test(
    'filter context copy with can clear selected',
    _testFilterContextCopyWithCanClearSelected,
  );
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

  expect(dataSet.filter.fieldItems.length, 2);
  expect(dataSet.filter.items.length, 2);
  expect(dataSet.recordCount, 1);
  expect(dataSet.fieldValue('name'), 'Gamma');

  dataSet.filter.clear();

  expect(dataSet.filter, isEmpty);
  expect(dataSet.recordCount, 3);
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

  expect(
    events,
    <String>['beforePost', 'afterPost'],
    reason:
        'Applying a filter while editing must post exactly once before '
        'rebuilding the filtered view.',
  );
  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.recordCount, 1);
  expect(dataSet.fieldValue('name'), 'Beta');

  dataSet.filter.clear();
  dataSet.first();
  expect(dataSet.fieldValue('name'), 'Changed');
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
  expect(dataSet.state, FdcDataSetState.insert);
  expect(dataSet.recordCount, 2);

  dataSet.filter.where('status').equals('active').apply();

  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.recordCount, 1);
  expect(FdcDataSetInternal.activeIndex(dataSet), 0);
  expect(dataSet.fieldValue('name'), 'Alpha');
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
  expect(dataSet.recordCount, 1);
  expect(dataSet.fieldValue('name'), 'Alpha');

  dataSet.edit();
  dataSet.setFieldValue('name', 'Changed');

  final changed = await dataSet.filter
      .where('status')
      .equals('inactive')
      .apply();

  expect(changed, false);
  expect(dataSet.state, FdcDataSetState.edit);
  expect(dataSet.filter.fieldItems.single.value, 'active');
  expect(dataSet.recordCount, 1);
  expect(dataSet.fieldValue('name'), 'Changed');
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

  expect(dataSet.filter.fieldItems.length, 1);
  expect(dataSet.recordCount, 1);
  expect(dataSet.fieldValue('name'), 'Alpha');

  dataSet.filter.clear();

  expect(dataSet.filter, isEmpty);
  expect(dataSet.recordCount, 2);
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

  expect(error is FdcDataSetException, isTrue);
  expect(
    error.toString(),
    contains('Unknown filter field "name222" in dataset FdcDataSet.'),
  );
  expect(dataSet.filter, isEmpty);
  expect(dataSet.recordCount, 1);
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
  expect(dataSet.recordCount, 2);

  dataSet.filter.where('active').isNotNull().apply();
  expect(dataSet.recordCount, 2);

  dataSet.filter.where('name').isNull().apply();
  expect(dataSet.recordCount, 1);
  expect(dataSet.fieldValue('amount'), null);
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
  expect(dataSet.recordCount, 2);

  dataSet.filter.where('name').isNotEmpty().apply();
  expect(dataSet.recordCount, 2);

  Object? error;
  try {
    dataSet.filter.where('amount').isEmpty().apply();
  } on Object catch (e) {
    error = e;
  }

  expect(error is FdcDataSetException, isTrue);
  expect(
    error.toString(),
    contains(
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
  expect(dataSet.recordCount, 3);

  dataSet.filter.where('name').isNotNullOrWhitespace().apply();
  expect(dataSet.recordCount, 1);
  expect(dataSet.fieldValue('name'), 'Alpha');

  Object? error;
  try {
    dataSet.filter.where('amount').isNullOrWhitespace().apply();
  } on Object catch (e) {
    error = e;
  }

  expect(error is FdcDataSetException, isTrue);
  expect(
    error.toString(),
    contains(
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
  expect(dataSet.fieldValue('name'), 'Bravo');

  dataSet.filter.where('status').equals('active').apply();

  expect(FdcDataSetInternal.activeIndex(dataSet), 0);
  expect(dataSet.fieldValue('name'), 'Charlie');

  dataSet.last();
  expect(dataSet.fieldValue('name'), 'Alpha');

  dataSet.sort.set(const <FdcDataSetSort>[FdcDataSetSort(fieldName: 'name')]);

  expect(FdcDataSetInternal.activeIndex(dataSet), 0);
  expect(dataSet.fieldValue('name'), 'Alpha');
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

  expect(dataSet.filter.active, isFalse);

  dataSet.filter.selected(true).apply();

  expect(dataSet.filter.fieldItems, isEmpty);
  expect(dataSet.filter.selectedFilter, true);
  expect(dataSet.filter.context.selected, true);
  expect(dataSet.filter.active, isTrue);
  expect(dataSet.recordCount, 1);
  expect(dataSet.fieldValue('name'), 'Alpha');

  dataSet.filter.clear();

  expect(dataSet.filter.fieldItems, isEmpty);
  expect(dataSet.filter.selectedFilter, null);
  expect(dataSet.filter.context.selected, null);
  expect(dataSet.filter.active, isFalse);
  expect(dataSet.recordCount, 2);
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

  expect(builder.fieldItems, isEmpty);
  expect(builder.selectedFilter, true);
  expect(builder.context.selected, true);

  final updatedBuilder = builder.where('status').equals('active');

  expect(identical(updatedBuilder, builder), isTrue);
  expect(builder.fieldItems.length, 1);
  expect(builder.fieldItems.single.fieldName, 'status');
  expect(builder.selectedFilter, true);
}

void _testFilterContextCopyWithCanClearSelected() {
  const base = FdcDataSetFilterContext(selected: true);

  final retained = base.copyWith();
  expect(retained.selected, true);

  final cleared = base.copyWith(selected: null);
  expect(cleared.selected, null);

  final changed = base.copyWith(selected: false);
  expect(changed.selected, false);

  Object? error;
  try {
    base.copyWith(selected: 'invalid');
  } on Object catch (e) {
    error = e;
  }
  expect(error is ArgumentError, isTrue);
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

  expect(dataSet.filter.active, isFalse);
  expect(dataSet.sort.active, isFalse);

  dataSet.filter.where('status').equals('active').apply();

  expect(dataSet.filter.active, isTrue);
  expect(dataSet.sort.active, isFalse);

  dataSet.sort.set(const <FdcDataSetSort>[FdcDataSetSort(fieldName: 'name')]);

  expect(dataSet.filter.active, isTrue);
  expect(dataSet.sort.active, isTrue);

  dataSet.filter.clear();

  expect(dataSet.filter.active, isFalse);
  expect(dataSet.sort.active, isTrue);

  dataSet.sort.clear();

  expect(dataSet.filter.active, isFalse);
  expect(dataSet.sort.active, isFalse);
}
