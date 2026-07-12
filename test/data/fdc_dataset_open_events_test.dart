import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('open fires callbacks in order for an empty memory adapter', () async {
    final eventLog = <String>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      beforeOpen: (dataSet) {
        eventLog.add('beforeOpen');
        expect(dataSet.state, FdcDataSetState.closed);
        expect(dataSet.recordCount, 0);
      },
      afterOpen: (dataSet) {
        eventLog.add('afterOpen');
        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.recordCount, 0);
      },
    );

    await dataSet.open();

    expect(dataSet.state, FdcDataSetState.browse);
    expect(eventLog, <String>['beforeOpen', 'afterOpen']);
    expect(dataSet.errors.message, isEmpty);
  });

  test('afterOpen observes rows loaded by the adapter', () async {
    final eventLog = <String>[];

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(size: 255, name: 'name'),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Alpha'},
          <String, Object?>{'id': 2, 'name': 'Beta'},
        ],
      ),
      beforeOpen: (dataSet) {
        eventLog.add('beforeOpen');
        expect(dataSet.state, FdcDataSetState.closed);
        expect(dataSet.recordCount, 0);
      },
      afterOpen: (dataSet) {
        eventLog.add('afterOpen');
        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.recordCount, 2);
        expect(dataSet.fieldValue('name'), 'Alpha');
      },
    );

    await dataSet.open();

    expect(dataSet.recordCount, 2);
    expect(eventLog, <String>['beforeOpen', 'afterOpen']);
    expect(dataSet.errors.message, isEmpty);
  });

  test(
    'constructing an adapter-backed dataset does not fire open callbacks',
    () {
      final eventLog = <String>[];

      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{'id': 1},
          ],
        ),
        beforeOpen: (_) => eventLog.add('beforeOpen'),
        afterOpen: (_) => eventLog.add('afterOpen'),
      );

      expect(dataSet.state, FdcDataSetState.closed);
      expect(dataSet.recordCount, 0);
      expect(eventLog, isEmpty);
      expect(dataSet.errors.message, isEmpty);
    },
  );

  test(
    'silent beforeOpen abort keeps the dataset closed without errors',
    () async {
      var afterOpenCalled = false;

      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{'id': 1},
          ],
        ),
        beforeOpen: (_) => throw const FdcDataSetAbortException.silent(),
        afterOpen: (_) => afterOpenCalled = true,
      );

      await dataSet.open();

      expect(afterOpenCalled, isFalse);
      expect(dataSet.state, FdcDataSetState.closed);
      expect(dataSet.recordCount, 0);
      expect(dataSet.errors.message, isEmpty);
    },
  );

  test(
    'visible beforeOpen abort exposes its message and keeps the dataset closed',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
        beforeOpen: (_) {
          throw FdcDataSetAbortException('Open is not allowed.');
        },
      );

      await dataSet.open();

      expect(dataSet.state, FdcDataSetState.closed);
      expect(dataSet.recordCount, 0);
      expect(dataSet.errors.message, 'Open is not allowed.');
    },
  );

  test('open loads a custom adapter once before firing afterOpen', () async {
    final eventLog = <String>[];
    final adapter = _MemoryLoadAdapter(<Map<String, Object?>>[
      <String, Object?>{'id': 1, 'name': 'Alpha'},
      <String, Object?>{'id': 2, 'name': 'Beta'},
    ]);

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(size: 255, name: 'name'),
      ],
      adapter: adapter,
      beforeOpen: (dataSet) {
        eventLog.add('beforeOpen');
        expect(dataSet.state, FdcDataSetState.closed);
      },
      afterOpen: (dataSet) {
        eventLog.add('afterOpen');
        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.recordCount, 2);
      },
    );

    await dataSet.open();

    expect(adapter.loadCount, 1);
    expect(dataSet.recordCount, 2);
    expect(eventLog, <String>['beforeOpen', 'afterOpen']);
    expect(dataSet.errors.message, isEmpty);
  });

  test('beforeOpen abort prevents a custom adapter load', () async {
    final adapter = _MemoryLoadAdapter(<Map<String, Object?>>[
      <String, Object?>{'id': 1},
    ]);

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      adapter: adapter,
      beforeOpen: (_) => throw const FdcDataSetAbortException.silent(),
    );

    await dataSet.open();

    expect(adapter.loadCount, 0);
    expect(dataSet.state, FdcDataSetState.closed);
    expect(dataSet.recordCount, 0);
    expect(dataSet.errors.message, isEmpty);
  });
}

class _MemoryLoadAdapter implements IFdcDataAdapter {
  _MemoryLoadAdapter(this.rows);

  final List<Map<String, Object?>> rows;
  int loadCount = 0;

  @override
  bool get readOnly => false;

  @override
  FdcDataAdapterCapabilities get capabilities =>
      const FdcDataAdapterCapabilities.none();

  @override
  Future<FdcDataAggregateResult> aggregate(
    FdcDataAggregateRequest request,
  ) async {
    throw FdcDataAdapterException(
      operation: 'aggregate',
      code: 'unsupported_adapter_operation',
      message: '$runtimeType does not support aggregate queries.',
    );
  }

  @override
  String? validateStorageValue(FdcFieldDef field, Object? value) => null;

  @override
  FdcDataApplyError mapApplyException(
    FdcChangeSetEntry entry,
    Object error, {
    required FdcDataApplyOperation operation,
  }) {
    return FdcDataApplyError(
      recordId: entry.recordId,
      message: error.toString(),
      code: 'adapter_error',
    );
  }

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    loadCount++;
    return FdcDataLoadResult(rows: rows);
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    return const FdcDataApplyResult.success();
  }
}
