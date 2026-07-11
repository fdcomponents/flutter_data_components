import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  final eventLog = <String>[];

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name'),
    ],
    beforeInsert: (dataSet) {
      eventLog.add('beforeInsert');
      assert(dataSet.state == FdcDataSetState.browse);
    },
    afterInsert: (dataSet) {
      eventLog.add('afterInsert');
      assert(dataSet.state == FdcDataSetState.insert);
      assert(dataSet.fieldValue('name') == null);
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
      ],
    ),
  );

  await dataSet.open();

  dataSet.append();

  assert(dataSet.state == FdcDataSetState.insert);
  assert(dataSet.recordCount == 2);
  assert(eventLog.length == 2);
  assert(eventLog[0] == 'beforeInsert');
  assert(eventLog[1] == 'afterInsert');
}
