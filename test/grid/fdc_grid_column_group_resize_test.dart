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
  testWidgets(
    'column group resize distributes width proportionally within min and max bounds',
    (tester) async {
      await tester.pumpWidget(
        _host(
          dataSet: _groupedGridDataSet(),
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn(fieldName: 'id', width: 80),
            FdcTextColumn(
              fieldName: 'name',
              groupId: 'customer',
              width: 100,
              minWidth: 80,
              maxWidth: 130,
            ),
            FdcTextColumn(
              fieldName: 'city',
              groupId: 'customer',
              width: 200,
              minWidth: 150,
              maxWidth: 260,
            ),
            FdcDecimalColumn(fieldName: 'amount', width: 80),
          ],
          columnGroups: const <FdcGridColumnGroup>[
            FdcGridColumnGroup(id: 'customer', label: 'Customer'),
          ],
        ),
      );
      await pumpPendingFrames(tester);

      final group = find.byKey(
        const ValueKey<String>('fdc-grid-column-group-1-2'),
      );
      final nameHeader = find.byKey(
        const ValueKey<String>('fdc-grid-header-field-name'),
      );
      final cityHeader = find.byKey(
        const ValueKey<String>('fdc-grid-header-field-city'),
      );
      expect(group, findsOneWidget);
      expect(nameHeader, findsOneWidget);
      expect(cityHeader, findsOneWidget);
      expect(tester.getSize(nameHeader).width, closeTo(100, 0.5));
      expect(tester.getSize(cityHeader).width, closeTo(200, 0.5));

      final groupRect = tester.getRect(group);
      final resizeGesture = await tester.startGesture(
        Offset(groupRect.right - 2, groupRect.center.dy),
      );
      await tester.pump();
      await resizeGesture.moveBy(const Offset(120, 0));
      await tester.pump();
      await resizeGesture.up();
      await pumpPendingFrames(tester);

      expect(tester.getSize(nameHeader).width, closeTo(130, 0.5));
      expect(tester.getSize(cityHeader).width, closeTo(260, 0.5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'column group resize shrink distributes width proportionally within min bounds',
    (tester) async {
      await tester.pumpWidget(
        _host(
          dataSet: _groupedGridDataSet(),
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn(fieldName: 'id', width: 80),
            FdcTextColumn(
              fieldName: 'name',
              groupId: 'customer',
              width: 100,
              minWidth: 90,
              maxWidth: 180,
            ),
            FdcTextColumn(
              fieldName: 'city',
              groupId: 'customer',
              width: 200,
              minWidth: 150,
              maxWidth: 300,
            ),
            FdcDecimalColumn(fieldName: 'amount', width: 80),
          ],
          columnGroups: const <FdcGridColumnGroup>[
            FdcGridColumnGroup(id: 'customer', label: 'Customer'),
          ],
        ),
      );
      await pumpPendingFrames(tester);

      final group = find.byKey(
        const ValueKey<String>('fdc-grid-column-group-1-2'),
      );
      final nameHeader = find.byKey(
        const ValueKey<String>('fdc-grid-header-field-name'),
      );
      final cityHeader = find.byKey(
        const ValueKey<String>('fdc-grid-header-field-city'),
      );
      expect(group, findsOneWidget);
      expect(nameHeader, findsOneWidget);
      expect(cityHeader, findsOneWidget);

      final groupRect = tester.getRect(group);
      final resizeGesture = await tester.startGesture(
        Offset(groupRect.right - 2, groupRect.center.dy),
      );
      await tester.pump();
      await resizeGesture.moveBy(const Offset(-120, 0));
      await tester.pump();
      await resizeGesture.up();
      await pumpPendingFrames(tester);

      expect(tester.getSize(nameHeader).width, closeTo(90, 0.5));
      expect(tester.getSize(cityHeader).width, closeTo(150, 0.5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ungrouped header segment resizes as an anonymous column group', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        dataSet: _groupedGridDataSet(),
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn(
            fieldName: 'id',
            width: 80,
            minWidth: 60,
            maxWidth: 120,
          ),
          FdcTextColumn(
            fieldName: 'name',
            groupId: 'customer',
            width: 100,
            minWidth: 80,
            maxWidth: 180,
          ),
          FdcTextColumn(
            fieldName: 'city',
            width: 200,
            minWidth: 150,
            maxWidth: 300,
          ),
          FdcDecimalColumn(
            fieldName: 'amount',
            width: 80,
            minWidth: 70,
            maxWidth: 90,
          ),
        ],
        columnGroups: const <FdcGridColumnGroup>[
          FdcGridColumnGroup(id: 'customer', label: 'Customer'),
        ],
      ),
    );
    await pumpPendingFrames(tester);

    final anonymousGroup = find.byKey(
      const ValueKey<String>('fdc-grid-column-group-2-2'),
    );
    final cityHeader = find.byKey(
      const ValueKey<String>('fdc-grid-header-field-city'),
    );
    final amountHeader = find.byKey(
      const ValueKey<String>('fdc-grid-header-field-amount'),
    );
    expect(anonymousGroup, findsOneWidget);
    expect(cityHeader, findsOneWidget);
    expect(amountHeader, findsOneWidget);

    final groupRect = tester.getRect(anonymousGroup);
    final resizeGesture = await tester.startGesture(
      Offset(groupRect.right - 2, groupRect.center.dy),
    );
    await tester.pump();
    await resizeGesture.moveBy(const Offset(60, 0));
    await tester.pump();
    await resizeGesture.up();
    await pumpPendingFrames(tester);

    expect(tester.getSize(cityHeader).width, closeTo(250, 0.5));
    expect(tester.getSize(amountHeader).width, closeTo(90, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'column group membership is column-based for duplicate field columns',
    (tester) async {
      await tester.pumpWidget(
        _host(
          dataSet: _groupedGridDataSet(),
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn(
              id: 'name-primary',
              fieldName: 'name',
              groupId: 'primary',
            ),
            FdcTextColumn(
              id: 'name-secondary',
              fieldName: 'name',
              groupId: 'secondary',
            ),
          ],
          columnGroups: const <FdcGridColumnGroup>[
            FdcGridColumnGroup(id: 'primary', label: 'Primary'),
            FdcGridColumnGroup(id: 'secondary', label: 'Secondary'),
          ],
        ),
      );
      await pumpPendingFrames(tester);

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
