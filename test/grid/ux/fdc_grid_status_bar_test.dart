import 'fdc_grid_ux_test_support.dart';

void _registerStatusBarTests() {
  group('Status bar', () {
    testWidgets('grid status bar shows record count and dataset state', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();

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
      await uxPumpPendingFrames(tester);

      expect(find.textContaining('Record 1 of 2'), findsOneWidget);
      expect(find.textContaining('State: Browse'), findsOneWidget);

      dataSet.edit();
      await uxPumpPendingFrames(tester);

      expect(find.textContaining('State: Edit'), findsOneWidget);
    });

    testWidgets('grid status bar listens to dataset record changes', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();

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
      await uxPumpPendingFrames(tester);

      expect(find.textContaining('Record 1 of 2'), findsOneWidget);

      dataSet.moveToRecord(2);
      await uxPumpPendingFrames(tester);

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
      await uxPumpPendingFrames(tester);

      expect(find.textContaining('Record 11 of 25'), findsOneWidget);

      dataSet.moveToRecord(3);
      await uxPumpPendingFrames(tester);

      expect(find.textContaining('Record 13 of 25'), findsOneWidget);
    });

    testWidgets('grid status bar shows filtered and sorted indicators', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();
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
      await uxPumpPendingFrames(tester);

      expect(find.textContaining('Record 1 of 1'), findsOneWidget);
      expect(find.textContaining('Filtered'), findsOneWidget);
      expect(find.textContaining('Sorted'), findsOneWidget);
    });

    testWidgets('grid status bar style defaults to header background', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();
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
      await uxPumpPendingFrames(tester);

      final statusBarBox = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('fdc_grid_status_bar')),
      );
      final decoration = statusBarBox.decoration as BoxDecoration;

      expect(decoration.color, headerBackground);
    });

    testWidgets('grid status bar uses component-owned style override', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();
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
      await uxPumpPendingFrames(tester);

      final statusBarFinder = find.byKey(const ValueKey('fdc_grid_status_bar'));
      final statusBarBox = tester.widget<DecoratedBox>(statusBarFinder);
      final decoration = statusBarBox.decoration as BoxDecoration;

      expect(decoration.color, statusBarBackground);
      expect(tester.getSize(statusBarFinder).height, 30);
    });

    testWidgets('grid status bar owns progress bar visibility', (tester) async {
      final dataSet = uxPeopleDataSet();

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
      await uxPumpPendingFrames(tester);

      expect(find.byKey(const ValueKey('fdc_grid_status_bar')), findsOneWidget);
      expect(find.byType(FdcProgressBar), findsNothing);
    });

    testWidgets('grid status bar owns progress bar width', (tester) async {
      final dataSet = uxPeopleDataSet();

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
      await uxPumpPendingFrames(tester);

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
      await uxPumpPendingFrames(tester);

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
      await uxPumpPendingFrames(tester);

      final bodyHeight = tester.getSize(find.byType(FdcGridBodyRow)).height;

      // Record-scroll mode keeps a whole-row viewport so snapping/navigation
      // never leaves a partial trailing row above footer panels.
      expect(bodyHeight, closeTo(108, 0.1));
    });
  });
}

void main() {
  group('FdcGrid widget UX / Status Bar', () {
    _registerStatusBarTests();
  });
}
