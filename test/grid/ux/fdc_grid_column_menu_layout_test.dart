import 'fdc_grid_ux_test_support.dart';

void _registerColumnMenuLayoutTests() {
  group('Column menu layout and pinning', () {
    testWidgets('column header menu icon is hidden when it has no actions', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        options: const FdcGridOptions(),
        header: const FdcGridHeader(height: 32),
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(
            fieldName: 'name',
            label: 'Name',
            allowSort: false,
            pin: FdcGridColumnPin.startFixed,
          ),
        ],
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.byIcon(Icons.menu), findsNothing);
    });

    testWidgets(
      'main menu hides with no actions and returns for reset layout',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcStringField(size: 255, name: 'city'),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha', 'city': 'Austin'},
            ],
          ),
        );
        dataSet.open();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          options: const FdcGridOptions(),
          pinning: const FdcGridColumnPinning(),
          header: const FdcGridHeader(height: 32),
          toolbarVisible: false,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
            FdcTextColumn<dynamic>(fieldName: 'city', label: 'City'),
          ],
        );

        expect(find.byIcon(Icons.menu), findsNothing);

        final header = find.byKey(
          const ValueKey<String>('fdc-grid-header-field-name'),
        );
        final rect = tester.getRect(header);
        final resizeGesture = await tester.startGesture(
          Offset(rect.right - 2, rect.center.dy),
        );
        await tester.pump();
        await resizeGesture.moveBy(const Offset(32, 0));
        await tester.pump();
        await resizeGesture.up();
        await uxPumpPendingFrames(tester);

        expect(find.byIcon(Icons.menu), findsOneWidget);
        await tester.tap(find.byIcon(Icons.menu));
        await uxPumpPendingFrames(tester);
        expect(find.text('Reset grid layout'), findsOneWidget);

        await tester.tap(find.text('Reset grid layout'));
        await uxPumpPendingFrames(tester);
        expect(find.byIcon(Icons.menu), findsNothing);
      },
    );

    testWidgets(
      'column header menu applies ascending descending and clear sort',
      (tester) async {
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
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
          ],
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await uxPumpPendingFrames(tester);
        expect(find.text('Sorting'), findsOneWidget);
        await tester.tap(find.text('Sorting'));
        await uxPumpPendingFrames(tester);

        expect(find.text('Sort ascending'), findsOneWidget);
        expect(find.text('Sort descending'), findsOneWidget);
        expect(find.text('Clear sort'), findsNothing);
        expect(find.text('Clear all sorts'), findsNothing);

        await tester.tap(find.text('Sort ascending'));
        await uxPumpPendingFrames(tester);

        expect(dataSet.sort.items.single.sortType, FdcSortType.ascending);
        expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Alpha');
        expect(find.byIcon(Icons.north), findsOneWidget);

        await tester.tap(find.byIcon(Icons.more_vert));
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Sorting'));
        await uxPumpPendingFrames(tester);

        expect(find.text('Sort ascending'), findsNothing);
        expect(find.text('Sort descending'), findsOneWidget);
        expect(find.text('Clear sort'), findsOneWidget);
        expect(find.text('Clear all sorts'), findsNothing);

        await tester.tap(find.text('Sort descending'));
        await uxPumpPendingFrames(tester);

        expect(dataSet.sort.items.single.sortType, FdcSortType.descending);
        expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Beta');
        expect(find.byIcon(Icons.south), findsOneWidget);

        await tester.tap(find.byIcon(Icons.more_vert));
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Sorting'));
        await uxPumpPendingFrames(tester);

        expect(find.text('Sort ascending'), findsOneWidget);
        expect(find.text('Sort descending'), findsNothing);
        expect(find.text('Clear sort'), findsOneWidget);
        expect(find.text('Clear all sorts'), findsNothing);

        await tester.tap(find.text('Clear sort'));
        await uxPumpPendingFrames(tester);

        expect(dataSet.sort.items, isEmpty);
        expect(find.byIcon(Icons.north), findsNothing);
        expect(find.byIcon(Icons.south), findsNothing);
      },
    );

    testWidgets('column header menu exposes pin and unpin actions', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcStringField(size: 255, name: 'city'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'city': 'Boston'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
          FdcTextColumn<dynamic>(fieldName: 'city', label: 'City'),
        ],
      );

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await uxPumpPendingFrames(tester);

      expect(find.text('Column pinning'), findsOneWidget);
      await tester.tap(find.text('Column pinning'));
      await uxPumpPendingFrames(tester);
      expect(find.text('Pin to left'), findsOneWidget);
      expect(find.text('Pin to right'), findsOneWidget);
      expect(find.text('Unpin'), findsNothing);

      await tester.tap(find.text('Pin to right'));
      await uxPumpPendingFrames(tester);

      await tester.tap(find.byIcon(Icons.more_vert).last);
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Column pinning'));
      await uxPumpPendingFrames(tester);

      expect(find.text('Pin to left'), findsOneWidget);
      expect(find.text('Pin to right'), findsOneWidget);
      expect(find.text('Unpin'), findsOneWidget);

      await tester.tap(find.text('Unpin'));
      await uxPumpPendingFrames(tester);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Column pinning'));
      await uxPumpPendingFrames(tester);

      expect(find.text('Pin to left'), findsOneWidget);
      expect(find.text('Pin to right'), findsOneWidget);
      expect(find.text('Unpin'), findsNothing);
    });

    testWidgets('main grid menu unpins only user-pinned columns', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcStringField(size: 255, name: 'city'),
          FdcStringField(size: 255, name: 'status'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'city': 'Boston', 'status': 'Active'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        rowIndicator: const FdcGridRowIndicator(
          visible: true,
          options: FdcGridRowIndicatorOptions(showRowNumbers: true),
        ),
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(
            fieldName: 'name',
            label: 'Name',
            pin: FdcGridColumnPin.start,
          ),
          FdcTextColumn<dynamic>(fieldName: 'city', label: 'City'),
          FdcTextColumn<dynamic>(fieldName: 'status', label: 'Status'),
        ],
      );

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Column pinning'));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Pin to right'));
      await uxPumpPendingFrames(tester);

      await tester.tap(find.byIcon(Icons.menu));
      await uxPumpPendingFrames(tester);

      expect(find.text('Unpin all columns'), findsOneWidget);

      await tester.tap(find.text('Unpin all columns'));
      await uxPumpPendingFrames(tester);

      await tester.tap(find.byIcon(Icons.menu));
      await uxPumpPendingFrames(tester);
      expect(find.text('Unpin all columns'), findsNothing);
      await tester.tapAt(const Offset(1, 1));
      await uxPumpPendingFrames(tester);

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Column pinning'));
      await uxPumpPendingFrames(tester);
      expect(find.text('Unpin'), findsOneWidget);
      await tester.tapAt(const Offset(1, 1));
      await uxPumpPendingFrames(tester);

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Column pinning'));
      await uxPumpPendingFrames(tester);
      expect(find.text('Unpin'), findsNothing);
    });

    testWidgets('main grid menu resets runtime grid layout state', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcStringField(size: 255, name: 'city'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'city': 'Boston'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        header: uxZeroDebounceHeader,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
          FdcTextColumn<dynamic>(fieldName: 'city', label: 'City'),
        ],
      );

      await tester.tap(find.byIcon(Icons.more_vert).last);
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Column pinning'));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Pin to right'));
      await uxPumpPendingFrames(tester);

      await tester.tap(find.byIcon(Icons.menu));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Hide filters'));
      await uxPumpPendingFrames(tester);

      await tester.tap(find.byIcon(Icons.menu));
      await uxPumpPendingFrames(tester);
      expect(find.text('Show filters'), findsOneWidget);
      expect(find.text('Unpin all columns'), findsOneWidget);
      expect(find.text('Reset grid layout'), findsOneWidget);

      await tester.tap(find.text('Reset grid layout'));
      await uxPumpPendingFrames(tester);

      await tester.tap(find.byIcon(Icons.menu));
      await uxPumpPendingFrames(tester);
      expect(find.text('Hide filters'), findsOneWidget);
      expect(find.text('Unpin all columns'), findsNothing);
      expect(find.text('Reset grid layout'), findsNothing);
      await tester.tapAt(const Offset(1, 1));
      await uxPumpPendingFrames(tester);

      await tester.tap(find.byIcon(Icons.more_vert).last);
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Column pinning'));
      await uxPumpPendingFrames(tester);
      expect(find.text('Unpin'), findsNothing);
      expect(find.text('Pin to right'), findsOneWidget);
    });

    testWidgets(
      'column menus expose main grid actions when indicator is hidden',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcStringField(size: 255, name: 'city'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha', 'city': 'Boston'},
            ],
          ),
        );
        dataSet.open();
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          header: uxZeroDebounceHeader,
          rowIndicator: const FdcGridRowIndicator(),
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
            FdcTextColumn<dynamic>(fieldName: 'city', label: 'City'),
          ],
        );

        expect(find.byIcon(Icons.menu), findsNothing);

        await tester.tap(find.byIcon(Icons.more_vert).last);
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Column pinning'));
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Pin to right'));
        await uxPumpPendingFrames(tester);

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await uxPumpPendingFrames(tester);
        expect(find.text('Hide filters'), findsOneWidget);
        expect(find.text('Unpin all columns'), findsOneWidget);
        expect(find.text('Reset grid layout'), findsOneWidget);

        await tester.tap(find.text('Reset grid layout'));
        await uxPumpPendingFrames(tester);

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await uxPumpPendingFrames(tester);
        expect(find.text('Hide filters'), findsOneWidget);
        expect(find.text('Unpin all columns'), findsNothing);
        expect(find.text('Reset grid layout'), findsNothing);
      },
    );

    testWidgets('fixed API-pinned columns do not expose UI unpin actions', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcStringField(size: 255, name: 'city'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'city': 'Boston'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(
            fieldName: 'name',
            label: 'Name',
            pin: FdcGridColumnPin.startFixed,
          ),
          FdcTextColumn<dynamic>(fieldName: 'city', label: 'City'),
        ],
      );

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await uxPumpPendingFrames(tester);

      expect(find.text('Sorting'), findsOneWidget);
      expect(find.text('Column pinning'), findsNothing);

      await tester.tapAt(const Offset(1, 1));
      await uxPumpPendingFrames(tester);

      await tester.tap(find.byIcon(Icons.more_vert).last);
      await uxPumpPendingFrames(tester);
      expect(find.text('Column pinning'), findsOneWidget);
      await tester.tap(find.text('Column pinning'));
      await uxPumpPendingFrames(tester);

      expect(find.text('Pin to left'), findsOneWidget);
      expect(find.text('Pin to right'), findsOneWidget);
    });

    testWidgets(
      'column header menu hides pin actions when column pinning is disabled',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name'),
            FdcStringField(size: 255, name: 'city'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alpha', 'city': 'Boston'},
            ],
          ),
        );
        dataSet.open();
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          pinning: const FdcGridColumnPinning(),
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(
              fieldName: 'name',
              label: 'Name',
              pin: FdcGridColumnPin.start,
            ),
            FdcTextColumn<dynamic>(fieldName: 'city', label: 'City'),
          ],
        );

        expect(find.text('Name'), findsOneWidget);
        expect(find.text('City'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await uxPumpPendingFrames(tester);

        expect(find.text('Sorting'), findsOneWidget);
        expect(find.text('Column pinning'), findsNothing);
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Column Menu Layout', () {
    _registerColumnMenuLayoutTests();
  });
}
