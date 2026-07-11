import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'open adopts adapter fields when dataset fields are not defined',
    () async {
      final dataSet = FdcDataSet(adapter: _SchemaDataAdapter());

      expect(dataSet.fieldCount, 0);

      await dataSet.open();

      expect(dataSet.fieldCount, 2);
      expect(dataSet.fieldNames, const <String>['id', 'name']);
      expect(dataSet.fieldDef<FdcIntegerField>('id').name, 'id');
      expect(dataSet.fieldDef<FdcStringField>('name').size, 80);
      expect(dataSet.fields.where((field) => field.isKey).single.name, 'id');
      expect(dataSet.recordCount, 1);
      expect(dataSet['id'], 1);
      expect(dataSet['name'], 'Alice');
    },
  );

  test('explicit dataset fields adopt compatible adapter key fields', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id', isKey: true),
        FdcStringField(name: 'name', size: 25),
      ],
      adapter: _SchemaDataAdapter(),
    );

    await dataSet.open();

    expect(dataSet.fieldNames, const <String>['id', 'name']);
    expect(dataSet.fields.where((field) => field.isKey).single.name, 'id');
    expect(dataSet['id'], 1);
    expect(dataSet['name'], 'Alice');
  });

  test('explicit dataset fields win over adapter fields', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 25)],
      adapter: _SchemaDataAdapter(),
    );

    await dataSet.open();

    expect(dataSet.fieldCount, 1);
    expect(dataSet.fieldNames, const <String>['name']);
    expect(dataSet.fieldDef<FdcStringField>('name').size, 25);
    expect(dataSet.fields.where((field) => field.isKey), isEmpty);
    expect(dataSet['name'], 'Alice');
  });
}

class _SchemaDataAdapter implements IFdcDataAdapter {
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
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async =>
      loadSync(request);

  FdcDataLoadResult loadSync(FdcDataLoadRequest request) {
    return const FdcDataLoadResult(
      fields: <FdcFieldDef>[
        FdcIntegerField(
          name: 'id',
          isKey: true,
          storage: FdcFieldStorage(generated: true),
        ),
        FdcStringField(name: 'name', size: 80),
      ],
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alice'},
      ],
      totalCount: 1,
    );
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    return const FdcDataApplyResult.success();
  }
}
