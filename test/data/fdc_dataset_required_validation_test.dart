import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name', label: 'Name', required: true),
      FdcStringField(size: 255, name: 'note'),
    ],

    adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );

  await dataSet.open();
  dataSet.append();
  dataSet.setFieldValue('note', 'Only optional field is filled');

  var validationThrown = false;
  try {
    dataSet.post();
  } on FdcDataSetValidationException catch (error) {
    validationThrown = true;
    assert(error.errors.length == 1);
    assert(error.errors.single.fieldName == 'name');
    assert(error.errors.single.code == FdcValidationCodes.requiredField);
    assert(error.errors.single.message == 'Field Name is required.');
  }

  assert(validationThrown);
  assert(dataSet.errors.messages.isNotEmpty);
  assert(dataSet.errors.messages.count == 1);
  assert(dataSet.errors.messages[0] == 'Field Name is required.');
  assert(dataSet.errors.messages[0] == 'Field Name is required.');
}
