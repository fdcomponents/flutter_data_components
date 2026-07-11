import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

FdcDataSet _editorEventsDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(name: 'name', label: 'Name', size: 50),
      FdcBooleanField(name: 'active', label: 'Active', required: true),
      FdcStringField(name: 'status', label: 'Status', size: 20),
      FdcStringField(name: 'sibling', label: 'Sibling', size: 50),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {
          'name': 'Alice',
          'active': false,
          'status': 'open',
          'sibling': 'unchanged',
        },
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

Future<void> _pumpEditorHost(
  WidgetTester tester, {
  required Widget child,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Material(child: child)),
    ),
  );
  await tester.pump();
}

Future<void> _selectComboOption(WidgetTester tester, String label) async {
  await tester.tap(find.byType(FdcComboEdit<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('standalone editors emit onEnter and onExit consistently', (
    tester,
  ) async {
    final dataSet = _editorEventsDataSet();
    final events = <String>[];

    await _pumpEditorHost(
      tester,
      child: Column(
        children: [
          FdcTextEdit(
            dataSet: dataSet,
            fieldName: 'name',
            onEnter: (context) => events.add(
              'text-enter:${context.host}:${context.fieldName}:'
              '${context.value}:${context.rawValue}:${context.rowIndex}',
            ),
            onExit: (context) => events.add(
              'text-exit:${context.host}:${context.fieldName}:'
              '${context.value}:${context.rawValue}:${context.rowIndex}',
            ),
          ),
          FdcBooleanEdit(
            dataSet: dataSet,
            fieldName: 'active',
            onEnter: (context) => events.add(
              'bool-enter:${context.host}:${context.fieldName}:'
              '${context.value}:${context.rawValue}:${context.rowIndex}',
            ),
            onExit: (context) => events.add(
              'bool-exit:${context.host}:${context.fieldName}:'
              '${context.value}:${context.rawValue}:${context.rowIndex}',
            ),
          ),
          FdcComboEdit<String>(
            dataSet: dataSet,
            fieldName: 'status',
            options: const <FdcOption<String>>[
              FdcOption<String>(value: 'open', label: 'Open'),
              FdcOption<String>(value: 'closed', label: 'Closed'),
            ],
            onEnter: (context) => events.add(
              'combo-enter:${context.host}:${context.fieldName}:'
              '${context.value}:${context.rawValue}:${context.rowIndex}',
            ),
            onExit: (context) => events.add(
              'combo-exit:${context.host}:${context.fieldName}:'
              '${context.value}:${context.rawValue}:${context.rowIndex}',
            ),
          ),
          const TextField(key: Key('after-editors')),
        ],
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.byType(FdcComboEdit<String>));
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(
      events,
      containsAll(<String>[
        'text-enter:FdcFieldEventHost.editor:name:Alice:Alice:0',
        'text-exit:FdcFieldEventHost.editor:name:Alice:Alice:0',
        'combo-enter:FdcFieldEventHost.editor:status:open:open:0',
        'combo-exit:FdcFieldEventHost.editor:status:open:open:0',
      ]),
    );
    // Do not assert global focus ordering here. Flutter may report the
    // newly-focused editor before the previously-focused editor loses focus,
    // depending on the control implementation and test hit target path.
  });

  testWidgets('text edit onValueChanging can accept cancel and replace', (
    tester,
  ) async {
    final dataSet = _editorEventsDataSet();
    final events = <String>[];

    await _pumpEditorHost(
      tester,
      child: FdcTextEdit(
        dataSet: dataSet,
        fieldName: 'name',
        onValueChanging: (context) {
          events.add(
            'changing:${context.host}:${context.fieldName}:'
            '${context.oldValue}->${context.newValue}:'
            '${context.oldRawValue}->${context.newRawValue}',
          );
          if (context.newValue == 'BLOCK') {
            return context.cancel('Blocked');
          }
          if (context.newValue == 'SCAN') {
            return context.replaceValue('Resolved');
          }
          return context.accept();
        },
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'Megan');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(dataSet.fieldValue('name'), 'Megan');

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'BLOCK');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(dataSet.fieldValue('name'), 'Megan');
    expect(find.text('Validation error'), findsNothing);
    await tester.enterText(find.byType(TextFormField), 'SCAN');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(dataSet.fieldValue('name'), 'Resolved');
    expect(
      events,
      containsAllInOrder(<String>[
        'changing:FdcFieldEventHost.editor:name:Alice->Megan:Alice->Megan',
        'changing:FdcFieldEventHost.editor:name:Megan->BLOCK:Megan->BLOCK',
        'changing:FdcFieldEventHost.editor:name:Megan->SCAN:Megan->SCAN',
      ]),
    );
  });

  testWidgets('boolean edit onValueChanging can accept cancel and replace', (
    tester,
  ) async {
    final dataSet = _editorEventsDataSet();
    final events = <String>[];
    var mode = 'accept';

    await _pumpEditorHost(
      tester,
      child: FdcBooleanEdit(
        dataSet: dataSet,
        fieldName: 'active',
        onValueChanging: (context) {
          events.add(
            'changing:${context.host}:${context.fieldName}:'
            '${context.oldValue}->${context.newValue}:'
            '${context.oldRawValue}->${context.newRawValue}',
          );
          if (mode == 'cancel') {
            return context.cancel('Blocked');
          }
          if (mode == 'replace') {
            return context.replaceValue(false);
          }
          return context.accept();
        },
      ),
    );

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(dataSet.fieldValue('active'), isTrue);

    mode = 'cancel';
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(dataSet.fieldValue('active'), isTrue);
    expect(find.text('Validation error'), findsNothing);
    mode = 'replace';
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(dataSet.fieldValue('active'), isFalse);

    expect(events, <String>[
      'changing:FdcFieldEventHost.editor:active:false->true:false->true',
      'changing:FdcFieldEventHost.editor:active:true->false:true->false',
      'changing:FdcFieldEventHost.editor:active:true->false:true->false',
    ]);
  });

  testWidgets('combo edit onValueChanging can accept cancel and replace', (
    tester,
  ) async {
    final dataSet = _editorEventsDataSet();
    final events = <String>[];
    var mode = 'accept';

    await _pumpEditorHost(
      tester,
      child: FdcComboEdit<String>(
        dataSet: dataSet,
        fieldName: 'status',
        options: const <FdcOption<String>>[
          FdcOption<String>(value: 'open', label: 'Open'),
          FdcOption<String>(value: 'closed', label: 'Closed'),
          FdcOption<String>(value: 'pending', label: 'Pending'),
        ],
        onValueChanging: (context) {
          events.add(
            'changing:${context.host}:${context.fieldName}:'
            '${context.oldValue}->${context.newValue}:'
            '${context.oldRawValue}->${context.newRawValue}',
          );
          if (mode == 'cancel') {
            return context.cancel('Blocked');
          }
          if (mode == 'replace') {
            return context.replaceValue('closed');
          }
          return context.accept();
        },
      ),
    );

    await _selectComboOption(tester, 'Closed');
    expect(dataSet.fieldValue('status'), 'closed');

    mode = 'cancel';
    await _selectComboOption(tester, 'Pending');
    expect(dataSet.fieldValue('status'), 'closed');
    expect(find.text('Validation error'), findsNothing);
    mode = 'replace';
    await _selectComboOption(tester, 'Open');
    expect(dataSet.fieldValue('status'), 'closed');

    expect(events, <String>[
      'changing:FdcFieldEventHost.editor:status:open->closed:open->closed',
      'changing:FdcFieldEventHost.editor:status:closed->pending:closed->pending',
      'changing:FdcFieldEventHost.editor:status:closed->open:closed->open',
    ]);
  });

  testWidgets('standalone editor onValueChanged exposes old and raw values', (
    tester,
  ) async {
    final dataSet = _editorEventsDataSet();
    final events = <String>[];

    await _pumpEditorHost(
      tester,
      child: Column(
        children: [
          FdcTextEdit(
            dataSet: dataSet,
            fieldName: 'name',
            onValueChanged: (context) => events.add(
              'text:${context.host}:${context.fieldName}:'
              '${context.oldValue}->${context.value}:'
              '${context.oldRawValue}->${context.rawValue}',
            ),
          ),
          FdcBooleanEdit(
            dataSet: dataSet,
            fieldName: 'active',
            onValueChanged: (context) => events.add(
              'bool:${context.host}:${context.fieldName}:'
              '${context.oldValue}->${context.value}:'
              '${context.oldRawValue}->${context.rawValue}',
            ),
          ),
          FdcComboEdit<String>(
            dataSet: dataSet,
            fieldName: 'status',
            options: const <FdcOption<String>>[
              FdcOption<String>(value: 'open', label: 'Open'),
              FdcOption<String>(value: 'closed', label: 'Closed'),
            ],
            onValueChanged: (context) => events.add(
              'combo:${context.host}:${context.fieldName}:'
              '${context.oldValue}->${context.value}:'
              '${context.oldRawValue}->${context.rawValue}',
            ),
          ),
        ],
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'Megan');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    await _selectComboOption(tester, 'Closed');

    expect(events, <String>[
      'text:FdcFieldEventHost.editor:name:Alice->Megan:Alice->Megan',
      'bool:FdcFieldEventHost.editor:active:false->true:false->true',
      'combo:FdcFieldEventHost.editor:status:open->closed:open->closed',
    ]);
  });

  testWidgets('standalone editor setValueOf requests are not applied', (
    tester,
  ) async {
    final dataSet = _editorEventsDataSet();

    await _pumpEditorHost(
      tester,
      child: FdcTextEdit(
        dataSet: dataSet,
        fieldName: 'name',
        onValueChanging: (context) {
          context.setValueOf<String>('sibling', 'changed');
          return context.replaceValue('Primary');
        },
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'SCAN');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(dataSet.fieldValue('name'), 'Primary');
    expect(dataSet.fieldValue('sibling'), 'unchanged');
  });
}
