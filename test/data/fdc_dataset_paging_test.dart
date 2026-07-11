import 'dart:async';

import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('paged dataset open loads the first adapter page', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(name: 'name', size: 50),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          for (var i = 1; i <= 25; i++)
            <String, Object?>{'id': i, 'name': 'Name $i'},
        ],
      ),
      paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
    );

    await dataSet.open();

    expect(dataSet.paging.enabled, isTrue);
    expect(dataSet.paging.pageIndex, 0);
    expect(dataSet.paging.pageSize, 10);
    expect(dataSet.paging.pageOffset, 0);
    expect(dataSet.recordCount, 10);
    expect(dataSet.paging.pageRecordCount, 10);
    expect(dataSet.paging.totalRecordCount, 25);
    expect(dataSet.paging.pageCount, 3);
    expect(dataSet.paging.hasPriorPage, isFalse);
    expect(dataSet.paging.hasNextPage, isTrue);
    expect(dataSet['id'], 1);
  });

  test(
    'paged dataset forwards opaque cursors for sequential navigation',
    () async {
      final adapter = _RecordingPagedAdapter();
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
        adapter: adapter,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      await dataSet.paging.nextPage();

      expect(adapter.lastRequest?.pageNavigation, FdcDataPageNavigation.next);
      expect(adapter.lastRequest?.pageCursor, 'next-0');

      await dataSet.paging.priorPage();
      expect(
        adapter.lastRequest?.pageNavigation,
        FdcDataPageNavigation.previous,
      );
      expect(adapter.lastRequest?.pageCursor, 'previous-10');
    },
  );

  test(
    'paged dataset validates offset and limit before adapter load',
    () async {
      final adapter = _RecordingPagedAdapter();
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
        adapter: adapter,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await expectLater(
        dataSet.open(request: const FdcDataLoadRequest(offset: -1, limit: 10)),
        throwsArgumentError,
      );
      expect(adapter.loadCount, 0);

      await expectLater(
        dataSet.open(request: const FdcDataLoadRequest(offset: 0, limit: 0)),
        throwsArgumentError,
      );
      expect(adapter.loadCount, 0);
    },
  );

  test('paged dataset open requires offset aligned to limit', () async {
    final adapter = _RecordingPagedAdapter();
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      adapter: adapter,
      paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
    );

    await expectLater(
      dataSet.open(request: const FdcDataLoadRequest(offset: 5, limit: 10)),
      throwsArgumentError,
    );
    expect(adapter.loadCount, 0);
  });

  test(
    'paged dataset open maps aligned offset request to page index',
    () async {
      final adapter = _RecordingPagedAdapter();
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
        adapter: adapter,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open(
        request: const FdcDataLoadRequest(offset: 20, limit: 10),
      );

      expect(dataSet.paging.pageIndex, 2);
      expect(dataSet.paging.pageSize, 10);
      expect(dataSet.paging.pageOffset, 20);
      expect(adapter.loadCount, 1);
      expect(adapter.lastRequest?.offset, 20);
      expect(adapter.lastRequest?.limit, 10);
    },
  );

  test('paged dataset navigation loads adapter pages', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          for (var i = 1; i <= 25; i++) <String, Object?>{'id': i},
        ],
      ),
      paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
    );

    await dataSet.open();
    await dataSet.paging.nextPage();

    expect(dataSet.paging.pageIndex, 1);
    expect(dataSet.paging.pageOffset, 10);
    expect(dataSet.recordCount, 10);
    expect(dataSet['id'], 11);

    await dataSet.paging.lastPage();

    expect(dataSet.paging.pageIndex, 2);
    expect(dataSet.recordCount, 5);
    expect(dataSet.paging.hasNextPage, isFalse);
    expect(dataSet['id'], 21);
  });

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

  test(
    'paged dataset sort resets to first page and uses adapter ordering',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            for (var i = 1; i <= 12; i++) <String, Object?>{'id': i},
          ],
        ),
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 5),
      );

      await dataSet.open();
      await dataSet.paging.nextPage();
      await dataSet.sort.set(const <FdcDataSetSort>[
        FdcDataSetSort(fieldName: 'id', sortType: FdcSortType.descending),
      ]);

      expect(dataSet.paging.pageIndex, 0);
      expect(dataSet.recordCount, 5);
      expect(dataSet['id'], 12);
    },
  );

  test(
    'paged dataset keeps adapter page authoritative after filtering',
    () async {
      final adapter = _AuthoritativePagedAdapter();
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'name', size: 50),
        ],
        adapter: adapter,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      await dataSet.filter.where('name').equals('Missing').apply();

      expect(adapter.lastRequest?.filters, hasLength(1));
      expect(dataSet.recordCount, 1);
      expect(dataSet['name'], 'Adapter authoritative row');
      expect(dataSet.paging.pageIndex, 0);
      expect(dataSet.paging.totalRecordCount, 1);
    },
  );

  test(
    'paged dataset global search resets to first page and uses adapter search',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'name', size: 50),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            for (var i = 1; i <= 25; i++)
              <String, Object?>{
                'id': i,
                'name': i == 21 ? 'Needle customer' : 'Name $i',
              },
          ],
        ),
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      await dataSet.paging.nextPage();
      await dataSet.search.apply('Needle', fields: const <String>['name']);

      expect(dataSet.paging.pageIndex, 0);
      expect(dataSet.recordCount, 1);
      expect(dataSet.paging.totalRecordCount, isNull);
      expect(dataSet['id'], 21);
    },
  );

  test(
    'paged dataset clearSearch reloads first unsearched adapter page',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'name', size: 50),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            for (var i = 1; i <= 25; i++)
              <String, Object?>{
                'id': i,
                'name': i == 21 ? 'Needle customer' : 'Name $i',
              },
          ],
        ),
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      await dataSet.search.apply('Needle', fields: const <String>['name']);
      await dataSet.search.clear();

      expect(dataSet.paging.pageIndex, 0);
      expect(dataSet.recordCount, 10);
      expect(dataSet.paging.totalRecordCount, 25);
      expect(dataSet['id'], 1);
    },
  );

  test(
    'paged dataset sends search state to adapter without local page filtering',
    () async {
      final adapter = _AuthoritativePagedAdapter();
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'name', size: 50),
        ],
        adapter: adapter,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );

      await dataSet.open();
      await dataSet.search.apply('Missing', fields: const <String>['name']);

      expect(adapter.lastRequest?.search.isActive, isTrue);
      expect(adapter.lastRequest?.search.text, 'Missing');
      expect(adapter.lastRequest?.includeTotalCount, isFalse);
      expect(dataSet.recordCount, 1);
      expect(dataSet['name'], 'Adapter authoritative row');
      expect(dataSet.paging.pageIndex, 0);
      expect(dataSet.paging.totalRecordCount, isNull);
    },
  );

  test('paged dataset rejects adapters that do not support paging', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      adapter: const _RawLoadAdapter(),
      paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
    );

    await expectLater(dataSet.open(), throwsA(isA<FdcDataAdapterException>()));
  });

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

  test('paged dataset applies adapter filters and default order', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcIntegerField(name: 'customer_id'),
        FdcStringField(name: 'status', size: 20),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'customer_id': 7, 'status': 'open'},
          <String, Object?>{'id': 4, 'customer_id': 8, 'status': 'open'},
          <String, Object?>{'id': 2, 'customer_id': 7, 'status': 'closed'},
          <String, Object?>{'id': 3, 'customer_id': 7, 'status': 'open'},
        ],
        filters: const <FdcDataAdapterFilter>[
          FdcDataAdapterFilter.equals('customer_id', 7),
        ],
        sorts: const <FdcDataAdapterSort>[FdcDataAdapterSort.desc('id')],
      ),
      paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
    );

    await dataSet.open();

    expect(dataSet.paging.totalRecordCount, 3);
    expect(dataSet.recordCount, 3);
    expect(dataSet['id'], 3);
  });

  test('paged dataset clear filters keeps adapter filters', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcIntegerField(name: 'customer_id'),
        FdcStringField(name: 'status', size: 20),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'customer_id': 7, 'status': 'open'},
          <String, Object?>{'id': 2, 'customer_id': 7, 'status': 'closed'},
          <String, Object?>{'id': 3, 'customer_id': 8, 'status': 'open'},
        ],
        filters: const <FdcDataAdapterFilter>[
          FdcDataAdapterFilter.equals('customer_id', 7),
        ],
      ),
      paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
    );

    await dataSet.open();
    await dataSet.filter.where('status').equals('open').apply();

    expect(dataSet.paging.totalRecordCount, 1);
    expect(dataSet['id'], 1);

    await dataSet.filter.clear();

    expect(dataSet.paging.totalRecordCount, 2);
    expect(dataSet.recordCount, 2);
    expect(
      <Object?>[
        FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id'),
        FdcDataSetInternal.fieldValueAt(dataSet, 1, 'id'),
      ],
      <Object?>[1, 2],
    );
  });

  test(
    'paged dataset preserves case and whitespace filter semantics in adapter request',
    () async {
      final adapter = _RecordingPagedAdapter();
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', isKey: true),
          FdcStringField(name: 'name', size: 40),
          FdcStringField(name: 'note', size: 40),
        ],
        adapter: adapter,
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );
      addTearDown(dataSet.dispose);

      await dataSet.open();
      await dataSet.filter
          .where('name')
          .contains('AN', caseSensitive: true)
          .apply();

      expect(adapter.lastRequest, isNotNull);
      expect(adapter.lastRequest!.filters, hasLength(1));
      expect(
        adapter.lastRequest!.filters.single.operator,
        FdcDataAdapterFilterOperator.contains,
      );
      expect(adapter.lastRequest!.filters.single.value, 'AN');
      expect(adapter.lastRequest!.filters.single.caseSensitive, isTrue);

      await dataSet.filter.where('note').isNullOrWhitespace().apply();
      expect(adapter.lastRequest!.filters, hasLength(1));
      expect(
        adapter.lastRequest!.filters.single.operator,
        FdcDataAdapterFilterOperator.isNullOrWhitespace,
      );
    },
  );

  test('paged dataset clear sort returns to adapter order', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'id': 1},
          <String, Object?>{'id': 2},
          <String, Object?>{'id': 3},
        ],
        sorts: const <FdcDataAdapterSort>[FdcDataAdapterSort.desc('id')],
      ),
      paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
    );

    await dataSet.open();
    expect(dataSet['id'], 3);

    await dataSet.sort.set(const <FdcDataSetSort>[
      FdcDataSetSort(fieldName: 'id'),
    ]);
    expect(dataSet['id'], 1);

    await dataSet.sort.clear();
    expect(dataSet['id'], 3);
  });
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

