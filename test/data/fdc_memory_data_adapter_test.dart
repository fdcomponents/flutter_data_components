import 'dart:async';
import 'dart:isolate';

import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

String _throwingSendableSearchFormatter(Object? value) {
  throw StateError('sendable formatter failed');
}

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

  test(
    'memory adapter applyUpdates applies inserts updates and deletes',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Ethan'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          inserts: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 3,
              values: <String, Object?>{'id': 3, 'name': 'Mia'},
              originalValues: <String, Object?>{},
              changedFields: <String>{'id', 'name'},
            ),
          ],
          updates: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 1,
              values: <String, Object?>{'name': 'Alice Maria'},
              originalValues: <String, Object?>{'name': 'Alice'},
              changedFields: <String>{'name'},
            ),
          ],
          deletes: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 2,
              values: <String, Object?>{},
              originalValues: <String, Object?>{'id': 2, 'name': 'Ethan'},
              changedFields: <String>{},
            ),
          ],
        ),
      );

      expect(result.success, isTrue);
      expect(adapter.rows, <Map<String, Object?>>[
        {'id': 1, 'name': 'Alice Maria'},
        {'id': 3, 'name': 'Mia'},
      ]);
    },
  );

  test(
    'memory adapter applyUpdates matches updates and deletes by key fields',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Server Alice'},
          {'id': 2, 'name': 'Server Ethan'},
          {'id': 3, 'name': 'Mia'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          fields: <FdcFieldDef>[
            FdcIntegerField(name: 'id', isKey: true),
            FdcStringField(name: 'name', size: 100),
          ],
          inserts: <FdcChangeSetEntry>[],
          updates: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{'name': 'Alice Maria'},
              originalValues: <String, Object?>{'id': 1, 'name': 'Local Alice'},
              changedFields: <String>{'name'},
            ),
          ],
          deletes: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{},
              originalValues: <String, Object?>{'id': 2, 'name': 'Local Ethan'},
              changedFields: <String>{},
            ),
          ],
        ),
      );

      expect(result.success, isTrue);
      expect(adapter.rows, <Map<String, Object?>>[
        {'id': 1, 'name': 'Alice Maria'},
        {'id': 3, 'name': 'Mia'},
      ]);
    },
  );

  test(
    'memory adapter applyUpdates fails missing update and keeps rows unchanged',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Ethan'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          inserts: <FdcChangeSetEntry>[],
          updates: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{'name': 'Ghost'},
              originalValues: <String, Object?>{'id': 99, 'name': 'Missing'},
              changedFields: <String>{'name'},
            ),
          ],
          deletes: <FdcChangeSetEntry>[],
        ),
      );

      expect(result.success, isFalse);
      expect(result.errors.single.recordId, 99);
      expect(result.errors.single.code, 'not_found');
      expect(result.errors.single.message, contains('Update failed'));
      expect(adapter.rows, <Map<String, Object?>>[
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Ethan'},
      ]);
    },
  );

  test(
    'memory adapter applyUpdates fails missing delete and keeps rows unchanged',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Ethan'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          inserts: <FdcChangeSetEntry>[],
          updates: <FdcChangeSetEntry>[],
          deletes: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{},
              originalValues: <String, Object?>{'id': 99, 'name': 'Missing'},
              changedFields: <String>{},
            ),
          ],
        ),
      );

      expect(result.success, isFalse);
      expect(result.errors.single.recordId, 99);
      expect(result.errors.single.code, 'not_found');
      expect(result.errors.single.message, contains('Delete failed'));
      expect(adapter.rows, <Map<String, Object?>>[
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Ethan'},
      ]);
    },
  );

  test(
    'memory adapter applyUpdates is copy-on-write for mixed batch failure',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Ethan'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          deletes: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 2,
              values: <String, Object?>{},
              originalValues: <String, Object?>{'id': 2, 'name': 'Ethan'},
              changedFields: <String>{},
            ),
          ],
          updates: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{'name': 'Ghost'},
              originalValues: <String, Object?>{'id': 99, 'name': 'Missing'},
              changedFields: <String>{'name'},
            ),
          ],
          inserts: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 3,
              values: <String, Object?>{'id': 3, 'name': 'Mia'},
              originalValues: <String, Object?>{},
              changedFields: <String>{'id', 'name'},
            ),
          ],
        ),
      );

      expect(result.success, isFalse);
      expect(result.errors.single.recordId, 99);
      expect(adapter.rows, <Map<String, Object?>>[
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Ethan'},
      ]);
    },
  );

  test(
    'memory adapter without keys does not fall back to value matching',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alice'},
          {'name': 'Ethan'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          inserts: <FdcChangeSetEntry>[],
          updates: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{'name': 'Alice Maria'},
              originalValues: <String, Object?>{'name': 'Alice'},
              changedFields: <String>{'name'},
            ),
          ],
          deletes: <FdcChangeSetEntry>[],
        ),
      );

      expect(result.success, isFalse);
      expect(result.errors.single.code, 'not_found');
      expect(adapter.rows, <Map<String, Object?>>[
        {'name': 'Alice'},
        {'name': 'Ethan'},
      ]);
    },
  );

  test(
    'memory adapter without keys does not delete by duplicate values',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alice'},
          {'name': 'Alice'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          inserts: <FdcChangeSetEntry>[],
          updates: <FdcChangeSetEntry>[],
          deletes: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{'name': 'Alice'},
              originalValues: <String, Object?>{'name': 'Alice'},
              changedFields: <String>{},
            ),
          ],
        ),
      );

      expect(result.success, isFalse);
      expect(result.errors.single.code, 'not_found');
      expect(adapter.rows, <Map<String, Object?>>[
        {'name': 'Alice'},
        {'name': 'Alice'},
      ]);
    },
  );

  test(
    'memory adapter returns internal row ids without exposing key fields',
    () {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alice'},
          {'name': 'Ethan'},
        ],
      );

      final result = adapter.loadSync(const FdcDataLoadRequest());

      expect(result.fields, isNull);
      expect(result.internalRowIds, <int>[1, 2]);
      expect(result.internalNextRowId, 3);
      expect(result.rows, <Map<String, Object?>>[
        {'name': 'Alice'},
        {'name': 'Ethan'},
      ]);
    },
  );

  test(
    'memory adapter without dataset keys updates by internal row identity',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alice'},
          {'name': 'Alice'},
        ],
      );
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 50, name: 'name')],
        adapter: adapter,
      );

      dataSet.open();
      dataSet.next();
      dataSet.edit();
      dataSet['name'] = 'Emily';
      dataSet.post();

      final result = await dataSet.applyUpdates();

      expect(result.success, isTrue);
      expect(adapter.rows, <Map<String, Object?>>[
        {'name': 'Alice'},
        {'name': 'Emily'},
      ]);
    },
  );

  test(
    'memory adapter without dataset keys deletes by internal row identity',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alice'},
          {'name': 'Alice'},
        ],
      );
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 50, name: 'name')],
        adapter: adapter,
      );

      dataSet.open();
      dataSet.next();
      dataSet.delete();

      final result = await dataSet.applyUpdates();

      expect(result.success, isTrue);
      expect(adapter.rows, <Map<String, Object?>>[
        {'name': 'Alice'},
      ]);
    },
  );

  test(
    'memory paged load allocates inserted row identity after full adapter range',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'A'},
          {'name': 'B'},
          {'name': 'C'},
        ],
      );
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 50, name: 'name')],
        adapter: adapter,
      );

      dataSet.open(request: const FdcDataLoadRequest(limit: 1));
      dataSet.append();
      dataSet['name'] = 'D';
      dataSet.post();

      final result = await dataSet.applyUpdates();

      expect(result.success, isTrue);
      expect(adapter.rows, <Map<String, Object?>>[
        {'name': 'A'},
        {'name': 'B'},
        {'name': 'C'},
        {'name': 'D'},
      ]);
    },
  );

  test(
    'memory inserted rows receive internal identity and can be updated later',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[],
      );
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 50, name: 'name')],
        adapter: adapter,
      );

      dataSet.open();
      dataSet.append();
      dataSet['name'] = 'Alice';
      dataSet.post();

      var result = await dataSet.applyUpdates();
      expect(result.success, isTrue);

      dataSet.edit();
      dataSet['name'] = 'Alice Maria';
      dataSet.post();

      result = await dataSet.applyUpdates();

      expect(result.success, isTrue);
      expect(adapter.rows, <Map<String, Object?>>[
        {'name': 'Alice Maria'},
      ]);
    },
  );

  test(
    'delete change set uses original values so memory delete matches edited rows without keys',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alice'},
        ],
      );
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', isKey: true),
          FdcStringField(size: 50, name: 'name'),
        ],
        adapter: adapter,
      );

      dataSet.open();
      dataSet.edit();
      dataSet['name'] = 'Alice Maria';
      dataSet.post();
      dataSet.delete();

      final result = await dataSet.applyUpdates();

      expect(result.success, isTrue);
      expect(adapter.rows, isEmpty);
      expect(dataSet.hasUpdates, isFalse);
    },
  );

  test(
    'memory adapter async load matches prepared sync search result',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alice', 'score': 10},
          {'id': 2, 'name': 'Ethan', 'score': 20},
          {'id': 3, 'name': 'Anita', 'score': 30},
        ],
      );
      const request = FdcDataLoadRequest(
        search: FdcDataSetSearchState(text: 'an'),
        fields: <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'name', size: 50),
          FdcIntegerField(name: 'score'),
        ],
        sorts: <FdcDataAdapterSort>[
          FdcDataAdapterSort(
            fieldName: 'score',
            sortType: FdcSortType.descending,
          ),
        ],
      );

      final syncResult = adapter.loadSync(request);
      final asyncResult = await adapter.load(request);

      expect(asyncResult.rows, syncResult.rows);
      expect(asyncResult.totalCount, syncResult.totalCount);
      expect(asyncResult.internalRowIds, syncResult.internalRowIds);
    },
  );

  test(
    'memory adapter computes multiple aggregates in one query result',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alice', 'amount': 10},
          {'name': 'Ethan', 'amount': 20},
          {'name': 'Anita', 'amount': 30},
        ],
      );
      const request = FdcDataAggregateRequest(
        search: FdcDataSetSearchState(text: 'an'),
        fields: <FdcFieldDef>[
          FdcStringField(name: 'name', size: 50),
          FdcIntegerField(name: 'amount'),
        ],
        aggregates: <FdcDataAggregateItem>[
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.sum,
          ),
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.avg,
          ),
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.min,
          ),
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.max,
          ),
        ],
      );

      final result = await adapter.aggregate(request);

      expect(
        result.valueFor('amount', FdcAggregate.sum),
        FdcDecimal.parse('50'),
      );
      expect(
        result.valueFor('amount', FdcAggregate.avg),
        FdcDecimal.parse('25'),
      );
      expect(result.valueFor('amount', FdcAggregate.min), 20);
      expect(result.valueFor('amount', FdcAggregate.max), 30);
    },
  );

  test(
    'memory adapter executes the real background-isolate load path',
    () async {
      final rows = List<Map<String, Object?>>.generate(
        2500,
        (index) => <String, Object?>{
          'id': index + 1,
          'name': index.isEven ? 'Alice $index' : 'Ethan $index',
          'amount': index,
        },
        growable: false,
      );
      final adapter = FdcMemoryDataAdapter(rows: rows);
      const request = FdcDataLoadRequest(
        search: FdcDataSetSearchState(text: 'alice'),
        fields: <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'name', size: 50),
          FdcIntegerField(name: 'amount'),
        ],
        sorts: <FdcDataAdapterSort>[
          FdcDataAdapterSort(
            fieldName: 'amount',
            sortType: FdcSortType.descending,
          ),
        ],
        offset: 10,
        limit: 25,
      );

      final syncResult = adapter.loadSync(request);
      final asyncResult = await adapter.load(request);

      expect(asyncResult.rows, syncResult.rows);
      expect(asyncResult.totalCount, 1250);
      expect(asyncResult.internalRowIds, syncResult.internalRowIds);
      expect(asyncResult.rows, hasLength(25));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'memory adapter does not retry a failed background query inline',
    () async {
      final rows = List<Map<String, Object?>>.generate(
        2500,
        (index) => <String, Object?>{'name': 'Alice $index'},
        growable: false,
      );
      final adapter = FdcMemoryDataAdapter(rows: rows);
      final calls = ReceivePort();
      final received = <Object?>[];
      final firstCall = Completer<void>();
      final subscription = calls.listen((message) {
        received.add(message);
        if (!firstCall.isCompleted) {
          firstCall.complete();
        }
      });
      final sendPort = calls.sendPort;
      final request = FdcDataLoadRequest(
        search: FdcDataSetSearchState(
          text: 'alice',
          fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
            'name': (value) {
              sendPort.send(value);
              throw StateError('formatter failed');
            },
          },
        ),
        fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 50)],
      );

      await expectLater(adapter.load(request), throwsStateError);
      await firstCall.future.timeout(const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(received, hasLength(1));
      await subscription.cancel();
      calls.close();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'memory adapter preserves query exception type across isolate threshold',
    () async {
      FdcDataLoadRequest request() => const FdcDataLoadRequest(
        search: FdcDataSetSearchState(
          text: 'alice',
          fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
            'name': _throwingSendableSearchFormatter,
          },
        ),
        fields: <FdcFieldDef>[FdcStringField(name: 'name', size: 50)],
      );

      final inlineAdapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alice'},
        ],
      );
      final workerAdapter = FdcMemoryDataAdapter(
        rows: List<Map<String, Object?>>.generate(
          2500,
          (index) => <String, Object?>{'name': 'Alice $index'},
          growable: false,
        ),
      );

      await expectLater(inlineAdapter.load(request()), throwsStateError);
      await expectLater(workerAdapter.load(request()), throwsStateError);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test(
    'memory adapter executes the real background-isolate aggregate path',
    () async {
      final rows = List<Map<String, Object?>>.generate(
        2500,
        (index) => <String, Object?>{
          'name': index.isEven ? 'Alice $index' : 'Ethan $index',
          'amount': index,
        },
        growable: false,
      );
      final adapter = FdcMemoryDataAdapter(rows: rows);
      const request = FdcDataAggregateRequest(
        search: FdcDataSetSearchState(text: 'alice'),
        fields: <FdcFieldDef>[
          FdcStringField(name: 'name', size: 50),
          FdcIntegerField(name: 'amount'),
        ],
        aggregates: <FdcDataAggregateItem>[
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.sum,
          ),
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.avg,
          ),
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.min,
          ),
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.max,
          ),
        ],
      );

      final syncResult = adapter.aggregateSync(request);
      final asyncResult = await adapter.aggregate(request);

      for (final aggregate in FdcAggregate.values) {
        expect(
          asyncResult.valueFor('amount', aggregate),
          syncResult.valueFor('amount', aggregate),
        );
      }
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
