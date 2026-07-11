import 'package:flutter_data_components/src/data/fdc_dataset_state.dart';
import 'package:flutter_data_components/src/data/fdc_record.dart';
import 'package:flutter_data_components/src/data/fdc_record_store.dart';

void main() {
  _recordsViewDoesNotAllowStructuralMutation();
  _removeWhereKeepsLookupIndexInSync();
  _replaceAllRebuildsLookupIndex();
  _insertRawKeepsRawIndexLookupInSync();
  _removeByIdKeepsRawIndexLookupInSync();
  _duplicateRecordIdsAreRejected();
}

void _recordsViewDoesNotAllowStructuralMutation() {
  final store = FdcRecordStore();
  final first = FdcRecord(id: store.takeNextRecordId(), values: const ['A']);
  final second = FdcRecord(id: store.takeNextRecordId(), values: const ['B']);

  store.insertRaw(0, first);
  store.insertRaw(1, second);

  var threw = false;
  try {
    store.records.removeWhere((record) => record.id == first.id);
    // ignore: avoid_catching_errors
  } on UnsupportedError {
    threw = true;
  }

  assert(threw);
  assert(store.length == 2);
  assert(identical(store.byId(first.id), first));
  assert(identical(store.byId(second.id), second));
}

void _removeWhereKeepsLookupIndexInSync() {
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

  assert(removed == 1);
  assert(store.length == 2);
  assert(identical(store.byId(first.id), first));
  assert(store.byId(second.id) == null);
  assert(identical(store.byId(third.id), third));
  assert(store.rawIndexForId(third.id) == 1);
}

void _replaceAllRebuildsLookupIndex() {
  final store = FdcRecordStore();
  final first = FdcRecord(id: store.takeNextRecordId(), values: const ['A']);
  store.insertRaw(0, first);

  final replacement = FdcRecord(
    id: store.takeNextRecordId(),
    values: const ['B'],
  );
  store.replaceAll(<FdcRecord>[replacement]);

  assert(store.length == 1);
  assert(store.byId(first.id) == null);
  assert(identical(store.byId(replacement.id), replacement));
  assert(store.rawIndexForId(replacement.id) == 0);
}

void _insertRawKeepsRawIndexLookupInSync() {
  final store = FdcRecordStore();
  final first = FdcRecord(id: store.takeNextRecordId(), values: const ['A']);
  final second = FdcRecord(id: store.takeNextRecordId(), values: const ['B']);
  final inserted = FdcRecord(id: store.takeNextRecordId(), values: const ['C']);

  store.insertRaw(0, first);
  store.insertRaw(1, second);
  store.insertRaw(1, inserted);

  assert(store.rawIndexForId(first.id) == 0);
  assert(store.rawIndexForId(inserted.id) == 1);
  assert(store.rawIndexForId(second.id) == 2);
}

void _removeByIdKeepsRawIndexLookupInSync() {
  final store = FdcRecordStore();
  final first = FdcRecord(id: store.takeNextRecordId(), values: const ['A']);
  final second = FdcRecord(id: store.takeNextRecordId(), values: const ['B']);
  final third = FdcRecord(id: store.takeNextRecordId(), values: const ['C']);

  store.insertRaw(0, first);
  store.insertRaw(1, second);
  store.insertRaw(2, third);

  final removed = store.removeById(second.id);

  assert(removed);
  assert(store.length == 2);
  assert(store.rawIndexForId(first.id) == 0);
  assert(store.rawIndexForId(second.id) == null);
  assert(store.rawIndexForId(third.id) == 1);
}

void _duplicateRecordIdsAreRejected() {
  final store = FdcRecordStore();
  final first = FdcRecord(id: 7, values: const ['A']);
  final duplicate = FdcRecord(id: 7, values: const ['B']);

  store.insertRaw(0, first);

  var insertThrew = false;
  try {
    store.insertRaw(1, duplicate);
    // ignore: avoid_catching_errors
  } on ArgumentError {
    insertThrew = true;
  }

  var replaceThrew = false;
  try {
    store.replaceAll(<FdcRecord>[first, duplicate]);
    // ignore: avoid_catching_errors
  } on ArgumentError {
    replaceThrew = true;
  }

  assert(insertThrew);
  assert(replaceThrew);
}
