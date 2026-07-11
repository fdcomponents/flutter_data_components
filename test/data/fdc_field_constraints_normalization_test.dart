import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('string field size rejects values that would be truncated', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(name: 'code', size: 3)],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'code': 'ABC'},
        ],
      ),
    );
    await dataSet.open();

    dataSet.edit();

    expect(
      () => dataSet.fieldByName('code').value = 'ABCD',
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message.toString(),
          'message',
          contains('would be truncated'),
        ),
      ),
    );
    expect(dataSet.fieldByName('code').asString, 'ABC');
  });

  test('decimal field scale rounds like SQL Server scale reduction', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcDecimalField(name: 'amount', precision: 6, scale: 2),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'amount': '12.345'},
        ],
      ),
    );
    await dataSet.open();

    expect(dataSet.fieldByName('amount').asDecimal?.toString(), '12.35');

    dataSet.edit();
    dataSet.fieldByName('amount').value = -12.345;
    dataSet.post();

    expect(dataSet.fieldByName('amount').asDecimal?.toString(), '-12.35');
  });

  test('decimal field precision rejects overflow after rounding', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcDecimalField(name: 'amount', precision: 5, scale: 2),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'amount': 999.99},
        ],
      ),
    );
    await dataSet.open();

    dataSet.edit();

    expect(
      () => dataSet.fieldByName('amount').value = 1000,
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message.toString(),
          'message',
          contains('exceeds precision 5 and scale 2'),
        ),
      ),
    );
  });

  test('time field scale rounds to configured SQL Server time scale', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcTimeField(name: 'time', scale: 3)],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'time': '12:34:56.7895678'},
        ],
      ),
    );
    await dataSet.open();

    expect(
      dataSet.fieldByName('time').asTime!.toSqlString(),
      '12:34:56.7900000',
    );
    expect(
      dataSet.fieldByName('time').asTime!.toSqlString(scale: 3),
      '12:34:56.790',
    );
  });
}
