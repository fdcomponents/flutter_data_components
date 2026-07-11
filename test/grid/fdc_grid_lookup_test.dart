import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'lookup receives raw editor text and writes primary and row values',
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

      String? lookupEditorText;
      FdcLookupMode? lookupMode;

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
                      lookupEditorText = context.lookupText;
                      lookupMode = context.lookupMode;
                      return const FdcLookupResult({
                        'code': 'B',
                        'description': 'Selected',
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'typed query');
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
      );
      await tester.pumpAndSettle();

      expect(lookupEditorText, 'typed query');
      expect(lookupMode, FdcLookupMode.search);
      expect(dataSet.fieldValue('code'), 'B');
      expect(dataSet.fieldValue('description'), 'Selected');
    },
  );

  testWidgets('lookup returning null discards result writes', (tester) async {
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
    );
    await tester.pumpAndSettle();

    expect(dataSet.fieldValue('code'), 'A');
    expect(dataSet.fieldValue('description'), 'Old');
  });
  testWidgets('lookup result rejects an unknown field during apply', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(name: 'code', size: 255)],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'code': 'A'},
        ],
      ),
    );
    dataSet.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 160,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: <FdcGridColumn<dynamic>>[
                FdcTextColumn<String>(
                  fieldName: 'code',
                  onLookup: (context) async =>
                      const FdcLookupResult({'missing_field': 'value'}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
    );
    await tester.pumpAndSettle();

    expect(dataSet.fieldValue('code'), 'A');
  });

  testWidgets('lookup uses the column-level icon', (tester) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(name: 'code', size: 255)],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'code': 'A'},
        ],
      ),
    );
    dataSet.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 160,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: <FdcGridColumn<dynamic>>[
                FdcTextColumn<String>(
                  fieldName: 'code',
                  lookupIcon: Icons.person_search,
                  onLookup: (context) async => null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();

    final lookupButton = find.byKey(
      const ValueKey<String>('fdc-grid-lookup-button'),
    );
    expect(lookupButton, findsOneWidget);
    expect(
      find.descendant(
        of: lookupButton,
        matching: find.byIcon(Icons.person_search),
      ),
      findsOneWidget,
    );
  });

  testWidgets('column lookup shortcut invokes lookup with editor text', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(name: 'code', size: 255)],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'code': 'A'},
        ],
      ),
    );
    dataSet.open();

    var lookupCount = 0;
    String? editorText;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 160,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: <FdcGridColumn<dynamic>>[
                FdcTextColumn<String>(
                  fieldName: 'code',
                  lookupShortcut: const FdcKeyboardShortcut(FdcKeyboardKey.f3),
                  onLookup: (context) async {
                    lookupCount++;
                    editorText = context.lookupText;
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'lookup query');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await tester.pumpAndSettle();

    expect(lookupCount, 1);
    expect(editorText, 'lookup query');
  });

  testWidgets('lookup ignores a second invocation while one is in progress', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcStringField(name: 'code', size: 255)],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'code': 'A'},
        ],
      ),
    );
    dataSet.open();

    final completer = Completer<void>();
    var lookupCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 160,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: <FdcGridColumn<dynamic>>[
                FdcTextColumn<String>(
                  fieldName: 'code',
                  onLookup: (context) async {
                    lookupCount += 1;
                    await completer.future;
                    return const FdcLookupResult({'code': 'B'});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey<String>('fdc-grid-lookup-button'));
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();

    expect(lookupCount, 1);

    completer.complete();
    await tester.pumpAndSettle();

    expect(dataSet.fieldValue('code'), 'B');
  });

  testWidgets(
    'lookup result is discarded when active cell changes while async lookup is open',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcStringField(name: 'code', size: 255)],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'code': 'A'},
            {'code': 'C'},
          ],
        ),
      );
      dataSet.open();

      final completer = Completer<void>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(visible: false),
                toolbar: const FdcGridToolbar(visible: false),
                columns: <FdcGridColumn<dynamic>>[
                  FdcTextColumn<String>(
                    fieldName: 'code',
                    onLookup: (context) async {
                      await completer.future;
                      return const FdcLookupResult({'code': 'B'});
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
      );
      await tester.pump();
      await tester.tap(find.text('C'));
      await tester.pumpAndSettle();

      completer.complete();
      await tester.pumpAndSettle();

      dataSet.moveToRecord(1);
      expect(dataSet.fieldValue('code'), 'A');
      dataSet.moveToRecord(2);
      expect(dataSet.fieldValue('code'), 'C');
    },
  );

  testWidgets(
    'lookup rolls back primary value when an additional write fails',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'code', size: 255),
          FdcIntegerField(name: 'qty'),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'code': 'A', 'qty': 1},
          ],
        ),
      );
      dataSet.open();

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
                      return const FdcLookupResult({
                        'code': 'B',
                        'qty': 'invalid',
                      });
                    },
                  ),
                  const FdcIntegerColumn(fieldName: 'qty'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
      );
      await tester.pumpAndSettle();

      expect(dataSet.fieldValue('code'), 'A');
      expect(dataSet.fieldValue('qty'), 1);
    },
  );

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
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'B');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(modes, contains(FdcLookupMode.resolve));
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '123');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'missing');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.textContaining('Unknown lookup value'), findsOneWidget);
    expect(resolveCount, 1);
    expect(dataSet.fieldValue('code'), 'A');
    expect(dataSet.fieldValue('description'), 'Old');

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'missing');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(resolveCount, 1);
      expect(dataSet.fieldValue('code'), 'A');
      expect(find.byType(TextField), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(resolveCount, 2);

      await tester.enterText(find.byType(TextField).first, 'B');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'missing');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(resolveCount, 1);
      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.text('Old'));
      await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'B');
    await tester.pump();
    await tester.tap(find.text('Old'));
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();

    expect(resolveCount, 1);
    expect(dataSet.fieldValue('code'), 'B');
    expect(dataSet.fieldValue('description'), 'Resolved B');
  });

  testWidgets(
    'lookup resolve error does not reenter through dialog focus bounce but explicit pointer retry works',
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
                        throw StateError(
                          'Unknown lookup value ${context.lookupText}.',
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'missing');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(resolveCount, 1);
      expect(
        find.textContaining('Unknown lookup value missing'),
        findsOneWidget,
      );

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(resolveCount, 1);
      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.text('Old'));
      await tester.pumpAndSettle();

      expect(resolveCount, 2);
      expect(
        find.textContaining('Unknown lookup value missing'),
        findsOneWidget,
      );
      expect(dataSet.fieldValue('code'), 'A');
      expect(dataSet.fieldValue('description'), 'Old');
    },
  );

  testWidgets(
    'lookup search result suppresses only the immediate implicit resolve commit',
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

      var searchCount = 0;
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
                  const FdcTextColumn<String>(fieldName: 'description'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'typed search');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
      );
      await tester.pumpAndSettle();

      expect(searchCount, 1);
      expect(resolveCount, 0);
      expect(dataSet.fieldValue('code'), 'B');
      expect(dataSet.fieldValue('description'), 'Selected');

      await tester.tap(find.text('Selected'));
      await tester.pumpAndSettle();

      expect(searchCount, 1);
      expect(resolveCount, 0);
    },
  );

  testWidgets('lookup search cancel does not suppress later resolve commit', (
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

    var searchCount = 0;
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
                    if (context.lookupMode == FdcLookupMode.search) {
                      searchCount++;
                      return null;
                    }
                    resolveCount++;
                    return FdcLookupResult({
                      'code': context.lookupText,
                      'description': 'Resolved ${context.lookupText}',
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
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'B');
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
    );
    await tester.pumpAndSettle();

    expect(searchCount, 1);
    expect(resolveCount, 0);
    expect(dataSet.fieldValue('code'), 'A');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(searchCount, 1);
    expect(resolveCount, 1);
    expect(dataSet.fieldValue('code'), 'B');
    expect(dataSet.fieldValue('description'), 'Resolved B');
  });

  testWidgets(
    'lookup resolve applies onValueChanging replacement and fires value changed once',
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

      var lookupCount = 0;
      var changingCount = 0;
      var changedCount = 0;
      final changedValues = <String?>[];

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
                  const FdcTextColumn<String>(fieldName: 'description'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'B');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(lookupCount, 1);
      expect(changingCount, 1);
      expect(changedCount, 1);
      expect(changedValues, <String?>['B-event']);
      expect(dataSet.fieldValue('code'), 'B-event');
      expect(dataSet.fieldValue('description'), 'Changed by event');
    },
  );

  testWidgets(
    'lookup resolve cancellation from onValueChanging keeps editor active and does not fire changed',
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

      var lookupCount = 0;
      var changingCount = 0;
      var changedCount = 0;

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
                  const FdcTextColumn<String>(fieldName: 'description'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'B');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();

      expect(lookupCount, 1);
      expect(changingCount, 1);
      expect(changedCount, 0);
      expect(dataSet.fieldValue('code'), 'A');
      expect(dataSet.fieldValue('description'), 'Old');
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets(
    'active grid search sibling-only result restores primary editor text',
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
      )..open();

      var searchCount = 0;
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
                      if (context.lookupMode == FdcLookupMode.search) {
                        searchCount++;
                        return const FdcLookupResult({
                          'description': 'Sibling only',
                        });
                      }
                      resolveCount++;
                      return FdcLookupResult({
                        'code': context.lookupText,
                        'description': 'Resolved ${context.lookupText}',
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'lookup query');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
      );
      await tester.pumpAndSettle();

      expect(searchCount, 1);
      expect(resolveCount, 0);
      expect(dataSet.fieldValue('code'), 'A');
      expect(dataSet.fieldValue('description'), 'Sibling only');
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        'A',
      );

      await tester.tap(find.text('Sibling only'));
      await tester.pumpAndSettle();

      expect(resolveCount, 0);
    },
  );

  testWidgets(
    'active grid search same-primary result restores primary editor text',
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
      )..open();

      var searchCount = 0;
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
                      if (context.lookupMode == FdcLookupMode.search) {
                        searchCount++;
                        return const FdcLookupResult({
                          'code': 'A',
                          'description': 'Same primary',
                        });
                      }
                      resolveCount++;
                      return FdcLookupResult({
                        'code': context.lookupText,
                        'description': 'Resolved ${context.lookupText}',
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
      await tester.pumpAndSettle();

      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'lookup query');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
      );
      await tester.pumpAndSettle();

      expect(searchCount, 1);
      expect(resolveCount, 0);
      expect(dataSet.fieldValue('code'), 'A');
      expect(dataSet.fieldValue('description'), 'Same primary');
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        'A',
      );

      await tester.tap(find.text('Same primary'));
      await tester.pumpAndSettle();

      expect(resolveCount, 0);
    },
  );
}
