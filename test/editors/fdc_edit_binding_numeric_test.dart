import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'integer edit emits non-blocking validation without inline error by default',
    (tester) async {
      final validationMessages = <String>[];
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'age', label: 'Age', minValue: 15),
        ],
        onValidationError: (dataSet, errors) {
          validationMessages.addAll(errors.map((error) => error.message));
        },

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'age': 20},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcIntegerEdit(dataSet: dataSet, fieldName: 'age'),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), '1');
      await tester.pump();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.fieldValue('age'), 20);
      expect(find.textContaining('15'), findsNothing);

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet.fieldValue('age'), 1);
      expect(
        validationMessages.any((message) => message.contains('15')),
        isTrue,
      );
      expect(find.textContaining('15'), findsNothing);
    },
  );

  testWidgets(
    'integer edit shows error indicator and does not block focus traversal',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'age', label: 'Age', minValue: 15),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'age': 20},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: [
                FdcIntegerEdit(dataSet: dataSet, fieldName: 'age'),
                const TextField(key: Key('next-field')),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, '1');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet.fieldValue('age'), 1);
      expect(find.textContaining('15'), findsNothing);
      final nextEditable = find.descendant(
        of: find.byKey(const Key('next-field')),
        matching: find.byType(EditableText),
      );
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .focusNode
            .hasFocus,
        isFalse,
      );
      expect(
        tester.widget<EditableText>(nextEditable).focusNode.hasFocus,
        isTrue,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip && widget.message?.contains('15') == true,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'integer edit remains keyboard reachable after external same-field validation error',
    (tester) async {
      for (final mode in <FdcErrorIndicatorMode>[
        FdcErrorIndicatorMode.marker,
        FdcErrorIndicatorMode.inline,
      ]) {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(name: 'name', label: 'Name', size: 20),
            FdcIntegerField(name: 'age', label: 'Age', minValue: 15),
            FdcDecimalField(
              name: 'balance',
              label: 'Balance',
              precision: 12,
              scale: 2,
            ),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alice', 'age': 20, 'balance': 10.0},
            ],
          ),
        )..open();

        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: Column(
                children: [
                  FdcTextEdit(dataSet: dataSet, fieldName: 'name'),
                  FdcIntegerEdit(
                    dataSet: dataSet,
                    fieldName: 'age',
                    errorIndicator: FdcErrorIndicatorOptions(mode: mode),
                  ),
                  FdcDecimalEdit(dataSet: dataSet, fieldName: 'balance'),
                ],
              ),
            ),
          ),
        );

        dataSet.edit();
        dataSet.setFieldValue('age', 1);
        FdcDataSetInternal.validateFieldValueAndEmit(dataSet, 'age', 1);
        await tester.pump();

        final ageEditable = find.descendant(
          of: find.byType(FdcIntegerEdit),
          matching: find.byType(EditableText),
        );

        await tester.tap(
          find.descendant(
            of: find.byType(FdcTextEdit),
            matching: find.byType(TextFormField),
          ),
        );
        await tester.pump();

        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();

        expect(
          tester.widget<EditableText>(ageEditable).focusNode.hasFocus,
          isTrue,
        );

        await tester.tap(
          find.descendant(
            of: find.byType(FdcTextEdit),
            matching: find.byType(TextFormField),
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        expect(
          tester.widget<EditableText>(ageEditable).focusNode.hasFocus,
          isTrue,
        );
      }
    },
  );

  testWidgets(
    'integer edit with validation error remains a keyboard traversal target',
    (tester) async {
      for (final mode in <FdcErrorIndicatorMode>[
        FdcErrorIndicatorMode.marker,
        FdcErrorIndicatorMode.inline,
      ]) {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(name: 'name', label: 'Name', size: 20),
            FdcIntegerField(name: 'age', label: 'Age', minValue: 15),
            FdcDecimalField(
              name: 'balance',
              label: 'Balance',
              precision: 12,
              scale: 2,
            ),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Alice', 'age': 20, 'balance': 10.0},
            ],
          ),
        )..open();

        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: Column(
                children: [
                  FdcTextEdit(dataSet: dataSet, fieldName: 'name'),
                  FdcIntegerEdit(
                    dataSet: dataSet,
                    fieldName: 'age',
                    errorIndicator: FdcErrorIndicatorOptions(mode: mode),
                  ),
                  FdcDecimalEdit(dataSet: dataSet, fieldName: 'balance'),
                ],
              ),
            ),
          ),
        );

        final ageEditable = find.descendant(
          of: find.byType(FdcIntegerEdit),
          matching: find.byType(EditableText),
        );
        final balanceEditable = find.descendant(
          of: find.byType(FdcDecimalEdit),
          matching: find.byType(EditableText),
        );

        await tester.tap(
          find.descendant(
            of: find.byType(FdcIntegerEdit),
            matching: find.byType(TextFormField),
          ),
        );
        await tester.enterText(
          find.descendant(
            of: find.byType(FdcIntegerEdit),
            matching: find.byType(TextFormField),
          ),
          '1',
        );
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();

        expect(dataSet.fieldValue('age'), 1);
        expect(
          tester.widget<EditableText>(balanceEditable).focusNode.hasFocus,
          isTrue,
        );

        await tester.tap(
          find.descendant(
            of: find.byType(FdcTextEdit),
            matching: find.byType(TextFormField),
          ),
        );
        await tester.pump();

        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();

        expect(
          tester.widget<EditableText>(ageEditable).focusNode.hasFocus,
          isTrue,
        );

        await tester.tap(
          find.descendant(
            of: find.byType(FdcTextEdit),
            matching: find.byType(TextFormField),
          ),
        );
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        expect(
          tester.widget<EditableText>(ageEditable).focusNode.hasFocus,
          isTrue,
        );
      }
    },
  );

  testWidgets('integer edit can hide validation feedback', (tester) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'age', label: 'Age', minValue: 15),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'age': 20},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: [
              FdcIntegerEdit(
                dataSet: dataSet,
                fieldName: 'age',
                errorIndicator: const FdcErrorIndicatorOptions(
                  mode: FdcErrorIndicatorMode.none,
                ),
              ),
              const TextField(key: Key('next-field')),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField).first);
    await tester.enterText(find.byType(TextFormField).first, '1');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(dataSet.fieldValue('age'), 1);
    final nextEditable = find.descendant(
      of: find.byKey(const Key('next-field')),
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(nextEditable).focusNode.hasFocus,
      isTrue,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Tooltip && widget.message?.contains('15') == true,
      ),
      findsNothing,
    );
  });

  testWidgets(
    'integer edit can show non-blocking inline validation through validation mode',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'age', label: 'Age', minValue: 15),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'age': 20},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcIntegerEdit(
              dataSet: dataSet,
              fieldName: 'age',
              errorIndicator: const FdcErrorIndicatorOptions(
                mode: FdcErrorIndicatorMode.inline,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), '1');
      await tester.pump();

      expect(find.textContaining('15'), findsNothing);

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet.fieldValue('age'), 1);
      expect(find.textContaining('15'), findsOneWidget);
    },
  );

  testWidgets('escape reverts local editor buffer without canceling dataset', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'name', label: 'Name', size: 20),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alice'},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcTextEdit(dataSet: dataSet, fieldName: 'name'),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'Megan');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(dataSet.state, FdcDataSetState.browse);
    expect(dataSet.fieldValue('name'), 'Alice');
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets(
    'memo edit keeps plain Enter as newline and commits on Ctrl+Enter',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'notes', label: 'Notes', size: 100),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'notes': 'Line 1'},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcMemoEdit(dataSet: dataSet, fieldName: 'notes'),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Line 1\nLine 2');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.fieldValue('notes'), 'Line 1');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet.fieldValue('notes'), 'Line 1\nLine 2');
    },
  );

  testWidgets(
    'navigation keys without standalone meaning stay native and do not move focus or commit editor',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'name', label: 'Name', size: 20),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alice'},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: [
                FdcTextEdit(dataSet: dataSet, fieldName: 'name'),
                const TextField(key: Key('other-field')),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Megan');
      await tester.pump();

      final firstEditableText = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(firstEditableText.focusNode.hasFocus, isTrue);

      for (final key in <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.pageDown,
        LogicalKeyboardKey.pageUp,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();

        expect(firstEditableText.focusNode.hasFocus, isTrue);
        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.fieldValue('name'), 'Alice');
      }
    },
  );

  testWidgets('decimal edit commits scale-limited decimal text', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcDecimalField(
          name: 'amount',
          label: 'Amount',
          precision: 5,
          scale: 2,
        ),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'amount': 1.2},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcDecimalEdit(dataSet: dataSet, fieldName: 'amount'),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), '123.67');
    await tester.pump();

    expect(dataSet.state, FdcDataSetState.browse);
    expect(dataSet.fieldByName('amount').asNum, 1.2);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(dataSet.state, FdcDataSetState.edit);
    expect(dataSet.fieldByName('amount').asNum, 123.67);
    expect(find.text('123.67'), findsOneWidget);
  });

  testWidgets('decimal edit accepts exact scale boundary on commit', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcDecimalField(
          name: 'amount',
          label: 'Amount',
          precision: 6,
          scale: 2,
        ),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'amount': 1.2},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcDecimalEdit(dataSet: dataSet, fieldName: 'amount'),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), '1.01');
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(dataSet.fieldByName('amount').asNum, 1.01);
    expect(find.text('1.01'), findsOneWidget);
  });

  testWidgets('decimal edit blocks scale overflow while typing', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcDecimalField(
          name: 'amount',
          label: 'Amount',
          precision: 5,
          scale: 2,
        ),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'amount': 1.2},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcDecimalEdit(
            dataSet: dataSet,
            fieldName: 'amount',
            errorIndicator: const FdcErrorIndicatorOptions(
              mode: FdcErrorIndicatorMode.inline,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), '999.99');
    await tester.pump();

    var editableText = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    expect(editableText.controller.text, '999.99');

    await tester.enterText(find.byType(TextFormField), '999.995');
    await tester.pump();

    editableText = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(editableText.controller.text, '999.99');
    expect(find.textContaining('precision 5 and scale 2'), findsNothing);
  });
}
