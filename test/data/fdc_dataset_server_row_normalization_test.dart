import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'applyUpdates normalizes serverRows before storing record values',
    () async {
      final adapter = _ServerRowAdapter(
        serverRowForRecord: (recordId) => <String, Object?>{
          'name': 'Server Alpha',
          'active': 1,
          'amount': '25.50',
          'date': '2026-06-08',
          'createdAt': '2026-06-08T09:10:11',
          'time': '12:34:56',
          'guid': '00112233-4455-6677-8899-aabbccddeeff',
        },
      );

      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', isKey: true),
          FdcStringField(name: 'name', size: 80),
          FdcBooleanField(name: 'active'),
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          FdcDateField(name: 'date'),
          FdcDateTimeField(name: 'createdAt'),
          FdcTimeField(name: 'time'),
          FdcGuidField(name: 'guid'),
        ],
        updateMode: FdcUpdateMode.cachedUpdates,
        adapter: adapter,
      );

      await dataSet.open();
      dataSet.edit();
      dataSet['name'] = 'Client Alpha';
      dataSet.post();

      final result = await dataSet.applyUpdates();

      expect(result.success, isTrue);
      expect(dataSet['name'], 'Server Alpha');
      expect(dataSet['active'], isTrue);
      expect(dataSet['amount'], '25.50'.decimal);
      expect(dataSet['date'], DateTime(2026, 6, 8));
      expect(dataSet['createdAt'], DateTime(2026, 6, 8, 9, 10, 11));
      expect(dataSet['time'], FdcTime(hour: 12, minute: 34, second: 56));
      expect(
        dataSet['guid'],
        FdcGuid.parse('00112233-4455-6677-8899-aabbccddeeff'),
      );
    },
  );

  test('dataset write API blocks storage read-only fields', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(
          name: 'id',
          isKey: true,
          storage: FdcFieldStorage(generated: true),
        ),
        FdcStringField(name: 'name', size: 80),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Alpha'},
        ],
      ),
    );

    await dataSet.open();
    dataSet.edit();

    expect(() => dataSet['id'] = 2, throwsStateError);
  });
}

class _ServerRowAdapter implements IFdcDataAdapter {
  const _ServerRowAdapter({required this.serverRowForRecord});

  final Map<String, Object?> Function(int recordId) serverRowForRecord;

  @override
  bool get readOnly => false;

  @override
  FdcDataAdapterCapabilities get capabilities =>
      const FdcDataAdapterCapabilities.none();

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    return const FdcDataLoadResult(
      rows: <Map<String, Object?>>[
        <String, Object?>{
          'id': 1,
          'name': 'Alpha',
          'active': false,
          'amount': '12.30',
          'date': '2026-06-01',
          'createdAt': '2026-06-01T08:00:00',
          'time': '08:00:00',
          'guid': '11111111-1111-1111-1111-111111111111',
        },
      ],
    );
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    final recordIds = <int>{
      for (final update in changes.updates) update.recordId,
      for (final insert in changes.inserts) insert.recordId,
    };
    return FdcDataApplyResult.success(
      serverRows: <int, Map<String, Object?>>{
        for (final recordId in recordIds)
          recordId: serverRowForRecord(recordId),
      },
    );
  }

  @override
  FdcDataApplyError mapApplyException(
    FdcChangeSetEntry entry,
    Object error, {
    required FdcDataApplyOperation operation,
  }) {
    return FdcDataApplyError(recordId: entry.recordId, message: '$error');
  }

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
}
