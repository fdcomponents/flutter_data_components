import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcDataSet search', () {
    test(
      'locale grouped integer search is not treated as decimal-only',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcIntegerField(name: 'amount'),
            FdcDecimalField(name: 'balance', precision: 12, scale: 2),
          ],
          formatSettings: const FdcFormatSettings(
            decimalSeparator: ',',
            thousandSeparator: '.',
          ),

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': 'Grouped Integer Person',
                'amount': 1234,
                'balance': FdcDecimal.parse('100.00', scale: 2),
              },
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply('1.234');

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'Grouped Integer Person');
      },
    );

    test(
      'decimal-like search keeps text fields but skips incompatible integers',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcIntegerField(name: 'age'),
            FdcDecimalField(name: 'balance', precision: 12, scale: 2),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': '750,25 text only',
                'age': 750,
                'balance': FdcDecimal.parse('100.00', scale: 2),
              },
              {
                'name': 'Displayed Decimal Person',
                'age': 10,
                'balance': FdcDecimal.parse('750.25', scale: 2),
              },
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          '750,25',
          fields: const ['name', 'age', 'balance'],
          fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
            'balance': (value) {
              if (value is FdcDecimal &&
                  value == FdcDecimal.parse('750.25', scale: 2)) {
                return '750,25';
              }
              return value?.toString() ?? '';
            },
          },
        );

        expect(dataSet.recordCount, 2);
        expect(dataSet.fieldValue('name'), '750,25 text only');
      },
    );

    test(
      'time-like raw time fast path avoids display formatter fallback',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcTimeField(name: 'time')],
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'time': FdcTime(hour: 8)},
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          '08:00',
          fields: const ['time'],
          fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
            'time': (_) => throw StateError('Formatter should not run'),
          },
        );

        expect(dataSet.recordCount, 1);
      },
    );

    test('time-like search matches dateTime time component', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcDateTimeField(name: 'lastContact'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'name': 'Morning Contact', 'lastContact': DateTime(2024, 1, 1, 8)},
            {'name': 'Later Contact', 'lastContact': DateTime(2024, 1, 1, 9)},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply(
        '08:00',
        fields: const ['lastContact'],
        fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
          'lastContact': (_) => throw StateError('Formatter should not run'),
        },
      );

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Morning Contact');
    });

    test('time-like search matches by minute precision', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcTimeField(name: 'time'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'name': 'Within Minute', 'time': FdcTime(hour: 8, second: 30)},
            {'name': 'Other Minute', 'time': FdcTime(hour: 8, minute: 1)},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply('08:00', fields: const ['time']);

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Within Minute');
    });

    test('incomplete time token does not search raw time field', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcTimeField(name: 'time'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'name': 'Morning Start', 'time': FdcTime(hour: 8, minute: 30)},
            {'name': 'Nine Start', 'time': FdcTime(hour: 9)},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply(
        '08:',
        fields: const ['time'],
        fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
          'time': (_) => throw StateError('Formatter should not run'),
        },
      );

      expect(dataSet.recordCount, 0);
    });

    test('incomplete time token does not search raw dateTime field', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcDateTimeField(name: 'lastContact'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {
              'name': 'Morning Contact',
              'lastContact': DateTime(2024, 1, 1, 8, 45),
            },
            {'name': 'Nine Contact', 'lastContact': DateTime(2024, 1, 1, 9)},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply(
        '08:',
        fields: const ['lastContact'],
        fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
          'lastContact': (_) => throw StateError('Formatter should not run'),
        },
      );

      expect(dataSet.recordCount, 0);
    });

    test('incomplete minute token does not search raw time field', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcTimeField(name: 'time'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'name': 'Eight Oh Three', 'time': FdcTime(hour: 8, minute: 3)},
            {'name': 'Eight Thirty', 'time': FdcTime(hour: 8, minute: 30)},
            {
              'name': 'Eight Thirty Nine',
              'time': FdcTime(hour: 8, minute: 39, second: 59),
            },
            {'name': 'Eight Forty', 'time': FdcTime(hour: 8, minute: 40)},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply(
        '08:3',
        fields: const ['time'],
        fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
          'time': (_) => throw StateError('Formatter should not run'),
        },
      );

      expect(dataSet.recordCount, 0);
    });

    test('incomplete second token does not search raw time field', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcTimeField(name: 'time'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {
              'name': 'Second One',
              'time': FdcTime(hour: 8, minute: 30, second: 1),
            },
            {
              'name': 'Second Ten',
              'time': FdcTime(hour: 8, minute: 30, second: 10),
            },
            {
              'name': 'Second Nineteen',
              'time': FdcTime(hour: 8, minute: 30, second: 19),
            },
            {
              'name': 'Second Twenty',
              'time': FdcTime(hour: 8, minute: 30, second: 20),
            },
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply(
        '08:30:1',
        fields: const ['time'],
        fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
          'time': (_) => throw StateError('Formatter should not run'),
        },
      );

      expect(dataSet.recordCount, 0);
    });

    test('structured time search keeps string fallback matches', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcTimeField(name: 'time'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'name': 'Alice Johnson 22:31', 'time': FdcTime(hour: 9)},
            {'name': 'Temporal match', 'time': FdcTime(hour: 22, minute: 31)},
            {'name': 'No match', 'time': FdcTime(hour: 10)},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply('22:31');

      expect(dataSet.recordCount, 2);
      expect(dataSet.fieldValue('name'), 'Alice Johnson 22:31');
    });

    test(
      'structured time search still supports explicit text-only fields',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcTimeField(name: 'time'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'name': 'Text says 08:', 'time': FdcTime(hour: 9)},
              {'name': 'Temporal only', 'time': FdcTime(hour: 10)},
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply('08:', fields: const ['name']);

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'Text says 08:');
      },
    );

    test(
      'incomplete date token keeps text fallback but skips raw date field',
      () async {
        var formatterCalls = 0;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcDateField(name: 'birthDate'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': 'Text says 01.05.20 but date is different',
                'birthDate': DateTime(2024),
              },
              {'name': 'Date match', 'birthDate': DateTime(2020, 5)},
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          '01.05.20',
          fields: const ['name', 'birthDate'],
          formatSettings: const FdcFormatSettings(dateFormat: 'dd.MM.yyyy'),
          fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
            'birthDate': (value) {
              formatterCalls++;
              final date = value as DateTime;
              return '${date.day.toString().padLeft(2, '0')}.'
                  '${date.month.toString().padLeft(2, '0')}.'
                  '${date.year.toString().padLeft(4, '0')}';
            },
          },
        );

        expect(dataSet.recordCount, 1);
        expect(
          dataSet.fieldValue('name'),
          'Text says 01.05.20 but date is different',
        );
        expect(formatterCalls, 0);
      },
    );

    test(
      'structured date search matches full dotted display date exactly',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcDateField(name: 'birthDate'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'name': 'Wrong date', 'birthDate': DateTime(1966, 2)},
              {'name': 'Expected date', 'birthDate': DateTime(1966)},
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          '01.01.1966',
          fields: const ['name', 'birthDate'],
          formatSettings: const FdcFormatSettings(dateFormat: 'dd.MM.yyyy'),
        );

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'Expected date');
      },
    );

    test('structured date search respects yyyy-dd-MM global format', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcDateField(name: 'birthDate'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'name': 'May 25', 'birthDate': DateTime(2026, 5, 25)},
            {'name': 'August 5', 'birthDate': DateTime(2026, 8, 5)},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply(
        '2026-25-05',
        fields: const ['birthDate'],
        formatSettings: const FdcFormatSettings(dateFormat: 'yyyy-dd-MM'),
      );

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'May 25');
    });
  });
}
