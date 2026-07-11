import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_data_components/src/editors/core/fdc_editor_core.dart';
import 'package:flutter_data_components/src/editors/core/fdc_editor_descriptor.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReadOnlyMemoryDataAdapter extends FdcMemoryDataAdapter {
  _ReadOnlyMemoryDataAdapter({required super.rows});

  @override
  bool get readOnly => true;
}

void main() {
  testWidgets('text edit commits to dataset on enter', (tester) async {
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

    expect(find.text('Alice'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isFalse,
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'Megan');
    await tester.pump();

    expect(dataSet.state, FdcDataSetState.browse);
    expect(dataSet.fieldValue('name'), 'Alice');

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(dataSet.state, FdcDataSetState.edit);
    expect(dataSet.fieldValue('name'), 'Megan');
  });

  testWidgets('text edit binds guid field as read-only display', (
    tester,
  ) async {
    final guid = FdcGuid.parse('a0ebd67f-6f77-4a8e-9f41-b04d08764f01');
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcGuidField(name: 'id', label: 'ID')],

      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          {'id': guid},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcTextEdit(dataSet: dataSet, fieldName: 'id'),
        ),
      ),
    );

    expect(find.text('a0ebd67f-6f77-4a8e-9f41-b04d08764f01'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isTrue,
    );
  });

  testWidgets('text edit does not mutate guid field from user input', (
    tester,
  ) async {
    final guid = FdcGuid.parse('a0ebd67f-6f77-4a8e-9f41-b04d08764f01');
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcGuidField(name: 'id', label: 'ID')],

      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          {'id': guid},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcTextEdit(dataSet: dataSet, fieldName: 'id'),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(
      find.byType(TextFormField),
      'ffffffff-ffff-4fff-bfff-ffffffffffff',
    );
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(dataSet.state, FdcDataSetState.browse);
    expect(dataSet.fieldValue('id'), guid);
  });

  testWidgets('text edit rejects non-string field binding', (tester) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'qty')],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'qty': 1},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcTextEdit(dataSet: dataSet, fieldName: 'qty'),
        ),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('text edit does not enter dataset edit mode on focus', (
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

    expect(dataSet.state, FdcDataSetState.browse);
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    expect(dataSet.state, FdcDataSetState.browse);
  });

  testWidgets(
    'decimal edit focus normalization does not enter dataset edit mode',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(
            name: 'amount',
            label: 'Amount',
            precision: 10,
            scale: 2,
          ),
          FdcStringField(name: 'name', label: 'Name', size: 20),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1234.5, 'name': 'Alice'},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcApp(
              formatSettings: const FdcFormatSettings(),
              child: Column(
                children: [
                  FdcDecimalEdit(dataSet: dataSet, fieldName: 'amount'),
                  FdcTextEdit(dataSet: dataSet, fieldName: 'name'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(dataSet.state, FdcDataSetState.browse);
      await tester.tap(find.byType(TextFormField).first);
      await tester.pump();
      expect(dataSet.state, FdcDataSetState.browse);

      await tester.tap(find.byType(TextFormField).last);
      await tester.pump();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.fieldByName('amount').asDecimal, 1234.5.decimal);
    },
  );

  testWidgets(
    'typed bound editors do not enter dataset edit mode on focus only',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'age', label: 'Age'),
          FdcDateField(name: 'birthDate', label: 'Birth date'),
          FdcDateTimeField(name: 'lastContact', label: 'Last contact'),
          FdcTimeField(name: 'time', label: 'Time'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {
              'age': 20,
              'birthDate': DateTime(2026, 5, 16),
              'lastContact': DateTime(2026, 5, 16, 10, 30),
              'time': DateTime(2026, 1, 1, 8, 15),
            },
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcApp(
              formatSettings: const FdcFormatSettings(dateFormat: 'dd.MM.yyyy'),
              child: Column(
                children: [
                  FdcIntegerEdit(dataSet: dataSet, fieldName: 'age'),
                  FdcDateEdit(dataSet: dataSet, fieldName: 'birthDate'),
                  FdcDateTimeEdit(dataSet: dataSet, fieldName: 'lastContact'),
                  FdcTimeEdit(dataSet: dataSet, fieldName: 'time'),
                ],
              ),
            ),
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      for (var index = 0; index < 4; index++) {
        await tester.tap(fields.at(index));
        await tester.pump();
        expect(dataSet.state, FdcDataSetState.browse);
      }
    },
  );

  testWidgets('text edit selectAllOnFocus selects text after tap focus', (
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
          child: FdcTextEdit(
            dataSet: dataSet,
            fieldName: 'name',
            selectAllOnFocus: true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.pump();

    final editableText = tester.widget<EditableText>(find.byType(EditableText));
    expect(editableText.controller.selection.baseOffset, 0);
    expect(editableText.controller.selection.extentOffset, 5);
  });

  testWidgets('text edit uses white fill color for editable state', (
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

    final decoration = tester
        .widget<InputDecorator>(find.byType(InputDecorator))
        .decoration;
    expect(decoration.filled, isTrue);
    expect(decoration.fillColor, const Color(0xFFFFFFFF));
  });

  testWidgets('text edit uses themed disabled fill color', (tester) async {
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
          child: FdcTextEdit(
            dataSet: dataSet,
            fieldName: 'name',
            enabled: false,
          ),
        ),
      ),
    );

    final decoration = tester
        .widget<InputDecorator>(find.byType(InputDecorator))
        .decoration;
    expect(decoration.filled, isTrue);
    expect(decoration.fillColor, FdcEditorThemes.light.input.disabledFillColor);
  });

  testWidgets('text edit uses themed read-only fill color', (tester) async {
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
          child: FdcTextEdit(
            dataSet: dataSet,
            fieldName: 'name',
            readOnly: true,
          ),
        ),
      ),
    );

    final decoration = tester
        .widget<InputDecorator>(find.byType(InputDecorator))
        .decoration;
    expect(decoration.filled, isTrue);
    expect(decoration.fillColor, FdcEditorThemes.light.input.readOnlyFillColor);
  });

  testWidgets('read-only adapter makes bound text edit read-only', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'name', label: 'Name', size: 20),
      ],
      adapter: _ReadOnlyMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alice'},
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

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).readOnly,
      isTrue,
    );
  });

  test('read-only adapter blocks edit operations', () async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(name: 'name', size: 20)],
      adapter: _ReadOnlyMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'name': 'Alice'},
        ],
      ),
    );
    await dataSet.open();

    expect(() => dataSet.edit(), throwsStateError);
    expect(() => dataSet.append(), throwsStateError);
    expect(() => dataSet.insert(), throwsStateError);
    expect(() => dataSet.delete(), throwsStateError);
  });

  testWidgets('text edit counter is visible only while focused', (
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
          child: Column(
            children: [
              FdcTextEdit(
                dataSet: dataSet,
                fieldName: 'name',
                showCounter: true,
              ),
              const TextField(key: Key('other-field')),
            ],
          ),
        ),
      ),
    );

    expect(find.text('5/20'), findsNothing);

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();

    expect(find.text('5/20'), findsOneWidget);

    await tester.tap(find.byKey(const Key('other-field')));
    await tester.pump();

    expect(find.text('5/20'), findsNothing);
  });

  testWidgets('memo edit counter is visible only while focused', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'review', label: 'Review', size: 50),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'review': 'Manual'},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: [
              FdcMemoEdit(
                dataSet: dataSet,
                fieldName: 'review',
                showCounter: true,
              ),
              const TextField(key: Key('other-field')),
            ],
          ),
        ),
      ),
    );

    expect(find.text('6/50'), findsNothing);

    await tester.tap(find.byType(TextFormField).first);
    await tester.pump();

    expect(find.text('6/50'), findsOneWidget);

    await tester.tap(find.byKey(const Key('other-field')));
    await tester.pump();

    expect(find.text('6/50'), findsNothing);
  });

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

  testWidgets('text edit shows inline error when beforeEdit aborts commit', (
    tester,
  ) async {
    var beforeEditCalls = 0;
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'name', label: 'Name', size: 20),
      ],
      beforeEdit: (dataSet) {
        beforeEditCalls++;
        throw FdcDataSetAbortException('Edit is not allowed.');
      },

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'name': 'Alice'},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcTextEdit(
            dataSet: dataSet,
            fieldName: 'name',
            errorIndicator: const FdcErrorIndicatorOptions(
              mode: FdcErrorIndicatorMode.inline,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'Megan');
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(beforeEditCalls, 1);
    expect(dataSet.state, FdcDataSetState.browse);
    expect(dataSet.fieldValue('name'), 'Alice');
    expect(find.text('Edit is not allowed.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'text edit keeps value unchanged when silent beforeEdit aborts commit',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'name', label: 'Name', size: 20),
        ],
        beforeEdit: (dataSet) {
          throw const FdcDataSetAbortException.silent();
        },

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alice'},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcTextEdit(
              dataSet: dataSet,
              fieldName: 'name',
              errorIndicator: const FdcErrorIndicatorOptions(
                mode: FdcErrorIndicatorMode.inline,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Megan');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(dataSet.state, FdcDataSetState.browse);
      expect(dataSet.fieldValue('name'), 'Alice');
      expect(find.text('Edit was canceled.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'second escape in standalone editor does not cancel dataset edit',
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
            child: FdcTextEdit(dataSet: dataSet, fieldName: 'name'),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Megan');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet.fieldValue('name'), 'Megan');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(dataSet.state, FdcDataSetState.edit);
      expect(dataSet.fieldValue('name'), 'Megan');
      expect(find.text('Megan'), findsOneWidget);
    },
  );

  testWidgets(
    'date time edit commits invalid parse text as null when inline validation is disabled',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDateTimeField(name: 'createdAt', label: 'Created at'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'createdAt': DateTime(2026, 5, 16, 10, 30)},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: [
                FdcDateTimeEdit(dataSet: dataSet, fieldName: 'createdAt'),
                const TextField(key: ValueKey('nextField')),
              ],
            ),
          ),
        ),
      );

      final editorFinder = find.descendant(
        of: find.byType(FdcDateTimeEdit),
        matching: find.byType(EditableText),
      );

      await tester.tap(
        find.descendant(
          of: find.byType(FdcDateTimeEdit),
          matching: find.byType(TextFormField),
        ),
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(FdcDateTimeEdit),
          matching: find.byType(TextFormField),
        ),
        '2026-13-40 10:30',
      );
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(find.textContaining('Enter a valid'), findsNothing);
      expect(
        tester.widget<EditableText>(editorFinder).focusNode.hasFocus,
        isFalse,
      );
      expect(dataSet.fieldValue('createdAt'), isNull);
    },
  );

  testWidgets(
    'date time edit commits invalid parse text as null when inline validation mode is enabled',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDateTimeField(name: 'createdAt', label: 'Created at'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'createdAt': DateTime(2026, 5, 16, 10, 30)},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcDateTimeEdit(
              dataSet: dataSet,
              fieldName: 'createdAt',
              errorIndicator: const FdcErrorIndicatorOptions(
                mode: FdcErrorIndicatorMode.inline,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), '2026-13-40 10:30');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(find.textContaining('Enter a valid'), findsNothing);
      expect(dataSet.fieldValue('createdAt'), isNull);
    },
  );

  testWidgets('date edit hides picker button when readOnly', (tester) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcDateField(name: 'dueDate', label: 'Due date'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          {'dueDate': DateTime(2026, 5, 16)},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcDateEdit(
            dataSet: dataSet,
            fieldName: 'dueDate',
            readOnly: true,
          ),
        ),
      ),
    );

    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets(
    'bound text edit resets dirty editor state when current record changes',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'name', label: 'Name', size: 20),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha'},
            {'name': 'Beta'},
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
      await tester.enterText(find.byType(TextFormField), 'Dirty Alpha');
      await tester.pump();

      expect(find.text('Dirty Alpha'), findsOneWidget);

      dataSet.moveToRecord(2);
      await tester.pump();

      expect(find.text('Dirty Alpha'), findsNothing);
      expect(find.text('Beta'), findsOneWidget);

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(dataSet.fieldValue('name'), 'Beta');

      dataSet.moveToRecord(1);
      expect(dataSet.fieldValue('name'), 'Alpha');
    },
  );

  testWidgets(
    'bound date time edit resets formatted text when current record changes',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDateTimeField(name: 'createdAt', label: 'Created at'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {'createdAt': DateTime(2026, 5, 16, 10, 30)},
            {'createdAt': DateTime(2026, 5, 17, 11, 45)},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: FdcApp(
            formatSettings: const FdcFormatSettings(),
            child: Material(
              child: FdcDateTimeEdit(dataSet: dataSet, fieldName: 'createdAt'),
            ),
          ),
        ),
      );

      expect(find.text('2026-05-16 10:30'), findsOneWidget);

      dataSet.moveToRecord(2);
      await tester.pump();

      expect(find.text('2026-05-16 10:30'), findsNothing);
      expect(find.text('2026-05-17 11:45'), findsOneWidget);
    },
  );

  testWidgets(
    'bound text edit follows dataset view rebuild after filter change',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'name', label: 'Name', size: 20),
          FdcStringField(name: 'status', size: 20),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alice', 'status': 'active'},
            {'name': 'Megan', 'status': 'inactive'},
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

      expect(find.text('Alice'), findsOneWidget);

      dataSet.filter.where('status').equals('inactive').apply();
      await tester.pumpAndSettle();

      expect(dataSet.recordCount, 1);
      expect(dataSet.fieldValue('name'), 'Megan');
      expect(find.text('Megan'), findsOneWidget);
      expect(find.text('Alice'), findsNothing);
    },
  );

  testWidgets(
    'bound text edit defers controller sync during dataset rebuild in form',
    (tester) async {
      final formKey = GlobalKey<FormState>();
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
            child: Form(
              key: formKey,
              child: FdcTextEdit(dataSet: dataSet, fieldName: 'name'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'Megan');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(dataSet.fieldValue('name'), 'Megan');
    },
  );

  testWidgets(
    'decimal editor focus formats from bound value instead of reparsing display text',
    (tester) async {
      final value = FdcDecimal.parse('887.70', scale: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcApp(
              formatSettings: const FdcFormatSettings(
                decimalSeparator: ',',
                thousandSeparator: '.',
              ),
              child: FdcEditorCore<FdcDecimal>(
                field: const FdcDecimalEditorDescriptor<FdcDecimal>(
                  fieldName: 'amount',
                  precision: 12,
                  scale: 2,
                ),
                value: value,
                // Simulates display text coming from a grid/cell formatter that uses
                // a dot decimal separator. This used to be reparsed as a grouped
                // integer with decimalSeparator=',' and thousandSeparator='.'.
                initialText: '887.70',
              ),
            ),
          ),
        ),
      );

      expect(find.text('887.70'), findsOneWidget);

      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      expect(find.text('887,70'), findsOneWidget);
      expect(find.text('88770,00'), findsNothing);
    },
  );

  testWidgets(
    'editor value identity change resyncs focused dirty decimal text',
    (tester) async {
      final firstValue = FdcDecimal.parse('1234.50', scale: 2);
      final secondValue = FdcDecimal.parse('887.70', scale: 2);

      Widget buildEditor({required int identity, required FdcDecimal value}) {
        return MaterialApp(
          home: Material(
            child: FdcApp(
              formatSettings: const FdcFormatSettings(
                decimalSeparator: ',',
                thousandSeparator: '.',
              ),
              child: FdcEditorCore<FdcDecimal>(
                field: const FdcDecimalEditorDescriptor<FdcDecimal>(
                  fieldName: 'amount',
                  precision: 12,
                  scale: 2,
                ),
                key: ValueKey<int>(identity),
                value: value,
                valueIdentity: identity,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildEditor(identity: 1, value: firstValue));
      expect(find.text('1.234,50'), findsOneWidget);

      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      expect(find.text('1234,50'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '9999,99');
      await tester.pump();
      expect(find.text('9999,99'), findsOneWidget);

      await tester.pumpWidget(buildEditor(identity: 2, value: secondValue));
      await tester.pumpAndSettle();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, '887,70');
      expect(find.text('9999,99'), findsNothing);
    },
  );

  testWidgets(
    'decimal edit refreshes formatted text after dataset cursor moves',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(
            name: 'amount',
            label: 'Amount',
            precision: 12,
            scale: 2,
          ),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1234.5},
            {'amount': 1887.7},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcApp(
              formatSettings: const FdcFormatSettings(
                decimalSeparator: ',',
                thousandSeparator: '.',
              ),
              child: FdcDecimalEdit(dataSet: dataSet, fieldName: 'amount'),
            ),
          ),
        ),
      );

      expect(find.text('1.234,50'), findsOneWidget);

      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), '9999,99');
      await tester.pump();

      dataSet.next();
      await tester.pumpAndSettle();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, '1.887,70');
      expect(find.text('9999,99'), findsNothing);
    },
  );

  testWidgets(
    'date and date time edits keep local formatting after dataset cursor moves',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDateField(name: 'dueDate', label: 'Due date'),
          FdcDateTimeField(name: 'createdAt', label: 'Created at'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            {
              'dueDate': DateTime(2026, 5, 16),
              'createdAt': DateTime(2026, 5, 16, 10, 30),
            },
            {
              'dueDate': DateTime(2026, 5, 17),
              'createdAt': DateTime(2026, 5, 17, 11, 45),
            },
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcApp(
              formatSettings: const FdcFormatSettings(dateFormat: 'dd.MM.yyyy'),
              child: Column(
                children: [
                  FdcDateEdit(dataSet: dataSet, fieldName: 'dueDate'),
                  FdcDateTimeEdit(dataSet: dataSet, fieldName: 'createdAt'),
                ],
              ),
            ),
          ),
        ),
      );

      final editors = find.byType(EditableText);
      expect(
        tester.widget<EditableText>(editors.at(0)).controller.text,
        '16.05.2026',
      );
      expect(
        tester.widget<EditableText>(editors.at(1)).controller.text,
        '16.05.2026 10:30',
      );

      dataSet.next();
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(editors.at(0)).controller.text,
        '17.05.2026',
      );
      expect(
        tester.widget<EditableText>(editors.at(1)).controller.text,
        '17.05.2026 11:45',
      );
    },
  );

  testWidgets(
    'bound editor syncs when same-record dataset value changes externally',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcDecimalField(
            name: 'amount',
            label: 'Amount',
            precision: 12,
            scale: 2,
          ),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'amount': 1234.5},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcApp(
              formatSettings: const FdcFormatSettings(
                decimalSeparator: ',',
                thousandSeparator: '.',
              ),
              child: FdcDecimalEdit(dataSet: dataSet, fieldName: 'amount'),
            ),
          ),
        ),
      );

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '1.234,50',
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), '9999,99');
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '9999,99',
      );

      dataSet.edit();
      dataSet.setFieldValue('amount', FdcDecimal.parse('1887.70', scale: 2));
      await tester.pumpAndSettle();

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '1.887,70',
      );
      expect(find.text('9999,99'), findsNothing);
    },
  );
}
