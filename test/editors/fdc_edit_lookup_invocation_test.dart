import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      await pumpPendingFrames(tester);

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
    await pumpPendingFrames(tester);

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
      await pumpPendingFrames(tester);

      expect(dataSet.fieldValue('code'), 'A');
      expect(dataSet.fieldValue('qty'), 1);
    },
  );
}
