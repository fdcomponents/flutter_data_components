import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('memory adapter update replaces existing key ignoring case', () async {
    final adapter = FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        <String, Object?>{'ID': 1, 'Name': 'Alpha'},
      ],
    );

    final result = await adapter.applyUpdates(
      const FdcChangeSet(
        fields: <FdcFieldDef>[
          FdcIntegerField(name: 'id', isKey: true),
          FdcStringField(name: 'name', size: 80),
        ],
        inserts: <FdcChangeSetEntry>[],
        updates: <FdcChangeSetEntry>[
          FdcChangeSetEntry(
            recordId: 1,
            values: <String, Object?>{'name': 'Beta'},
            originalValues: <String, Object?>{'id': 1, 'name': 'Alpha'},
            changedFields: <String>{'name'},
          ),
        ],
        deletes: <FdcChangeSetEntry>[],
      ),
    );

    expect(result.success, isTrue);
    expect(adapter.rows.single, <String, Object?>{'ID': 1, 'Name': 'Beta'});
  });
}
