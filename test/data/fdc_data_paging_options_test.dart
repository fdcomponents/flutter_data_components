import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dataset validates paging options at runtime', () {
    expect(
      () => FdcDataSet(
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 0),
      ),
      throwsRangeError,
    );

    expect(
      () => FdcDataSet(
        paging: const FdcDataPagingOptions(enabled: true, maxPageSize: 0),
      ),
      throwsRangeError,
    );

    expect(
      () => FdcDataSet(
        paging: const FdcDataPagingOptions(
          enabled: true,
          pageSize: 20,
          maxPageSize: 10,
        ),
      ),
      throwsRangeError,
    );

    expect(
      () => FdcDataSet(
        paging: const FdcDataPagingOptions(
          enabled: true,
          infiniteLoadThreshold: 0,
        ),
      ),
      throwsRangeError,
    );

    expect(
      () => FdcDataSet(
        paging: const FdcDataPagingOptions(
          enabled: true,
          infiniteLoadThreshold: 1.1,
        ),
      ),
      throwsRangeError,
    );
  });
}
