import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fieldByName exposes current record value and isNull', () async {
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
          const <String, Object?>{
            'name': null,
            'quantity': null,
            'amount': null,
            'active': null,
            'date': null,
            'createdAt': null,
            'time': null,
          },
        ],
      ),
    );
    await dataSet.open();

    expect(dataSet.fieldByName('name').value, 'Alpha');
    expect(dataSet.fieldByName('quantity').value, 3);
    expect(dataSet.fieldByName('amount').asNum, 12.5);
    expect(dataSet.fieldByName('active').value, isTrue);
    expect(dataSet.fieldByName('date').value, DateTime(2026, 5, 13));
    expect(
      dataSet.fieldByName('createdAt').value,
      DateTime(2026, 5, 13, 10, 30),
    );
    expect(dataSet.fieldByName('time').value, FdcTime(hour: 10, minute: 30));
    expect(dataSet.fieldByName('active').isNull, isFalse);

    dataSet.next();

    expect(dataSet.fieldByName('name').value, isNull);
    expect(dataSet.fieldByName('name').isNull, isTrue);
    expect(dataSet.fieldByName('active').value, isNull);
    expect(dataSet.fieldByName('active').isNull, isTrue);
  });

  test('fieldByName value reads active edit buffer value', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(size: 255, name: 'name'),
        FdcBooleanField(name: 'active'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha', 'active': false},
        ],
      ),
    );
    await dataSet.open();

    dataSet.edit();
    dataSet.setFieldValue('name', 'Beta');
    dataSet.setFieldValue('active', true);

    expect(dataSet.fieldByName('name').value, 'Beta');
    expect(dataSet.fieldByName('active').value, isTrue);
    expect(dataSet.fieldByName('active').isNull, isFalse);
  });
}
