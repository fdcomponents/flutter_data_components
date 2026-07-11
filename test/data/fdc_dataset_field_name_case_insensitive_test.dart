import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'field lookups are case-insensitive while preserving field name casing',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'Name', size: 50),
          FdcIntegerField(name: 'Quantity'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'QUANTITY': 3},
          ],
        ),
      );

      await dataSet.open();

      expect(dataSet.hasField('name'), isTrue);
      expect(dataSet.hasField('NAME'), isTrue);
      expect(dataSet.fieldIndex('name'), 0);
      expect(dataSet.fieldIndex('NAME'), 0);
      expect(dataSet.fieldNames, const <String>['Name', 'Quantity']);
      expect(dataSet.fieldDef<FdcStringField>('name').name, 'Name');
      expect(dataSet.fieldByName('NAME').asString, 'Alpha');
      expect(dataSet.fieldValue('quantity'), 3);

      dataSet.edit();
      dataSet.setFieldValue('nAmE', 'Beta');
      expect(dataSet.fieldByName('Name').asString, 'Beta');
    },
  );

  test('filter and sort field names are case-insensitive', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'Name', size: 50),
        FdcIntegerField(name: 'Quantity'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'Name': 'Charlie', 'Quantity': 3},
          {'Name': 'Alpha', 'Quantity': 1},
          {'Name': 'Beta', 'Quantity': 2},
        ],
      ),
    );

    await dataSet.open();

    await dataSet.filter.where('name').contains('a').apply();
    await dataSet.sort.set(const <FdcDataSetSort>[
      FdcDataSetSort(fieldName: 'NAME'),
    ]);

    expect(dataSet.recordCount, 3);

    // Sorting positions the dataset on the first visible row.
    expect(dataSet.fieldValue('name'), 'Alpha');
    dataSet.next();
    expect(dataSet.fieldValue('NAME'), 'Beta');
  });

  test('unknown filter field throws a dataset error', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(name: 'Name', size: 50)],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'Name': 'Alpha'},
        ],
      ),
    );

    await dataSet.open();

    await expectLater(
      Future<bool>.sync(
        () => dataSet.filter.where('name222').endsWith('c').apply(),
      ),
      throwsA(
        isA<FdcDataSetException>().having(
          (error) => error.message,
          'message',
          'Unknown filter field "name222" in dataset FdcDataSet.',
        ),
      ),
    );
    expect(dataSet.filter.isEmpty, isTrue);
    expect(dataSet.recordCount, 1);
  });

  test(
    'sort controller canonicalizes field names case-insensitively',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'Name', size: 50),
          FdcIntegerField(name: 'Quantity'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'Name': 'Charlie', 'Quantity': 3},
            {'Name': 'Alpha', 'Quantity': 1},
            {'Name': 'Beta', 'Quantity': 2},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.sort
          .sortBy('quantity')
          .descending
          .sortBy('name')
          .ascending
          .apply();

      expect(dataSet.sort.items.length, 2);
      expect(dataSet.sort.items[0].fieldName, 'Quantity');
      expect(dataSet.sort.items[0].sortType, FdcSortType.descending);
      expect(dataSet.sort.items[1].fieldName, 'Name');
      expect(dataSet.sort.items[1].sortType, FdcSortType.ascending);

      dataSet.first();
      expect(dataSet.fieldValue('name'), 'Charlie');
    },
  );

  test(
    'unknown sort field throws a dataset error and leaves sort unchanged',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'Name', size: 50)],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'Name': 'Alpha'},
          ],
        ),
      );

      await dataSet.open();

      await expectLater(
        Future<bool>.sync(
          () => dataSet.sort.sortBy('missing').ascending.apply(),
        ),
        throwsA(
          isA<FdcDataSetException>().having(
            (error) => error.message,
            'message',
            'Unknown sort field "missing" in dataset FdcDataSet.',
          ),
        ),
      );
      expect(dataSet.sort.isEmpty, isTrue);
    },
  );

  test('duplicate sort fields differing only by case are rejected', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(name: 'Name', size: 50)],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'Name': 'Alpha'},
        ],
      ),
    );

    await dataSet.open();

    await expectLater(
      Future<bool>.sync(
        () => dataSet.sort.set(const <FdcDataSetSort>[
          FdcDataSetSort(fieldName: 'name'),
          FdcDataSetSort(fieldName: 'NAME', sortType: FdcSortType.descending),
        ]),
      ),
      throwsA(
        isA<FdcDataSetException>().having(
          (error) => error.message,
          'message',
          'Duplicate sort field "Name" in dataset FdcDataSet.',
        ),
      ),
    );
    expect(dataSet.sort.isEmpty, isTrue);
  });

  test('string sort values are case-insensitive', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'Name', size: 50),
        FdcIntegerField(name: 'Age'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'Name': 'Emily Davis', 'Age': 22},
          {'Name': 'Emma Baker', 'Age': 24},
          {'Name': 'alice', 'Age': 23},
          {'Name': 'alice', 'Age': 21},
          {'Name': 'alice', 'Age': 20},
        ],
      ),
    );

    await dataSet.open();

    await dataSet.sort
        .sortBy('name')
        .ascending
        .sortBy('age')
        .descending
        .apply();

    dataSet.first();
    expect(dataSet.fieldValue('Name'), 'alice');
    expect(dataSet.fieldValue('Age'), 23);
    dataSet.next();
    expect(dataSet.fieldValue('Name'), 'alice');
    expect(dataSet.fieldValue('Age'), 21);
    dataSet.next();
    expect(dataSet.fieldValue('Name'), 'alice');
    expect(dataSet.fieldValue('Age'), 20);
    dataSet.next();
    expect(dataSet.fieldValue('Name'), 'Emily Davis');
    dataSet.next();
    expect(dataSet.fieldValue('Name'), 'Emma Baker');
  });

  test('duplicate field names differing only by case are rejected', () {
    expect(
      () => FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'name', size: 50),
          FdcStringField(name: 'Name', size: 50),
        ],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      ),
      throwsA(
        isA<FdcDataSetException>().having(
          (error) => error.message,
          'message',
          'Duplicate field name "Name" in dataset FdcDataSet. '
              'Field name "name" already exists.',
        ),
      ),
    );
  });
}
