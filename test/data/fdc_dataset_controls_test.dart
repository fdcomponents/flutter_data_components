import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main() async {
  Future<FdcDataSet> createDataSet({
    FdcDataSetStateChanged? onStateChanged,
    FdcDataSetFieldChanged? onFieldChanged,
    FdcDataSetBeforeScroll? beforeScroll,
    FdcDataSetAfterScroll? afterScroll,
  }) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(name: 'name', size: 50),
      ],
      onStateChanged: onStateChanged,
      onFieldChanged: onFieldChanged,
      beforeScroll: beforeScroll,
      afterScroll: afterScroll,
    );
    await dataSet.loadRows(<Map<String, Object?>>[
      <String, Object?>{'id': 1, 'name': 'One'},
      <String, Object?>{'id': 2, 'name': 'Two'},
      <String, Object?>{'id': 3, 'name': 'Three'},
    ]);
    return dataSet;
  }

  test(
    'disableControls suppresses listener delivery while state stays live',
    () async {
      final dataSet = await createDataSet();
      var notifications = 0;
      dataSet.addListener(() => notifications++);

      dataSet.disableControls();
      dataSet.next();
      dataSet.next();

      expect(dataSet.controlsDisabled, isTrue);
      expect(dataSet.controlsDisableCount, 1);
      expect(dataSet.recordNumber, 3);
      expect(dataSet.fieldValue('name'), 'Three');
      expect(notifications, 0);

      dataSet.enableControls();

      expect(dataSet.controlsDisabled, isFalse);
      expect(dataSet.controlsDisableCount, 0);
      expect(notifications, 1);

      dataSet.dispose();
    },
  );

  test(
    'nested disableControls flushes only after the outermost enable',
    () async {
      final dataSet = await createDataSet();
      var notifications = 0;
      dataSet.addListener(() => notifications++);

      dataSet.disableControls();
      dataSet.disableControls();
      dataSet.next();

      expect(dataSet.controlsDisableCount, 2);
      expect(notifications, 0);

      dataSet.enableControls();
      expect(dataSet.controlsDisableCount, 1);
      expect(dataSet.controlsDisabled, isTrue);
      expect(notifications, 0);

      dataSet.last();
      expect(notifications, 0);

      dataSet.enableControls();
      expect(dataSet.controlsDisableCount, 0);
      expect(notifications, 1);

      dataSet.dispose();
    },
  );

  test('no-op disable and enable pair does not emit a notification', () async {
    final dataSet = await createDataSet();
    var notifications = 0;
    dataSet.addListener(() => notifications++);

    dataSet.disableControls();
    dataSet.enableControls();

    expect(notifications, 0);
    dataSet.dispose();
  });

  test('multiple edit and navigation notifications coalesce to one', () async {
    final dataSet = await createDataSet();
    var notifications = 0;
    dataSet.addListener(() => notifications++);

    dataSet.disableControls();
    dataSet.edit();
    dataSet.setFieldValue('name', 'Updated');
    dataSet.post();
    dataSet.next();
    dataSet.last();

    expect(notifications, 0);
    expect(dataSet.recordNumber, 3);
    expect(dataSet.state, FdcDataSetState.browse);

    dataSet.enableControls();

    expect(notifications, 1);
    dataSet.first();
    expect(dataSet.fieldValue('name'), 'Updated');

    dataSet.dispose();
  });

  test(
    'typed lifecycle callbacks remain active while controls are disabled',
    () async {
      final events = <String>[];
      final dataSet = await createDataSet(
        onStateChanged: (dataSet, previousState, currentState) {
          events.add('state:$previousState->$currentState');
        },
        onFieldChanged: (dataSet, field, oldValue, newValue) {
          events.add('field:${field.name}:$oldValue->$newValue');
        },
        beforeScroll: (dataSet, currentRecordNumber, targetRecordNumber) {
          events.add('before:$currentRecordNumber->$targetRecordNumber');
        },
        afterScroll: (dataSet, previousRecordNumber, currentRecordNumber) {
          events.add('after:$previousRecordNumber->$currentRecordNumber');
        },
      );
      events.clear();
      var notifications = 0;
      dataSet.addListener(() => notifications++);

      dataSet.disableControls();
      dataSet.edit();
      dataSet.setFieldValue('name', 'Changed');
      dataSet.post();
      dataSet.next();

      expect(notifications, 0);
      expect(
        events,
        <String>[
          'state:FdcDataSetState.browse->FdcDataSetState.edit',
          'field:name:One->Changed',
          'state:FdcDataSetState.edit->FdcDataSetState.browse',
          'before:1->2',
          'after:1->2',
        ],
        reason:
            'Disabling controls must suppress listener notifications '
            'without changing typed lifecycle callback order.',
      );

      dataSet.enableControls();
      expect(notifications, 1);

      dataSet.dispose();
    },
  );

  test('enableControls rejects an unbalanced call', () async {
    final dataSet = await createDataSet();

    expect(dataSet.enableControls, throwsStateError);
    expect(dataSet.controlsDisableCount, 0);

    dataSet.dispose();
  });

  test(
    'dispose clears a pending controls suspension without flushing it',
    () async {
      final dataSet = await createDataSet();
      var notifications = 0;
      dataSet.addListener(() => notifications++);

      dataSet.disableControls();
      dataSet.next();
      dataSet.dispose();

      expect(notifications, 0);
      expect(dataSet.controlsDisabled, isFalse);
      expect(dataSet.controlsDisableCount, 0);
      expect(dataSet.enableControls, returnsNormally);
    },
  );

  test('restoreCurrentRecord defaults to false', () async {
    final dataSet = await createDataSet();

    dataSet.moveToRecord(2);
    dataSet.disableControls();
    dataSet.last();
    dataSet.enableControls();

    expect(dataSet.recordNumber, 3);
    expect(dataSet.fieldValue('id'), 3);
    expect(dataSet.restoresCurrentRecordOnEnable, isFalse);

    dataSet.dispose();
  });

  test(
    'restoreCurrentRecord restores the saved record before final notify',
    () async {
      final dataSet = await createDataSet();
      dataSet.moveToRecord(2);
      var notifications = 0;
      final notifiedRecordNumbers = <int>[];
      dataSet.addListener(() {
        notifications++;
        notifiedRecordNumbers.add(dataSet.recordNumber);
      });

      dataSet.disableControls(restoreCurrentRecord: true);
      expect(dataSet.restoresCurrentRecordOnEnable, isTrue);

      dataSet.first();
      dataSet.last();
      expect(dataSet.recordNumber, 3);
      expect(notifications, 0);

      dataSet.enableControls();

      expect(dataSet.recordNumber, 2);
      expect(dataSet.fieldValue('id'), 2);
      expect(notifications, 1);
      expect(notifiedRecordNumbers, <int>[2]);
      expect(dataSet.restoresCurrentRecordOnEnable, isFalse);

      dataSet.dispose();
    },
  );

  test('nested restore waits for the outermost enable', () async {
    final dataSet = await createDataSet();
    dataSet.moveToRecord(2);
    var notifications = 0;
    dataSet.addListener(() => notifications++);

    dataSet.disableControls(restoreCurrentRecord: true);
    dataSet.disableControls();
    dataSet.last();

    dataSet.enableControls();
    expect(dataSet.recordNumber, 3);
    expect(dataSet.controlsDisabled, isTrue);
    expect(notifications, 0);

    dataSet.enableControls();
    expect(dataSet.recordNumber, 2);
    expect(dataSet.controlsDisabled, isFalse);
    expect(notifications, 1);

    dataSet.dispose();
  });

  test('first nested restore request owns the suspension bookmark', () async {
    final dataSet = await createDataSet();

    dataSet.disableControls();
    dataSet.next();
    dataSet.disableControls(restoreCurrentRecord: true);
    dataSet.last();
    dataSet.disableControls(restoreCurrentRecord: true);
    dataSet.first();

    dataSet.enableControls();
    dataSet.enableControls();
    expect(dataSet.recordNumber, 1);

    dataSet.enableControls();
    expect(dataSet.recordNumber, 2);
    expect(dataSet.fieldValue('id'), 2);

    dataSet.dispose();
  });

  test(
    'restore falls back to the nearest valid index when record is deleted',
    () async {
      final dataSet = await createDataSet();
      dataSet.moveToRecord(2);
      var notifications = 0;
      dataSet.addListener(() => notifications++);

      dataSet.disableControls(restoreCurrentRecord: true);
      dataSet.delete();
      dataSet.last();
      expect(dataSet.recordCount, 2);
      expect(dataSet.fieldValue('id'), 3);

      dataSet.enableControls();

      expect(dataSet.recordNumber, 2);
      expect(dataSet.fieldValue('id'), 3);
      expect(notifications, 1);

      dataSet.dispose();
    },
  );

  test('restore-only no-op does not emit a notification', () async {
    final dataSet = await createDataSet();
    dataSet.moveToRecord(2);
    var notifications = 0;
    dataSet.addListener(() => notifications++);

    dataSet.disableControls(restoreCurrentRecord: true);
    dataSet.enableControls();

    expect(dataSet.recordNumber, 2);
    expect(notifications, 0);

    dataSet.dispose();
  });

  test('bookmarks.create returns null without a current open record', () async {
    final closedDataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
    );
    expect(closedDataSet.bookmarks.create(), isNull);

    await closedDataSet.loadRows(const <Map<String, Object?>>[]);
    expect(closedDataSet.bookmarks.create(), isNull);

    closedDataSet.dispose();
  });

  test(
    'bookmark restores the same record after arbitrary navigation',
    () async {
      final dataSet = await createDataSet();
      dataSet.moveToRecord(2);
      final bookmark = dataSet.bookmarks.create();

      expect(bookmark, isNotNull);
      dataSet.last();

      final restored = dataSet.bookmarks.restore(bookmark!);

      expect(restored, isTrue);
      expect(dataSet.recordNumber, 2);
      expect(dataSet.fieldValue('id'), 2);

      dataSet.dispose();
    },
  );

  test(
    'bookmark follows record identity across active-view reordering',
    () async {
      final dataSet = await createDataSet();
      dataSet.moveToRecord(2);
      final bookmark = dataSet.bookmarks.create()!;

      await dataSet.sort.set(const <FdcDataSetSort>[
        FdcDataSetSort(fieldName: 'name', sortType: FdcSortType.descending),
      ]);
      dataSet.last();

      final restored = dataSet.bookmarks.restore(bookmark);

      expect(restored, isTrue);
      expect(dataSet.fieldValue('id'), 2);

      dataSet.dispose();
    },
  );

  test(
    'bookmark from another dataset is rejected without navigation',
    () async {
      final source = await createDataSet();
      final target = await createDataSet();
      source.moveToRecord(2);
      target.moveToRecord(3);
      final bookmark = source.bookmarks.create()!;

      final restored = target.bookmarks.restore(
        bookmark,
        fallbackToNearest: true,
      );

      expect(restored, isFalse);
      expect(target.recordNumber, 3);
      expect(target.fieldValue('id'), 3);

      source.dispose();
      target.dispose();
    },
  );

  test('missing bookmarked record does not move without fallback', () async {
    final dataSet = await createDataSet();
    dataSet.moveToRecord(2);
    final bookmark = dataSet.bookmarks.create()!;
    dataSet.delete();
    dataSet.first();

    final restored = dataSet.bookmarks.restore(bookmark);

    expect(restored, isFalse);
    expect(dataSet.recordNumber, 1);
    expect(dataSet.fieldValue('id'), 1);

    dataSet.dispose();
  });

  test(
    'missing bookmarked record can fall back to nearest valid index',
    () async {
      final dataSet = await createDataSet();
      dataSet.moveToRecord(2);
      final bookmark = dataSet.bookmarks.create()!;
      dataSet.delete();
      dataSet.first();

      final restored = dataSet.bookmarks.restore(
        bookmark,
        fallbackToNearest: true,
      );

      expect(restored, isFalse);
      expect(dataSet.recordNumber, 2);
      expect(dataSet.fieldValue('id'), 3);

      dataSet.dispose();
    },
  );

  test(
    'bookmark restore participates in controls notification coalescing',
    () async {
      final dataSet = await createDataSet();
      dataSet.moveToRecord(2);
      final bookmark = dataSet.bookmarks.create()!;
      var notifications = 0;
      final notifiedRecords = <int>[];
      dataSet.addListener(() {
        notifications++;
        notifiedRecords.add(dataSet.recordNumber);
      });

      dataSet.disableControls();
      dataSet.last();
      expect(dataSet.bookmarks.restore(bookmark), isTrue);
      expect(notifications, 0);
      dataSet.enableControls();

      expect(notifications, 1);
      expect(notifiedRecords, <int>[2]);

      dataSet.dispose();
    },
  );

  test(
    'later nested restore request can capture after an empty start',
    () async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      );
      await dataSet.loadRows(const <Map<String, Object?>>[]);

      dataSet.disableControls(restoreCurrentRecord: true);
      expect(dataSet.restoresCurrentRecordOnEnable, isFalse);

      await dataSet.loadRows(const <Map<String, Object?>>[
        <String, Object?>{'id': 1},
        <String, Object?>{'id': 2},
      ]);
      expect(dataSet.recordNumber, 1);

      dataSet.disableControls(restoreCurrentRecord: true);
      expect(dataSet.restoresCurrentRecordOnEnable, isTrue);
      dataSet.last();

      dataSet.enableControls();
      expect(dataSet.recordNumber, 2);
      expect(dataSet.controlsDisabled, isTrue);

      dataSet.enableControls();
      expect(dataSet.recordNumber, 1);
      expect(dataSet.fieldValue('id'), 1);
      expect(dataSet.controlsDisabled, isFalse);

      dataSet.dispose();
    },
  );

  test('bookmark APIs are safe after dataset disposal', () async {
    final dataSet = await createDataSet();
    dataSet.moveToRecord(2);
    final bookmark = dataSet.bookmarks.create()!;

    dataSet.dispose();

    expect(dataSet.bookmarks.create(), isNull);
    expect(dataSet.bookmarks.restore(bookmark), isFalse);
  });
}
