import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EOF navigation', () {
    test('tracks EOF while moving through populated records', () async {
      final dataSet = _createDataSet();

      expect(dataSet.eof, isTrue);
      expect(dataSet.recordNumber, -1);

      await dataSet.open();

      expect(dataSet.eof, isFalse);
      expect(dataSet.recordNumber, 1);

      dataSet.next();
      expect(dataSet.eof, isFalse);
      expect(dataSet.recordNumber, 2);

      dataSet.next();
      expect(dataSet.eof, isTrue);
      expect(dataSet.recordNumber, 2);
      expect(dataSet.fieldValue('id'), 2);

      dataSet.first();
      expect(dataSet.eof, isFalse);
      expect(dataSet.recordNumber, 1);

      dataSet.last();
      expect(dataSet.eof, isTrue);
      expect(dataSet.recordNumber, 2);
      expect(dataSet.fieldValue('id'), 2);
    });

    test('moveToRecord updates EOF and rejects out-of-range records', () async {
      final dataSet = _createDataSet();
      await dataSet.open();

      dataSet.moveToRecord(2);
      expect(dataSet.recordNumber, 2);
      expect(dataSet.eof, isTrue);

      dataSet.moveToRecord(1);
      expect(dataSet.recordNumber, 1);
      expect(dataSet.eof, isFalse);

      expect(() => dataSet.moveToRecord(50), throwsRangeError);
    });

    test(
      'closed dataset is at EOF and rejects prior and next navigation',
      () async {
        final dataSet = _createDataSet();
        await dataSet.open();

        dataSet.close();

        expect(dataSet.eof, isTrue);
        expect(dataSet.recordNumber, -1);
        expect(dataSet.prior, throwsStateError);
        expect(dataSet.next, throwsStateError);
      },
    );

    test('empty opened dataset is simultaneously at BOF and EOF', () async {
      final dataSet = _createDataSet();
      (dataSet.adapter as FdcMemoryDataAdapter).replaceRows(
        const <Map<String, Object?>>[],
      );

      await dataSet.open();

      expect(dataSet.bof, isTrue);
      expect(dataSet.eof, isTrue);
      expect(dataSet.recordNumber, -1);
    });
  });
}

FdcDataSet _createDataSet() => FdcDataSet(
  fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
  adapter: FdcMemoryDataAdapter(
    rows: const <Map<String, Object?>>[
      {'id': 1},
      {'id': 2},
    ],
  ),
);
