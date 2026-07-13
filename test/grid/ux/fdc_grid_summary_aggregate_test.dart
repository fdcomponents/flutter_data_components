import 'fdc_grid_ux_test_support.dart';

void _registerSummaryAggregateTests() {
  group('Summary aggregates', () {
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

      await uxPumpGrid(
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
      await uxPumpPendingFrames(tester);

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

      await uxPumpGrid(
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
      await uxPumpPendingFrames(tester);
      expect(find.text('Max'), findsNothing);

      await tester.tap(find.text('15.38'));
      await uxPumpPendingFrames(tester);
      expect(find.text('Max'), findsOneWidget);
      expect(find.text('None'), findsNothing);

      await tester.tap(find.text('Max'));
      await uxPumpPendingFrames(tester);
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

        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);

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
        await uxPumpGrid(
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
        await uxPumpGrid(
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
        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Max'), findsOneWidget);
        await tester.tap(find.text('Max'));
        await uxPumpPendingFrames(tester);
        expect(summaryText('Max 20.50'), findsOneWidget);

        await tester.tap(summaryText('Max 20.50'));
        await uxPumpPendingFrames(tester);
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Avg'), findsNothing);
        await tester.tap(find.text('Total'));
        await uxPumpPendingFrames(tester);
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
        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Max'));
        await uxPumpPendingFrames(tester);
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
        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Max'));
        await uxPumpPendingFrames(tester);

        expect(summaryText('20.50'), findsOneWidget);
        expect(summaryText('Max 20.50'), findsNothing);
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Summary Aggregate', () {
    _registerSummaryAggregateTests();
  });
}
