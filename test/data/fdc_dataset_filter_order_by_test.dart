import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'filter orderBy applies filters and multi-sort in one fluent expression',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'Name', size: 50),
          FdcIntegerField(name: 'Age'),
          FdcStringField(name: 'Status', size: 50),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'Name': 'Emily Davis', 'Age': 22, 'Status': 'active'},
            {'Name': 'Emma Baker', 'Age': 24, 'Status': 'inactive'},
            {'Name': 'alice', 'Age': 23, 'Status': 'active'},
            {'Name': 'alice', 'Age': 21, 'Status': 'active'},
            {'Name': 'alice', 'Age': 20, 'Status': 'inactive'},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.filter
          .where('status')
          .equals('active')
          .orderBy('name')
          .ascending
          .orderBy('age')
          .descending
          .apply();

      expect(dataSet.filter.items.length, 1);
      expect(dataSet.sort.items.length, 2);
      expect(dataSet.sort.items[0].fieldName, 'Name');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(dataSet.sort.items[1].fieldName, 'Age');
      expect(dataSet.sort.items[1].sortType, FdcSortType.descending);

      dataSet.first();
      expect(dataSet.fieldValue('name'), 'alice');
      expect(dataSet.fieldValue('age'), 23);
      dataSet.next();
      expect(dataSet.fieldValue('name'), 'alice');
      expect(dataSet.fieldValue('age'), 21);
      dataSet.next();
      expect(dataSet.fieldValue('name'), 'Emily Davis');
      expect(dataSet.fieldValue('age'), 22);
      expect(dataSet.eof, isFalse);
      dataSet.next();
      expect(dataSet.eof, isTrue);
    },
  );

  test(
    'filter orderBy can start from filter controller with no conditions',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'Name', size: 50)],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'Name': 'Charlie'},
            {'Name': 'Alpha'},
            {'Name': 'Bravo'},
          ],
        ),
      );

      await dataSet.open();

      await dataSet.filter.orderBy('name').ascending.apply();

      expect(dataSet.filter.items, isEmpty);
      expect(dataSet.sort.items.length, 1);
      dataSet.first();
      expect(dataSet.fieldValue('name'), 'Alpha');
    },
  );

  test('filter conditions cannot be added after orderBy', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'Name', size: 50),
        FdcIntegerField(name: 'Age'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'Name': 'Alpha', 'Age': 1},
        ],
      ),
    );

    await dataSet.open();

    expect(
      () => dataSet.filter
          .where('name')
          .contains('a')
          .orderBy('age')
          .descending
          .where('name')
          .equals('Alpha'),
      throwsStateError,
    );
  });

  test(
    'filter orderBy validates unknown and duplicate sort fields on apply',
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

      expect(
        () => dataSet.filter
            .where('name')
            .equals('Alpha')
            .orderBy('missing')
            .ascending
            .apply(),
        throwsA(isA<FdcDataSetException>()),
      );

      expect(
        () => dataSet.filter
            .where('name')
            .equals('Alpha')
            .orderBy('name')
            .ascending
            .orderBy('NAME')
            .descending
            .apply(),
        throwsA(isA<FdcDataSetException>()),
      );
    },
  );
}
