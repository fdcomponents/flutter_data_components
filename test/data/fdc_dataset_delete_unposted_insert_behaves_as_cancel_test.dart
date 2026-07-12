import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deleting an unposted append discards it without delete or cancel events',
    () async {
      final eventLog = <String>[];
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name'),
        ],
        beforeDelete: (dataSet) {
          eventLog.add('beforeDelete');
          throw FdcDataSetAbortException(
            'Delete must not run for unposted insert.',
          );
        },
        afterDelete: (dataSet) => eventLog.add('afterDelete'),
        beforeCancel: (dataSet) {
          eventLog.add('beforeCancel');
          throw FdcDataSetAbortException(
            'Cancel must not run for delete insert.',
          );
        },
        afterCancel: (dataSet) => eventLog.add('afterCancel'),
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      );

      await dataSet.open();
      dataSet.append();
      dataSet.setFieldValue('id', 2);
      dataSet.setFieldValue('name', 'Unposted append');

      dataSet.delete();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 1);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id'), 1);
      expect(dataSet.errors.message, isEmpty);
      expect(eventLog, isEmpty);
    },
  );

  test(
    'deleting an inserted row discards only the active unposted record',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name'),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
            {'id': 3, 'name': 'Gamma'},
          ],
        ),
      );

      await dataSet.open();
      dataSet.moveToRecord(2);
      dataSet.insert();
      dataSet.setFieldValue('id', 2);
      dataSet.setFieldValue('name', 'Unposted insert');

      dataSet.delete();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
      expect(
        <Object?>[
          FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id'),
          FdcDataSetInternal.fieldValueAt(dataSet, 1, 'id'),
        ],
        <Object?>[1, 3],
      );
      expect(dataSet.changeSet.inserts, isEmpty);
      expect(dataSet.changeSet.deletes, isEmpty);
    },
  );

  test(
    'beforeCancel abort does not block deleting an unposted insert',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name'),
        ],
        beforeCancel: (dataSet) {
          throw FdcDataSetAbortException('Cancel is blocked.');
        },
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      );

      await dataSet.open();
      dataSet.append();
      dataSet.setFieldValue('id', 2);
      dataSet.setFieldValue('name', 'Unposted append');

      dataSet.delete();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 1);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'id'), 1);
      expect(dataSet.errors.message, isEmpty);
    },
  );
}
