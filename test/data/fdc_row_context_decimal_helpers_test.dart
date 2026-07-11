import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  await _typedHelpersPreserveNullWhileValueUsesCalculatedZeroFallback();
}

Future<void>
_typedHelpersPreserveNullWhileValueUsesCalculatedZeroFallback() async {
  final seen = <String, Object?>{};
  final dataSet = FdcDataSet(
    fields: <FdcFieldDef>[
      const FdcDecimalField(name: 'amount', precision: 12, scale: 2),
      FdcDecimalField(
        name: 'calc',
        precision: 12,
        scale: 2,
        calculatedValue: (row) {
          seen['value'] = row.value('amount');
          seen['decimalValue'] = row.decimalValue('amount');
          seen['decimalOrZero'] = row.decimalOrZero('amount');
          seen['numValue'] = row.numValue('amount');
          seen['numOrZero'] = row.numOrZero('amount');
          return row.decimalOrZero('amount') + 1;
        },
      ),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'amount': null},
      ],
    ),
  );

  await dataSet.open();

  assert(seen['value'] == FdcDecimal.zero);
  assert(seen['decimalValue'] == null);
  assert(seen['decimalOrZero'] == FdcDecimal.zero);
  assert(seen['numValue'] == null);
  assert(seen['numOrZero'] == 0);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'calc') == '1.00'.decimal);
}
