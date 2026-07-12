import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'insert places an unposted row before the current sorted record',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name'),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Bravo'},
            {'id': 2, 'name': 'Charlie'},
            {'id': 3, 'name': 'Delta'},
          ],
        ),
      );

      await dataSet.open();
      await dataSet.sort.set(const <FdcDataSetSort>[
        FdcDataSetSort(fieldName: 'name'),
      ]);
      dataSet.moveToRecord(2);

      expect(dataSet.fieldValue('id'), 2);

      dataSet.insert();
      dataSet.setFieldValue('id', 4);
      dataSet.setFieldValue('name', 'Aardvark');

      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet.recordCount, 4);
      expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      expect(
        <Object?>[
          for (var rowIndex = 0; rowIndex < dataSet.recordCount; rowIndex++)
            FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, 'id'),
        ],
        <Object?>[1, 4, 2, 3],
        reason:
            'The unposted insert should remain before the former current row.',
      );
      expect(dataSet.fieldValue('id'), 4);
      expect(dataSet.fieldValue('name'), 'Aardvark');
    },
  );
}
