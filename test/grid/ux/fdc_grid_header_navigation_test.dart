import 'fdc_grid_ux_test_support.dart';

void _registerHeaderNavigationTests() {
  group('Header filter navigation', () {
    testWidgets(
      'ArrowUp on first row keeps grid focus when filters are hidden',
      (tester) async {
        const selectedColor = Colors.orange;
        final dataSet = uxPeopleDataSet();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          style: const FdcGridStyle(selectedCellBackgroundColor: selectedColor),
        );

        int selectedCellBackgroundCount() {
          return tester.widgetList<Container>(find.byType(Container)).where((
            container,
          ) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.color == selectedColor;
          }).length;
        }

        await tester.tap(find.text('Alpha').first);
        await uxPumpPendingFrames(tester);
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await uxPumpPendingFrames(tester);

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await uxPumpPendingFrames(tester);
        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      },
    );

    testWidgets(
      'ArrowUp on first row ignores non-focusable header filter cell',
      (tester) async {
        const selectedColor = Colors.orange;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcBooleanField(name: 'active'),
            FdcStringField(size: 255, name: 'name'),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'active': false, 'name': 'Alpha'},
              <String, Object?>{'id': 2, 'active': true, 'name': 'Beta'},
            ],
          ),
        );
        dataSet.open();

        await uxPumpFilterGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcBooleanColumn<dynamic>(fieldName: 'active', width: 100),
            FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
          ],
          style: const FdcGridStyle(selectedCellBackgroundColor: selectedColor),
        );

        int selectedCellBackgroundCount() {
          return tester.widgetList<Container>(find.byType(Container)).where((
            container,
          ) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.color == selectedColor;
          }).length;
        }

        await tester.tap(find.byType(Checkbox).first);
        await uxPumpPendingFrames(tester);
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await uxPumpPendingFrames(tester);

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await uxPumpPendingFrames(tester);
        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      },
    );

    testWidgets(
      'ArrowUp on first row ignores menu-only list header filter cell',
      (tester) async {
        const selectedColor = Colors.orange;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcStringField(size: 32, name: 'status'),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'status': 'New'},
              <String, Object?>{'id': 2, 'status': 'Closed'},
            ],
          ),
        );
        dataSet.open();

        await uxPumpFilterGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(
              fieldName: 'status',
              width: 140,
              filterConfig: FdcColumnFilterConfig(
                editor: FdcFilterEditor.list,
                values: <FdcOption<Object?>>[
                  FdcOption<Object?>(value: 'New', label: 'New'),
                  FdcOption<Object?>(value: 'Closed', label: 'Closed'),
                ],
              ),
            ),
          ],
          style: const FdcGridStyle(selectedCellBackgroundColor: selectedColor),
        );

        int selectedCellBackgroundCount() {
          return tester.widgetList<Container>(find.byType(Container)).where((
            container,
          ) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.color == selectedColor;
          }).length;
        }

        await tester.tap(find.text('New').last, warnIfMissed: false);
        await uxPumpPendingFrames(tester);
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await uxPumpPendingFrames(tester);

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await uxPumpPendingFrames(tester);
        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      },
    );

    testWidgets(
      'list header filter apply waits for draft changes and all applies immediately',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 32, name: 'status')],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              <String, Object?>{'status': 'New'},
              <String, Object?>{'status': 'Closed'},
            ],
          ),
        );
        dataSet.open();

        await uxPumpFilterGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(
              fieldName: 'status',
              width: 140,
              filterConfig: FdcColumnFilterConfig(
                editor: FdcFilterEditor.list,
                values: <FdcOption<Object?>>[
                  FdcOption<Object?>(value: 'New', label: 'New'),
                  FdcOption<Object?>(value: 'Closed', label: 'Closed'),
                ],
              ),
            ),
          ],
        );

        await tester.tap(find.text('All').first);
        await uxPumpPendingFrames(tester);

        var applyButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Apply'),
        );
        expect(applyButton.onPressed, isNull);

        await tester.tap(find.text('New').last, warnIfMissed: false);
        await uxPumpPendingFrames(tester);

        applyButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Apply'),
        );
        expect(applyButton.onPressed, isNotNull);

        await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
        await uxPumpPendingFrames(tester);

        expect(dataSet.filter.fieldItems, hasLength(1));
        expect(
          dataSet.filter.fieldItems.single.operator,
          FdcFilterOperator.inList,
        );
        expect(find.text('New'), findsOneWidget);
        expect(find.text('Closed'), findsNothing);

        await tester.tap(find.text('1 selected'));
        await uxPumpPendingFrames(tester);

        applyButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Apply'),
        );
        expect(applyButton.onPressed, isNull);

        await tester.tap(find.text('All').last, warnIfMissed: false);
        await uxPumpPendingFrames(tester);

        expect(dataSet.filter.fieldItems, isEmpty);
        expect(find.widgetWithText(FilledButton, 'Apply'), findsNothing);
        expect(find.text('New'), findsOneWidget);
        expect(find.text('Closed'), findsOneWidget);
      },
    );

    testWidgets('Tab in header filters skips non-focusable filter columns', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 32, name: 'name'),
          FdcStringField(size: 32, name: 'status'),
          FdcBooleanField(name: 'active'),
          FdcStringField(size: 32, name: 'note'),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{
              'id': 1,
              'name': 'Alpha',
              'status': 'New',
              'active': true,
              'note': 'First',
            },
          ],
        ),
      );
      dataSet.open();

      await uxPumpFilterGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name', width: 120),
          FdcTextColumn<dynamic>(
            fieldName: 'status',
            width: 120,
            filterConfig: FdcColumnFilterConfig(
              editor: FdcFilterEditor.list,
              values: <FdcOption<Object?>>[
                FdcOption<Object?>(value: 'New', label: 'New'),
                FdcOption<Object?>(value: 'Closed', label: 'Closed'),
              ],
            ),
          ),
          FdcBooleanColumn<dynamic>(fieldName: 'active', width: 100),
          FdcTextColumn<dynamic>(fieldName: 'note', width: 120),
        ],
      );

      List<EditableText> headerFilterInputs() => tester
          .widgetList<EditableText>(find.byType(EditableText))
          .where((editor) => editor.controller.text.isEmpty && !editor.readOnly)
          .toList(growable: false);

      final inputs = headerFilterInputs();
      expect(inputs, hasLength(2));

      await tester.tap(find.byType(EditableText).first);
      await uxPumpPendingFrames(tester);
      expect(headerFilterInputs().first.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await uxPumpPendingFrames(tester);

      final afterTab = headerFilterInputs();
      expect(afterTab.first.focusNode.hasFocus, isFalse);
      expect(afterTab.last.focusNode.hasFocus, isTrue);
    });

    testWidgets(
      'ArrowUp on first row is no-op while editing with filters visible',
      (tester) async {
        final dataSet = uxPeopleDataSet();

        await uxPumpFilterGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha').first);
        await uxPumpPendingFrames(tester);
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await uxPumpPendingFrames(tester);
        expect(dataSet.state, FdcDataSetState.edit);

        EditableText activeNameEditor() {
          return tester
              .widgetList<EditableText>(find.byType(EditableText))
              .firstWhere((editor) => editor.controller.text == 'Alpha');
        }

        expect(activeNameEditor().focusNode.hasFocus, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await uxPumpPendingFrames(tester);

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(dataSet.state, FdcDataSetState.edit);
        expect(activeNameEditor().focusNode.hasFocus, isTrue);
        expect(
          tester
              .widgetList<EditableText>(find.byType(EditableText))
              .where((editor) => editor.controller.text != 'Alpha')
              .any((editor) => editor.focusNode.hasFocus),
          isFalse,
        );
      },
    );

    testWidgets('external editor update preserves grid horizontal scroll', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'c1'),
          FdcStringField(size: 255, name: 'c2'),
          FdcStringField(size: 255, name: 'c3'),
          FdcStringField(size: 255, name: 'c4'),
          FdcStringField(size: 255, name: 'c5'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {
              'c1': 'one',
              'c2': 'two',
              'c3': 'three',
              'c4': 'four',
              'c5': 'five',
            },
          ],
        ),
      )..open();
      final externalEditorKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 260,
                  height: 180,
                  child: FdcGrid(
                    dataSet: dataSet,
                    header: const FdcGridHeader(height: 32),
                    columns: const <FdcGridColumn<dynamic>>[
                      FdcTextColumn<dynamic>(fieldName: 'c1'),
                      FdcTextColumn<dynamic>(fieldName: 'c2'),
                      FdcTextColumn<dynamic>(fieldName: 'c3'),
                      FdcTextColumn<dynamic>(fieldName: 'c4'),
                      FdcTextColumn<dynamic>(fieldName: 'c5'),
                    ],
                    options: const FdcGridOptions(
                      defaultColumnWidth: 150,
                      rowHeight: 36,
                    ),
                  ),
                ),
                FdcTextEdit(
                  key: externalEditorKey,
                  dataSet: dataSet,
                  fieldName: 'c1',
                  label: 'External c1',
                ),
              ],
            ),
          ),
        ),
      );
      await uxPumpPendingFrames(tester);

      final horizontalScrollView = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      );
      final scrollView = tester.widget<SingleChildScrollView>(
        horizontalScrollView.first,
      );
      final controller = scrollView.controller!;

      await tester.drag(horizontalScrollView.first, const Offset(-320, 0));
      await uxPumpPendingFrames(tester);
      final offsetBeforeExternalEdit = controller.offset;
      expect(offsetBeforeExternalEdit, greaterThan(0));

      await tester.tap(find.byKey(externalEditorKey));
      await uxPumpPendingFrames(tester);
      await tester.enterText(
        find.byType(TextFormField).last,
        'changed outside',
      );
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await uxPumpPendingFrames(tester);

      expect(dataSet['c1'], 'changed outside');
      expect(controller.offset, offsetBeforeExternalEdit);
    });
  });
}

void main() {
  group('FdcGrid widget UX / Header Navigation', () {
    _registerHeaderNavigationTests();
  });
}
