import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'append fires insert callbacks around creation of the new record',
    () async {
      final eventLog = <String>[];

      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name'),
        ],
        beforeInsert: (dataSet) {
          eventLog.add('beforeInsert');
          expect(dataSet.state, FdcDataSetState.browse);
        },
        afterInsert: (dataSet) {
          eventLog.add('afterInsert');
          expect(dataSet.state, FdcDataSetState.insert);
          expect(dataSet.fieldValue('name'), isNull);
        },
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            <String, Object?>{'id': 1, 'name': 'Alpha'},
          ],
        ),
      );

      await dataSet.open();
      dataSet.append();

      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet.recordCount, 2);
      expect(eventLog, <String>['beforeInsert', 'afterInsert']);
    },
  );
}
