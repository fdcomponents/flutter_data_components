import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  var afterInsertCalled = false;

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    beforeInsert: (dataSet) {
      throw FdcDataSetAbortException('Insert is not allowed.');
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
  assert(dataSet.errors.messages.isNotEmpty);
  assert(dataSet.errors.messages[0] == 'Insert is not allowed.');
  assert(dataSet.errors.messages[0] == 'Insert is not allowed.');
}
