import 'package:flutter_data_components/fdc.dart';

Future<void> main() async {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    beforeDelete: (dataSet) {
      throw FdcDataSetAbortException('Delete is not allowed.');
    },

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1},
      ],
    ),
  );

  await dataSet.open();

  dataSet.delete();
  assert(dataSet.errors.messages.isNotEmpty);
  assert(dataSet.errors.messages[0] == 'Delete is not allowed.');
  assert(dataSet.recordCount == 1);
}
