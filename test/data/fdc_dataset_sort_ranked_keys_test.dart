import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcDataSet ranked sort keys', () {
    test(
      'sorts strings case-insensitively with deterministic case tie-breaks',
      () async {
        final dataSet = _createSortDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(id: 1, name: 'bravo'),
              _row(id: 2, name: 'alpha'),
              _row(id: 3, name: 'Alpha'),
              _row(id: 4, name: 'Bravo'),
            ],
          ),
        );
        await dataSet.open();

        await dataSet.sort.sortBy('NAME').ascending.apply();

        expect(_values<int>(dataSet, 'id'), <int>[3, 2, 4, 1]);

        await dataSet.sort.sortBy('name').descending.apply();

        expect(_values<int>(dataSet, 'id'), <int>[1, 4, 2, 3]);
      },
    );

    test(
      'sorts nullable values with ascending nulls last and descending nulls first',
      () async {
        final dataSet = _createSortDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(id: 1, name: 'Bravo'),
              _row(id: 2),
              _row(id: 3, name: 'Alpha'),
            ],
          ),
        );
        await dataSet.open();

        await dataSet.sort.sortBy('name').ascending.apply();

        expect(_values<int>(dataSet, 'id'), <int>[3, 1, 2]);

        await dataSet.sort.sortBy('name').descending.apply();

        expect(_values<int>(dataSet, 'id'), <int>[2, 1, 3]);
      },
    );

    test('sorts integers and decimals through multi-sort ranks', () async {
      final dataSet = _createSortDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            _row(id: 1, age: 30, amount: '10.10'),
            _row(id: 2, age: 20, amount: '99.99'),
            _row(id: 3, age: 20, amount: '15.50'),
            _row(id: 4, age: 30, amount: '12.00'),
            _row(id: 5, age: 20),
          ],
        ),
      );
      await dataSet.open();
      await dataSet.sort
          .sortBy('age')
          .ascending
          .sortBy('amount')
          .descending
          .apply();

      expect(_values<int>(dataSet, 'id'), <int>[5, 2, 3, 4, 1]);
    });

    test(
      'sorts date, dateTime, and FdcTime fields in both directions',
      () async {
        final dataSet = _createSortDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(
                id: 1,
                date: DateTime(2026, 1, 2),
                dateTime: DateTime(2026, 1, 1, 9),
                time: FdcTime.parse('10:30'),
              ),
              _row(
                id: 2,
                date: DateTime(2026),
                dateTime: DateTime(2026, 1, 1, 8),
                time: FdcTime.parse('09:15'),
              ),
              _row(
                id: 3,
                date: DateTime(2026),
                dateTime: DateTime(2026, 1, 2, 8),
                time: FdcTime.parse('17:45'),
              ),
            ],
          ),
        );
        await dataSet.open();
        await dataSet.sort
            .sortBy('date')
            .ascending
            .sortBy('dateTime')
            .descending
            .apply();

        expect(_values<int>(dataSet, 'id'), <int>[3, 2, 1]);

        await dataSet.sort.sortBy('time').descending.apply();

        expect(_values<int>(dataSet, 'id'), <int>[3, 1, 2]);
      },
    );

    test(
      'keeps raw-index fallback stable when all sort keys are equal',
      () async {
        final dataSet = _createSortDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(id: 30, name: 'same', age: 1),
              _row(id: 10, name: 'same', age: 1),
              _row(id: 20, name: 'same', age: 1),
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

        expect(_values<int>(dataSet, 'id'), <int>[30, 10, 20]);
      },
    );

    test(
      'sorts filtered views and clear filter restores full sorted order',
      () async {
        final dataSet = _createSortDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(id: 1, name: 'Delta', age: 20, status: 'open'),
              _row(id: 2, name: 'Alpha', age: 30, status: 'closed'),
              _row(id: 3, name: 'Charlie', age: 40, status: 'open'),
              _row(id: 4, name: 'Bravo', age: 10, status: 'closed'),
            ],
          ),
        );
        await dataSet.open();

        await dataSet.sort.sortBy('name').ascending.apply();
        expect(_values<int>(dataSet, 'id'), <int>[2, 4, 3, 1]);

        await dataSet.filter.where('status').equals('open').apply();
        expect(_values<int>(dataSet, 'id'), <int>[3, 1]);

        await dataSet.filter.clear();
        expect(_values<int>(dataSet, 'id'), <int>[2, 4, 3, 1]);
      },
    );

    test(
      'editing a non-sort field preserves sorted order across clear filter',
      () async {
        final dataSet = _createSortDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(id: 1, name: 'Bravo', amount: '10.00', status: 'open'),
              _row(id: 2, name: 'Charlie', amount: '20.00', status: 'closed'),
              _row(id: 3, name: 'Alpha', amount: '30.00', status: 'open'),
            ],
          ),
        );
        await dataSet.open();

        await dataSet.sort.sortBy('name').ascending.apply();
        await dataSet.filter.where('status').equals('open').apply();

        dataSet.last();
        expect(dataSet.fieldValue('id'), 1);
        dataSet.edit();
        dataSet.fieldByName('amount').value = '99.99';
        dataSet.post();

        await dataSet.filter.clear();

        expect(_values<int>(dataSet, 'id'), <int>[3, 1, 2]);
        expect(
          FdcDataSetInternal.fieldValueAt(dataSet, 1, 'amount'),
          FdcDecimal.parse('99.99'),
        );
      },
    );

    test(
      'editing an active sort field invalidates cached full sorted view',
      () async {
        final dataSet = _createSortDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(id: 1, name: 'Bravo', status: 'open'),
              _row(id: 2, name: 'Charlie', status: 'closed'),
              _row(id: 3, name: 'Alpha', status: 'open'),
            ],
          ),
        );
        await dataSet.open();

        await dataSet.sort.sortBy('name').ascending.apply();
        expect(_values<int>(dataSet, 'id'), <int>[3, 1, 2]);

        await dataSet.filter.where('status').equals('open').apply();
        dataSet.last();
        expect(dataSet.fieldValue('id'), 1);
        dataSet.edit();
        dataSet.fieldByName('name').value = 'Zulu';
        dataSet.post();

        await dataSet.filter.clear();

        expect(_values<int>(dataSet, 'id'), <int>[3, 2, 1]);
      },
    );

    test(
      'sort rank cache remains correct after deleting and inserting records',
      () async {
        final dataSet = _createSortDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(id: 1, name: 'Charlie'),
              _row(id: 2, name: 'Alpha'),
              _row(id: 3, name: 'Bravo'),
            ],
          ),
        );
        await dataSet.open();

        await dataSet.sort.sortBy('name').ascending.apply();
        expect(_values<int>(dataSet, 'id'), <int>[2, 3, 1]);

        dataSet.first();
        dataSet.delete();
        dataSet.append();
        dataSet.fieldByName('id').value = 4;
        dataSet.fieldByName('name').value = 'Aaron';
        dataSet.post();
        await dataSet.sort.sortBy('name').ascending.apply();

        expect(_values<int>(dataSet, 'id'), <int>[4, 3, 1]);
      },
    );
  });
}

FdcDataSet _createSortDataSet({IFdcDataAdapter? adapter}) {
  return FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(name: 'name', size: 50),
      FdcIntegerField(name: 'age'),
      FdcDecimalField(name: 'amount', precision: 18, scale: 2),
      FdcDateField(name: 'date'),
      FdcDateTimeField(name: 'dateTime'),
      FdcTimeField(name: 'time'),
      FdcStringField(name: 'status', size: 20),
    ],

    adapter:
        adapter ?? FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );
}

Map<String, Object?> _row({
  required int id,
  String? name,
  int? age,
  Object? amount,
  DateTime? date,
  DateTime? dateTime,
  FdcTime? time,
  String? status,
}) {
  return <String, Object?>{
    'id': id,
    'name': name,
    'age': age,
    'amount': amount,
    'date': date,
    'dateTime': dateTime,
    'time': time,
    'status': status,
  };
}

List<T?> _values<T>(FdcDataSet dataSet, String fieldName) {
  return <T?>[
    for (var index = 0; index < dataSet.recordCount; index++)
      FdcDataSetInternal.fieldValueAt(dataSet, index, fieldName) as T?,
  ];
}
