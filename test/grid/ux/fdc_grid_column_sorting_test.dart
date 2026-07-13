import 'fdc_grid_ux_test_support.dart';

void _registerColumnSortingTests() {
  group('Column sorting', () {
    testWidgets('column header menu can build a multi-column sort chain', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'group'),
          FdcStringField(size: 255, name: 'name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'group': 'B', 'name': 'Alpha'},
            {'group': 'A', 'name': 'Beta'},
            {'group': 'A', 'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'group', label: 'Group'),
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
        ],
      );

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Sorting'));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Sort ascending'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.sort.items, hasLength(1));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(find.text('1'), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Sorting'));
      await uxPumpPendingFrames(tester);

      expect(find.text('Add ascending sort'), findsOneWidget);
      expect(find.text('Add descending sort'), findsOneWidget);
      expect(find.text('Sort ascending'), findsNothing);
      expect(find.text('Sort descending'), findsNothing);
      expect(find.text('Clear all sorts'), findsNothing);

      await tester.tap(find.text('Add descending sort'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.sort.items, hasLength(2));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(dataSet.sort.items[1].fieldName, 'name');
      expect(dataSet.sort.items[1].sortType, FdcSortType.descending);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'group'), 'A');
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Beta');

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Sorting'));
      await uxPumpPendingFrames(tester);

      expect(find.text('Clear sort'), findsOneWidget);
      expect(find.text('Clear all sorts'), findsOneWidget);

      await tester.tap(find.text('Clear all sorts'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.sort.items, isEmpty);
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
    });

    testWidgets('plain click on unsorted header replaces existing sort', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'group'),
          FdcStringField(size: 255, name: 'name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'group': 'B', 'name': 'Alpha'},
            {'group': 'A', 'name': 'Beta'},
            {'group': 'A', 'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'group', label: 'Group'),
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
        ],
      );

      await tester.tap(find.text('Group'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.sort.items, hasLength(1));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);

      await tester.tap(find.text('Name'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.sort.items, hasLength(1));
      expect(dataSet.sort.items[0].fieldName, 'name');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
    });

    testWidgets('Ctrl click header cycles ascending descending and none', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'group'),
          FdcStringField(size: 255, name: 'name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'group': 'B', 'name': 'Alpha'},
            {'group': 'A', 'name': 'Beta'},
            {'group': 'A', 'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'group', label: 'Group'),
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
        ],
      );

      await tester.tap(find.text('Group'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.sort.items, hasLength(1));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(find.text('1'), findsNothing);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('Name'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(dataSet.sort.items, hasLength(2));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(dataSet.sort.items[1].fieldName, 'name');
      expect(dataSet.sort.items[1].sortType, FdcSortType.ascending);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('Name'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(dataSet.sort.items, hasLength(2));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(dataSet.sort.items[1].fieldName, 'name');
      expect(dataSet.sort.items[1].sortType, FdcSortType.descending);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('Name'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(dataSet.sort.items, hasLength(1));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
    });
  });
}

void main() {
  group('FdcGrid widget UX / Column Sorting', () {
    _registerColumnSortingTests();
  });
}
