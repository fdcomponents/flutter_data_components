import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'edit fires beforeEdit and afterEdit once for a browse record',
    () async {
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
          expect(dataSet.state, FdcDataSetState.browse);
          expect(dataSet.fieldValue('name'), 'Alpha');
        },
        afterEdit: (dataSet) {
          eventLog.add('afterEdit');
          afterEditRecordId = dataSet.fieldValue('id');
          expect(dataSet.state, FdcDataSetState.edit);
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

      expect(dataSet.state, FdcDataSetState.edit);
      expect(eventLog, <String>['beforeEdit', 'afterEdit']);
      expect(afterEditRecordId, same(beforeEditRecordId));

      dataSet.edit();
      expect(
        eventLog,
        <String>['beforeEdit', 'afterEdit'],
        reason:
            'Calling edit while already editing must not fire callbacks again.',
      );
    },
  );
}
