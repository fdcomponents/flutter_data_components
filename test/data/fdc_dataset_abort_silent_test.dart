import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('silent beforeInsert abort keeps browse state without errors', () async {
    var afterInsertCalled = false;
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      beforeInsert: (dataSet) {
        throw const FdcDataSetAbortException.silent();
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
    expect(dataSet.errors.message, isEmpty);
  });

  test(
    'visible beforeInsert abort exposes its error and preserves rows',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
        beforeInsert: (dataSet) {
          throw FdcDataSetAbortException('Insert is not allowed.');
        },
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            <String, Object?>{'id': 1},
          ],
        ),
      );

      await dataSet.open();
      dataSet.append();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 1);
      expect(dataSet.errors.message, 'Insert is not allowed.');
    },
  );

  test(
    'silent beforeEdit abort does not invoke afterEdit or add errors',
    () async {
      var afterEditCalled = false;
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
        beforeEdit: (dataSet) {
          throw const FdcDataSetAbortException.silent();
        },
        afterEdit: (dataSet) {
          afterEditCalled = true;
        },
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha'},
          ],
        ),
      );

      await dataSet.open();
      dataSet.edit();

      expect(afterEditCalled, isFalse);
      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.errors.message, isEmpty);
    },
  );
}
