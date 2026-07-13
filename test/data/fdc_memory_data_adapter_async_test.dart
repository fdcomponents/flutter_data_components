import 'dart:async';
import 'dart:isolate';

import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

String _throwingSendableSearchFormatter(Object? value) {
  throw StateError('sendable formatter failed');
}

void main() {
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
