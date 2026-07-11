import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'adapter open normalizes external values to field runtime types',
    () async {
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
          rows: const <Map<String, Object?>>[
            <String, Object?>{
              'name': 'Alpha',
              'quantity': '42',
              'amount': '10,50',
              'active': '1',
              'date': '2026-05-14T10:20:30',
              'createdAt': '2026-05-14T10:20:30',
              'time': '12:34:56.7891234',
            },
          ],
        ),
      );
      await dataSet.open();

      expect(dataSet.fieldByName('name').asString, 'Alpha');
      expect(dataSet.fieldByName('quantity').asInteger, 42);
      expect(dataSet.fieldByName('amount').asDecimal?.toString(), '10.50');
      expect(dataSet.fieldByName('active').asBoolean, isTrue);
      expect(dataSet.fieldByName('date').asDate, DateTime(2026, 5, 14));
      expect(
        dataSet.fieldByName('createdAt').asDateTime,
        DateTime(2026, 5, 14, 10, 20, 30),
      );
      expect(
        dataSet.fieldByName('time').asTime,
        FdcTime.parse('12:34:56.7891234'),
      );
    },
  );

  test('field writes normalize valid assignable values', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
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
            'quantity': 1,
            'amount': 1.0,
            'active': false,
            'date': DateTime(2026),
            'createdAt': DateTime(2026),
            'time': FdcTime(hour: 1),
          },
        ],
      ),
    );
    await dataSet.open();

    dataSet.edit();
    dataSet.fieldByName('quantity').value = 5.0;
    dataSet.fieldByName('amount').value = '12.25';
    dataSet.fieldByName('active').value = 'yes';
    dataSet.fieldByName('date').value = '2026-05-14T11:22:33';
    dataSet.fieldByName('createdAt').value = '2026-05-14T11:22:33';
    dataSet.fieldByName('time').value = '08:15:30.123';
    dataSet.post();

    expect(dataSet.fieldByName('quantity').asInteger, 5);
    expect(dataSet.fieldByName('amount').asDecimal?.toString(), '12.25');
    expect(dataSet.fieldByName('active').asBoolean, isTrue);
    expect(dataSet.fieldByName('date').asDate, DateTime(2026, 5, 14));
    expect(
      dataSet.fieldByName('createdAt').asDateTime,
      DateTime(2026, 5, 14, 11, 22, 33),
    );
    expect(dataSet.fieldByName('time').asTime, FdcTime.parse('08:15:30.123'));
  });

  test(
    'decimal normalization rounds scale using decimal-safe rounding',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 6, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{'amount': 0},
          ],
        ),
      );
      await dataSet.open();

      dataSet.edit();
      dataSet.fieldByName('amount').value = '1.005';
      dataSet.post();

      expect(dataSet.fieldByName('amount').asDecimal?.toString(), '1.01');
    },
  );

  test('decimal normalization rounds numeric half values safely', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcDecimalField(name: 'amount', precision: 6, scale: 2),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'amount': 0},
        ],
      ),
    );
    await dataSet.open();

    dataSet.edit();
    dataSet.fieldByName('amount').value = 1.005;
    dataSet.post();

    expect(dataSet.fieldByName('amount').asDecimal?.toString(), '1.01');
  });

  test(
    'decimal normalization rejects precision overflow after rounding',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 5, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{'amount': 1.2},
          ],
        ),
      );
      await dataSet.open();

      dataSet.edit();

      expect(
        () => dataSet.fieldByName('amount').value = '999.995',
        throwsArgumentError,
      );
      expect(dataSet.fieldByName('amount').asDecimal?.toString(), '1.20');
    },
  );

  test('invalid field write fails before mutating the edit buffer', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'quantity')],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'quantity': 1},
        ],
      ),
    );
    await dataSet.open();

    dataSet.edit();

    expect(
      () => dataSet.fieldByName('quantity').value = 'abc',
      throwsArgumentError,
    );
    expect(dataSet.fieldByName('quantity').asInteger, 1);
  });

  test('empty editor text normalizes to null for non-string fields', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'quantity', required: true),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'quantity': 1},
        ],
      ),
    );
    await dataSet.open();

    dataSet.edit();
    dataSet.fieldByName('quantity').value = '';

    expect(dataSet.fieldByName('quantity').value, isNull);
    expect(dataSet.validateFieldValue('quantity', ''), isNotEmpty);
  });

  test('object fields keep custom values unchanged', () async {
    final badge = Object();
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcObjectField(name: 'custom')],
      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          <String, Object?>{'custom': badge},
        ],
      ),
    );
    await dataSet.open();

    expect(dataSet.fieldByName('custom').asObject, same(badge));

    final nextValue = Object();
    dataSet.edit();
    dataSet.fieldByName('custom').value = nextValue;
    dataSet.post();

    expect(dataSet.fieldByName('custom').asObject, same(nextValue));
  });

  test(
    'calculated field values are normalized through field metadata',
    () async {
      final dataSet = FdcDataSet(
        fields: <FdcFieldDef>[
          const FdcIntegerField(name: 'quantity'),
          FdcIntegerField(
            name: 'doubleQuantity',
            calculatedValue: (row) => "${row.intValue('quantity')! * 2}",
          ),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{'quantity': 5},
          ],
        ),
      );
      await dataSet.open();

      expect(dataSet.fieldByName('doubleQuantity').asInteger, 10);
    },
  );
}
