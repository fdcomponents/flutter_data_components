import 'fdc_grid_ux_test_support.dart';

void _registerHeaderFilterEditorTests() {
  group('Header filter editors', () {
    testWidgets('header filter remains editable when filter returns no rows', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcStringField(size: 255, name: 'status'),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'status': 'active'},
            {'name': 'Beta', 'status': 'blocked'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        header: uxZeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).at(1), 'missing');
      await uxPumpPendingFrames(tester);

      expect(dataSet.filter.active, isTrue);
      expect(dataSet.recordCount, 0);

      var filterTextField = tester.widget<TextField>(
        find.byType(TextField).at(1),
      );
      expect(filterTextField.enabled, isTrue);

      await tester.enterText(find.byType(EditableText).at(1), 'active');
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 1);
      expect(find.text('Alpha'), findsOneWidget);
      filterTextField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(filterTextField.enabled, isTrue);
    });

    testWidgets('text header filter menu hides programming null operators', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha'},
            {'name': ''},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        header: uxZeroDebounceHeader,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await uxPumpPendingFrames(tester);

      expect(find.text('Contains'), findsWidgets);
      expect(find.text('Does not contain'), findsOneWidget);
      expect(find.text('Equals'), findsOneWidget);
      expect(find.text('Not equal'), findsOneWidget);
      expect(find.text('Starts with'), findsOneWidget);
      expect(find.text('Ends with'), findsOneWidget);
      expect(find.text('Is empty'), findsOneWidget);
      expect(find.text('Is not empty'), findsOneWidget);
      expect(find.text('Is null'), findsNothing);
      expect(find.text('Is not null'), findsNothing);
      expect(find.text('Is null or whitespace'), findsNothing);
      expect(find.text('Is not null or whitespace'), findsNothing);
    });

    testWidgets(
      'no-input header filter operator renders as disabled inline value',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcIntegerField(name: 'qty')],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'qty': 1},
              {'qty': null},
            ],
          ),
        );
        dataSet.open();
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'qty'),
          ],
          header: uxZeroDebounceHeader,
          toolbarVisible: false,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Is null'));
        await uxPumpPendingFrames(tester);

        final filterTextField = tester.widget<TextField>(
          find.byType(TextField),
        );
        final filterEditableText = tester.widget<EditableText>(
          find.byType(EditableText),
        );

        expect(filterTextField.enabled, isFalse);
        expect(filterEditableText.controller.text, 'Is null');
        expect(find.widgetWithText(Text, 'Is null'), findsNothing);
        expect(
          dataSet.filter.fieldItems.single.operator,
          FdcFilterOperator.isNull,
        );
        expect(find.text('1'), findsNothing);
      },
    );

    testWidgets(
      'boolean header filter shows All until selected and disables manual input',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcBooleanField(name: 'active')],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'active': true},
              {'active': false},
            ],
          ),
        );
        dataSet.open();
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcBooleanColumn<dynamic>(fieldName: 'active'),
          ],
          header: uxZeroDebounceHeader,
          toolbarVisible: false,
        );

        var filterTextField = tester.widget<TextField>(find.byType(TextField));
        var filterEditableText = tester.widget<EditableText>(
          find.byType(EditableText),
        );

        expect(filterTextField.enabled, isFalse);
        expect(filterEditableText.controller.text, 'All');
        expect(find.widgetWithText(Text, 'Is true'), findsNothing);

        await tester.tap(find.byIcon(Icons.more_vert));
        await uxPumpPendingFrames(tester);

        expect(find.byIcon(Icons.check), findsNothing);

        await tester.tap(find.text('Is false'));
        await uxPumpPendingFrames(tester);

        filterTextField = tester.widget<TextField>(find.byType(TextField));
        filterEditableText = tester.widget<EditableText>(
          find.byType(EditableText),
        );

        expect(filterTextField.enabled, isFalse);
        expect(filterEditableText.controller.text, 'Is false');
        expect(
          dataSet.filter.fieldItems.single.operator,
          FdcFilterOperator.isFalse,
        );
        expect(find.text('true'), findsNothing);
      },
    );

    testWidgets(
      'header filter overflow tooltip is disabled while editor has focus',
      (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        const tooltipText = '123456789012345678901234567890';

        Finder tooltipFinder() {
          return find.byWidgetPredicate(
            (widget) => widget is Tooltip && widget.message == tooltipText,
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 24,
                height: 32,
                child: FdcGridHeaderFilterShell(
                  label: '',
                  focusNode: focusNode,
                  style: FdcGridHeaderFilterStyle.defaults,
                  overflowTooltipText: tooltipText,
                  overflowTooltipTextStyle: const TextStyle(fontSize: 18),
                  overflowTooltipReservedWidth: 24,
                  child: Focus(
                    focusNode: focusNode,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );

        focusNode.requestFocus();
        await tester.pump();

        expect(tooltipFinder(), findsNothing);
        expect(find.byType(FdcGridHeaderFilterShell), findsOneWidget);
      },
    );

    testWidgets('narrow boolean header filter all value exposes tooltip', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcBooleanField(name: 'active')],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'active': true},
            {'active': false},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcBooleanColumn<dynamic>(fieldName: 'active', width: 14),
        ],
        header: uxZeroDebounceHeader,
        toolbarVisible: false,
        width: 80,
      );

      final tooltipFinder = find.byTooltip('All');
      expect(tooltipFinder, findsOneWidget);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(tooltipFinder));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('All'), findsOneWidget);
      await gesture.removePointer();
    });

    testWidgets(
      'column menu filter actions is disabled during active edit state',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha'},
              {'name': 'Beta'},
            ],
          ),
        );
        dataSet.open();
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          header: uxZeroDebounceHeader,
          toolbarVisible: false,
        );

        dataSet.edit();
        await uxPumpPendingFrames(tester);

        await tester.tap(find.byIcon(Icons.more_vert));
        await uxPumpPendingFrames(tester);

        expect(
          find.descendant(
            of: find.byType(MenuItemButton),
            matching: find.text('Contains'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'header filter inline clear button clears current column filter',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcStringField(size: 255, name: 'status'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha', 'status': 'active'},
              {'name': 'Beta', 'status': 'blocked'},
            ],
          ),
        );
        dataSet.open();
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
            FdcTextColumn<dynamic>(fieldName: 'status'),
          ],
          header: uxZeroDebounceHeader,
        );

        await tester.enterText(find.byType(EditableText).at(1), 'active');
        await uxPumpPendingFrames(tester);

        expect(dataSet.filter.fieldItems, hasLength(1));
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsNothing);
        expect(find.byIcon(Icons.close), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await uxPumpPendingFrames(tester);

        expect(dataSet.filter.fieldItems, isEmpty);
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsOneWidget);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).at(1))
              .controller
              .text,
          '',
        );
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Header Filter Editor', () {
    _registerHeaderFilterEditorTests();
  });
}
