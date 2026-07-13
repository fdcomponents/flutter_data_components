import 'fdc_grid_ux_test_support.dart';

void _registerHeaderFilterValidationTests() {
  group('Header filter validation', () {
    testWidgets('between operator opens range form and applies only on Apply', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 10.00},
            {'amount': 20.00},
            {'amount': 30.00},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
        ],
        header: uxZeroDebounceHeader,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Between'));
      await uxPumpPendingFrames(tester);

      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);

      final fields = uxHeaderRangeFilterTextFields();
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '15.00');
      await tester.enterText(fields.at(1), '25.00');
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 3);
      expect(find.text('10.00'), findsOneWidget);
      expect(find.text('30.00'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 1);
      expect(find.text('20.00'), findsOneWidget);
      expect(find.text('10.00'), findsNothing);
      expect(find.text('30.00'), findsNothing);
    });

    testWidgets('between apply requires both fields with valid values', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 10.00},
            {'amount': 20.00},
            {'amount': 30.00},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
        ],
        header: uxZeroDebounceHeader,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Between'));
      await uxPumpPendingFrames(tester);

      FilledButton applyButton() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Apply'),
      );

      expect(applyButton().onPressed, isNull);

      final fields = uxHeaderRangeFilterTextFields();
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '15.00');
      await uxPumpPendingFrames(tester);
      expect(applyButton().onPressed, isNull);

      await tester.enterText(fields.at(1), 'abc');
      await uxPumpPendingFrames(tester);
      expect(applyButton().onPressed, isNull);

      await tester.enterText(fields.at(1), '25.00');
      await uxPumpPendingFrames(tester);
      expect(applyButton().onPressed, isNotNull);

      applyButton().onPressed!();
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 1);
      expect(find.text('20.00'), findsOneWidget);
    });

    testWidgets(
      'between apply consumes auto-open token before layout rebuilds',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'amount': 10.00},
              {'amount': 20.00},
              {'amount': 30.00},
            ],
          ),
        );
        dataSet.open();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
          ],
          header: uxZeroDebounceHeader,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Between'));
        await uxPumpPendingFrames(tester);

        final fields = uxHeaderRangeFilterTextFields();
        await tester.enterText(fields.at(0), '15.00');
        await tester.enterText(fields.at(1), '25.00');
        await uxPumpPendingFrames(tester);

        await tester.tap(find.text('Apply'));
        await uxPumpPendingFrames(tester);

        expect(find.text('From'), findsNothing);
        expect(find.text('To'), findsNothing);
        expect(dataSet.recordCount, 1);

        await tester.pumpWidget(const SizedBox.shrink());
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
          ],
          header: uxZeroDebounceHeader,
        );
        await uxPumpPendingFrames(tester);

        expect(find.text('From'), findsNothing);
        expect(find.text('To'), findsNothing);
        expect(dataSet.recordCount, 1);
      },
    );

    testWidgets(
      'switching from between to scalar operator clears range value',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcDecimalField(name: 'amount', precision: 12, scale: 2),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'amount': 10.00},
              {'amount': 20.00},
              {'amount': 30.00},
            ],
          ),
        );
        dataSet.open();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
          ],
          header: uxZeroDebounceHeader,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Between'));
        await uxPumpPendingFrames(tester);

        final fields = uxHeaderRangeFilterTextFields();
        await tester.enterText(fields.at(0), '15.00');
        await tester.enterText(fields.at(1), '25.00');
        await uxPumpPendingFrames(tester);

        await tester.tap(find.text('Apply'));
        await uxPumpPendingFrames(tester);

        expect(dataSet.recordCount, 1);
        expect(find.text('20.00'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.more_vert));
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Equals').last);
        await uxPumpPendingFrames(tester);

        expect(dataSet.recordCount, 3);
        expect(find.text('10.00'), findsOneWidget);
        expect(find.text('20.00'), findsOneWidget);
        expect(find.text('30.00'), findsOneWidget);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText).last)
              .controller
              .text,
          '',
        );
      },
    );

    testWidgets('selecting an empty scalar filter operator focuses its input', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();

      await uxPumpFilterGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      final nameFilter = tester.widget<EditableText>(
        find.byType(EditableText).at(1),
      );
      expect(nameFilter.controller.text, isEmpty);
      expect(nameFilter.focusNode.hasFocus, isFalse);

      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Equals').last);
      await uxPumpPendingFrames(tester);

      expect(nameFilter.focusNode.hasFocus, isTrue);
    });

    testWidgets('text header filter uses grid-safe edit context menu', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();

      await uxPumpFilterGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      final textField = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(textField.contextMenuBuilder, isNotNull);
      expect(textField.groupId, same(fdcGridTapRegionGroup));
    });

    testWidgets(
      'clearing text header filter value preserves selected scalar operator and focus',
      (tester) async {
        final dataSet = uxPeopleDataSet();

        await uxPumpFilterGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        final filterFinder = find.byType(EditableText).at(1);
        await tester.tap(find.byIcon(Icons.more_vert).at(1));
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Equals').last);
        await uxPumpPendingFrames(tester);

        await tester.enterText(filterFinder, 'Alpha');
        await uxPumpPendingFrames(tester);
        expect(
          dataSet.filter.fieldItems.single.operator,
          FdcFilterOperator.equals,
        );
        expect(dataSet.recordCount, 1);

        await tester.enterText(filterFinder, '');
        await uxPumpPendingFrames(tester);

        final clearedFilter = tester.widget<EditableText>(filterFinder);
        expect(clearedFilter.controller.text, isEmpty);
        expect(clearedFilter.focusNode.hasFocus, isTrue);
        expect(dataSet.recordCount, 2);

        await tester.enterText(filterFinder, 'Al');
        await uxPumpPendingFrames(tester);

        expect(
          dataSet.filter.fieldItems.single.operator,
          FdcFilterOperator.equals,
        );
        expect(dataSet.recordCount, 0);
      },
    );

    testWidgets('between cancel restores previous header filter state', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 10.00},
            {'amount': 20.00},
            {'amount': 30.00},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
        ],
        header: uxZeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).last, '20.00');
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 1);
      expect(find.text('20.00'), findsWidgets);

      await tester.tap(find.byIcon(Icons.more_vert));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Between'));
      await uxPumpPendingFrames(tester);

      expect(find.text('From'), findsOneWidget);
      expect(find.text('20.00'), findsWidgets);
      expect(find.text('No range filter'), findsNothing);

      await tester.tap(find.text('Cancel'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 1);
      expect(find.text('20.00'), findsWidgets);
      expect(find.text('From'), findsNothing);
    });

    testWidgets(
      'between DateTime fields normalize date-only input on field exit',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcDateTimeField(name: 'createdAt')],
          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              {'createdAt': DateTime(2029, 12, 31)},
              {'createdAt': DateTime(2029, 12, 31, 14, 30)},
              {'createdAt': DateTime(2030)},
            ],
          ),
        );
        dataSet.open();

        const formats = FdcFormatSettings(
          dateFormat: 'MM/dd/yyyy',
          dateTimeFormat: 'MM/dd/yyyy HH:mm',
        );

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcDateTimeColumn<dynamic>(
              fieldName: 'createdAt',
              label: 'Created',
              formatSettings: formats,
            ),
          ],
          header: uxZeroDebounceHeader,
          formatSettings: formats,
        );

        await tester.tap(find.byIcon(Icons.more_vert));
        await uxPumpPendingFrames(tester);
        await tester.tap(find.text('Between'));
        await uxPumpPendingFrames(tester);

        final fields = uxHeaderRangeFilterTextFields();
        expect(fields, findsNWidgets(2));
        await tester.enterText(fields.at(0), '12/31/2029');
        await tester.tap(fields.at(1));
        await uxPumpPendingFrames(tester);

        final fromTextField = tester.widget<TextField>(
          uxHeaderRangeFilterTextFields().at(0),
        );
        expect(fromTextField.controller?.text, '12/31/2029 00:00');
        expect(dataSet.recordCount, 3);

        await tester.enterText(
          uxHeaderRangeFilterTextFields().at(1),
          '12/31/2029',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.tap(find.text('Apply'));
        await uxPumpPendingFrames(tester);

        expect(dataSet.recordCount, 1);
        expect(
          find.text('12/31/2029 00:00 – 12/31/2029 00:00'),
          findsOneWidget,
        );
      },
    );

    testWidgets('between range form captures keyboard inside popup', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 10.00},
            {'amount': 20.00},
            {'amount': 30.00},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(fieldName: 'amount', label: 'Amount'),
        ],
        header: uxZeroDebounceHeader,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Between'));
      await uxPumpPendingFrames(tester);

      final fields = uxHeaderRangeFilterTextFields();
      expect(fields, findsNWidgets(2));

      await tester.tap(fields.at(0));
      await tester.enterText(fields.at(0), '15.00');
      await uxPumpPendingFrames(tester);

      TextField fromField = tester.widget<TextField>(fields.at(0));
      TextField toField = tester.widget<TextField>(fields.at(1));
      expect(fromField.focusNode?.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      fromField = tester.widget<TextField>(fields.at(0));
      expect(fromField.focusNode?.hasFocus, isTrue);
      expect(fromField.controller?.selection.baseOffset, 4);
      expect(find.text('Apply'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();

      fromField = tester.widget<TextField>(fields.at(0));
      expect(fromField.focusNode?.hasFocus, isTrue);
      expect(fromField.controller?.selection.baseOffset, 0);
      expect(find.text('Apply'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      toField = tester.widget<TextField>(fields.at(1));
      expect(toField.focusNode?.hasFocus, isTrue);
      expect(find.text('Apply'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      fromField = tester.widget<TextField>(fields.at(0));
      expect(fromField.focusNode?.hasFocus, isTrue);
      expect(find.text('Apply'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      fromField = tester.widget<TextField>(fields.at(0));
      expect(fromField.focusNode?.hasFocus, isTrue);
      expect(find.text('Apply'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      toField = tester.widget<TextField>(fields.at(1));
      expect(toField.focusNode?.hasFocus, isTrue);
      expect(find.text('Apply'), findsOneWidget);
      expect(dataSet.recordCount, 3);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      toField = tester.widget<TextField>(fields.at(1));
      expect(toField.focusNode?.hasFocus, isTrue);
      expect(find.text('Apply'), findsOneWidget);
      expect(dataSet.recordCount, 3);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await uxPumpPendingFrames(tester);

      expect(find.text('Apply'), findsOneWidget);
      expect(dataSet.recordCount, 3);
      expect(find.text('Required'), findsOneWidget);

      await tester.enterText(fields.at(1), '25.00');
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await uxPumpPendingFrames(tester);

      expect(find.text('Apply'), findsNothing);
      expect(dataSet.recordCount, 1);
      expect(find.text('20.00'), findsOneWidget);
      expect(find.text('10.00'), findsNothing);
      expect(find.text('30.00'), findsNothing);
    });
  });
}

void main() {
  group('FdcGrid widget UX / Header Filter Validation', () {
    _registerHeaderFilterValidationTests();
  });
}
