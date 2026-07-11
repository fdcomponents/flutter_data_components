part of '../fdc_grid_widget_ux_test.dart';

void _registerColumnMenuSortingTests() {
  group('Column menu and sorting', () {
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

      await _pumpGrid(
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

        await _pumpGrid(
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
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.menu), findsOneWidget);
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        expect(find.text('Reset grid layout'), findsOneWidget);

        await tester.tap(find.text('Reset grid layout'));
        await tester.pumpAndSettle();
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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
          ],
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        expect(find.text('Sorting'), findsOneWidget);
        await tester.tap(find.text('Sorting'));
        await tester.pumpAndSettle();

        expect(find.text('Sort ascending'), findsOneWidget);
        expect(find.text('Sort descending'), findsOneWidget);
        expect(find.text('Clear sort'), findsNothing);
        expect(find.text('Clear all sorts'), findsNothing);

        await tester.tap(find.text('Sort ascending'));
        await tester.pumpAndSettle();

        expect(dataSet.sort.items.single.sortType, FdcSortType.ascending);
        expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Alpha');
        expect(find.byIcon(Icons.north), findsOneWidget);

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sorting'));
        await tester.pumpAndSettle();

        expect(find.text('Sort ascending'), findsNothing);
        expect(find.text('Sort descending'), findsOneWidget);
        expect(find.text('Clear sort'), findsOneWidget);
        expect(find.text('Clear all sorts'), findsNothing);

        await tester.tap(find.text('Sort descending'));
        await tester.pumpAndSettle();

        expect(dataSet.sort.items.single.sortType, FdcSortType.descending);
        expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Beta');
        expect(find.byIcon(Icons.south), findsOneWidget);

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sorting'));
        await tester.pumpAndSettle();

        expect(find.text('Sort ascending'), findsOneWidget);
        expect(find.text('Sort descending'), findsNothing);
        expect(find.text('Clear sort'), findsOneWidget);
        expect(find.text('Clear all sorts'), findsNothing);

        await tester.tap(find.text('Clear sort'));
        await tester.pumpAndSettle();

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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
          FdcTextColumn<dynamic>(fieldName: 'city', label: 'City'),
        ],
      );

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      expect(find.text('Column pinning'), findsOneWidget);
      await tester.tap(find.text('Column pinning'));
      await tester.pumpAndSettle();
      expect(find.text('Pin to left'), findsOneWidget);
      expect(find.text('Pin to right'), findsOneWidget);
      expect(find.text('Unpin'), findsNothing);

      await tester.tap(find.text('Pin to right'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Column pinning'));
      await tester.pumpAndSettle();

      expect(find.text('Pin to left'), findsOneWidget);
      expect(find.text('Pin to right'), findsOneWidget);
      expect(find.text('Unpin'), findsOneWidget);

      await tester.tap(find.text('Unpin'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Column pinning'));
      await tester.pumpAndSettle();

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

      await _pumpGrid(
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
      await tester.pumpAndSettle();
      await tester.tap(find.text('Column pinning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pin to right'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Unpin all columns'), findsOneWidget);

      await tester.tap(find.text('Unpin all columns'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('Unpin all columns'), findsNothing);
      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Column pinning'));
      await tester.pumpAndSettle();
      expect(find.text('Unpin'), findsOneWidget);
      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Column pinning'));
      await tester.pumpAndSettle();
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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        header: _zeroDebounceHeader,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
          FdcTextColumn<dynamic>(fieldName: 'city', label: 'City'),
        ],
      );

      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Column pinning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pin to right'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hide filters'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('Show filters'), findsOneWidget);
      expect(find.text('Unpin all columns'), findsOneWidget);
      expect(find.text('Reset grid layout'), findsOneWidget);

      await tester.tap(find.text('Reset grid layout'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('Hide filters'), findsOneWidget);
      expect(find.text('Unpin all columns'), findsNothing);
      expect(find.text('Reset grid layout'), findsNothing);
      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Column pinning'));
      await tester.pumpAndSettle();
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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          header: _zeroDebounceHeader,
          rowIndicator: const FdcGridRowIndicator(),
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
            FdcTextColumn<dynamic>(fieldName: 'city', label: 'City'),
          ],
        );

        expect(find.byIcon(Icons.menu), findsNothing);

        await tester.tap(find.byIcon(Icons.more_vert).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Column pinning'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pin to right'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        expect(find.text('Hide filters'), findsOneWidget);
        expect(find.text('Unpin all columns'), findsOneWidget);
        expect(find.text('Reset grid layout'), findsOneWidget);

        await tester.tap(find.text('Reset grid layout'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
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

      await _pumpGrid(
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
      await tester.pumpAndSettle();

      expect(find.text('Sorting'), findsOneWidget);
      expect(find.text('Column pinning'), findsNothing);

      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pumpAndSettle();
      expect(find.text('Column pinning'), findsOneWidget);
      await tester.tap(find.text('Column pinning'));
      await tester.pumpAndSettle();

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
        await _pumpGrid(
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
        await tester.pumpAndSettle();

        expect(find.text('Sorting'), findsOneWidget);
        expect(find.text('Column pinning'), findsNothing);
      },
    );

    testWidgets('column header menu can build a multi-column sort chain', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'group'),
          FdcStringField(size: 255, name: 'name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'group': 'B', 'name': 'Alpha'},
            {'group': 'A', 'name': 'Beta'},
            {'group': 'A', 'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'group', label: 'Group'),
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
        ],
      );

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sorting'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sort ascending'));
      await tester.pumpAndSettle();

      expect(dataSet.sort.items, hasLength(1));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(find.text('1'), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sorting'));
      await tester.pumpAndSettle();

      expect(find.text('Add ascending sort'), findsOneWidget);
      expect(find.text('Add descending sort'), findsOneWidget);
      expect(find.text('Sort ascending'), findsNothing);
      expect(find.text('Sort descending'), findsNothing);
      expect(find.text('Clear all sorts'), findsNothing);

      await tester.tap(find.text('Add descending sort'));
      await tester.pumpAndSettle();

      expect(dataSet.sort.items, hasLength(2));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(dataSet.sort.items[1].fieldName, 'name');
      expect(dataSet.sort.items[1].sortType, FdcSortType.descending);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'group'), 'A');
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Beta');

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sorting'));
      await tester.pumpAndSettle();

      expect(find.text('Clear sort'), findsOneWidget);
      expect(find.text('Clear all sorts'), findsOneWidget);

      await tester.tap(find.text('Clear all sorts'));
      await tester.pumpAndSettle();

      expect(dataSet.sort.items, isEmpty);
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
    });

    testWidgets('plain click on unsorted header replaces existing sort', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'group'),
          FdcStringField(size: 255, name: 'name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'group': 'B', 'name': 'Alpha'},
            {'group': 'A', 'name': 'Beta'},
            {'group': 'A', 'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'group', label: 'Group'),
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
        ],
      );

      await tester.tap(find.text('Group'));
      await tester.pumpAndSettle();

      expect(dataSet.sort.items, hasLength(1));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      expect(dataSet.sort.items, hasLength(1));
      expect(dataSet.sort.items[0].fieldName, 'name');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
    });

    testWidgets('Ctrl click header cycles ascending descending and none', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'group'),
          FdcStringField(size: 255, name: 'name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'group': 'B', 'name': 'Alpha'},
            {'group': 'A', 'name': 'Beta'},
            {'group': 'A', 'name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'group', label: 'Group'),
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
        ],
      );

      await tester.tap(find.text('Group'));
      await tester.pumpAndSettle();

      expect(dataSet.sort.items, hasLength(1));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(find.text('1'), findsNothing);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(dataSet.sort.items, hasLength(2));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(dataSet.sort.items[1].fieldName, 'name');
      expect(dataSet.sort.items[1].sortType, FdcSortType.ascending);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(dataSet.sort.items, hasLength(2));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(dataSet.sort.items[1].fieldName, 'name');
      expect(dataSet.sort.items[1].sortType, FdcSortType.descending);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(dataSet.sort.items, hasLength(1));
      expect(dataSet.sort.items[0].fieldName, 'group');
      expect(dataSet.sort.items[0].sortType, FdcSortType.ascending);
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
    });

    testWidgets(
      'unsorted sortable header shows disabled sort affordance on hover',
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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
          ],
        );

        expect(find.byIcon(Icons.north), findsNothing);

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: const Offset(590, 310));
        await tester.pump();
        await gesture.moveTo(tester.getCenter(find.text('Name')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));

        expect(find.byIcon(Icons.north), findsOneWidget);

        await gesture.moveTo(const Offset(590, 310));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.north), findsNothing);
        await gesture.removePointer();
      },
    );

    testWidgets('Space opens combo dropdown when autoEdit is false', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 20, name: 'status')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'status': 'open'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        options: const FdcGridOptions(autoEdit: false),
        columns: const <FdcGridColumn<dynamic>>[
          FdcComboColumn<String>(
            fieldName: 'status',
            options: <FdcOption<String>>[
              FdcOption<String>(value: 'open', label: 'Open'),
              FdcOption<String>(value: 'closed', label: 'Closed'),
            ],
          ),
        ],
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Closed'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(find.text('Closed'), findsOneWidget);
      expect(dataSet.fieldValue('status'), 'open');
    });
  });
}
