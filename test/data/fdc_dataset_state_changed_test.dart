import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'state changed does not fire on construction',
    _testStateChangedDoesNotFireOnConstruction,
  );
  test('adapter open state changed', _testAdapterOpenStateChanged);
  test(
    'edit post cancel insert close state changed',
    _testEditPostCancelInsertCloseStateChanged,
  );
  test(
    'state changed does not fire when state is unchanged',
    _testStateChangedDoesNotFireWhenStateIsUnchanged,
  );
  test('open async state changed', _testOpenAsyncStateChanged);
  test('apply updates state changed', _testApplyUpdatesStateChanged);
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

  expect(dataSet.state, FdcDataSetState.closed);
  expect(eventLog, isEmpty);
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
      expect(previousState, FdcDataSetState.closed);
      expect(currentState, FdcDataSetState.browse);
      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(dataSet.fieldValue('name'), 'Alpha');
    },
  );

  await dataSet.open();

  expect(eventLog.length, 1);
  expect(eventLog.single, 'closed->browse');
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
      expect(dataSet.state, currentState);
      if (currentState == FdcDataSetState.edit ||
          currentState == FdcDataSetState.insert) {
        expect(dataSet.recordCount, greaterThan(0));
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

  expect(
    eventLog.join('|'),
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

  expect(dataSetClosed.state, FdcDataSetState.closed);
  expect(dataSetClosed.recordCount, 0);
  expect(eventLog.length, 1);
  expect(eventLog.single, 'closed->browse');
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
        expect(dataSet.recordCount, 0);
      }
      if (currentState == FdcDataSetState.browse) {
        expect(dataSet.recordCount, 1);
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      }
    },
  );

  await dataSet.open();

  expect(eventLog.join('|'), 'closed->loading|loading->browse');
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
      expect(dataSet.state, currentState);
    },
  );

  await dataSet.open();
  dataSet.edit();
  dataSet.setFieldValue('name', 'Changed');
  dataSet.post();
  expect(dataSet.hasUpdates, isTrue);

  final result = await dataSet.applyUpdates();

  expect(result.success, isTrue);
  expect(
    eventLog.join('|'),
    'closed->loading|loading->browse|browse->edit|edit->browse|browse->applyingUpdates|applyingUpdates->browse',
  );
  expect(dataSet.hasUpdates, isFalse);
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
