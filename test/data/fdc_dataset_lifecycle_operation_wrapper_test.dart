import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  await _testAbortLifecycleIsHandledThroughOperationWrapper();
  await _testUnexpectedLifecycleErrorIsWrappedAndStored();
  await _testValidationErrorStillRemainsValidationException();
}

Future<FdcDataSet> _newDataSet({
  FdcDataSetBeforeEdit? beforeEdit,
  FdcDataSetBeforePost? beforePost,
  FdcRecordValidator? recordValidator,
}) async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforeEdit: beforeEdit,
    beforePost: beforePost,
    recordValidator: recordValidator,

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'A'},
      ],
    ),
  );
  await dataSet.open();
  return dataSet;
}

Future<void> _testAbortLifecycleIsHandledThroughOperationWrapper() async {
  final dataSet = await _newDataSet(
    beforeEdit: (_) => throw const FdcDataSetAbortException.silent(),
  );

  dataSet.edit();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.errors.messages.isEmpty);
}

Future<void> _testUnexpectedLifecycleErrorIsWrappedAndStored() async {
  final dataSet = await _newDataSet(
    beforeEdit: (_) => throw Exception('edit failed'),
  );

  var wrapped = false;
  try {
    dataSet.edit();
  } on FdcDataSetException catch (error) {
    wrapped = true;
    assert(error.message == 'edit failed');
  }

  assert(wrapped);
  assert(dataSet.errors.messages.count == 1);
  assert(dataSet.errors.messages[0] == 'edit failed');
  assert(dataSet.state == FdcDataSetState.browse);
}

Future<void> _testValidationErrorStillRemainsValidationException() async {
  final dataSet = await _newDataSet(
    recordValidator: (record) => const <FdcValidationError>[
      FdcValidationError(fieldName: 'name', message: 'Name is invalid'),
    ],
  );

  dataSet.edit();
  dataSet.setFieldValue('name', 'B');

  var validationThrown = false;
  try {
    dataSet.post();
  } on FdcDataSetValidationException {
    validationThrown = true;
  }

  assert(validationThrown);
  assert(dataSet.state == FdcDataSetState.edit);
  assert(dataSet.errors.messages.count == 1);
  assert(dataSet.errors.messages[0] == 'Name is invalid');
}
