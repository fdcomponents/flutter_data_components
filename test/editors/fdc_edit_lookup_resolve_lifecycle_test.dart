import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

FdcDataSet _lookupDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(name: 'code', label: 'Code', size: 30),
      FdcStringField(name: 'description', label: 'Description', size: 60),
    ],
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'code': 'A', 'description': 'Original'},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

void main() {
  testWidgets(
    'standalone lookup resolve error does not double fire and can be explicitly retried',
    (tester) async {
      final dataSet = _lookupDataSet();
      var resolveCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: [
                FdcTextEdit(
                  dataSet: dataSet,
                  fieldName: 'code',
                  onLookup: (context) async {
                    if (context.lookupMode == FdcLookupMode.resolve) {
                      resolveCount++;
                      throw StateError('Unknown value ${context.lookupText}.');
                    }
                    return null;
                  },
                ),
                const TextField(key: ValueKey<String>('next-field')),
              ],
            ),
          ),
        ),
      );

      final firstEditable = find.byType(EditableText).first;

      await tester.tap(firstEditable);
      await tester.enterText(firstEditable, 'missing');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(resolveCount, 1);
      expect(find.textContaining('Unknown value missing'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await pumpPendingFrames(tester);

      expect(resolveCount, 1);
      expect(
        tester.widget<EditableText>(firstEditable).focusNode.hasFocus,
        isTrue,
      );

      // Closing a dialog can leave the test TextInput connection detached even
      // though the editor focus node is restored. Re-tap to model an explicit
      // user retry and to re-attach the input connection before sending the
      // platform action.
      await tester.tap(firstEditable);
      await tester.showKeyboard(firstEditable);
      await tester.enterText(firstEditable, 'missing');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(resolveCount, 2);
      expect(find.textContaining('Unknown value missing'), findsOneWidget);
      expect(dataSet.fieldValue('code'), 'A');
    },
  );

  testWidgets(
    'standalone lookup search result suppresses immediate resolve traversal',
    (tester) async {
      final dataSet = _lookupDataSet();
      var searchCount = 0;
      var resolveCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: [
                FdcTextEdit(
                  dataSet: dataSet,
                  fieldName: 'code',
                  onLookup: (context) async {
                    if (context.lookupMode == FdcLookupMode.search) {
                      searchCount++;
                      return const FdcLookupResult({
                        'code': 'B',
                        'description': 'Selected',
                      });
                    }
                    resolveCount++;
                    return FdcLookupResult({
                      'code': context.lookupText,
                      'description': 'Resolved ${context.lookupText}',
                    });
                  },
                ),
                const TextField(key: ValueKey<String>('next-field')),
              ],
            ),
          ),
        ),
      );

      final firstEditable = find.byType(EditableText).first;
      final secondEditable = find.byType(EditableText).last;
      await tester.tap(firstEditable);
      await tester.enterText(firstEditable, 'typed search');
      await tester.pump();
      await tester.tap(find.byTooltip('Lookup (F4)'));
      await pumpPendingFrames(tester);

      expect(searchCount, 1);
      expect(resolveCount, 0);
      expect(dataSet.fieldValue('code'), 'B');
      expect(dataSet.fieldValue('description'), 'Selected');

      await tester.tap(secondEditable);
      await pumpPendingFrames(tester);

      expect(searchCount, 1);
      expect(resolveCount, 0);
    },
  );

  testWidgets(
    'standalone lookup resolve applies value changing replacement and changed once',
    (tester) async {
      final dataSet = _lookupDataSet();
      var lookupCount = 0;
      var changingCount = 0;
      var changedCount = 0;
      final changedValues = <Object?>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: [
                FdcTextEdit(
                  dataSet: dataSet,
                  fieldName: 'code',
                  onLookup: (context) async {
                    if (context.lookupMode == FdcLookupMode.resolve) {
                      lookupCount++;
                      return FdcLookupResult({'code': context.lookupText});
                    }
                    return null;
                  },
                  onValueChanging: (context) {
                    changingCount++;
                    context.setValueOf<String>(
                      'description',
                      'Changed by event',
                    );
                    return context.replaceValue('${context.newValue}-event');
                  },
                  onValueChanged: (context) {
                    changedCount++;
                    changedValues.add(context.value);
                  },
                ),
                const TextField(key: ValueKey<String>('next-field')),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableText).first);
      await tester.enterText(find.byType(EditableText).first, 'B');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await pumpPendingFrames(tester);

      expect(lookupCount, 1);
      expect(changingCount, 1);
      expect(changedCount, 1);
      expect(changedValues, <Object?>['B-event']);
      expect(dataSet.fieldValue('code'), 'B-event');
      expect(dataSet.fieldValue('description'), 'Changed by event');
    },
  );

  testWidgets(
    'standalone lookup resolve cancellation from value changing keeps focus and original values',
    (tester) async {
      final dataSet = _lookupDataSet();
      var lookupCount = 0;
      var changingCount = 0;
      var changedCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: [
                FdcTextEdit(
                  dataSet: dataSet,
                  fieldName: 'code',
                  onLookup: (context) async {
                    if (context.lookupMode == FdcLookupMode.resolve) {
                      lookupCount++;
                      return FdcLookupResult({'code': context.lookupText});
                    }
                    return null;
                  },
                  onValueChanging: (context) {
                    changingCount++;
                    return context.cancel('Rejected by event');
                  },
                  onValueChanged: (_) {
                    changedCount++;
                  },
                ),
                const TextField(key: ValueKey<String>('next-field')),
              ],
            ),
          ),
        ),
      );

      final firstEditable = find.byType(EditableText).first;

      await tester.tap(firstEditable);
      await tester.enterText(firstEditable, 'B');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await pumpPendingFrames(tester);

      expect(lookupCount, 1);
      expect(changingCount, 1);
      expect(changedCount, 0);
      expect(dataSet.fieldValue('code'), 'A');
      expect(dataSet.fieldValue('description'), 'Original');
      expect(
        tester.widget<EditableText>(firstEditable).focusNode.hasFocus,
        isTrue,
      );
    },
  );

  testWidgets(
    'standalone lookup resolve same primary value does not fire value changed',
    (tester) async {
      final dataSet = _lookupDataSet();
      var changedCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcTextEdit(
              dataSet: dataSet,
              fieldName: 'code',
              onLookup: (context) async {
                if (context.lookupMode != FdcLookupMode.resolve) {
                  return null;
                }
                return const FdcLookupResult({
                  'code': 'A',
                  'description': 'Sibling changed',
                });
              },
              onValueChanged: (_) {
                changedCount++;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'B');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await pumpPendingFrames(tester);

      expect(dataSet.fieldValue('code'), 'A');
      expect(dataSet.fieldValue('description'), 'Sibling changed');
      expect(changedCount, 0);
    },
  );
}
