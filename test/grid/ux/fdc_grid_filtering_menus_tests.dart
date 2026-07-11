part of '../fdc_grid_widget_ux_test.dart';

void _registerFilteringMenuTests() {
  group('Filtering and menus', () {
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

      await _pumpGrid(
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
      await tester.pumpAndSettle();

      expect(find.text('Show filters'), findsOneWidget);
      expect(find.text('Hide filters'), findsNothing);

      await tester.tap(find.text('Show filters'));
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'Alpha');
      await tester.pumpAndSettle();

      // The filter editor still contains "Alpha" while the matching row is visible.
      expect(find.text('Alpha'), findsNWidgets(2));
      expect(find.text('Beta'), findsNothing);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hide filters'));
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsNothing);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          header: _zeroDebounceHeader,
        );

        dataSet.edit();
        dataSet.setFieldValue('name', 'Changed');
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hide filters'));
        await tester.pumpAndSettle();

        expect(find.text('Post is not allowed.'), findsNothing);
        expect(dataSet.state, FdcDataSetState.edit);
        expect(find.byType(EditableText), findsNothing);

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          header: _zeroDebounceHeader,
        );

        await tester.enterText(find.byType(EditableText), 'Alpha');
        await tester.pumpAndSettle();
        expect(find.text('Beta'), findsNothing);

        dataSet.edit();
        dataSet.setFieldValue('name', 'Changed');
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hide filters'));
        await tester.pumpAndSettle();

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

        await _pumpGrid(
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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        header: _zeroDebounceHeader,
      );

      expect(dataSet.filter.active, isTrue);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Clear filters'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        rowIndicator: const FdcGridRowIndicator(
          visible: true,
          options: FdcGridRowIndicatorOptions(showRowNumbers: true),
        ),
        header: _zeroDebounceHeader,
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
      await tester.pumpAndSettle();
      expect(selectedCellBackgroundCount(), greaterThan(0));

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(selectedCellBackgroundCount(), 0);

      expect(find.text('Clear all sorts'), findsOneWidget);

      await tester.tap(find.text('Clear all sorts'));
      await tester.pumpAndSettle();

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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).at(1), 'active');
      await tester.pumpAndSettle();

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
      final adapter = _GatedFilterMemoryDataAdapter(
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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'code'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        header: _zeroDebounceHeader,
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
      await tester.pumpAndSettle();

      expect(flutterErrors, isEmpty);
      expect(dataSet.filter.fieldItems, hasLength(1));
      expect(dataSet.filter.fieldItems.single.fieldName, 'code');
      expect(dataSet.filter.fieldItems.single.value, '212');
      expect(adapter.loadCount, 3);
    });

    testWidgets('header filter remains editable when filter returns no rows', (
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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).at(1), 'missing');
      await tester.pumpAndSettle();

      expect(dataSet.filter.active, isTrue);
      expect(dataSet.recordCount, 0);

      var filterTextField = tester.widget<TextField>(
        find.byType(TextField).at(1),
      );
      expect(filterTextField.enabled, isTrue);

      await tester.enterText(find.byType(EditableText).at(1), 'active');
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 1);
      expect(find.text('Alpha'), findsOneWidget);
      filterTextField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(filterTextField.enabled, isTrue);
    });

    testWidgets('text header filter menu hides programming null operators', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha'},
            {'name': ''},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Contains'), findsWidgets);
      expect(find.text('Does not contain'), findsOneWidget);
      expect(find.text('Equals'), findsOneWidget);
      expect(find.text('Not equal'), findsOneWidget);
      expect(find.text('Starts with'), findsOneWidget);
      expect(find.text('Ends with'), findsOneWidget);
      expect(find.text('Is empty'), findsOneWidget);
      expect(find.text('Is not empty'), findsOneWidget);
      expect(find.text('Is null'), findsNothing);
      expect(find.text('Is not null'), findsNothing);
      expect(find.text('Is null or whitespace'), findsNothing);
      expect(find.text('Is not null or whitespace'), findsNothing);
    });

    testWidgets(
      'no-input header filter operator renders as disabled inline value',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcIntegerField(name: 'qty')],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'qty': 1},
              {'qty': null},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'qty'),
          ],
          header: _zeroDebounceHeader,
          toolbarVisible: false,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Is null'));
        await tester.pumpAndSettle();

        final filterTextField = tester.widget<TextField>(
          find.byType(TextField),
        );
        final filterEditableText = tester.widget<EditableText>(
          find.byType(EditableText),
        );

        expect(filterTextField.enabled, isFalse);
        expect(filterEditableText.controller.text, 'Is null');
        expect(find.widgetWithText(Text, 'Is null'), findsNothing);
        expect(
          dataSet.filter.fieldItems.single.operator,
          FdcFilterOperator.isNull,
        );
        expect(find.text('1'), findsNothing);
      },
    );

    testWidgets(
      'boolean header filter shows All until selected and disables manual input',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcBooleanField(name: 'active')],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'active': true},
              {'active': false},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcBooleanColumn<dynamic>(fieldName: 'active'),
          ],
          header: _zeroDebounceHeader,
          toolbarVisible: false,
        );

        var filterTextField = tester.widget<TextField>(find.byType(TextField));
        var filterEditableText = tester.widget<EditableText>(
          find.byType(EditableText),
        );

        expect(filterTextField.enabled, isFalse);
        expect(filterEditableText.controller.text, 'All');
        expect(find.widgetWithText(Text, 'Is true'), findsNothing);

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsNothing);

        await tester.tap(find.text('Is false'));
        await tester.pumpAndSettle();

        filterTextField = tester.widget<TextField>(find.byType(TextField));
        filterEditableText = tester.widget<EditableText>(
          find.byType(EditableText),
        );

        expect(filterTextField.enabled, isFalse);
        expect(filterEditableText.controller.text, 'Is false');
        expect(
          dataSet.filter.fieldItems.single.operator,
          FdcFilterOperator.isFalse,
        );
        expect(find.text('true'), findsNothing);
      },
    );

    testWidgets(
      'header filter overflow tooltip is disabled while editor has focus',
      (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);

        const tooltipText = '123456789012345678901234567890';

        Finder tooltipFinder() {
          return find.byWidgetPredicate(
            (widget) => widget is Tooltip && widget.message == tooltipText,
          );
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 24,
                height: 32,
                child: FdcGridHeaderFilterShell(
                  label: '',
                  focusNode: focusNode,
                  style: FdcGridHeaderFilterStyle.defaults,
                  overflowTooltipText: tooltipText,
                  overflowTooltipTextStyle: const TextStyle(fontSize: 18),
                  overflowTooltipReservedWidth: 24,
                  child: Focus(
                    focusNode: focusNode,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );

        focusNode.requestFocus();
        await tester.pump();

        expect(tooltipFinder(), findsNothing);
        expect(find.byType(FdcGridHeaderFilterShell), findsOneWidget);
      },
    );

    testWidgets('narrow boolean header filter all value exposes tooltip', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcBooleanField(name: 'active')],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'active': true},
            {'active': false},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcBooleanColumn<dynamic>(fieldName: 'active', width: 14),
        ],
        header: _zeroDebounceHeader,
        toolbarVisible: false,
        width: 80,
      );

      final tooltipFinder = find.byTooltip('All');
      expect(tooltipFinder, findsOneWidget);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(tooltipFinder));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('All'), findsOneWidget);
      await gesture.removePointer();
    });

    testWidgets(
      'column menu filter actions is disabled during active edit state',
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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          header: _zeroDebounceHeader,
          toolbarVisible: false,
        );

        dataSet.edit();
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(MenuItemButton),
            matching: find.text('Contains'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'header filter inline clear button clears current column filter',
      (tester) async {
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
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
            FdcTextColumn<dynamic>(fieldName: 'status'),
          ],
          header: _zeroDebounceHeader,
        );

        await tester.enterText(find.byType(EditableText).at(1), 'active');
        await tester.pumpAndSettle();

        expect(dataSet.filter.fieldItems, hasLength(1));
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsNothing);
        expect(find.byIcon(Icons.close), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

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
      },
    );

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

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          header: _zeroDebounceHeader,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      expect(find.byType(FdcGridHeaderFilterCell), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsNothing);
      expect(find.text('Show filters'), findsOneWidget);
      await tester.tap(find.text('Show filters'));
      await tester.pumpAndSettle();

      expect(find.byType(FdcGridHeaderFilterCell), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Hide filters'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Filters').hitTestable()).dy,
        lessThan(
          tester.getTopLeft(find.text('Contains').hitTestable().first).dy,
        ),
      );
      await tester.tap(find.text('Hide filters'));
      await tester.pumpAndSettle();

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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).at(1), 'active');
      await tester.pumpAndSettle();

      expect(dataSet.filter.fieldItems, hasLength(1));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      await tester.tap(find.text('Clear filter'));
      await tester.pumpAndSettle();

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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).at(0), 'Al');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(1), 'active');
      await tester.pumpAndSettle();

      expect(dataSet.filter.fieldItems, hasLength(2));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);
      expect(find.text('Alpine'), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Clear filter'), findsOneWidget);
      expect(find.text('Clear all filters'), findsOneWidget);

      await tester.tap(find.text('Clear all filters'));
      await tester.pumpAndSettle();

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

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        header: _zeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).at(1), 'active');
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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

      await _pumpGrid(
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
      await tester.pumpAndSettle();

      expect(dataSet.filter.fieldItems, hasLength(1));
      expect(dataSet.filter.fieldItems.single.fieldName, 'status');
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);
    });
  });
}
