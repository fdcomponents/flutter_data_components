import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  await _testSilentBeforeInsertAbortDoesNotSetErrors();
  await _testVisibleBeforeInsertAbortSetsErrors();
  await _testSilentBeforeEditAbortDoesNotSetErrors();
}

Future<void> _testSilentBeforeInsertAbortDoesNotSetErrors() async {
  var afterInsertCalled = false;

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    beforeInsert: (dataSet) {
      throw const FdcDataSetAbortException.silent();
    },
    afterInsert: (dataSet) {
      afterInsertCalled = true;
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();

  assert(!afterInsertCalled);
  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 1);
  assert(dataSet.errors.messages.isEmpty);
}

Future<void> _testVisibleBeforeInsertAbortSetsErrors() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    beforeInsert: (dataSet) {
      throw FdcDataSetAbortException('Insert is not allowed.');
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 1);
  assert(dataSet.errors.messages.isNotEmpty);
  assert(dataSet.errors.messages[0] == 'Insert is not allowed.');
  assert(dataSet.errors.messages[0] == 'Insert is not allowed.');
}

Future<void> _testSilentBeforeEditAbortDoesNotSetErrors() async {
  var afterEditCalled = false;

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
    beforeEdit: (dataSet) {
      throw const FdcDataSetAbortException.silent();
    },
    afterEdit: (dataSet) {
      afterEditCalled = true;
    },

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.edit();

  assert(!afterEditCalled);
  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.errors.messages.isEmpty);
}
