import 'fdc_grid_ux_test_support.dart';

void _registerToolbarSearchCollapseTests() {
  group('Toolbar search collapse and viewport', () {
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

      expect(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_field')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_icon_button')),
      );
      await uxPumpPendingFrames(tester);

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

        await uxPumpPendingFrames(tester);

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

        await uxPumpPendingFrames(tester);
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

      await tester.tap(find.text('Alpha'));
      await uxPumpPendingFrames(tester);

      expect(searchField, findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('fdc_grid_toolbar_search_clear_button')),
      );
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Alpha'));
      await uxPumpPendingFrames(tester);

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
        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await uxPumpPendingFrames(tester);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await uxPumpPendingFrames(tester);

        expect(find.text('Customer 12'), findsWidgets);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await uxPumpPendingFrames(tester);

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

void main() {
  group('FdcGrid widget UX / Toolbar Search Collapse', () {
    _registerToolbarSearchCollapseTests();
  });
}
