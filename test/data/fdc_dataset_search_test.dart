import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_data_components/src/data/fdc_dataset_search.dart'
    as search_internal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcDataSet search', () {
    test(
      'search state hashCode is order-independent for sets and maps',
      () async {
        String formatter(Object? value) => 'formatted:$value';

        final first = FdcDataSetSearchState(
          text: 'query',
          mode: FdcSearchMode.anyWord,
          fields: <String>{'name', 'age'},
          fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
            'name': formatter,
            'age': formatter,
          },
          fieldFormatSettings: const <String, FdcFormatSettings>{
            'name': FdcFormatSettings(locale: 'en_US'),
            'age': FdcFormatSettings(locale: 'hr_HR'),
          },
        );

        final second = FdcDataSetSearchState(
          text: 'query',
          mode: FdcSearchMode.anyWord,
          fields: <String>{'age', 'name'},
          fieldTextFormatters: <String, FdcSearchFieldTextFormatter>{
            'age': formatter,
            'name': formatter,
          },
          fieldFormatSettings: const <String, FdcFormatSettings>{
            'age': FdcFormatSettings(locale: 'hr_HR'),
            'name': FdcFormatSettings(locale: 'en_US'),
          },
        );

        expect(first, second);
        expect(first.hashCode, second.hashCode);
      },
    );

    test('normalized search state hashCode is order-independent', () async {
      const first = FdcDataSetSearchState(
        text: ' query ',
        fields: <String>{'Name', 'AGE'},
        fieldFormatSettings: <String, FdcFormatSettings>{
          'Name': FdcFormatSettings(locale: 'en_US'),
          'AGE': FdcFormatSettings(locale: 'hr_HR'),
        },
      );

      const second = FdcDataSetSearchState(
        text: 'query',
        fields: <String>{'age', 'name'},
        fieldFormatSettings: <String, FdcFormatSettings>{
          'age': FdcFormatSettings(locale: 'hr_HR'),
          'name': FdcFormatSettings(locale: 'en_US'),
        },
      );

      final normalizedFirst = first.normalized();
      final normalizedSecond = second.normalized();

      expect(normalizedFirst, normalizedSecond);
      expect(normalizedFirst.hashCode, normalizedSecond.hashCode);
    });

    test('phrase search is case insensitive by default', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply('alice');

      expect(dataSet.search.active, isTrue);
      expect(dataSet.search.state.isActive, isTrue);
      expect(dataSet.search.state.mode, FdcSearchMode.phrase);
      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Alice Johnson');
    });

    test('phrase search can be case sensitive', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply('alice', caseSensitive: true);

      expect(dataSet.recordCount, 0);

      await dataSet.search.apply('Alice', caseSensitive: true);

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Alice Johnson');
    });

    test(
      'phrase search preserves repeated tokens after case normalization',
      () async {
        final prepared = search_internal.prepareDataSetSearch(
          search: const FdcDataSetSearchState(text: 'Alice alice'),
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
          fieldIndexByName: const <String, int>{'name': 0},
          formatSettings: const FdcFormatSettings(),
        );

        expect(prepared, isNotNull);
        expect(prepared!.phrase, 'alice alice');
        expect(prepared.tokens, const <String>['alice', 'alice']);
      },
    );

    test(
      'search token normalization de-duplicates case-insensitive tokens',
      () async {
        final prepared = search_internal.prepareDataSetSearch(
          search: const FdcDataSetSearchState(
            text: 'Alice alice ALICE',
            mode: FdcSearchMode.anyWord,
          ),
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
          fieldIndexByName: const <String, int>{'name': 0},
          formatSettings: const FdcFormatSettings(),
        );

        expect(prepared, isNotNull);
        expect(prepared!.phrase, 'alice alice alice');
        expect(prepared.tokens, const <String>['alice']);
      },
    );

    test(
      'search token normalization preserves case-sensitive token identity',
      () async {
        final prepared = search_internal.prepareDataSetSearch(
          search: const FdcDataSetSearchState(
            text: 'Alice alice ALICE Alice',
            mode: FdcSearchMode.anyWord,
            caseSensitive: true,
          ),
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
          fieldIndexByName: const <String, int>{'name': 0},
          formatSettings: const FdcFormatSettings(),
        );

        expect(prepared, isNotNull);
        expect(prepared!.phrase, 'Alice alice ALICE Alice');
        expect(prepared.tokens, const <String>['Alice', 'alice', 'ALICE']);
      },
    );

    test('allWords matches multiple words within the same field', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply('alice johnson', mode: FdcSearchMode.allWords);

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Alice Johnson');
    });

    test('allWords matches multiple words across different fields', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply(
        'alice new york',
        mode: FdcSearchMode.allWords,
      );

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Alice Johnson');
    });

    test('anyWord matches multiple words within the same field', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply('alice johnson', mode: FdcSearchMode.anyWord);

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Alice Johnson');
    });

    test('anyWord matches multiple words across different fields', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply(
        'chicago inactive',
        mode: FdcSearchMode.anyWord,
      );

      expect(dataSet.recordCount, 2);
      expect(dataSet.fieldValue('name'), 'Ethan Evans');
    });

    test('anyWord matches a later token within the same field', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply(
        'missing johnson',
        mode: FdcSearchMode.anyWord,
      );

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Alice Johnson');
    });

    test(
      'anyWord matches words in the same field across different records',
      () async {
        final dataSet = _createDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
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
                'name': 'Michael Miller',
                'city': 'Boston',
                'status': 'active',
                'amount': 40,
                'active': true,
                'birthDate': DateTime(2024, 4),
              },
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          'alice michael',
          mode: FdcSearchMode.anyWord,
        );

        expect(dataSet.recordCount, 2);
      },
    );

    test(
      'allWords does not match words chicago across different records',
      () async {
        final dataSet = _createDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
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
                'name': 'Michael Miller',
                'city': 'Boston',
                'status': 'active',
                'amount': 40,
                'active': true,
                'birthDate': DateTime(2024, 4),
              },
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          'alice michael',
          mode: FdcSearchMode.allWords,
        );

        expect(dataSet.recordCount, 0);
      },
    );

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

    test('boolean fields are never searched', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply('true', fields: const ['active']);

      expect(dataSet.recordCount, 0);
    });

    test('text search uses only text-like fields by default', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply('2024');

      expect(dataSet.recordCount, 0);
    });
    test('search combines with active filters', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.filter.where('status').equals('active').apply();
      await dataSet.search.apply('chicago', mode: FdcSearchMode.allWords);

      expect(dataSet.filter.active, isTrue);
      expect(dataSet.search.active, isTrue);
      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Ethan Evans');
    });

    test(
      'duplicate logical search keeps retained appended row visible',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcStringField(size: 255, name: 'status'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha', 'status': 'active'},
              {'name': 'Beta', 'status': 'active'},
            ],
          ),
        );

        await dataSet.open();

        await dataSet.search.apply(
          'Alpha',
          fields: const ['name'],
          fieldTextFormatters: {'name': (value) => value?.toString() ?? ''},
        );
        expect(dataSet.recordCount, 1);

        dataSet.append();
        dataSet.setFieldValue('name', 'Draft row');
        dataSet.setFieldValue('status', 'draft');
        dataSet.post();

        expect(dataSet.recordCount, 2);
        expect(dataSet.fieldValue('name'), 'Draft row');

        await dataSet.search.apply(
          'Alpha',
          fields: const ['name'],
          fieldTextFormatters: {'name': (value) => value?.toString() ?? ''},
        );

        expect(dataSet.recordCount, 2);
        expect(dataSet.fieldValue('name'), 'Draft row');
      },
    );

    test('changed logical search clears retained appended row', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcStringField(size: 255, name: 'status'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'status': 'active'},
            {'name': 'Beta', 'status': 'active'},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.search.apply('Alpha', fields: const ['name']);
      dataSet.append();
      dataSet.setFieldValue('name', 'Draft row');
      dataSet.setFieldValue('status', 'draft');
      dataSet.post();

      expect(dataSet.recordCount, 2);

      await dataSet.search.apply('Beta', fields: const ['name']);

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Beta');
    });

    test('search and clearSearch update the search state', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();

      await dataSet.search.apply('new york');

      expect(dataSet.recordCount, 2);
      expect(dataSet.search.state.text, 'new york');

      await dataSet.search.clear();

      expect(dataSet.search.active, isFalse);
      expect(dataSet.recordCount, 3);
    });

    test('close clears search filter sort and view state', () async {
      var filterChangeCount = 0;
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(rows: _rows),
      );

      await dataSet.open();
      FdcDataSetInternal.addFilterChangedListener(
        dataSet,
        (_) => filterChangeCount++,
      );

      await dataSet.search.apply('alice', fields: const ['name']);
      await dataSet.filter.set(const <FdcDataSetFilter>[
        FdcDataSetFilter(
          fieldName: 'status',
          operator: FdcFilterOperator.equals,
          value: 'active',
        ),
      ]);
      await dataSet.sort.set(const <FdcDataSetSort>[
        FdcDataSetSort(fieldName: 'amount'),
      ]);

      expect(dataSet.search.active, isTrue);
      expect(dataSet.filter.active, isTrue);
      expect(dataSet.sort.active, isTrue);
      expect(dataSet.search.state.isActive, isTrue);
      expect(dataSet.filter.items, isNotEmpty);
      expect(dataSet.sort.items, isNotEmpty);

      dataSet.close();

      expect(dataSet.isOpen, isFalse);
      expect(dataSet.search.active, isFalse);
      expect(dataSet.filter.active, isFalse);
      expect(dataSet.sort.active, isFalse);
      expect(dataSet.search.state.isActive, isFalse);
      expect(dataSet.filter.items, isEmpty);
      expect(dataSet.sort.items, isEmpty);
      expect(dataSet.recordCount, 0);
      expect(filterChangeCount, greaterThan(0));
    });

    test('closed dataset ignores search filter and sort operations', () async {
      var workStarted = 0;
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcStringField(size: 255, name: 'status'),
          FdcIntegerField(name: 'amount'),
        ],
        onWorkStarted: (_, _) => workStarted++,

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      );

      expect(dataSet.isOpen, isFalse);

      await expectLater(
        dataSet.search.apply('alpha', fields: const ['missing']),
        completes,
      );
      await dataSet.search.apply('alpha');
      await dataSet.search.clear();
      await dataSet.search.clear();

      expect(
        await dataSet.filter.set(const <FdcDataSetFilter>[
          FdcDataSetFilter(
            fieldName: 'missing',
            operator: FdcFilterOperator.equals,
            value: 'x',
          ),
        ]),
        isFalse,
      );
      expect(
        await dataSet.filter.set(const <FdcDataSetFilter>[
          FdcDataSetFilter(
            fieldName: 'missing',
            operator: FdcFilterOperator.equals,
            value: 'x',
          ),
        ]),
        isFalse,
      );
      expect(await dataSet.filter.clear(), isFalse);
      expect(await dataSet.filter.clear(), isFalse);

      expect(
        await dataSet.sort.set(const <FdcDataSetSort>[
          FdcDataSetSort(fieldName: 'missing'),
        ]),
        isFalse,
      );
      expect(
        await dataSet.sort.set(const <FdcDataSetSort>[
          FdcDataSetSort(fieldName: 'missing'),
        ]),
        isFalse,
      );
      expect(await dataSet.sort.clear(), isFalse);
      expect(await dataSet.sort.clear(), isFalse);

      expect(dataSet.search.active, isFalse);
      expect(dataSet.filter.active, isFalse);
      expect(dataSet.sort.active, isFalse);
      expect(workStarted, 0);
    });

    test(
      'explicit search fields limit matching to the selected fields',
      () async {
        final dataSet = _createDataSet(
          adapter: FdcMemoryDataAdapter(rows: _rows),
        );

        await dataSet.open();

        await dataSet.search.apply('active', fields: const ['city']);

        expect(dataSet.recordCount, 0);

        await dataSet.search.apply(
          'active',
          mode: FdcSearchMode.exactPhrase,
          fields: const ['status'],
        );

        expect(dataSet.recordCount, 2);
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
