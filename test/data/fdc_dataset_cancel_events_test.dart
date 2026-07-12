import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'cancel edit restores the original record and fires callbacks',
    () async {
      await _testCancelEditEvents();
    },
  );
  test('cancel insert removes the new record and fires callbacks', () async {
    await _testCancelInsertEvents();
  });
  test('beforeCancel abort keeps the dataset in edit state', () async {
    await _testBeforeCancelAbortKeepsEditState();
  });
  test('beforeCancel abort keeps the dataset in insert state', () async {
    await _testBeforeCancelAbortKeepsInsertState();
  });
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
      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet.fieldValue('name'), 'Beta');
    },
    afterCancel: (dataSet) {
      eventLog.add('afterCancel');
      afterCancelRecordId = dataSet.fieldValue('id');
      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.fieldValue('name'), 'Alpha');
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

  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.fieldValue('name'), 'Alpha');
  expect(eventLog, <String>['beforeCancel', 'afterCancel']);
  expect(afterCancelRecordId, beforeCancelRecordId);
  expect(dataSet.errors.message, isEmpty);
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
      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet.fieldValue('name'), 'Inserted');
    },
    afterCancel: (dataSet) {
      eventLog.add('afterCancel');
      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), isNot(canceledRowName));
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

  expect(dataSet.state, FdcDataSetState.browse);
  expect(dataSet.recordCount, 1);
  expect(dataSet.fieldValue('name'), 'Alpha');
  expect(eventLog, <String>['beforeCancel', 'afterCancel']);
  expect(dataSet.errors.message, isEmpty);
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
  expect(dataSet.state, FdcDataSetState.edit);
  expect(dataSet.fieldValue('name'), 'Beta');
  expect(dataSet.recordCount, 1);
  expect(dataSet.errors.message, 'Cancel edit is not allowed.');
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

  dataSet.cancel();
  expect(dataSet.state, FdcDataSetState.insert);
  expect(dataSet.fieldValue('name'), 'Inserted');
  expect(dataSet.recordCount, 2);
  expect(dataSet.errors.message, 'Cancel insert is not allowed.');
}
