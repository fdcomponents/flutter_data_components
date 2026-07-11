import 'package:flutter_data_components/src/data/fdc_dataset_state.dart';
import 'package:flutter_data_components/src/data/fdc_record.dart';

void main() {
  _lazyOriginalSnapshotDetachesOnFirstWrite();
  _sameValueWriteDoesNotMarkFieldChanged();
  _restoreOriginalValuesClearsChangesAfterCopyOnWrite();
  _acceptChangesMakesCurrentValuesTheNewOriginalBaseline();
  _explicitOriginalValuesArePreserved();
  _restoreValuesPreservesOriginalBaselineWhenSnapshotWasShared();
}

void _lazyOriginalSnapshotDetachesOnFirstWrite() {
  final record = FdcRecord(id: 1, values: const ['A', 10]);

  assert(record.changedFieldIndexes().isEmpty);
  assert(record.originalValueAt(0) == 'A');

  record.setValueAt(0, 'B');

  assert(record.valueAt(0) == 'B');
  assert(record.originalValueAt(0) == 'A');
  assert(record.isFieldChanged(0));
  assert(!record.isFieldChanged(1));
  assert(record.changedFieldIndexes().length == 1);
  assert(record.changedFieldIndexes().contains(0));
}

void _sameValueWriteDoesNotMarkFieldChanged() {
  final record = FdcRecord(id: 1, values: const ['A', 10]);

  record.setValueAt(0, 'A');

  assert(record.valueAt(0) == 'A');
  assert(record.originalValueAt(0) == 'A');
  assert(record.changedFieldIndexes().isEmpty);
}

void _restoreOriginalValuesClearsChangesAfterCopyOnWrite() {
  final record = FdcRecord(id: 1, values: const ['A', 10]);

  record.setValueAt(0, 'B');
  record.setValueAt(1, 20);
  record.state = FdcRecordState.modified;

  record.restoreOriginalValues();
  record.state = FdcRecordState.unchanged;

  assert(record.valueAt(0) == 'A');
  assert(record.valueAt(1) == 10);
  assert(record.originalValueAt(0) == 'A');
  assert(record.originalValueAt(1) == 10);
  assert(record.changedFieldIndexes().isEmpty);
  assert(record.state == FdcRecordState.unchanged);
}

void _acceptChangesMakesCurrentValuesTheNewOriginalBaseline() {
  final record = FdcRecord(id: 1, values: const ['A', 10]);

  record.setValueAt(0, 'B');
  record.state = FdcRecordState.modified;
  record.acceptChanges();

  assert(record.state == FdcRecordState.unchanged);
  assert(record.valueAt(0) == 'B');
  assert(record.originalValueAt(0) == 'B');
  assert(record.changedFieldIndexes().isEmpty);

  record.setValueAt(0, 'C');

  assert(record.valueAt(0) == 'C');
  assert(record.originalValueAt(0) == 'B');
  assert(record.isFieldChanged(0));
}

void _explicitOriginalValuesArePreserved() {
  final record = FdcRecord(
    id: 1,
    values: const ['B', 20],
    originalValues: const ['A', 10],
    state: FdcRecordState.modified,
  );

  assert(record.valueAt(0) == 'B');
  assert(record.originalValueAt(0) == 'A');
  assert(record.isFieldChanged(0));
  assert(record.isFieldChanged(1));
}

void _restoreValuesPreservesOriginalBaselineWhenSnapshotWasShared() {
  final record = FdcRecord(id: 1, values: const ['A', 10]);

  record.restoreValues(const ['B', 10]);

  assert(record.valueAt(0) == 'B');
  assert(record.originalValueAt(0) == 'A');
  assert(record.isFieldChanged(0));
  assert(!record.isFieldChanged(1));
}
