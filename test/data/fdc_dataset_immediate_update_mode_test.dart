import 'dart:async';

import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dataset defaults to immediate update mode', () {
    final adapter = _RecordingAdapter(<Map<String, Object?>>[]);
    final dataSet = _createDataSet(adapter);

    expect(dataSet.updateMode, FdcUpdateMode.immediate);
  });

  test(
    'immediate update mode completes posted edits after adapter apply succeeds',
    () async {
      final adapter = _RecordingAdapter(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ]);
      final dataSet = _createDataSet(adapter);

      await dataSet.open();
      dataSet.edit();
      dataSet['name'] = 'Beta';
      dataSet.post();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(adapter.applyCalls, isEmpty);

      await _drainImmediateApply();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(adapter.applyCalls, hasLength(1));
      expect(adapter.applyCalls.single.updates, hasLength(1));
      expect(adapter.applyCalls.single.updates.single.values['name'], 'Beta');
      expect(dataSet.hasUpdates, isFalse);
    },
  );

  test('applyUpdates shares an in-flight public apply operation', () async {
    final adapter = _RecordingAdapter(<Map<String, Object?>>[
      <String, Object?>{'id': 1, 'name': 'Alpha'},
    ]);
    final applyGate = Completer<void>();
    final applyStarted = Completer<void>();
    adapter.applyGate = applyGate;
    adapter.applyStarted = applyStarted;
    final dataSet = _createDataSet(
      adapter,
      updateMode: FdcUpdateMode.cachedUpdates,
    );

    await dataSet.open();
    dataSet.edit();
    dataSet['name'] = 'Beta';
    dataSet.post();

    final firstApply = dataSet.applyUpdates();
    await applyStarted.future;

    final secondApply = dataSet.applyUpdates();

    expect(adapter.applyCalls, hasLength(1));

    applyGate.complete();
    final results = await Future.wait(<Future<FdcDataApplyResult>>[
      firstApply,
      secondApply,
    ]);

    expect(adapter.applyCalls, hasLength(1));
    expect(results[0].success, isTrue);
    expect(identical(results[0], results[1]), isTrue);
    expect(dataSet.hasUpdates, isFalse);
  });

  test(
    'applyUpdates shares an in-flight Future.wait public apply operation',
    () async {
      final adapter = _RecordingAdapter(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ]);
      final applyGate = Completer<void>();
      final applyStarted = Completer<void>();
      adapter.applyGate = applyGate;
      adapter.applyStarted = applyStarted;
      final dataSet = _createDataSet(
        adapter,
        updateMode: FdcUpdateMode.cachedUpdates,
      );

      await dataSet.open();
      dataSet.edit();
      dataSet['name'] = 'Beta';
      dataSet.post();

      final joined = Future.wait(<Future<FdcDataApplyResult>>[
        dataSet.applyUpdates(),
        dataSet.applyUpdates(),
      ]);

      await applyStarted.future;
      await Future<void>.delayed(Duration.zero);

      expect(adapter.applyCalls, hasLength(1));

      applyGate.complete();
      final results = await joined;

      expect(adapter.applyCalls, hasLength(1));
      expect(results[0].success, isTrue);
      expect(identical(results[0], results[1]), isTrue);
      expect(dataSet.hasUpdates, isFalse);
    },
  );

  test('immediate update mode applies deletes automatically', () async {
    final adapter = _RecordingAdapter(<Map<String, Object?>>[
      <String, Object?>{'id': 1, 'name': 'Alpha'},
    ]);
    final dataSet = _createDataSet(adapter);

    await dataSet.open();
    dataSet.delete();

    expect(dataSet.state, FdcDataSetState.browse);
    expect(adapter.applyCalls, isEmpty);

    await _drainImmediateApply();

    expect(adapter.applyCalls, hasLength(1));
    expect(adapter.applyCalls.single.deletes, hasLength(1));
    expect(adapter.applyCalls.single.deletes.single.originalValues['id'], 1);
    expect(dataSet.hasUpdates, isFalse);
  });

  test(
    'immediate delete keeps current row at deleted row view position after apply',
    () async {
      final adapter = _RecordingAdapter(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
        <String, Object?>{'id': 2, 'name': 'Beta'},
        <String, Object?>{'id': 3, 'name': 'Gamma'},
        <String, Object?>{'id': 4, 'name': 'Delta'},
      ]);
      final dataSet = _createDataSet(adapter);

      await dataSet.open();
      dataSet.next();
      expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      expect(dataSet['id'], 2);

      dataSet.delete();

      expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      expect(dataSet['id'], 3);

      await _drainImmediateApply();

      expect(adapter.applyCalls, hasLength(1));
      expect(dataSet.hasUpdates, isFalse);
      expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      expect(dataSet['id'], 3);
    },
  );

  test(
    'immediate update mode restores all pending deletes when adapter apply fails',
    () async {
      final adapter = _RecordingAdapter(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
        <String, Object?>{'id': 2, 'name': 'Beta'},
        <String, Object?>{'id': 3, 'name': 'Gamma'},
      ])..failNextApply = true;
      final dataSet = _createDataSet(adapter);

      await dataSet.open();
      expect(dataSet.recordCount, 3);

      dataSet.delete();
      dataSet.delete();

      expect(dataSet.recordCount, 1);
      expect(adapter.applyCalls, isEmpty);

      await _drainImmediateApply();

      expect(adapter.applyCalls, hasLength(1));
      expect(adapter.applyCalls.single.deletes, hasLength(2));
      expect(dataSet.hasUpdates, isFalse);
      expect(dataSet.recordCount, 3);
      expect(dataSet['id'], 1);

      dataSet.next();
      expect(dataSet['id'], 2);
      dataSet.next();
      expect(dataSet['id'], 3);
    },
  );

  test(
    'immediate update mode keeps rejected local changes dirty when adapter apply fails',
    () async {
      final adapter = _RecordingAdapter(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ])..failNextApply = true;
      final errors = <List<FdcDataSetError>>[];
      final dataSet = _createDataSet(
        adapter,
        onError: (dataSet, items, cause) => errors.add(items),
      );

      await dataSet.open();
      dataSet.append();
      dataSet['id'] = 1;
      dataSet['name'] = 'Duplicate';
      dataSet.post();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
      expect(dataSet.hasUpdates, isTrue);

      await _drainImmediateApply();

      expect(adapter.applyCalls, hasLength(1));
      expect(dataSet.hasUpdates, isTrue);
      expect(dataSet.recordCount, 2);
      expect(dataSet.errors.messages.isNotEmpty, isTrue);
      expect(errors, hasLength(1));
      expect(errors.single.single.message, 'Insert failed: duplicate key.');

      dataSet.cancelUpdates();

      expect(dataSet.hasUpdates, isFalse);
      expect(dataSet.recordCount, 1);
    },
  );

  test(
    'immediate adapter constraint failure leaves insert state active',
    () async {
      final adapter = _RecordingAdapter(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ])..failNextApply = true;
      final errors = <List<FdcDataSetError>>[];
      final dataSet = _createDataSet(
        adapter,
        onError: (dataSet, items, cause) => errors.add(items),
      );

      await dataSet.open();
      dataSet.append();
      dataSet['id'] = 1;
      dataSet['name'] = 'Duplicate';
      dataSet.post();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.hasUpdates, isTrue);
      expect(adapter.applyCalls, isEmpty);

      await _drainImmediateApply();

      expect(adapter.applyCalls, hasLength(1));
      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet['id'], 1);
      expect(dataSet['name'], 'Duplicate');
      expect(dataSet.hasUpdates, isTrue);
      expect(dataSet.errors.messages.isNotEmpty, isTrue);
      expect(errors, hasLength(1));
      expect(errors.single.single.message, 'Insert failed: duplicate key.');
    },
  );

  test('immediate update mode maps thrown adapter apply errors', () async {
    final adapter = _RecordingAdapter(<Map<String, Object?>>[
      <String, Object?>{'id': 1, 'name': 'Alpha'},
    ])..throwNextApply = true;
    final errors = <List<FdcDataSetError>>[];
    final dataSet = _createDataSet(
      adapter,
      onError: (dataSet, items, cause) => errors.add(items),
    );

    await dataSet.open();
    dataSet.append();
    dataSet['id'] = 1;
    dataSet['name'] = 'Duplicate';
    dataSet.post();

    await _drainImmediateApply();

    expect(dataSet.hasUpdates, isTrue);
    expect(dataSet.recordCount, 2);
    expect(dataSet.errors.messages.isNotEmpty, isTrue);
    expect(errors, hasLength(1));
    expect(
      errors.single.single.message,
      'insert mapped: Bad state: backend exploded',
    );
    expect(errors.single.single.code, 'mapped_insert');
  });

  test(
    'immediate update mode does not post pristine auto-append row',
    () async {
      final adapter = _RecordingAdapter(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ]);
      final dataSet = _createDataSet(adapter);

      await dataSet.open();
      dataSet.edit();
      dataSet['name'] = 'Beta';
      dataSet.post();

      expect(dataSet.state, FdcDataSetState.browse);

      await _drainImmediateApply();

      expect(dataSet.state, FdcDataSetState.browse);
      dataSet.append();
      expect(dataSet.state, FdcDataSetState.insert);
      expect(adapter.applyCalls, hasLength(1));
      expect(adapter.applyCalls.single.updates, hasLength(1));
      expect(adapter.applyCalls.single.inserts, isEmpty);
      expect(adapter.applyCalls.single.updates.single.values['name'], 'Beta');
      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet['id'], isNull);
      expect(dataSet['name'], isNull);
    },
  );

  test(
    'immediate update mode failed post keeps the original edit buffer active',
    () async {
      final adapter = _RecordingAdapter(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ])..failNextApply = true;
      final dataSet = _createDataSet(adapter);

      await dataSet.open();
      dataSet.edit();
      dataSet['name'] = 'Beta';
      dataSet.post();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet['id'], 1);
      expect(dataSet['name'], 'Beta');

      await _drainImmediateApply();

      expect(adapter.applyCalls, hasLength(1));
      expect(adapter.applyCalls.single.updates, hasLength(1));
      expect(adapter.applyCalls.single.updates.single.recordId, 1);
      expect(dataSet.hasUpdates, isTrue);
      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet['id'], 1);
      expect(dataSet['name'], 'Beta');
    },
  );

  test(
    'immediate update mode applies server values before a new append starts',
    () async {
      final adapter = _RecordingAdapter(<Map<String, Object?>>[])
        ..nextInsertServerRows[1] = <String, Object?>{'id': 1001};
      final dataSet = _createDataSet(adapter);

      await dataSet.open();
      dataSet.append();
      dataSet['name'] = 'Beta';
      dataSet.post();

      expect(dataSet.state, FdcDataSetState.browse);

      await _drainImmediateApply();

      expect(adapter.applyCalls, hasLength(1));
      expect(adapter.applyCalls.single.inserts, hasLength(1));
      expect(adapter.applyCalls.single.inserts.single.values['name'], 'Beta');
      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 1);
      expect(dataSet['id'], 1001);
      expect(dataSet['name'], 'Beta');
      expect(dataSet.hasUpdates, isFalse);

      dataSet.append();
      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet.recordCount, 2);
      expect(dataSet['id'], isNull);
      expect(dataSet['name'], isNull);
    },
  );

  test('cached update mode keeps posted edits local', () async {
    final adapter = _RecordingAdapter(<Map<String, Object?>>[
      <String, Object?>{'id': 1, 'name': 'Alpha'},
    ]);
    final dataSet = _createDataSet(
      adapter,
      updateMode: FdcUpdateMode.cachedUpdates,
    );

    await dataSet.open();
    dataSet.edit();
    dataSet['name'] = 'Beta';
    dataSet.post();

    await _drainImmediateApply();

    expect(adapter.applyCalls, isEmpty);
    expect(dataSet.hasUpdates, isTrue);
  });
}

