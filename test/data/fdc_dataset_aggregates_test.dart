import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcDataSet aggregates', () {
    test('sum and avg use FdcDecimal over the current filtered view', () async {
      final dataSet = _createAggregateDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            _row(name: 'Alpha', status: 'open', amount: '10.10', quantity: 2),
            _row(name: 'Beta', status: 'closed', amount: '20.20', quantity: 3),
            _row(name: 'Gamma', status: 'open', amount: '30.30', quantity: 4),
            _row(name: 'Delta', status: 'open'),
          ],
        ),
      );
      await dataSet.open();

      await dataSet.filter.where('STATUS').equals('open').apply();

      expect(dataSet.aggregates.count(), 3);
      expect(dataSet.aggregates.sum('AMOUNT'), FdcDecimal.parse('40.40'));
      expect(
        dataSet.aggregates.avg('amount'),
        FdcDecimal.parse('20.200000000000'),
      );
      expect(dataSet.aggregates.sum('quantity'), FdcDecimal.parse('6'));
      expect(
        dataSet.aggregates.avg('QUANTITY'),
        FdcDecimal.parse('3.000000000000'),
      );
    });

    test(
      'sum returns zero and avg returns null when no non-null values exist',
      () async {
        final dataSet = _createAggregateDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(name: 'Alpha', status: 'open'),
              _row(name: 'Beta', status: 'open'),
            ],
          ),
        );
        await dataSet.open();

        expect(dataSet.aggregates.count(), 2);
        expect(dataSet.aggregates.sum('amount'), FdcDecimal.zero);
        expect(dataSet.aggregates.avg('amount'), isNull);
        expect(dataSet.aggregates.min('amount'), isNull);
        expect(dataSet.aggregates.max('amount'), isNull);
      },
    );

    test(
      'min and max use the current filtered view for numeric and string fields',
      () async {
        final dataSet = _createAggregateDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(
                name: 'Charlie',
                status: 'closed',
                amount: '5.00',
                quantity: 5,
              ),
              _row(
                name: 'Alpha',
                status: 'open',
                amount: '10.00',
                quantity: 10,
              ),
              _row(name: 'Beta', status: 'open', amount: '20.00', quantity: 20),
            ],
          ),
        );
        await dataSet.open();

        await dataSet.filter.where('status').equals('open').apply();

        expect(dataSet.aggregates.min('name'), 'Alpha');
        expect(dataSet.aggregates.max('name'), 'Beta');
        expect(dataSet.aggregates.min('amount'), FdcDecimal.parse('10.00'));
        expect(dataSet.aggregates.max('QUANTITY'), 20);
      },
    );

    test(
      'min and max support date, date-time, and FdcTime fields over the filtered view',
      () async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(name: 'Status', size: 20),
            FdcDateField(name: 'Created'),
            FdcDateTimeField(name: 'UpdatedAt'),
            FdcTimeField(name: 'StartedAt'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'status': 'closed',
                'created': DateTime(2025, 12, 31),
                'updatedAt': DateTime(2025, 12, 31, 23, 59),
                'startedAt': FdcTime(hour: 6, minute: 45),
              },
              {
                'status': 'open',
                'created': DateTime(2026, 1, 2, 16, 30),
                'updatedAt': DateTime(2026, 1, 2, 16, 30),
                'startedAt': FdcTime(hour: 9, minute: 45),
              },
              {
                'status': 'open',
                'created': DateTime(2026, 1, 1, 8, 15),
                'updatedAt': DateTime(2026, 1, 3, 10, 30),
                'startedAt': FdcTime(hour: 7, minute: 30),
              },
            ],
          ),
        );
        await dataSet.open();

        await dataSet.filter.where('status').equals('open').apply();

        expect(dataSet.aggregates.min('created'), DateTime(2026));
        expect(dataSet.aggregates.max('created'), DateTime(2026, 1, 2));
        expect(
          dataSet.aggregates.min('updatedAt'),
          DateTime(2026, 1, 2, 16, 30),
        );
        expect(
          dataSet.aggregates.max('updatedAt'),
          DateTime(2026, 1, 3, 10, 30),
        );
        expect(
          dataSet.aggregates.min('startedAt'),
          FdcTime(hour: 7, minute: 30),
        );
        expect(
          dataSet.aggregates.max('startedAt'),
          FdcTime(hour: 9, minute: 45),
        );
      },
    );

    test('aggregates validate field names and supported data types', () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'Name', size: 50),
          FdcBooleanField(name: 'Active'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'Name': 'Alpha', 'Active': true},
          ],
        ),
      );
      await dataSet.open();

      expect(
        () => dataSet.aggregates.sum('missing'),
        throwsA(
          isA<FdcDataSetException>().having(
            (error) => error.message,
            'message',
            'Unknown sum field "missing" in dataset FdcDataSet.',
          ),
        ),
      );

      expect(
        () => dataSet.aggregates.sum('name'),
        throwsA(
          isA<FdcDataSetException>().having(
            (error) => error.message,
            'message',
            'Cannot calculate sum for non-numeric field "Name".',
          ),
        ),
      );

      expect(
        () => dataSet.aggregates.avg('active'),
        throwsA(
          isA<FdcDataSetException>().having(
            (error) => error.message,
            'message',
            'Cannot calculate avg for non-numeric field "Active".',
          ),
        ),
      );

      expect(
        () => dataSet.aggregates.min('active'),
        throwsA(
          isA<FdcDataSetException>().having(
            (error) => error.message,
            'message',
            'Cannot calculate min for field "Active" of type boolean.',
          ),
        ),
      );
    });

    test(
      'aggregates include active edit buffer values before and after post',
      () async {
        final dataSet = _createAggregateDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(name: 'Alpha', status: 'open', amount: '10.00', quantity: 1),
              _row(name: 'Beta', status: 'open', amount: '20.00', quantity: 2),
            ],
          ),
        );
        await dataSet.open();

        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('30.00'));
        expect(
          dataSet.aggregates.avg('amount'),
          FdcDecimal.parse('15.000000000000'),
        );

        dataSet.edit();
        dataSet.setFieldValue('amount', FdcDecimal.parse('100.00'));

        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('120.00'));
        expect(
          dataSet.aggregates.avg('amount'),
          FdcDecimal.parse('60.000000000000'),
        );
        expect(dataSet.aggregates.max('amount'), FdcDecimal.parse('100.00'));

        dataSet.post();

        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('120.00'));
        expect(
          dataSet.aggregates.avg('amount'),
          FdcDecimal.parse('60.000000000000'),
        );
        expect(dataSet.aggregates.max('amount'), FdcDecimal.parse('100.00'));
      },
    );

    test(
      'aggregates include active insert buffer before and after post',
      () async {
        final dataSet = _createAggregateDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(name: 'Alpha', status: 'open', amount: '10.00', quantity: 1),
              _row(name: 'Beta', status: 'open', amount: '20.00', quantity: 2),
            ],
          ),
        );
        await dataSet.open();

        dataSet.append();
        dataSet.setFieldValue('name', 'Gamma');
        dataSet.setFieldValue('status', 'open');
        dataSet.setFieldValue('amount', FdcDecimal.parse('50.00'));
        dataSet.setFieldValue('quantity', 5);

        expect(dataSet.aggregates.count(), 3);
        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('80.00'));
        expect(
          dataSet.aggregates.avg('amount'),
          FdcDecimal.parse('26.666666666667'),
        );
        expect(dataSet.aggregates.max('quantity'), 5);

        dataSet.post();

        expect(dataSet.aggregates.count(), 3);
        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('80.00'));
        expect(
          dataSet.aggregates.avg('amount'),
          FdcDecimal.parse('26.666666666667'),
        );
        expect(dataSet.aggregates.max('quantity'), 5);
      },
    );

    test(
      'cancelled edit restores aggregate values after active buffer was visible',
      () async {
        final dataSet = _createAggregateDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(name: 'Alpha', status: 'open', amount: '10.00', quantity: 1),
              _row(name: 'Beta', status: 'open', amount: '20.00', quantity: 2),
            ],
          ),
        );
        await dataSet.open();

        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('30.00'));

        dataSet.edit();
        dataSet.setFieldValue('amount', FdcDecimal.parse('100.00'));
        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('120.00'));

        dataSet.cancel();

        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('30.00'));
        expect(
          dataSet.aggregates.avg('amount'),
          FdcDecimal.parse('15.000000000000'),
        );
      },
    );

    test(
      'cancelled insert removes active insert buffer from aggregates',
      () async {
        final dataSet = _createAggregateDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(name: 'Alpha', status: 'open', amount: '10.00', quantity: 1),
            ],
          ),
        );
        await dataSet.open();

        dataSet.append();
        dataSet.setFieldValue('name', 'Beta');
        dataSet.setFieldValue('status', 'open');
        dataSet.setFieldValue('amount', FdcDecimal.parse('90.00'));
        dataSet.setFieldValue('quantity', 9);

        expect(dataSet.aggregates.count(), 2);
        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('100.00'));

        dataSet.cancel();

        expect(dataSet.aggregates.count(), 1);
        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('10.00'));
        expect(dataSet.aggregates.max('quantity'), 1);
      },
    );

    test('null transitions update sum and avg correctly', () async {
      final dataSet = _createAggregateDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            _row(name: 'Alpha', status: 'open', amount: '10.00'),
            _row(name: 'Beta', status: 'open'),
            _row(name: 'Gamma', status: 'open', amount: '30.00'),
          ],
        ),
      );
      await dataSet.open();

      expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('40.00'));
      expect(
        dataSet.aggregates.avg('amount'),
        FdcDecimal.parse('20.000000000000'),
      );

      dataSet.next();
      dataSet.edit();
      dataSet.setFieldValue('amount', FdcDecimal.parse('20.00'));

      expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('60.00'));
      expect(
        dataSet.aggregates.avg('amount'),
        FdcDecimal.parse('20.000000000000'),
      );

      dataSet.post();
      dataSet.next();
      dataSet.edit();
      dataSet.setFieldValue('amount', null);

      expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('30.00'));
      expect(
        dataSet.aggregates.avg('amount'),
        FdcDecimal.parse('15.000000000000'),
      );

      dataSet.post();

      expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('30.00'));
      expect(
        dataSet.aggregates.avg('amount'),
        FdcDecimal.parse('15.000000000000'),
      );
    });

    test(
      'min and max recover when edited value was the cached extreme',
      () async {
        final dataSet = _createAggregateDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(name: 'Alpha', status: 'open', amount: '10.00', quantity: 1),
              _row(name: 'Beta', status: 'open', amount: '20.00', quantity: 2),
              _row(name: 'Gamma', status: 'open', amount: '30.00', quantity: 3),
            ],
          ),
        );
        await dataSet.open();

        expect(dataSet.aggregates.min('amount'), FdcDecimal.parse('10.00'));
        expect(dataSet.aggregates.max('amount'), FdcDecimal.parse('30.00'));

        dataSet.edit();
        dataSet.setFieldValue('amount', FdcDecimal.parse('25.00'));

        expect(dataSet.aggregates.min('amount'), FdcDecimal.parse('20.00'));
        expect(dataSet.aggregates.max('amount'), FdcDecimal.parse('30.00'));

        dataSet.post();
        dataSet.last();
        dataSet.edit();
        dataSet.setFieldValue('amount', FdcDecimal.parse('15.00'));

        expect(dataSet.aggregates.min('amount'), FdcDecimal.parse('15.00'));
        expect(dataSet.aggregates.max('amount'), FdcDecimal.parse('25.00'));

        dataSet.post();

        expect(dataSet.aggregates.min('amount'), FdcDecimal.parse('15.00'));
        expect(dataSet.aggregates.max('amount'), FdcDecimal.parse('25.00'));
      },
    );

    test(
      'delete invalidates aggregate caches and excludes deleted records',
      () async {
        final dataSet = _createAggregateDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(name: 'Alpha', status: 'open', amount: '10.00', quantity: 1),
              _row(name: 'Beta', status: 'open', amount: '20.00', quantity: 2),
              _row(name: 'Gamma', status: 'open', amount: '30.00', quantity: 3),
            ],
          ),
        );
        await dataSet.open();

        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('60.00'));
        expect(dataSet.aggregates.max('quantity'), 3);

        dataSet.last();
        dataSet.delete();

        expect(dataSet.aggregates.count(), 2);
        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('30.00'));
        expect(dataSet.aggregates.max('quantity'), 2);
      },
    );

    test(
      'filter changes invalidate view aggregate values and clear restores full-view aggregates',
      () async {
        final dataSet = _createAggregateDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              _row(name: 'Alpha', status: 'open', amount: '10.00', quantity: 1),
              _row(
                name: 'Beta',
                status: 'closed',
                amount: '20.00',
                quantity: 2,
              ),
              _row(name: 'Gamma', status: 'open', amount: '30.00', quantity: 3),
            ],
          ),
        );
        await dataSet.open();

        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('60.00'));

        await dataSet.filter.where('status').equals('open').apply();

        expect(dataSet.aggregates.count(), 2);
        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('40.00'));
        expect(
          dataSet.aggregates.avg('quantity'),
          FdcDecimal.parse('2.000000000000'),
        );

        await dataSet.filter.clear();

        expect(dataSet.aggregates.count(), 3);
        expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('60.00'));
        expect(
          dataSet.aggregates.avg('quantity'),
          FdcDecimal.parse('2.000000000000'),
        );
      },
    );

    test(
      'calculated aggregate values update on dependency field edits',
      () async {
        final dataSet = _createCalculatedAggregateDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': 'Alpha',
                'status': 'open',
                'balance': FdcDecimal.parse('10.00'),
              },
              {
                'name': 'Beta',
                'status': 'open',
                'balance': FdcDecimal.parse('20.00'),
              },
            ],
          ),
        );
        await dataSet.open();

        expect(dataSet.aggregates.sum('tax'), FdcDecimal.parse('7.5000'));
        expect(dataSet.aggregates.sum('total'), FdcDecimal.parse('37.5000'));
        expect(
          dataSet.aggregates.avg('total'),
          FdcDecimal.parse('18.750000000000'),
        );

        dataSet.edit();
        dataSet.setFieldValue('balance', FdcDecimal.parse('40.00'));

        expect(dataSet.aggregates.sum('tax'), FdcDecimal.parse('15.0000'));
        expect(dataSet.aggregates.sum('total'), FdcDecimal.parse('75.0000'));
        expect(
          dataSet.aggregates.avg('total'),
          FdcDecimal.parse('37.500000000000'),
        );

        dataSet.post();

        expect(dataSet.aggregates.sum('tax'), FdcDecimal.parse('15.0000'));
        expect(dataSet.aggregates.sum('total'), FdcDecimal.parse('75.0000'));
        expect(
          dataSet.aggregates.avg('total'),
          FdcDecimal.parse('37.500000000000'),
        );
      },
    );

    test(
      'unrelated field edits do not change calculated aggregate values',
      () async {
        final dataSet = _createCalculatedAggregateDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {
                'name': 'Alpha',
                'status': 'open',
                'balance': FdcDecimal.parse('10.00'),
              },
              {
                'name': 'Beta',
                'status': 'open',
                'balance': FdcDecimal.parse('20.00'),
              },
            ],
          ),
        );
        await dataSet.open();

        expect(dataSet.aggregates.sum('tax'), FdcDecimal.parse('7.5000'));
        expect(dataSet.aggregates.sum('total'), FdcDecimal.parse('37.5000'));

        dataSet.edit();
        dataSet.setFieldValue('name', 'Alpha renamed');

        expect(dataSet.aggregates.sum('tax'), FdcDecimal.parse('7.5000'));
        expect(dataSet.aggregates.sum('total'), FdcDecimal.parse('37.5000'));

        dataSet.post();

        expect(dataSet.aggregates.sum('tax'), FdcDecimal.parse('7.5000'));
        expect(dataSet.aggregates.sum('total'), FdcDecimal.parse('37.5000'));
      },
    );

    test('sort does not change aggregate values', () async {
      final dataSet = _createAggregateDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            _row(name: 'Gamma', status: 'open', amount: '30.00', quantity: 3),
            _row(name: 'Alpha', status: 'open', amount: '10.00', quantity: 1),
            _row(name: 'Beta', status: 'open', amount: '20.00', quantity: 2),
          ],
        ),
      );
      await dataSet.open();

      expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('60.00'));
      expect(
        dataSet.aggregates.avg('quantity'),
        FdcDecimal.parse('2.000000000000'),
      );
      expect(dataSet.aggregates.min('name'), 'Alpha');
      expect(dataSet.aggregates.max('name'), 'Gamma');

      await dataSet.sort.sortBy('name').ascending.apply();

      expect(dataSet.aggregates.sum('amount'), FdcDecimal.parse('60.00'));
      expect(
        dataSet.aggregates.avg('quantity'),
        FdcDecimal.parse('2.000000000000'),
      );
      expect(dataSet.aggregates.min('name'), 'Alpha');
      expect(dataSet.aggregates.max('name'), 'Gamma');
    });
  });
}

