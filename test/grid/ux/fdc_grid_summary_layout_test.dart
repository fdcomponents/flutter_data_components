import 'fdc_grid_ux_test_support.dart';

void _registerSummaryLayoutTests() {
  group('Summary layout and diagnostics', () {
    testWidgets('grid summary row renders between viewport and status bar', (
      tester,
    ) async {
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
      await uxPumpPendingFrames(tester);

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
      await uxPumpPendingFrames(tester);

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
      await uxPumpPendingFrames(tester);

      final summaryRowFinder = find.byKey(
        const ValueKey('fdc_grid_summary_row'),
      );
      final summaryRowBox = tester.widget<DecoratedBox>(summaryRowFinder);
      final summaryDecoration = summaryRowBox.decoration as BoxDecoration;
      final summaryBorder = summaryDecoration.border as Border;

      expect(summaryBorder.top, BorderSide.none);
      expect(summaryBorder.bottom, BorderSide.none);
    });

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

      await uxPumpGrid(
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
        await uxPumpGrid(
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
        await uxPumpGrid(
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

          await uxPumpGrid(
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
          expect(
            warnings,
            hasLength(1),
            reason:
                'Unsupported date AVG should emit exactly one metadata warning.',
          );
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
        await uxPumpGrid(
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
              find.byWidgetPredicate(uxIsSummaryCellPositionWidget),
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

      await uxPumpGrid(
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

      await uxPumpGrid(
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

      await uxPumpGrid(
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
            find.byWidgetPredicate(uxIsSummaryCellPositionWidget),
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
      await uxPumpPendingFrames(tester);

      final after = tester.getTopLeft(firstCellFinder).dx;
      expect(after, lessThan(before - 20));
    });
  });
}

void main() {
  group('FdcGrid widget UX / Summary Layout', () {
    _registerSummaryLayoutTests();
  });
}
