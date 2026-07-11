part of '../fdc_grid_widget_ux_test.dart';

const _basicGridOptions = FdcGridOptions(
  allowColumnSorting: true,
  allowColumnReordering: true,
);
const _basicRowIndicator = FdcGridRowIndicator(visible: true);

const _filterGridOptions = FdcGridOptions(
  allowColumnSorting: true,
  allowColumnReordering: true,
);
const _filterRowIndicator = FdcGridRowIndicator(visible: true);

const _zeroDebounceHeader = FdcGridHeader(
  height: 32,
  filters: FdcGridHeaderFilters(
    visible: true,
    options: FdcGridFilterOptions(debounceDuration: Duration.zero),
  ),
);

const _hiddenZeroDebounceHeader = FdcGridHeader(
  height: 32,
  filters: FdcGridHeaderFilters(
    visible: true,
    initiallyVisible: false,
    options: FdcGridFilterOptions(debounceDuration: Duration.zero),
  ),
);

Finder _headerRangeFilterTextFields() {
  return find.byWidgetPredicate((widget) {
    if (widget is! TextField) {
      return false;
    }
    return widget.focusNode?.debugLabel?.contains(
          'FdcGrid header range filter',
        ) ==
        true;
  });
}

class _ReadOnlyMemoryDataAdapter extends FdcMemoryDataAdapter {
  _ReadOnlyMemoryDataAdapter({required super.rows});

  @override
  bool get readOnly => true;
}

class _BlockedLoadWaiter {
  _BlockedLoadWaiter(this.count, this.completer);

  final int count;
  final Completer<void> completer;
}

class _EmptyFilteredPagedSummaryAdapter extends FdcDataAdapter {
  _EmptyFilteredPagedSummaryAdapter()
    : super(
        readOnly: true,
        capabilities: const FdcDataAdapterCapabilities(
          filtering: true,
          paging: true,
          totalCount: true,
          aggregates: true,
        ),
      );

  Completer<FdcDataAggregateResult>? filteredAggregateGate;

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    if (request.filters.isNotEmpty) {
      return const FdcDataLoadResult(
        rows: <Map<String, Object?>>[],
        totalCount: 0,
      );
    }
    return const FdcDataLoadResult(
      rows: <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'status': 'open', 'amount': '100.00'},
        <String, Object?>{'id': 2, 'status': 'open', 'amount': '200.00'},
      ],
      totalCount: 2,
    );
  }

  @override
  Future<FdcDataAggregateResult> aggregate(
    FdcDataAggregateRequest request,
  ) async {
    if (request.filters.isNotEmpty) {
      final gate = filteredAggregateGate;
      if (gate != null) {
        return gate.future;
      }
      return _aggregateResult('0.00');
    }
    return _aggregateResult('300.00');
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    return const FdcDataApplyResult.success();
  }

  static FdcDataAggregateResult _aggregateResult(String value) {
    return FdcDataAggregateResult(
      values: <FdcDataAggregateKey, Object?>{
        const FdcDataAggregateKey(
          fieldName: 'amount',
          aggregate: FdcAggregate.sum,
        ): FdcDecimal.parse(
          value,
        ),
      },
    );
  }
}

class _GatedFilterMemoryDataAdapter extends FdcMemoryDataAdapter {
  _GatedFilterMemoryDataAdapter({required super.rows});

  final List<FdcDataLoadRequest> loadRequests = <FdcDataLoadRequest>[];
  final List<Completer<void>> _blockedLoadGates = <Completer<void>>[];
  final List<_BlockedLoadWaiter> _blockedLoadWaiters = <_BlockedLoadWaiter>[];
  int _blockedLoadCount = 0;

  int get loadCount => loadRequests.length;

  int get blockedLoadCount => _blockedLoadCount;

  Future<void> waitForBlockedLoadCount(int count) {
    if (_blockedLoadCount >= count) {
      return Future<void>.value();
    }
    final completer = Completer<void>();
    _blockedLoadWaiters.add(_BlockedLoadWaiter(count, completer));
    return completer.future;
  }

  void completeNextBlockedLoad() {
    if (_blockedLoadGates.isEmpty) {
      throw StateError('No blocked load is waiting.');
    }
    final gate = _blockedLoadGates.removeAt(0);
    if (!gate.isCompleted) {
      gate.complete();
    }
  }

