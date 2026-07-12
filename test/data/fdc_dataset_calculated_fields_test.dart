import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

Object? _lineTotal(FdcCalculatedFieldContext context) {
  final quantity = context.numValue('quantity') ?? 0;
  final price = context.numValue('price') ?? 0;
  return quantity * price;
}

void main() {
  test(
    'calculated decimal field follows source fields across append and edit',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'quantity', defaultValue: 0),
          FdcDecimalField(
            name: 'price',
            precision: 12,
            scale: 2,
            defaultValue: 0.0,
          ),
          FdcDecimalField(
            name: 'total',
            precision: 12,
            scale: 2,
            calculatedValue: _lineTotal,
          ),
        ],
        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      );

      await dataSet.open();
      dataSet.append();
      expect(dataSet.fieldByName('total').asDecimal, FdcDecimal.zero);

      dataSet.setFieldValue('quantity', 3);
      dataSet.setFieldValue('price', 7.5);
      expect(dataSet.fieldByName('total').asDecimal, '22.50'.decimal);

      dataSet.post();
      expect(dataSet.fieldByName('total').asDecimal, '22.50'.decimal);

      dataSet.edit();
      dataSet.setFieldValue('quantity', 4);
      expect(dataSet.fieldByName('total').asDecimal, '30.00'.decimal);
    },
  );

  test('calculated field rejects direct writes', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'quantity', defaultValue: 0),
        FdcDecimalField(
          name: 'price',
          precision: 12,
          scale: 2,
          defaultValue: 0.0,
        ),
        FdcDecimalField(
          name: 'total',
          precision: 12,
          scale: 2,
          calculatedValue: _lineTotal,
        ),
      ],
      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );

    await dataSet.open();
    dataSet.append();

    expect(() => dataSet.setFieldValue('total', 123), throwsStateError);
  });
}
