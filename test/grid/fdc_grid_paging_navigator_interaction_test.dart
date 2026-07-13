import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

FdcDataSet _dataSet() => FdcDataSet(
  fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
  adapter: FdcMemoryDataAdapter(
    rows: <Map<String, Object?>>[
      for (var i = 1; i <= 25; i++) <String, Object?>{'id': i},
    ],
  ),
  paging: const FdcDataPagingOptions(enabled: true, pageSize: 10),
);

void main() {
  testWidgets('paging navigator buttons drive dataset navigation', (
    tester,
  ) async {
    final dataSet = _dataSet();
    await dataSet.open();
    const navigator = FdcGridPagingNavigator.input();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => navigator.buildForDataSet(context, dataSet),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Next page'));
    await pumpPendingFrames(tester);
    expect(dataSet.paging.pageIndex, 1);
    expect(dataSet['id'], 11);

    await tester.tap(find.byTooltip('Last page'));
    await pumpPendingFrames(tester);
    expect(dataSet.paging.pageIndex, 2);
    expect(dataSet['id'], 21);

    await tester.tap(find.byTooltip('Previous page'));
    await pumpPendingFrames(tester);
    expect(dataSet.paging.pageIndex, 1);

    await tester.tap(find.byTooltip('First page'));
    await pumpPendingFrames(tester);
    expect(dataSet.paging.pageIndex, 0);
  });

  testWidgets('page input clamps out-of-range page to last page', (
    tester,
  ) async {
    final dataSet = _dataSet();
    await dataSet.open();
    const navigator = FdcGridPagingNavigator.input();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => navigator.buildForDataSet(context, dataSet),
          ),
        ),
      ),
    );

    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '99');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpPendingFrames(tester);

    expect(dataSet.paging.pageIndex, 2);
    expect(dataSet['id'], 21);
  });

  testWidgets('page-size selector changes page size through its menu', (
    tester,
  ) async {
    final dataSet = _dataSet();
    await dataSet.open();
    final selector = FdcGridPageSizeSelector(
      label: 'Rows',
      options: <int>[10, 20],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => selector.buildForDataSet(context, dataSet),
          ),
        ),
      ),
    );

    await tester.tap(find.text('10'));
    await pumpPendingFrames(tester);
    await tester.tap(find.text('20').last);
    await pumpPendingFrames(tester);

    expect(dataSet.paging.pageSize, 20);
    expect(dataSet.paging.pageIndex, 0);
    expect(dataSet.recordCount, 20);
  });
}
