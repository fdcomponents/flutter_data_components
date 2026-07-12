import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'while-not-EOF traversal updates every record and prior exits EOF',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name'),
          FdcDecimalField(name: 'balance', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha', 'balance': 1.0},
            {'id': 2, 'name': 'Beta', 'balance': 2.0},
            {'id': 3, 'name': 'Gamma', 'balance': 3.0},
          ],
        ),
      );

      await dataSet.open();

      expect(dataSet.bof, isTrue);
      expect(dataSet.eof, isFalse);
      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(dataSet.recordNumber, 1);

      var updated = 0;
      while (!dataSet.eof) {
        dataSet.edit();
        dataSet.fieldByName('name').value = 'test';
        dataSet.fieldByName('balance').value = 10.09;
        dataSet.post();
        updated++;
        dataSet.next();
      }

      expect(updated, 3);
      expect(dataSet.eof, isTrue);
      expect(FdcDataSetInternal.activeIndex(dataSet), dataSet.recordCount - 1);
      expect(dataSet.recordNumber, dataSet.recordCount);
      expect(dataSet.fieldValue('id'), 3);

      for (var rowIndex = 0; rowIndex < dataSet.recordCount; rowIndex++) {
        expect(
          FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, 'name'),
          'test',
          reason: 'Record ${rowIndex + 1} should contain the posted name.',
        );
        expect(
          FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, 'balance'),
          '10.09'.decimalScale(2),
          reason: 'Record ${rowIndex + 1} should contain the posted balance.',
        );
      }

      dataSet.prior();

      expect(dataSet.eof, isFalse);
      expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      expect(dataSet.recordNumber, 2);
      expect(dataSet.fieldValue('id'), 2);
    },
  );
}
