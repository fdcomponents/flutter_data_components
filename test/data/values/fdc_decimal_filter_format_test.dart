import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fdc decimal filter format', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcDecimalField(name: 'amount', precision: 12, scale: 2),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'amount': 1234.56},
          {'amount': 2000.00},
          {'amount': 12.30},
        ],
      ),
    );

    await dataSet.open();

    FdcDataSetInternal.setViewState(
      dataSet,
      filters: const <FdcDataSetFilter>[
        FdcDataSetFilter(
          fieldName: 'amount',
          operator: FdcFilterOperator.equals,
          value: '1.234,56',
          dataType: FdcDataType.decimal,
        ),
      ],
      context: const FdcDataSetFilterContext(
        formatSettings: FdcFormatSettings(
          decimalSeparator: ',',
          thousandSeparator: '.',
        ),
      ),
    );

    expect(dataSet.recordCount, 1);
    expect(
      FdcDataSetInternal.fieldValueAt(dataSet, 0, 'amount'),
      '1234.56'.decimalScale(2),
    );

    FdcDataSetInternal.setViewState(
      dataSet,
      filters: const <FdcDataSetFilter>[
        FdcDataSetFilter(
          fieldName: 'amount',
          operator: FdcFilterOperator.equals,
          value: '2.000,00',
          dataType: FdcDataType.decimal,
          formatSettings: FdcFormatSettings(
            decimalSeparator: ',',
            thousandSeparator: '.',
          ),
        ),
      ],
    );

    expect(dataSet.recordCount, 1);
    expect(
      FdcDataSetInternal.fieldValueAt(dataSet, 0, 'amount'),
      '2000.00'.decimalScale(2),
    );
  });
}
