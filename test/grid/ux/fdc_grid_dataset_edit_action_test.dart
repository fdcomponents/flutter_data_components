import 'fdc_grid_ux_test_support.dart';

void _registerDatasetEditActionTests() {
  group('Dataset edit actions', () {
    testWidgets('calculated field cannot enter grid editor', (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id', calculatedValue: uxConstantId),
          FdcStringField(size: 255, name: 'name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
          ],
        ),
      )..open();

      await uxPumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('1'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);

      expect(find.byType(TextFormField), findsNothing);
      expect(dataSet.state, FdcDataSetState.browse);
    });

    testWidgets('Insert key inserts a row before the current record', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();
      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Beta'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.insert);
      await uxPumpPendingFrames(tester);

      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet.recordCount, 3);
      expect(dataSet['name'], isNull);
      expect(dataSet.toMaps()[2]['name'], 'Beta');
    });

    testWidgets('Insert key is ignored while dataset is editing', (
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
      final recordCountBeforeInsertKey = dataSet.recordCount;

      await tester.sendKeyEvent(LogicalKeyboardKey.insert);
      await uxPumpPendingFrames(tester);

      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet.recordCount, recordCountBeforeInsertKey);
    });

    testWidgets('Insert key is ignored while dataset is inserting', (
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
      dataSet.insert();
      final recordCountBeforeInsertKey = dataSet.recordCount;

      await tester.sendKeyEvent(LogicalKeyboardKey.insert);
      await uxPumpPendingFrames(tester);

      expect(dataSet.state, FdcDataSetState.insert);
      expect(dataSet.recordCount, recordCountBeforeInsertKey);
    });

    testWidgets('readOnly grid ignores Insert key', (tester) async {
      final dataSet = uxPeopleDataSet();
      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        options: const FdcGridOptions(readOnly: true),
      );

      await tester.tap(find.text('Alpha'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.insert);
      await uxPumpPendingFrames(tester);

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
    });

    testWidgets('adapter readOnly dataset ignores Insert key', (tester) async {
      final dataSet = uxReadOnlyPeopleDataSet();
      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.insert);
      await uxPumpPendingFrames(tester);

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.recordCount, 2);
    });

    testWidgets('Ctrl+Delete with confirm=true keeps row when cancelled', (
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
      await uxPressCtrlDelete(tester);

      expect(find.text('Confirm delete'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 2);
      expect(
        dataSet.toMaps(),
        const <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Alpha'},
          <String, Object?>{'id': 2, 'name': 'Beta'},
        ],
        reason: 'Cancelling delete must leave the complete dataset unchanged.',
      );
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('Ctrl+Delete with confirm=true deletes row when confirmed', (
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
      await uxPressCtrlDelete(tester);

      expect(find.text('Confirm delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 1);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets(
      'Ctrl+Delete keeps grid focus in the same column after delete',
      (tester) async {
        const selectedColor = Colors.teal;
        final dataSet = uxPeopleDataSet();

        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);
        final beforeDeleteRect = selectedCellRect();

        await uxPressCtrlDelete(tester);

        expect(find.text('Confirm delete'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await uxPumpPendingFrames(tester);

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
      final dataSet = uxPeopleDataSet();
      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcActionColumn(actions: [FdcRowAction.delete()]),
        ],
      );

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await uxPumpPendingFrames(tester);

      expect(find.text('Confirm delete'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 2);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('action delete respects confirmDelete confirmation', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();
      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcActionColumn(actions: [FdcRowAction.delete()]),
        ],
      );

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await uxPumpPendingFrames(tester);

      expect(find.text('Confirm delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 1);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('readOnly grid ignores Ctrl+Delete', (tester) async {
      final dataSet = uxPeopleDataSet();
      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        options: const FdcGridOptions(readOnly: true),
      );

      await tester.tap(find.text('Alpha'));
      await uxPumpPendingFrames(tester);
      await uxPressCtrlDelete(tester);

      expect(find.text('Confirm delete'), findsNothing);
      expect(dataSet.recordCount, 2);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(dataSet.state, FdcDataSetState.browse);
    });

    testWidgets('adapter readOnly dataset ignores Ctrl+Delete', (tester) async {
      final dataSet = uxReadOnlyPeopleDataSet();
      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await uxPumpPendingFrames(tester);
      await uxPressCtrlDelete(tester);

      expect(find.text('Confirm delete'), findsNothing);
      expect(dataSet.recordCount, 2);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(dataSet.state, FdcDataSetState.browse);
    });

    testWidgets('adapter readOnly dataset disables built-in action delete', (
      tester,
    ) async {
      final dataSet = uxReadOnlyPeopleDataSet();
      await uxPumpGrid(
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
      await uxPumpPendingFrames(tester);

      expect(find.text('Confirm delete'), findsNothing);
      expect(dataSet.recordCount, 2);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });
  });
}

void main() {
  group('FdcGrid widget UX / Dataset Edit Action', () {
    _registerDatasetEditActionTests();
  });
}