  void _markBlockedLoadStarted() {
    _blockedLoadCount++;
    for (var i = _blockedLoadWaiters.length - 1; i >= 0; i--) {
      final waiter = _blockedLoadWaiters[i];
      if (_blockedLoadCount >= waiter.count) {
        _blockedLoadWaiters.removeAt(i);
        if (!waiter.completer.isCompleted) {
          waiter.completer.complete();
        }
      }
    }
  }

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    loadRequests.add(request);
    if (request.filters.isNotEmpty) {
      final gate = Completer<void>();
      _blockedLoadGates.add(gate);
      _markBlockedLoadStarted();
      await gate.future;
    }
    return super.load(request);
  }
}

class _AsyncApplyMemoryAdapter implements IFdcDataAdapter {
  _AsyncApplyMemoryAdapter(this.rows);

  final List<Map<String, Object?>> rows;
  final List<FdcChangeSet> applyCalls = <FdcChangeSet>[];
  Completer<void>? applyGate;
  Completer<void>? applyStarted;

  @override
  bool get readOnly => false;

  @override
  FdcDataAdapterCapabilities get capabilities =>
      const FdcDataAdapterCapabilities.none();

  @override
  Future<FdcDataAggregateResult> aggregate(
    FdcDataAggregateRequest request,
  ) async {
    throw FdcDataAdapterException(
      operation: 'aggregate',
      code: 'unsupported_adapter_operation',
      message: '$runtimeType does not support aggregate queries.',
    );
  }

  @override
  String? validateStorageValue(FdcFieldDef field, Object? value) => null;

  @override
  FdcDataApplyError mapApplyException(
    FdcChangeSetEntry entry,
    Object error, {
    required FdcDataApplyOperation operation,
  }) {
    return FdcDataApplyError(
      recordId: entry.recordId,
      message: '${operation.name} mapped: $error',
      code: 'mapped_${operation.name}',
    );
  }

  @override
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request) async {
    return FdcDataLoadResult(rows: rows);
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    applyCalls.add(changes);
    final started = applyStarted;
    if (started != null && !started.isCompleted) {
      started.complete();
    }
    final gate = applyGate;
    if (gate != null) {
      await gate.future;
    }
    for (final update in changes.updates) {
      final id = update.originalValues['id'] ?? update.values['id'];
      final index = rows.indexWhere((row) => row['id'] == id);
      if (index >= 0) {
        rows[index] = <String, Object?>{...rows[index], ...update.values};
      }
    }
    return const FdcDataApplyResult.success();
  }
}

FdcGridToolbar _withToolbarVisibility(FdcGridToolbar toolbar, bool visible) {
  if (visible) {
    return toolbar;
  }

  if (!toolbar.visible) {
    return toolbar;
  }

  return FdcGridToolbar(
    visible: false,
    style: toolbar.style,
    items: toolbar.items,
  );
}

Widget _testHost({
  required FdcDataSet dataSet,
  required List<FdcGridColumn<dynamic>> columns,
  FdcGridOptions options = _basicGridOptions,
  FdcGridColumnPinning pinning = const FdcGridColumnPinning(enabled: true),
  FdcGridRowIndicator rowIndicator = _basicRowIndicator,
  FdcGridCellIndicator cellIndicator = const FdcGridCellIndicator(),
  FdcGridStyle style = const FdcGridStyle(),
  FdcGridHeader header = _hiddenZeroDebounceHeader,
  bool toolbarVisible = true,
  FdcGridToolbar toolbar = const FdcGridToolbar(),
  FdcGridSummary summary = const FdcGridSummary(),
  FdcGridStatusBar statusBar = const FdcGridStatusBar(),
  FdcFormatSettings? formatSettings,
  double width = 600,
  double height = 320,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: FdcGrid(
          dataSet: dataSet,
          columns: columns,
          options: options.copyWith(defaultColumnWidth: 140, rowHeight: 36),
          pinning: pinning,
          rowIndicator: rowIndicator,
          cellIndicator: cellIndicator,
          toolbar: _withToolbarVisibility(toolbar, toolbarVisible),
          header: header.copyWith(height: 32),
          summary: summary,
          statusBar: statusBar,
          style: style,
          formatSettings: formatSettings,
        ),
      ),
    ),
  );
}

