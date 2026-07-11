import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('checkbox FormField validation follows changed value', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcBooleanField(name: 'accepted', label: 'Accepted', required: true),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'accepted': null},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Form(
            key: formKey,
            child: FdcBooleanEdit(dataSet: dataSet, fieldName: 'accepted'),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    expect(find.text('Accepted is required'), findsNothing);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(dataSet.fieldValue('accepted'), isTrue);
    expect(formKey.currentState!.validate(), isTrue);
    expect(find.text('Accepted is required'), findsNothing);
  });

  testWidgets('boolean edit renders label after checkbox without label frame', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcBooleanField(name: 'accepted', label: 'Accepted'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'accepted': true},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcBooleanEdit(dataSet: dataSet, fieldName: 'accepted'),
        ),
      ),
    );

    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.byType(InputDecorator), findsNothing);
    expect(find.text('Accepted'), findsOneWidget);
  });

  testWidgets(
    'boolean switch edit renders label after switch without label frame',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcBooleanField(name: 'active', label: 'Active'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'active': false},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcBooleanEdit(
              dataSet: dataSet,
              fieldName: 'active',
              control: FdcBooleanControl.switchControl,
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(InputDecorator), findsNothing);
      expect(find.text('Active'), findsOneWidget);
    },
  );

  testWidgets('boolean edit supports custom label and hidden label', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcBooleanField(name: 'accepted', label: 'Accepted'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'accepted': true},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: [
              FdcBooleanEdit(
                dataSet: dataSet,
                fieldName: 'accepted',
                label: 'Custom Accepted',
              ),
              FdcBooleanEdit(
                dataSet: dataSet,
                fieldName: 'accepted',
                showLabel: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Custom Accepted'), findsOneWidget);
    expect(find.text('Accepted'), findsNothing);
    expect(find.byType(InputDecorator), findsNothing);
  });

  testWidgets('boolean edit Enter moves focus without toggling value', (
    tester,
  ) async {
    final nextFocusNode = FocusNode();
    addTearDown(nextFocusNode.dispose);

    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcBooleanField(name: 'accepted', label: 'Accepted'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'accepted': false},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: [
              FdcBooleanEdit(
                dataSet: dataSet,
                fieldName: 'accepted',
                autofocus: true,
              ),
              TextField(focusNode: nextFocusNode),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(dataSet.fieldValue('accepted'), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(dataSet.fieldValue('accepted'), isFalse);
    expect(nextFocusNode.hasFocus, isTrue);
  });

  testWidgets('boolean edit Space follows checkbox tristate cycle', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcBooleanField(name: 'accepted', label: 'Accepted'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'accepted': false},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcBooleanEdit(
            dataSet: dataSet,
            fieldName: 'accepted',
            autofocus: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(dataSet.fieldValue('accepted'), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(dataSet.fieldValue('accepted'), isNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(dataSet.fieldValue('accepted'), isTrue);
  });

  testWidgets('required boolean edit Space cycles only checked and unchecked', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcBooleanField(name: 'accepted', label: 'Accepted', required: true),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'accepted': false},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcBooleanEdit(
            dataSet: dataSet,
            fieldName: 'accepted',
            autofocus: true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(dataSet.fieldValue('accepted'), isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(dataSet.fieldValue('accepted'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(dataSet.fieldValue('accepted'), isFalse);
  });

  testWidgets(
    'required boolean edit can display initial null but first Space checks it',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcBooleanField(name: 'accepted', label: 'Accepted', required: true),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'accepted': null},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcBooleanEdit(
              dataSet: dataSet,
              fieldName: 'accepted',
              autofocus: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(dataSet.fieldValue('accepted'), isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(dataSet.fieldValue('accepted'), isTrue);
    },
  );

  testWidgets('boolean edit does not overflow when width is very narrow', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcBooleanField(
          name: 'accepted',
          label: 'Very long accepted label that should never overflow',
        ),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'accepted': true},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 52,
            child: FdcBooleanEdit(dataSet: dataSet, fieldName: 'accepted'),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('boolean edit emits focus enter and exit callbacks', (
    tester,
  ) async {
    final events = <String>[];
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcBooleanField(name: 'accepted', label: 'Accepted'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'accepted': false},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: [
              FdcBooleanEdit(
                dataSet: dataSet,
                fieldName: 'accepted',
                autofocus: true,
                onEnter: (context) => events.add(
                  'enter:${context.fieldName}:${context.value}:${context.rowIndex}',
                ),
                onExit: (context) => events.add(
                  'exit:${context.fieldName}:${context.value}:${context.rowIndex}',
                ),
              ),
              const TextField(key: Key('next-field')),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byKey(const Key('next-field')));
    await tester.pump();

    expect(events, <String>['enter:accepted:false:0', 'exit:accepted:false:0']);
  });
}
