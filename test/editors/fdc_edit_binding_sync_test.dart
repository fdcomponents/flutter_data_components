import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/editors/core/fdc_editor_core.dart';
import 'package:flutter_data_components/src/editors/core/fdc_editor_descriptor.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

void main() {
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
      await pumpPendingFrames(tester);

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
      await pumpPendingFrames(tester);

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
      await pumpPendingFrames(tester);

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
      await pumpPendingFrames(tester);

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
      await pumpPendingFrames(tester);

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '1.887,70',
      );
      expect(find.text('9999,99'), findsNothing);
    },
  );
}
