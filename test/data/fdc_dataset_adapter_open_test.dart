import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('open resolves rows from the configured memory adapter', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(name: 'name', size: 50),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Alpha'},
          <String, Object?>{'id': 2, 'name': 'Beta'},
        ],
      ),
    );

    await dataSet.open();

    expect(dataSet.isOpen, isTrue);
    expect(dataSet.recordCount, 2);
    expect(dataSet['name'], 'Alpha');
  });

  test('memory adapter rows can be replaced before reopening', () async {
    final adapter = FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ],
    );
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(name: 'name', size: 50),
      ],
      adapter: adapter,
    );

    await dataSet.open();
    expect(dataSet['name'], 'Alpha');

    adapter.replaceRows(const <Map<String, Object?>>[
      <String, Object?>{'id': 2, 'name': 'Beta'},
    ]);
    await dataSet.open();

    expect(dataSet.recordCount, 1);
    expect(dataSet['name'], 'Beta');
  });

  test('open awaits asynchronous adapters', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(name: 'name', size: 50),
      ],
      adapter: _AsyncAdapter(),
    );

    await dataSet.open();

    expect(dataSet.isOpen, isTrue);
    expect(dataSet.recordCount, 1);
    expect(dataSet['name'], 'Async');
  });
}

class _AsyncAdapter implements IFdcDataAdapter {
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
    await Future<void>.delayed(Duration.zero);
    return const FdcDataLoadResult(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Async'},
      ],
    );
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async =>
      const FdcDataApplyResult.success();
}
