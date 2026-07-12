import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'post rejects an empty required field and publishes its field error',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(
            size: 255,
            name: 'name',
            label: 'Name',
            required: true,
          ),
          FdcStringField(size: 255, name: 'note'),
        ],
        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      );

      await dataSet.open();
      dataSet.append();
      dataSet.setFieldValue('note', 'Only optional field is filled');

      expect(
        dataSet.post,
        throwsA(
          isA<FdcDataSetValidationException>()
              .having((error) => error.errors, 'errors', hasLength(1))
              .having(
                (error) => error.errors.single.fieldName,
                'fieldName',
                'name',
              )
              .having(
                (error) => error.errors.single.code,
                'code',
                FdcValidationCodes.requiredField,
              )
              .having(
                (error) => error.errors.single.message,
                'message',
                'Field Name is required.',
              ),
        ),
      );

      expect(dataSet.errors.message, 'Field Name is required.');
    },
  );
}
