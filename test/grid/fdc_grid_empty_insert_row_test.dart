import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_row.dart'
    show FdcGridRowWidget;
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

class _ReadOnlyMemoryDataAdapter extends FdcMemoryDataAdapter {
  _ReadOnlyMemoryDataAdapter({required super.rows});

  @override
  bool get readOnly => true;
}

FdcDataSet _emptyPeopleDataSet({bool readOnly = false}) {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(name: 'name', size: 40),
    ],
    adapter: readOnly
        ? _ReadOnlyMemoryDataAdapter(rows: const <Map<String, Object?>>[])
        : FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
  );
  unawaited(dataSet.open());
  return dataSet;
}

FdcDataSet _peopleDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(name: 'name', size: 40),
    ],
    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'name': 'Alpha'},
        <String, Object?>{'id': 2, 'name': 'Beta'},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

Widget _host({
  required FdcDataSet dataSet,
  FdcGridOptions options = const FdcGridOptions(),
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 360,
        height: 180,
        child: FdcGrid(
          dataSet: dataSet,
          options: options,
          header: const FdcGridHeader(visible: false),
          toolbar: const FdcGridToolbar(visible: false),
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('editable empty grid renders one insert placeholder row', (
    tester,
  ) async {
    final dataSet = _emptyPeopleDataSet();

    await tester.pumpWidget(_host(dataSet: dataSet));
    await pumpPendingFrames(tester);

    expect(dataSet.recordCount, 0);
    expect(find.byType(FdcGridRowWidget), findsOneWidget);
  });

  testWidgets('read-only empty grid does not render insert placeholder row', (
    tester,
  ) async {
    final dataSet = _emptyPeopleDataSet(readOnly: true);

    await tester.pumpWidget(_host(dataSet: dataSet));
    await pumpPendingFrames(tester);

    expect(dataSet.recordCount, 0);
    expect(find.byType(FdcGridRowWidget), findsNothing);
  });

  testWidgets('filtered empty view keeps insert placeholder row visible', (
    tester,
  ) async {
    final dataSet = _peopleDataSet();
    dataSet.filter.set(const <FdcDataSetFilter>[
      FdcDataSetFilter(
        fieldName: 'name',
        operator: FdcFilterOperator.equals,
        value: 'No match',
      ),
    ]);

    await tester.pumpWidget(_host(dataSet: dataSet));
    await pumpPendingFrames(tester);

    expect(dataSet.filter.active, isTrue);
    expect(dataSet.recordCount, 0);
    expect(find.byType(FdcGridRowWidget), findsOneWidget);
  });

  testWidgets('typing into empty insert row appends the first dataset record', (
    tester,
  ) async {
    final dataSet = _emptyPeopleDataSet();

    await tester.pumpWidget(_host(dataSet: dataSet));
    await pumpPendingFrames(tester);

    await tester.tap(find.byType(FdcGridRowWidget).first);
    await pumpPendingFrames(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await pumpPendingFrames(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await pumpPendingFrames(tester);

    expect(dataSet.recordCount, 1);
    expect(dataSet.state, FdcDataSetState.insert);
    expect(find.byType(TextField), findsOneWidget);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.focusNode?.hasFocus, isTrue);
  });
}
