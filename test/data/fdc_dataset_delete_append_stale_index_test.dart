import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deleting an appended row restores the last valid active index',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name'),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            for (var index = 0; index < 50; index++)
              {'id': index + 1, 'name': 'Row ${index + 1}'},
          ],
        ),
      );

      await dataSet.open();

      dataSet.last();
      dataSet.append();

      expect(FdcDataSetInternal.activeIndex(dataSet), 50);
      expect(dataSet.recordCount, 51);

      dataSet.delete();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 50);
      expect(
        FdcDataSetInternal.activeIndex(dataSet),
        49,
        reason: 'The active index must not retain the deleted append position.',
      );
      expect(
        FdcDataSetInternal.fieldValueAt(
          dataSet,
          FdcDataSetInternal.activeIndex(dataSet),
          'id',
        ),
        50,
      );
    },
  );
}
