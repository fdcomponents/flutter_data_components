import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

void main() {
  testWidgets('onCellChanged reports context with old and new values', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcBooleanField(name: 'active'),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'active': false},
        ],
      ),
    );
    dataSet.open();

    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 180,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: const <FdcGridColumn<dynamic>>[
                FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
                FdcBooleanColumn<dynamic>(fieldName: 'active'),
              ],
              onCellChanged: (context) {
                events.add(
                  '${context.rowIndex}:${context.columnIndex}:'
                  '${context.fieldName}:${context.oldValue}->${context.value}:'
                  '${(context.column as FdcGridColumn<dynamic>?)?.fieldName}',
                );
              },
            ),
          ),
        ),
      ),
    );
    await pumpPendingFrames(tester);

    await tester.tap(find.byType(Checkbox).first);
    await pumpPendingFrames(tester);

    expect(events, <String>['0:1:active:false->true:active']);
  });

  testWidgets(
    'onCellChanged callback errors are shown as grid operation errors',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcBooleanField(name: 'active'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'active': false},
          ],
        ),
      );
      dataSet.open();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 180,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(visible: false),
                toolbar: const FdcGridToolbar(visible: false),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
                  FdcBooleanColumn<dynamic>(fieldName: 'active'),
                ],
                onCellChanged: (_) {
                  throw StateError('cell callback failed');
                },
              ),
            ),
          ),
        ),
      );
      await pumpPendingFrames(tester);

      await tester.tap(find.byType(Checkbox).first);
      await pumpPendingFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('cell callback failed'), findsOneWidget);
    },
  );
}
