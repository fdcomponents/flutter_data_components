import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deleting an unposted append clears immediate validation errors',
    () async {
      var validationEventCount = 0;
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name', required: true),
        ],
        onValidationError: (_, _) => validationEventCount++,
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      );

      await dataSet.open();
      dataSet.append();
      dataSet.setFieldValue('id', 2);

      final errors = FdcDataSetInternal.validateFieldValueAndEmit(
        dataSet,
        'name',
        '',
      );

      expect(errors, isNotEmpty);
      expect(dataSet.errors.message, isNotEmpty);
      expect(validationEventCount, 1);

      dataSet.delete();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 1);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Alpha');
      expect(dataSet.errors.message, isEmpty);
    },
  );

  test(
    'canceling an unposted insert clears immediate validation errors',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name', required: true),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
            {'id': 3, 'name': 'Gamma'},
          ],
        ),
      );

      await dataSet.open();
      dataSet.moveToRecord(2);
      dataSet.insert();
      dataSet.setFieldValue('id', 2);

      final errors = FdcDataSetInternal.validateFieldValueAndEmit(
        dataSet,
        'name',
        '',
      );

      expect(errors, isNotEmpty);
      expect(dataSet.errors.message, isNotEmpty);

      dataSet.cancel();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
      expect(
        <Object?>[
          FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id'),
          FdcDataSetInternal.fieldValueAt(dataSet, 1, 'id'),
        ],
        <Object?>[1, 3],
      );
      expect(dataSet.errors.message, isEmpty);
    },
  );
}
