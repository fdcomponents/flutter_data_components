import 'fdc_grid_ux_test_support.dart';

void _registerEditingDecimalTests() {
  group('Editing decimal behavior', () {
    testWidgets('Calculated field refreshes and stays non-editable', (
      tester,
    ) async {
      final dataSet = uxCalculatedDataSet();
      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'quantity'),
          FdcDecimalColumn<dynamic>(fieldName: 'total'),
        ],
      );

      expect(find.text('50.00'), findsOneWidget);

      await tester.tap(find.text('50.00'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);
      expect(find.byType(TextFormField), findsNothing);

      await tester.tap(find.text('5'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);
      expect(find.byType(EditableText), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '6');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await uxPumpPendingFrames(tester);

      expect(dataSet.fieldByName('total').asNum, 60);
      expect(find.text('60.00'), findsOneWidget);
    });

    testWidgets('Decimal column formats and edits scale-limited decimal text', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 5, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1.2},
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
      );

      expect(find.text('1.20'), findsOneWidget);

      await tester.tap(find.text('1.20'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);

      await tester.enterText(find.byType(EditableText), '123.67');
      await tester.pump();

      final editableText = tester.widget<EditableText>(
        find.byType(EditableText).last,
      );
      expect(editableText.controller.text, '123.67');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await uxPumpPendingFrames(tester);

      expect(
        (FdcDataSetInternal.fieldValueAt(dataSet, 0, 'amount') as FdcDecimal)
            .toNum(),
        123.67,
      );
      expect(find.text('123.67'), findsOneWidget);
    });

    testWidgets('Decimal column accepts exact scale boundary on commit', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 6, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1.2},
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
      );

      await tester.tap(find.text('1.20'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);

      await tester.enterText(find.byType(EditableText), '1.01');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await uxPumpPendingFrames(tester);

      expect(
        (FdcDataSetInternal.fieldValueAt(dataSet, 0, 'amount') as FdcDecimal)
            .toNum(),
        1.01,
      );
      expect(find.text('1.01'), findsOneWidget);
    });

    testWidgets('Decimal column rejects precision overflow on commit', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 5, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1.2},
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
      );

      await tester.tap(find.text('1.20'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);

      final editableText = tester.widget<EditableText>(
        find.byType(EditableText).last,
      );
      editableText.controller.text = '12345.67';
      editableText.controller.selection = const TextSelection.collapsed(
        offset: 8,
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      // The rejected commit intentionally keeps the in-place editor focused,
      // so waiting for a fully settled frame can hang on the active text
      // input/caret pipeline. Pump only the validation response frame.
      await tester.pump();

      expect(
        (FdcDataSetInternal.fieldValueAt(dataSet, 0, 'amount') as FdcDecimal)
            .toNum(),
        1.2,
      );
      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('Decimal header filter uses decimal column format', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1234.56},
            {'amount': 2000.00},
            {'amount': 12.30},
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
            label: 'Amount',
            formatSettings: FdcFormatSettings(
              decimalSeparator: ',',
              thousandSeparator: '.',
            ),
          ),
        ],
        header: uxZeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).last, '1.234,56');
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 1);
      expect(
        (FdcDataSetInternal.fieldValueAt(dataSet, 0, 'amount') as FdcDecimal)
            .toNum(),
        1234.56,
      );
      expect(find.text('1.234,56'), findsWidgets);
      expect(find.text('2.000,00'), findsNothing);
    });

    testWidgets('Decimal header filter displays grouped column decimal text', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1500.21},
            {'amount': 2000.00},
          ],
        ),
      );
      dataSet.open();

      const formats = FdcFormatSettings();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(
            fieldName: 'amount',
            label: 'Amount',
            formatSettings: formats,
          ),
        ],
        header: uxZeroDebounceHeader,
      );

      await tester.enterText(find.byType(EditableText).last, '1500.21');
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 1);
      expect(find.text('1500.21'), findsWidgets);

      await tester.tap(find.text('1,500.21'));
      await uxPumpPendingFrames(tester);

      expect(find.text('1,500.21'), findsWidgets);
    });

    testWidgets('between decimal range fields use column decimal format', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(name: 'amount', precision: 12, scale: 2),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1000.00},
            {'amount': 1500.25},
            {'amount': 2500.00},
          ],
        ),
      );
      dataSet.open();

      const formats = FdcFormatSettings(
        decimalSeparator: ',',
        thousandSeparator: '.',
      );

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcDecimalColumn<dynamic>(
            fieldName: 'amount',
            label: 'Amount',
            formatSettings: formats,
          ),
        ],
        header: uxZeroDebounceHeader,
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await uxPumpPendingFrames(tester);
      await tester.tap(find.text('Between'));
      await uxPumpPendingFrames(tester);

      final fields = uxHeaderRangeFilterTextFields();
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '1000,00');
      await tester.enterText(fields.at(1), '2000,00');
      await uxPumpPendingFrames(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.text('1.000,00'), findsWidgets);
      expect(find.text('2000,00'), findsOneWidget);

      await tester.tap(find.text('Apply'));
      await uxPumpPendingFrames(tester);

      expect(dataSet.recordCount, 2);
      expect(find.text('1.000,00'), findsWidgets);
      expect(find.text('1.500,25'), findsOneWidget);
      expect(find.text('2.500,00'), findsNothing);
    });
  });
}

void main() {
  group('FdcGrid widget UX / Editing Decimal', () {
    _registerEditingDecimalTests();
  });
}
