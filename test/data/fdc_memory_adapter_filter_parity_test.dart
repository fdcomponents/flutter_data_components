import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'paged memory adapter matches local case-sensitive text filters',
    () async {
      await _expectLocalAndPagedMemoryIds(
        (dataSet) => dataSet.filter
            .where('name')
            .contains('AN', caseSensitive: true)
            .apply(),
      );

      await _expectLocalAndPagedMemoryIds(
        (dataSet) => dataSet.filter.where('name').contains('an').apply(),
      );

      await _expectLocalAndPagedMemoryIds(
        (dataSet) => dataSet.filter
            .where('name')
            .startsWith('An', caseSensitive: true)
            .apply(),
      );

      await _expectLocalAndPagedMemoryIds(
        (dataSet) => dataSet.filter
            .where('name')
            .endsWith('AN', caseSensitive: true)
            .apply(),
      );
    },
  );

  test('paged memory adapter matches local list case semantics', () async {
    await _expectLocalAndPagedMemoryIds(
      (dataSet) => dataSet.filter.where('name').inList(const <Object?>[
        'alice',
        'AN',
      ]).apply(),
    );

    await _expectLocalAndPagedMemoryIds(
      (dataSet) => dataSet.filter.where('name').inList(const <Object?>[
        'alice',
        'AN',
      ], caseSensitive: true).apply(),
    );

    await _expectLocalAndPagedMemoryIds(
      (dataSet) => dataSet.filter.where('name').notInList(const <Object?>[
        'alice',
        'AN',
      ]).apply(),
    );
  });

  test(
    'paged memory adapter matches local null empty whitespace filters',
    () async {
      await _expectLocalAndPagedMemoryIds(
        (dataSet) => dataSet.filter.where('note').isNull().apply(),
      );

      await _expectLocalAndPagedMemoryIds(
        (dataSet) => dataSet.filter.where('note').isNotNull().apply(),
      );

      await _expectLocalAndPagedMemoryIds(
        (dataSet) => dataSet.filter.where('note').isEmpty().apply(),
      );

      await _expectLocalAndPagedMemoryIds(
        (dataSet) => dataSet.filter.where('note').isNotEmpty().apply(),
      );

      await _expectLocalAndPagedMemoryIds(
        (dataSet) => dataSet.filter.where('note').isNullOrWhitespace().apply(),
      );

      await _expectLocalAndPagedMemoryIds(
        (dataSet) =>
            dataSet.filter.where('note').isNotNullOrWhitespace().apply(),
      );
    },
  );
}

typedef _ApplyFilter = Future<bool> Function(FdcDataSet dataSet);

Future<void> _expectLocalAndPagedMemoryIds(_ApplyFilter applyFilter) async {
  final localIds = await _filteredLocalIds(applyFilter);
  final pagedMemoryIds = await _filteredPagedMemoryIds(applyFilter);

  expect(pagedMemoryIds, localIds);
}

Future<List<Object?>> _filteredLocalIds(_ApplyFilter applyFilter) async {
  final dataSet = FdcDataSet(fields: _fields);
  addTearDown(dataSet.dispose);
  dataSet.loadRows(_rows);

  await applyFilter(dataSet);

  return _ids(dataSet);
}

Future<List<Object?>> _filteredPagedMemoryIds(_ApplyFilter applyFilter) async {
  final dataSet = FdcDataSet(
    fields: _fields,
    adapter: FdcMemoryDataAdapter(rows: _rows),
    paging: const FdcDataPagingOptions(enabled: true, pageSize: 20),
  );
  addTearDown(dataSet.dispose);

  await dataSet.open();
  await applyFilter(dataSet);

  return _ids(dataSet);
}

List<Object?> _ids(FdcDataSet dataSet) {
  return dataSet.toMaps().map((row) => row['id']).toList();
}

const _fields = <FdcFieldDef>[
  FdcIntegerField(name: 'id', isKey: true),
  FdcStringField(name: 'name', size: 40),
  FdcStringField(name: 'note', size: 40),
];

const _rows = <Map<String, Object?>>[
  <String, Object?>{'id': 1, 'name': 'Alice', 'note': ''},
  <String, Object?>{'id': 2, 'name': 'ALICE', 'note': '   '},
  <String, Object?>{'id': 3, 'name': 'anita', 'note': null},
  <String, Object?>{'id': 4, 'name': 'Banana', 'note': 'ready'},
  <String, Object?>{'id': 5, 'name': 'James', 'note': 'done'},
  <String, Object?>{'id': 6, 'name': 'Mia', 'note': 'x'},
  <String, Object?>{'id': 7, 'name': 'AN', 'note': 'Y'},
];
