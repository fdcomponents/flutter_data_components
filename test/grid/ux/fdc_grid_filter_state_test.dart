import 'fdc_grid_ux_test_support.dart';

void _registerFilterStateTests() {
  group('Filter state and application', () {
    testWidgets('main grid menu hides column filters and clears active filters', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha'},
            {'name': 'Beta'},
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
        rowIndicator: const FdcGridRowIndicator(
          visible: true,
          options: FdcGridRowIndicatorOptions(showRowNumbers: true),
        ),
      );

      expect(find.byType(EditableText), findsNothing);

      await tester.tap(find.byIcon(Icons.menu));
      await uxPumpPendingFrames(tester);

      expect(find.text('Show filters'), findsOneWidget);
      expect(find.text('Hide filters'), findsNothing);

      await tester.tap(find.text('Show filters'));
      await uxPumpPendingFrames(tester);

      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'Alpha');
      await uxPumpPendingFrames(tester);

      // The filter editor still contains "Alpha" while the matching row is visible.
      expect(find.text('Alpha'), findsNWidgets(2));
      expect(find.text('Beta'), findsNothing);

      await tester.tap(find.byIcon(Icons.menu));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Hide filters'));
      await uxPumpPendingFrames(tester);

      expect(find.byType(EditableText), findsNothing);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu));
      await uxPumpPendingFrames(tester);

      expect(find.text('Show filters'), findsOneWidget);
      expect(find.text('Clear filters'), findsNothing);
    });

    testWidgets(
      'hide filters without active filters stays a layout action during dirty edit',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
          beforePost: (dataSet) {
            throw FdcDataSetAbortException('Post is not allowed.');
          },

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha'},
              {'name': 'Beta'},
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
          header: uxZeroDebounceHeader,
        );

        dataSet.edit();
        dataSet.setFieldValue('name', 'Changed');
        await uxPumpPendingFrames(tester);

        await tester.tap(find.byIcon(Icons.menu));
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Hide filters'));
        await uxPumpPendingFrames(tester);

        expect(find.text('Post is not allowed.'), findsNothing);
        expect(dataSet.state, FdcDataSetState.edit);
        expect(find.byType(EditableText), findsNothing);

        await tester.tap(find.byIcon(Icons.menu));
        await uxPumpPendingFrames(tester);
        expect(find.text('Show filters'), findsOneWidget);
      },
    );

    testWidgets(
      'hide filters is blocked while dirty edit would make it clear active filters',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
          beforePost: (dataSet) {
            throw FdcDataSetAbortException('Post is not allowed.');
          },

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha'},
              {'name': 'Beta'},
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
          header: uxZeroDebounceHeader,
        );

        await tester.enterText(find.byType(EditableText), 'Alpha');
        await uxPumpPendingFrames(tester);
        expect(find.text('Beta'), findsNothing);

        dataSet.edit();
        dataSet.setFieldValue('name', 'Changed');
        await uxPumpPendingFrames(tester);

        await tester.tap(find.byIcon(Icons.menu));
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Hide filters'));
        await uxPumpPendingFrames(tester);

        expect(find.text('Post is not allowed.'), findsNothing);
        expect(dataSet.state, FdcDataSetState.edit);
        expect(find.text('Beta'), findsNothing);
      },
    );

    testWidgets(
      'allowColumnFiltering disables grid filter UI without blocking dataset filters',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha'},
              {'name': 'Beta'},
            ],
          ),
        );
        dataSet.open();
        dataSet.filter.where('name').equals('Alpha').apply();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          options: const FdcGridOptions(allowColumnFiltering: false),
          rowIndicator: const FdcGridRowIndicator(
            visible: true,
            options: FdcGridRowIndicatorOptions(showRowNumbers: true),
          ),
        );

        expect(find.byType(EditableText), findsNothing);
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsNothing);

        expect(find.byIcon(Icons.menu), findsNothing);
        expect(find.text('Show filters'), findsNothing);
        expect(find.text('Hide filters'), findsNothing);
        expect(find.text('Clear filters'), findsNothing);
      },
    );

    testWidgets('main menu clear filters uses dataset filter state', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha'},
            {'name': 'Beta'},
          ],
        ),
      );
      dataSet.open();
      dataSet.filter.where('name').equals('Alpha').apply();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        header: uxZeroDebounceHeader,
      );

      expect(dataSet.filter.active, isTrue);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);

      await tester.tap(find.byIcon(Icons.menu));
      await uxPumpPendingFrames(tester);

      expect(find.text('Clear filters'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.filter.active, isFalse);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('main menu clear all sorts uses dataset sort state', (
      tester,
    ) async {
      const selectedColor = Colors.cyan;
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Beta'},
            {'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();
      dataSet.sort.sortBy('name').ascending.apply();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        rowIndicator: const FdcGridRowIndicator(
          visible: true,
          options: FdcGridRowIndicatorOptions(showRowNumbers: true),
        ),
        header: uxZeroDebounceHeader,
        style: const FdcGridStyle(selectedCellBackgroundColor: selectedColor),
      );

      int selectedCellBackgroundCount() {
        return tester.widgetList<Container>(find.byType(Container)).where((
          container,
        ) {
          final decoration = container.decoration;
          return decoration is BoxDecoration &&
              decoration.color == selectedColor;
        }).length;
      }

      expect(dataSet.sort.active, isTrue);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Alpha');

      await tester.tap(find.text('Alpha').first);
      await uxPumpPendingFrames(tester);
      expect(selectedCellBackgroundCount(), greaterThan(0));

      await tester.tap(find.byIcon(Icons.menu));
      await uxPumpPendingFrames(tester);
      expect(selectedCellBackgroundCount(), 0);

      expect(find.text('Clear all sorts'), findsOneWidget);

      await tester.tap(find.text('Clear all sorts'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.sort.active, isFalse);
      expect(dataSet.sort.items, isEmpty);
      expect(selectedCellBackgroundCount(), 0);
    });

    testWidgets('header filter writes active dataset filter state', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcStringField(size: 255, name: 'status'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'status': 'active'},
            {'name': 'Beta', 'status': 'blocked'},
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
        header: uxZeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).at(1), 'active');
      await uxPumpPendingFrames(tester);

      expect(dataSet.filter.fieldItems, hasLength(1));
      expect(dataSet.filter.fieldItems.single.fieldName, 'status');
      expect(
        dataSet.filter.fieldItems.single.operator,
        FdcFilterOperator.contains,
      );
      expect(dataSet.filter.fieldItems.single.value, 'active');
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);
    });

    testWidgets('paged header filter serializes rapid async applies', (
      tester,
    ) async {
      final adapter = UxGatedFilterMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          for (var i = 1; i <= 30; i++)
            <String, Object?>{'code': '21$i', 'name': 'Name $i'},
        ],
      );
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 50, name: 'code'),
          FdcStringField(size: 255, name: 'name'),
        ],
        adapter: adapter,
        paging: const FdcDataPagingOptions(
          enabled: true,
          pageSize: 10,
          requireTotalCount: true,
        ),
      );
      await dataSet.open();

      final flutterErrors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = flutterErrors.add;
      addTearDown(() {
        FlutterError.onError = previousOnError;
      });

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'code'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        header: uxZeroDebounceHeader,
      );

      expect(adapter.loadCount, 1);

      final codeFilter = find.byType(EditableText).first;
      await tester.enterText(codeFilter, '2');
      await tester.pump();
      await adapter.waitForBlockedLoadCount(1);
      expect(adapter.loadCount, 2);

      await tester.enterText(codeFilter, '21');
      await tester.pump();
      await tester.enterText(codeFilter, '212');
      await tester.pump();

      expect(adapter.blockedLoadCount, 1);
      expect(adapter.loadCount, 2);

      adapter.completeNextBlockedLoad();
      await tester.pump();
      await tester.pump();
      await adapter.waitForBlockedLoadCount(2);

      expect(adapter.loadCount, 3);

      adapter.completeNextBlockedLoad();
      await uxPumpPendingFrames(tester);

      expect(flutterErrors, isEmpty);
      expect(dataSet.filter.fieldItems, hasLength(1));
      expect(dataSet.filter.fieldItems.single.fieldName, 'code');
      expect(dataSet.filter.fieldItems.single.value, '212');
      expect(adapter.loadCount, 3);
    });
  });
}

void main() {
  group('FdcGrid widget UX / Filter State', () {
    _registerFilterStateTests();
  });
}
