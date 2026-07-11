import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'failed onNewRecord rolls insert back atomically and allows retry',
    () async {
      var failNextInsert = true;
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'name', size: 100),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{'id': 1, 'name': 'Alpha'},
            <String, Object?>{'id': 2, 'name': 'Beta'},
          ],
        ),
        onNewRecord: (dataSet) {
          if (failNextInsert) {
            failNextInsert = false;
            throw StateError('default failure');
          }
          dataSet.setFieldValue('id', 3);
          dataSet.setFieldValue('name', 'Gamma');
        },
      );
      await dataSet.open();

      dataSet.last();
      final previousIndex = FdcDataSetInternal.activeIndex(dataSet);

      expect(dataSet.insert, throwsA(isA<FdcDataSetException>()));

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
      expect(FdcDataSetInternal.activeIndex(dataSet), previousIndex);
      expect(dataSet.fieldValue('name'), 'Beta');

      dataSet.insert();

      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet.recordCount, 3);
      expect(dataSet.fieldValue('id'), 3);
      expect(dataSet.fieldValue('name'), 'Gamma');
    },
  );

  test(
    'afterInsert abort removes the pending row and restores browse state',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 100)],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{'name': 'Alpha'},
          ],
        ),
        afterInsert: (dataSet) {
          throw const FdcDataSetAbortException.silent();
        },
      );
      await dataSet.open();

      dataSet.insert();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Alpha');
    },
  );
}
