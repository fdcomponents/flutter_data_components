import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(
        name: 'quantity',
        label: 'Quantity',
        minValue: 1,
        maxValue: 10,
      ),
    ],

    adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );

  await dataSet.open();
  dataSet.append();
  dataSet.setFieldValue('quantity', 0);

  var minValidationThrown = false;
  try {
    dataSet.post();
  } on FdcDataSetValidationException catch (error) {
    minValidationThrown = true;
    assert(error.errors.length == 1);
    assert(error.errors.single.fieldName == 'quantity');
    assert(error.errors.single.code == FdcValidationCodes.minValue);
    assert(
      error.errors.single.message ==
          'Field Quantity must be greater than or equal to 1.',
    );
  }

  assert(minValidationThrown);
  assert(dataSet.errors.messages.isNotEmpty);
  assert(
    dataSet.errors.messages[0] ==
        'Field Quantity must be greater than or equal to 1.',
  );
  assert(dataSet.fieldValue('quantity') == 0);

  dataSet.setFieldValue('quantity', 11);

  var maxValidationThrown = false;
  try {
    dataSet.post();
  } on FdcDataSetValidationException catch (error) {
    maxValidationThrown = true;
    assert(error.errors.length == 1);
    assert(error.errors.single.fieldName == 'quantity');
    assert(error.errors.single.code == FdcValidationCodes.maxValue);
    assert(
      error.errors.single.message ==
          'Field Quantity must be less than or equal to 10.',
    );
  }

  assert(maxValidationThrown);
  assert(dataSet.errors.messages.isNotEmpty);
  assert(
    dataSet.errors.messages[0] ==
        'Field Quantity must be less than or equal to 10.',
  );
  assert(dataSet.fieldValue('quantity') == 11);
}
