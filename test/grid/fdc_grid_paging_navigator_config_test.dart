import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('paging controls are independent grid items', () {
    const navigator = FdcGridPagingNavigator.input(
      placement: FdcGridItemPlacement.start,
      pageLabel: 'Page',
      pageCountLabel: 'of',
      showFirstLastButtons: false,
      allowPageInput: false,
    );
    const recordInfo = FdcGridPagingRecordInfo(
      placement: FdcGridItemPlacement.center,
      label: 'Records',
    );
    final pageSize = FdcGridPageSizeSelector(
      label: 'Rows per page',
      options: <int>[25, 50, 100],
    );

    expect(navigator.placement, FdcGridItemPlacement.start);
    expect(recordInfo.placement, FdcGridItemPlacement.center);
    expect(recordInfo.label, 'Records');
    expect(pageSize.placement, FdcGridItemPlacement.end);
    expect(pageSize.label, 'Rows per page');
    expect(pageSize.options, const <int>[25, 50, 100]);
  });

  test('empty page-size options are supported', () {
    final selector = FdcGridPageSizeSelector(options: <int>[]);
    expect(selector.options, isEmpty);
  });

  test('numbered navigator rejects invalid visible page count', () {
    expect(
      () => FdcGridPagingNavigator.numbered(visiblePageCount: 0),
      throwsRangeError,
    );
  });

  test('page-size selector rejects non-positive options', () {
    expect(
      () => FdcGridPageSizeSelector(options: <int>[25, 0, 100]),
      throwsRangeError,
    );
    expect(
      () => FdcGridPageSizeSelector(options: <int>[25, -1, 100]),
      throwsRangeError,
    );
  });

  test('page-size selector rejects duplicate options', () {
    expect(
      () => FdcGridPageSizeSelector(options: <int>[25, 50, 25]),
      throwsArgumentError,
    );
  });

  test('page-size selector stores an immutable option snapshot', () {
    final source = <int>[25, 50];
    final selector = FdcGridPageSizeSelector(options: source);

    source.add(100);

    expect(selector.options, const <int>[25, 50]);
    expect(() => selector.options.add(100), throwsUnsupportedError);
  });
}
