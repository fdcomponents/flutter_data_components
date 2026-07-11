import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  var afterEditCalled = false;

  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    beforeEdit: (dataSet) {
      throw FdcDataSetAbortException('Edit is not allowed.');
    },
    afterEdit: (dataSet) {
      afterEditCalled = true;
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1},
      ],
    ),
  );

  await dataSet.open();

  dataSet.edit();
  assert(!afterEditCalled);
  assert(dataSet.state == FdcDataSetState.browse);
  assert(dataSet.errors.messages.isNotEmpty);
  assert(dataSet.errors.messages[0] == 'Edit is not allowed.');
  assert(dataSet.errors.messages[0] == 'Edit is not allowed.');
}
