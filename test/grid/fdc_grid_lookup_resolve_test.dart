import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

void main() {
  testWidgets('lookup resolve mode runs when edited value is committed', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'code', size: 255),
        FdcStringField(name: 'description', size: 255),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'code': 'A', 'description': 'Old'},
        ],
      ),
    );
    dataSet.open();

    final modes = <FdcLookupMode>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 180,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: <FdcGridColumn<dynamic>>[
                FdcTextColumn<String>(
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
                const FdcTextColumn<String>(fieldName: 'description'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'B');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
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
    'lookup resolve commits typed value when result omits primary field',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'code', size: 255),
          FdcStringField(name: 'description', size: 255),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'code': 'A', 'description': 'Old'},
          ],
        ),
      );
      dataSet.open();

      String? receivedLookupText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(visible: false),
                toolbar: const FdcGridToolbar(visible: false),
                columns: <FdcGridColumn<dynamic>>[
                  FdcTextColumn<String>(
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
                  const FdcTextColumn<String>(fieldName: 'description'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, '123');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpPendingFrames(tester);

      expect(receivedLookupText, '123');
      expect(dataSet.fieldValue('code'), '123');
      expect(dataSet.fieldValue('description'), 'Resolved without primary');
    },
  );

  testWidgets('lookup resolve error keeps typed edit in the active editor', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'code', size: 255),
        FdcStringField(name: 'description', size: 255),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'code': 'A', 'description': 'Old'},
        ],
      ),
    );
    dataSet.open();

    var resolveCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 180,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: <FdcGridColumn<dynamic>>[
                FdcTextColumn<String>(
                  fieldName: 'code',
                  onLookup: (context) async {
                    if (context.lookupMode == FdcLookupMode.resolve) {
                      resolveCount++;
                      throw ArgumentError.value(
                        context.lookupText,
                        context.fieldName,
                        'Unknown lookup value.',
                      );
                    }
                    return null;
                  },
                ),
                const FdcTextColumn<String>(fieldName: 'description'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'missing');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpPendingFrames(tester);

    expect(find.textContaining('Unknown lookup value'), findsOneWidget);
    expect(resolveCount, 1);
    expect(dataSet.fieldValue('code'), 'A');
    expect(dataSet.fieldValue('description'), 'Old');

    await tester.tap(find.text('OK'));
    await pumpPendingFrames(tester);

    expect(resolveCount, 1);

    final editor = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(editor.focusNode.hasFocus, isTrue);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('lookup resolve mode runs when edited value is cleared to null', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'code', size: 255),
        FdcStringField(name: 'description', size: 255),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'code': 'A', 'description': 'Old'},
        ],
      ),
    );
    dataSet.open();

    String? receivedLookupText = 'not-called';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 180,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: <FdcGridColumn<dynamic>>[
                FdcTextColumn<String>(
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
                const FdcTextColumn<String>(fieldName: 'description'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpPendingFrames(tester);

    expect(receivedLookupText, '');
    expect(dataSet.fieldValue('code'), isNull);
    expect(dataSet.fieldValue('description'), 'Cleared');
  });

  testWidgets(
    'lookup resolve failure can be retried by committing the same text again',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'code', size: 255),
          FdcStringField(name: 'description', size: 255),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'code': 'A', 'description': 'Old'},
          ],
        ),
      );
      dataSet.open();

      var resolveCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(visible: false),
                toolbar: const FdcGridToolbar(visible: false),
                columns: <FdcGridColumn<dynamic>>[
                  FdcTextColumn<String>(
                    fieldName: 'code',
                    onLookup: (context) async {
                      if (context.lookupMode == FdcLookupMode.resolve) {
                        resolveCount++;
                        return null;
                      }
                      return null;
                    },
                  ),
                  const FdcTextColumn<String>(fieldName: 'description'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'missing');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpPendingFrames(tester);

      expect(resolveCount, 1);
      expect(dataSet.fieldValue('code'), 'A');
      expect(find.byType(TextField), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpPendingFrames(tester);

      expect(resolveCount, 2);

      await tester.enterText(find.byType(TextField).first, 'B');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpPendingFrames(tester);

      expect(resolveCount, 3);
    },
  );

  testWidgets(
    'lookup resolve failure can be retried by pointer exit with the same text',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'code', size: 255),
          FdcStringField(name: 'description', size: 255),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'code': 'A', 'description': 'Old'},
          ],
        ),
      );
      dataSet.open();

      var resolveCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(visible: false),
                toolbar: const FdcGridToolbar(visible: false),
                columns: <FdcGridColumn<dynamic>>[
                  FdcTextColumn<String>(
                    fieldName: 'code',
                    onLookup: (context) async {
                      if (context.lookupMode == FdcLookupMode.resolve) {
                        resolveCount++;
                      }
                      return null;
                    },
                  ),
                  const FdcTextColumn<String>(fieldName: 'description'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'missing');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await pumpPendingFrames(tester);

      expect(resolveCount, 1);
      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.text('Old'));
      await pumpPendingFrames(tester);

      expect(resolveCount, 2);
      expect(dataSet.fieldValue('code'), 'A');
      expect(dataSet.fieldValue('description'), 'Old');
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets('lookup resolve runs when pointer leaves the edited field', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'code', size: 255),
        FdcStringField(name: 'description', size: 255),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'code': 'A', 'description': 'Old'},
        ],
      ),
    );
    dataSet.open();

    var resolveCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 180,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: <FdcGridColumn<dynamic>>[
                FdcTextColumn<String>(
                  fieldName: 'code',
                  onLookup: (context) async {
                    if (context.lookupMode == FdcLookupMode.resolve) {
                      resolveCount++;
                      return FdcLookupResult({
                        'code': context.lookupText,
                        'description': 'Resolved ${context.lookupText}',
                      });
                    }
                    return null;
                  },
                ),
                const FdcTextColumn<String>(fieldName: 'description'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'B');
    await tester.pump();
    await tester.tap(find.text('Old'));
    await pumpPendingFrames(tester);

    expect(resolveCount, 1);
    expect(dataSet.fieldValue('code'), 'B');
    expect(dataSet.fieldValue('description'), 'Resolved B');
  });

  testWidgets('lookup resolve in progress ignores repeated keyboard commits', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'code', size: 255),
        FdcStringField(name: 'description', size: 255),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'code': 'A', 'description': 'Old'},
        ],
      ),
    );
    dataSet.open();

    final completer = Completer<void>();
    var resolveCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 180,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: <FdcGridColumn<dynamic>>[
                FdcTextColumn<String>(
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
                const FdcTextColumn<String>(fieldName: 'description'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'B');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(resolveCount, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(resolveCount, 1);
    expect(dataSet.fieldValue('code'), 'A');
    expect(dataSet.fieldValue('description'), 'Old');

    completer.complete();
    await pumpPendingFrames(tester);

    expect(resolveCount, 1);
    expect(dataSet.fieldValue('code'), 'B');
    expect(dataSet.fieldValue('description'), 'Resolved B');
  });
}
