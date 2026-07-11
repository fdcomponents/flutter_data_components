import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcDataSet public row selection API', () {
    test('selects, toggles, clears, and counts view rows', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'Name': 'Alpha', 'Status': 'open'},
            {'Name': 'Bravo', 'Status': 'closed'},
            {'Name': 'Charlie', 'Status': 'open'},
          ],
        ),
      );
      await dataSet.open();

      expect(dataSet.selection.count, 0);
      expect(dataSet.selection.isSelectedAt(1), isFalse);

      dataSet.selection.setSelectedAt(1, true);

      expect(dataSet.selection.isSelectedAt(1), isTrue);
      expect(dataSet.selection.count, 1);
      expect(dataSet.selection.rows(), <Map<String, Object?>>[
        {'Name': 'Bravo', 'Status': 'closed'},
      ]);

      expect(dataSet.selection.toggleAt(1), isFalse);
      expect(dataSet.selection.count, 0);

      dataSet.selection.selectAll();
      expect(dataSet.selection.count, 3);

      dataSet.selection.unselectAll();
      expect(dataSet.selection.count, 0);

      dataSet.selection.selectAll();
      dataSet.selection.unselectAll();
      expect(dataSet.selection.count, 0);
    });

    test('current-row helpers use the dataset cursor', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'Name': 'Alpha', 'Status': 'open'},
            {'Name': 'Bravo', 'Status': 'closed'},
          ],
        ),
      );
      await dataSet.open();

      dataSet.last();
      dataSet.selection.selectCurrent();

      expect(dataSet.selection.isSelectedAt(1), isTrue);
      expect(dataSet.selection.rows(), <Map<String, Object?>>[
        {'Name': 'Bravo', 'Status': 'closed'},
      ]);

      expect(dataSet.selection.toggleCurrent(), isFalse);
      expect(dataSet.selection.isSelectedAt(1), isFalse);

      dataSet.selection.toggleCurrent();
      dataSet.selection.unselectCurrent();
      expect(dataSet.selection.isSelectedAt(1), isFalse);
    });

    test('selection survives filter and sort view rebuilds', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'Name': 'Alpha', 'Status': 'open'},
            {'Name': 'Bravo', 'Status': 'closed'},
            {'Name': 'Charlie', 'Status': 'open'},
          ],
        ),
      );
      await dataSet.open();

      dataSet.selection.setSelectedAt(1, true);
      dataSet.selection.setSelectedAt(2, true);

      await dataSet.filter.where('status').equals('open').apply();

      expect(dataSet.selection.count, 1);
      expect(dataSet.selection.rows(), <Map<String, Object?>>[
        {'Name': 'Charlie', 'Status': 'open'},
      ]);
      await dataSet.sort.sortBy('name').descending.apply();

      expect(dataSet.selection.count, 1);
      expect(dataSet.selection.rows(), <Map<String, Object?>>[
        {'Name': 'Charlie', 'Status': 'open'},
      ]);
    });

    test(
      'filter selected true rebuilds current view from selected rows only',
      () async {
        final dataSet = _createDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'Name': 'Alpha', 'Status': 'open'},
              {'Name': 'Bravo', 'Status': 'closed'},
              {'Name': 'Charlie', 'Status': 'open'},
            ],
          ),
        );
        await dataSet.open();

        dataSet.selection.setSelectedAt(0, true);
        dataSet.selection.setSelectedAt(2, true);

        await dataSet.filter.selected(true).apply();

        expect(dataSet.filter.active, isTrue);
        expect(dataSet.filter.active, isTrue);
        expect(dataSet.recordCount, 2);
        expect(dataSet.selection.count, 2);
        expect(dataSet.selection.rows(), <Map<String, Object?>>[
          {'Name': 'Alpha', 'Status': 'open'},
          {'Name': 'Charlie', 'Status': 'open'},
        ]);
      },
    );

    test(
      'filter selected false rebuilds current view from unselected rows only',
      () async {
        final dataSet = _createDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'Name': 'Alpha', 'Status': 'open'},
              {'Name': 'Bravo', 'Status': 'closed'},
              {'Name': 'Charlie', 'Status': 'open'},
            ],
          ),
        );
        await dataSet.open();

        dataSet.selection.setSelectedAt(1, true);

        await dataSet.filter.selected(false).apply();

        expect(dataSet.filter.active, isTrue);
        expect(dataSet.filter.active, isTrue);
        expect(dataSet.recordCount, 2);
        expect(dataSet.selection.count, 0);
        dataSet.first();
        expect(dataSet.fieldValue('name'), 'Alpha');
        dataSet.next();
        expect(dataSet.fieldValue('name'), 'Charlie');
      },
    );

    test(
      'filter selected can combine with field filters and orderBy',
      () async {
        final dataSet = _createDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'Name': 'Alpha', 'Status': 'open'},
              {'Name': 'Bravo', 'Status': 'closed'},
              {'Name': 'Charlie', 'Status': 'open'},
              {'Name': 'Delta', 'Status': 'open'},
            ],
          ),
        );
        await dataSet.open();

        dataSet.selection.setSelectedAt(0, true);
        dataSet.selection.setSelectedAt(2, true);
        dataSet.selection.setSelectedAt(3, true);

        await dataSet.filter
            .where('status')
            .equals('open')
            .selected(true)
            .orderBy('name')
            .descending
            .apply();

        expect(dataSet.recordCount, 3);
        dataSet.first();
        expect(dataSet.fieldValue('name'), 'Delta');
        dataSet.next();
        expect(dataSet.fieldValue('name'), 'Charlie');
        dataSet.next();
        expect(dataSet.fieldValue('name'), 'Alpha');
      },
    );

    test(
      'reapplying selected filter rebuilds when selection state changed',
      () async {
        final dataSet = _createDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'Name': 'Alpha', 'Status': 'open'},
              {'Name': 'Bravo', 'Status': 'closed'},
              {'Name': 'Charlie', 'Status': 'open'},
            ],
          ),
        );
        await dataSet.open();

        dataSet.selection.setSelectedAt(0, true);
        dataSet.selection.setSelectedAt(2, true);
        await dataSet.filter.selected(true).apply();

        expect(dataSet.recordCount, 2);
        expect(dataSet.fieldValue('name'), 'Alpha');

        dataSet.selection.setSelectedAt(0, false);
        await dataSet.filter.selected(true).apply();

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'Charlie');
      },
    );

    test(
      'reapplying selected filter asynchronously rebuilds when selection state changed',
      () async {
        final dataSet = _createDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'Name': 'Alpha', 'Status': 'open'},
              {'Name': 'Bravo', 'Status': 'closed'},
              {'Name': 'Charlie', 'Status': 'open'},
            ],
          ),
        );
        await dataSet.open();

        dataSet.selection.setSelectedAt(0, true);
        dataSet.selection.setSelectedAt(2, true);
        await dataSet.filter.selected(true).apply();

        expect(dataSet.recordCount, 2);
        expect(dataSet.fieldValue('name'), 'Alpha');

        dataSet.selection.setSelectedAt(0, false);
        await dataSet.filter.selected(true).apply();

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'Charlie');
      },
    );

    test('filter selected must be declared before orderBy', () async {
      final dataSet = _createDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'Name': 'Alpha', 'Status': 'open'},
          ],
        ),
      );
      await dataSet.open();

      expect(
        () => dataSet.filter.orderBy('name').ascending.selected(true),
        throwsStateError,
      );
    });

    test(
      'selection changes notify listeners only when state changes',
      () async {
        final dataSet = _createDataSet(
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'Name': 'Alpha', 'Status': 'open'},
            ],
          ),
        );
        await dataSet.open();

        var notifications = 0;
        dataSet.addListener(() {
          notifications++;
        });

        dataSet.selection.setSelectedAt(0, true);
        dataSet.selection.setSelectedAt(0, true);
        dataSet.selection.unselectAll();
        dataSet.selection.unselectAll();

        expect(notifications, 2);
      },
    );
  });
}

FdcDataSet _createDataSet({IFdcDataAdapter? adapter}) {
  return FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(name: 'Name', size: 50),
      FdcStringField(name: 'Status', size: 20),
    ],

    adapter:
        adapter ?? FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );
}
