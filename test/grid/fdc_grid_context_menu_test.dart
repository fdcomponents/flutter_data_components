import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('column context menu overrides grid context menu', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(name: 'name', size: 80),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alpha'},
        ],
      ),
    );
    dataSet.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 220,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              menuBuilder: (context) => <FdcMenuEntry>[
                FdcMenuAction(text: 'Grid ${context.column.fieldName}'),
              ],
              columns: <FdcGridColumn<dynamic>>[
                FdcTextColumn(
                  fieldName: 'name',
                  width: 240,
                  menuBuilder: (context) => <FdcMenuEntry>[
                    FdcMenuAction(text: 'Column ${context.value}'),
                  ],
                ),
                const FdcIntegerColumn(fieldName: 'id', width: 100),
              ],
            ),
          ),
        ),
      ),
    );
    await _pumpGrid(tester);

    await _openSecondaryMenu(tester, find.text('Alpha'));
    expect(find.text('Column Alpha'), findsOneWidget);
    expect(find.text('Grid name'), findsNothing);

    await tester.tapAt(const Offset(1, 1));
    await tester.pump();

    await _openSecondaryMenu(tester, find.text('1'));
    expect(find.text('Grid id'), findsOneWidget);
  });

  testWidgets('grid menu append action runs once and closes cleanly', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(name: 'name', size: 80),
      ],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alpha'},
        ],
      ),
    );
    dataSet.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 220,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              menuBuilder: (_) => <FdcMenuEntry>[
                FdcMenuAction(text: 'Append record', onPressed: dataSet.append),
              ],
              columns: const <FdcGridColumn<dynamic>>[
                FdcTextColumn(fieldName: 'name', width: 240),
                FdcIntegerColumn(fieldName: 'id', width: 100),
              ],
            ),
          ),
        ),
      ),
    );
    await _pumpGrid(tester);

    await _openSecondaryMenu(tester, find.text('Alpha'));
    expect(find.text('Append record'), findsOneWidget);

    await tester.tap(find.text('Append record'));
    await tester.pump();
    await tester.pump();

    expect(dataSet.recordCount, 2);
    expect(find.text('Append record'), findsNothing);
  });
}

Future<void> _pumpGrid(WidgetTester tester) async {
  await tester.pump();
  // The grid schedules initialization work in a post-frame callback.
  await tester.pump();
}

Future<void> _openSecondaryMenu(WidgetTester tester, Finder finder) async {
  final gesture = await tester.startGesture(
    tester.getCenter(finder),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await tester.pump();
  await gesture.up();
  // Dynamic menu entries rebuild the anchor in one frame and open the overlay
  // from a post-frame callback, so a second frame is required.
  await tester.pump();
  await tester.pump();
}
