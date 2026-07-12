import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('beforeEdit abort prevents edit and skips afterEdit', () async {
    var afterEditCalled = false;
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      beforeEdit: (dataSet) {
        throw FdcDataSetAbortException('Edit is not allowed.');
      },
      afterEdit: (dataSet) {
        afterEditCalled = true;
      },
      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          <String, Object?>{'id': 1},
        ],
      ),
    );

    await dataSet.open();
    dataSet.edit();

    expect(afterEditCalled, isFalse);
    expect(dataSet.state, FdcDataSetState.browse);
    expect(dataSet.errors.message, 'Edit is not allowed.');
  });
}
