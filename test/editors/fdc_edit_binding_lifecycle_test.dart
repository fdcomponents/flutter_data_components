import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
