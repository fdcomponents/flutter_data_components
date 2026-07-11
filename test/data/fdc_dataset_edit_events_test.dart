import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  final eventLog = <String>[];
  Object? beforeEditRecordId;
  Object? afterEditRecordId;

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforeEdit: (dataSet) {
      eventLog.add('beforeEdit');
      beforeEditRecordId = dataSet.fieldValue('id');
      assert(dataSet.state == FdcDataSetState.browse);
      assert(dataSet.fieldValue('name') == 'Alpha');
    },
    afterEdit: (dataSet) {
      eventLog.add('afterEdit');
      afterEditRecordId = dataSet.fieldValue('id');
      assert(dataSet.state == FdcDataSetState.edit);
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

  assert(dataSet.state == FdcDataSetState.edit);
  assert(eventLog.length == 2);
  assert(eventLog[0] == 'beforeEdit');
  assert(eventLog[1] == 'afterEdit');
  assert(beforeEditRecordId == afterEditRecordId);

  dataSet.edit();
  assert(eventLog.length == 2);
}