class _RecordingPagedAdapter extends FdcDataAdapter {
  _RecordingPagedAdapter()
    : super(
        readOnly: true,
        capabilities: const FdcDataAdapterCapabilities(
          filtering: true,
          paging: true,
          totalCount: true,
        ),
      );

  int loadCount = 0;
  FdcDataLoadRequest? lastRequest;

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    loadCount++;
    lastRequest = request;
    return FdcDataLoadResult(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': (request.offset ?? 0) + 1},
      ],
      totalCount: request.includeTotalCount ? 100 : null,
      previousPageCursor: 'previous-${request.offset ?? 0}',
      nextPageCursor: 'next-${request.offset ?? 0}',
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
    return FdcDataApplyError(recordId: entry.recordId, message: '$error');
  }

  @override
  String? validateStorageValue(FdcFieldDef field, Object? value) => null;
}

class _RawLoadAdapter extends FdcDataAdapter {
  const _RawLoadAdapter() : super(readOnly: true);

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    return const FdcDataLoadResult(rows: <Map<String, Object?>>[]);
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

class _AuthoritativePagedAdapter extends FdcDataAdapter {
  _AuthoritativePagedAdapter()
    : super(
        readOnly: true,
        capabilities: const FdcDataAdapterCapabilities(
          filtering: true,
          sorting: true,
          paging: true,
          totalCount: true,
          search: true,
        ),
      );

  FdcDataLoadRequest? lastRequest;

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    lastRequest = request;
    if (request.filters.isEmpty && !request.search.isActive) {
      return FdcDataLoadResult(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Initial'},
        ],
        totalCount: request.includeTotalCount ? 1 : null,
      );
    }

    // Deliberately return a row that does not match the requested filter.
    // This adapter test proves that a paged dataset treats adapter-loaded
    // pages as authoritative instead of applying local filtering/indexing
    // again over the already-paged result.
    return FdcDataLoadResult(
      rows: const <Map<String, Object?>>[
        <String, Object?>{'id': 99, 'name': 'Adapter authoritative row'},
      ],
      totalCount: request.includeTotalCount ? 1 : null,
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
    return FdcDataApplyError(recordId: entry.recordId, message: '$error');
  }

  @override
  String? validateStorageValue(FdcFieldDef field, Object? value) => null;
}
