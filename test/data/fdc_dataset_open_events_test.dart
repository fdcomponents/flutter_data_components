import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  await _testOpenEvents();
  await _testAdapterOpenEvents();
  _testAdapterConstructionDoesNotFireOpenEvents();
  await _testSilentBeforeOpenAbortDoesNotOpenOrSetErrors();
  await _testVisibleBeforeOpenAbortSetsErrors();
  await _testOpenAsyncEvents();
  await _testOpenAsyncBeforeOpenAbortDoesNotLoadAdapter();
}

Future<void> _testOpenEvents() async {
  final eventLog = <String>[];

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    beforeOpen: (dataSet) {
      eventLog.add('beforeOpen');
      assert(dataSet.state == FdcDataSetState.closed);
      assert(dataSet.recordCount == 0);
    },
    afterOpen: (dataSet) {
      eventLog.add('afterOpen');
      assert(dataSet.state == FdcDataSetState.browse);
      assert(dataSet.recordCount == 0);
    },
  );

  await dataSet.open();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(eventLog.length == 2);
  assert(eventLog[0] == 'beforeOpen');
  assert(eventLog[1] == 'afterOpen');
  assert(dataSet.errors.messages.isEmpty);
}

Future<void> _testAdapterOpenEvents() async {
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
      assert(dataSet.state == FdcDataSetState.closed);
      assert(dataSet.recordCount == 0);
    },
    afterOpen: (dataSet) {
      eventLog.add('afterOpen');
      assert(dataSet.state == FdcDataSetState.browse);
      assert(dataSet.recordCount == 2);
      assert(dataSet.fieldValue('name') == 'Alpha');
    },
  );

  await dataSet.open();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 2);
  assert(eventLog.length == 2);
  assert(eventLog[0] == 'beforeOpen');
  assert(eventLog[1] == 'afterOpen');
  assert(dataSet.errors.messages.isEmpty);
}

void _testAdapterConstructionDoesNotFireOpenEvents() {
  final eventLog = <String>[];

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        <String, Object?>{'id': 1},
      ],
    ),
    beforeOpen: (dataSet) {
      eventLog.add('beforeOpen');
    },
    afterOpen: (dataSet) {
      eventLog.add('afterOpen');
    },
  );

  assert(dataSet.state == FdcDataSetState.closed);
  assert(dataSet.recordCount == 0);
  assert(eventLog.isEmpty);
  assert(dataSet.errors.messages.isEmpty);
}

Future<void> _testSilentBeforeOpenAbortDoesNotOpenOrSetErrors() async {
  var afterOpenCalled = false;

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        <String, Object?>{'id': 1},
      ],
    ),
    beforeOpen: (dataSet) {
      throw const FdcDataSetAbortException.silent();
    },
    afterOpen: (dataSet) {
      afterOpenCalled = true;
    },
  );

  await dataSet.open();

  assert(dataSet.errors.messages.isEmpty);
  assert(!afterOpenCalled);
  assert(dataSet.state == FdcDataSetState.closed);
  assert(dataSet.recordCount == 0);
  assert(dataSet.errors.messages.isEmpty);
}

Future<void> _testVisibleBeforeOpenAbortSetsErrors() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    beforeOpen: (dataSet) {
      throw FdcDataSetAbortException('Open is not allowed.');
    },
  );

  await dataSet.open();

  assert(dataSet.errors.messages[0] == 'Open is not allowed.');
  assert(dataSet.state == FdcDataSetState.closed);
  assert(dataSet.recordCount == 0);
  assert(dataSet.errors.messages.isNotEmpty);
  assert(dataSet.errors.messages[0] == 'Open is not allowed.');
}

Future<void> _testOpenAsyncEvents() async {
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
      assert(dataSet.state == FdcDataSetState.closed);
    },
    afterOpen: (dataSet) {
      eventLog.add('afterOpen');
      assert(dataSet.state == FdcDataSetState.browse);
      assert(dataSet.recordCount == 2);
    },
  );

  await dataSet.open();

  assert(adapter.loadCount == 1);
  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 2);
  assert(eventLog.length == 2);
  assert(eventLog[0] == 'beforeOpen');
  assert(eventLog[1] == 'afterOpen');
  assert(dataSet.errors.messages.isEmpty);
}

Future<void> _testOpenAsyncBeforeOpenAbortDoesNotLoadAdapter() async {
  final adapter = _MemoryLoadAdapter(<Map<String, Object?>>[
    <String, Object?>{'id': 1},
  ]);

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    adapter: adapter,
    beforeOpen: (dataSet) {
      throw const FdcDataSetAbortException.silent();
    },
  );

  await dataSet.open();

  assert(dataSet.errors.messages.isEmpty);
  assert(adapter.loadCount == 0);
  assert(dataSet.state == FdcDataSetState.closed);
  assert(dataSet.recordCount == 0);
  assert(dataSet.errors.messages.isEmpty);
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
