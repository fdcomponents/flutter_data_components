import 'dart:async';

import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loadRows completion is ignored after dataset dispose', () async {
    final rowsCompleter = Completer<List<Map<String, Object?>>>();
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(name: 'name', size: 50),
      ],
    );

    final loadFuture = dataSet.loadRows(rowsCompleter.future);
    expect(dataSet.state, FdcDataSetState.loading);

    dataSet.dispose();
    final stateAfterDispose = dataSet.state;

    rowsCompleter.complete(<Map<String, Object?>>[
      <String, Object?>{'id': 1, 'name': 'Late row'},
    ]);

    await expectLater(loadFuture, completes);
    expect(dataSet.state, stateAfterDispose);
    expect(dataSet.recordCount, 0);
  });
  testWidgets(
    'search body is skipped when dataset is disposed during reported-work yield',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'name', size: 50),
        ],
      );
      dataSet.loadRows(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ]);

      final searchFuture = dataSet.search.apply('Alpha');
      dataSet.dispose();
      await tester.pump();

      await expectLater(searchFuture, completes);
      expect(dataSet.recordCount, 1);
    },
  );

  test('late apply failure is ignored after dataset dispose', () async {
    final adapter = _DelayedFailingApplyAdapter();
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id', isKey: true),
        FdcStringField(name: 'name', size: 50),
      ],
      updateMode: FdcUpdateMode.cachedUpdates,
      adapter: adapter,
    );

    await dataSet.open();
    dataSet.edit();
    dataSet['name'] = 'Beta';
    dataSet.post();

    final applyFuture = dataSet.applyUpdates();
    dataSet.dispose();
    final stateAfterDispose = dataSet.state;
    final errorsAfterDispose = dataSet.errors;
    adapter.applyCompleter.completeError(StateError('late failure'));

    final result = await applyFuture;
    expect(result.success, isFalse);
    expect(dataSet.state, stateAfterDispose);
    expect(dataSet.errors, same(errorsAfterDispose));
  });
}

class _DelayedFailingApplyAdapter implements IFdcDataAdapter {
  final Completer<FdcDataApplyResult> applyCompleter =
      Completer<FdcDataApplyResult>();

  @override
  bool get readOnly => false;

  @override
  FdcDataAdapterCapabilities get capabilities =>
      const FdcDataAdapterCapabilities.none();

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    return const FdcDataLoadResult(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ],
    );
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) =>
      applyCompleter.future;

  @override
  Future<FdcDataAggregateResult> aggregate(
    FdcDataAggregateRequest request,
  ) async {
    throw UnsupportedError('aggregate');
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
      code: 'delayed_failure',
      message: error.toString(),
    );
  }

  void dispose() {}
}
