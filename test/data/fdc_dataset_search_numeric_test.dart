import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcDataSet search', () {
    test('numeric-start search includes numeric fields', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply('20');

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Ethan Evans');
    });

    test(
      'non-numeric-start search with only numeric fields matches nothing',
      () async {
        final dataSet = _createDataSet(
          adapter: FdcMemoryDataAdapter(rows: _rows),
        );

        await dataSet.open();

        await dataSet.search.apply('amount', fields: const ['amount']);

        expect(dataSet.recordCount, 0);
      },
    );

    test('numeric text search uses digit boundaries in text fields', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcStringField(size: 255, name: 'code'),
          FdcIntegerField(name: 'amount'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'name': 'Future year', 'code': 'INV-2026', 'amount': 10},
            {'name': 'Integer exact', 'code': 'INV-1000', 'amount': 20},
            {'name': 'Text segment', 'code': 'A20', 'amount': 10},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply(
        '20',
        fields: const ['name', 'code', 'amount'],
      );

      expect(dataSet.recordCount, 2);
      expect(dataSet.fieldValue('name'), 'Integer exact');
      dataSet.next();
      expect(dataSet.fieldValue('name'), 'Text segment');
    });

    test(
      'leading zero numeric search tokens do not collapse to integer values',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcStringField(size: 255, name: 'code'),
            FdcIntegerField(name: 'amount'),
            FdcDecimalField(name: 'balance', precision: 12, scale: 2),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': 'Zero Value',
                'code': 'ZERO',
                'amount': 0,
                'balance': FdcDecimal.parse('0.00', scale: 2),
              },
              {
                'name': 'One Value',
                'code': 'ONE',
                'amount': 1,
                'balance': FdcDecimal.parse('1.00', scale: 2),
              },
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          '0000000',
          fields: const ['name', 'code', 'amount', 'balance'],
        );
        expect(dataSet.recordCount, 0);

        await dataSet.search.apply(
          '00000001',
          fields: const ['name', 'code', 'amount', 'balance'],
        );
        expect(dataSet.recordCount, 0);
      },
    );

    test('time-like search includes time fields', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply('08:00', fields: const ['time']);

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Alice Johnson');
    });

    test('time-like search requires the full configured time format', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply(
        '8:00',
        fields: const ['time'],
        fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
          'time': (_) => throw StateError('Formatter should not run'),
        },
      );

      expect(dataSet.recordCount, 0);
    });

    test(
      'date-like search matches dotted day-month-year date values',
      () async {
        final dataSet = _createDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': 'Date Person',
                'city': 'New York',
                'status': 'active',
                'amount': 10,
                'active': true,
                'birthDate': DateTime(1965),
                'time': FdcTime(hour: 8),
              },
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          '01.01.1965',
          fields: const ['birthDate'],
          formatSettings: const FdcFormatSettings(dateFormat: 'dd.MM.yyyy'),
        );

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'Date Person');
      },
    );

    test('dateTime search requires date and time component', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcDateTimeField(name: 'lastContact'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'name': 'DateTime Person', 'lastContact': DateTime(1965, 1, 1, 8)},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply(
        '01.01.1965 08:00',
        fields: const ['lastContact'],
        formatSettings: const FdcFormatSettings(dateFormat: 'dd.MM.yyyy'),
      );

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'DateTime Person');
    });

    test(
      'date-like search matches dateTime date component without time component',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcDateTimeField(name: 'lastContact'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': 'DateTime Person',
                'lastContact': DateTime(1965, 1, 1, 8),
              },
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          '01.01.1965',
          fields: const ['lastContact'],
          formatSettings: const FdcFormatSettings(dateFormat: 'dd.MM.yyyy'),
        );

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'DateTime Person');
      },
    );

    test(
      'search uses display-aware date field formatter when provided',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcDateField(name: 'birthDate'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'name': 'Displayed Date Person', 'birthDate': DateTime(1965)},
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          '01.01.1965',
          fields: const ['birthDate'],
          formatSettings: const FdcFormatSettings(dateFormat: 'dd.MM.yyyy'),
          fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
            'birthDate': (value) {
              final date = value as DateTime;
              final dd = date.day.toString().padLeft(2, '0');
              final mm = date.month.toString().padLeft(2, '0');
              final yyyy = date.year.toString().padLeft(4, '0');
              return '$dd.$mm.$yyyy';
            },
          },
        );

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'Displayed Date Person');
      },
    );

    test(
      'search uses display-aware decimal field formatter when provided',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcDecimalField(name: 'balance', precision: 12, scale: 2),
          ],
          formatSettings: const FdcFormatSettings(
            decimalSeparator: ',',
            thousandSeparator: '.',
          ),

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': 'Displayed Decimal Person',
                'balance': FdcDecimal.parse('1234.50', scale: 2),
              },
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          '1.234,50',
          fields: const ['balance'],
          fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
            'balance': (_) => '1.234,50',
          },
        );

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'Displayed Decimal Person');
      },
    );

    test(
      'decimal-like search matches comma input against raw decimal values',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcDecimalField(name: 'balance', precision: 12, scale: 2),
          ],
          formatSettings: const FdcFormatSettings(
            decimalSeparator: ',',
            thousandSeparator: '.',
          ),

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': 'Raw Decimal Person',
                'balance': FdcDecimal.parse('750.25', scale: 2),
              },
              {
                'name': 'Other Decimal Person',
                'balance': FdcDecimal.parse('100.00', scale: 2),
              },
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply('750,25', fields: const ['name', 'balance']);

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'Raw Decimal Person');
      },
    );

    test(
      'decimal-like search compares compiled decimal values across scales',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcDecimalField(name: 'balance', precision: 12, scale: 4),
          ],
          formatSettings: const FdcFormatSettings(
            decimalSeparator: ',',
            thousandSeparator: '.',
          ),

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': 'Scaled Decimal Person',
                'balance': FdcDecimal.parse('750.2500', scale: 4),
              },
              {
                'name': 'Other Decimal Person',
                'balance': FdcDecimal.parse('750.2600', scale: 4),
              },
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply('750,25', fields: const ['balance']);

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'Scaled Decimal Person');
      },
    );

    test(
      'decimal-like raw decimal fast path avoids display formatter fallback',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcDecimalField(name: 'balance', precision: 12, scale: 2),
          ],
          formatSettings: const FdcFormatSettings(
            decimalSeparator: ',',
            thousandSeparator: '.',
          ),

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'balance': FdcDecimal.parse('750.25', scale: 2)},
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          '750,25',
          fields: const ['balance'],
          fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
            'balance': (_) => throw StateError('Formatter should not run'),
          },
        );

        expect(dataSet.recordCount, 1);
      },
    );

    test(
      'decimal-like raw decimal fast path uses configured locale separators',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcDecimalField(name: 'balance', precision: 12, scale: 2),
          ],
          formatSettings: const FdcFormatSettings(
            decimalSeparator: ',',
            thousandSeparator: '.',
          ),

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'balance': FdcDecimal.parse('1234.50', scale: 2)},
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          '1.234,50',
          fields: const ['balance'],
          fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
            'balance': (_) => throw StateError('Formatter should not run'),
          },
        );

        expect(dataSet.recordCount, 1);
      },
    );

    test('decimal search requires configured decimal separator', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcDecimalField(name: 'balance', precision: 12, scale: 2),
        ],
        formatSettings: const FdcFormatSettings(
          decimalSeparator: ',',
          thousandSeparator: '.',
        ),

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {
              'name': 'Comma Decimal Person',
              'balance': FdcDecimal.parse('750.25', scale: 2),
            },
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply('750.25', fields: const ['balance']);

      expect(dataSet.recordCount, 0);

      await dataSet.search.apply('750,25', fields: const ['balance']);

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Comma Decimal Person');
    });

    test(
      'partial date-like token does not enable decimal formatter fallback',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcDecimalField(name: 'balance', precision: 12, scale: 2),
            FdcDateField(name: 'birthDate'),
          ],
          formatSettings: const FdcFormatSettings(
            decimalSeparator: ',',
            thousandSeparator: '.',
            dateFormat: 'dd.MM.yyyy',
          ),

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': 'Partial Date Person',
                'balance': FdcDecimal.parse('1.01', scale: 2),
                'birthDate': DateTime(1965),
              },
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          '01.01',
          fields: const ['balance', 'birthDate'],
          fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
            'balance': (_) => '01.01',
          },
        );

        expect(dataSet.recordCount, 0);
      },
    );

    test('integer-looking token matches decimal value exactly', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcDecimalField(name: 'balance', precision: 12, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {
              'name': 'Exact Decimal Person',
              'balance': FdcDecimal.parse('25.00', scale: 2),
            },
            {
              'name': 'Other Decimal Person',
              'balance': FdcDecimal.parse('25.10', scale: 2),
            },
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply('25', fields: const ['balance']);

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Exact Decimal Person');
    });

    test(
      'incomplete decimal token does not search raw decimal field',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcDecimalField(name: 'balance', precision: 12, scale: 2),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'balance': FdcDecimal.parse('25.00', scale: 2)},
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply('25.', fields: const ['balance']);

        expect(dataSet.recordCount, 0);
      },
    );

    test(
      'decimal search uses exact numeric equality, not formatted contains',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcDecimalField(name: 'balance', precision: 12, scale: 3),
          ],
          formatSettings: const FdcFormatSettings(
            decimalSeparator: ',',
            thousandSeparator: '.',
          ),

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': 'Text has 4873',
                'balance': FdcDecimal.parse('487339.000', scale: 3),
              },
              {
                'name': 'Decimal exact',
                'balance': FdcDecimal.parse('4873.000', scale: 3),
              },
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply('4873', fields: const ['name', 'balance']);

        expect(dataSet.recordCount, 2);
        expect(dataSet.fieldValue('name'), 'Text has 4873');
        dataSet.next();
        expect(dataSet.fieldValue('name'), 'Decimal exact');
      },
    );
  });
}

FdcDataSet _createDataSet({IFdcDataAdapter? adapter}) {
  return FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name'),
      FdcStringField(size: 255, name: 'city'),
      FdcStringField(size: 255, name: 'status'),
      FdcIntegerField(name: 'amount'),
      FdcBooleanField(name: 'active'),
      FdcDateField(name: 'birthDate'),
      FdcTimeField(name: 'time'),
    ],

    adapter:
        adapter ?? FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );
}

final _rows = <Map<String, Object?>>[
  {
    'name': 'Alice Johnson',
    'city': 'New York',
    'status': 'active',
    'amount': 10,
    'active': true,
    'birthDate': DateTime(2024),
    'time': FdcTime(hour: 8),
  },
  {
    'name': 'Ethan Evans',
    'city': 'Chicago',
    'status': 'active',
    'amount': 20,
    'active': true,
    'birthDate': DateTime(2024, 2),
    'time': FdcTime(hour: 9, minute: 30),
  },
  {
    'name': 'Mia Miller',
    'city': 'New York',
    'status': 'inactive',
    'amount': 30,
    'active': false,
    'birthDate': DateTime(2024, 3),
    'time': FdcTime(hour: 10),
  },
];
