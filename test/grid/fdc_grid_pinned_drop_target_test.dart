import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

void main() {
  testWidgets('single-column pinned bands still expose header drag targets', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcStringField(name: 'left', size: 20),
        FdcStringField(name: 'center_a', size: 20),
        FdcStringField(name: 'center_b', size: 20),
        FdcStringField(name: 'right', size: 20),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'left': 'L', 'center_a': 'A', 'center_b': 'B', 'right': 'R'},
        ],
      ),
    );
    dataSet.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 260,
            child: FdcGrid(
              dataSet: dataSet,
              options: const FdcGridOptions(allowColumnReordering: true),
              toolbar: const FdcGridToolbar(visible: false),
              header: const FdcGridHeader(
                filters: FdcGridHeaderFilters(initiallyVisible: false),
              ),
              columns: const <FdcGridColumn<dynamic>>[
                FdcTextColumn<dynamic>(
                  fieldName: 'left',
                  pin: FdcGridColumnPin.startFixed,
                ),
                FdcTextColumn<dynamic>(fieldName: 'center_a'),
                FdcTextColumn<dynamic>(fieldName: 'center_b'),
                FdcTextColumn<dynamic>(
                  fieldName: 'right',
                  pin: FdcGridColumnPin.endFixed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await pumpPendingFrames(tester);

    const viewportTargetKey = ValueKey<String>(
      'fdc-grid-column-reorder-viewport-target',
    );
    expect(find.byKey(viewportTargetKey), findsOneWidget);

    final allTargets = find.byType(DragTarget<int>);
    expect(allTargets, findsNWidgets(5));
    expect(
      find.descendant(of: find.byType(FdcGrid), matching: allTargets),
      findsNWidgets(5),
    );
  });
}
