import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fieldByName value setter writes active edit buffer value', () async {
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

    expect(dataSet.fieldByName('name').value, 'Beta');
    expect(dataSet.fieldByName('quantity').value, 7);
    expect(dataSet.fieldByName('amount').asNum, 99.95);
    expect(dataSet.fieldByName('active').value, isTrue);
    expect(dataSet.fieldByName('date').value, DateTime(2026, 6));
    expect(
      dataSet.fieldByName('createdAt').value,
      DateTime(2026, 6, 1, 11, 45),
    );
    expect(dataSet.fieldByName('time').value, FdcTime(hour: 11, minute: 45));

    dataSet.post();

    expect(dataSet.fieldByName('name').value, 'Beta');
    expect(dataSet.fieldByName('quantity').value, 7);
    expect(dataSet.fieldByName('amount').asNum, 99.95);
    expect(dataSet.fieldByName('active').value, isTrue);
  });

  test('fieldByName value setter can write null', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(size: 255, name: 'name'),
        FdcBooleanField(name: 'active'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha', 'active': true},
        ],
      ),
    );

    await dataSet.open();

    dataSet.edit();
    dataSet.fieldByName('name').value = null;
    dataSet.fieldByName('active').value = null;

    expect(dataSet.fieldByName('name').value, isNull);
    expect(dataSet.fieldByName('name').isNull, isTrue);
    expect(dataSet.fieldByName('active').value, isNull);
    expect(dataSet.fieldByName('active').isNull, isTrue);
  });

  test('fieldByName value setter follows dataset edit-state rules', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alpha'},
        ],
      ),
    );

    await dataSet.open();

    expect(() {
      dataSet.fieldByName('name').value = 'Beta';
    }, throwsStateError);
  });
}
