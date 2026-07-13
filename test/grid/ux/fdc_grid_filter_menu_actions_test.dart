import 'fdc_grid_ux_test_support.dart';

void _registerFilterMenuActionTests() {
  group('Filter menu actions', () {
    testWidgets(
      'column menu hides clear filter when current column has no filter',
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

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          header: uxZeroDebounceHeader,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await uxPumpPendingFrames(tester);

        expect(find.text('Filters'), findsOneWidget);
        expect(find.text('Clear filter'), findsNothing);
      },
    );

    testWidgets('column menu can show and hide header filters', (tester) async {
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
      );

      expect(find.byType(FdcGridHeaderFilterCell), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert));
      await uxPumpPendingFrames(tester);

      expect(find.text('Filters'), findsNothing);
      expect(find.text('Show filters'), findsOneWidget);
      await tester.tap(find.text('Show filters'));
      await uxPumpPendingFrames(tester);

      expect(find.byType(FdcGridHeaderFilterCell), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await uxPumpPendingFrames(tester);

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Hide filters'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Filters').hitTestable()).dy,
        lessThan(
          tester.getTopLeft(find.text('Contains').hitTestable().first).dy,
        ),
      );
      await tester.tap(find.text('Hide filters'));
      await uxPumpPendingFrames(tester);

      expect(find.byType(FdcGridHeaderFilterCell), findsNothing);
    });

    testWidgets('column menu filter section clears current column filter', (
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
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await uxPumpPendingFrames(tester);

      expect(find.text('Filters'), findsOneWidget);
      await tester.tap(find.text('Clear filter'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.filter.fieldItems, isEmpty);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .controller
            .text,
        '',
      );
    });

    testWidgets('column menu filter section can clear all active filters', (
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
            {'name': 'Alpine', 'status': 'blocked'},
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

      await tester.enterText(find.byType(EditableText).at(0), 'Al');
      await uxPumpPendingFrames(tester);
      await tester.enterText(find.byType(EditableText).at(1), 'active');
      await uxPumpPendingFrames(tester);

      expect(dataSet.filter.fieldItems, hasLength(2));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);
      expect(find.text('Alpine'), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await uxPumpPendingFrames(tester);

      expect(find.text('Clear filter'), findsOneWidget);
      expect(find.text('Clear all filters'), findsOneWidget);

      await tester.tap(find.text('Clear all filters'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.filter.fieldItems, isEmpty);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Alpine'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(0))
            .controller
            .text,
        '',
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .controller
            .text,
        '',
      );
    });

    testWidgets('external dataset filter clears header filter editors', (
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

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .controller
            .text,
        'active',
      );
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);

      dataSet.filter.where('name').equals('Beta').apply();
      await uxPumpPendingFrames(tester);

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(0))
            .controller
            .text,
        '',
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).at(1))
            .controller
            .text,
        '',
      );
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsOneWidget);
      expect(dataSet.filter.fieldItems.single.fieldName, 'name');
    });

    testWidgets('external dataset filter survives grid sort changes', (
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
      dataSet.filter.where('status').equals('active').apply();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
          FdcTextColumn<dynamic>(fieldName: 'status', label: 'Status'),
        ],
      );

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);

      await tester.tap(find.text('Name'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.filter.fieldItems, hasLength(1));
      expect(dataSet.filter.fieldItems.single.fieldName, 'status');
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);
    });
  });
}

void main() {
  group('FdcGrid widget UX / Filter Menu Actions', () {
    _registerFilterMenuActionTests();
  });
}
