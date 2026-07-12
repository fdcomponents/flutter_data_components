import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('beforeInsert abort prevents append and skips afterInsert', () async {
    var afterInsertCalled = false;
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      beforeInsert: (dataSet) {
        throw FdcDataSetAbortException('Insert is not allowed.');
      },
      afterInsert: (dataSet) {
        afterInsertCalled = true;
      },
      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          <String, Object?>{'id': 1},
        ],
      ),
    );

    await dataSet.open();
    dataSet.append();

    expect(afterInsertCalled, isFalse);
    expect(dataSet.state, FdcDataSetState.browse);
    expect(dataSet.recordCount, 1);
    expect(dataSet.errors.message, 'Insert is not allowed.');
  });
}
