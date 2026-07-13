import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'paged selected false deducts total even when selected row is off page',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id', isKey: true)],
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            for (var i = 1; i <= 25; i++) <String, Object?>{'id': i},
          ],
        ),
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      await dataSet.paging.nextPage();
      dataSet.selection.setSelectedAt(4, true); // id 15

      await dataSet.paging.firstPage();
      await dataSet.filter.selected(false).apply();

      expect(dataSet.paging.pageIndex, 0);
      expect(dataSet.recordCount, 10);
      expect(dataSet.paging.totalRecordCount, 24);
      expect(dataSet.paging.pageCount, 3);
      expect(dataSet['id'], 1);
    },
  );

  test(
    'paged selected true with no selected keys returns empty result',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id', isKey: true)],
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            for (var i = 1; i <= 5; i++) <String, Object?>{'id': i},
          ],
        ),
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      await dataSet.filter.selected(true).apply();

      expect(dataSet.recordCount, 0);
      expect(dataSet.paging.totalRecordCount, 0);
      expect(dataSet.paging.pageCount, 0);
    },
  );

  test(
    'paged delete removes selected key before selected-key filtering',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id', isKey: true)],
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            for (var i = 1; i <= 5; i++) <String, Object?>{'id': i},
          ],
        ),
        updateMode: FdcUpdateMode.cachedUpdates,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      dataSet.selection.setSelectedAt(0, true);
      dataSet.delete();
      await dataSet.filter.selected(true).apply();

      expect(dataSet.recordCount, 0);
      expect(dataSet.paging.totalRecordCount, 0);
    },
  );

  test(
    'paged selected false calculates aggregates from the visible local view',
    () async {
      final adapter = _AggregateRecordingPagedAdapter();
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', isKey: true),
          FdcDecimalField(name: 'amount', precision: 18, scale: 2),
        ],
        adapter: adapter,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      await dataSet.filter.selected(false).apply();
      final result = await dataSet.aggregates.calculate(const <
        FdcDataAggregateItem
      >[
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.sum),
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.avg),
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.min),
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.max),
      ]);

      expect(adapter.aggregateCallCount, 0);
      expect(
        result.valueFor('amount', FdcAggregate.sum),
        FdcDecimal.parse('100.00'),
      );
      expect(
        result.valueFor('amount', FdcAggregate.avg),
        FdcDecimal.parse('100.00'),
      );
      expect(
        result.valueFor('amount', FdcAggregate.min),
        FdcDecimal.parse('100.00'),
      );
      expect(
        result.valueFor('amount', FdcAggregate.max),
        FdcDecimal.parse('100.00'),
      );
    },
  );

  test(
    'paged selected true forwards selected keys to aggregate requests',
    () async {
      final adapter = _AggregateRecordingPagedAdapter();
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', isKey: true),
          FdcDecimalField(name: 'amount', precision: 18, scale: 2),
        ],
        adapter: adapter,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      dataSet.selection.setSelectedAt(0, true);
      await dataSet.filter.selected(true).apply();
      await dataSet.aggregates.calculate(const <FdcDataAggregateItem>[
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.sum),
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.avg),
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.min),
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.max),
      ]);

      expect(adapter.aggregateCallCount, 1);
      expect(adapter.lastAggregateRequest, isNotNull);
      expect(adapter.lastAggregateRequest!.selectedKeysOnly, isTrue);
      expect(adapter.lastAggregateRequest!.selectedKeys, hasLength(1));
      expect(
        adapter.lastAggregateRequest!.selectedKeys.single.toMap(),
        <String, Object?>{'id': 1},
      );
    },
  );

  test(
    'paged selection changes invalidate active selected-filter aggregates',
    () async {
      final adapter = _AggregateRecordingPagedAdapter();
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', isKey: true),
          FdcDecimalField(name: 'amount', precision: 18, scale: 2),
        ],
        adapter: adapter,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      dataSet.selection.setSelectedAt(0, true);
      await dataSet.filter.selected(true).apply();
      await dataSet.aggregates.calculate(const <FdcDataAggregateItem>[
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.sum),
      ]);

      expect(adapter.aggregateCallCount, 1);
      final signature = FdcDataSetInternal.aggregateQuerySignature(dataSet);

      dataSet.selection.setSelectedAt(0, false);

      expect(
        FdcDataSetInternal.aggregateQuerySignature(dataSet),
        isNot(signature),
      );
      await dataSet.aggregates.calculate(const <FdcDataAggregateItem>[
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.sum),
      ]);
      expect(adapter.aggregateCallCount, 2);
      expect(adapter.lastAggregateRequest!.selectedKeys, isEmpty);
    },
  );
}

class _AggregateRecordingPagedAdapter extends FdcDataAdapter {
  _AggregateRecordingPagedAdapter({
    super.readOnly = true,
    bool withFilter = false,
  }) : super(
         filters: withFilter
             ? const <FdcDataAdapterFilter>[
                 FdcDataAdapterFilter.equals('status', 'open'),
               ]
             : const <FdcDataAdapterFilter>[],
         capabilities: const FdcDataAdapterCapabilities(
           filtering: true,
           paging: true,
           totalCount: true,
           search: true,
           aggregates: true,
           selectedKeyFiltering: true,
         ),
       );

  static FdcDataAggregateResult sumResult() {
    return FdcDataAggregateResult(
      values: <FdcDataAggregateKey, Object?>{
        const FdcDataAggregateKey(
          fieldName: 'amount',
          aggregate: FdcAggregate.sum,
        ): FdcDecimal.parse(
          '300.00',
        ),
      },
    );
  }

  FdcDataLoadRequest? lastLoadRequest;
  FdcDataAggregateRequest? lastAggregateRequest;
  int aggregateCallCount = 0;

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    lastLoadRequest = request;
    return const FdcDataLoadResult(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'status': 'open', 'amount': '100.00'},
      ],
      totalCount: 30,
    );
  }

  @override
  Future<FdcDataAggregateResult> aggregate(
    FdcDataAggregateRequest request,
  ) async {
    aggregateCallCount++;
    lastAggregateRequest = request;
    return sumResult();
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
    return FdcDataApplyError(recordId: entry.recordId, message: '$error');
  }

  @override
  String? validateStorageValue(FdcFieldDef field, Object? value) => null;
}
