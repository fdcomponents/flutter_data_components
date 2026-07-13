import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
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
}
