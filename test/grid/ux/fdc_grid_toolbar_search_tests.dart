part of '../fdc_grid_widget_ux_test.dart';

void _registerToolbarSearchTests() {
  group('Toolbar and search', () {
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

      await _pumpGrid(
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

      await _pumpGrid(
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

      await _pumpGrid(
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

      await _pumpGrid(
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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        header: _zeroDebounceHeader,
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

      await _pumpGrid(
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

      await _pumpGrid(
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
              builder: _buildToolbarTestItem,
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

    testWidgets(
      'Grid toolbar search button expands and autofocuses search field',
      (tester) async {
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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        expect(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
          findsNothing,
        );

        await tester.tap(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        );
        await tester.pumpAndSettle();

        final searchField = find.byKey(
          const ValueKey('fdc_grid_toolbar_search_field'),
        );
        expect(searchField, findsOneWidget);

        final editableText = tester.widget<EditableText>(
          find.descendant(of: searchField, matching: find.byType(EditableText)),
        );
        expect(editableText.focusNode.hasFocus, isTrue);
      },
    );

    testWidgets('Home and End in toolbar search keep text input focus', (
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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
      );
      await tester.pumpAndSettle();

      final searchField = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_field'),
      );
      final editableFinder = find.descendant(
        of: searchField,
        matching: find.byType(EditableText),
      );

      await tester.enterText(editableFinder, 'Alpha');
      await tester.pumpAndSettle();

      EditableText editable = tester.widget<EditableText>(editableFinder);
      expect(editable.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();

      editable = tester.widget<EditableText>(editableFinder);
      expect(editable.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();

      editable = tester.widget<EditableText>(editableFinder);
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('Ctrl+F expands and focuses grid toolbar search', (
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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
        findsNothing,
      );

      await tester.tap(find.text('Alpha'));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      final searchField = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_field'),
      );
      expect(searchField, findsOneWidget);

      final editableText = tester.widget<EditableText>(
        find.descendant(of: searchField, matching: find.byType(EditableText)),
      );
      expect(editableText.focusNode.hasFocus, isTrue);
    });

    testWidgets(
      'Ctrl+F restores grid focus after Escape closes toolbar search',
      (tester) async {
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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await tester.pump();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
          findsOneWidget,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
          findsNothing,
        );

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Grid toolbar search button is disabled for empty grids', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', label: 'ID'),
          FdcStringField(size: 255, name: 'name', label: 'Name'),
        ],

        adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      final searchButton = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_button'),
      );
      expect(searchButton, findsOneWidget);
      expect(tester.widget<IconButton>(searchButton).onPressed, isNull);

      await tester.tap(searchButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
        findsNothing,
      );
    });

    testWidgets(
      'Grid toolbar search collapses empty field during active edit',
      (tester) async {
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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        );
        await tester.pumpAndSettle();

        final searchField = find.byKey(
          const ValueKey('fdc_grid_toolbar_search_field'),
        );
        expect(searchField, findsOneWidget);
        expect(tester.widget<TextField>(searchField).enabled, isTrue);

        dataSet.edit();
        await tester.pumpAndSettle();

        final searchButton = tester.widget<IconButton>(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        );
        expect(searchButton.onPressed, isNull);
        expect(searchField, findsNothing);
      },
    );

    testWidgets(
      'Grid toolbar disabled debounce keeps focus after Enter submit',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id', label: 'ID'),
            FdcStringField(size: 255, name: 'name', label: 'Name'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'id': 1, 'name': 'Alpha'},
              {'id': 2, 'name': 'Beta'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          toolbar: const FdcGridToolbar(
            items: <FdcGridItem>[
              FdcGridSearchBar(debouncePolicy: FdcDebouncePolicy.disabled),
            ],
          ),
        );

        await tester.tap(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        );
        await tester.pumpAndSettle();

        final searchField = find.byKey(
          const ValueKey('fdc_grid_toolbar_search_field'),
        );
        await tester.enterText(searchField, 'alp');
        await tester.pumpAndSettle();

        expect(find.text('Beta'), findsOneWidget);

        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsNothing);

        final editableText = tester.widget<EditableText>(
          find.descendant(of: searchField, matching: find.byType(EditableText)),
        );
        expect(editableText.focusNode.hasFocus, isTrue);
      },
    );

    testWidgets('Grid toolbar search clear button clears search text', (
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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
      );
      await tester.pumpAndSettle();

      final searchField = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_field'),
      );
      await tester.enterText(searchField, 'alpha');
      await tester.pumpAndSettle();

      final clearButton = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_clear_button'),
      );
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(searchField, findsOneWidget);
      expect(find.text('alpha'), findsNothing);
      expect(clearButton, findsNothing);
    });

    testWidgets('Grid toolbar simple search hides case and mode controls', (
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
            {'id': 2, 'name': 'Beta'},
          ],
        ),
      );
      dataSet.open();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        toolbar: const FdcGridToolbar(
          items: <FdcGridItem>[
            FdcGridSearchBar(
              mode: FdcGridSearchBarMode.simple,
              debounceDuration: Duration.zero,
            ),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_case_button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_options_button')),
        findsNothing,
      );

      final searchField = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_field'),
      );
      await tester.enterText(searchField, 'alpha');
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);
      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_clear_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_case_button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_options_button')),
        findsNothing,
      );
    });

    testWidgets('Grid toolbar search case button toggles case sensitivity', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', label: 'ID'),
          FdcStringField(size: 255, name: 'name', label: 'Name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha team'},
            {'id': 2, 'name': 'alpha team'},
            {'id': 3, 'name': 'Beta team'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        toolbar: const FdcGridToolbar(
          items: <FdcGridItem>[
            FdcGridSearchBar(debounceDuration: Duration.zero),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
      );
      await tester.pumpAndSettle();

      final searchField = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_field'),
      );
      await tester.enterText(searchField, 'alpha');
      await tester.pumpAndSettle();

      expect(find.text('Alpha team'), findsOneWidget);
      expect(find.text('alpha team'), findsOneWidget);
      expect(find.text('Beta team'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_case_button')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha team'), findsNothing);
      expect(find.text('alpha team'), findsOneWidget);
      expect(find.text('Beta team'), findsNothing);
    });

    testWidgets('Grid toolbar search options menu changes match mode', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', label: 'ID'),
          FdcStringField(size: 255, name: 'name', label: 'Name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha only'},
            {'id': 2, 'name': 'Beta only'},
            {'id': 3, 'name': 'Alpha Beta'},
            {'id': 4, 'name': 'Gamma only'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        toolbar: const FdcGridToolbar(
          items: <FdcGridItem>[
            FdcGridSearchBar(debounceDuration: Duration.zero),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
      );
      await tester.pumpAndSettle();

      final searchField = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_field'),
      );
      await tester.enterText(searchField, 'alpha beta');
      await tester.pumpAndSettle();

      expect(find.text('Alpha only'), findsOneWidget);
      expect(find.text('Beta only'), findsOneWidget);
      expect(find.text('Alpha Beta'), findsOneWidget);
      expect(find.text('Gamma only'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_options_button')),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('All words'));
      await tester.pump();
      final textFieldDuringClose = tester.widget<TextField>(searchField);
      final enabledBorderDuringClose =
          textFieldDuringClose.decoration!.enabledBorder! as OutlineInputBorder;
      final focusedBorderDuringClose =
          textFieldDuringClose.decoration!.focusedBorder! as OutlineInputBorder;
      expect(
        enabledBorderDuringClose.borderSide,
        focusedBorderDuringClose.borderSide,
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha only'), findsNothing);
      expect(find.text('Beta only'), findsNothing);
      expect(find.text('Alpha Beta'), findsOneWidget);
      expect(find.text('Gamma only'), findsNothing);
    });

    testWidgets(
      'Grid toolbar search options menu stays open while empty search loses focus',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id', label: 'ID'),
            FdcStringField(size: 255, name: 'name', label: 'Name'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'id': 1, 'name': 'Alpha'},
              {'id': 2, 'name': 'Beta'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        );
        await tester.pumpAndSettle();

        final searchField = find.byKey(
          const ValueKey('fdc_grid_toolbar_search_field'),
        );
        expect(searchField, findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_options_button')),
        );
        await tester.pumpAndSettle();

        expect(searchField, findsOneWidget);
        expect(find.text('Any word'), findsOneWidget);
        expect(find.text('All words'), findsOneWidget);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer();
        await mouse.moveTo(tester.getCenter(find.text('All words')));
        await tester.pumpAndSettle();

        expect(searchField, findsOneWidget);
        expect(find.text('Any word'), findsOneWidget);
        expect(find.text('All words'), findsOneWidget);

        final textField = tester.widget<TextField>(searchField);
        final enabledBorder =
            textField.decoration!.enabledBorder! as OutlineInputBorder;
        final focusedBorder =
            textField.decoration!.focusedBorder! as OutlineInputBorder;
        expect(enabledBorder.borderSide, focusedBorder.borderSide);

        await mouse.removePointer();
      },
    );

    testWidgets(
      'Grid toolbar search Escape clears text then collapses empty search',
      (tester) async {
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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        );
        await tester.pumpAndSettle();

        final searchField = find.byKey(
          const ValueKey('fdc_grid_toolbar_search_field'),
        );
        await tester.enterText(searchField, 'alpha');
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(searchField, findsOneWidget);
        expect(find.text('alpha'), findsNothing);

        final editableText = tester.widget<EditableText>(
          find.descendant(of: searchField, matching: find.byType(EditableText)),
        );
        expect(editableText.focusNode.hasFocus, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(searchField, findsNothing);
        expect(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Grid toolbar search icon collapses empty expanded search', (
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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_icon_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        findsOneWidget,
      );
    });

    testWidgets(
      'Grid toolbar search keeps field mounted while collapsing from grid tap',
      (tester) async {
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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        );
        await tester.pumpAndSettle();

        final searchField = find.byKey(
          const ValueKey('fdc_grid_toolbar_search_field'),
        );
        expect(searchField, findsOneWidget);

        await tester.tap(find.text('Alpha'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        expect(searchField, findsOneWidget);
        final collapsingTextField = tester.widget<TextField>(searchField);
        final enabledBorderDuringCollapse =
            collapsingTextField.decoration!.enabledBorder!
                as OutlineInputBorder;
        final focusedBorderDuringCollapse =
            collapsingTextField.decoration!.focusedBorder!
                as OutlineInputBorder;
        expect(
          enabledBorderDuringCollapse.borderSide,
          focusedBorderDuringCollapse.borderSide,
        );

        await tester.pumpAndSettle();

        expect(searchField, findsNothing);
        expect(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Grid toolbar search fades trailing actions early during collapse',
      (tester) async {
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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        );
        await tester.pumpAndSettle();

        final searchField = find.byKey(
          const ValueKey('fdc_grid_toolbar_search_field'),
        );
        expect(searchField, findsOneWidget);

        await tester.tap(find.text('Alpha'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));

        expect(searchField, findsOneWidget);
        expect(
          find.byKey(
            const ValueKey('fdc_grid_toolbar_search_animated_outline'),
          ),
          findsOneWidget,
        );
        final trailingActions = tester.widget<Opacity>(
          find.byKey(
            const ValueKey('fdc_grid_toolbar_search_trailing_actions'),
          ),
        );
        expect(trailingActions.opacity, lessThan(0.2));

        await tester.pumpAndSettle();
        expect(searchField, findsNothing);
      },
    );

    testWidgets('Grid toolbar search collapses on blur only when empty', (
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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
      );
      await tester.pumpAndSettle();

      final searchField = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_field'),
      );
      await tester.enterText(searchField, 'alpha');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      expect(searchField, findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_clear_button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      expect(searchField, findsNothing);
      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
        findsOneWidget,
      );
    });

    testWidgets(
      'ArrowDown append keeps new row visible above summary and status bars after horizontal scroll',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id', label: 'ID'),
            FdcStringField(size: 255, name: 'name', label: 'Name'),
            FdcStringField(size: 255, name: 'city', label: 'City'),
            FdcStringField(size: 255, name: 'note', label: 'Note'),
          ],
          onNewRecord: (dataSet) {
            dataSet.setFieldValue('id', 99);
            dataSet.setFieldValue('name', 'New customer');
            dataSet.setFieldValue('city', 'Boston');
            dataSet.setFieldValue('note', 'Created from append');
          },

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              for (var i = 1; i <= 12; i++)
                {
                  'id': i,
                  'name': 'Customer $i',
                  'city': 'City $i',
                  'note': 'Note $i',
                },
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          width: 360,
          height: 240,
          statusBar: const FdcGridStatusBar(visible: true),
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(
              fieldName: 'id',
              readOnly: true,
              summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
            ),
            FdcTextColumn<dynamic>(fieldName: 'name'),
            FdcTextColumn<dynamic>(fieldName: 'city'),
            FdcTextColumn<dynamic>(fieldName: 'note'),
          ],
        );

        await tester.tap(find.text('Customer 1'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pumpAndSettle();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();

        expect(find.text('Customer 12'), findsWidgets);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        expect(dataSet.recordCount, 13);
        expect(dataSet.state, FdcDataSetState.insert);
        expect(FdcDataSetInternal.activeIndex(dataSet), 12);

        final appendedFinder = find.text('New customer');
        expect(appendedFinder, findsWidgets);
        final appendedBottom = tester.getBottomLeft(appendedFinder.first).dy;
        final summaryTop = tester
            .getTopLeft(find.byKey(const ValueKey('fdc_grid_summary_row')))
            .dy;
        expect(appendedBottom, lessThanOrEqualTo(summaryTop));
      },
    );
  });
}
