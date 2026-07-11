import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  _testStateChangedDoesNotFireOnConstruction();
  await _testAdapterOpenStateChanged();
  await _testEditPostCancelInsertCloseStateChanged();
  await _testStateChangedDoesNotFireWhenStateIsUnchanged();
  await _testOpenAsyncStateChanged();
  await _testApplyUpdatesStateChanged();
}

void _testStateChangedDoesNotFireOnConstruction() {
  final eventLog = <String>[];

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    onStateChanged: (dataSet, previousState, currentState) {
      eventLog.add('${previousState.name}->${currentState.name}');
    },
  );

  assert(dataSet.state == FdcDataSetState.closed);
  assert(eventLog.isEmpty);
}

Future<void> _testAdapterOpenStateChanged() async {
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
    onStateChanged: (dataSet, previousState, currentState) {
      eventLog.add('${previousState.name}->${currentState.name}');
      assert(previousState == FdcDataSetState.closed);
      assert(currentState == FdcDataSetState.browse);
      assert(dataSet.state == FdcDataSetState.browse);
      assert(dataSet.recordCount == 2);
      assert(FdcDataSetInternal.activeIndex(dataSet) == 0);
      assert(dataSet.fieldValue('name') == 'Alpha');
    },
  );

  await dataSet.open();

  assert(eventLog.length == 1);
  assert(eventLog.single == 'closed->browse');
}

Future<void> _testEditPostCancelInsertCloseStateChanged() async {
  final eventLog = <String>[];

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ],
    ),
    onStateChanged: (dataSet, previousState, currentState) {
      eventLog.add('${previousState.name}->${currentState.name}');
      assert(dataSet.state == currentState);
      if (currentState == FdcDataSetState.edit ||
          currentState == FdcDataSetState.insert) {
        assert(dataSet.recordCount > 0);
      }
    },
  );

  await dataSet.open();
  dataSet.edit();
  dataSet.setFieldValue('name', 'Changed');
  dataSet.post();
  dataSet.insert();
  dataSet.cancel();
  dataSet.close();

  assert(
    eventLog.join('|') ==
        'closed->browse|browse->edit|edit->browse|browse->insert|insert->browse|browse->closed',
  );
}

Future<void> _testStateChangedDoesNotFireWhenStateIsUnchanged() async {
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
    onStateChanged: (dataSet, previousState, currentState) {
      eventLog.add('${previousState.name}->${currentState.name}');
    },
  );

  await dataSet.open();
  dataSet.next();
  dataSet.prior();
  await dataSet.filter.set(const <FdcDataSetFilter>[]);

  final dataSetClosed = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        <String, Object?>{'id': 1},
      ],
    ),
    onStateChanged: (dataSet, previousState, currentState) {
      eventLog.add(
        'closed-dataset:${previousState.name}->${currentState.name}',
      );
    },
  );

  assert(dataSetClosed.state == FdcDataSetState.closed);
  assert(dataSetClosed.recordCount == 0);
  assert(eventLog.length == 1);
  assert(eventLog.single == 'closed->browse');
}

Future<void> _testOpenAsyncStateChanged() async {
  final eventLog = <String>[];
  final adapter = _MemoryAdapter(<Map<String, Object?>>[
    <String, Object?>{'id': 1, 'name': 'Alpha'},
  ]);

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    adapter: adapter,
    onStateChanged: (dataSet, previousState, currentState) {
      eventLog.add('${previousState.name}->${currentState.name}');
      if (currentState == FdcDataSetState.loading) {
        assert(dataSet.recordCount == 0);
      }
      if (currentState == FdcDataSetState.browse) {
        assert(dataSet.recordCount == 1);
        assert(FdcDataSetInternal.activeIndex(dataSet) == 0);
      }
    },
  );

  await dataSet.open();

  assert(eventLog.join('|') == 'closed->loading|loading->browse');
}

Future<void> _testApplyUpdatesStateChanged() async {
  final eventLog = <String>[];
  final adapter = _MemoryAdapter(<Map<String, Object?>>[
    <String, Object?>{'id': 1, 'name': 'Alpha'},
  ]);

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    adapter: adapter,
    onStateChanged: (dataSet, previousState, currentState) {
      eventLog.add('${previousState.name}->${currentState.name}');
      assert(dataSet.state == currentState);
    },
  );

  await dataSet.open();
  dataSet.edit();
  dataSet.setFieldValue('name', 'Changed');
  dataSet.post();
  assert(dataSet.hasUpdates);

  final result = await dataSet.applyUpdates();

  assert(result.success);
  assert(
    eventLog.join('|') ==
        'closed->loading|loading->browse|browse->edit|edit->browse|browse->applyingUpdates|applyingUpdates->browse',
  );
  assert(!dataSet.hasUpdates);
}

class _MemoryAdapter implements IFdcDataAdapter {
  _MemoryAdapter(this.rows);

  final List<Map<String, Object?>> rows;

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
    return FdcDataLoadResult(rows: rows);
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    return const FdcDataApplyResult.success();
  }
}
