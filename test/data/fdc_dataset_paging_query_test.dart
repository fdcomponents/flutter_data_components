import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
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
