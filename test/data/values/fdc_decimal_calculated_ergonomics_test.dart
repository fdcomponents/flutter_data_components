import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: <FdcFieldDef>[
      const FdcDecimalField(name: 'balance', precision: 12, scale: 2),
      FdcDecimalField(
        name: 'quarter',
        precision: 12,
        scale: 2,
        calculatedValue: (row) {
          final balance = row.value('balance') ?? 0;
          return balance * 0.25;
        },
      ),
      FdcDecimalField(
        name: 'plus_fee',
        precision: 12,
        scale: 2,
        calculatedValue: (row) {
          final balance = row.value('balance') ?? 0;
          return balance + 1.25;
        },
      ),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'balance': 100.00},
        {'balance': 12.50},
      ],
    ),
  );

  await dataSet.open();

  assert(
    FdcDataSetInternal.fieldValueAt(dataSet, 0, 'quarter') == '25.00'.decimal,
  );
  assert(
    FdcDataSetInternal.fieldValueAt(dataSet, 1, 'quarter') == '3.13'.decimal,
  );
  assert(
    FdcDataSetInternal.fieldValueAt(dataSet, 0, 'plus_fee') == '101.25'.decimal,
  );

  final nullableDataSet = FdcDataSet(
    fields: <FdcFieldDef>[
      const FdcDecimalField(name: 'balance', precision: 12, scale: 2),
      const FdcDecimalField(name: 'tax', precision: 12, scale: 2),
      FdcDecimalField(
        name: 'total',
        precision: 12,
        scale: 2,
        calculatedValue: (row) {
          final balance = row.value('balance') ?? 0;
          final tax = row.value('tax') ?? 0;
          return balance + tax;
        },
      ),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'tax': 25.00},
        {'balance': 100.00, 'tax': 25.00},
      ],
    ),
  );

  await nullableDataSet.open();

  assert(
    FdcDataSetInternal.fieldValueAt(nullableDataSet, 0, 'total') ==
        '25.00'.decimal,
  );
  assert(
    FdcDataSetInternal.fieldValueAt(nullableDataSet, 1, 'total') ==
        '125.00'.decimal,
  );
}
