import 'fdc_grid_ux_test_exports.dart';

export 'fdc_grid_ux_test_exports.dart';

const uxBasicGridOptions = FdcGridOptions(
  allowColumnSorting: true,
  allowColumnReordering: true,
);
const uxBasicRowIndicator = FdcGridRowIndicator(visible: true);

const uxFilterGridOptions = FdcGridOptions(
  allowColumnSorting: true,
  allowColumnReordering: true,
);
const uxFilterRowIndicator = FdcGridRowIndicator(visible: true);

const uxZeroDebounceHeader = FdcGridHeader(
  height: 32,
  filters: FdcGridHeaderFilters(
    visible: true,
    options: FdcGridFilterOptions(debounceDuration: Duration.zero),
  ),
);

const uxHiddenZeroDebounceHeader = FdcGridHeader(
  height: 32,
  filters: FdcGridHeaderFilters(
    visible: true,
    initiallyVisible: false,
    options: FdcGridFilterOptions(debounceDuration: Duration.zero),
  ),
);

Finder uxHeaderRangeFilterTextFields() {
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

class UxReadOnlyMemoryDataAdapter extends FdcMemoryDataAdapter {
  UxReadOnlyMemoryDataAdapter({required super.rows});

  @override
  bool get readOnly => true;
}

class UxBlockedLoadWaiter {
  UxBlockedLoadWaiter(this.count, this.completer);

  final int count;
  final Completer<void> completer;
}

class UxEmptyFilteredPagedSummaryAdapter extends FdcDataAdapter {
  UxEmptyFilteredPagedSummaryAdapter()
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
      return uxAggregateResult('0.00');
    }
    return uxAggregateResult('300.00');
  }

  @override
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes) async {
    return const FdcDataApplyResult.success();
  }

  static FdcDataAggregateResult uxAggregateResult(String value) {
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

class UxGatedFilterMemoryDataAdapter extends FdcMemoryDataAdapter {
  UxGatedFilterMemoryDataAdapter({required super.rows});

  final List<FdcDataLoadRequest> loadRequests = <FdcDataLoadRequest>[];
  final List<Completer<void>> uxBlockedLoadGates = <Completer<void>>[];
  final List<UxBlockedLoadWaiter> uxBlockedLoadWaiters =
      <UxBlockedLoadWaiter>[];
  int uxBlockedLoadCount = 0;

  int get loadCount => loadRequests.length;

  int get blockedLoadCount => uxBlockedLoadCount;

  Future<void> waitForBlockedLoadCount(int count) {
    if (uxBlockedLoadCount >= count) {
      return Future<void>.value();
    }
    final completer = Completer<void>();
    uxBlockedLoadWaiters.add(UxBlockedLoadWaiter(count, completer));
    return completer.future;
  }

  void completeNextBlockedLoad() {
    if (uxBlockedLoadGates.isEmpty) {
      throw StateError('No blocked load is waiting.');
    }
    final gate = uxBlockedLoadGates.removeAt(0);
    if (!gate.isCompleted) {
      gate.complete();
    }
  }

  void uxMarkBlockedLoadStarted() {
    uxBlockedLoadCount++;
    for (var i = uxBlockedLoadWaiters.length - 1; i >= 0; i--) {
      final waiter = uxBlockedLoadWaiters[i];
      if (uxBlockedLoadCount >= waiter.count) {
        uxBlockedLoadWaiters.removeAt(i);
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
      uxBlockedLoadGates.add(gate);
      uxMarkBlockedLoadStarted();
      await gate.future;
    }
    return super.load(request);
  }
}

class UxAsyncApplyMemoryAdapter implements IFdcDataAdapter {
  UxAsyncApplyMemoryAdapter(this.rows);

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

FdcGridToolbar uxWithToolbarVisibility(FdcGridToolbar toolbar, bool visible) {
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

Widget uxTestHost({
  required FdcDataSet dataSet,
  required List<FdcGridColumn<dynamic>> columns,
  FdcGridOptions options = uxBasicGridOptions,
  FdcGridColumnPinning pinning = const FdcGridColumnPinning(enabled: true),
  FdcGridRowIndicator rowIndicator = uxBasicRowIndicator,
  FdcGridCellIndicator cellIndicator = const FdcGridCellIndicator(),
  FdcGridStyle style = const FdcGridStyle(),
  FdcGridHeader header = uxHiddenZeroDebounceHeader,
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
          toolbar: uxWithToolbarVisibility(toolbar, toolbarVisible),
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

Widget uxBuildToolbarTestItem(BuildContext context) {
  return const Text(
    'Custom toolbar item',
    key: ValueKey('fdc-toolbar-test-item'),
  );
}

Future<void> uxPumpPendingFrames(
  WidgetTester tester, {
  int maxFrames = 120,
}) async {
  for (var frame = 0; frame < maxFrames; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (!tester.binding.hasScheduledFrame) {
      return;
    }
  }

  throw TestFailure(
    'The grid UX did not become idle within $maxFrames frames. '
    'This usually indicates a repeating animation, an unresolved async '
    'operation, or a test that should wait for a more specific condition.',
  );
}

Future<void> uxPumpGrid(
  WidgetTester tester, {
  required FdcDataSet dataSet,
  required List<FdcGridColumn<dynamic>> columns,
  FdcGridOptions options = uxBasicGridOptions,
  FdcGridColumnPinning pinning = const FdcGridColumnPinning(enabled: true),
  FdcGridRowIndicator rowIndicator = uxBasicRowIndicator,
  FdcGridCellIndicator cellIndicator = const FdcGridCellIndicator(),
  FdcGridStyle style = const FdcGridStyle(),
  FdcGridHeader header = uxHiddenZeroDebounceHeader,
  bool toolbarVisible = true,
  FdcGridToolbar toolbar = const FdcGridToolbar(),
  FdcGridSummary summary = const FdcGridSummary(),
  FdcGridStatusBar statusBar = const FdcGridStatusBar(),
  FdcFormatSettings? formatSettings,
  double width = 600,
  double height = 320,
}) async {
  await tester.pumpWidget(
    uxTestHost(
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
  await uxPumpPendingFrames(tester);
}

Future<void> uxPumpBasicGrid(
  WidgetTester tester, {
  required FdcDataSet dataSet,
  required List<FdcGridColumn<dynamic>> columns,
  FdcGridStyle style = const FdcGridStyle(),
  FdcGridCellIndicator cellIndicator = const FdcGridCellIndicator(),
  FdcGridHeader header = uxHiddenZeroDebounceHeader,
  double width = 600,
  double height = 320,
}) {
  return uxPumpGrid(
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

Future<void> uxPumpFilterGrid(
  WidgetTester tester, {
  required FdcDataSet dataSet,
  required List<FdcGridColumn<dynamic>> columns,
  FdcGridOptions options = uxFilterGridOptions,
  FdcGridRowIndicator rowIndicator = uxFilterRowIndicator,
  FdcGridCellIndicator cellIndicator = const FdcGridCellIndicator(),
  FdcGridStyle style = const FdcGridStyle(),
  FdcGridHeader header = uxZeroDebounceHeader,
  double width = 600,
  double height = 320,
}) {
  return uxPumpGrid(
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

Future<void> uxPumpIndicatorGrid(
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
  return uxPumpGrid(
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
        ? uxZeroDebounceHeader
        : uxHiddenZeroDebounceHeader,
    width: width,
    height: height,
  );
}

FdcDataSet uxPeopleDataSet() {
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

FdcDataSet uxReadOnlyPeopleDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcIntegerField(name: 'id'),
      FdcStringField(size: 255, name: 'name', label: 'Name', required: true),
    ],

    adapter: UxReadOnlyMemoryDataAdapter(
      rows: const <Map<String, Object?>>[
        {'id': 1, 'name': 'Alpha'},
        {'id': 2, 'name': 'Beta'},
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

FdcDataSet uxWideSelectionDataSet() {
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

FdcDataSet uxWideTallTextDataSet() {
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

FdcDataSet uxWideTallBooleanDataSet() {
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

FdcDataSet uxWideTallDateDataSet() {
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

FdcDataSet uxPeopleStatusDataSet() {
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

FdcDataSet uxQuantityDataSet({FdcDataSetValidationError? onValidationError}) {
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

Object? uxConstantId(FdcCalculatedFieldContext context) => 1;

FdcDataSet uxCalculatedDataSet() {
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

Future<void> uxPressCtrlDelete(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.delete);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await uxPumpPendingFrames(tester);
}

bool uxIsSummaryCellPositionWidget(Widget widget) {
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
