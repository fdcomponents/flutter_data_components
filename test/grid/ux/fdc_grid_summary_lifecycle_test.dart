import 'fdc_grid_ux_test_support.dart';

void _registerSummaryLifecycleTests() {
  group('Summary lifecycle', () {
    testWidgets(
      'grid hides default summary row when no column has an aggregate',
      (tester) async {
        final dataSet = uxPeopleDataSet();

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
        await uxPumpPendingFrames(tester);

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

        await uxPumpGrid(
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
        final adapter = UxEmptyFilteredPagedSummaryAdapter();
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

        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);

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
        await uxPumpPendingFrames(tester);
        await filterFuture;

        expect(dataSet.recordCount, 0);
        expect(
          find.descendant(of: summaryRowFinder, matching: find.text('300.00')),
          findsOneWidget,
        );

        adapter.filteredAggregateGate!.complete(
          UxEmptyFilteredPagedSummaryAdapter.uxAggregateResult('0.00'),
        );
        await uxPumpPendingFrames(tester);

        expect(
          find.descendant(of: summaryRowFinder, matching: find.text('0.00')),
          findsOneWidget,
        );
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Summary Lifecycle', () {
    _registerSummaryLifecycleTests();
  });
}
