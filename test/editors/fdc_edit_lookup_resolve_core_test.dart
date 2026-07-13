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
  testWidgets('standalone lookup resolve mode runs when value is committed', (
    tester,
  ) async {
    final dataSet = _lookupDataSet();
    final modes = <FdcLookupMode>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: [
              FdcTextEdit(
                dataSet: dataSet,
                fieldName: 'code',
                onLookup: (context) async {
                  modes.add(context.lookupMode);
                  if (context.lookupMode == FdcLookupMode.resolve) {
                    return FdcLookupResult({
                      'code': context.lookupText,
                      'description': 'Resolved ${context.lookupText}',
                    });
                  }
                  return null;
                },
              ),
              const Text('outside'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'B');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await pumpPendingFrames(tester);

    expect(
      modes,
      const <FdcLookupMode>[FdcLookupMode.resolve],
      reason:
          'Committing the edited value must invoke lookup exactly once in resolve mode.',
    );
    expect(dataSet.fieldValue('code'), 'B');
    expect(dataSet.fieldValue('description'), 'Resolved B');
  });

  testWidgets(
    'standalone lookup resolve mode runs when value is cleared to null',
    (tester) async {
      final dataSet = _lookupDataSet();
      String? receivedLookupText = 'not-called';

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: [
                FdcTextEdit(
                  dataSet: dataSet,
                  fieldName: 'code',
                  onLookup: (context) async {
                    if (context.lookupMode != FdcLookupMode.resolve) {
                      return null;
                    }
                    receivedLookupText = context.lookupText;
                    return const FdcLookupResult({
                      'code': null,
                      'description': 'Cleared',
                    });
                  },
                ),
                const Text('outside'),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), '');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await pumpPendingFrames(tester);

      expect(receivedLookupText, '');
      expect(dataSet.fieldValue('code'), isNull);
      expect(dataSet.fieldValue('description'), 'Cleared');
    },
  );

  testWidgets(
    'standalone lookup resolve commits typed value when result omits primary field',
    (tester) async {
      final dataSet = _lookupDataSet();
      String? receivedLookupText;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: [
                FdcTextEdit(
                  dataSet: dataSet,
                  fieldName: 'code',
                  onLookup: (context) async {
                    if (context.lookupMode != FdcLookupMode.resolve) {
                      return null;
                    }
                    receivedLookupText = context.lookupText;
                    return const FdcLookupResult({
                      'description': 'Resolved without primary',
                    });
                  },
                ),
                const Text('outside'),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), '123');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await pumpPendingFrames(tester);

      expect(receivedLookupText, '123');
      expect(dataSet.fieldValue('code'), '123');
      expect(dataSet.fieldValue('description'), 'Resolved without primary');
    },
  );

  testWidgets('standalone lookup error keeps focus in the editor', (
    tester,
  ) async {
    final dataSet = _lookupDataSet();

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
                    throw ArgumentError.value(
                      context.lookupText,
                      context.fieldName,
                      'Unknown value.',
                    );
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
    final secondEditable = find.byType(EditableText).last;

    await tester.tap(firstEditable);
    await tester.enterText(firstEditable, 'missing');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    expect(find.textContaining('Unknown value'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await pumpPendingFrames(tester);

    expect(
      tester.widget<EditableText>(firstEditable).focusNode.hasFocus,
      isTrue,
    );
    expect(
      tester.widget<EditableText>(secondEditable).focusNode.hasFocus,
      isFalse,
    );
  });

  testWidgets(
    'standalone lookup resolve in progress ignores repeated next actions',
    (tester) async {
      final dataSet = _lookupDataSet();
      final completer = Completer<void>();
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
                      await completer.future;
                      return FdcLookupResult({
                        'code': context.lookupText,
                        'description': 'Resolved ${context.lookupText}',
                      });
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
      await tester.enterText(firstEditable, 'B');
      await tester.pump();

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(resolveCount, 1);

      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(resolveCount, 1);
      expect(dataSet.fieldValue('code'), 'A');

      completer.complete();
      await pumpPendingFrames(tester);

      expect(resolveCount, 1);
      expect(dataSet.fieldValue('code'), 'B');
      expect(dataSet.fieldValue('description'), 'Resolved B');
    },
  );
}
