part of '../fdc_grid_widget_ux_test.dart';

void _registerCustomColumnTests() {
  group('Custom columns', () {
    testWidgets('grid does not overflow when height is extremely narrow', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 92,
              height: 82,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(height: 32),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
                  FdcIntegerColumn(fieldName: 'id', width: 140),
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

      expect(tester.takeException(), isNull);
    });

    testWidgets('custom column can read and write bound field value', (
      tester,
    ) async {
      final dataSet = _peopleStatusDataSet();
      var changed = 0;

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: <FdcGridColumn<dynamic>>[
          const FdcTextColumn<dynamic>(fieldName: 'name', width: 120),
          FdcCustomColumn<String>(
            fieldName: 'status',
            label: 'Status label',
            width: 180,
            cellBuilder: (field, cell) {
              final name = field.valueOf<String>('name');
              return TextButton(
                key: ValueKey<String>('status-${field.rowIndex}'),
                onPressed: () {
                  if (field.setValue('Blocked')) {
                    changed++;
                  }
                },
                child: Text('$name:${field.value}'),
              );
            },
          ),
        ],
      );

      expect(find.text('Status label'), findsOneWidget);
      expect(find.text('Alpha:Active'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('status-0')));
      await tester.pumpAndSettle();

      expect(changed, 1);
      expect(dataSet.fieldValue('status'), 'Blocked');
      expect(find.text('Alpha:Blocked'), findsOneWidget);
    });

    testWidgets('custom column exposes resolved cell style to builder', (
      tester,
    ) async {
      final dataSet = _peopleStatusDataSet();
      Color? backgroundColor;
      Color? foregroundColor;
      TextStyle? textStyle;
      Alignment? alignment;
      TextAlign? textAlign;

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        style: const FdcGridStyle(
          cellTextStyle: TextStyle(color: Color(0xFF334155), fontSize: 13),
        ),
        columns: <FdcGridColumn<dynamic>>[
          FdcCustomColumn<String>(
            fieldName: 'status',
            label: 'Status',
            width: 180,
            readOnly: true,
            cellStyle: const FdcGridCellStyle(
              backgroundColor: Color(0xFFEFF6FF),
            ),
            cellBuilder: (field, cell) {
              if (field.rowIndex == 1) {
                backgroundColor = cell.backgroundColor;
                foregroundColor = cell.foregroundColor;
                textStyle = cell.textStyle;
                alignment = cell.alignment;
                textAlign = cell.textAlign;
              }

              return Container(
                key: ValueKey<String>('styled-status-${field.rowIndex}'),
                color: cell.backgroundColor,
                alignment: cell.alignment,
                child: Text(
                  field.value ?? '',
                  textAlign: cell.textAlign,
                  style: cell.textStyle,
                ),
              );
            },
          ),
        ],
      );

      expect(backgroundColor, const Color(0xFFEFF6FF));
      expect(foregroundColor, const Color(0xFF334155));
      expect(textStyle?.fontSize, 13);
      expect(alignment, Alignment.centerLeft);
      expect(textAlign, TextAlign.start);
      expect(
        find.byKey(const ValueKey<String>('styled-status-1')),
        findsOneWidget,
      );
    });

    testWidgets(
      'column onValueChanging transforms custom cell writes before dataset write',
      (tester) async {
        final dataSet = _peopleStatusDataSet();

        await _pumpBasicGrid(
          tester,
          dataSet: dataSet,
          columns: <FdcGridColumn<dynamic>>[
            FdcTextColumn<String>(
              fieldName: 'status',
              width: 160,
              onValueChanging: (context) {
                if (context.newValue == '3851234567890') {
                  return context.replaceValue('ART-001');
                }
                return context.accept();
              },
            ),
            FdcCustomColumn<String>(
              fieldName: 'name',
              label: 'Scan',
              width: 160,
              cellBuilder: (field, cell) {
                return TextButton(
                  key: ValueKey<String>('scan-${field.rowIndex}'),
                  onPressed: () =>
                      field.setValueOf<String>('status', '3851234567890'),
                  child: Text(field.value ?? ''),
                );
              },
            ),
          ],
        );

        await tester.tap(find.byKey(const ValueKey<String>('scan-0')));
        await tester.pumpAndSettle();

        expect(dataSet.fieldValue('status'), 'ART-001');
        expect(find.text('ART-001'), findsOneWidget);
      },
    );

    testWidgets(
      'field writes resolve value-changing columns case-insensitively',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcStringField(size: 255, name: 'Name', label: 'Name'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'id': 1, 'Name': 'Alpha'},
            ],
          ),
        );
        dataSet.open();

        await _pumpBasicGrid(
          tester,
          dataSet: dataSet,
          columns: <FdcGridColumn<dynamic>>[
            FdcTextColumn<String>(
              fieldName: 'Name',
              width: 160,
              onValueChanging: (context) {
                if (context.newValue == 'scan') {
                  return context.replaceValue('Resolved Name');
                }
                return context.accept();
              },
            ),
            FdcCustomColumn<int>(
              fieldName: 'id',
              label: 'Action',
              width: 160,
              cellBuilder: (field, cell) {
                return TextButton(
                  key: const ValueKey<String>('case-field-write'),
                  onPressed: () => field.setValueOf<String>('name', 'scan'),
                  child: Text('${field.value ?? ''}'),
                );
              },
            ),
          ],
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('case-field-write')),
        );
        await tester.pumpAndSettle();

        expect(dataSet.fieldValue('Name'), 'Resolved Name');
        expect(find.text('Resolved Name'), findsWidgets);
      },
    );

    testWidgets('value-changing primary field guard is case-insensitive', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'Name', label: 'Name'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'Name': 'Alpha'},
          ],
        ),
      );
      dataSet.open();

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: <FdcGridColumn<dynamic>>[
          FdcTextColumn<String>(
            fieldName: 'Name',
            width: 160,
            onValueChanging: (context) {
              if (context.newValue == 'scan') {
                context.setValueOf<String>('name', 'Should be ignored');
                return context.replaceValue('Primary Replacement');
              }
              return context.accept();
            },
          ),
          FdcCustomColumn<int>(
            fieldName: 'id',
            label: 'Action',
            width: 160,
            cellBuilder: (field, cell) {
              return TextButton(
                key: const ValueKey<String>('case-primary-guard'),
                onPressed: () => field.setValueOf<String>('Name', 'scan'),
                child: Text('${field.value ?? ''}'),
              );
            },
          ),
        ],
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('case-primary-guard')),
      );
      await tester.pumpAndSettle();

      expect(dataSet.fieldValue('Name'), 'Primary Replacement');
      expect(find.text('Primary Replacement'), findsWidgets);
      expect(find.text('Should be ignored'), findsNothing);
    });

    testWidgets(
      'column onValueChanging can update sibling fields in the same row',
      (tester) async {
        final dataSet = _peopleStatusDataSet();

        await _pumpBasicGrid(
          tester,
          dataSet: dataSet,
          columns: <FdcGridColumn<dynamic>>[
            FdcTextColumn<String>(
              fieldName: 'status',
              width: 160,
              onValueChanging: (context) {
                if (context.newValue == '3851234567890') {
                  context.setValueOf<String>('name', 'Lookup article name');
                  return context.replaceValue('ART-001');
                }
                return context.accept();
              },
            ),
            FdcCustomColumn<String>(
              fieldName: 'name',
              label: 'Scan',
              width: 160,
              cellBuilder: (field, cell) {
                return TextButton(
                  key: ValueKey<String>('scan-sibling-${field.rowIndex}'),
                  onPressed: () =>
                      field.setValueOf<String>('status', '3851234567890'),
                  child: Text(field.value ?? ''),
                );
              },
            ),
          ],
        );

        await tester.tap(find.byKey(const ValueKey<String>('scan-sibling-0')));
        await tester.pumpAndSettle();

        expect(dataSet.fieldValue('status'), 'ART-001');
        expect(dataSet.fieldValue('name'), 'Lookup article name');
        expect(find.text('ART-001'), findsOneWidget);
        expect(find.text('Lookup article name'), findsOneWidget);
      },
    );

    testWidgets('column onValueChanging can cancel custom cell writes', (
      tester,
    ) async {
      final dataSet = _peopleStatusDataSet();

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: <FdcGridColumn<dynamic>>[
          FdcCustomColumn<String>(
            fieldName: 'status',
            label: 'Status',
            width: 180,
            onValueChanging: (context) => context.cancel(),
            cellBuilder: (field, cell) {
              return TextButton(
                key: ValueKey<String>('cancel-status-${field.rowIndex}'),
                onPressed: () => field.setValue('Blocked'),
                child: Text(field.value ?? ''),
              );
            },
          ),
        ],
      );

      await tester.tap(find.byKey(const ValueKey<String>('cancel-status-0')));
      await tester.pump();

      expect(dataSet.fieldValue('status'), 'Active');
      expect(find.text('Blocked'), findsNothing);
    });

    testWidgets(
      'cellIndicator visible false suppresses active cell indicator',
      (tester) async {
        final dataSet = _peopleStatusDataSet();

        await _pumpBasicGrid(
          tester,
          dataSet: dataSet,
          cellIndicator: const FdcGridCellIndicator(visible: false),
          columns: <FdcGridColumn<dynamic>>[
            FdcCustomColumn<String>(
              fieldName: 'status',
              label: 'Status',
              width: 180,
              cellBuilder: (field, cell) {
                return TextButton(
                  key: ValueKey<String>('hidden-indicator-${field.rowIndex}'),
                  onPressed: () {},
                  child: Text(field.value ?? ''),
                );
              },
            ),
          ],
        );

        final buttonFinder = find.byKey(
          const ValueKey<String>('hidden-indicator-0'),
        );
        final frameFinder = find.ancestor(
          of: buttonFinder,
          matching: find.byType(FdcGridCellFrame),
        );

        expect(frameFinder, findsOneWidget);
        expect(
          tester.widget<FdcGridCellFrame>(frameFinder).indicatorStyle,
          isNull,
        );
      },
    );

    testWidgets('column showIndicator can suppress active cell indicator', (
      tester,
    ) async {
      final dataSet = _peopleStatusDataSet();

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: <FdcGridColumn<dynamic>>[
          FdcCustomColumn<String>(
            fieldName: 'status',
            label: 'Status',
            width: 180,
            showIndicator: false,
            cellBuilder: (field, cell) {
              return TextButton(
                key: ValueKey<String>('no-indicator-${field.rowIndex}'),
                onPressed: () {},
                child: Text(field.value ?? ''),
              );
            },
          ),
        ],
      );

      final buttonFinder = find.byKey(const ValueKey<String>('no-indicator-0'));
      final frameFinder = find.ancestor(
        of: buttonFinder,
        matching: find.byType(FdcGridCellFrame),
      );

      expect(frameFinder, findsOneWidget);
      expect(
        tester.widget<FdcGridCellFrame>(frameFinder).indicatorStyle,
        isNull,
      );
    });

    testWidgets(
      'custom column setValue focuses readonly cell without writing',
      (tester) async {
        final dataSet = _peopleStatusDataSet();
        await _pumpBasicGrid(
          tester,
          dataSet: dataSet,
          columns: <FdcGridColumn<dynamic>>[
            const FdcTextColumn<dynamic>(fieldName: 'name', width: 120),
            FdcCustomColumn<String>(
              fieldName: 'status',
              label: 'Status',
              width: 180,
              readOnly: true,
              cellBuilder: (field, cell) {
                return TextButton(
                  key: ValueKey<String>('readonly-status-${field.rowIndex}'),
                  onPressed: () => field.setValue('Should not write'),
                  child: Text(field.value ?? ''),
                );
              },
            ),
          ],
        );

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);

        await tester.tap(
          find.byKey(const ValueKey<String>('readonly-status-1')),
        );
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
        expect(dataSet.fieldValue('status'), 'Inactive');
        expect(find.text('Should not write'), findsNothing);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      },
    );

    testWidgets(
      'mouse cell tap continues to clicked row after immediate post',
      (tester) async {
        final applyGate = Completer<void>();
        final applyStarted = Completer<void>();
        final adapter =
            _AsyncApplyMemoryAdapter(<Map<String, Object?>>[
                <String, Object?>{'id': 1, 'name': 'Alpha'},
                <String, Object?>{'id': 2, 'name': 'Beta'},
              ])
              ..applyGate = applyGate
              ..applyStarted = applyStarted;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcStringField(name: 'name', size: 40),
          ],
          adapter: adapter,
        );
        await dataSet.open();

        await _pumpBasicGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id', width: 80),
            FdcTextColumn<dynamic>(fieldName: 'name', width: 160),
          ],
        );

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        dataSet.edit();
        dataSet['name'] = 'Alpha changed';
        expect(dataSet.state, FdcDataSetState.edit);

        await tester.tap(find.text('Beta'));
        await applyStarted.future;
        await tester.pump();

        expect(adapter.applyCalls, hasLength(1));
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);

        applyGate.complete();
        await tester.pumpAndSettle();

        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.errors.messages.isNotEmpty, isFalse);
        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
        expect(dataSet.fieldValue('name'), 'Beta');
      },
    );

    testWidgets('boolean checkbox click continues after async immediate post', (
      tester,
    ) async {
      final applyGate = Completer<void>();
      final applyStarted = Completer<void>();
      final adapter =
          _AsyncApplyMemoryAdapter(<Map<String, Object?>>[
              <String, Object?>{'id': 1, 'name': 'Alpha', 'active': false},
              <String, Object?>{'id': 2, 'name': 'Beta', 'active': false},
            ])
            ..applyGate = applyGate
            ..applyStarted = applyStarted;
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'name', size: 40),
          FdcBooleanField(name: 'active', required: true),
        ],
        adapter: adapter,
      );
      await dataSet.open();

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id', width: 80),
          FdcTextColumn<dynamic>(fieldName: 'name', width: 160),
          FdcBooleanColumn<dynamic>(fieldName: 'active', width: 100),
        ],
      );

      dataSet.edit();
      dataSet['name'] = 'Alpha changed';

      await tester.tap(find.byType(Checkbox).at(1));
      await applyStarted.future;
      await tester.pump();

      expect(adapter.applyCalls, hasLength(1));
      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'active'), false);

      applyGate.complete();
      await tester.pumpAndSettle();

      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet.errors.messages.isNotEmpty, isFalse);
      expect(adapter.applyCalls, hasLength(1));
      expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'active'), true);
    });

    testWidgets('custom column setValue activates the owning row first', (
      tester,
    ) async {
      final dataSet = _peopleStatusDataSet();

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: <FdcGridColumn<dynamic>>[
          const FdcTextColumn<dynamic>(fieldName: 'name', width: 120),
          FdcCustomColumn<String>(
            fieldName: 'status',
            label: 'Status',
            width: 180,
            cellBuilder: (field, cell) {
              return TextButton(
                key: ValueKey<String>('set-status-${field.rowIndex}'),
                onPressed: () => field.setValue('Clicked ${field.rowIndex}'),
                child: Text(field.value ?? ''),
              );
            },
          ),
        ],
      );

      expect(FdcDataSetInternal.activeIndex(dataSet), 0);

      await tester.tap(find.byKey(const ValueKey<String>('set-status-1')));
      await tester.pumpAndSettle();

      expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      expect(dataSet.fieldValue('status'), 'Clicked 1');
      expect(find.text('Clicked 1'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
    });
  });
}
