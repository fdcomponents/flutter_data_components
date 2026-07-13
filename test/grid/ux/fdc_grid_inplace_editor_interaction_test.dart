import 'fdc_grid_ux_test_support.dart';

void _registerInplaceEditorInteractionTests() {
  group('Inplace editor interactions', () {
    testWidgets(
      'inplace text editor caret scroll does not move grid horizontally',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcStringField(size: 255, name: 'city'),
            FdcStringField(size: 255, name: 'note'),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha', 'city': 'New York', 'note': 'One'},
            ],
          ),
        )..open();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', width: 72),
            FdcTextColumn<dynamic>(
              fieldName: 'city',
              label: 'City',
              width: 120,
            ),
            FdcTextColumn<dynamic>(
              fieldName: 'note',
              label: 'Note',
              width: 120,
            ),
          ],
          toolbarVisible: false,
          width: 180,
          height: 160,
        );

        final horizontalScrollView = find.byWidgetPredicate(
          (widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.horizontal,
        );
        final horizontalController = tester
            .widget<SingleChildScrollView>(horizontalScrollView.first)
            .controller!;
        final headerBeforeEdit = tester.getTopLeft(find.text('City'));

        await tester.tap(find.text('Alpha'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await uxPumpPendingFrames(tester);
        expect(find.byType(EditableText), findsOneWidget);

        final offsetBeforeTyping = horizontalController.offset;
        await tester.enterText(
          find.byType(EditableText),
          'Alpha typed text that is intentionally much wider than the cell',
        );
        await uxPumpPendingFrames(tester);

        expect(horizontalController.offset, closeTo(offsetBeforeTyping, 0.5));
        expect(tester.getTopLeft(find.text('City')), headerBeforeEdit);
      },
    );

    testWidgets(
      'vertical keyboard move from text editor preserves horizontal scroll',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcStringField(size: 255, name: 'city'),
            FdcStringField(size: 255, name: 'note'),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha', 'city': 'New York', 'note': 'One'},
              {'name': 'Beta', 'city': 'Chicago', 'note': 'Two'},
            ],
          ),
        )..open();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', width: 72),
            FdcTextColumn<dynamic>(
              fieldName: 'city',
              label: 'City',
              width: 120,
            ),
            FdcTextColumn<dynamic>(
              fieldName: 'note',
              label: 'Note',
              width: 120,
            ),
          ],
          toolbarVisible: false,
          width: 180,
          height: 180,
        );

        final horizontalScrollView = find.byWidgetPredicate(
          (widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.horizontal,
        );
        final horizontalController = tester
            .widget<SingleChildScrollView>(horizontalScrollView.first)
            .controller!;

        horizontalController.jumpTo(72);
        await uxPumpPendingFrames(tester);
        final offsetBeforeEdit = horizontalController.offset;
        expect(offsetBeforeEdit, greaterThan(0));

        await tester.tap(find.text('New York'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await uxPumpPendingFrames(tester);
        expect(find.byType(EditableText), findsOneWidget);

        await tester.enterText(
          find.byType(EditableText),
          'New York typed text that is intentionally wider than the city cell',
        );
        await uxPumpPendingFrames(tester);

        final offsetBeforeMove = horizontalController.offset;
        expect(offsetBeforeMove, closeTo(offsetBeforeEdit, 0.5));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await uxPumpPendingFrames(tester);

        expect(horizontalController.offset, closeTo(offsetBeforeMove, 1.0));
      },
    );

    testWidgets(
      'Enter from text editor does not horizontally reveal target column',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcStringField(size: 255, name: 'city'),
            FdcStringField(size: 255, name: 'note'),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha', 'city': 'New York', 'note': 'One'},
              {'name': 'Beta', 'city': 'Chicago', 'note': 'Two'},
            ],
          ),
        )..open();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', width: 72),
            FdcTextColumn<dynamic>(fieldName: 'city', label: 'City', width: 72),
            FdcTextColumn<dynamic>(
              fieldName: 'note',
              label: 'Note',
              width: 160,
            ),
          ],
          toolbarVisible: false,
          width: 150,
          height: 180,
        );

        final horizontalScrollView = find.byWidgetPredicate(
          (widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.horizontal,
        );
        final horizontalController = tester
            .widget<SingleChildScrollView>(horizontalScrollView.first)
            .controller!;

        horizontalController.jumpTo(72);
        await uxPumpPendingFrames(tester);
        final offsetBeforeEdit = horizontalController.offset;
        expect(offsetBeforeEdit, greaterThan(0));

        await tester.tap(find.text('New York'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await uxPumpPendingFrames(tester);
        expect(find.byType(EditableText), findsOneWidget);

        await tester.enterText(
          find.byType(EditableText),
          'New York typed text wider than the edited city column',
        );
        await uxPumpPendingFrames(tester);
        final offsetBeforeEnter = horizontalController.offset;
        expect(offsetBeforeEnter, closeTo(offsetBeforeEdit, 0.5));

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await uxPumpPendingFrames(tester);

        expect(horizontalController.offset, closeTo(offsetBeforeEnter, 1.0));
      },
    );

    testWidgets('Escape inside inplace editor restores old cell value', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();
      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);
      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'Changed');
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Changed',
      );
      expect(dataSet.fieldValue('name'), 'Alpha');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await uxPumpPendingFrames(tester);

      expect(find.byType(TextFormField), findsNothing);
      expect(dataSet.fieldValue('name'), 'Alpha');
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('inplace text editor keeps Shift+Arrow text selection keys', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();
      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);
      expect(find.byType(EditableText), findsOneWidget);

      final editableText = tester.widget<EditableText>(
        find.byType(EditableText).last,
      );
      editableText.controller.selection = const TextSelection.collapsed(
        offset: 0,
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(editableText.controller.selection.isCollapsed, isFalse);
    });

    testWidgets('inplace text editor double click selects all text', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();
      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);
      expect(find.byType(EditableText), findsOneWidget);

      final editableFinder = find.byType(EditableText).last;
      final editableText = tester.widget<EditableText>(editableFinder);
      editableText.controller.selection = const TextSelection.collapsed(
        offset: 2,
      );
      await tester.pump();

      await tester.tap(editableFinder);
      await tester.pump();
      await tester.tap(editableFinder);
      await tester.pump();

      expect(editableText.controller.selection.baseOffset, 0);
      expect(
        editableText.controller.selection.extentOffset,
        editableText.controller.text.length,
      );
    });

    testWidgets('Escape without editor cancels dataset edit rollback', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();
      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await uxPumpPendingFrames(tester);

      dataSet.edit();
      dataSet.setFieldValue('name', 'Changed');
      await uxPumpPendingFrames(tester);

      expect(find.byType(TextFormField), findsNothing);
      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet.fieldValue('name'), 'Changed');
      expect(find.text('Changed'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await uxPumpPendingFrames(tester);

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.fieldValue('name'), 'Alpha');
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets(
      'beforeCancel abort from grid Escape shows dataset error dialog',
      (tester) async {
        var beforeCancelCalls = 0;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcStringField(size: 255, name: 'name'),
          ],
          beforeCancel: (dataSet) {
            beforeCancelCalls++;
            throw FdcDataSetAbortException('Cancel is not allowed.');
          },

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
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await uxPumpPendingFrames(tester);

        dataSet.edit();
        dataSet.setFieldValue('name', 'Changed');
        await uxPumpPendingFrames(tester);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await uxPumpPendingFrames(tester);

        expect(beforeCancelCalls, 1);
        expect(dataSet.state, FdcDataSetState.edit);
        expect(dataSet.fieldValue('name'), 'Changed');
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
        expect(dataSet.errors.messages[0], 'Cancel is not allowed.');
        expect(find.text('Cancel is not allowed.'), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Inplace Editor Interaction', () {
    _registerInplaceEditorInteractionTests();
  });
}
