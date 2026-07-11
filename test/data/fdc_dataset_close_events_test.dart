import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;

Future<void> main() async {
  await _testCloseEvents();
  await _testSilentBeforeCloseAbortDoesNotCloseOrSetErrors();
  await _testVisibleBeforeCloseAbortSetsErrors();
  await _testBeforeCloseAbortInEditKeepsEditStateAndBuffer();
  await _testAfterCloseRunsAfterSuccessfulClose();
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
      assert(dataSet.state == FdcDataSetState.browse);
      assert(dataSet.recordCount == 2);
      assert(dataSet.fieldValue('name') == 'Alpha');
    },
    afterClose: (dataSet) {
      eventLog.add('afterClose');
      assert(dataSet.state == FdcDataSetState.closed);
      assert(dataSet.recordCount == 0);
      assert(dataSet.recordCount == 0);
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

  assert(dataSet.state == FdcDataSetState.closed);
  assert(dataSet.recordCount == 0);
  assert(eventLog.length == 2);
  assert(eventLog[0] == 'beforeClose');
  assert(eventLog[1] == 'afterClose');
  assert(dataSet.errors.messages.isEmpty);
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

  assert(!afterCloseCalled);
  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 1);
  assert(dataSet.recordCount > 0);
  assert(dataSet.errors.messages.isEmpty);
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

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 1);
  assert(dataSet.errors.messages.isNotEmpty);
  assert(dataSet.errors.messages[0] == 'Close is not allowed.');
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

  assert(dataSet.state == FdcDataSetState.edit);
  assert(dataSet.recordCount == 1);
  assert(dataSet.fieldValue('name') == 'Changed');
  assert(dataSet.errors.messages.isEmpty);
}

Future<void> _testAfterCloseRunsAfterSuccessfulClose() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    afterClose: (dataSet) {
      assert(dataSet.state == FdcDataSetState.closed);
      assert(dataSet.recordCount == 0);
      assert(FdcDataSetInternal.activeIndex(dataSet) == -1);
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1},
      ],
    ),
  );

  await dataSet.open();

  dataSet.close();

  assert(dataSet.state == FdcDataSetState.closed);
  assert(dataSet.recordCount == 0);
  assert(FdcDataSetInternal.activeIndex(dataSet) == -1);
  assert(dataSet.errors.messages.isEmpty);
}
