import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

Object? _lineTotal(FdcCalculatedFieldContext context) {
  final quantity = context.numValue('quantity') ?? 0;
  final price = context.numValue('price') ?? 0;
  return quantity * price;
}

void main() {
  test('fdc dataset calculated persistence', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'quantity'),
        FdcDecimalField(name: 'price', precision: 12, scale: 2),
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
    dataSet.setFieldValue('quantity', 3);
    dataSet.setFieldValue('price', 7.5);
    dataSet.post();

    expect(dataSet.fieldByName('total').asDecimal, '22.50'.decimal);

    final persistentMap = dataSet.toMaps().single;
    expect(persistentMap.containsKey('quantity'), isTrue);
    expect(persistentMap.containsKey('price'), isTrue);
    expect(persistentMap.containsKey('total'), isFalse);

    final fullMap = dataSet.toMaps(includeNonPersistent: true).single;
    expect(fullMap['total'], '22.50'.decimal);

    final insert = dataSet.changeSet.inserts.single;
    expect(insert.values.containsKey('quantity'), isTrue);
    expect(insert.values.containsKey('price'), isTrue);
    expect(insert.values.containsKey('total'), isFalse);
    expect(insert.changedFields.contains('total'), isFalse);

    final persistentCalculated = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'quantity'),
        FdcDecimalField(name: 'price', precision: 12, scale: 2),
        FdcDecimalField(
          name: 'total',
          precision: 12,
          scale: 2,
          calculatedValue: _lineTotal,
          persistent: true,
        ),
      ],

      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );

    await persistentCalculated.open();
    persistentCalculated.append();
    persistentCalculated.setFieldValue('quantity', 2);
    persistentCalculated.setFieldValue('price', 5);
    persistentCalculated.post();

    expect(persistentCalculated.toMaps().single['total'], '10.00'.decimal);
  });
}
