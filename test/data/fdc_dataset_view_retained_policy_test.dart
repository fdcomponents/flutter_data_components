import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'clear sorts keeps retained inserted rows',
    _clearSortsKeepsRetainedInsertedRows,
  );
  test('clear filters clears retained rows', _clearFiltersClearsRetainedRows);
  test(
    'adapter open keeps active filter but clears retained rows',
    _adapterOpenKeepsActiveFilterButClearsRetainedRows,
  );
  test(
    'close then open does not leak retained rows',
    _closeThenOpenDoesNotLeakRetainedRows,
  );
  test(
    'delete retained inserted record leaves no stale view index',
    _deleteRetainedInsertedRecordLeavesNoStaleViewIndex,
  );
}

FdcDataSet _createDataSet({List<Map<String, Object?>>? rows}) {
  return FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'status'),
    ],
    adapter: FdcMemoryDataAdapter(rows: rows ?? const <Map<String, Object?>>[]),
  );
}

const _activeFilter = <FdcDataSetFilter>[
  FdcDataSetFilter(
    fieldName: 'status',
    operator: FdcFilterOperator.equals,
    value: 'active',
  ),
];

void _replaceAdapterRows(FdcDataSet dataSet, List<Map<String, Object?>> rows) {
  (dataSet.adapter as FdcMemoryDataAdapter).replaceRows(rows);
}

Future<void> _seedActiveRows(FdcDataSet dataSet) async {
  _replaceAdapterRows(dataSet, const <Map<String, Object?>>[
    {'name': 'Bravo', 'status': 'active'},
    {'name': 'Charlie', 'status': 'active'},
  ]);
  await dataSet.open();
}

void _appendDraftRow(FdcDataSet dataSet, String name) {
  dataSet.append();
  dataSet.setFieldValue('name', name);
  dataSet.setFieldValue('status', 'draft');
  dataSet.post();
}

Future<void> _clearSortsKeepsRetainedInsertedRows() async {
  final dataSet = _createDataSet();
  await _seedActiveRows(dataSet);
  await dataSet.filter.set(_activeFilter);
  _appendDraftRow(dataSet, 'Aardvark');

  await dataSet.sort.set(const <FdcDataSetSort>[
    FdcDataSetSort(fieldName: 'name'),
  ]);
  expect(dataSet.recordCount, 3);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Aardvark');

  await dataSet.sort.clear();

  expect(dataSet.recordCount, 3);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 2, 'name'), 'Aardvark');
}

Future<void> _clearFiltersClearsRetainedRows() async {
  final dataSet = _createDataSet();
  await _seedActiveRows(dataSet);
  await dataSet.filter.set(_activeFilter);
  _appendDraftRow(dataSet, 'Draft');

  expect(dataSet.recordCount, 3);

  await dataSet.filter.clear();
  expect(dataSet.recordCount, 3);

  // Re-apply the same filter without explicitly clearing retained rows. If
  // clearFilters did not clear retained state, this would keep Draft visible.
  FdcDataSetInternal.setViewState(
    dataSet,
    filters: _activeFilter,
    clearRetainedVisibleRecords: false,
  );

  expect(dataSet.recordCount, 2);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Bravo');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name'), 'Charlie');
}

Future<void> _adapterOpenKeepsActiveFilterButClearsRetainedRows() async {
  final dataSet = _createDataSet();
  await _seedActiveRows(dataSet);
  await dataSet.filter.set(_activeFilter);
  _appendDraftRow(dataSet, 'OldDraft');

  expect(dataSet.recordCount, 3);

  _replaceAdapterRows(dataSet, const <Map<String, Object?>>[
    {'name': 'NewDraft', 'status': 'draft'},
    {'name': 'NewActive', 'status': 'active'},
  ]);
  await dataSet.open();

  expect(dataSet.recordCount, 1);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'NewActive');

  // A sort-only view refresh must not resurrect any retained row from before
  // adapter open replaced storage.
  await dataSet.sort.set(const <FdcDataSetSort>[
    FdcDataSetSort(fieldName: 'name'),
  ]);

  expect(dataSet.recordCount, 1);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'NewActive');
}

Future<void> _closeThenOpenDoesNotLeakRetainedRows() async {
  final dataSet = _createDataSet();
  await _seedActiveRows(dataSet);
  await dataSet.filter.set(_activeFilter);
  _appendDraftRow(dataSet, 'OldDraft');

  expect(dataSet.recordCount, 3);

  dataSet.close();
  expect(dataSet.filter.active, false);

  _replaceAdapterRows(dataSet, const <Map<String, Object?>>[
    {'name': 'ReloadDraft', 'status': 'draft'},
    {'name': 'ReloadActive', 'status': 'active'},
  ]);
  await dataSet.open();

  expect(dataSet.recordCount, 2);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'ReloadDraft');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name'), 'ReloadActive');
}

Future<void> _deleteRetainedInsertedRecordLeavesNoStaleViewIndex() async {
  final dataSet = _createDataSet();
  await _seedActiveRows(dataSet);
  await dataSet.filter.set(_activeFilter);
  _appendDraftRow(dataSet, 'Draft');

  expect(dataSet.recordCount, 3);
  expect(dataSet.fieldValue('name'), 'Draft');

  dataSet.delete();

  expect(dataSet.recordCount, 2);

  // Force multiple view rebuilds. Any stale retained id/raw index would show up
  // either as a wrong row count, wrong value, or RangeError from valueAt.
  await dataSet.sort.set(const <FdcDataSetSort>[
    FdcDataSetSort(fieldName: 'name'),
  ]);
  await dataSet.sort.clear();
  FdcDataSetInternal.setViewState(
    dataSet,
    sorts: const <FdcDataSetSort>[FdcDataSetSort(fieldName: 'name')],
  );

  expect(dataSet.recordCount, 2);
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Bravo');
  expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name'), 'Charlie');
}
