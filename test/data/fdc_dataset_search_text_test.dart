import 'package:flutter_data_components/fdc.dart';
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
