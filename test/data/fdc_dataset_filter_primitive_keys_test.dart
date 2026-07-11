import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcDataSet primitive filter keys', () {
    test(
      'dateTime date-only equals filters by day using primitive keys',
      () async {
        final dataSet = _createTemporalDataSet();
        await dataSet.open();

        await dataSet.filter.set(const <FdcDataSetFilter>[
          FdcDataSetFilter(
            fieldName: 'createdAt',
            operator: FdcFilterOperator.equals,
            value: '2026-01-02',
          ),
        ]);

        expect(_ids(dataSet), <int>[2, 3]);
      },
    );

    test('dateTime range comparisons keep full time precision', () async {
      final dataSet = _createTemporalDataSet();
      await dataSet.open();

      await dataSet.filter.set(<FdcDataSetFilter>[
        FdcDataSetFilter(
          fieldName: 'createdAt',
          operator: FdcFilterOperator.greaterThanOrEqual,
          value: DateTime(2026, 1, 2, 12),
        ),
      ]);

      expect(_ids(dataSet), <int>[3, 4]);
    });

    test(
      'date and time inList filters use the same primitive path as sort',
      () async {
        final dataSet = _createTemporalDataSet();
        await dataSet.open();

        await dataSet.filter.set(const <FdcDataSetFilter>[
          FdcDataSetFilter(
            fieldName: 'workDate',
            operator: FdcFilterOperator.inList,
            value: <String>['2026-01-01', '2026-01-03'],
          ),
          FdcDataSetFilter(
            fieldName: 'workTime',
            operator: FdcFilterOperator.inList,
            value: <String>['09:00', '17:30'],
          ),
        ]);

        expect(_ids(dataSet), <int>[1, 4]);
      },
    );

    test(
      'integer and boolean inList filters use prepared primitive sets',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcIntegerField(name: 'age'),
            FdcBooleanField(name: 'active'),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'age': 20, 'active': true},
              <String, Object?>{'id': 2, 'age': 30, 'active': false},
              <String, Object?>{'id': 3, 'age': 40, 'active': true},
              <String, Object?>{'id': 4, 'age': 50, 'active': false},
            ],
          ),
        );
        await dataSet.open();

        await dataSet.filter.set(const <FdcDataSetFilter>[
          FdcDataSetFilter(
            fieldName: 'age',
            operator: FdcFilterOperator.inList,
            value: <int>[20, 40, 50],
          ),
          FdcDataSetFilter(
            fieldName: 'active',
            operator: FdcFilterOperator.inList,
            value: <bool>[true],
          ),
        ]);

        expect(_ids(dataSet), <int>[1, 3]);
      },
    );

    test(
      'case-insensitive text contains keeps normalized cache semantics',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcStringField(name: 'name', size: 40),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'name': 'Alpha Customer'},
              <String, Object?>{'id': 2, 'name': 'beta account'},
              <String, Object?>{'id': 3, 'name': 'ALPINE vendor'},
            ],
          ),
        );
        await dataSet.open();

        await dataSet.filter.set(const <FdcDataSetFilter>[
          FdcDataSetFilter(
            fieldName: 'name',
            operator: FdcFilterOperator.contains,
            value: 'alp',
          ),
        ]);

        expect(_ids(dataSet), <int>[1, 3]);
      },
    );

    test(
      'time between filters by ticks without constructing FdcTime per row',
      () async {
        final dataSet = _createTemporalDataSet();
        await dataSet.open();

        await dataSet.filter.set(const <FdcDataSetFilter>[
          FdcDataSetFilter(
            fieldName: 'workTime',
            operator: FdcFilterOperator.between,
            value: '10:00',
            secondValue: '17:30',
          ),
        ]);

        expect(_ids(dataSet), <int>[2, 3, 4]);
      },
    );
  });
}

FdcDataSet _createTemporalDataSet() {
  return FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcDateField(name: 'workDate'),
      FdcDateTimeField(name: 'createdAt'),
      FdcTimeField(name: 'workTime'),
    ],
    adapter: FdcMemoryDataAdapter(rows: _temporalRows()),
  );
}

List<Map<String, Object?>> _temporalRows() {
  return <Map<String, Object?>>[
    <String, Object?>{
      'id': 1,
      'workDate': DateTime(2026),
      'createdAt': DateTime(2026, 1, 1, 8),
      'workTime': FdcTime.parse('09:00'),
    },
    <String, Object?>{
      'id': 2,
      'workDate': DateTime(2026, 1, 2),
      'createdAt': DateTime(2026, 1, 2, 8),
      'workTime': FdcTime.parse('10:15'),
    },
    <String, Object?>{
      'id': 3,
      'workDate': DateTime(2026, 1, 2),
      'createdAt': DateTime(2026, 1, 2, 13),
      'workTime': FdcTime.parse('16:45'),
    },
    <String, Object?>{
      'id': 4,
      'workDate': DateTime(2026, 1, 3),
      'createdAt': DateTime(2026, 1, 3, 9),
      'workTime': FdcTime.parse('17:30'),
    },
  ];
}

List<int> _ids(FdcDataSet dataSet) {
  return dataSet.toMaps().map((row) => row['id']! as int).toList();
}
