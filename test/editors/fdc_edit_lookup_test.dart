import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

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
    'standalone lookup receives raw editor text and applies primary and sibling values',
    (tester) async {
      final dataSet = _lookupDataSet();
      String? receivedText;
      FdcLookupMode? receivedMode;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcTextEdit(
              dataSet: dataSet,
              fieldName: 'code',
              onLookup: (context) async {
                receivedText = context.lookupText;
                receivedMode = context.lookupMode;
                expect(context.fieldName, 'code');
                expect(context.valueOf<String>('description'), 'Original');
                return const FdcLookupResult({
                  'code': 'B',
                  'description': 'Lookup result',
                });
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'typed query');
      await tester.pump();
      await tester.tap(find.byTooltip('Lookup (F4)'));
      await tester.pump();

      expect(receivedText, 'typed query');
      expect(receivedMode, FdcLookupMode.search);
      expect(dataSet.fieldValue('code'), 'B');
      expect(dataSet.fieldValue('description'), 'Lookup result');
    },
  );

  testWidgets('standalone lookup shortcut invokes callback', (tester) async {
    final dataSet = _lookupDataSet();
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcTextEdit(
            dataSet: dataSet,
            fieldName: 'code',
            onLookup: (context) async {
              calls += 1;
              return null;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    await tester.pump();

    expect(calls, 1);
    expect(dataSet.fieldValue('code'), 'A');
  });

  testWidgets(
    'standalone lookup ignores a second invocation while one is in progress',
    (tester) async {
      final dataSet = _lookupDataSet();
      final completer = Completer<void>();
      var calls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcTextEdit(
              dataSet: dataSet,
              fieldName: 'code',
              onLookup: (context) async {
                calls += 1;
                await completer.future;
                return const FdcLookupResult({'code': 'B'});
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      await tester.tap(find.byTooltip('Lookup (F4)'));
      await tester.pump();
      await tester.tap(find.byTooltip('Lookup (F4)'));
      await tester.pump();

      expect(calls, 1);

      completer.complete();
      await tester.pumpAndSettle();

      expect(dataSet.fieldValue('code'), 'B');
    },
  );

  testWidgets('standalone lookup discards result when current record changes', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'code', label: 'Code', size: 30),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'code': 'A'},
          {'code': 'C'},
        ],
      ),
    )..open();
    final completer = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcTextEdit(
            dataSet: dataSet,
            fieldName: 'code',
            onLookup: (context) async {
              await completer.future;
              return const FdcLookupResult({'code': 'B'});
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.tap(find.byTooltip('Lookup (F4)'));
    await tester.pump();
    dataSet.moveToRecord(2);
    await tester.pump();

    completer.complete();
    await tester.pumpAndSettle();

    dataSet.moveToRecord(1);
    expect(dataSet.fieldValue('code'), 'A');
    dataSet.moveToRecord(2);
    expect(dataSet.fieldValue('code'), 'C');
  });

  testWidgets(
    'standalone lookup rolls back primary value when a sibling write fails',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'code', label: 'Code', size: 30),
          FdcIntegerField(name: 'qty'),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'code': 'A', 'qty': 1},
          ],
        ),
      )..open();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: FdcTextEdit(
              dataSet: dataSet,
              fieldName: 'code',
              onLookup: (context) async {
                return const FdcLookupResult({'code': 'B', 'qty': 'invalid'});
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pump();
      await tester.tap(find.byTooltip('Lookup (F4)'));
      await tester.pumpAndSettle();

      expect(dataSet.fieldValue('code'), 'A');
      expect(dataSet.fieldValue('qty'), 1);
    },
  );

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
    await tester.pumpAndSettle();

    expect(modes, contains(FdcLookupMode.resolve));
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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(resolveCount, 1);
      expect(dataSet.fieldValue('code'), 'B');
      expect(dataSet.fieldValue('description'), 'Resolved B');
    },
  );

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(searchCount, 1);
      expect(resolveCount, 0);
      expect(dataSet.fieldValue('code'), 'B');
      expect(dataSet.fieldValue('description'), 'Selected');

      await tester.tap(secondEditable);
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(dataSet.fieldValue('code'), 'A');
      expect(dataSet.fieldValue('description'), 'Sibling changed');
      expect(changedCount, 0);
    },
  );
}
