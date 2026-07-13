import 'fdc_grid_ux_test_support.dart';

void _registerDatasetGuardIdentityTests() {
  group('Dataset guards and runtime identity', () {
    testWidgets(
      'external append keeps indicator content when grid focus returns',
      (tester) async {
        final dataSet = uxPeopleDataSet();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          rowIndicator: const FdcGridRowIndicator(
            visible: true,
            options: FdcGridRowIndicatorOptions(
              showRowNumbers: true,
              showRowSelect: true,
            ),
          ),
        );

        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        dataSet.append();
        await uxPumpPendingFrames(tester);

        expect(dataSet.state, FdcDataSetState.insert);
        expect(dataSet.recordCount, 3);
        expect(find.text('3'), findsOneWidget);
        expect(find.byType(Checkbox), findsNWidgets(4));

        await tester.tap(find.text('Alpha'));
        await uxPumpPendingFrames(tester);

        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.recordCount, 2);
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsNothing);
        expect(find.byType(Checkbox), findsNWidgets(3));
      },
    );

    testWidgets(
      'beforeScroll visible abort from grid shows dataset error dialog',
      (tester) async {
        var beforeScrollCalls = 0;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcStringField(size: 255, name: 'name'),
          ],
          beforeScroll: (dataSet, currentRecordNumber, targetRecordNumber) {
            beforeScrollCalls++;
            if (targetRecordNumber > 0 &&
                FdcDataSetInternal.fieldValueAt(
                      dataSet,
                      targetRecordNumber - 1,
                      'id',
                    ) ==
                    2) {
              throw FdcDataSetAbortException('Scroll is not allowed.');
            }
          },

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'id': 1, 'name': 'Alpha'},
              {'id': 2, 'name': 'Beta'},
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

        await tester.tap(find.text('Beta'));
        await uxPumpPendingFrames(tester);

        expect(beforeScrollCalls, 1);
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
        expect(dataSet.errors.messages[0], 'Scroll is not allowed.');
        expect(find.text('Scroll is not allowed.'), findsOneWidget);
      },
    );

    testWidgets(
      'beforeScroll silent abort from grid keeps current row without dialog',
      (tester) async {
        var beforeScrollCalls = 0;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcStringField(size: 255, name: 'name'),
          ],
          beforeScroll: (dataSet, currentRecordNumber, targetRecordNumber) {
            beforeScrollCalls++;
            if (targetRecordNumber > 0 &&
                FdcDataSetInternal.fieldValueAt(
                      dataSet,
                      targetRecordNumber - 1,
                      'id',
                    ) ==
                    2) {
              throw const FdcDataSetAbortException.silent();
            }
          },

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'id': 1, 'name': 'Alpha'},
              {'id': 2, 'name': 'Beta'},
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

        await tester.tap(find.text('Beta'));
        await uxPumpPendingFrames(tester);

        expect(beforeScrollCalls, 1);
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(dataSet.errors.messages.isNotEmpty, isFalse);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'parent column reorder updates visual order when no user reorder override exists',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'first'),
            FdcStringField(size: 255, name: 'second'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'first': 'Alpha', 'second': 'Beta'},
            ],
          ),
        );
        dataSet.open();
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'first', label: 'First'),
            FdcTextColumn<dynamic>(fieldName: 'second', label: 'Second'),
          ],
        );

        expect(
          tester.getTopLeft(find.text('First')).dx,
          lessThan(tester.getTopLeft(find.text('Second')).dx),
        );

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'second', label: 'Second'),
            FdcTextColumn<dynamic>(fieldName: 'first', label: 'First'),
          ],
        );

        expect(
          tester.getTopLeft(find.text('Second')).dx,
          lessThan(tester.getTopLeft(find.text('First')).dx),
        );
      },
    );

    testWidgets(
      'sort indicator is scoped to runtime column identity for duplicate field columns',
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
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name A'),
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name B'),
          ],
        );

        expect(find.byIcon(Icons.north), findsNothing);
        expect(find.byIcon(Icons.more_vert), findsNWidgets(2));

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await uxPumpPendingFrames(tester);

        expect(dataSet.sort.items, isEmpty);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await uxPumpPendingFrames(tester);

        await tester.tap(find.text('Name A'));
        await uxPumpPendingFrames(tester);

        expect(find.byIcon(Icons.north), findsOneWidget);
        expect(find.byIcon(Icons.unfold_more), findsNothing);
        expect(find.byIcon(Icons.more_vert), findsNWidgets(2));
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Dataset Guard Identity', () {
    _registerDatasetGuardIdentityTests();
  });
}
