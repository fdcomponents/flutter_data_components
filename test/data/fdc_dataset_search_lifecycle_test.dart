import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcDataSet search', () {
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
