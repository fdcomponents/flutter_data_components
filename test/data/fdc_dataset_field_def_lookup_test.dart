import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fieldDef returns typed field metadata definitions', () {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'name', size: 50),
        FdcIntegerField(name: 'quantity', minValue: 1, maxValue: 10),
        FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        FdcBooleanField(name: 'active'),
        FdcDateField(name: 'date'),
        FdcDateTimeField(name: 'createdAt'),
        FdcTimeField(name: 'time'),
      ],

      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );

    expect(dataSet.fieldDef<FdcFieldDef>('name').name, 'name');
    expect(dataSet.fieldDef<FdcStringField>('name').size, 50);
    expect(dataSet.fieldDef<FdcIntegerField>('quantity').minValue, 1);
    expect(dataSet.fieldDef<FdcIntegerField>('quantity').maxValue, 10);
    expect(dataSet.fieldDef<FdcDecimalField>('amount').precision, 12);
    expect(dataSet.fieldDef<FdcDecimalField>('amount').scale, 2);
    expect(dataSet.fieldDef<FdcBooleanField>('active').name, 'active');
    expect(dataSet.fieldDef<FdcDateField>('date').name, 'date');
    expect(dataSet.fieldDef<FdcDateTimeField>('createdAt').name, 'createdAt');
    expect(dataSet.fieldDef<FdcTimeField>('time').name, 'time');
  });

  test(
    'fieldDef throws a clear error when the requested definition type is invalid',
    () {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      );

      expect(
        () => dataSet.fieldDef<FdcDecimalField>('name'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Invalid field definition type: field "name" is FdcStringField, expected FdcDecimalField.',
          ),
        ),
      );
    },
  );
}
