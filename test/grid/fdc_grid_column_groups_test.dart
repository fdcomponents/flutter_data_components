import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_header_metrics.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_row_indicator_header.dart';
import 'package:flutter_test/flutter_test.dart';

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

    final label = tester.widget<Text>(find.text('Customer'));

    expect(label.style?.color, Colors.deepPurple);
    expect(label.style?.fontWeight, FontWeight.w700);
  });

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

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
    await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('duplicate column group ids throw a clear error', (tester) async {
    await tester.pumpWidget(
      _host(
        dataSet: _groupedGridDataSet(),
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn(fieldName: 'name', groupId: 'customer'),
        ],
        columnGroups: const <FdcGridColumnGroup>[
          FdcGridColumnGroup(id: 'customer', label: 'Customer'),
          FdcGridColumnGroup(id: 'customer', label: 'Duplicate customer'),
        ],
      ),
    );
    await tester.pump();

    final exception = tester.takeException();
    expect(exception, isA<ArgumentError>());
    expect(
      exception.toString(),
      contains('Duplicate FdcGridColumnGroup.id "customer"'),
    );
  });

  testWidgets('blank and whitespace group ids throw clear errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        dataSet: _groupedGridDataSet(),
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn(fieldName: 'name'),
        ],
        columnGroups: const <FdcGridColumnGroup>[
          FdcGridColumnGroup(id: ' ', label: 'Blank'),
        ],
      ),
    );
    await tester.pump();

    final blankException = tester.takeException();
    expect(blankException, isA<ArgumentError>());
    expect(
      blankException.toString(),
      contains('FdcGridColumnGroup.id must not be empty'),
    );

    await tester.pumpWidget(
      _host(
        dataSet: _groupedGridDataSet(),
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn(fieldName: 'name', groupId: ' customer'),
        ],
        columnGroups: const <FdcGridColumnGroup>[
          FdcGridColumnGroup(id: 'customer', label: 'Customer'),
        ],
      ),
    );
    await tester.pump();

    final whitespaceException = tester.takeException();
    expect(whitespaceException, isA<ArgumentError>());
    expect(
      whitespaceException.toString(),
      contains(
        'FdcGridColumn.groupId must not contain leading or trailing whitespace',
      ),
    );
  });

  testWidgets('blank and whitespace column ids throw clear errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        dataSet: _groupedGridDataSet(),
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn(id: '', fieldName: 'name'),
        ],
        columnGroups: const <FdcGridColumnGroup>[],
      ),
    );
    await tester.pump();

    final blankException = tester.takeException();
    expect(blankException, isA<ArgumentError>());
    expect(
      blankException.toString(),
      contains('FdcGridColumn.id must not be empty'),
    );

    await tester.pumpWidget(
      _host(
        dataSet: _groupedGridDataSet(),
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn(id: ' name', fieldName: 'name'),
        ],
        columnGroups: const <FdcGridColumnGroup>[],
      ),
    );
    await tester.pump();

    final whitespaceException = tester.takeException();
    expect(whitespaceException, isA<ArgumentError>());
    expect(
      whitespaceException.toString(),
      contains(
        'FdcGridColumn.id must not contain leading or trailing whitespace',
      ),
    );
  });

  testWidgets('missing column group reference throws a clear error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        dataSet: _groupedGridDataSet(),
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn(fieldName: 'name', groupId: 'missing'),
        ],
        columnGroups: const <FdcGridColumnGroup>[
          FdcGridColumnGroup(id: 'customer', label: 'Customer'),
        ],
      ),
    );
    await tester.pump();

    final exception = tester.takeException();
    expect(exception, isA<ArgumentError>());
    expect(exception.toString(), contains('FdcGridColumn.groupId "missing"'));
  });

  testWidgets('column group label updates when only columnGroups changes', (
    tester,
  ) async {
    final dataSet = _groupedGridDataSet();
    const columns = <FdcGridColumn<dynamic>>[
      FdcIntegerColumn(fieldName: 'id'),
      FdcTextColumn(fieldName: 'name', groupId: 'customer'),
      FdcTextColumn(fieldName: 'city', groupId: 'customer'),
      FdcDecimalColumn(fieldName: 'amount'),
    ];

    await tester.pumpWidget(
      _host(
        dataSet: dataSet,
        columns: columns,
        columnGroups: const <FdcGridColumnGroup>[
          FdcGridColumnGroup(id: 'customer', label: 'Customer'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Client'), findsNothing);

    await tester.pumpWidget(
      _host(
        dataSet: dataSet,
        columns: columns,
        columnGroups: const <FdcGridColumnGroup>[
          FdcGridColumnGroup(id: 'customer', label: 'Client'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer'), findsNothing);
    expect(find.text('Client'), findsOneWidget);
  });

  testWidgets(
    'column group style updates when only columnGroups style changes',
    (tester) async {
      final dataSet = _groupedGridDataSet();
      const columns = <FdcGridColumn<dynamic>>[
        FdcTextColumn(fieldName: 'name', groupId: 'customer'),
        FdcTextColumn(fieldName: 'city', groupId: 'customer'),
      ];

      await tester.pumpWidget(
        _host(
          dataSet: dataSet,
          columns: columns,
          columnGroups: const <FdcGridColumnGroup>[
            FdcGridColumnGroup(
              id: 'customer',
              label: 'Customer',
              style: FdcGridColumnGroupStyle(
                textStyle: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.text('Customer')).style?.color,
        Colors.deepPurple,
      );

      await tester.pumpWidget(
        _host(
          dataSet: dataSet,
          columns: columns,
          columnGroups: const <FdcGridColumnGroup>[
            FdcGridColumnGroup(
              id: 'customer',
              label: 'Customer',
              style: FdcGridColumnGroupStyle(
                textStyle: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(find.text('Customer')).style?.color,
        Colors.green,
      );
    },
  );

  testWidgets('column list in-place mutation refreshes grid columns', (
    tester,
  ) async {
    final dataSet = _groupedGridDataSet();
    final columns = <FdcGridColumn<dynamic>>[
      const FdcIntegerColumn(fieldName: 'id'),
      const FdcTextColumn(fieldName: 'name'),
    ];

    await tester.pumpWidget(
      _host(
        dataSet: dataSet,
        columns: columns,
        columnGroups: const <FdcGridColumnGroup>[],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('City'), findsNothing);

    columns.add(const FdcTextColumn(fieldName: 'city'));

    await tester.pumpWidget(
      _host(
        dataSet: dataSet,
        columns: columns,
        columnGroups: const <FdcGridColumnGroup>[],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
  });

  testWidgets('columnGroups list in-place mutation refreshes group headers', (
    tester,
  ) async {
    final dataSet = _groupedGridDataSet();
    final columns = <FdcGridColumn<dynamic>>[
      const FdcIntegerColumn(fieldName: 'id'),
      const FdcTextColumn(fieldName: 'name', groupId: 'customer'),
      const FdcTextColumn(fieldName: 'city', groupId: 'customer'),
    ];
    final columnGroups = <FdcGridColumnGroup>[
      const FdcGridColumnGroup(id: 'customer', label: 'Customer'),
    ];

    await tester.pumpWidget(
      _host(dataSet: dataSet, columns: columns, columnGroups: columnGroups),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Client'), findsNothing);

    columnGroups[0] = const FdcGridColumnGroup(id: 'customer', label: 'Client');

    await tester.pumpWidget(
      _host(dataSet: dataSet, columns: columns, columnGroups: columnGroups),
    );
    await tester.pumpAndSettle();

    expect(find.text('Customer'), findsNothing);
    expect(find.text('Client'), findsOneWidget);
  });
}
