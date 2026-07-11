import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

Future<void> main() async {
  Future<FdcDataSet> createDataSet({
    FdcDataSetBeforeScroll? beforeScroll,
    FdcDataSetAfterScroll? afterScroll,
  }) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(size: 255, name: 'name'),
      ],
      beforeScroll: beforeScroll,
      afterScroll: afterScroll,

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Alpha'},
          <String, Object?>{'id': 2, 'name': 'Beta'},
          <String, Object?>{'id': 3, 'name': 'Gamma'},
        ],
      ),
    );
    await dataSet.open();
    return dataSet;
  }

  test('beforeScroll and afterScroll fire around current record change', () async {
    final eventLog = <String>[];
    late final FdcDataSet dataSet;

    dataSet = await createDataSet(
      beforeScroll: (dataSet, currentRecordNumber, targetRecordNumber) {
        final currentName = currentRecordNumber <= 0
            ? null
            : FdcDataSetInternal.fieldValueAt(
                dataSet,
                currentRecordNumber - 1,
                'name',
              );
        final targetName = targetRecordNumber <= 0
            ? null
            : FdcDataSetInternal.fieldValueAt(
                dataSet,
                targetRecordNumber - 1,
                'name',
              );
        eventLog.add(
          'before:$currentRecordNumber->$targetRecordNumber:$currentName->$targetName:index=${FdcDataSetInternal.activeIndex(dataSet)}',
        );
      },
      afterScroll: (dataSet, previousRecordNumber, currentRecordNumber) {
        final previousName = previousRecordNumber <= 0
            ? null
            : FdcDataSetInternal.fieldValueAt(
                dataSet,
                previousRecordNumber - 1,
                'name',
              );
        final currentName = currentRecordNumber <= 0
            ? null
            : FdcDataSetInternal.fieldValueAt(
                dataSet,
                currentRecordNumber - 1,
                'name',
              );
        eventLog.add(
          'after:$previousRecordNumber->$currentRecordNumber:$previousName->$currentName:index=${FdcDataSetInternal.activeIndex(dataSet)}',
        );
      },
    );

    dataSet.next();

    expect(FdcDataSetInternal.activeIndex(dataSet), 1);
    expect(eventLog, <String>[
      'before:1->2:Alpha->Beta:index=0',
      'after:1->2:Alpha->Beta:index=1',
    ]);
  });

  test(
    'beforeScroll silent abort blocks navigation without dataset errors',
    () async {
      var beforeCalls = 0;
      final dataSet = await createDataSet(
        beforeScroll: (dataSet, currentRecordNumber, targetRecordNumber) {
          beforeCalls++;
          if (targetRecordNumber > 0 &&
              FdcDataSetInternal.fieldValueAt(
                    dataSet,
                    targetRecordNumber - 1,
                    'id',
                  ) ==
                  2) {
            throw const FdcDataSetAbortException.silent();
          }
        },
      );

      dataSet.next();

      expect(beforeCalls, 1);
      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(dataSet.fieldValue('name'), 'Alpha');
      expect(dataSet.errors.messages.isNotEmpty, isFalse);
    },
  );

  test(
    'beforeScroll visible abort blocks navigation and stores dataset error',
    () async {
      var beforeCalls = 0;
      final dataSet = await createDataSet(
        beforeScroll: (dataSet, currentRecordNumber, targetRecordNumber) {
          beforeCalls++;
          if (targetRecordNumber > 0 &&
              FdcDataSetInternal.fieldValueAt(
                    dataSet,
                    targetRecordNumber - 1,
                    'id',
                  ) ==
                  2) {
            throw FdcDataSetAbortException('Scroll is not allowed.');
          }
        },
      );

      dataSet.next();

      expect(beforeCalls, 1);
      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(dataSet.errors.messages.isNotEmpty, isTrue);
      expect(dataSet.errors.messages[0], 'Scroll is not allowed.');
    },
  );

  test(
    'scroll events do not fire when target record is already current',
    () async {
      final eventLog = <String>[];
      final dataSet = await createDataSet(
        beforeScroll: (dataSet, currentRecordNumber, targetRecordNumber) {
          eventLog.add('before');
        },
        afterScroll: (dataSet, previousRecordNumber, currentRecordNumber) {
          eventLog.add('after');
        },
      );

      dataSet.moveToRecord(1);

      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(eventLog, isEmpty);
    },
  );

  test('afterScroll does not fire when beforeScroll aborts', () async {
    final eventLog = <String>[];
    final dataSet = await createDataSet(
      beforeScroll: (dataSet, currentRecordNumber, targetRecordNumber) {
        eventLog.add('before');
        throw const FdcDataSetAbortException.silent();
      },
      afterScroll: (dataSet, previousRecordNumber, currentRecordNumber) {
        eventLog.add('after');
      },
    );

    dataSet.last();

    expect(FdcDataSetInternal.activeIndex(dataSet), 0);
    expect(eventLog, <String>['before']);
  });
}
