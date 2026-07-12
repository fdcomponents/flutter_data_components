import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fdc dataset row context validator', () async {
    final dataSet = FdcDataSet(
      fields: <FdcFieldDef>[
        FdcStringField(
          size: 255,
          name: 'name',
          validator: (record, value) {
            if (record.value('status') == 'blocked') {
              return 'Blocked record.';
            }
            return null;
          },
        ),
        const FdcStringField(size: 255, name: 'status'),
      ],
      recordValidator: (record) {
        if (record.value('name') == 'Bad') {
          return <FdcValidationError>[
            const FdcValidationError(fieldName: 'name', message: 'Bad name.'),
          ];
        }
        return const <FdcValidationError>[];
      },

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alpha', 'status': 'ok'},
        ],
      ),
    );

    await dataSet.open();

    dataSet.edit();
    dataSet.setFieldValue('status', 'blocked');

    final fieldErrors = dataSet.validateFieldValue('name', 'Alpha');
    expect(fieldErrors.single.message, 'Blocked record.');

    dataSet.setFieldValue('status', 'ok');
    dataSet.setFieldValue('name', 'Bad');

    var recordValidatorRaised = false;
    try {
      dataSet.post();
    } on FdcDataSetValidationException catch (error) {
      recordValidatorRaised = true;
      expect(error.errors.single.message, 'Bad name.');
    }
    expect(recordValidatorRaised, isTrue);
  });
}
