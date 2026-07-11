part of '../fdc_grid_widget_ux_test.dart';

void _registerKeyboardNavigationTests() {
  group('Keyboard navigation', () {
    testWidgets('ArrowRight uses pinned visual column order', (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'left'),
          FdcStringField(size: 255, name: 'center'),
          FdcStringField(size: 255, name: 'right'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'left': 'L1', 'center': 'C1', 'right': 'R1'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'center'),
          FdcTextColumn<dynamic>(
            fieldName: 'right',
            pin: FdcGridColumnPin.endFixed,
          ),
          FdcTextColumn<dynamic>(
            fieldName: 'left',
            pin: FdcGridColumnPin.startFixed,
          ),
        ],
      );

      await tester.tap(find.text('L1'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsOneWidget);
      final editor = tester.widget<EditableText>(find.byType(EditableText));
      expect(editor.controller.text, 'x');

      await tester.tap(find.text('R1'));
      await tester.pumpAndSettle();

      expect(dataSet.fieldValue('left'), 'L1');
      expect(dataSet.fieldValue('center'), 'x');
      expect(dataSet.fieldValue('right'), 'R1');
    });

    testWidgets('Enter uses pinned visual column order', (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'left'),
          FdcStringField(size: 255, name: 'center'),
          FdcStringField(size: 255, name: 'right'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'left': 'L1', 'center': 'C1', 'right': 'R1'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'center'),
          FdcTextColumn<dynamic>(
            fieldName: 'right',
            pin: FdcGridColumnPin.endFixed,
          ),
          FdcTextColumn<dynamic>(
            fieldName: 'left',
            pin: FdcGridColumnPin.startFixed,
          ),
        ],
      );

      await tester.tap(find.text('L1'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsOneWidget);
      final editor = tester.widget<EditableText>(find.byType(EditableText));
      expect(editor.controller.text, 'y');

      await tester.tap(find.text('R1'));
      await tester.pumpAndSettle();

      expect(dataSet.fieldValue('left'), 'L1');
      expect(dataSet.fieldValue('center'), 'y');
      expect(dataSet.fieldValue('right'), 'R1');
    });

    testWidgets('Tab fallback order uses pinned visual column order', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'left'),
          FdcStringField(size: 255, name: 'center'),
          FdcStringField(size: 255, name: 'right'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'left': 'L1', 'center': 'C1', 'right': 'R1'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'center'),
          FdcTextColumn<dynamic>(
            fieldName: 'right',
            pin: FdcGridColumnPin.endFixed,
          ),
          FdcTextColumn<dynamic>(
            fieldName: 'left',
            pin: FdcGridColumnPin.startFixed,
          ),
        ],
      );

      await tester.tap(find.text('L1'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsOneWidget);
      final editor = tester.widget<EditableText>(find.byType(EditableText));
      expect(editor.controller.text, 'z');

      await tester.tap(find.text('R1'));
      await tester.pumpAndSettle();

      expect(dataSet.fieldValue('left'), 'L1');
      expect(dataSet.fieldValue('center'), 'z');
      expect(dataSet.fieldValue('right'), 'R1');
    });
    testWidgets('Tab visits disabled columns without editing them', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'a'),
          FdcStringField(size: 255, name: 'b'),
          FdcStringField(size: 255, name: 'c'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'a': 'A1', 'b': 'B1', 'c': 'C1'},
          ],
        ),
      );
      dataSet.open();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'a', focusOrder: 1),
          FdcTextColumn<dynamic>(fieldName: 'b', focusOrder: 2, enabled: false),
          FdcTextColumn<dynamic>(fieldName: 'c', focusOrder: 3),
        ],
      );

      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsNothing);
      expect(dataSet.fieldValue('b'), 'B1');
      expect(dataSet.fieldValue('c'), 'C1');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsOneWidget);
      final editor = tester.widget<EditableText>(find.byType(EditableText));
      expect(editor.controller.text, 'z');

      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      expect(dataSet.fieldValue('b'), 'B1');
      expect(dataSet.fieldValue('c'), 'z');
    });

    testWidgets(
      'Keyboard navigation skips columns with showIndicator disabled',
      (tester) async {
        Future<FdcDataSet> pumpGrid() async {
          final dataSet = FdcDataSet(
            fields: const <FdcFieldDef>[
              FdcStringField(size: 255, name: 'a'),
              FdcStringField(size: 255, name: 'b'),
              FdcStringField(size: 255, name: 'c'),
            ],
            adapter: FdcMemoryDataAdapter(
              rows: const <Map<String, Object?>>[
                {'a': 'A1', 'b': 'B1', 'c': 'C1'},
              ],
            ),
          );
          dataSet.open();
          await _pumpGrid(
            tester,
            dataSet: dataSet,
            columns: const <FdcGridColumn<dynamic>>[
              FdcTextColumn<dynamic>(fieldName: 'a'),
              FdcTextColumn<dynamic>(fieldName: 'b', showIndicator: false),
              FdcTextColumn<dynamic>(fieldName: 'c'),
            ],
          );
          return dataSet;
        }

        var dataSet = await pumpGrid();
        await tester.tap(find.text('A1'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
        await tester.pumpAndSettle();

        expect(find.byType(EditableText), findsOneWidget);
        var editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'x');
        await tester.tap(find.text('A1'));
        await tester.pumpAndSettle();
        expect(dataSet.fieldValue('b'), 'B1');
        expect(dataSet.fieldValue('c'), 'x');

        dataSet = await pumpGrid();
        await tester.tap(find.text('A1'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
        await tester.pumpAndSettle();

        expect(find.byType(EditableText), findsOneWidget);
        editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'y');
        await tester.tap(find.text('A1'));
        await tester.pumpAndSettle();
        expect(dataSet.fieldValue('b'), 'B1');
        expect(dataSet.fieldValue('c'), 'y');

        dataSet = await pumpGrid();
        await tester.tap(find.text('A1'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.pumpAndSettle();

        expect(find.byType(EditableText), findsOneWidget);
        editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'z');
        await tester.tap(find.text('A1'));
        await tester.pumpAndSettle();
        expect(dataSet.fieldValue('b'), 'B1');
        expect(dataSet.fieldValue('c'), 'z');
      },
    );

    testWidgets('Tab skips columns with tabStop disabled', (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'a'),
          FdcStringField(size: 255, name: 'b'),
          FdcStringField(size: 255, name: 'c'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'a': 'A1', 'b': 'B1', 'c': 'C1'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'a', focusOrder: 1),
          FdcTextColumn<dynamic>(fieldName: 'b', focusOrder: 2, tabStop: false),
          FdcTextColumn<dynamic>(fieldName: 'c', focusOrder: 3),
        ],
      );

      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsOneWidget);
      final editor = tester.widget<EditableText>(find.byType(EditableText));
      expect(editor.controller.text, 'z');

      await tester.tap(find.text('A1'));
      await tester.pumpAndSettle();

      expect(dataSet.fieldValue('b'), 'B1');
      expect(dataSet.fieldValue('c'), 'z');
    });

    testWidgets(
      'Tab visits readOnly columns before continuing through tab order',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'a'),
            FdcStringField(size: 255, name: 'b'),
            FdcStringField(size: 255, name: 'c'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'a': 'A1', 'b': 'B1', 'c': 'C1'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'a', focusOrder: 1),
            FdcTextColumn<dynamic>(
              fieldName: 'b',
              focusOrder: 2,
              readOnly: true,
            ),
            FdcTextColumn<dynamic>(fieldName: 'c', focusOrder: 3),
          ],
        );

        await tester.tap(find.text('A1'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
        await tester.pumpAndSettle();

        expect(find.byType(EditableText), findsNothing);
        expect(dataSet.fieldValue('b'), 'B1');
        expect(dataSet.fieldValue('c'), 'C1');

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
        await tester.pumpAndSettle();

        expect(find.byType(EditableText), findsOneWidget);
        final editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'z');

        await tester.tap(find.text('A1'));
        await tester.pumpAndSettle();

        expect(dataSet.fieldValue('b'), 'B1');
        expect(dataSet.fieldValue('c'), 'z');
      },
    );

    testWidgets(
      'Tab after last editable cell appends empty row in insert mode',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(
              size: 255,
              name: 'name',
              label: 'Name',
              required: true,
            ),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(dataSet.recordCount, 2);
        expect(dataSet.state, FdcDataSetState.insert);
        expect(dataSet.errors.messages.isNotEmpty, isFalse);
        expect(find.text('Validation error'), findsNothing);
        expect(find.byType(TextFormField), findsNothing);

        await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
        await tester.pumpAndSettle();

        expect(find.byType(EditableText), findsOneWidget);
        final editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'x');
      },
    );

    testWidgets(
      'Tab auto append selects first tab column with indicator and readOnly column',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id', label: 'ID'),
            FdcStringField(
              size: 255,
              name: 'name',
              label: 'Name',
              required: true,
            ),
          ],
          onNewRecord: (dataSet) {
            dataSet.setFieldValue('id', 99);
            dataSet.setFieldValue('name', 'New customer');
          },

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
            FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(dataSet.recordCount, 2);
        expect(dataSet.state, FdcDataSetState.insert);
        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
        expect(dataSet.fieldValue('id'), 99);
        expect(dataSet.fieldValue('name'), 'New customer');
        expect(find.text('New customer'), findsWidgets);

        await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
        await tester.pumpAndSettle();

        expect(find.byType(EditableText), findsNothing);
        expect(dataSet.fieldValue('id'), 99);

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
        await tester.pumpAndSettle();

        expect(find.byType(EditableText), findsOneWidget);
        final editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'y');
      },
    );

    testWidgets(
      'ArrowDown on last row auto append selects first editable cell and typing starts auto edit',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id', label: 'ID'),
            FdcStringField(
              size: 255,
              name: 'name',
              label: 'Name',
              required: true,
            ),
          ],
          onNewRecord: (dataSet) {
            dataSet.setFieldValue('id', 99);
            dataSet.setFieldValue('name', 'New customer');
          },

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
            FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

        expect(dataSet.recordCount, 2);
        expect(dataSet.state, FdcDataSetState.insert);
        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
        expect(dataSet.fieldValue('name'), 'New customer');
        expect(find.text('New customer'), findsWidgets);

        expect(find.byType(TextFormField), findsNothing);

        await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
        await tester.pumpAndSettle();

        expect(find.byType(EditableText), findsOneWidget);
        final editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.focusNode.hasFocus, isTrue);
        expect(editor.controller.text, 'x');
      },
    );
  });
}
