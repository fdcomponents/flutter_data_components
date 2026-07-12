import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'calculated decimal division materializes scaled values for every row',
    () async {
      final dataSet = FdcDataSet(
        fields: <FdcFieldDef>[
          const FdcDecimalField(name: 'balance', precision: 12, scale: 2),
          const FdcDecimalField(name: 'tax', precision: 12, scale: 2),
          FdcDecimalField(
            name: 'ratio',
            precision: 12,
            scale: 2,
            calculatedValue: (context) {
              final balance = context.numValue('balance') ?? 0;
              final tax = context.numValue('tax') ?? 0;
              if (tax == 0) {
                return null;
              }
              return balance / tax;
            },
          ),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'balance': 10.0, 'tax': 4.0},
            {'balance': 9.0, 'tax': 3.0},
          ],
        ),
      );

      await dataSet.open();

      expect(
        FdcDataSetInternal.fieldValueAt(dataSet, 0, 'ratio'),
        '2.50'.decimal,
      );
      expect(
        FdcDataSetInternal.fieldValueAt(dataSet, 1, 'ratio'),
        '3.00'.decimal,
      );
    },
  );
}
