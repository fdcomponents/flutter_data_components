import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

void main() {
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
      expect(
        find.textContaining('Unknown lookup value missing'),
        findsOneWidget,
      );

      await tester.tap(find.text('OK'));
      await pumpPendingFrames(tester);

      expect(resolveCount, 1);
      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.text('Old'));
      await pumpPendingFrames(tester);

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
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'typed search');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
      );
      await pumpPendingFrames(tester);

      expect(searchCount, 1);
      expect(resolveCount, 0);
      expect(dataSet.fieldValue('code'), 'B');
      expect(dataSet.fieldValue('description'), 'Selected');

      await tester.tap(find.text('Selected'));
      await pumpPendingFrames(tester);

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
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'B');
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
    );
    await pumpPendingFrames(tester);

    expect(searchCount, 1);
    expect(resolveCount, 0);
    expect(dataSet.fieldValue('code'), 'A');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await pumpPendingFrames(tester);

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
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'lookup query');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
      );
      await pumpPendingFrames(tester);

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
      await pumpPendingFrames(tester);

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
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, 'lookup query');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey<String>('fdc-grid-lookup-button')),
      );
      await pumpPendingFrames(tester);

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
      await pumpPendingFrames(tester);

      expect(resolveCount, 0);
    },
  );
}
