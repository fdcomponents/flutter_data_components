import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FdcDataLoadRequest.copyWith can clear nullable paging values', () {
    const request = FdcDataLoadRequest(offset: 20, limit: 10);

    final retained = request.copyWith();
    final cleared = request.copyWith(offset: null, limit: null);

    expect(retained.offset, 20);
    expect(retained.limit, 10);
    expect(cleared.offset, isNull);
    expect(cleared.limit, isNull);
  });
}
