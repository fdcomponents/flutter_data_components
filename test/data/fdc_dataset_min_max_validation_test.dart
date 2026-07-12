import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FdcDataSet dataSet;

  setUp(() async {
    dataSet = FdcDataSet(
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
  });

  test(
    'post rejects a value below the field minimum and preserves the edit value',
    () {
      dataSet.setFieldValue('quantity', 0);

      expect(
        dataSet.post,
        throwsA(
          isA<FdcDataSetValidationException>()
              .having(
                (error) => error.errors.single.fieldName,
                'fieldName',
                'quantity',
              )
              .having(
                (error) => error.errors.single.code,
                'code',
                FdcValidationCodes.minValue,
              )
              .having(
                (error) => error.errors.single.message,
                'message',
                'Field Quantity must be greater than or equal to 1.',
              ),
        ),
      );

      expect(
        dataSet.errors.message,
        'Field Quantity must be greater than or equal to 1.',
      );
      expect(dataSet.fieldValue('quantity'), 0);
    },
  );

  test(
    'post rejects a value above the field maximum and preserves the edit value',
    () {
      dataSet.setFieldValue('quantity', 11);

      expect(
        dataSet.post,
        throwsA(
          isA<FdcDataSetValidationException>()
              .having(
                (error) => error.errors.single.fieldName,
                'fieldName',
                'quantity',
              )
              .having(
                (error) => error.errors.single.code,
                'code',
                FdcValidationCodes.maxValue,
              )
              .having(
                (error) => error.errors.single.message,
                'message',
                'Field Quantity must be less than or equal to 10.',
              ),
        ),
      );

      expect(
        dataSet.errors.message,
        'Field Quantity must be less than or equal to 10.',
      );
      expect(dataSet.fieldValue('quantity'), 11);
    },
  );
}
