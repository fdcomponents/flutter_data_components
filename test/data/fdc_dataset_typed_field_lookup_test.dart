import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FdcDataSet dataSet;

  setUp(() {
    dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'name', size: 50),
        FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        FdcIntegerField(name: 'quantity', minValue: 1, maxValue: 10),
        FdcBooleanField(name: 'active'),
        FdcDateField(name: 'date'),
        FdcDateTimeField(name: 'createdAt'),
        FdcTimeField(name: 'time'),
      ],
      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );
  });

  test('fieldByName returns the runtime field definition', () {
    expect(dataSet.fieldByName('name').definition, isA<FdcStringField>());
  });

  test('fieldDef returns typed definitions with configured metadata', () {
    expect(dataSet.fieldDef<FdcStringField>('name').size, 50);

    final amount = dataSet.fieldDef<FdcDecimalField>('amount');
    expect(amount.precision, 12);
    expect(amount.scale, 2);

    final quantity = dataSet.fieldDef<FdcIntegerField>('quantity');
    expect(quantity.minValue, 1);
    expect(quantity.maxValue, 10);

    expect(dataSet.fieldDef<FdcBooleanField>('active').name, 'active');
    expect(dataSet.fieldDef<FdcDateField>('date').name, 'date');
    expect(dataSet.fieldDef<FdcDateTimeField>('createdAt').name, 'createdAt');
    expect(dataSet.fieldDef<FdcTimeField>('time').name, 'time');
  });

  test('fieldDef rejects a requested definition type that does not match', () {
    expect(
      () => dataSet.fieldDef<FdcDecimalField>('name'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Invalid field definition type: field "name" is FdcStringField, '
              'expected FdcDecimalField.',
        ),
      ),
    );
  });
}
