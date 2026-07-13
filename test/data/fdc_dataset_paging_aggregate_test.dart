import 'dart:async';

import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'paged dataset aggregate query signature ignores page navigation',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcDecimalField(name: 'amount', precision: 18, scale: 2),
        ],
        adapter: _AggregateRecordingPagedAdapter(),
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      final firstSignature = FdcDataSetInternal.aggregateQuerySignature(
        dataSet,
      );

      await dataSet.paging.nextPage();
      final secondSignature = FdcDataSetInternal.aggregateQuerySignature(
        dataSet,
      );

      expect(secondSignature, firstSignature);
    },
  );

  test(
    'paged dataset internal view refresh without retained rows keeps adapter aggregate cache',
    () async {
      final adapter = _AggregateRecordingPagedAdapter();
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcDecimalField(name: 'amount', precision: 18, scale: 2),
        ],
        adapter: adapter,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      await dataSet.aggregates.calculate(const <FdcDataAggregateItem>[
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.sum),
      ]);
      expect(adapter.aggregateCallCount, 1);
      final firstSignature = FdcDataSetInternal.aggregateQuerySignature(
        dataSet,
      );

      FdcDataSetInternal.setViewState(
        dataSet,
        clearRetainedVisibleRecords: true,
        notify: false,
      );

      expect(
        FdcDataSetInternal.aggregateQuerySignature(dataSet),
        firstSignature,
      );
      await dataSet.aggregates.calculate(const <FdcDataAggregateItem>[
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.sum),
      ]);
      expect(adapter.aggregateCallCount, 1);
    },
  );

  test(
    'paged dataset aggregate delegates to adapter without page limits',
    () async {
      final adapter = _AggregateRecordingPagedAdapter();
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcDecimalField(name: 'amount', precision: 18, scale: 2),
        ],
        adapter: adapter,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      final result = await dataSet.aggregates.calculate(
        const <FdcDataAggregateItem>[
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.sum,
          ),
        ],
      );

      expect(adapter.lastAggregateRequest, isNotNull);
      expect(adapter.lastLoadRequest!.limit, 10);
      expect(adapter.lastAggregateRequest!.aggregates, hasLength(1));
      expect(
        result.valueFor('amount', FdcAggregate.sum),
        FdcDecimal.parse('300.00'),
      );
    },
  );

  test(
    'paged dataset keeps adapter aggregate cache while append is unposted',
    () async {
      final adapter = _AggregateRecordingPagedAdapter(readOnly: false);
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcDecimalField(name: 'amount', precision: 18, scale: 2),
        ],
        adapter: adapter,
        updateMode: FdcUpdateMode.cachedUpdates,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      final initial = await dataSet.aggregates.calculate(
        const <FdcDataAggregateItem>[
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.sum,
          ),
        ],
      );
      expect(
        initial.valueFor('amount', FdcAggregate.sum),
        FdcDecimal.parse('300.00'),
      );
      expect(adapter.aggregateCallCount, 1);

      dataSet.append();
      dataSet['amount'] = FdcDecimal.parse('999.00');

      final whileAppending = await dataSet.aggregates.calculate(
        const <FdcDataAggregateItem>[
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.sum,
          ),
        ],
      );
      expect(
        whileAppending.valueFor('amount', FdcAggregate.sum),
        FdcDecimal.parse('300.00'),
      );
      expect(adapter.aggregateCallCount, 1);

      dataSet.cancel();
    },
  );

  test(
    'paged dataset invalidates cached aggregates after successful apply',
    () async {
      final adapter = _AggregateRecordingPagedAdapter(readOnly: false);
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'code', size: 20),
          FdcDecimalField(name: 'amount', precision: 18, scale: 2),
        ],
        adapter: adapter,
        updateMode: FdcUpdateMode.cachedUpdates,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      final initial = await dataSet.aggregates.calculate(
        const <FdcDataAggregateItem>[
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.sum,
          ),
        ],
      );
      expect(
        initial.valueFor('amount', FdcAggregate.sum),
        FdcDecimal.parse('300.00'),
      );
      expect(adapter.aggregateCallCount, 1);

      dataSet.edit();
      dataSet['code'] = 'A-001';

      final duringEdit = await dataSet.aggregates.calculate(
        const <FdcDataAggregateItem>[
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.sum,
          ),
        ],
      );
      expect(
        duringEdit.valueFor('amount', FdcAggregate.sum),
        FdcDecimal.parse('300.00'),
      );
      expect(adapter.aggregateCallCount, 1);

      dataSet.post();
      await dataSet.applyUpdates();

      await dataSet.aggregates.calculate(const <FdcDataAggregateItem>[
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.sum),
      ]);
      expect(adapter.aggregateCallCount, 2);
    },
  );

  test(
    'paged dataset discards stale in-flight aggregate after successful apply',
    () async {
      final aggregateGate = Completer<FdcDataAggregateResult>();
      final adapter = _AggregateRecordingPagedAdapter(
        readOnly: false,
        aggregateGate: aggregateGate,
      );
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'code', size: 20),
          FdcDecimalField(name: 'amount', precision: 18, scale: 2),
        ],
        adapter: adapter,
        updateMode: FdcUpdateMode.cachedUpdates,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      final aggregateFuture = dataSet.aggregates.calculate(
        const <FdcDataAggregateItem>[
          FdcDataAggregateItem(
            fieldName: 'amount',
            aggregate: FdcAggregate.sum,
          ),
        ],
      );
      await Future<void>.delayed(Duration.zero);
      expect(adapter.aggregateCallCount, 1);

      dataSet.edit();
      dataSet['code'] = 'A-002';
      dataSet.post();
      await dataSet.applyUpdates();

      aggregateGate.complete(_AggregateRecordingPagedAdapter.sumResult());
      await aggregateFuture;

      await dataSet.aggregates.calculate(const <FdcDataAggregateItem>[
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.sum),
      ]);
      expect(adapter.aggregateCallCount, 2);
    },
  );

  test(
    'paged dataset invalidates cached aggregates when apply returns server rows',
    () async {
      final adapter = _AggregateRecordingPagedAdapter(
        readOnly: false,
        returnServerRows: true,
      );
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', isKey: true),
          FdcDecimalField(name: 'amount', precision: 18, scale: 2),
        ],
        adapter: adapter,
        updateMode: FdcUpdateMode.cachedUpdates,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      await dataSet.aggregates.calculate(const <FdcDataAggregateItem>[
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.sum),
      ]);
      expect(adapter.aggregateCallCount, 1);

      dataSet.edit();
      dataSet['amount'] = FdcDecimal.parse('150.00');
      dataSet.post();
      await dataSet.applyUpdates();

      await dataSet.aggregates.calculate(const <FdcDataAggregateItem>[
        FdcDataAggregateItem(fieldName: 'amount', aggregate: FdcAggregate.sum),
      ]);
      expect(adapter.aggregateCallCount, 2);
    },
  );

  test(
    'paged dataset invalidates total count after apply with active adapter filters',
    () async {
      final adapter = _AggregateRecordingPagedAdapter(
        readOnly: false,
        withFilter: true,
      );
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', isKey: true),
          FdcStringField(name: 'status', size: 20),
          FdcDecimalField(name: 'amount', precision: 18, scale: 2),
        ],
        adapter: adapter,
        updateMode: FdcUpdateMode.cachedUpdates,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      expect(dataSet.paging.totalRecordCount, 30);

      dataSet.edit();
      dataSet['amount'] = FdcDecimal.parse('150.00');
      dataSet.post();
      await dataSet.applyUpdates();

      expect(dataSet.paging.totalRecordCount, isNull);
    },
  );

  test(
    'paged dataset invalidates total count after apply with active search',
    () async {
      final adapter = _AggregateRecordingPagedAdapter(readOnly: false);
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', isKey: true),
          FdcStringField(name: 'status', size: 20),
          FdcDecimalField(name: 'amount', precision: 18, scale: 2),
        ],
        adapter: adapter,
        updateMode: FdcUpdateMode.cachedUpdates,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );
      await dataSet.open();
      await dataSet.search.apply('open', fields: const <String>['status']);
      expect(dataSet.paging.totalRecordCount, 30);
      dataSet.edit();
      dataSet['amount'] = FdcDecimal.parse('150.00');
      dataSet.post();
      await dataSet.applyUpdates();
      expect(dataSet.paging.totalRecordCount, isNull);
    },
  );
}

class _AggregateRecordingPagedAdapter extends FdcDataAdapter {
  _AggregateRecordingPagedAdapter({
    super.readOnly = true,
    this.returnServerRows = false,
    this.aggregateGate,
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

  final bool returnServerRows;
  final Completer<FdcDataAggregateResult>? aggregateGate;

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
    final gate = aggregateGate;
    if (gate != null) {
      return gate.future;
    }
    return sumResult();
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    if (!returnServerRows || changes.updates.isEmpty) {
      return const FdcDataApplyResult.success();
    }
    final update = changes.updates.first;
    return FdcDataApplyResult.success(
      serverRows: <int, Map<String, Object?>>{
        update.recordId: <String, Object?>{
          'id': 1,
          'status': 'open',
          'amount': '175.00',
        },
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
  String? validateStorageValue(FdcFieldDef field, Object? value) => null;
}
