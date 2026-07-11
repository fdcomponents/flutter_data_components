import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'decimal precision allows scale-only values when precision equals scale',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'rate', precision: 2, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'rate': 0.99},
            {'rate': -0.01},
            {'rate': 0},
          ],
        ),
      );

      await dataSet.open();

      expect(dataSet.recordCount, 3);
      expect(
        dataSet.toMaps(includeNonPersistent: true)[0]['rate'],
        '0.99'.decimalScale(2),
      );
      expect(
        dataSet.toMaps(includeNonPersistent: true)[1]['rate'],
        '-0.01'.decimalScale(2),
      );
      expect(
        dataSet.toMaps(includeNonPersistent: true)[2]['rate'],
        '0.00'.decimalScale(2),
      );
    },
  );

  test(
    'decimal precision still rejects integer digits when precision equals scale',
    () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'rate', precision: 2, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'rate': 1.00},
          ],
        ),
      );

      expect(() => dataSet.open(), throwsA(isA<FdcDataSetException>()));
    },
  );
}
