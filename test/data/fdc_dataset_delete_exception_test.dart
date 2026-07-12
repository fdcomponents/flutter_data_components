import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'beforeDelete abort preserves the record and exposes its error',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
        beforeDelete: (dataSet) {
          throw FdcDataSetAbortException('Delete is not allowed.');
        },
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            <String, Object?>{'id': 1},
          ],
        ),
      );

      await dataSet.open();
      dataSet.delete();

      expect(dataSet.errors.message, 'Delete is not allowed.');
      expect(dataSet.recordCount, 1);
    },
  );
}