Widget _buildToolbarTestItem(BuildContext context) {
  return const Text(
    'Custom toolbar item',
    key: ValueKey('fdc-toolbar-test-item'),
  );
}

Future<void> _pumpGrid(
  WidgetTester tester, {
  required FdcDataSet dataSet,
  required List<FdcGridColumn<dynamic>> columns,
  FdcGridOptions options = _basicGridOptions,
  FdcGridColumnPinning pinning = const FdcGridColumnPinning(enabled: true),
  FdcGridRowIndicator rowIndicator = _basicRowIndicator,
  FdcGridCellIndicator cellIndicator = const FdcGridCellIndicator(),
  FdcGridStyle style = const FdcGridStyle(),
  FdcGridHeader header = _hiddenZeroDebounceHeader,
  bool toolbarVisible = true,
  FdcGridToolbar toolbar = const FdcGridToolbar(),
  FdcGridSummary summary = const FdcGridSummary(),
  FdcGridStatusBar statusBar = const FdcGridStatusBar(),
  FdcFormatSettings? formatSettings,
  double width = 600,
  double height = 320,
}) async {
  await tester.pumpWidget(
    _testHost(
      dataSet: dataSet,
      columns: columns,
      options: options,
      pinning: pinning,
      rowIndicator: rowIndicator,
      cellIndicator: cellIndicator,
      style: style,
      header: header,
      toolbarVisible: toolbarVisible,
      toolbar: toolbar,
      summary: summary,
      statusBar: statusBar,
      formatSettings: formatSettings,
      width: width,
      height: height,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpBasicGrid(
  WidgetTester tester, {
  required FdcDataSet dataSet,
  required List<FdcGridColumn<dynamic>> columns,
  FdcGridStyle style = const FdcGridStyle(),
  FdcGridCellIndicator cellIndicator = const FdcGridCellIndicator(),
  FdcGridHeader header = _hiddenZeroDebounceHeader,
  double width = 600,
  double height = 320,
}) {
  return _pumpGrid(
    tester,
    dataSet: dataSet,
    columns: columns,
    toolbarVisible: false,
    style: style,
    cellIndicator: cellIndicator,
    header: header,
    width: width,
    height: height,
  );
}

Future<void> _pumpFilterGrid(
  WidgetTester tester, {
  required FdcDataSet dataSet,
  required List<FdcGridColumn<dynamic>> columns,
  FdcGridOptions options = _filterGridOptions,
  FdcGridRowIndicator rowIndicator = _filterRowIndicator,
  FdcGridCellIndicator cellIndicator = const FdcGridCellIndicator(),
  FdcGridStyle style = const FdcGridStyle(),
  FdcGridHeader header = _zeroDebounceHeader,
  double width = 600,
  double height = 320,
}) {
  return _pumpGrid(
    tester,
    dataSet: dataSet,
    columns: columns,
    options: options,
    rowIndicator: rowIndicator,
    cellIndicator: cellIndicator,
    style: style,
    header: header,
    width: width,
    height: height,
  );
}

Future<void> _pumpIndicatorGrid(
  WidgetTester tester, {
  required FdcDataSet dataSet,
  required List<FdcGridColumn<dynamic>> columns,
  bool headerFiltersVisible = false,
  bool showRowSelect = true,
  bool showRowNumbers = false,
  bool showRecordStatus = true,
  double width = 600,
  double height = 320,
}) {
  return _pumpGrid(
    tester,
    dataSet: dataSet,
    columns: columns,
    rowIndicator: FdcGridRowIndicator(
      visible: true,
      options: FdcGridRowIndicatorOptions(
        showRowSelect: showRowSelect,
        showRowNumbers: showRowNumbers,
        showRecordStatus: showRecordStatus,
      ),
    ),
    header: headerFiltersVisible
        ? _zeroDebounceHeader
        : _hiddenZeroDebounceHeader,
    width: width,
    height: height,
  );
}

FdcDataSet _peopleDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name', label: 'Name', required: true),
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

FdcDataSet _readOnlyPeopleDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name', label: 'Name', required: true),
    ],

    adapter: _ReadOnlyMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha'},
        {'id': 2, 'name': 'Beta'},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

FdcDataSet _wideSelectionDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'c1'),
      FdcStringField(size: 255, name: 'c2'),
      FdcStringField(size: 255, name: 'c3'),
      FdcStringField(size: 255, name: 'c4'),
      FdcStringField(size: 255, name: 'c5'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {
          'c1': 'Alpha',
          'c2': 'Alpha two',
          'c3': 'Alpha three',
          'c4': 'Alpha four',
          'c5': 'Alpha five',
        },
        {
          'c1': 'Beta',
          'c2': 'Beta two',
          'c3': 'Beta three',
          'c4': 'Beta four',
          'c5': 'Beta five',
        },
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

FdcDataSet _wideTallTextDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'c1'),
      FdcStringField(size: 255, name: 'c2'),
      FdcStringField(size: 255, name: 'c3'),
      FdcStringField(size: 255, name: 'c4'),
      FdcStringField(size: 255, name: 'c5'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: List<Map<String, Object?>>.generate(32, (index) {
        final rowNo = index + 1;
        return {
          'c1': 'R$rowNo c1',
          'c2': 'R$rowNo c2',
          'c3': 'R$rowNo c3',
          'c4': 'R$rowNo c4',
          'c5': 'R$rowNo c5',
        };
      }),
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

FdcDataSet _wideTallBooleanDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'c1'),
      FdcStringField(size: 255, name: 'c2'),
      FdcStringField(size: 255, name: 'c3'),
      FdcBooleanField(name: 'flag'),
      FdcStringField(size: 255, name: 'c5'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: List<Map<String, Object?>>.generate(32, (index) {
        final rowNo = index + 1;
        return {
          'c1': 'R$rowNo c1',
          'c2': 'R$rowNo c2',
          'c3': 'R$rowNo c3',
          'flag': index.isEven,
          'c5': 'R$rowNo c5',
        };
      }),
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

FdcDataSet _wideTallDateDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'c1'),
      FdcStringField(size: 255, name: 'c2'),
      FdcStringField(size: 255, name: 'c3'),
      FdcDateField(name: 'date'),
      FdcStringField(size: 255, name: 'c5'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: List<Map<String, Object?>>.generate(32, (index) {
        final rowNo = index + 1;
        return {
          'c1': 'R$rowNo c1',
          'c2': 'R$rowNo c2',
          'c3': 'R$rowNo c3',
          'date': DateTime(2026, 1, (index % 28) + 1),
          'c5': 'R$rowNo c5',
        };
      }),
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

FdcDataSet _peopleStatusDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name', label: 'Name'),
      FdcStringField(size: 255, name: 'status', label: 'Status'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha', 'status': 'Active'},
        {'id': 2, 'name': 'Beta', 'status': 'Inactive'},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

FdcDataSet _quantityDataSet({FdcDataSetValidationError? onValidationError}) {
  final dataSet = FdcDataSet(
    onValidationError: onValidationError,
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcIntegerField(
        name: 'quantity',
        label: 'Quantity',
        minValue: 1,
        maxValue: 10,
      ),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'quantity': 5},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

Object? _constantId(FdcCalculatedFieldContext context) => 1;

FdcDataSet _calculatedDataSet() {
  final dataSet = FdcDataSet(
    fields: <FdcFieldDef>[
      const FdcIntegerField(name: 'quantity'),
      const FdcDecimalField(name: 'price', precision: 12, scale: 2),
      FdcDecimalField(
        name: 'total',
        precision: 12,
        scale: 2,
        calculatedValue: (context) {
          final quantity = context.numValue('quantity') ?? 0;
          final price = context.numValue('price') ?? 0;
          return quantity * price;
        },
      ),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'quantity': 5, 'price': 10},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

Future<void> _pressCtrlDelete(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.delete);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

bool _isSummaryCellPositionWidget(Widget widget) {
  final key = widget.key;
  if (key is! ValueKey<Object?>) {
    return false;
  }
  final value = key.value.toString();
  return (widget is Positioned || widget is AnimatedPositioned) &&
      value.startsWith('fdc-grid-summary-cell-') &&
      !value.endsWith('-left-separator') &&
      !value.endsWith('-right-separator');
}
