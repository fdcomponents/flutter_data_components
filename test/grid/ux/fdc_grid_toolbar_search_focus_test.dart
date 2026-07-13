import 'fdc_grid_ux_test_support.dart';

void _registerToolbarSearchFocusTests() {
  group('Toolbar search focus and keyboard', () {
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
        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);

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

      await uxPumpGrid(
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
      await uxPumpPendingFrames(tester);

      final searchField = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_field'),
      );
      final editableFinder = find.descendant(
        of: searchField,
        matching: find.byType(EditableText),
      );

      await tester.enterText(editableFinder, 'Alpha');
      await uxPumpPendingFrames(tester);

      EditableText editable = tester.widget<EditableText>(editableFinder);
      expect(editable.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await uxPumpPendingFrames(tester);

      editable = tester.widget<EditableText>(editableFinder);
      expect(editable.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await uxPumpPendingFrames(tester);

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

      await uxPumpGrid(
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
      await uxPumpPendingFrames(tester);

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
        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);

        expect(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
          findsOneWidget,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await uxPumpPendingFrames(tester);

        expect(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
          findsNothing,
        );

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await uxPumpPendingFrames(tester);

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

      await uxPumpGrid(
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
      await uxPumpPendingFrames(tester);

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
        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);

        final searchField = find.byKey(
          const ValueKey('fdc_grid_toolbar_search_field'),
        );
        expect(searchField, findsOneWidget);
        expect(tester.widget<TextField>(searchField).enabled, isTrue);

        dataSet.edit();
        await uxPumpPendingFrames(tester);

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
        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);

        final searchField = find.byKey(
          const ValueKey('fdc_grid_toolbar_search_field'),
        );
        await tester.enterText(searchField, 'alp');
        await uxPumpPendingFrames(tester);

        expect(find.text('Beta'), findsOneWidget);

        await tester.testTextInput.receiveAction(TextInputAction.search);
        await uxPumpPendingFrames(tester);

        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsNothing);

        final editableText = tester.widget<EditableText>(
          find.descendant(of: searchField, matching: find.byType(EditableText)),
        );
        expect(editableText.focusNode.hasFocus, isTrue);
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Toolbar Search Focus', () {
    _registerToolbarSearchFocusTests();
  });
}
