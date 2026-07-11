import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fieldByName as accessors read current record values', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(size: 255, name: 'name'),
        FdcIntegerField(name: 'quantity'),
        FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        FdcBooleanField(name: 'active'),
        FdcDateField(name: 'date'),
        FdcDateTimeField(name: 'createdAt'),
        FdcTimeField(name: 'time'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          <String, Object?>{
            'name': 'Alpha',
            'quantity': 3,
            'amount': 12.5,
            'active': true,
            'date': DateTime(2026, 5, 13),
            'createdAt': DateTime(2026, 5, 13, 10, 30),
            'time': FdcTime(hour: 10, minute: 30),
          },
        ],
      ),
    );

    await dataSet.open();

    expect(dataSet.fieldByName('name').asString, 'Alpha');
    expect(dataSet.fieldByName('quantity').asInteger, 3);
    expect(dataSet.fieldByName('amount').asDecimal?.toString(), '12.50');
    expect(dataSet.fieldByName('active').asBoolean, isTrue);
    expect(dataSet.fieldByName('date').asDate, DateTime(2026, 5, 13));
    expect(
      dataSet.fieldByName('createdAt').asDateTime,
      DateTime(2026, 5, 13, 10, 30),
    );
    expect(dataSet.fieldByName('time').asTime, FdcTime(hour: 10, minute: 30));
  });

  test('fieldByName value setter writes active edit buffer values', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(size: 255, name: 'name'),
        FdcIntegerField(name: 'quantity'),
        FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        FdcBooleanField(name: 'active'),
        FdcDateField(name: 'date'),
        FdcDateTimeField(name: 'createdAt'),
        FdcTimeField(name: 'time'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          <String, Object?>{
            'name': 'Alpha',
            'quantity': 3,
            'amount': 12.5,
            'active': false,
            'date': DateTime(2026, 5, 13),
            'createdAt': DateTime(2026, 5, 13, 10, 30),
            'time': FdcTime(hour: 10, minute: 30),
          },
        ],
      ),
    );

    await dataSet.open();

    dataSet.edit();
    dataSet.fieldByName('name').value = 'Beta';
    dataSet.fieldByName('quantity').value = 7;
    dataSet.fieldByName('amount').value = 99.95;
    dataSet.fieldByName('active').value = true;
    dataSet.fieldByName('date').value = DateTime(2026, 6);
    dataSet.fieldByName('createdAt').value = DateTime(2026, 6, 1, 11, 45);
    dataSet.fieldByName('time').value = FdcTime(hour: 11, minute: 45);

    expect(dataSet.fieldByName('name').asString, 'Beta');
    expect(dataSet.fieldByName('quantity').asInteger, 7);
    expect(dataSet.fieldByName('amount').asDecimal?.toString(), '99.95');
    expect(dataSet.fieldByName('active').asBoolean, isTrue);
    expect(dataSet.fieldByName('date').asDate, DateTime(2026, 6));
    expect(
      dataSet.fieldByName('createdAt').asDateTime,
      DateTime(2026, 6, 1, 11, 45),
    );
    expect(dataSet.fieldByName('time').asTime, FdcTime(hour: 11, minute: 45));
  });

  test('fieldByName as accessors reject invalid field type', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha'},
        ],
      ),
    );

    await dataSet.open();

    expect(
      () => dataSet.fieldByName('name').asDecimal,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Invalid field value access: field "name" is FdcStringField, cannot access asDecimal.',
        ),
      ),
    );
  });
}
