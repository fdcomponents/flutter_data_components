import 'fdc_grid_ux_test_support.dart';

void _registerIndicatorSelectionTests() {
  group('Indicator and selection state', () {
    testWidgets('row selection on another row is disabled during dirty edit', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name', required: true),
        ],
        beforePost: (dataSet) {
          throw FdcDataSetAbortException('Post is not allowed.');
        },

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
            {'id': 2, 'name': 'Beta'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpIndicatorGrid(
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
      await tester.enterText(find.byType(EditableText), 'Changed');
      await tester.pump();

      await tester.tap(find.byType(Checkbox).at(2));
      await uxPumpPendingFrames(tester);

      expect(find.text('Post is not allowed.'), findsNothing);
      expect(dataSet.state, FdcDataSetState.edit);
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 0);
      final otherRowCheckbox = tester.widget<Checkbox>(
        find.byType(Checkbox).at(2),
      );
      expect(otherRowCheckbox.value, isFalse);
      expect(otherRowCheckbox.onChanged, isNull);
    });

    testWidgets('row selection on same row does not post dirty edit', (
      tester,
    ) async {
      var beforePostCount = 0;
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name', required: true),
        ],
        beforePost: (dataSet) {
          beforePostCount++;
          throw FdcDataSetAbortException('Post is not allowed.');
        },

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
            {'id': 2, 'name': 'Beta'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpIndicatorGrid(
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
      await tester.enterText(find.byType(EditableText), 'Changed');
      await tester.pump();

      await tester.tap(find.byType(Checkbox).at(1));
      await uxPumpPendingFrames(tester);

      expect(beforePostCount, 0);
      expect(find.text('Post is not allowed.'), findsNothing);
      expect(dataSet.state, FdcDataSetState.edit);
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
        isTrue,
      );
    });

    testWidgets(
      'indicator header checkbox reflects partial visible selection',
      (tester) async {
        final dataSet = uxPeopleDataSet();

        await uxPumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        // Header select-all checkbox + one row checkbox for each visible row.
        expect(find.byType(Checkbox), findsNWidgets(3));
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).at(0)).value,
          isFalse,
        );

        FdcDataSetInternal.setRecordSelectedAt(dataSet, 0, true);
        // Internal selection helpers deliberately do not notify by themselves;
        // trigger a normal dataset notification so the mounted grid rebuilds.
        dataSet.moveToRecord(2);
        await uxPumpPendingFrames(tester);

        expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).at(0)).value,
          isNull,
        );

        await tester.tap(find.byType(Checkbox).at(0));
        await uxPumpPendingFrames(tester);

        expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 2);
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).at(0)).value,
          isTrue,
        );
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
          isTrue,
        );
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).at(2)).value,
          isTrue,
        );
      },
    );

    testWidgets(
      'indicator select all uses filter row when filters are visible',
      (tester) async {
        final dataSet = uxPeopleDataSet();

        await uxPumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          headerFiltersVisible: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Checkbox), findsNWidgets(3));
        expect(find.byIcon(Icons.menu), findsOneWidget);

        final menuCenter = tester.getCenter(find.byIcon(Icons.menu));
        final headerCheckboxCenter = tester.getCenter(
          find.byType(Checkbox).first,
        );
        final firstRowCheckboxCenter = tester.getCenter(
          find.byType(Checkbox).at(1),
        );
        expect(headerCheckboxCenter.dy, greaterThan(menuCenter.dy + 20));
        expect(
          headerCheckboxCenter.dx,
          closeTo(firstRowCheckboxCenter.dx, 1.0),
        );
        expect(find.byIcon(Icons.grading_outlined), findsNothing);
      },
    );

    testWidgets(
      'indicator selection filter icon is not shown in the row indicator header',
      (tester) async {
        final dataSet = uxPeopleDataSet();

        await uxPumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        expect(find.byIcon(Icons.grading_outlined), findsNothing);
        expect(find.byIcon(Icons.menu), findsOneWidget);
      },
    );

    testWidgets(
      'indicator select all shares first header row when filters are hidden',
      (tester) async {
        final dataSet = uxPeopleDataSet();

        await uxPumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Checkbox), findsNWidgets(3));
        expect(find.byIcon(Icons.menu), findsOneWidget);

        final menuCenter = tester.getCenter(find.byIcon(Icons.menu));
        final headerCheckboxCenter = tester.getCenter(
          find.byType(Checkbox).first,
        );
        final firstRowCheckboxCenter = tester.getCenter(
          find.byType(Checkbox).at(1),
        );

        expect(headerCheckboxCenter.dx, lessThan(menuCenter.dx));
        expect(headerCheckboxCenter.dy, closeTo(menuCenter.dy, 1.0));
        expect(
          headerCheckboxCenter.dx,
          closeTo(firstRowCheckboxCenter.dx, 1.0),
        );
      },
    );

    testWidgets(
      'indicator main menu is centered over row numbers when select all is hidden',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name', label: 'Name'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              for (var index = 0; index < 2000; index++)
                <String, Object?>{'name': 'Person $index'},
            ],
          ),
        );
        dataSet.open();

        await uxPumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          showRecordStatus: false,
          showRowSelect: false,
          showRowNumbers: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Checkbox), findsNothing);
        expect(find.byIcon(Icons.menu), findsOneWidget);

        final menuCenter = tester.getCenter(find.byIcon(Icons.menu));
        final firstRowNumberCenter = tester.getCenter(find.text('1'));

        expect(menuCenter.dx, closeTo(firstRowNumberCenter.dx, 1.0));
      },
    );

    testWidgets(
      'indicator main menu is centered when header filters are visible',
      (tester) async {
        final dataSet = uxPeopleDataSet();

        await uxPumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          headerFiltersVisible: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Checkbox), findsNWidgets(3));
        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.byType(FdcGridRowIndicatorHeader), findsOneWidget);

        final menuCenter = tester.getCenter(find.byIcon(Icons.menu));
        final indicatorHeaderCenter = tester.getCenter(
          find.byType(FdcGridRowIndicatorHeader),
        );
        final headerCheckboxCenter = tester.getCenter(
          find.byType(Checkbox).first,
        );

        expect(menuCenter.dx, closeTo(indicatorHeaderCenter.dx, 1.0));
        expect(menuCenter.dy, lessThan(headerCheckboxCenter.dy));
      },
    );

    testWidgets(
      'indicator header keeps select all and main menu visible without overflow',
      (tester) async {
        final dataSet = uxPeopleDataSet();

        await uxPumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          width: 220,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Checkbox), findsNWidgets(3));
        expect(find.byIcon(Icons.menu), findsOneWidget);
      },
    );

    testWidgets('grid row selection survives filter hide and show by record', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name'),
          FdcStringField(size: 255, name: 'status'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha', 'status': 'active'},
            {'id': 2, 'name': 'Beta', 'status': 'blocked'},
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
        rowIndicator: const FdcGridRowIndicator(
          visible: true,
          options: FdcGridRowIndicatorOptions(showRowSelect: true),
        ),
      );

      await tester.tap(find.byType(Checkbox).at(2));
      await uxPumpPendingFrames(tester);

      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);

      FdcDataSetInternal.setViewState(
        dataSet,
        filters: const <FdcDataSetFilter>[
          FdcDataSetFilter(
            fieldName: 'status',
            operator: FdcFilterOperator.equals,
            value: 'active',
          ),
        ],
      );
      await uxPumpPendingFrames(tester);

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 0);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(0)).value,
        isFalse,
      );
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
        isFalse,
      );

      FdcDataSetInternal.setViewState(
        dataSet,
        filters: const <FdcDataSetFilter>[],
      );
      await uxPumpPendingFrames(tester);

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(0)).value,
        isNull,
      );
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
        isFalse,
      );
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(2)).value,
        isTrue,
      );
    });
  });
}

void main() {
  group('FdcGrid widget UX / Indicator Selection', () {
    _registerIndicatorSelectionTests();
  });
}