FdcDataSet _createDataSet(
  _RecordingAdapter adapter, {
  FdcUpdateMode updateMode = FdcUpdateMode.immediate,
  FdcDataSetErrorEvent? onError,
}) {
  return FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(name: 'name', size: 80),
    ],
    updateMode: updateMode,
    adapter: adapter,
    onError: onError,
  );
}

Future<void> _drainImmediateApply() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.value();
  }
}

class _RecordingAdapter implements IFdcDataAdapter {
  _RecordingAdapter(this.rows);

  final List<Map<String, Object?>> rows;
  final List<FdcChangeSet> applyCalls = <FdcChangeSet>[];
  final Map<int, Map<String, Object?>> nextInsertServerRows =
      <int, Map<String, Object?>>{};
  Completer<void>? applyGate;
  Completer<void>? applyStarted;
  bool failNextApply = false;
  bool throwNextApply = false;

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
      message: '${operation.name} mapped: $error',
      code: 'mapped_${operation.name}',
    );
  }

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    return FdcDataLoadResult(rows: rows);
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    applyCalls.add(changes);
    final started = applyStarted;
    if (started != null && !started.isCompleted) {
      started.complete();
    }
    final gate = applyGate;
    if (gate != null) {
      await gate.future;
    }
    if (throwNextApply) {
      throwNextApply = false;
      throw StateError('backend exploded');
    }
    if (failNextApply) {
      failNextApply = false;
      return FdcDataApplyResult.failure(
        errors: <FdcDataApplyError>[
          FdcDataApplyError(
            recordId: changes.inserts.isNotEmpty
                ? changes.inserts.first.recordId
                : changes.updates.isNotEmpty
                ? changes.updates.first.recordId
                : changes.deletes.first.recordId,
            code: 'duplicate',
            message: 'Insert failed: duplicate key.',
          ),
        ],
      );
    }
    final serverRows = <int, Map<String, Object?>>{};
    for (final insert in changes.inserts) {
      final row = nextInsertServerRows[insert.recordId];
      if (row != null) {
        serverRows[insert.recordId] = row;
      }
    }
    return FdcDataApplyResult.success(serverRows: serverRows);
  }
}
