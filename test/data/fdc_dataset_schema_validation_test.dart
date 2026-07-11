import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dataset validates string field size in runtime schema validation', () {
    expect(
      () => FdcDataSet(
        fields: <FdcFieldDef>[const FdcStringField(name: 'name', size: 0)],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      ),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'size')
            .having(
              (error) => error.message,
              'message',
              'FdcStringField "name" size must be greater than zero.',
            ),
      ),
    );
  });

  test('dataset validates decimal precision and scale at runtime', () {
    expect(
      () => FdcDataSet(
        fields: <FdcFieldDef>[
          const FdcDecimalField(name: 'amount', precision: 0, scale: 0),
        ],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      ),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'precision')
            .having(
              (error) => error.message,
              'message',
              'FdcDecimalField "amount" precision must be in range 1..38.',
            ),
      ),
    );

    expect(
      () => FdcDataSet(
        fields: <FdcFieldDef>[
          const FdcDecimalField(name: 'amount', precision: 12, scale: 39),
        ],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      ),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'scale')
            .having(
              (error) => error.message,
              'message',
              'FdcDecimalField "amount" scale must be in range 0..38.',
            ),
      ),
    );

    expect(
      () => FdcDataSet(
        fields: <FdcFieldDef>[
          const FdcDecimalField(name: 'amount', precision: 4, scale: 5),
        ],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      ),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'scale')
            .having(
              (error) => error.message,
              'message',
              'FdcDecimalField "amount" scale must be less than or equal to precision.',
            ),
      ),
    );
  });

  test('dataset validates time scale in runtime schema validation', () {
    expect(
      () => FdcDataSet(
        fields: <FdcFieldDef>[const FdcTimeField(name: 'startsAt', scale: 8)],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      ),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'scale')
            .having(
              (error) => error.message,
              'message',
              'FdcTimeField "startsAt" scale must be in range 0..7.',
            ),
      ),
    );
  });

  test('valid field schema still accepts const field definitions', () {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'name', size: 50),
        FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        FdcTimeField(name: 'startsAt'),
      ],
      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );

    expect(dataSet.fieldCount, 3);
  });
  test('dataset validates field names at runtime', () {
    expect(
      () => FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: '', size: 50)],
        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      ),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'name')
            .having(
              (error) => error.message,
              'message',
              'FdcFieldDef.name is required and must not be empty.',
            ),
      ),
    );

    expect(
      () => FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: ' name', size: 50)],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      ),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'name')
            .having(
              (error) => error.message,
              'message',
              'FdcFieldDef.name must not have leading or trailing whitespace.',
            ),
      ),
    );
  });

  test('dataset validates numeric min and max schema constraints', () {
    expect(
      () => FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'qty', minValue: 10, maxValue: 1),
        ],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      ),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'maxValue')
            .having(
              (error) => error.message,
              'message',
              'FdcIntegerField "qty" maxValue must be greater than or equal to minValue.',
            ),
      ),
    );

    expect(
      () => FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(
            name: 'amount',
            precision: 12,
            scale: 2,
            minValue: 10,
            maxValue: 1,
          ),
        ],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      ),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'maxValue')
            .having(
              (error) => error.message,
              'message',
              'FdcDecimalField "amount" maxValue must be greater than or equal to minValue.',
            ),
      ),
    );

    expect(
      () => FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(
            name: 'amount',
            precision: 12,
            scale: 2,
            minValue: double.nan,
          ),
        ],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      ),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'minValue')
            .having(
              (error) => error.message,
              'message',
              'FdcDecimalField "amount" minValue must be finite.',
            ),
      ),
    );
  });
}
