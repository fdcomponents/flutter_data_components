import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'validateFieldValue emits min and max validation errors immediately',
    () async {
      final dataSet = FdcDataSet(
        fields: const [
          FdcIntegerField(
            name: 'qty',
            label: 'Quantity',
            minValue: 1,
            maxValue: 10,
          ),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: [
            {'qty': 5},
          ],
        ),
      );
      await dataSet.open();

      dataSet.edit();

      final minErrors = FdcDataSetInternal.validateFieldValueAndEmit(
        dataSet,
        'qty',
        0,
      );
      expect(minErrors, hasLength(1));
      expect(minErrors.single.fieldName, 'qty');
      expect(minErrors.single.code, FdcValidationCodes.minValue);
      expect(
        minErrors.single.message,
        'Field Quantity must be greater than or equal to 1.',
      );
      expect(dataSet.errors.messages.isNotEmpty, isTrue);

      final maxErrors = FdcDataSetInternal.validateFieldValueAndEmit(
        dataSet,
        'qty',
        11,
      );
      expect(maxErrors, hasLength(1));
      expect(maxErrors.single.fieldName, 'qty');
      expect(maxErrors.single.code, FdcValidationCodes.maxValue);
      expect(
        maxErrors.single.message,
        'Field Quantity must be less than or equal to 10.',
      );
      expect(dataSet.errors.messages.isNotEmpty, isTrue);

      final okErrors = FdcDataSetInternal.validateFieldValueAndEmit(
        dataSet,
        'qty',
        7,
      );
      expect(okErrors, isEmpty);
      expect(dataSet.errors.messages.isNotEmpty, isFalse);
    },
  );
}
