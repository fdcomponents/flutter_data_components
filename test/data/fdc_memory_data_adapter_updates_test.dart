import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'memory adapter applyUpdates applies inserts updates and deletes',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Ethan'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          inserts: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 3,
              values: <String, Object?>{'id': 3, 'name': 'Mia'},
              originalValues: <String, Object?>{},
              changedFields: <String>{'id', 'name'},
            ),
          ],
          updates: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 1,
              values: <String, Object?>{'name': 'Alice Maria'},
              originalValues: <String, Object?>{'name': 'Alice'},
              changedFields: <String>{'name'},
            ),
          ],
          deletes: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 2,
              values: <String, Object?>{},
              originalValues: <String, Object?>{'id': 2, 'name': 'Ethan'},
              changedFields: <String>{},
            ),
          ],
        ),
      );

      expect(result.success, isTrue);
      expect(adapter.rows, <Map<String, Object?>>[
        {'id': 1, 'name': 'Alice Maria'},
        {'id': 3, 'name': 'Mia'},
      ]);
    },
  );

  test(
    'memory adapter applyUpdates matches updates and deletes by key fields',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Server Alice'},
          {'id': 2, 'name': 'Server Ethan'},
          {'id': 3, 'name': 'Mia'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          fields: <FdcFieldDef>[
            FdcIntegerField(name: 'id', isKey: true),
            FdcStringField(name: 'name', size: 100),
          ],
          inserts: <FdcChangeSetEntry>[],
          updates: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{'name': 'Alice Maria'},
              originalValues: <String, Object?>{'id': 1, 'name': 'Local Alice'},
              changedFields: <String>{'name'},
            ),
          ],
          deletes: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{},
              originalValues: <String, Object?>{'id': 2, 'name': 'Local Ethan'},
              changedFields: <String>{},
            ),
          ],
        ),
      );

      expect(result.success, isTrue);
      expect(adapter.rows, <Map<String, Object?>>[
        {'id': 1, 'name': 'Alice Maria'},
        {'id': 3, 'name': 'Mia'},
      ]);
    },
  );

  test(
    'memory adapter applyUpdates fails missing update and keeps rows unchanged',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Ethan'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          inserts: <FdcChangeSetEntry>[],
          updates: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{'name': 'Ghost'},
              originalValues: <String, Object?>{'id': 99, 'name': 'Missing'},
              changedFields: <String>{'name'},
            ),
          ],
          deletes: <FdcChangeSetEntry>[],
        ),
      );

      expect(result.success, isFalse);
      expect(result.errors.single.recordId, 99);
      expect(result.errors.single.code, 'not_found');
      expect(result.errors.single.message, contains('Update failed'));
      expect(adapter.rows, <Map<String, Object?>>[
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Ethan'},
      ]);
    },
  );

  test(
    'memory adapter applyUpdates fails missing delete and keeps rows unchanged',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Ethan'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          inserts: <FdcChangeSetEntry>[],
          updates: <FdcChangeSetEntry>[],
          deletes: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{},
              originalValues: <String, Object?>{'id': 99, 'name': 'Missing'},
              changedFields: <String>{},
            ),
          ],
        ),
      );

      expect(result.success, isFalse);
      expect(result.errors.single.recordId, 99);
      expect(result.errors.single.code, 'not_found');
      expect(result.errors.single.message, contains('Delete failed'));
      expect(adapter.rows, <Map<String, Object?>>[
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Ethan'},
      ]);
    },
  );

  test(
    'memory adapter applyUpdates is copy-on-write for mixed batch failure',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Ethan'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          deletes: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 2,
              values: <String, Object?>{},
              originalValues: <String, Object?>{'id': 2, 'name': 'Ethan'},
              changedFields: <String>{},
            ),
          ],
          updates: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{'name': 'Ghost'},
              originalValues: <String, Object?>{'id': 99, 'name': 'Missing'},
              changedFields: <String>{'name'},
            ),
          ],
          inserts: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 3,
              values: <String, Object?>{'id': 3, 'name': 'Mia'},
              originalValues: <String, Object?>{},
              changedFields: <String>{'id', 'name'},
            ),
          ],
        ),
      );

      expect(result.success, isFalse);
      expect(result.errors.single.recordId, 99);
      expect(adapter.rows, <Map<String, Object?>>[
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Ethan'},
      ]);
    },
  );

  test(
    'memory adapter without keys does not fall back to value matching',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alice'},
          {'name': 'Ethan'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          inserts: <FdcChangeSetEntry>[],
          updates: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{'name': 'Alice Maria'},
              originalValues: <String, Object?>{'name': 'Alice'},
              changedFields: <String>{'name'},
            ),
          ],
          deletes: <FdcChangeSetEntry>[],
        ),
      );

      expect(result.success, isFalse);
      expect(result.errors.single.code, 'not_found');
      expect(adapter.rows, <Map<String, Object?>>[
        {'name': 'Alice'},
        {'name': 'Ethan'},
      ]);
    },
  );

  test(
    'memory adapter without keys does not delete by duplicate values',
    () async {
      final adapter = FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alice'},
          {'name': 'Alice'},
        ],
      );

      final result = await adapter.applyUpdates(
        const FdcChangeSet(
          inserts: <FdcChangeSetEntry>[],
          updates: <FdcChangeSetEntry>[],
          deletes: <FdcChangeSetEntry>[
            FdcChangeSetEntry(
              recordId: 99,
              values: <String, Object?>{'name': 'Alice'},
              originalValues: <String, Object?>{'name': 'Alice'},
              changedFields: <String>{},
            ),
          ],
        ),
      );

      expect(result.success, isFalse);
      expect(result.errors.single.code, 'not_found');
      expect(adapter.rows, <Map<String, Object?>>[
        {'name': 'Alice'},
        {'name': 'Alice'},
      ]);
    },
  );
}
