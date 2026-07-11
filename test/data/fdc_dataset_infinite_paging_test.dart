import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('infinite paging appends next page and preserves current row', () async {
    final rows = List<Map<String, Object?>>.generate(
      5,
      (index) => <String, Object?>{'id': index + 1},
    );
    final dataSet = FdcDataSet(
      fields: <FdcFieldDef>[const FdcIntegerField(name: 'id')],
      adapter: FdcMemoryDataAdapter(rows: rows),
      paging: const FdcDataPagingOptions(
        enabled: true,
        pageSize: 2,
        mode: FdcDataPagingMode.infinite,
      ),
    );

    await dataSet.paging.openPage(0);
    dataSet.moveToRecord(2);
    await dataSet.paging.nextPage();

    expect(dataSet.recordCount, 4);
    expect(dataSet.paging.pageIndex, 1);
    expect(dataSet.recordNumber, 2);
    expect(dataSet.fieldValue('id'), 2);
    expect(dataSet.paging.hasNextPage, isTrue);

    await dataSet.paging.nextPage();
    expect(dataSet.recordCount, 5);
    expect(dataSet.paging.pageIndex, 2);
    expect(dataSet.paging.hasNextPage, isFalse);
  });

  test('infinite paging deduplicates concurrent next-page loads', () async {
    final adapter = _DelayedPagingAdapter();
    final dataSet = FdcDataSet(
      fields: <FdcFieldDef>[const FdcIntegerField(name: 'id')],
      adapter: adapter,
      paging: const FdcDataPagingOptions(
        enabled: true,
        pageSize: 2,
        mode: FdcDataPagingMode.infinite,
      ),
    );

    await dataSet.paging.openPage(0);
    await Future.wait(<Future<void>>[
      dataSet.paging.nextPage(),
      dataSet.paging.nextPage(),
    ]);

    expect(adapter.loadCount, 2);
    expect(dataSet.recordCount, 4);
  });
}

class _DelayedPagingAdapter extends FdcMemoryDataAdapter {
  _DelayedPagingAdapter()
    : super(
        rows: List<Map<String, Object?>>.generate(
          4,
          (index) => <String, Object?>{'id': index + 1},
        ),
      );

  int loadCount = 0;

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    loadCount++;
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return super.load(request);
  }
}
