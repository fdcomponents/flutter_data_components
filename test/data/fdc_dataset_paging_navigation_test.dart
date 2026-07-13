import 'package:flutter_data_components/fdc.dart';
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

  test('paged dataset rejects adapters that do not support paging', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      adapter: const _RawLoadAdapter(),
      paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
    );

    await expectLater(dataSet.open(), throwsA(isA<FdcDataAdapterException>()));
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
