import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  await _testDeleteUnpostedAppendClearsImmediateValidationErrors();
  await _testCancelUnpostedInsertClearsImmediateValidationErrors();
}

Future<void> _testDeleteUnpostedAppendClearsImmediateValidationErrors() async {
  var validationEventCount = 0;

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name', required: true),
    ],
    onValidationError: (_, _) {
      validationEventCount++;
    },

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
  assert(errors.isNotEmpty);
  assert(dataSet.errors.messages.isNotEmpty);
  assert(validationEventCount == 1);

  dataSet.delete();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 1);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name') == 'Alpha');
  assert(dataSet.errors.messages.isEmpty);
}

Future<void> _testCancelUnpostedInsertClearsImmediateValidationErrors() async {
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
  assert(errors.isNotEmpty);
  assert(dataSet.errors.messages.isNotEmpty);

  dataSet.cancel();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 2);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id') == 1);
  assert(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'id') == 3);
  assert(dataSet.errors.messages.isEmpty);
}
