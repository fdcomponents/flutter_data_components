import 'fdc_grid_ux_test_support.dart';

void _registerEditingLifecycleErrorTests() {
  group('Editing lifecycle and errors', () {
    testWidgets(
      'beforeInsert abort from grid auto append shows dataset error dialog',
      (tester) async {
        var beforeInsertCalls = 0;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
          beforeInsert: (dataSet) {
            beforeInsertCalls++;
            throw FdcDataSetAbortException('Insert is not allowed.');
          },

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
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await uxPumpPendingFrames(tester);

        expect(beforeInsertCalls, 1);
        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.recordCount, 1);
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
        expect(dataSet.errors.messages[0], 'Insert is not allowed.');
        expect(find.text('Insert is not allowed.'), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
      },
    );

    testWidgets('beforeEdit abort from grid shows dataset error dialog', (
      tester,
    ) async {
      var beforeEditCalls = 0;
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
        beforeEdit: (dataSet) {
          beforeEditCalls++;
          throw FdcDataSetAbortException('Edit is not allowed.');
        },

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
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await uxPumpPendingFrames(tester);

      expect(beforeEditCalls, 1);
      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.errors.messages.isNotEmpty, isTrue);
      expect(dataSet.errors.messages[0], 'Edit is not allowed.');
      expect(find.text('Edit is not allowed.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets(
      'silent beforeEdit abort from grid does not show error dialog',
      (tester) async {
        var beforeEditCalls = 0;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
          beforeEdit: (dataSet) {
            beforeEditCalls++;
            throw const FdcDataSetAbortException.silent();
          },

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
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
        await uxPumpPendingFrames(tester);

        expect(beforeEditCalls, 1);
        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.errors.messages.isNotEmpty, isFalse);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(TextFormField), findsNothing);
      },
    );

    testWidgets(
      'silent beforeInsert abort from grid auto append does not show error dialog',
      (tester) async {
        var beforeInsertCalls = 0;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],
          beforeInsert: (dataSet) {
            beforeInsertCalls++;
            throw const FdcDataSetAbortException.silent();
          },

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
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await uxPumpPendingFrames(tester);

        expect(beforeInsertCalls, 1);
        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.recordCount, 1);
        expect(dataSet.errors.messages.isNotEmpty, isFalse);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(TextFormField), findsNothing);
      },
    );

    testWidgets(
      'grid keeps externally posted row visible until filter is explicitly reapplied',
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

        dataSet.filter.where('status').equals('active').apply();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
            FdcTextColumn<dynamic>(fieldName: 'status'),
          ],
        );

        expect(dataSet.recordCount, 1);
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsNothing);

        dataSet.edit();
        dataSet.setFieldValue('status', 'inactive');
        dataSet.post();
        await uxPumpPendingFrames(tester);

        expect(dataSet.recordCount, 1);
        expect(dataSet.fieldValue('name'), 'Alpha');
        expect(dataSet.fieldValue('status'), 'inactive');
        expect(find.text('Alpha'), findsOneWidget);
      },
    );

    testWidgets(
      'leaving unchanged header filter does not reapply active filter',
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

        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsNothing);

        dataSet.append();
        dataSet.setFieldValue('name', 'Gamma');
        dataSet.setFieldValue('status', 'inactive');
        dataSet.post();
        await uxPumpPendingFrames(tester);

        expect(find.text('Gamma'), findsOneWidget);

        await tester.tap(find.byType(EditableText).at(1));
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Alpha').first);
        await uxPumpPendingFrames(tester);

        expect(find.text('Gamma'), findsOneWidget);
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Editing Lifecycle Error', () {
    _registerEditingLifecycleErrorTests();
  });
}
