import 'package:flutter_data_components/fdc.dart';

Object? _unsafeRatio(FdcCalculatedFieldContext context) {
  final amount = context.numValue('amount') ?? 0;
  final divisor = context.numValue('divisor') ?? 0;
  return amount / divisor;
}

Future<void> main() async {
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

  var validationThrown = false;
  try {
    dataSet.post();
  } on FdcDataSetValidationException catch (error) {
    validationThrown = true;
    assert(error.errors.length == 1);
    assert(error.errors.single.fieldName == 'ratio');
    assert(error.errors.single.code == FdcValidationCodes.nonFiniteNumber);
    assert(
      error.errors.single.message == 'Field Ratio has invalid numeric value.',
    );
  }

  assert(validationThrown);
  assert(dataSet.errors.messages.isNotEmpty);
  assert(
    dataSet.errors.messageForField('ratio') ==
        'Field Ratio has invalid numeric value.',
  );
  assert(
    dataSet.errors.messages[0] == 'Field Ratio has invalid numeric value.',
  );
}
