import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fdc dataset validation translations', () async {
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

    expect(
      dataSet.post,
      throwsA(
        isA<FdcDataSetValidationException>().having(
          (error) => error.errors.single.message,
          'validation message',
          'Polje Naziv je obavezno.',
        ),
      ),
    );
    expect(dataSet.errors.messages[0], 'Polje Naziv je obavezno.');
  });
}

String _requiredField(String fieldLabel) => 'Polje $fieldLabel je obavezno.';
