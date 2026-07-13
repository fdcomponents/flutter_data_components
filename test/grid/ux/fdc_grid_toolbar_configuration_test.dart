import 'fdc_grid_ux_test_support.dart';

void _registerToolbarConfigurationTests() {
  group('Toolbar configuration', () {
    testWidgets('Grid toolbar is shown by default and can be hidden', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', label: 'ID'),
          FdcStringField(size: 255, name: 'name', label: 'Name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      final toolbarFinder = find.byKey(const ValueKey('fdc_grid_toolbar'));
      expect(toolbarFinder, findsOneWidget);
      expect(tester.getSize(toolbarFinder).height, 44);

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        toolbar: const FdcGridToolbar(visible: false),
      );

      expect(toolbarFinder, findsNothing);
    });

    testWidgets('Grid toolbar empty items hides default search', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', label: 'ID'),
          FdcStringField(size: 255, name: 'name', label: 'Name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        toolbar: const FdcGridToolbar(items: <FdcGridItem>[]),
      );

      expect(find.byKey(const ValueKey('fdc_grid_toolbar')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        findsNothing,
      );
    });

    testWidgets('Grid toolbar style controls shell height', (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', label: 'ID'),
          FdcStringField(size: 255, name: 'name', label: 'Name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        toolbar: const FdcGridToolbar(style: FdcGridToolbarStyle(height: 48)),
      );

      final toolbarFinder = find.byKey(const ValueKey('fdc_grid_toolbar'));
      expect(toolbarFinder, findsOneWidget);
      expect(tester.getSize(toolbarFinder).height, 48);
    });

    testWidgets('Grid toolbar main menu hides header main menu', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', label: 'ID'),
          FdcStringField(size: 255, name: 'name', label: 'Name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        header: uxZeroDebounceHeader,
        toolbar: const FdcGridToolbar(
          items: <FdcGridItem>[FdcGridMainMenuButton()],
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_main_menu_button')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('fdc_grid_toolbar')),
          matching: find.byIcon(Icons.menu),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(FdcGridRowIndicatorHeader),
          matching: find.byIcon(Icons.menu),
        ),
        findsNothing,
      );
    });

    testWidgets('Grid toolbar renders start and end custom buttons', (
      tester,
    ) async {
      var startPressed = 0;
      var endPressed = 0;
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', label: 'ID'),
          FdcStringField(size: 255, name: 'name', label: 'Name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        toolbar: FdcGridToolbar(
          items: <FdcGridItem>[
            FdcGridButton(
              id: 'start',
              placement: FdcGridItemPlacement.start,
              icon: Icons.add,
              tooltip: 'Start',
              onPressed: () => startPressed++,
            ),
            FdcGridButton(
              id: 'end',
              icon: Icons.refresh,
              tooltip: 'End',
              onPressed: () => endPressed++,
            ),
          ],
        ),
      );

      expect(
        find.byKey(const ValueKey('fdc-grid-button-start')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('fdc-grid-button-end')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('fdc-grid-button-start')));
      await tester.tap(find.byKey(const ValueKey('fdc-grid-button-end')));

      expect(startPressed, 1);
      expect(endPressed, 1);
    });

    testWidgets('Grid toolbar custom items render when built-ins are hidden', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', label: 'ID'),
          FdcStringField(size: 255, name: 'name', label: 'Name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        toolbar: const FdcGridToolbar(
          items: <FdcGridItem>[
            FdcGridCustomItem(
              id: 'custom',
              placement: FdcGridItemPlacement.center,
              builder: uxBuildToolbarTestItem,
            ),
          ],
        ),
      );

      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('fdc-toolbar-test-item')),
        findsOneWidget,
      );
    });
  });
}

void main() {
  group('FdcGrid widget UX / Toolbar Configuration', () {
    _registerToolbarConfigurationTests();
  });
}
