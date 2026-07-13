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
    await pumpPendingFrames(tester);

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
    await pumpPendingFrames(tester);

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
      await pumpPendingFrames(tester);

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
      await pumpPendingFrames(tester);

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
    await pumpPendingFrames(tester);

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
    await pumpPendingFrames(tester);

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
    await pumpPendingFrames(tester);

    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Client'), findsNothing);

    columnGroups[0] = const FdcGridColumnGroup(id: 'customer', label: 'Client');

    await tester.pumpWidget(
      _host(dataSet: dataSet, columns: columns, columnGroups: columnGroups),
    );
    await pumpPendingFrames(tester);

    expect(find.text('Customer'), findsNothing);
    expect(find.text('Client'), findsOneWidget);
  });
}
