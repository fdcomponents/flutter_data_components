import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('memory adapter applies load filters before sort and paging', () {
    final adapter = FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alice', 'score': 20},
        {'id': 2, 'name': 'Ethan', 'score': 10},
        {'id': 3, 'name': 'Anita', 'score': 30},
      ],
    );

    final result = adapter.loadSync(
      const FdcDataLoadRequest(
        filters: <FdcDataAdapterFilter>[
          FdcDataAdapterFilter(
            fieldName: 'name',
            value: 'an',
            operator: FdcDataAdapterFilterOperator.contains,
          ),
        ],
        sorts: <FdcDataAdapterSort>[
          FdcDataAdapterSort(
            fieldName: 'score',
            sortType: FdcSortType.descending,
          ),
        ],
        offset: 0,
        limit: 1,
      ),
    );

    expect(result.totalCount, 2);
    expect(result.rows, hasLength(1));
    expect(result.rows.single['name'], 'Anita');
  });

  test(
    'memory adapter applies unsorted filters and paging without sorting',
    () {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Ethan'},
          {'id': 3, 'name': 'Anita'},
          {'id': 4, 'name': 'Anamarija'},
        ],
      );

      final result = adapter.loadSync(
        const FdcDataLoadRequest(
          filters: <FdcDataAdapterFilter>[
            FdcDataAdapterFilter(
              fieldName: 'name',
              value: 'an',
              operator: FdcDataAdapterFilterOperator.contains,
            ),
          ],
          offset: 1,
          limit: 1,
        ),
      );

      expect(result.totalCount, 3);
      expect(result.rows, <Map<String, Object?>>[
        {'id': 3, 'name': 'Anita'},
      ]);
    },
  );

  test('memory adapter supports every load filter operator', () {
    final adapter = FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alice', 'score': 10, 'note': ''},
        {'id': 2, 'name': 'Ethan', 'score': 20, 'note': 'ready'},
        {'id': 3, 'name': 'Mia', 'score': 30, 'note': null},
        {'id': 4, 'name': 'Anita', 'score': 40, 'note': 'done'},
        {'id': 5, 'name': 'ALICE', 'score': 50, 'note': '   '},
      ],
    );

    List<Object?> idsFor(FdcDataAdapterFilter filter) {
      final result = adapter.loadSync(
        FdcDataLoadRequest(filters: <FdcDataAdapterFilter>[filter]),
      );
      return result.rows.map((row) => row['id']).toList();
    }

    expect(
      idsFor(const FdcDataAdapterFilter(fieldName: 'name', value: 'Alice')),
      <Object?>[1],
    );
    expect(
      idsFor(
        const FdcDataAdapterFilter(
          fieldName: 'name',
          value: 'Alice',
          operator: FdcDataAdapterFilterOperator.notEquals,
        ),
      ),
      <Object?>[2, 3, 4, 5],
    );
    expect(
      idsFor(
        const FdcDataAdapterFilter(
          fieldName: 'name',
          value: 'an',
          operator: FdcDataAdapterFilterOperator.contains,
        ),
      ),
      <Object?>[2, 4],
    );
    expect(
      idsFor(
        const FdcDataAdapterFilter(
          fieldName: 'name',
          value: 'an',
          operator: FdcDataAdapterFilterOperator.startsWith,
        ),
      ),
      <Object?>[4],
    );
    expect(
      idsFor(
        const FdcDataAdapterFilter(
          fieldName: 'name',
          value: 'ia',
          operator: FdcDataAdapterFilterOperator.endsWith,
        ),
      ),
      <Object?>[3],
    );
    expect(
      idsFor(
        const FdcDataAdapterFilter(
          fieldName: 'score',
          value: 20,
          operator: FdcDataAdapterFilterOperator.greaterThan,
        ),
      ),
      <Object?>[3, 4, 5],
    );
    expect(
      idsFor(
        const FdcDataAdapterFilter(
          fieldName: 'score',
          value: 20,
          operator: FdcDataAdapterFilterOperator.greaterThanOrEqual,
        ),
      ),
      <Object?>[2, 3, 4, 5],
    );
    expect(
      idsFor(
        const FdcDataAdapterFilter(
          fieldName: 'score',
          value: 30,
          operator: FdcDataAdapterFilterOperator.lessThan,
        ),
      ),
      <Object?>[1, 2],
    );
    expect(
      idsFor(
        const FdcDataAdapterFilter(
          fieldName: 'score',
          value: 30,
          operator: FdcDataAdapterFilterOperator.lessThanOrEqual,
        ),
      ),
      <Object?>[1, 2, 3],
    );
    expect(
      idsFor(const FdcDataAdapterFilter.inList('score', <Object?>[10, 30])),
      <Object?>[1, 3],
    );
    expect(
      idsFor(const FdcDataAdapterFilter.notInList('score', <Object?>[10, 30])),
      <Object?>[2, 4, 5],
    );
    expect(
      idsFor(
        const FdcDataAdapterFilter(
          fieldName: 'note',
          value: null,
          operator: FdcDataAdapterFilterOperator.isEmpty,
        ),
      ),
      <Object?>[1, 3],
    );
    expect(
      idsFor(
        const FdcDataAdapterFilter(
          fieldName: 'note',
          value: null,
          operator: FdcDataAdapterFilterOperator.isNotEmpty,
        ),
      ),
      <Object?>[2, 4, 5],
    );
    expect(idsFor(const FdcDataAdapterFilter.isNull('note')), <Object?>[3]);
    expect(idsFor(const FdcDataAdapterFilter.isNotNull('note')), <Object?>[
      1,
      2,
      4,
      5,
    ]);
    expect(
      idsFor(const FdcDataAdapterFilter.isNullOrWhitespace('note')),
      <Object?>[1, 3, 5],
    );
    expect(
      idsFor(const FdcDataAdapterFilter.isNotNullOrWhitespace('note')),
      <Object?>[2, 4],
    );
    expect(
      idsFor(
        const FdcDataAdapterFilter.contains('name', 'AL', caseSensitive: true),
      ),
      <Object?>[5],
    );
    expect(idsFor(const FdcDataAdapterFilter.contains('name', 'an')), <Object?>[
      2,
      4,
    ]);
  });
}
