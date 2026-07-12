import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'append keeps an unposted sorted row at the end of the active view',
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

      dataSet.append();
      dataSet.setFieldValue('id', 4);
      dataSet.setFieldValue('name', 'Aardvark');

      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet.recordCount, 4);
      expect(FdcDataSetInternal.activeIndex(dataSet), dataSet.recordCount - 1);
      expect(
        FdcDataSetInternal.fieldValueAt(dataSet, dataSet.recordCount - 1, 'id'),
        4,
      );
      expect(dataSet.fieldValue('id'), 4);
      expect(dataSet.fieldValue('name'), 'Aardvark');

      dataSet.post();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(
        FdcDataSetInternal.fieldValueAt(dataSet, dataSet.recordCount - 1, 'id'),
        4,
        reason: 'Posting should not implicitly rebuild the sorted view.',
      );
    },
  );
}
