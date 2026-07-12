import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'abort lifecycle is handled through operation wrapper',
    _testAbortLifecycleIsHandledThroughOperationWrapper,
  );
  test(
    'unexpected lifecycle error is wrapped and stored',
    _testUnexpectedLifecycleErrorIsWrappedAndStored,
  );
  test(
    'validation error still remains validation exception',
    _testValidationErrorStillRemainsValidationException,
  );
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

  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.errors.messages.isEmpty, isTrue);
}

Future<void> _testUnexpectedLifecycleErrorIsWrappedAndStored() async {
  final dataSet = await _newDataSet(
    beforeEdit: (_) => throw Exception('edit failed'),
  );

  expect(
    dataSet.edit,
    throwsA(
      isA<FdcDataSetException>().having(
        (error) => error.message,
        'message',
        'edit failed',
      ),
    ),
  );
  expect(dataSet.errors.messages.count, 1);
  expect(dataSet.errors.messages[0], 'edit failed');
  expect(dataSet.state, FdcDataSetState.browse);
}

Future<void> _testValidationErrorStillRemainsValidationException() async {
  final dataSet = await _newDataSet(
    recordValidator: (record) => const <FdcValidationError>[
      FdcValidationError(fieldName: 'name', message: 'Name is invalid'),
    ],
  );

  dataSet.edit();
  dataSet.setFieldValue('name', 'B');

  expect(dataSet.post, throwsA(isA<FdcDataSetValidationException>()));
  expect(dataSet.state, FdcDataSetState.edit);
  expect(dataSet.errors.messages.count, 1);
  expect(dataSet.errors.messages[0], 'Name is invalid');
}
