import 'fdc_grid_ux_test_support.dart';

void _registerToolbarSearchQueryTests() {
  group('Toolbar search query behavior', () {
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
      await tester.enterText(searchField, 'alpha');
      await uxPumpPendingFrames(tester);

      final clearButton = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_clear_button'),
      );
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await uxPumpPendingFrames(tester);

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
      await uxPumpGrid(
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
      await uxPumpPendingFrames(tester);

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
      await uxPumpPendingFrames(tester);

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

      await uxPumpGrid(
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
      await uxPumpPendingFrames(tester);

      final searchField = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_field'),
      );
      await tester.enterText(searchField, 'alpha');
      await uxPumpPendingFrames(tester);

      expect(find.text('Alpha team'), findsOneWidget);
      expect(find.text('alpha team'), findsOneWidget);
      expect(find.text('Beta team'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_case_button')),
      );
      await uxPumpPendingFrames(tester);

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

      await uxPumpGrid(
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
      await uxPumpPendingFrames(tester);

      final searchField = find.byKey(
        const ValueKey('fdc_grid_toolbar_search_field'),
      );
      await tester.enterText(searchField, 'alpha beta');
      await uxPumpPendingFrames(tester);

      expect(find.text('Alpha only'), findsOneWidget);
      expect(find.text('Beta only'), findsOneWidget);
      expect(find.text('Alpha Beta'), findsOneWidget);
      expect(find.text('Gamma only'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_options_button')),
      );
      await uxPumpPendingFrames(tester);
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
      await uxPumpPendingFrames(tester);

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

        await tester.tap(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_options_button')),
        );
        await uxPumpPendingFrames(tester);

        expect(searchField, findsOneWidget);
        expect(find.text('Any word'), findsOneWidget);
        expect(find.text('All words'), findsOneWidget);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer();
        await mouse.moveTo(tester.getCenter(find.text('All words')));
        await uxPumpPendingFrames(tester);

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
        await tester.enterText(searchField, 'alpha');
        await uxPumpPendingFrames(tester);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await uxPumpPendingFrames(tester);

        expect(searchField, findsOneWidget);
        expect(find.text('alpha'), findsNothing);

        final editableText = tester.widget<EditableText>(
          find.descendant(of: searchField, matching: find.byType(EditableText)),
        );
        expect(editableText.focusNode.hasFocus, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await uxPumpPendingFrames(tester);

        expect(searchField, findsNothing);
        expect(
          find.byKey(const ValueKey('fdc_grid_toolbar_search_button')),
          findsOneWidget,
        );
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Toolbar Search Query', () {
    _registerToolbarSearchQueryTests();
  });
}