FdcDataSet _createAggregateDataSet({IFdcDataAdapter? adapter}) {
  return FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(name: 'Name', size: 50),
      FdcStringField(name: 'Status', size: 20),
      FdcDecimalField(name: 'Amount', precision: 18, scale: 2),
      FdcIntegerField(name: 'Quantity'),
    ],

    adapter:
        adapter ?? FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );
}

FdcDataSet _createCalculatedAggregateDataSet({IFdcDataAdapter? adapter}) {
  return FdcDataSet(
    fields: <FdcFieldDef>[
      const FdcStringField(name: 'Name', size: 50),
      const FdcStringField(name: 'Status', size: 20),
      const FdcDecimalField(name: 'Balance', precision: 18, scale: 2),
      FdcDecimalField(
        name: 'Tax',
        precision: 18,
        scale: 4,
        calculatedValue: (row) {
          final balance = row.value('balance') ?? FdcDecimal.zero;
          return balance * FdcDecimal.parse('0.25');
        },
      ),
      FdcDecimalField(
        name: 'Total',
        precision: 18,
        scale: 4,
        calculatedValue: (row) {
          final balance = row.value('balance') ?? FdcDecimal.zero;
          final tax = row.value('tax') ?? FdcDecimal.zero;
          return balance + tax;
        },
      ),
    ],

    adapter:
        adapter ?? FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );
}

Map<String, Object?> _row({
  required String name,
  required String status,
  String? amount,
  int? quantity,
}) {
  return <String, Object?>{
    'name': name,
    'status': status,
    'amount': amount == null ? null : FdcDecimal.parse(amount),
    'quantity': quantity,
  };
}
