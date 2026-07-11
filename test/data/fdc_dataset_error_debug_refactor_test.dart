import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'error controller preserves validation and error event behavior',
    () async {
      final validationLog = <List<FdcValidationError>>[];
      final errorLog = <List<FdcDataSetError>>[];

      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(
            size: 255,
            name: 'name',
            label: 'Name',
            required: true,
          ),
        ],
        onValidationError: (_, errors) => validationLog.add(errors),
        onError: (_, errors, _) => errorLog.add(errors),

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      );
      await dataSet.open();

      dataSet.append();

      expect(
        () => dataSet.post(),
        throwsA(isA<FdcDataSetValidationException>()),
      );
      expect(validationLog, hasLength(1));
      expect(errorLog, hasLength(1));
      expect(dataSet.errors.messages.isNotEmpty, isTrue);
      expect(dataSet.errors.messageForField('name'), 'Field Name is required.');

      expect(
        FdcDataSetInternal.validateFieldValueAndEmit(dataSet, 'name', 'Alpha'),
        isEmpty,
      );
      expect(dataSet.errors.messages.isNotEmpty, isFalse);
    },
  );
}
