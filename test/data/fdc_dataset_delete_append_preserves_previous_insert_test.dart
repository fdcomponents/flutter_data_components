import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deleting an unposted append preserves an earlier posted insert',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name'),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      );

      await dataSet.open();

      dataSet.append();
      dataSet.setFieldValue('id', 2);
      dataSet.setFieldValue('name', 'Inserted');
      dataSet.post();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
      expect(dataSet.changeSet.inserts, hasLength(1));

      dataSet.append();
      dataSet.setFieldValue('id', 3);
      dataSet.setFieldValue('name', 'Appended');

      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet.recordCount, 3);

      dataSet.delete();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
      expect(
        dataSet.changeSet.inserts,
        hasLength(1),
        reason:
            'Deleting the active unposted append must not remove prior inserts.',
      );

      final ids = <Object?>[
        for (var rowIndex = 0; rowIndex < dataSet.recordCount; rowIndex++)
          FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, 'id'),
      ];

      expect(ids, unorderedEquals(<Object?>[1, 2]));
    },
  );
}
