import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

FdcDataSet _groupedGridDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id', label: 'ID'),
      FdcStringField(size: 255, name: 'name', label: 'Name'),
      FdcStringField(size: 255, name: 'city', label: 'City'),
      FdcDecimalField(name: 'amount', label: 'Amount', precision: 12, scale: 2),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha', 'city': 'Boston', 'amount': '10.00'},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

Widget _host({
  required FdcDataSet dataSet,
  required List<FdcGridColumn<dynamic>> columns,
  required List<FdcGridColumnGroup> columnGroups,
  FdcGridColumnPinning pinning = const FdcGridColumnPinning(enabled: true),
  FdcGridOptions options = const FdcGridOptions(
    allowColumnSorting: true,
    allowColumnReordering: true,
  ),
  FdcGridRowIndicator rowIndicator = const FdcGridRowIndicator(),
  FdcGridHeader header = const FdcGridHeader(
    filters: FdcGridHeaderFilters(visible: true, initiallyVisible: false),
  ),
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 520,
        height: 240,
        child: FdcGrid(
          dataSet: dataSet,
          columns: columns,
          columnGroups: columnGroups,
          pinning: pinning,
          options: options.copyWith(defaultColumnWidth: 120, rowHeight: 36),
          rowIndicator: rowIndicator,
          header: header.copyWith(height: 32),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('column groups render an additional visual header band', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        dataSet: _groupedGridDataSet(),
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn(fieldName: 'id'),
          FdcTextColumn(fieldName: 'name', groupId: 'customer'),
          FdcTextColumn(fieldName: 'city', groupId: 'customer'),
          FdcDecimalColumn(fieldName: 'amount'),
        ],
        columnGroups: const <FdcGridColumnGroup>[
          FdcGridColumnGroup(id: 'customer', label: 'Customer'),
        ],
      ),
    );
    await pumpPendingFrames(tester);

    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
  });

  testWidgets(
    'pinned regions render optional labels in the group header band',
    (tester) async {
      await tester.pumpWidget(
        _host(
          dataSet: _groupedGridDataSet(),
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn(fieldName: 'id', pin: FdcGridColumnPin.start),
            FdcTextColumn(fieldName: 'name', groupId: 'customer'),
            FdcTextColumn(fieldName: 'city', groupId: 'customer'),
            FdcDecimalColumn(fieldName: 'amount', pin: FdcGridColumnPin.end),
          ],
          columnGroups: const <FdcGridColumnGroup>[
            FdcGridColumnGroup(id: 'customer', label: 'Customer'),
          ],
          pinning: const FdcGridColumnPinning(
            startPinnedGroupLabel: 'Identity',
            unpinnedGroupLabel: 'General',
            endPinnedGroupLabel: 'Financial',
          ),
        ),
      );
      await pumpPendingFrames(tester);

      expect(find.text('Identity'), findsOneWidget);
      expect(find.text('General'), findsNothing);
      expect(find.text('Customer'), findsOneWidget);
      expect(find.text('Financial'), findsOneWidget);
    },
  );

  testWidgets('unpinned group label renders for ungrouped scrollable columns', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        dataSet: _groupedGridDataSet(),
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn(fieldName: 'id', pin: FdcGridColumnPin.start),
          FdcTextColumn(fieldName: 'name', groupId: 'customer'),
          FdcTextColumn(fieldName: 'city'),
          FdcDecimalColumn(fieldName: 'amount', pin: FdcGridColumnPin.end),
        ],
        columnGroups: const <FdcGridColumnGroup>[
          FdcGridColumnGroup(id: 'customer', label: 'Customer'),
        ],
        pinning: const FdcGridColumnPinning(
          startPinnedGroupLabel: 'Identity',
          unpinnedGroupLabel: 'General',
          endPinnedGroupLabel: 'Financial',
        ),
      ),
    );
    await pumpPendingFrames(tester);

    expect(find.text('Identity'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Financial'), findsOneWidget);
  });

  testWidgets('empty pinned region group labels render no text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        dataSet: _groupedGridDataSet(),
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn(fieldName: 'id', pin: FdcGridColumnPin.start),
          FdcTextColumn(fieldName: 'name', groupId: 'customer'),
          FdcTextColumn(fieldName: 'city', groupId: 'customer'),
          FdcDecimalColumn(fieldName: 'amount', pin: FdcGridColumnPin.end),
        ],
        columnGroups: const <FdcGridColumnGroup>[
          FdcGridColumnGroup(id: 'customer', label: 'Customer'),
        ],
      ),
    );
    await pumpPendingFrames(tester);

    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Identity'), findsNothing);
    expect(find.text('Financial'), findsNothing);
  });

  testWidgets('column group style overrides shared group header styling', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        dataSet: _groupedGridDataSet(),
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn(fieldName: 'name', groupId: 'customer'),
          FdcTextColumn(fieldName: 'city', groupId: 'customer'),
        ],
        columnGroups: const <FdcGridColumnGroup>[
          FdcGridColumnGroup(
            id: 'customer',
            label: 'Customer',
            style: FdcGridColumnGroupStyle(
              textStyle: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w700,
              ),
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.only(left: 14),
            ),
          ),
        ],
      ),
    );
    await pumpPendingFrames(tester);

    final label = tester.widget<Text>(find.text('Customer'));

    expect(label.style?.color, Colors.deepPurple);
    expect(label.style?.fontWeight, FontWeight.w700);
  });
}
