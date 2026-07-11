part of '../fdc_grid_widget_ux_test.dart';

void _registerStatusSummaryTests() {
  group('Status and summary', () {
    testWidgets('grid status bar shows record count and dataset state', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(height: 32),
                options: const FdcGridOptions(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                  FdcIntegerColumn(fieldName: 'id', width: 100),
                ],
                statusBar: const FdcGridStatusBar(visible: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Record 1 of 2'), findsOneWidget);
      expect(find.textContaining('State: Browse'), findsOneWidget);

      dataSet.edit();
      await tester.pumpAndSettle();

      expect(find.textContaining('State: Edit'), findsOneWidget);
    });

    testWidgets('grid status bar listens to dataset record changes', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 32,
            child: FdcGridStatusBarShell(
              dataSet: dataSet,
              statusBar: const FdcGridStatusBar(
                visible: true,
                items: <FdcGridItem>[FdcGridStatusText()],
              ),
              style: FdcGridStatusBarStyle.defaults,
              separatorColor: Colors.transparent,
              progressBarStyle: const FdcProgressBarStyle(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Record 1 of 2'), findsOneWidget);

      dataSet.moveToRecord(2);
      await tester.pumpAndSettle();

      expect(find.textContaining('Record 2 of 2'), findsOneWidget);
    });

    testWidgets('grid status bar shows global record number in paged mode', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            for (var i = 1; i <= 25; i++) <String, Object?>{'id': i},
          ],
        ),
        paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
      );
      await dataSet.open();
      await dataSet.paging.nextPage();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 320,
            height: 32,
            child: FdcGridStatusBarShell(
              dataSet: dataSet,
              statusBar: const FdcGridStatusBar(
                visible: true,
                items: <FdcGridItem>[FdcGridStatusText()],
              ),
              style: FdcGridStatusBarStyle.defaults,
              separatorColor: Colors.transparent,
              progressBarStyle: const FdcProgressBarStyle(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Record 11 of 25'), findsOneWidget);

      dataSet.moveToRecord(3);
      await tester.pumpAndSettle();

      expect(find.textContaining('Record 13 of 25'), findsOneWidget);
    });

    testWidgets('grid status bar shows filtered and sorted indicators', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();
      dataSet.filter.where('name').equals('Alpha').apply();
      dataSet.sort.sortBy('name').ascending.apply();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(height: 32),
                options: const FdcGridOptions(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                  FdcIntegerColumn(fieldName: 'id', width: 100),
                ],
                statusBar: const FdcGridStatusBar(visible: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Record 1 of 1'), findsOneWidget);
      expect(find.textContaining('Filtered'), findsOneWidget);
      expect(find.textContaining('Sorted'), findsOneWidget);
    });

    testWidgets('grid status bar style defaults to header background', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();
      const headerBackground = Color(0xFFEAF2FF);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                options: const FdcGridOptions(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                  FdcIntegerColumn(fieldName: 'id', width: 100),
                ],
                statusBar: const FdcGridStatusBar(visible: true),
                header: const FdcGridHeader(
                  height: 32,
                  style: FdcGridHeaderStyle(backgroundColor: headerBackground),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final statusBarBox = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('fdc_grid_status_bar')),
      );
      final decoration = statusBarBox.decoration as BoxDecoration;

      expect(decoration.color, headerBackground);
    });

    testWidgets('grid status bar uses component-owned style override', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();
      const statusBarBackground = Color(0xFFE8F5E9);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(height: 32),
                options: const FdcGridOptions(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                  FdcIntegerColumn(fieldName: 'id', width: 100),
                ],
                statusBar: const FdcGridStatusBar(
                  visible: true,
                  style: FdcGridStatusBarStyle(
                    backgroundColor: statusBarBackground,
                    height: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final statusBarFinder = find.byKey(const ValueKey('fdc_grid_status_bar'));
      final statusBarBox = tester.widget<DecoratedBox>(statusBarFinder);
      final decoration = statusBarBox.decoration as BoxDecoration;

      expect(decoration.color, statusBarBackground);
      expect(tester.getSize(statusBarFinder).height, 30);
    });

    testWidgets('grid status bar owns progress bar visibility', (tester) async {
      final dataSet = _peopleDataSet();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(height: 32),
                options: const FdcGridOptions(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                  FdcIntegerColumn(fieldName: 'id', width: 100),
                ],
                statusBar: const FdcGridStatusBar(
                  visible: true,
                  items: <FdcGridItem>[FdcGridStatusText()],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('fdc_grid_status_bar')), findsOneWidget);
      expect(find.byType(FdcProgressBar), findsNothing);
    });

    testWidgets('grid status bar owns progress bar width', (tester) async {
      final dataSet = _peopleDataSet();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(height: 32),
                options: const FdcGridOptions(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                  FdcIntegerColumn(fieldName: 'id', width: 100),
                ],
                statusBar: const FdcGridStatusBar(
                  visible: true,
                  items: <FdcGridItem>[
                    FdcGridStatusText(),
                    FdcGridProgressBar(width: 120),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(FdcProgressBar)).width, 120);
    });

    testWidgets('grid body consumes residual height before footer panels', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: List<Map<String, Object?>>.generate(40, (index) {
            return <String, Object?>{'id': index + 1, 'name': 'Name $index'};
          }),
        ),
      );
      dataSet.open();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 227,
              child: FdcGrid(
                dataSet: dataSet,
                toolbar: const FdcGridToolbar(visible: false),
                header: const FdcGridHeader(
                  height: 32,
                  filters: FdcGridHeaderFilters(initiallyVisible: false),
                ),
                options: const FdcGridOptions(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                  verticalScrollMode: FdcGridVerticalScrollMode.smooth,
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                  FdcIntegerColumn(
                    fieldName: 'id',
                    width: 100,
                    summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
                  ),
                ],
                statusBar: const FdcGridStatusBar(visible: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bodyHeight = tester.getSize(find.byType(FdcGridBodyRow)).height;

      // 227 total - 32 header - 36 summary - 28 status bar - 4 frame inset.
      // This is intentionally not snapped down to whole row height; otherwise
      // the 19px remainder would appear as a footer-adjacent gap.
      expect(bodyHeight, closeTo(127, 0.1));
    });

    testWidgets('record-scroll body keeps whole-row footer gap', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: List<Map<String, Object?>>.generate(40, (index) {
            return <String, Object?>{'id': index + 1, 'name': 'Name $index'};
          }),
        ),
      );
      dataSet.open();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 227,
              child: FdcGrid(
                dataSet: dataSet,
                toolbar: const FdcGridToolbar(visible: false),
                header: const FdcGridHeader(
                  height: 32,
                  filters: FdcGridHeaderFilters(initiallyVisible: false),
                ),
                options: const FdcGridOptions(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                  FdcIntegerColumn(
                    fieldName: 'id',
                    width: 100,
                    summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
                  ),
                ],
                statusBar: const FdcGridStatusBar(visible: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bodyHeight = tester.getSize(find.byType(FdcGridBodyRow)).height;

      // Record-scroll mode keeps a whole-row viewport so snapping/navigation
      // never leaves a partial trailing row above footer panels.
      expect(bodyHeight, closeTo(108, 0.1));
    });

    testWidgets(
      'grid hides default summary row when no column has an aggregate',
      (tester) async {
        final dataSet = _peopleDataSet();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 480,
                height: 220,
                child: FdcGrid(
                  dataSet: dataSet,
                  header: const FdcGridHeader(height: 32),
                  columns: const <FdcGridColumn<dynamic>>[
                    FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                    FdcIntegerColumn(fieldName: 'id', width: 100),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('fdc_grid_summary_row')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'paged summary aggregate load does not notify progress during build',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              for (var i = 1; i <= 25; i++)
                <String, Object?>{'id': i, 'amount': i * 10.0},
            ],
          ),
          paging: const FdcDataPagingOptions(
            enabled: true,
            pageSize: 10,
            requireTotalCount: true,
          ),
        );
        await dataSet.open();

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn(fieldName: 'id', width: 80),
            FdcDecimalColumn<dynamic>(
              fieldName: 'amount',
              width: 140,
              summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
            ),
          ],
          statusBar: const FdcGridStatusBar(visible: true),
          width: 360,
          height: 220,
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('fdc_grid_status_progress')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'paged summary keeps displayed value while empty filtered page reloads',
      (tester) async {
        final adapter = _EmptyFilteredPagedSummaryAdapter();
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcStringField(size: 20, name: 'status'),
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],
          adapter: adapter,
          paging: const FdcDataPagingOptions(
            enabled: true,
            pageSize: 10,
            requireTotalCount: true,
          ),
        );
        await dataSet.open();

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn(fieldName: 'id', width: 80),
            FdcTextColumn<dynamic>(fieldName: 'status', width: 100),
            FdcDecimalColumn<dynamic>(
              fieldName: 'amount',
              width: 120,
              summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
            ),
          ],
          width: 360,
          height: 220,
        );
        await tester.pumpAndSettle();

        final summaryRowFinder = find.byKey(
          const ValueKey('fdc_grid_summary_row'),
        );
        expect(
          find.descendant(of: summaryRowFinder, matching: find.text('300.00')),
          findsOneWidget,
        );

        adapter.filteredAggregateGate = Completer<FdcDataAggregateResult>();
        final filterFuture = dataSet.filter
            .where('status')
            .equals('missing')
            .apply();
        await tester.pumpAndSettle();
        await filterFuture;

        expect(dataSet.recordCount, 0);
        expect(
          find.descendant(of: summaryRowFinder, matching: find.text('300.00')),
          findsOneWidget,
        );

        adapter.filteredAggregateGate!.complete(
          _EmptyFilteredPagedSummaryAdapter._aggregateResult('0.00'),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(of: summaryRowFinder, matching: find.text('0.00')),
          findsOneWidget,
        );
      },
    );

    testWidgets('grid summary row renders between viewport and status bar', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 220,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(height: 32),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                  FdcIntegerColumn(
                    fieldName: 'id',
                    width: 100,
                    summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
                  ),
                ],
                options: const FdcGridOptions(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                ),
                statusBar: const FdcGridStatusBar(visible: true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final summaryRowFinder = find.byKey(
        const ValueKey('fdc_grid_summary_row'),
      );
      final statusBarFinder = find.byKey(const ValueKey('fdc_grid_status_bar'));

      expect(summaryRowFinder, findsOneWidget);
      expect(statusBarFinder, findsOneWidget);
      expect(tester.getSize(summaryRowFinder).height, 36);
      expect(
        tester.getTopLeft(summaryRowFinder).dy,
        lessThan(tester.getTopLeft(statusBarFinder).dy),
      );

      final summaryRowBox = tester.widget<DecoratedBox>(summaryRowFinder);
      final summaryDecoration = summaryRowBox.decoration as BoxDecoration;
      final summaryBorder = summaryDecoration.border as Border;

      expect(summaryBorder.top, isNot(BorderSide.none));
      expect(summaryBorder.top.color, isNot(Colors.transparent));
      expect(summaryBorder.bottom, BorderSide.none);
    });

    testWidgets('grid summary row does not draw a bottom border', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 220,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(height: 32),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                  FdcIntegerColumn(
                    fieldName: 'id',
                    width: 100,
                    summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
                  ),
                ],
                options: const FdcGridOptions(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final summaryRowFinder = find.byKey(
        const ValueKey('fdc_grid_summary_row'),
      );
      final summaryRowBox = tester.widget<DecoratedBox>(summaryRowFinder);
      final summaryDecoration = summaryRowBox.decoration as BoxDecoration;
      final summaryBorder = summaryDecoration.border as Border;

      expect(summaryBorder.top, isNot(BorderSide.none));
      expect(summaryBorder.bottom, BorderSide.none);
    });

    testWidgets('grid summary row can hide top separator', (tester) async {
      final dataSet = _peopleDataSet();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 480,
              height: 220,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(height: 32),
                options: const FdcGridOptions(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                  FdcIntegerColumn(
                    fieldName: 'id',
                    width: 100,
                    summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
                  ),
                ],
                summary: const FdcGridSummary(
                  style: FdcGridSummaryStyle(showTopSeparator: false),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final summaryRowFinder = find.byKey(
        const ValueKey('fdc_grid_summary_row'),
      );
      final summaryRowBox = tester.widget<DecoratedBox>(summaryRowFinder);
      final summaryDecoration = summaryRowBox.decoration as BoxDecoration;
      final summaryBorder = summaryDecoration.border as Border;

      expect(summaryBorder.top, BorderSide.none);
      expect(summaryBorder.bottom, BorderSide.none);
    });

    testWidgets('grid summary row shows configured aggregates', (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'quantity'),
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          FdcDateField(name: 'created'),
          FdcDateTimeField(name: 'updatedAt'),
          FdcTimeField(name: 'startedAt'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {
              'quantity': 2,
              'amount': 10.25,
              'created': DateTime(2026, 1, 3),
              'updatedAt': DateTime(2026, 1, 3, 10, 30),
              'startedAt': FdcTime(hour: 9, minute: 45),
            },
            {
              'quantity': 3,
              'amount': 20.50,
              'created': DateTime(2026),
              'updatedAt': DateTime(2026, 1, 1, 8, 15),
              'startedAt': FdcTime(hour: 7, minute: 30),
            },
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn(
            fieldName: 'quantity',
            width: 100,
            summary: FdcColumnSummary(
              aggregate: FdcAggregate.sum,
              style: FdcGridSummaryCellStyle(alignment: Alignment.centerLeft),
            ),
          ),
          FdcDecimalColumn<dynamic>(
            fieldName: 'amount',
            width: 120,
            summary: FdcColumnSummary(aggregate: FdcAggregate.avg),
          ),
          FdcDateColumn<dynamic>(
            fieldName: 'created',
            width: 120,
            summary: FdcColumnSummary(aggregate: FdcAggregate.min),
          ),
          FdcDateTimeColumn<dynamic>(
            fieldName: 'updatedAt',
            width: 150,
            summary: FdcColumnSummary(aggregate: FdcAggregate.min),
          ),
          FdcDateTimeColumn<dynamic>(
            fieldName: 'updatedAt',
            width: 150,
            summary: FdcColumnSummary(aggregate: FdcAggregate.max),
          ),
          FdcTimeColumn<dynamic>(
            fieldName: 'startedAt',
            width: 100,
            summary: FdcColumnSummary(aggregate: FdcAggregate.min),
          ),
          FdcTimeColumn<dynamic>(
            fieldName: 'startedAt',
            width: 100,
            summary: FdcColumnSummary(aggregate: FdcAggregate.max),
          ),
        ],
        formatSettings: const FdcFormatSettings(),
        width: 620,
        height: 220,
      );

      final summaryRowFinder = find.byKey(
        const ValueKey('fdc_grid_summary_row'),
      );
      expect(summaryRowFinder, findsOneWidget);
      expect(
        find.descendant(of: summaryRowFinder, matching: find.text('5')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: summaryRowFinder, matching: find.text('15.38')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: summaryRowFinder,
          matching: find.text('2026-01-01'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: summaryRowFinder,
          matching: find.text('2026-01-01 08:15'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: summaryRowFinder,
          matching: find.text('2026-01-03 10:30'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: summaryRowFinder, matching: find.text('07:30')),
        findsOneWidget,
      );

      // Summary cells are horizontally virtualized. Scroll the summary row
      // before asserting values that start outside the initial viewport.
      await tester.drag(summaryRowFinder, const Offset(-220, 0));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: summaryRowFinder, matching: find.text('09:45')),
        findsOneWidget,
      );
    });

    testWidgets('grid summary row popup changes aggregate at runtime', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'amount': 10.25},
            {'amount': 20.50},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(
            fieldName: 'amount',
            width: 120,
            summary: FdcColumnSummary(
              aggregate: FdcAggregate.avg,
              allowAggregateChange: true,
            ),
          ),
        ],
        width: 220,
        height: 200,
      );

      final summaryRowFinder = find.byKey(
        const ValueKey('fdc_grid_summary_row'),
      );
      expect(
        find.descendant(of: summaryRowFinder, matching: find.text('15.38')),
        findsOneWidget,
      );

      await tester.tapAt(
        tester.getTopLeft(summaryRowFinder) + const Offset(10, 18),
      );
      await tester.pumpAndSettle();
      expect(find.text('Max'), findsNothing);

      await tester.tap(find.text('15.38'));
      await tester.pumpAndSettle();
      expect(find.text('Max'), findsOneWidget);
      expect(find.text('None'), findsNothing);

      await tester.tap(find.text('Max'));
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: summaryRowFinder, matching: find.text('Max 20.50')),
        findsOneWidget,
      );
    });

    testWidgets(
      'grid summary row does not open aggregate menu when dataset is closed',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'amount': 10.25},
              {'amount': 20.50},
            ],
          ),
        );
        expect(dataSet.isOpen, isFalse);

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDecimalColumn<dynamic>(
              fieldName: 'amount',
              width: 120,
              summary: FdcColumnSummary(
                aggregate: FdcAggregate.avg,
                label: 'Total',
                allowAggregateChange: true,
              ),
            ),
          ],
          width: 220,
          height: 200,
        );

        final summaryRowFinder = find.byKey(
          const ValueKey('fdc_grid_summary_row'),
        );
        expect(summaryRowFinder, findsOneWidget);
        expect(
          find.descendant(
            of: summaryRowFinder,
            matching: find.text('Total 0.00'),
          ),
          findsOneWidget,
        );

        await tester.tapAt(
          tester.getTopLeft(summaryRowFinder) + const Offset(10, 18),
        );
        await tester.pumpAndSettle();

        expect(find.text('Max'), findsNothing);
        expect(find.text('Min'), findsNothing);
        expect(find.text('Sum'), findsNothing);
      },
    );

    testWidgets(
      'grid summary row formats closed dataset numeric fallback values',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'quantity'),
            FdcDecimalField(name: 'amount', precision: 12, scale: 3),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'quantity': 2, 'amount': 10.25},
              {'quantity': 3, 'amount': 20.50},
            ],
          ),
        );
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(
              fieldName: 'quantity',
              width: 120,
              summary: FdcColumnSummary(
                aggregate: FdcAggregate.sum,
                label: 'Qty',
              ),
            ),
            FdcDecimalColumn<dynamic>(
              fieldName: 'amount',
              width: 120,
              summary: FdcColumnSummary(
                aggregate: FdcAggregate.sum,
                label: 'Amount',
              ),
            ),
          ],
          width: 300,
          height: 200,
        );

        final summaryRowFinder = find.byKey(
          const ValueKey('fdc_grid_summary_row'),
        );
        expect(
          find.descendant(of: summaryRowFinder, matching: find.text('Qty 0')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: summaryRowFinder,
            matching: find.text('Amount 0.000'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'grid summary row hides closed dataset date aggregate fallback values',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcDateField(name: 'due_date')],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'due_date': DateTime(2026, 1, 10)},
              {'due_date': DateTime(2026, 1, 20)},
            ],
          ),
        );
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDateColumn<dynamic>(
              fieldName: 'due_date',
              width: 140,
              summary: FdcColumnSummary(
                aggregate: FdcAggregate.min,
                label: 'Earliest',
              ),
            ),
          ],
          width: 220,
          height: 200,
        );

        final summaryRowFinder = find.byKey(
          const ValueKey('fdc_grid_summary_row'),
        );
        expect(summaryRowFinder, findsOneWidget);
        expect(
          find.descendant(of: summaryRowFinder, matching: find.text('0')),
          findsNothing,
        );
        expect(
          find.descendant(of: summaryRowFinder, matching: find.text('0.00')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'grid summary row restores configured label for default aggregate',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'quantity'),
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'quantity': 2, 'amount': 10.25},
              {'quantity': 3, 'amount': 20.50},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn(
              fieldName: 'quantity',
              width: 120,
              summary: FdcColumnSummary(
                aggregate: FdcAggregate.sum,
                label: 'Items',
              ),
            ),
            FdcDecimalColumn<dynamic>(
              fieldName: 'amount',
              width: 140,
              summary: FdcColumnSummary(
                aggregate: FdcAggregate.avg,
                label: 'Total',
                allowAggregateChange: true,
              ),
            ),
          ],
          width: 320,
          height: 200,
        );

        final summaryRowFinder = find.byKey(
          const ValueKey('fdc_grid_summary_row'),
        );
        Finder summaryText(String text) {
          return find.descendant(
            of: summaryRowFinder,
            matching: find.byWidgetPredicate((widget) {
              if (widget is! Text) {
                return false;
              }
              return (widget.data ?? widget.textSpan?.toPlainText()) == text;
            }),
          );
        }

        expect(summaryText('Items 5'), findsOneWidget);
        expect(summaryText('Total 15.38'), findsOneWidget);

        await tester.tap(summaryText('Total 15.38'));
        await tester.pumpAndSettle();
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Max'), findsOneWidget);
        await tester.tap(find.text('Max'));
        await tester.pumpAndSettle();
        expect(summaryText('Max 20.50'), findsOneWidget);

        await tester.tap(summaryText('Max 20.50'));
        await tester.pumpAndSettle();
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Avg'), findsNothing);
        await tester.tap(find.text('Total'));
        await tester.pumpAndSettle();
        expect(summaryText('Total 15.38'), findsOneWidget);
      },
    );

    testWidgets(
      'grid summary row shows runtime aggregate label without configured summary label',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'amount': 10.25},
              {'amount': 20.50},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDecimalColumn<dynamic>(
              fieldName: 'amount',
              width: 140,
              summary: FdcColumnSummary(
                aggregate: FdcAggregate.avg,
                allowAggregateChange: true,
              ),
            ),
          ],
          width: 180,
          height: 200,
        );

        final summaryRowFinder = find.byKey(
          const ValueKey('fdc_grid_summary_row'),
        );
        Finder summaryText(String text) {
          return find.descendant(
            of: summaryRowFinder,
            matching: find.byWidgetPredicate((widget) {
              if (widget is! Text) {
                return false;
              }
              return (widget.data ?? widget.textSpan?.toPlainText()) == text;
            }),
          );
        }

        expect(summaryText('15.38'), findsOneWidget);

        await tester.tap(summaryText('15.38'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Max'));
        await tester.pumpAndSettle();
        expect(summaryText('Max 20.50'), findsOneWidget);
      },
    );

    testWidgets(
      'grid summary row hides configured and runtime labels when disabled',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'amount': 10.25},
              {'amount': 20.50},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDecimalColumn<dynamic>(
              fieldName: 'amount',
              width: 140,
              summary: FdcColumnSummary(
                aggregate: FdcAggregate.avg,
                label: 'Total',
                labelVisible: false,
                allowAggregateChange: true,
              ),
            ),
          ],
          width: 180,
          height: 200,
        );

        final summaryRowFinder = find.byKey(
          const ValueKey('fdc_grid_summary_row'),
        );
        Finder summaryText(String text) {
          return find.descendant(
            of: summaryRowFinder,
            matching: find.byWidgetPredicate((widget) {
              if (widget is! Text) {
                return false;
              }
              return (widget.data ?? widget.textSpan?.toPlainText()) == text;
            }),
          );
        }

        expect(summaryText('15.38'), findsOneWidget);
        expect(summaryText('Total 15.38'), findsNothing);
        expect(find.text('Total'), findsNothing);

        await tester.tap(summaryText('15.38'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Max'));
        await tester.pumpAndSettle();

        expect(summaryText('20.50'), findsOneWidget);
        expect(summaryText('Max 20.50'), findsNothing);
      },
    );

    testWidgets('grid summary row can left-align label inside the cell', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'amount': 10.25},
            {'amount': 20.50},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(
            fieldName: 'amount',
            width: 180,
            summary: FdcColumnSummary(
              aggregate: FdcAggregate.avg,
              label: 'Total',
              labelAlignment: FdcSummaryLabelAlignment.startAligned,
            ),
          ),
        ],
        width: 220,
        height: 200,
      );

      final summaryRowFinder = find.byKey(
        const ValueKey('fdc_grid_summary_row'),
      );
      final labelFinder = find.descendant(
        of: summaryRowFinder,
        matching: find.text('Total'),
      );
      final valueFinder = find.descendant(
        of: summaryRowFinder,
        matching: find.text('15.38'),
      );

      expect(labelFinder, findsOneWidget);
      expect(valueFinder, findsOneWidget);
      expect(
        tester.getTopLeft(labelFinder).dx,
        lessThan(tester.getTopLeft(valueFinder).dx),
      );
    });

    testWidgets(
      'grid summary row shows left-aligned label for left-aligned value',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'amount': 10.25},
              {'amount': 20.50},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDecimalColumn<dynamic>(
              fieldName: 'amount',
              width: 180,
              summary: FdcColumnSummary(
                aggregate: FdcAggregate.avg,
                label: 'Total',
                labelAlignment: FdcSummaryLabelAlignment.startAligned,
                style: FdcGridSummaryCellStyle(alignment: Alignment.centerLeft),
              ),
            ),
          ],
          width: 220,
          height: 200,
        );

        final summaryRowFinder = find.byKey(
          const ValueKey('fdc_grid_summary_row'),
        );
        final labelFinder = find.descendant(
          of: summaryRowFinder,
          matching: find.text('Total'),
        );
        final valueFinder = find.descendant(
          of: summaryRowFinder,
          matching: find.text('15.38'),
        );

        expect(labelFinder, findsOneWidget);
        expect(valueFinder, findsOneWidget);
        expect(
          tester.getTopLeft(labelFinder).dx,
          lessThan(tester.getTopLeft(valueFinder).dx),
        );
      },
    );

    testWidgets(
      'grid summary row hides left-aligned label before it overlaps value',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'amount': 10.25},
              {'amount': 20.50},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDecimalColumn<dynamic>(
              fieldName: 'amount',
              width: 80,
              summary: FdcColumnSummary(
                aggregate: FdcAggregate.avg,
                label: 'Very Long Total Label',
                labelAlignment: FdcSummaryLabelAlignment.startAligned,
              ),
            ),
          ],
          width: 120,
          height: 200,
        );

        final summaryRowFinder = find.byKey(
          const ValueKey('fdc_grid_summary_row'),
        );

        expect(
          find.descendant(
            of: summaryRowFinder,
            matching: find.text('Very Long Total Label'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(of: summaryRowFinder, matching: find.text('15.38')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'grid summary row emits meta warning for unsupported aggregate',
      (tester) async {
        final originalDebugPrint = debugPrint;
        final messages = <String>[];
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) {
            messages.add(message);
          }
        };

        try {
          final dataSet = FdcDataSet(
            fields: const <FdcFieldDef>[FdcDateField(name: 'created')],

            adapter: FdcMemoryDataAdapter(
              rows: <Map<String, Object?>>[
                {'created': DateTime(2026)},
              ],
            ),
          );
          dataSet.open();

          await _pumpGrid(
            tester,
            dataSet: dataSet,
            columns: const <FdcGridColumn<dynamic>>[
              FdcDateColumn<dynamic>(
                fieldName: 'created',
                width: 120,
                summary: FdcColumnSummary(aggregate: FdcAggregate.avg),
              ),
            ],
            width: 180,
            height: 180,
          );

          final summaryRowFinder = find.byKey(
            const ValueKey('fdc_grid_summary_row'),
          );
          expect(
            find.descendant(of: summaryRowFinder, matching: find.text('N/A')),
            findsOneWidget,
          );

          final warnings = messages
              .where(
                (message) =>
                    message.contains('[FDC-META-WARNING]') &&
                    message.contains('FdcAggregate.avg') &&
                    message.contains('type date'),
              )
              .toList(growable: false);
          expect(warnings, hasLength(1));
        } finally {
          debugPrint = originalDebugPrint;
        }
      },
    );

    testWidgets(
      'grid summary row draws vertical dividers only for aggregated columns',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(name: 'name', size: 50),
            FdcIntegerField(name: 'quantity'),
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'name': 'A', 'quantity': 2, 'amount': 10.25},
              {'name': 'B', 'quantity': 3, 'amount': 20.50},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', width: 100),
            FdcIntegerColumn(
              fieldName: 'quantity',
              width: 100,
              summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
            ),
            FdcDecimalColumn<dynamic>(
              fieldName: 'amount',
              width: 100,
              summary: FdcColumnSummary(aggregate: FdcAggregate.avg),
            ),
          ],
          width: 360,
          height: 220,
        );

        final summaryCellIds = tester
            .widgetList<Widget>(
              find.byWidgetPredicate(_isSummaryCellPositionWidget),
            )
            .map(
              (widget) => (widget.key! as ValueKey<Object?>).value
                  .toString()
                  .replaceFirst('fdc-grid-summary-cell-', ''),
            )
            .toList(growable: false);
        expect(summaryCellIds, hasLength(3));

        Finder leftSeparator(String id) => find.byKey(
          ValueKey<Object?>('fdc-grid-summary-cell-$id-left-separator'),
        );
        Finder rightSeparator(String id) => find.byKey(
          ValueKey<Object?>('fdc-grid-summary-cell-$id-right-separator'),
        );

        expect(leftSeparator(summaryCellIds[0]), findsNothing);
        expect(rightSeparator(summaryCellIds[0]), findsNothing);
        expect(leftSeparator(summaryCellIds[1]), findsOneWidget);
        expect(rightSeparator(summaryCellIds[1]), findsOneWidget);
        expect(leftSeparator(summaryCellIds[2]), findsNothing);
        expect(rightSeparator(summaryCellIds[2]), findsOneWidget);
      },
    );

    testWidgets('grid summary row applies vertical separator style', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'quantity')],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'quantity': 2},
            {'quantity': 3},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn(
            fieldName: 'quantity',
            width: 100,
            summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
          ),
        ],
        summary: const FdcGridSummary(
          style: FdcGridSummaryStyle(verticalSeparatorInset: 4),
        ),
        width: 180,
        height: 220,
      );

      final rightSeparator = tester.widget<Positioned>(
        find.byWidgetPredicate((widget) {
          final key = widget.key;
          return widget is Positioned &&
              key is ValueKey<Object?> &&
              key.value.toString().endsWith('-right-separator');
        }),
      );
      expect(rightSeparator.top, 4);
      expect(rightSeparator.bottom, 4);

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn(
            fieldName: 'quantity',
            width: 100,
            summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
          ),
        ],
        summary: const FdcGridSummary(
          style: FdcGridSummaryStyle(showVerticalSeparators: false),
        ),
        width: 180,
        height: 220,
      );

      expect(
        find.byWidgetPredicate((widget) {
          final key = widget.key;
          return widget is Positioned &&
              key is ValueKey<Object?> &&
              key.value.toString().endsWith('-right-separator');
        }),
        findsNothing,
      );
    });

    testWidgets('grid summary row supports horizontal drag scrolling', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'c1'),
          FdcIntegerField(name: 'c2'),
          FdcIntegerField(name: 'c3'),
          FdcIntegerField(name: 'c4'),
          FdcIntegerField(name: 'c5'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'c1': 1, 'c2': 2, 'c3': 3, 'c4': 4, 'c5': 5},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn(
            fieldName: 'c1',
            width: 140,
            summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
          ),
          FdcIntegerColumn(
            fieldName: 'c2',
            width: 140,
            summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
          ),
          FdcIntegerColumn(
            fieldName: 'c3',
            width: 140,
            summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
          ),
          FdcIntegerColumn(
            fieldName: 'c4',
            width: 140,
            summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
          ),
          FdcIntegerColumn(
            fieldName: 'c5',
            width: 140,
            summary: FdcColumnSummary(aggregate: FdcAggregate.sum),
          ),
        ],
        width: 260,
        height: 220,
      );

      final firstSummaryCellId = tester
          .widgetList<Widget>(
            find.byWidgetPredicate(_isSummaryCellPositionWidget),
          )
          .map(
            (widget) => (widget.key! as ValueKey<Object?>).value
                .toString()
                .replaceFirst('fdc-grid-summary-cell-', ''),
          )
          .first;
      final firstCellFinder = find.byKey(
        ValueKey<Object?>('fdc-grid-summary-cell-$firstSummaryCellId'),
      );
      final before = tester.getTopLeft(firstCellFinder).dx;

      await tester.drag(
        find.byKey(const ValueKey('fdc_grid_summary_row')),
        const Offset(-160, 0),
      );
      await tester.pumpAndSettle();

      final after = tester.getTopLeft(firstCellFinder).dx;
      expect(after, lessThan(before - 20));
    });
  });
}
