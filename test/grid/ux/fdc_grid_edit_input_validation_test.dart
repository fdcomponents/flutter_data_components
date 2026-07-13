import 'fdc_grid_ux_test_support.dart';

void _registerEditInputValidationTests() {
  group('Edit input and validation', () {
    testWidgets(
      'Immediate min/max validation accepts invalid cell value without inline dialog',
      (tester) async {
        final validationMessages = <String>[];
        final dataSet = uxQuantityDataSet(
          onValidationError: (_, errors) {
            validationMessages.addAll(errors.map((error) => error.message));
          },
        );
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'quantity'),
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
          ],
        );

        await tester.tap(find.text('5'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await uxPumpPendingFrames(tester);
        await tester.enterText(find.byType(EditableText), '20');
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await uxPumpPendingFrames(tester);

        expect(find.text('Validation error'), findsNothing);
        expect(
          find.text('Field Quantity must be less than or equal to 10.'),
          findsNothing,
        );
        expect(dataSet.fieldValue('quantity'), 20);
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
        expect(
          validationMessages.any(
            (message) => message.contains('less than or equal to 10'),
          ),
          isTrue,
        );
        expect(find.byType(TextFormField), findsNothing);
      },
    );

    testWidgets('Text column limits input length from string field metadata', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(name: 'code', size: 3),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'code': 'Ab'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'code', showCounter: true),
        ],
      );

      await tester.tap(find.text('Ab'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);

      expect(find.text('2/3'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'ABCDE');
      await tester.pump();

      expect(find.text('3/3'), findsOneWidget);
      expect(find.text('2/3'), findsNothing);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .controller
            .text,
        'ABC',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await uxPumpPendingFrames(tester);

      expect(find.text('Validation error'), findsNothing);
      expect(find.textContaining('would be truncated'), findsNothing);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'code'), 'ABC');
    });

    testWidgets('Text column limits input length even without counter', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'code', size: 3)],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'code': 'Ab'},
          ],
        ),
      );
      dataSet.open();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'code'),
        ],
      );

      await tester.tap(find.text('Ab'));
      await uxPumpPendingFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await uxPumpPendingFrames(tester);

      await tester.enterText(find.byType(EditableText), 'ABCDE');
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).last)
            .controller
            .text,
        'ABC',
      );
    });

    testWidgets(
      'Tab follows column focusOrder order while Enter keeps visual order',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'a'),
            FdcStringField(size: 255, name: 'b'),
            FdcStringField(size: 255, name: 'c'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'a': 'A1', 'b': 'B1', 'c': 'C1'},
            ],
          ),
        );
        dataSet.open();
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'a', focusOrder: 1),
            FdcTextColumn<dynamic>(fieldName: 'b', focusOrder: 3),
            FdcTextColumn<dynamic>(fieldName: 'c', focusOrder: 2),
          ],
        );

        await tester.tap(find.text('A1'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
        await uxPumpPendingFrames(tester);

        expect(find.byType(EditableText), findsOneWidget);
        var editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'x');

        await tester.tap(find.text('B1'));
        await uxPumpPendingFrames(tester);

        expect(dataSet.fieldValue('b'), 'B1');
        expect(dataSet.fieldValue('c'), 'x');

        final enterDataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'a'),
            FdcStringField(size: 255, name: 'b'),
            FdcStringField(size: 255, name: 'c'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'a': 'A1', 'b': 'B1', 'c': 'C1'},
            ],
          ),
        );
        enterDataSet.open();

        await uxPumpGrid(
          tester,
          dataSet: enterDataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'a', focusOrder: 1),
            FdcTextColumn<dynamic>(fieldName: 'b', focusOrder: 3),
            FdcTextColumn<dynamic>(fieldName: 'c', focusOrder: 2),
          ],
        );

        await tester.tap(find.text('A1'));
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
        await uxPumpPendingFrames(tester);

        expect(find.byType(EditableText), findsOneWidget);
        editor = tester.widget<EditableText>(find.byType(EditableText));
        expect(editor.controller.text, 'y');

        await tester.tap(find.text('C1'));
        await uxPumpPendingFrames(tester);

        expect(enterDataSet.fieldValue('b'), 'y');
        expect(enterDataSet.fieldValue('c'), 'C1');
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Edit Input Validation', () {
    _registerEditInputValidationTests();
  });
}
