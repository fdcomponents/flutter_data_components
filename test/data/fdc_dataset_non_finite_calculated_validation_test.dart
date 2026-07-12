import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

Object? _unsafeRatio(FdcCalculatedFieldContext context) {
  final amount = context.numValue('amount') ?? 0;
  final divisor = context.numValue('divisor') ?? 0;
  return amount / divisor;
}

void main() {
  test('post rejects a non-finite calculated decimal value', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcDecimalField(
          name: 'amount',
          precision: 12,
          scale: 2,
          label: 'Amount',
          defaultValue: 10.0,
        ),
        FdcDecimalField(
          name: 'divisor',
          precision: 12,
          scale: 2,
          label: 'Divisor',
          defaultValue: 0.0,
        ),
        FdcDecimalField(
          name: 'ratio',
          precision: 12,
          scale: 2,
          label: 'Ratio',
          calculatedValue: _unsafeRatio,
        ),
      ],
      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );

    await dataSet.open();
    dataSet.append();

    expect(
      dataSet.post,
      throwsA(
        isA<FdcDataSetValidationException>()
            .having(
              (error) => error.errors.single.fieldName,
              'fieldName',
              'ratio',
            )
            .having(
              (error) => error.errors.single.code,
              'code',
              FdcValidationCodes.nonFiniteNumber,
            )
            .having(
              (error) => error.errors.single.message,
              'message',
              'Field Ratio has invalid numeric value.',
            ),
      ),
    );

    expect(
      dataSet.errors.messageForField('ratio'),
      'Field Ratio has invalid numeric value.',
    );
    expect(dataSet.errors.messages.count, 1);
  });
}
