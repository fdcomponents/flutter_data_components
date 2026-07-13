import 'fdc_grid_ux_test_support.dart';

void _registerEditingInsertValidationTests() {
  group('Editing insert validation', () {
    testWidgets('ArrowDown on pristine append row keeps insert buffer active', (
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
            {'id': 3, 'name': 'Gamma'},
            {'id': 4, 'name': 'Delta'},
            {'id': 5, 'name': 'Epsilon'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Epsilon'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 6);
      expect(dataSet.state, FdcDataSetState.insert);
      expect(FdcDataSetInternal.activeIndex(dataSet), 5);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 6);
      expect(dataSet.state, FdcDataSetState.insert);
      expect(FdcDataSetInternal.activeIndex(dataSet), 5);
    });

    testWidgets(
      'Auto appended insert row keeps insert indicator while editing',
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
            FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await uxPumpPendingFrames(tester);

        expect(dataSet.state, FdcDataSetState.insert);
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.byIcon(Icons.edit_outlined), findsNothing);
      },
    );

    testWidgets(
      'Grid auto append does not validate a pristine required insert row',
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
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await uxPumpPendingFrames(tester);

        expect(dataSet.recordCount, 2);
        expect(dataSet.state, FdcDataSetState.insert);
        expect(dataSet.errors.messages.isNotEmpty, isFalse);
        expect(find.text('Validation error'), findsNothing);
      },
    );

    testWidgets(
      'Grid auto append displays onNewRecord defaults before deferred editor starts',
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
          onNewRecord: (dataSet) {
            dataSet.setFieldValue('name', 'New customer');
          },

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha'},
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
        );

        await tester.tap(find.text('Alpha'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await uxPumpPendingFrames(tester);

        expect(dataSet.recordCount, 2);
        expect(dataSet.state, FdcDataSetState.insert);
        expect(dataSet.fieldValue('name'), 'New customer');
        expect(find.text('New customer'), findsWidgets);
        expect(find.byType(TextFormField), findsNothing);

        await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
        await uxPumpPendingFrames(tester);

        expect(find.byType(EditableText), findsOneWidget);
        final editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'x');
      },
    );

    testWidgets('Invalid active insert blocks activating another row', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(
            size: 255,
            name: 'name',
            label: 'Name',
            required: true,
          ),
        ],
        onNewRecord: (dataSet) {
          dataSet.setFieldValue('name', 'Temp');
        },

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
      );

      await tester.tap(find.text('Beta'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await uxPumpPendingFrames(tester);

      expect(dataSet.state, FdcDataSetState.insert);
      expect(FdcDataSetInternal.activeIndex(dataSet), 2);
      expect(find.byType(TextFormField), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);
      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '');
      await tester.pump();
      await tester.tap(find.text('Alpha'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.state, FdcDataSetState.insert);
      expect(FdcDataSetInternal.activeIndex(dataSet), 2);
      expect(dataSet.recordCount, 3);
      expect(dataSet.errors.messages.isNotEmpty, isTrue);
      expect(find.text('Validation error'), findsOneWidget);
      expect(find.text('Field Name is required.'), findsOneWidget);
    });

    testWidgets('Invalid active insert can blur when tapping outside grid', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(
            size: 255,
            name: 'name',
            label: 'Name',
            required: true,
          ),
        ],
        onNewRecord: (dataSet) {
          dataSet.setFieldValue('name', 'Temp');
        },

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
      );

      await tester.tap(find.text('Beta'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await uxPumpPendingFrames(tester);

      expect(find.byType(TextFormField), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);
      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '');
      await tester.pump();
      await tester.tapAt(const Offset(700, 500));
      await uxPumpPendingFrames(tester);

      expect(dataSet.state, FdcDataSetState.insert);
      expect(FdcDataSetInternal.activeIndex(dataSet), 2);
      expect(dataSet.recordCount, 3);
      expect(dataSet.errors.messages.isNotEmpty, isTrue);
      expect(find.byType(EditableText), findsNothing);
      expect(find.text('Validation error'), findsNothing);
      expect(find.text('Field Name is required.'), findsNothing);
    });

    testWidgets(
      'Pristine required insert row is cancelled when leaving before changes',
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
        );

        await tester.tap(find.text('Beta'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await uxPumpPendingFrames(tester);

        expect(dataSet.state, FdcDataSetState.insert);
        expect(FdcDataSetInternal.activeIndex(dataSet), 2);
        expect(dataSet.recordCount, 3);

        await tester.tap(find.text('Alpha'));
        await uxPumpPendingFrames(tester);

        // A completely untouched insert row is not validated. It is cancelled
        // automatically when the user leaves it.
        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.recordCount, 2);
        expect(dataSet.errors.messages.isNotEmpty, isFalse);
        expect(find.text('Field Name is required.'), findsNothing);
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Editing Insert Validation', () {
    _registerEditingInsertValidationTests();
  });
}
