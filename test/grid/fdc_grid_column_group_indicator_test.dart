import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_header_metrics.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_row_indicator_header.dart';
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
    'row indicator select all aligns with leaf header when filters are hidden',
    (tester) async {
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
          rowIndicator: const FdcGridRowIndicator(
            visible: true,
            options: FdcGridRowIndicatorOptions(showRowSelect: true),
          ),
        ),
      );
      await pumpPendingFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(Checkbox), findsNWidgets(2));

      final headerCheckboxCenter = tester.getCenter(
        find.byType(Checkbox).first,
      );
      final mainMenuCenter = tester.getCenter(find.byIcon(Icons.menu));
      final leafHeaderCenter = tester.getCenter(
        find.byKey(const ValueKey<String>('fdc-grid-header-field-name')),
      );

      expect(headerCheckboxCenter.dy, closeTo(leafHeaderCenter.dy, 1.0));
      expect(mainMenuCenter.dy, closeTo(leafHeaderCenter.dy, 1.0));
    },
  );

  testWidgets(
    'status-only row indicator main menu stays vertically centered when filters are hidden',
    (tester) async {
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
          rowIndicator: const FdcGridRowIndicator(visible: true),
        ),
      );
      await pumpPendingFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byIcon(Icons.menu), findsOneWidget);

      final menuCenter = tester.getCenter(find.byIcon(Icons.menu));
      final indicatorHeaderCenter = tester.getCenter(
        find.byType(FdcGridRowIndicatorHeader),
      );
      final leafHeaderCenter = tester.getCenter(
        find.byKey(const ValueKey<String>('fdc-grid-header-field-name')),
      );

      expect(menuCenter.dx, closeTo(indicatorHeaderCenter.dx, 1.0));
      expect(menuCenter.dy, closeTo(indicatorHeaderCenter.dy, 1.0));
      expect(menuCenter.dy, lessThan(leafHeaderCenter.dy));
    },
  );

  testWidgets(
    'status and record-number row indicator centers main menu horizontally',
    (tester) async {
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
          rowIndicator: const FdcGridRowIndicator(
            visible: true,
            options: FdcGridRowIndicatorOptions(showRowNumbers: true),
          ),
        ),
      );
      await pumpPendingFrames(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byIcon(Icons.menu), findsOneWidget);

      final menuCenter = tester.getCenter(find.byIcon(Icons.menu));
      final indicatorHeaderCenter = tester.getCenter(
        find.byType(FdcGridRowIndicatorHeader),
      );
      final leafHeaderCenter = tester.getCenter(
        find.byKey(const ValueKey<String>('fdc-grid-header-field-name')),
      );

      expect(menuCenter.dx, closeTo(indicatorHeaderCenter.dx, 1.0));
      expect(menuCenter.dy, closeTo(leafHeaderCenter.dy, 1.0));
    },
  );

  testWidgets('row indicator status icon stays centered in every status slot', (
    tester,
  ) async {
    Future<void> pumpAndExpectCentered(
      FdcGridRowIndicatorOptions options,
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
          rowIndicator: FdcGridRowIndicator(visible: true, options: options),
        ),
      );
      await pumpPendingFrames(tester);

      expect(tester.takeException(), isNull);

      final statusSlotFinder = find
          .byKey(const ValueKey<String>('fdc-grid-row-indicator-status-slot'))
          .first;
      final statusSlotCenter = tester.getCenter(statusSlotFinder);
      final statusSlotSize = tester.getSize(statusSlotFinder);
      final statusIconBoxCenter = tester.getCenter(
        find.byKey(
          const ValueKey<String>('fdc-grid-row-indicator-status-icon-box'),
        ),
      );
      final statusIconBoxSize = tester.getSize(
        find.byKey(
          const ValueKey<String>('fdc-grid-row-indicator-status-icon-box'),
        ),
      );

      expect(
        statusSlotSize.width,
        closeTo(
          FdcGridHeaderMetrics.rowIndicatorStatusSlotWidth(
            showRecordStatus: options.showRecordStatus,
            showRowSelect: options.showRowSelect,
            showRowNumbers: options.showRowNumbers,
          ),
          0.1,
        ),
      );
      expect(statusSlotSize.height, closeTo(36, 0.1));
      expect(
        statusIconBoxSize.width,
        closeTo(FdcGridHeaderMetrics.rowIndicatorStatusIconSize, 0.1),
      );
      expect(
        statusIconBoxSize.height,
        closeTo(FdcGridHeaderMetrics.rowIndicatorStatusIconSize, 0.1),
      );
      expect(statusIconBoxCenter.dx, closeTo(statusSlotCenter.dx, 0.5));
      expect(statusIconBoxCenter.dy, closeTo(statusSlotCenter.dy, 0.5));
    }

    await pumpAndExpectCentered(const FdcGridRowIndicatorOptions());
    await pumpAndExpectCentered(
      const FdcGridRowIndicatorOptions(showRowSelect: true),
    );
    await pumpAndExpectCentered(
      const FdcGridRowIndicatorOptions(showRowNumbers: true),
    );
    await pumpAndExpectCentered(
      const FdcGridRowIndicatorOptions(
        showRowSelect: true,
        showRowNumbers: true,
      ),
    );
  });
}
