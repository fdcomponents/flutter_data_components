import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  await _testCancelEditEvents();
  await _testCancelInsertEvents();
  await _testBeforeCancelAbortKeepsEditState();
  await _testBeforeCancelAbortKeepsInsertState();
}

Future<void> _testCancelEditEvents() async {
  final eventLog = <String>[];
  Object? beforeCancelRecordId;
  Object? afterCancelRecordId;

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforeCancel: (dataSet) {
      eventLog.add('beforeCancel');
      beforeCancelRecordId = dataSet.fieldValue('id');
      assert(dataSet.state == FdcDataSetState.edit);
      assert(dataSet.fieldValue('name') == 'Beta');
    },
    afterCancel: (dataSet) {
      eventLog.add('afterCancel');
      afterCancelRecordId = dataSet.fieldValue('id');
      assert(dataSet.state == FdcDataSetState.browse);
      assert(dataSet.fieldValue('name') == 'Alpha');
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.edit();
  dataSet.setFieldValue('name', 'Beta');
  dataSet.cancel();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.fieldValue('name') == 'Alpha');
  assert(eventLog.length == 2);
  assert(eventLog[0] == 'beforeCancel');
  assert(eventLog[1] == 'afterCancel');
  assert(beforeCancelRecordId == afterCancelRecordId);
  assert(dataSet.errors.messages.isEmpty);
}

Future<void> _testCancelInsertEvents() async {
  final eventLog = <String>[];
  Object? canceledRowName;

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforeCancel: (dataSet) {
      eventLog.add('beforeCancel');
      canceledRowName = dataSet.fieldValue('name');
      assert(dataSet.state == FdcDataSetState.insert);
      assert(dataSet.fieldValue('name') == 'Inserted');
    },
    afterCancel: (dataSet) {
      eventLog.add('afterCancel');
      assert(dataSet.state == FdcDataSetState.browse);
      assert(dataSet.recordCount == 1);
      assert(dataSet.fieldValue('name') != canceledRowName);
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();
  dataSet.setFieldValue('name', 'Inserted');
  dataSet.cancel();

  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.recordCount == 1);
  assert(dataSet.fieldValue('name') == 'Alpha');
  assert(eventLog.length == 2);
  assert(eventLog[0] == 'beforeCancel');
  assert(eventLog[1] == 'afterCancel');
  assert(dataSet.errors.messages.isEmpty);
}

Future<void> _testBeforeCancelAbortKeepsEditState() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforeCancel: (dataSet) {
      throw FdcDataSetAbortException('Cancel edit is not allowed.');
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.edit();
  dataSet.setFieldValue('name', 'Beta');

  dataSet.cancel();
  assert(dataSet.state == FdcDataSetState.edit);
  assert(dataSet.fieldValue('name') == 'Beta');
  assert(dataSet.recordCount == 1);
  assert(dataSet.errors.messages.isNotEmpty);
  assert(dataSet.errors.messages[0] == 'Cancel edit is not allowed.');
  assert(dataSet.errors.messages[0] == 'Cancel edit is not allowed.');
}

Future<void> _testBeforeCancelAbortKeepsInsertState() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforeCancel: (dataSet) {
      throw FdcDataSetAbortException('Cancel insert is not allowed.');
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();
  dataSet.setFieldValue('name', 'Inserted');

  final insertedName = dataSet.fieldValue('name');
  dataSet.cancel();
  assert(dataSet.state == FdcDataSetState.insert);
  assert(dataSet.fieldValue('name') == insertedName);
  assert(dataSet.fieldValue('name') == 'Inserted');
  assert(dataSet.recordCount == 2);
  assert(dataSet.errors.messages.isNotEmpty);
  assert(dataSet.errors.messages[0] == 'Cancel insert is not allowed.');
  assert(dataSet.errors.messages[0] == 'Cancel insert is not allowed.');
}
