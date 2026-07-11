part of '../fdc_grid_widget_ux_test.dart';

void _registerEditingActionTests() {
  group('Editing actions', () {
    testWidgets('calculated field cannot enter grid editor', (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', calculatedValue: _constantId),
          FdcStringField(size: 255, name: 'name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      )..open();

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNothing);
      expect(dataSet.state, FdcDataSetState.browse);
    });

    testWidgets('Insert key inserts a row before the current record', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.insert);
      await tester.pumpAndSettle();

      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet.recordCount, 3);
      expect(dataSet['name'], isNull);
      expect(dataSet.toMaps()[2]['name'], 'Beta');
    });

    testWidgets('Insert key is ignored while dataset is editing', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      dataSet.edit();
      final recordCountBeforeInsertKey = dataSet.recordCount;

      await tester.sendKeyEvent(LogicalKeyboardKey.insert);
      await tester.pumpAndSettle();

      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet.recordCount, recordCountBeforeInsertKey);
    });

    testWidgets('Insert key is ignored while dataset is inserting', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      dataSet.insert();
      final recordCountBeforeInsertKey = dataSet.recordCount;

      await tester.sendKeyEvent(LogicalKeyboardKey.insert);
      await tester.pumpAndSettle();

      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet.recordCount, recordCountBeforeInsertKey);
    });

    testWidgets('readOnly grid ignores Insert key', (tester) async {
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        options: const FdcGridOptions(readOnly: true),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.insert);
      await tester.pumpAndSettle();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
    });

    testWidgets('adapter readOnly dataset ignores Insert key', (tester) async {
      final dataSet = _readOnlyPeopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.insert);
      await tester.pumpAndSettle();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
    });

    testWidgets('Ctrl+Delete with confirm=true keeps row when cancelled', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await _pressCtrlDelete(tester);

      expect(find.text('Confirm delete'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 2);
      expect(dataSet.toMaps().map((row) => row['name']), contains('Alpha'));
      expect(dataSet.toMaps().map((row) => row['id']), contains(1));
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('Ctrl+Delete with confirm=true deletes row when confirmed', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await _pressCtrlDelete(tester);

      expect(find.text('Confirm delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 1);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets(
      'Ctrl+Delete keeps grid focus in the same column after delete',
      (tester) async {
        const selectedColor = Colors.teal;
        final dataSet = _peopleDataSet();

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          style: const FdcGridStyle(selectedCellBackgroundColor: selectedColor),
        );

        Rect selectedCellRect() {
          final selectedCellFinder = find.byWidgetPredicate((widget) {
            if (widget is! Container) {
              return false;
            }
            final decoration = widget.decoration;
            return decoration is BoxDecoration &&
                decoration.color == selectedColor;
          });

          final matches = selectedCellFinder.evaluate().toList();
          expect(matches, isNotEmpty);

          final rects = <Rect>[
            for (var i = 0; i < matches.length; i++)
              tester.getRect(selectedCellFinder.at(i)),
          ];
          rects.sort(
            (a, b) => (b.width * b.height).compareTo(a.width * a.height),
          );
          return rects.first;
        }

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        final beforeDeleteRect = selectedCellRect();

        await _pressCtrlDelete(tester);

        expect(find.text('Confirm delete'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(dataSet.recordCount, 1);
        expect(find.text('Alpha'), findsNothing);
        expect(find.text('Beta'), findsOneWidget);

        final afterDeleteRect = selectedCellRect();
        expect(
          afterDeleteRect.center.dx,
          closeTo(beforeDeleteRect.center.dx, 1),
        );
      },
    );

    testWidgets('action delete respects confirmDelete cancel', (tester) async {
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcActionColumn(actions: [FdcRowAction.delete()]),
        ],
      );

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Confirm delete'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 2);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('action delete respects confirmDelete confirmation', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcActionColumn(actions: [FdcRowAction.delete()]),
        ],
      );

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Confirm delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 1);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('readOnly grid ignores Ctrl+Delete', (tester) async {
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        options: const FdcGridOptions(readOnly: true),
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await _pressCtrlDelete(tester);

      expect(find.text('Confirm delete'), findsNothing);
      expect(dataSet.recordCount, 2);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(dataSet.state, FdcDataSetState.browse);
    });

    testWidgets('adapter readOnly dataset ignores Ctrl+Delete', (tester) async {
      final dataSet = _readOnlyPeopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await _pressCtrlDelete(tester);

      expect(find.text('Confirm delete'), findsNothing);
      expect(dataSet.recordCount, 2);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(dataSet.state, FdcDataSetState.browse);
    });

    testWidgets('adapter readOnly dataset disables built-in action delete', (
      tester,
    ) async {
      final dataSet = _readOnlyPeopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcActionColumn(actions: [FdcRowAction.delete()]),
        ],
      );

      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.delete_outline).first,
      );
      expect(button.onPressed, isNull);

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Confirm delete'), findsNothing);
      expect(dataSet.recordCount, 2);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

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

        await _pumpGrid(
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
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await tester.pumpAndSettle();
        expect(find.byType(EditableText), findsOneWidget);

        final offsetBeforeTyping = horizontalController.offset;
        await tester.enterText(
          find.byType(EditableText),
          'Alpha typed text that is intentionally much wider than the cell',
        );
        await tester.pumpAndSettle();

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

        await _pumpGrid(
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
        await tester.pumpAndSettle();
        final offsetBeforeEdit = horizontalController.offset;
        expect(offsetBeforeEdit, greaterThan(0));

        await tester.tap(find.text('New York'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await tester.pumpAndSettle();
        expect(find.byType(EditableText), findsOneWidget);

        await tester.enterText(
          find.byType(EditableText),
          'New York typed text that is intentionally wider than the city cell',
        );
        await tester.pumpAndSettle();

        final offsetBeforeMove = horizontalController.offset;
        expect(offsetBeforeMove, closeTo(offsetBeforeEdit, 0.5));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();

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

        await _pumpGrid(
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
        await tester.pumpAndSettle();
        final offsetBeforeEdit = horizontalController.offset;
        expect(offsetBeforeEdit, greaterThan(0));

        await tester.tap(find.text('New York'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await tester.pumpAndSettle();
        expect(find.byType(EditableText), findsOneWidget);

        await tester.enterText(
          find.byType(EditableText),
          'New York typed text wider than the edited city column',
        );
        await tester.pumpAndSettle();
        final offsetBeforeEnter = horizontalController.offset;
        expect(offsetBeforeEnter, closeTo(offsetBeforeEdit, 0.5));

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(horizontalController.offset, closeTo(offsetBeforeEnter, 1.0));
      },
    );

    testWidgets('Escape inside inplace editor restores old cell value', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'Changed');
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Changed',
      );
      expect(dataSet.fieldValue('name'), 'Alpha');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNothing);
      expect(dataSet.fieldValue('name'), 'Alpha');
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('inplace text editor keeps Shift+Arrow text selection keys', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
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
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);

      final editableFinder = find.byType(EditableText).last;
      final editableText = tester.widget<EditableText>(editableFinder);
      editableText.controller.selection = const TextSelection.collapsed(
        offset: 2,
      );
      await tester.pump();

      await tester.tap(editableFinder);
      await tester.pump(const Duration(milliseconds: 20));
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
      final dataSet = _peopleDataSet();
      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      dataSet.edit();
      dataSet.setFieldValue('name', 'Changed');
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNothing);
      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet.fieldValue('name'), 'Changed');
      expect(find.text('Changed'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();

        dataSet.edit();
        dataSet.setFieldValue('name', 'Changed');
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        expect(beforeCancelCalls, 1);
        expect(dataSet.state, FdcDataSetState.edit);
        expect(dataSet.fieldValue('name'), 'Changed');
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
        expect(dataSet.errors.messages[0], 'Cancel is not allowed.');
        expect(find.text('Cancel is not allowed.'), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
      },
    );

    testWidgets(
      'Immediate min/max validation accepts invalid cell value without inline dialog',
      (tester) async {
        final validationMessages = <String>[];
        final dataSet = _quantityDataSet(
          onValidationError: (_, errors) {
            validationMessages.addAll(errors.map((error) => error.message));
          },
        );
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'quantity'),
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
          ],
        );

        await tester.tap(find.text('5'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), '20');
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(find.text('Validation error'), findsNothing);
        expect(
          find.text('Field Quantity must be less than or equal to 10.'),
          findsNothing,
        );
        expect(dataSet.fieldValue('quantity'), 20);
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
        expect(
          validationMessages.any(
            (message) => message.contains('less than or equal to 10'),
          ),
          isTrue,
        );
        expect(find.byType(TextFormField), findsNothing);
      },
    );

    testWidgets('Text column limits input length from string field metadata', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'code', size: 3),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'code': 'Ab'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'code', showCounter: true),
        ],
      );

      await tester.tap(find.text('Ab'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();

      expect(find.text('2/3'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'ABCDE');
      await tester.pump();

      expect(find.text('3/3'), findsOneWidget);
      expect(find.text('2/3'), findsNothing);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .controller
            .text,
        'ABC',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Validation error'), findsNothing);
      expect(find.textContaining('would be truncated'), findsNothing);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'code'), 'ABC');
    });

    testWidgets('Text column limits input length even without counter', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'code', size: 3)],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'code': 'Ab'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'code'),
        ],
      );

      await tester.tap(find.text('Ab'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText), 'ABCDE');
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .controller
            .text,
        'ABC',
      );
    });

    testWidgets(
      'Tab follows column focusOrder order while Enter keeps visual order',
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
            FdcTextColumn<dynamic>(fieldName: 'b', focusOrder: 3),
            FdcTextColumn<dynamic>(fieldName: 'c', focusOrder: 2),
          ],
        );

        await tester.tap(find.text('A1'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
        await tester.pumpAndSettle();

        expect(find.byType(EditableText), findsOneWidget);
        var editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'x');

        await tester.tap(find.text('B1'));
        await tester.pumpAndSettle();

        expect(dataSet.fieldValue('b'), 'B1');
        expect(dataSet.fieldValue('c'), 'x');

        final enterDataSet = FdcDataSet(
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
        enterDataSet.open();

        await _pumpGrid(
          tester,
          dataSet: enterDataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'a', focusOrder: 1),
            FdcTextColumn<dynamic>(fieldName: 'b', focusOrder: 3),
            FdcTextColumn<dynamic>(fieldName: 'c', focusOrder: 2),
          ],
        );

        await tester.tap(find.text('A1'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
        await tester.pumpAndSettle();

        expect(find.byType(EditableText), findsOneWidget);
        editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'y');

        await tester.tap(find.text('C1'));
        await tester.pumpAndSettle();

        expect(enterDataSet.fieldValue('b'), 'y');
        expect(enterDataSet.fieldValue('c'), 'C1');
      },
    );
  });
}
