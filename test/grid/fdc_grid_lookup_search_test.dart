import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

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
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'typed query');
      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
      );
      await pumpPendingFrames(tester);

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
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
    );
    await pumpPendingFrames(tester);

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
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
    );
    await pumpPendingFrames(tester);

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
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('A'));
    await tester.pump();

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
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'lookup query');
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await pumpPendingFrames(tester);

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
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('A'));
    await tester.pump();
    final button = find.byKey(const ValueKey<String>('fdc-grid-lookup-button'));
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();

    expect(lookupCount, 1);

    completer.complete();
    await pumpPendingFrames(tester);

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
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
      );
      await tester.pump();
      await tester.tap(find.text('C'));
      await pumpPendingFrames(tester);

      completer.complete();
      await pumpPendingFrames(tester);

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
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
      );
      await pumpPendingFrames(tester);

      expect(dataSet.fieldValue('code'), 'A');
      expect(dataSet.fieldValue('qty'), 1);
    },
  );
}
