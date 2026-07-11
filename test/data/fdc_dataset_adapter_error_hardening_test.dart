import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('open normalizes plain adapter load exceptions', () async {
    final errorLog = <List<FdcDataSetError>>[];
    final causes = <Object?>[];
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id', isKey: true),
        FdcStringField(name: 'name', size: 80),
      ],
      adapter: _ThrowingLoadAdapter(),
      onError: (dataSet, errors, cause) {
        errorLog.add(errors);
        causes.add(cause);
      },
    );

    await expectLater(
      dataSet.open(),
      throwsA(
        isA<FdcDataAdapterException>().having(
          (error) => error.message,
          'message',
          'backend load exploded',
        ),
      ),
    );

    expect(dataSet.state, FdcDataSetState.closed);
    expect(dataSet.errors.messages.isNotEmpty, isTrue);
    expect(errorLog, hasLength(1));
    expect(errorLog.single.single.message, 'backend load exploded');
    expect(errorLog.single.single.code, 'adapter_error');
    expect(causes.single, isA<FdcDataAdapterException>());
  });

  test(
    'applyUpdates normalizes thrown adapter errors even when mapper fails',
    () async {
      final errorLog = <List<FdcDataSetError>>[];
      final causes = <Object?>[];
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', isKey: true),
          FdcStringField(name: 'name', size: 80),
        ],
        updateMode: FdcUpdateMode.cachedUpdates,
        adapter: _ThrowingApplyAdapter(),
        onError: (dataSet, errors, cause) {
          errorLog.add(errors);
          causes.add(cause);
        },
      );

      await dataSet.open();
      dataSet.edit();
      dataSet['name'] = 'Beta';
      dataSet.post();

      final result = await dataSet.applyUpdates();

      expect(result.success, isFalse);
      expect(result.errors, hasLength(1));
      expect(result.errors.single.message, 'backend apply exploded');
      expect(result.errors.single.code, 'adapter_error');
      expect(dataSet.hasUpdates, isTrue);
      expect(dataSet.errors.messages.isNotEmpty, isTrue);
      expect(errorLog, hasLength(1));
      expect(errorLog.single.single.message, 'backend apply exploded');
      expect(errorLog.single.single.code, 'adapter_error');
      expect(errorLog.single.single.cause, isA<FdcDataAdapterException>());
      expect(causes.single, isA<FdcDataAdapterException>());
    },
  );

  test('adapter exceptions preserve field and code context', () async {
    final errorLog = <List<FdcDataSetError>>[];
    final causes = <Object?>[];
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id', isKey: true),
        FdcStringField(name: 'name', size: 80),
      ],
      updateMode: FdcUpdateMode.cachedUpdates,
      adapter: _TypedApplyErrorAdapter(),
      onError: (dataSet, errors, cause) {
        errorLog.add(errors);
        causes.add(cause);
      },
    );

    await dataSet.open();
    dataSet.edit();
    dataSet['name'] = 'Beta';
    dataSet.post();

    final result = await dataSet.applyUpdates();

    expect(result.success, isFalse);
    expect(result.errors.single.message, 'Name is rejected.');
    expect(result.errors.single.fieldName, 'name');
    expect(result.errors.single.code, 'name_rejected');
    expect(errorLog, hasLength(1));
    expect(errorLog.single.single.message, 'Name is rejected.');
    expect(errorLog.single.single.fieldName, 'name');
    expect(errorLog.single.single.code, 'name_rejected');
    expect(causes.single, isA<FdcDataAdapterException>());
  });
}

class _ThrowingLoadAdapter extends _BaseAdapter {
  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    throw Exception('backend load exploded');
  }
}

class _ThrowingApplyAdapter extends _BaseAdapter {
  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    throw Exception('backend apply exploded');
  }

  @override
  FdcDataApplyError mapApplyException(
    FdcChangeSetEntry entry,
    Object error, {
    required FdcDataApplyOperation operation,
  }) {
    throw StateError('mapper should not be trusted');
  }
}

class _TypedApplyErrorAdapter extends _BaseAdapter {
  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    throw FdcDataAdapterException(
      operation: 'update',
      recordId: changes.updates.single.recordId,
      fieldName: 'name',
      code: 'name_rejected',
      message: 'Name is rejected.',
    );
  }
}

abstract class _BaseAdapter implements IFdcDataAdapter {
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
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    return const FdcDataLoadResult(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ],
    );
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    return const FdcDataApplyResult.success();
  }

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
}
