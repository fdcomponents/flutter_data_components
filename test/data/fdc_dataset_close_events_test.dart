import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('close fires callbacks around successful dataset cleanup', () async {
    await _testCloseEvents();
  });
  test('silent beforeClose abort keeps data open without errors', () async {
    await _testSilentBeforeCloseAbortDoesNotCloseOrSetErrors();
  });
  test(
    'visible beforeClose abort keeps data open and reports the error',
    () async {
      await _testVisibleBeforeCloseAbortSetsErrors();
    },
  );
  test('beforeClose abort preserves edit state and buffer', () async {
    await _testBeforeCloseAbortInEditKeepsEditStateAndBuffer();
  });
  test('afterClose observes the fully closed internal state', () async {
    await _testAfterCloseRunsAfterSuccessfulClose();
  });
}

Future<void> _testCloseEvents() async {
  final eventLog = <String>[];

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforeClose: (dataSet) {
      eventLog.add('beforeClose');
      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
      expect(dataSet.fieldValue('name'), 'Alpha');
    },
    afterClose: (dataSet) {
      eventLog.add('afterClose');
      expect(dataSet.state, FdcDataSetState.closed);
      expect(dataSet.recordCount, 0);
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
        <String, Object?>{'id': 2, 'name': 'Beta'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.close();

  expect(dataSet.state, FdcDataSetState.closed);
  expect(dataSet.recordCount, 0);
  expect(eventLog, <String>['beforeClose', 'afterClose']);
  expect(dataSet.errors.message, isEmpty);
}

Future<void> _testSilentBeforeCloseAbortDoesNotCloseOrSetErrors() async {
  var afterCloseCalled = false;

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    beforeClose: (dataSet) {
      throw const FdcDataSetAbortException.silent();
    },
    afterClose: (dataSet) {
      afterCloseCalled = true;
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1},
      ],
    ),
  );

  await dataSet.open();

  dataSet.close();

  expect(afterCloseCalled, isFalse);
  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.recordCount, 1);
  expect(dataSet.errors.message, isEmpty);
}

Future<void> _testVisibleBeforeCloseAbortSetsErrors() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    beforeClose: (dataSet) {
      throw FdcDataSetAbortException('Close is not allowed.');
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1},
      ],
    ),
  );

  await dataSet.open();

  dataSet.close();

  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.recordCount, 1);
  expect(dataSet.errors.message, 'Close is not allowed.');
}

Future<void> _testBeforeCloseAbortInEditKeepsEditStateAndBuffer() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforeClose: (dataSet) {
      throw const FdcDataSetAbortException.silent();
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();
  dataSet.edit();
  dataSet.setFieldValue('name', 'Changed');

  dataSet.close();

  expect(dataSet.state, FdcDataSetState.edit);
  expect(dataSet.recordCount, 1);
  expect(dataSet.fieldValue('name'), 'Changed');
  expect(dataSet.errors.message, isEmpty);
}

Future<void> _testAfterCloseRunsAfterSuccessfulClose() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    afterClose: (dataSet) {
      expect(dataSet.state, FdcDataSetState.closed);
      expect(dataSet.recordCount, 0);
      expect(FdcDataSetInternal.activeIndex(dataSet), -1);
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1},
      ],
    ),
  );

  await dataSet.open();

  dataSet.close();

  expect(dataSet.state, FdcDataSetState.closed);
  expect(dataSet.recordCount, 0);
  expect(FdcDataSetInternal.activeIndex(dataSet), -1);
  expect(dataSet.errors.message, isEmpty);
}
