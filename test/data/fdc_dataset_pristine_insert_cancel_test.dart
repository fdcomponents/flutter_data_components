import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'canceling a pristine insert removes it and preserves new-record defaults',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcStringField(size: 255, name: 'status'),
        ],
        onNewRecord: (dataSet) {
          dataSet.setFieldValue('status', 'draft');
        },
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'status': 'active'},
          ],
        ),
      );

      await dataSet.open();
      dataSet.append();

      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet.recordCount, 2);
      expect(dataSet.fieldValue('status'), 'draft');

      dataSet.cancel();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Alpha');

      dataSet.append();
      dataSet.setFieldValue('name', 'Beta');
      dataSet.post();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name'), 'Beta');
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'status'), 'draft');
    },
  );
}
