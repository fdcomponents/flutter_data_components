import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

void main() {
  testWidgets('combo edit does not open dropdown on enter while focused', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'status', label: 'Status', size: 20),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'status': 'open'},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcComboEdit<String>(
            dataSet: dataSet,
            fieldName: 'status',
            autofocus: true,
            options: const <FdcOption<String>>[
              FdcOption<String>(value: 'open', label: 'Open'),
              FdcOption<String>(value: 'closed', label: 'Closed'),
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Closed'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpPendingFrames(tester);

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Closed'), findsNothing);
    expect(dataSet.fieldValue('status'), 'open');
  });

  testWidgets('combo edit moves focus to next field on enter', (tester) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'status', label: 'Status', size: 20),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'status': 'open'},
        ],
      ),
    )..open();
    final nextFocusNode = FocusNode();
    addTearDown(nextFocusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: [
              FdcComboEdit<String>(
                dataSet: dataSet,
                fieldName: 'status',
                autofocus: true,
                options: const <FdcOption<String>>[
                  FdcOption<String>(value: 'open', label: 'Open'),
                  FdcOption<String>(value: 'closed', label: 'Closed'),
                ],
              ),
              TextField(key: const Key('next-field'), focusNode: nextFocusNode),
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    expect(nextFocusNode.hasFocus, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpPendingFrames(tester);

    expect(nextFocusNode.hasFocus, isTrue);
    expect(find.text('Closed'), findsNothing);
    expect(dataSet.fieldValue('status'), 'open');
  });

  testWidgets('combo edit emits focus enter and exit callbacks', (
    tester,
  ) async {
    final events = <String>[];
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'status', label: 'Status', size: 20),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'status': 'open'},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: [
              FdcComboEdit<String>(
                dataSet: dataSet,
                fieldName: 'status',
                autofocus: true,
                options: const <FdcOption<String>>[
                  FdcOption<String>(value: 'open', label: 'Open'),
                  FdcOption<String>(value: 'closed', label: 'Closed'),
                ],
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

    expect(events, <String>['enter:status:open:0', 'exit:status:open:0']);
  });
}
