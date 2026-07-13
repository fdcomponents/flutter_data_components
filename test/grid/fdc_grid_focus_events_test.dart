import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

FdcDataSet _peopleDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name', label: 'Name'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha'},
        {'id': 2, 'name': 'Beta'},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

Widget _host({required FdcDataSet dataSet, required List<String> events}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 480,
        height: 240,
        child: FdcGrid(
          dataSet: dataSet,
          header: const FdcGridHeader(visible: false),
          toolbar: const FdcGridToolbar(visible: false),
          options: const FdcGridOptions(defaultColumnWidth: 120, rowHeight: 36),
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          onRowExit: (context) => events.add('rowExit:${context.rowIndex}'),
          onRowEnter: (context) => events.add('rowEnter:${context.rowIndex}'),
          onColumnExit: (context) => events.add(
            'columnExit:${context.fieldName}:${context.reason.name}',
          ),
          onColumnEnter: (context) => events.add(
            'columnEnter:${context.fieldName}:${context.reason.name}',
          ),
          onCellExit: (context) => events.add(
            'cellExit:${context.fieldName}:${context.rowIndex}:${context.reason.name}',
          ),
          onCellEnter: (context) => events.add(
            'cellEnter:${context.fieldName}:${context.rowIndex}:${context.reason.name}',
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('grid focus events fire for row and column changes', (
    tester,
  ) async {
    final events = <String>[];
    final dataSet = _peopleDataSet();

    await tester.pumpWidget(_host(dataSet: dataSet, events: events));
    await pumpPendingFrames(tester);

    await tester.tap(find.text('Alpha').first);
    await pumpPendingFrames(tester);

    expect(events, <String>[
      'rowEnter:0',
      'columnEnter:name:mouse',
      'cellEnter:name:0:mouse',
    ]);

    events.clear();
    await tester.tap(find.text('1').first);
    await pumpPendingFrames(tester);

    expect(events, <String>[
      'cellExit:name:0:mouse',
      'columnExit:name:mouse',
      'columnEnter:id:mouse',
      'cellEnter:id:0:mouse',
    ]);

    events.clear();
    await tester.tap(find.text('2').first);
    await pumpPendingFrames(tester);

    expect(events, <String>[
      'cellExit:id:0:mouse',
      'rowExit:0',
      'rowEnter:1',
      'cellEnter:id:1:mouse',
    ]);
  });
}
