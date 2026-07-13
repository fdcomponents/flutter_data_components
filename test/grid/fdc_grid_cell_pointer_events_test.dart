import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

void main() {
  testWidgets('cell pointer callbacks expose row column value and positions', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(name: 'name', size: 64),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'id': 1, 'name': 'Alpha'},
        ],
      ),
    );
    dataSet.open();

    final tapDownEvents = <FdcGridCellPointerContext>[];
    final doubleTapEvents = <FdcGridCellPointerContext>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 200,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: const <FdcGridColumn<dynamic>>[
                FdcIntegerColumn<dynamic>(fieldName: 'id'),
                FdcTextColumn<dynamic>(fieldName: 'name'),
              ],
              onCellTapDown: tapDownEvents.add,
              onCellDoubleTap: doubleTapEvents.add,
            ),
          ),
        ),
      ),
    );
    await pumpPendingFrames(tester);

    final alpha = find.text('Alpha').first;
    await tester.tap(alpha);
    await tester.pump();

    expect(tapDownEvents, hasLength(1));
    expect(tapDownEvents.single.dataSet, same(dataSet));
    expect(tapDownEvents.single.rowIndex, 0);
    expect(tapDownEvents.single.columnIndex, 1);
    expect(tapDownEvents.single.column.fieldName, 'name');
    expect(tapDownEvents.single.value, 'Alpha');
    expect(tapDownEvents.single.row['id'], 1);
    expect(tapDownEvents.single.globalPosition, isNot(Offset.zero));

    // Reset the runtime double-tap candidate deterministically by tapping a
    // different cell. Advancing the widget-test clock does not advance
    // DateTime.now(), which the grid uses for double-tap detection.
    await tester.tap(find.text('1').first);
    await tester.pump();
    tapDownEvents.clear();

    await tester.tap(alpha);
    await tester.pump();
    await tester.tap(alpha);
    await pumpPendingFrames(tester);

    expect(tapDownEvents, hasLength(2));
    expect(doubleTapEvents, hasLength(1));
    expect(doubleTapEvents.single.rowIndex, 0);
    expect(doubleTapEvents.single.column.fieldName, 'name');
    expect(doubleTapEvents.single.value, 'Alpha');
  });
}
