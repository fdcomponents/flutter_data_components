import 'package:flutter_data_components/src/data/fdc_dataset_state.dart';
import 'package:flutter_data_components/src/data/fdc_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lazy original snapshot detaches on the first changed write', () {
    final record = FdcRecord(id: 1, values: const ['A', 10]);

    expect(record.changedFieldIndexes(), isEmpty);
    expect(record.originalValueAt(0), 'A');

    record.setValueAt(0, 'B');

    expect(record.valueAt(0), 'B');
    expect(record.originalValueAt(0), 'A');
    expect(record.isFieldChanged(0), isTrue);
    expect(record.isFieldChanged(1), isFalse);
    expect(record.changedFieldIndexes(), <int>[0]);
  });

  test('writing the same value does not mark the field as changed', () {
    final record = FdcRecord(id: 1, values: const ['A', 10]);

    record.setValueAt(0, 'A');

    expect(record.valueAt(0), 'A');
    expect(record.originalValueAt(0), 'A');
    expect(record.changedFieldIndexes(), isEmpty);
  });

  test('restoreOriginalValues clears changes after copy-on-write', () {
    final record = FdcRecord(id: 1, values: const ['A', 10]);

    record.setValueAt(0, 'B');
    record.setValueAt(1, 20);
    record.state = FdcRecordState.modified;

    record.restoreOriginalValues();
    record.state = FdcRecordState.unchanged;

    expect(record.valueAt(0), 'A');
    expect(record.valueAt(1), 10);
    expect(record.originalValueAt(0), 'A');
    expect(record.originalValueAt(1), 10);
    expect(record.changedFieldIndexes(), isEmpty);
    expect(record.state, FdcRecordState.unchanged);
  });

  test('acceptChanges establishes current values as the new baseline', () {
    final record = FdcRecord(id: 1, values: const ['A', 10]);

    record.setValueAt(0, 'B');
    record.state = FdcRecordState.modified;
    record.acceptChanges();

    expect(record.state, FdcRecordState.unchanged);
    expect(record.valueAt(0), 'B');
    expect(record.originalValueAt(0), 'B');
    expect(record.changedFieldIndexes(), isEmpty);

    record.setValueAt(0, 'C');

    expect(record.valueAt(0), 'C');
    expect(record.originalValueAt(0), 'B');
    expect(record.isFieldChanged(0), isTrue);
  });

  test('explicit original values remain the modification baseline', () {
    final record = FdcRecord(
      id: 1,
      values: const ['B', 20],
      originalValues: const ['A', 10],
      state: FdcRecordState.modified,
    );

    expect(record.valueAt(0), 'B');
    expect(record.originalValueAt(0), 'A');
    expect(record.isFieldChanged(0), isTrue);
    expect(record.isFieldChanged(1), isTrue);
  });

  test('restoreValues preserves a previously shared original baseline', () {
    final record = FdcRecord(id: 1, values: const ['A', 10]);

    record.restoreValues(const ['B', 10]);

    expect(record.valueAt(0), 'B');
    expect(record.originalValueAt(0), 'A');
    expect(record.isFieldChanged(0), isTrue);
    expect(record.isFieldChanged(1), isFalse);
  });
}
