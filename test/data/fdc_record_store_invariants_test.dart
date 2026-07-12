import 'package:flutter_data_components/src/data/fdc_dataset_state.dart';
import 'package:flutter_data_components/src/data/fdc_record.dart';
import 'package:flutter_data_components/src/data/fdc_record_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('records view rejects structural mutation and preserves indexes', () {
    final store = FdcRecordStore();
    final first = FdcRecord(id: store.takeNextRecordId(), values: const ['A']);
    final second = FdcRecord(id: store.takeNextRecordId(), values: const ['B']);

    store.insertRaw(0, first);
    store.insertRaw(1, second);

    expect(
      () => store.records.removeWhere((record) => record.id == first.id),
      throwsUnsupportedError,
    );
    expect(store.length, 2);
    expect(store.byId(first.id), same(first));
    expect(store.byId(second.id), same(second));
  });

  test('removeWhere keeps record and raw-index lookups synchronized', () {
    final store = FdcRecordStore();
    final first = FdcRecord(id: store.takeNextRecordId(), values: const ['A']);
    final second = FdcRecord(
      id: store.takeNextRecordId(),
      values: const ['B'],
      state: FdcRecordState.deleted,
    );
    final third = FdcRecord(id: store.takeNextRecordId(), values: const ['C']);

    store.insertRaw(0, first);
    store.insertRaw(1, second);
    store.insertRaw(2, third);

    final removed = store.removeWhere(
      (record) => record.state == FdcRecordState.deleted,
    );

    expect(removed, 1);
    expect(store.length, 2);
    expect(store.byId(first.id), same(first));
    expect(store.byId(second.id), isNull);
    expect(store.byId(third.id), same(third));
    expect(store.rawIndexForId(third.id), 1);
  });

  test('replaceAll rebuilds record and raw-index lookups', () {
    final store = FdcRecordStore();
    final first = FdcRecord(id: store.takeNextRecordId(), values: const ['A']);
    store.insertRaw(0, first);

    final replacement = FdcRecord(
      id: store.takeNextRecordId(),
      values: const ['B'],
    );
    store.replaceAll(<FdcRecord>[replacement]);

    expect(store.length, 1);
    expect(store.byId(first.id), isNull);
    expect(store.byId(replacement.id), same(replacement));
    expect(store.rawIndexForId(replacement.id), 0);
  });

  test('insertRaw shifts following raw-index lookups', () {
    final store = FdcRecordStore();
    final first = FdcRecord(id: store.takeNextRecordId(), values: const ['A']);
    final second = FdcRecord(id: store.takeNextRecordId(), values: const ['B']);
    final inserted = FdcRecord(
      id: store.takeNextRecordId(),
      values: const ['C'],
    );

    store.insertRaw(0, first);
    store.insertRaw(1, second);
    store.insertRaw(1, inserted);

    expect(store.rawIndexForId(first.id), 0);
    expect(store.rawIndexForId(inserted.id), 1);
    expect(store.rawIndexForId(second.id), 2);
  });

  test('removeById removes the record and shifts following raw indexes', () {
    final store = FdcRecordStore();
    final first = FdcRecord(id: store.takeNextRecordId(), values: const ['A']);
    final second = FdcRecord(id: store.takeNextRecordId(), values: const ['B']);
    final third = FdcRecord(id: store.takeNextRecordId(), values: const ['C']);

    store.insertRaw(0, first);
    store.insertRaw(1, second);
    store.insertRaw(2, third);

    final removed = store.removeById(second.id);

    expect(removed, isTrue);
    expect(store.length, 2);
    expect(store.rawIndexForId(first.id), 0);
    expect(store.rawIndexForId(second.id), isNull);
    expect(store.rawIndexForId(third.id), 1);
  });

  test('insertRaw and replaceAll reject duplicate record IDs', () {
    final store = FdcRecordStore();
    final first = FdcRecord(id: 7, values: const ['A']);
    final duplicate = FdcRecord(id: 7, values: const ['B']);

    store.insertRaw(0, first);

    expect(() => store.insertRaw(1, duplicate), throwsArgumentError);
    expect(
      () => store.replaceAll(<FdcRecord>[first, duplicate]),
      throwsArgumentError,
    );
  });
}
