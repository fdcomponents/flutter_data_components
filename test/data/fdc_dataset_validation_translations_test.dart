import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'name', label: 'Naziv', required: true),
    ],
    adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    validationTranslations: const FdcValidationTranslations(
      requiredField: _requiredField,
    ),
  );

  await dataSet.open();
  dataSet.append();

  var validationThrown = false;
  try {
    dataSet.post();
  } on FdcDataSetValidationException catch (error) {
    validationThrown = true;
    assert(error.errors.single.message == 'Polje Naziv je obavezno.');
  }

  assert(validationThrown);
  assert(dataSet.errors.messages[0] == 'Polje Naziv je obavezno.');
}

String _requiredField(String fieldLabel) => 'Polje $fieldLabel je obavezno.';
