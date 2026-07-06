// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

class _FdcGridState extends State<FdcGridHost> {
  // Flutter-hosted runtime state. Runtime services and transient UI state are
  // grouped behind `_FdcGridRuntimeController`; this class keeps widget
  // lifecycle, callbacks, focus state, caches, and compatibility accessors.
  // Remaining direct fields are intentionally host-owned: dataset row-source
  // wiring, format/theme snapshots, column identity/cache maps, Flutter
  // focus/notifier/callback handles, and rebuild coordination.
  late IFdcGridRowSource _rows;
  late List<Object?> _columnDefinitionsSignature;
  late List<Object?> _columnGroupsSignature;
  bool _updatingDataSetFromGrid = false;

  // Row-number width is compact when the dataset is unfiltered, but once a
  // filter/search session is active it must not shrink to the smaller visible
  // result count. Shrinking the leading indicator region moves every grid band
  // horizontally and produces a visible layout jump.
  int? _rowIndicatorWidthAnchorRowCount;

  // Async/paged filter and search clearing can briefly report an unnarrowed
  // view while totalCount still contains the previous narrowed result. Keep
  // the anchor through that handoff so the leading row-indicator band does not
  // shrink for one frame and then expand again when the refreshed total arrives.
  bool _holdRowIndicatorWidthUntilCountRestores = false;

  // Header/menu overlays can transiently detach or relayout the horizontal
  // body scrollable before the selected menu action runs. Keep the pre-open
  // origin as a fallback so view actions such as Clear filters do not snapshot
  // a temporary zero offset.
  double? _headerMenuHorizontalOffsetToPreserve;

  int? _pendingDeleteRestoreRowIndex;
  int? _pendingDeleteRestoreColumnIndex;
  final Set<int> _expandedDetailRecordIds = <int>{};
  final Set<int> _visibleDetailRecordIds = <int>{};
  final Map<int, double> _detailRowMeasuredHeights = <int, double>{};
  int _detailRevealGeneration = 0;
  late FdcGridRangeSelectionSession _rangeSelectionSession;
  FdcGridCellRef? _lookupCellInProgress;

  List<int> _expandedDetailRowIndicesCache = const <int>[];
  bool _expandedDetailRowIndicesDirty = true;
  Timer? _layoutAutoSaveTimer;
  bool _suppressLayoutAutoSave = false;
  int _layoutPersistenceGeneration = 0;
  late FdcDataSetState _lastObservedDataSetState;
  late int _lastObservedDataSetRecordCount;
  final _FdcGridRuntimeController _runtime = _FdcGridRuntimeController();
  late final FdcGridRangeSelectionHost _rangeSelectionHost;

  _FdcGridUiState get _ui => _runtime.ui;

  Map<FdcColumnIdentity, Object?> get _headerFilterValues =>
      _ui.header.filter.values;

  Map<FdcColumnIdentity, FdcFilterOperator> get _headerFilterOperators =>
      _ui.header.filter.operators;

  Map<FdcColumnIdentity, _FdcGridHeaderFilterRangeEditSnapshot>
  get _headerFilterRangeEditSnapshots => _ui.header.filter.rangeEditSnapshots;

  Map<FdcColumnIdentity, FocusNode> get _headerFilterFocusNodes =>
      _ui.header.filter.focusNodes;

  Timer? get _headerFilterDebounceTimer => _ui.header.filter.debounceTimer;

  set _headerFilterDebounceTimer(Timer? value) {
    _ui.header.filter.debounceTimer = value;
  }

  int get _headerFilterRefreshGeneration => _ui.header.filter.refreshGeneration;

  set _headerFilterRefreshGeneration(int value) {
    _ui.header.filter.refreshGeneration = value;
  }

  bool? get _rowSelectionFilter => _ui.header.filter.rowSelectionFilter;

  set _rowSelectionFilter(bool? value) {
    _ui.header.filter.rowSelectionFilter = value;
  }

  String? get _lastAppliedHeaderFilterSignature =>
      _ui.header.filter.lastAppliedSignature;

  set _lastAppliedHeaderFilterSignature(String? value) {
    _ui.header.filter.lastAppliedSignature = value;
  }

  bool get _headerFilterApplyInFlight => _ui.header.filter.applyInFlight;

  set _headerFilterApplyInFlight(bool value) {
    _ui.header.filter.applyInFlight = value;
  }

  bool get _headerFilterApplyQueued => _ui.header.filter.applyQueued;

  set _headerFilterApplyQueued(bool value) {
    _ui.header.filter.applyQueued = value;
  }

  String? get _headerFilterInFlightSignature =>
      _ui.header.filter.inFlightSignature;

  set _headerFilterInFlightSignature(String? value) {
    _ui.header.filter.inFlightSignature = value;
  }

  FdcFormatSettings _formatSettings = const FdcFormatSettings();
  FdcTranslations _translations = const FdcTranslations();
  late FdcValueFormatter _valueFormatter;
  int get _headerFilterResetGeneration => _ui.header.filter.resetGeneration;

  set _headerFilterResetGeneration(int value) {
    _ui.header.filter.resetGeneration = value;
  }

  int get _headerFilterRangeAutoOpenGeneration =>
      _ui.header.filter.rangeAutoOpenGeneration;

  set _headerFilterRangeAutoOpenGeneration(int value) {
    _ui.header.filter.rangeAutoOpenGeneration = value;
  }

  FdcColumnIdentity? get _rangeAutoOpenColumnId =>
      _ui.header.filter.rangeAutoOpenRuntimeColumnId;

  set _rangeAutoOpenColumnId(FdcColumnIdentity? value) {
    _ui.header.filter.rangeAutoOpenRuntimeColumnId = value;
  }

  FdcGridScrollManager get _scroll => _runtime.domains.scroll.scroll;

  FdcGridScrollCoordinator get _scrollCoordinator =>
      _runtime.domains.scroll.coordinator;

  FdcGridColumnSizingManager get _columnSizing =>
      _runtime.domains.columns.sizing;

  FdcGridTypingManager get _typing => _runtime.domains.editing.typing;

  FdcGridCellManager get _cells => _runtime.domains.cells.cells;

  FdcGridNavigationManager get _navigation =>
      _runtime.domains.navigation.navigation;

  FdcGridStyleManager get _styles => _runtime.domains.core.styles;
  late final FocusNode _gridFocusNode;
  int _nextGridColumnIdentityValue = 1;
  // Column identity belongs to this concrete grid instance and is intentionally
  // separate from the public immutable column definition. The identity is keyed
  // by a stable semantic column key rather than by source index, so runtime
  // state follows the same column across parent rebuilds, inserts, removes and
  // reorders.
  final Map<FdcColumnIdentityKey, FdcColumnIdentity> _columnIdentitiesByKey =
      <FdcColumnIdentityKey, FdcColumnIdentity>{};
  final Map<FdcColumnIdentity, bool> _runtimeColumnVisibilityOverrides =
      <FdcColumnIdentity, bool>{};
  final Map<FdcColumnIdentity, FdcGridColumnPin> _runtimeColumnPinOverrides =
      <FdcColumnIdentity, FdcGridColumnPin>{};
  final Map<FdcColumnIdentity, FdcAggregate?>
  _runtimeSummaryAggregateOverrides = <FdcColumnIdentity, FdcAggregate?>{};
  final Map<_FdcGridSummaryAggregateCacheKey, Object?>
  _summaryAggregateValueCache = <_FdcGridSummaryAggregateCacheKey, Object?>{};
  final Set<_FdcGridSummaryAggregateCacheKey> _summaryAggregatePending =
      <_FdcGridSummaryAggregateCacheKey>{};
  final Map<FdcColumnIdentity, String> _summaryDisplayedValueCache =
      <FdcColumnIdentity, String>{};
  final Map<_FdcGridSummaryDisplayCacheKey, String>
  _summaryDisplayedValueSemanticCache =
      <_FdcGridSummaryDisplayCacheKey, String>{};
  bool _summaryAggregateLoadDeferred = false;
  String? _lastSummaryAggregateQuerySignature;
  final List<FdcColumnIdentity> _runtimeColumnOrderIds = <FdcColumnIdentity>[];
  bool _hasUserColumnOrderOverride = false;
  late List<FdcGridColumn<dynamic>> _visibleColumnsCache;
  late List<FdcColumnIdentity> _visibleRuntimeColumnIdsCache;
  late List<FdcColumnIdentity> _declarativeRuntimeColumnIdsCache;
  late FdcGridColumnBands _columnBandsCache;
  TextDirection _textDirection = TextDirection.ltr;
  bool _columnWidthsDirty = true;
  double? _lastColumnWidthViewport;
  bool get _handlingGridMove => _ui.navigation.handlingGridMove;

  set _handlingGridMove(bool value) {
    _ui.navigation.handlingGridMove = value;
  }

  bool get _showingGridOperationErrorDialog =>
      _ui.data.operation.showingGridOperationErrorDialog;

  set _showingGridOperationErrorDialog(bool value) {
    _ui.data.operation.showingGridOperationErrorDialog = value;
  }

  Future<void>? get _gridOperationErrorDialogFuture =>
      _ui.data.operation.gridOperationErrorDialogFuture;

  set _gridOperationErrorDialogFuture(Future<void>? value) {
    _ui.data.operation.gridOperationErrorDialogFuture = value;
  }

  bool get _focusActiveEditorAfterGridErrorDialog =>
      _ui.data.operation.focusActiveEditorAfterGridErrorDialog;

  set _focusActiveEditorAfterGridErrorDialog(bool value) {
    _ui.data.operation.focusActiveEditorAfterGridErrorDialog = value;
  }

  bool get _showingDeleteConfirmDialog =>
      _ui.data.operation.showingDeleteConfirmDialog;

  set _showingDeleteConfirmDialog(bool value) {
    _ui.data.operation.showingDeleteConfirmDialog = value;
  }

  bool get _pendingAppendAfterImmediatePost =>
      _ui.data.operation.pendingAppendAfterImmediatePost;

  set _pendingAppendAfterImmediatePost(bool value) {
    _ui.data.operation.pendingAppendAfterImmediatePost = value;
  }

  bool get _pendingAppendUsesTabOrder =>
      _ui.data.operation.pendingAppendUsesTabOrder;

  set _pendingAppendUsesTabOrder(bool value) {
    _ui.data.operation.pendingAppendUsesTabOrder = value;
  }

  FdcGridCellRef? get _pendingCellMoveAfterImmediatePost =>
      _ui.data.operation.pendingCellMoveAfterImmediatePost;

  set _pendingCellMoveAfterImmediatePost(FdcGridCellRef? value) {
    _ui.data.operation.pendingCellMoveAfterImmediatePost = value;
  }

  bool get _pendingCellMoveEditIfPossible =>
      _ui.data.operation.pendingCellMoveEditIfPossible;

  set _pendingCellMoveEditIfPossible(bool value) {
    _ui.data.operation.pendingCellMoveEditIfPossible = value;
  }

  bool get _preferLeadingColumnForPendingMove =>
      _ui.data.operation.preferLeadingColumnForPendingMove;

  set _preferLeadingColumnForPendingMove(bool value) {
    _ui.data.operation.preferLeadingColumnForPendingMove = value;
  }

  FdcGridFocusChangeReason get _pendingCellMoveFocusReason =>
      _ui.data.operation.pendingCellMoveFocusReason;

  set _pendingCellMoveFocusReason(FdcGridFocusChangeReason value) {
    _ui.data.operation.pendingCellMoveFocusReason = value;
  }

  bool get _suppressRevealForPendingMove =>
      _ui.data.operation.suppressRevealForPendingMove;

  set _suppressRevealForPendingMove(bool value) {
    _ui.data.operation.suppressRevealForPendingMove = value;
  }

  String? get _lastShownGridOperationErrorSignature =>
      _ui.data.operation.lastShownGridOperationErrorSignature;

  set _lastShownGridOperationErrorSignature(String? value) {
    _ui.data.operation.lastShownGridOperationErrorSignature = value;
  }

  String? get _pendingEditText => _ui.cells.interaction.pendingEditText;

  set _pendingEditText(String? value) {
    _ui.cells.interaction.pendingEditText = value;
  }

  FdcGridCellRef? get _pendingEditCell => _ui.cells.interaction.pendingEditCell;

  set _pendingEditCell(FdcGridCellRef? value) {
    _ui.cells.interaction.pendingEditCell = value;
  }

  bool get _suppressKeyboardColumnReveal =>
      _ui.cells.interaction.suppressKeyboardColumnReveal;

  set _suppressKeyboardColumnReveal(bool value) {
    _ui.cells.interaction.suppressKeyboardColumnReveal = value;
  }

  int? get _selectedRowIndex => _ui.cells.interaction.selectedRowIndex;

  set _selectedRowIndex(int? value) {
    _ui.cells.interaction.selectedRowIndex = value;
  }

  FdcGridCellRef? get _selectedCell => _ui.cells.interaction.selectedCell;

  set _selectedCell(FdcGridCellRef? value) {
    _ui.cells.interaction.selectedCell = value;
  }

  FdcGridCellRef? get _editingCell => _ui.cells.interaction.editingCell;

  set _editingCell(FdcGridCellRef? value) {
    _ui.cells.interaction.editingCell = value;
  }

  FdcGridCellRef? get _editAtEndCell => _ui.cells.interaction.editAtEndCell;

  set _editAtEndCell(FdcGridCellRef? value) {
    _ui.cells.interaction.editAtEndCell = value;
  }

  FdcGridCellRef? get _editingOriginalCell =>
      _ui.cells.interaction.editingOriginalCell;

  set _editingOriginalCell(FdcGridCellRef? value) {
    _ui.cells.interaction.editingOriginalCell = value;
  }

  Object? get _editingOriginalValue =>
      _ui.cells.interaction.editingOriginalValue;

  set _editingOriginalValue(Object? value) {
    _ui.cells.interaction.editingOriginalValue = value;
  }

  bool get _hasEditingOriginalValue =>
      _ui.cells.interaction.hasEditingOriginalValue;

  set _hasEditingOriginalValue(bool value) {
    _ui.cells.interaction.hasEditingOriginalValue = value;
  }

  bool get _showColumnFilters => _ui.header.filter.showColumnFilters;

  set _showColumnFilters(bool value) {
    _ui.header.filter.showColumnFilters = value;
  }

  int get _visibleRowCount => _ui.scroll.viewport.visibleRowCount;

  set _visibleRowCount(int value) {
    _ui.scroll.viewport.visibleRowCount = value;
  }

  double get _visibleRowsViewportHeight =>
      _ui.scroll.viewport.visibleRowsViewportHeight;

  set _visibleRowsViewportHeight(double value) {
    _ui.scroll.viewport.visibleRowsViewportHeight = value;
  }

  int? get _pendingScrollbarSelectionRowIndex =>
      _ui.scroll.viewport.pendingScrollbarSelectionRowIndex;

  set _pendingScrollbarSelectionRowIndex(int? value) {
    _ui.scroll.viewport.pendingScrollbarSelectionRowIndex = value;
  }

  double get _bodyVerticalDragDistance =>
      _ui.scroll.viewport.bodyVerticalDragDistance;

  set _bodyVerticalDragDistance(double value) {
    _ui.scroll.viewport.bodyVerticalDragDistance = value;
  }

  double get _bodyVerticalDragStartOffset =>
      _ui.scroll.viewport.bodyVerticalDragStartOffset;

  set _bodyVerticalDragStartOffset(double value) {
    _ui.scroll.viewport.bodyVerticalDragStartOffset = value;
  }

  int get _verticalSettleGeneration =>
      _ui.scroll.viewport.verticalSettleGeneration;

  set _verticalSettleGeneration(int value) {
    _ui.scroll.viewport.verticalSettleGeneration = value;
  }

  int get _verticalOffsetRestoreGeneration =>
      _ui.scroll.viewport.verticalOffsetRestoreGeneration;

  set _verticalOffsetRestoreGeneration(int value) {
    _ui.scroll.viewport.verticalOffsetRestoreGeneration = value;
  }

  int get _toolbarSearchGeneration => _ui.toolbarSearch.generation;

  set _toolbarSearchGeneration(int value) {
    _ui.toolbarSearch.generation = value;
  }

  FdcGridSortManager get _sort => _runtime.domains.header.sort;

  final Map<FdcGridCellBackgroundKey, Color?> _cellBackgroundColorCache =
      <FdcGridCellBackgroundKey, Color?>{};
  final Map<FdcColumnIdentity, FdcGridColumnCellTextStyles>
  _cellTextStyleCache = <FdcColumnIdentity, FdcGridColumnCellTextStyles>{};
  final Map<String, FdcGridFieldMetadata> _fieldMetadataCache =
      <String, FdcGridFieldMetadata>{};
  final Set<String> _unsupportedSummaryAggregateWarnings = <String>{};
  final Map<FdcColumnIdentity, FdcGridColumnCellRenderInfo>
  _columnCellRenderInfoCache =
      <FdcColumnIdentity, FdcGridColumnCellRenderInfo>{};
  int? get _draggingColumnIndex => _ui.header.interaction.draggingColumnIndex;

  set _draggingColumnIndex(int? value) {
    _ui.header.interaction.draggingColumnIndex = value;
  }

  void _blockLiveSwapTarget(FdcColumnIdentity runtimeColumnId) {
    _ui.header.interaction.blockLiveSwapTarget(
      runtimeColumnId,
      fdcGridColumnReorderRepeatSwapCooldown,
    );
  }

  void _clearLiveSwapTargetBlock() {
    _ui.header.interaction.clearLiveSwapTargetBlock();
  }

  FdcColumnIdentity? get _pendingSwapTargetColumnId =>
      _ui.header.interaction.pendingSwapTargetColumnId;

  set _pendingSwapTargetColumnId(FdcColumnIdentity? value) {
    _ui.header.interaction.pendingSwapTargetColumnId = value;
  }

  bool get _liveSwapLocked => _ui.header.interaction.liveSwapLocked;

  void _lockLiveSwapUntilAnimationEnds() {
    _ui.header.interaction.lockLiveSwap(
      fdcGridColumnReorderAnimationDuration,
      onUnlocked: _flushPendingLiveSwapHoverTarget,
    );
  }

  void _clearLiveSwapLock() {
    _ui.header.interaction.clearLiveSwapLock();
  }

  bool get _invalidColumnDropTargetHovering =>
      _ui.header.interaction.invalidColumnDropTargetHovering;

  set _invalidColumnDropTargetHovering(bool value) {
    _ui.header.interaction.invalidColumnDropTargetHovering = value;
  }

  ValueNotifier<bool> get _invalidDropTargetHoverNotifier =>
      _ui.header.interaction.invalidDropTargetHoverNotifier;

  bool get _headerHorizontalDragScrolling =>
      _ui.header.interaction.horizontalDragScrolling;

  set _headerHorizontalDragScrolling(bool value) {
    _ui.header.interaction.horizontalDragScrolling = value;
  }

  FdcColumnIdentity? get _resizingRuntimeColumnId =>
      _ui.columnResize.runtimeColumnId;

  set _resizingRuntimeColumnId(FdcColumnIdentity? value) {
    _ui.columnResize.runtimeColumnId = value;
  }

  double get _resizingColumnStartWidth => _ui.columnResize.columnStartWidth;

  set _resizingColumnStartWidth(double value) {
    _ui.columnResize.columnStartWidth = value;
  }

  double? get _resizingColumnDragStartGlobalX =>
      _ui.columnResize.dragStartGlobalX;

  set _resizingColumnDragStartGlobalX(double? value) {
    _ui.columnResize.dragStartGlobalX = value;
  }

  List<FdcColumnIdentity> get _resizingGroupRuntimeColumnIds =>
      _ui.columnResize.groupRuntimeColumnIds;

  set _resizingGroupRuntimeColumnIds(List<FdcColumnIdentity> value) {
    _ui.columnResize.groupRuntimeColumnIds = value;
  }

  List<double> get _resizingGroupStartWidths =>
      _ui.columnResize.groupStartWidths;

  set _resizingGroupStartWidths(List<double> value) {
    _ui.columnResize.groupStartWidths = value;
  }

  FdcGridCellRef? get _lastTappedCell => _ui.cells.interaction.lastTappedCell;

  set _lastTappedCell(FdcGridCellRef? value) {
    _ui.cells.interaction.lastTappedCell = value;
  }

  DateTime? get _lastCellTapTime => _ui.cells.interaction.lastCellTapTime;

  set _lastCellTapTime(DateTime? value) {
    _ui.cells.interaction.lastCellTapTime = value;
  }

  late final ValueNotifier<FdcGridInteractionState> _interactionState;
  late final FdcGridCellCallbacks _cellCallbacks;
  late final FdcGridHeaderCallbacks _headerCallbacks;
  late final FdcGridViewportCallbacks _viewportCallbacks;
  FdcGridThemeData _gridTheme = FdcGridThemes.light;
  FdcGridStyle _gridStyle = const FdcGridStyle();
  FdcGridHeaderStyle _headerStyle = FdcGridHeaderStyle.defaults;

  MouseCursor get _gridMouseCursor {
    return _resizingRuntimeColumnId == null
        ? MouseCursor.defer
        : SystemMouseCursors.resizeLeftRight;
  }

  bool get _columnFilteringAllowed {
    return widget.header.visible &&
        widget.header.filters.visible &&
        widget.options.allowColumnFiltering;
  }

  bool get _headerFiltersInitiallyVisible =>
      widget.header.filters.visible && widget.header.filters.initiallyVisible;

  FdcGridFilterOptions get _headerFilterOptions =>
      widget.header.filters.options;

  bool get _showsHeaderFilterRow {
    return _columnFilteringAllowed &&
        _showColumnFilters &&
        _visibleColumns.any((column) => column.filterEnabled);
  }

  double get _headerFilterControlHeight {
    return widget.header.filters.style?.height ??
        FdcGridHeaderMetrics.filterFieldControlHeight;
  }

  double get _headerFilterRowHeight {
    return FdcGridHeaderMetrics.filterRowHeightFor(_headerFilterControlHeight);
  }

  bool get _hasColumnGroups => widget.columnGroups.isNotEmpty;

  double get _columnGroupHeaderHeight {
    if (!_hasColumnGroups) {
      return 0.0;
    }
    return math.max(0.0, _headerStyle.groupHeight ?? 0.0);
  }

  double get _effectiveHeaderHeight {
    if (!widget.header.visible) {
      return 0.0;
    }
    return _columnGroupHeaderHeight +
        math.max(0.0, widget.header.height) +
        (_showsHeaderFilterRow ? _headerFilterRowHeight : 0);
  }

  void _applyGridState(VoidCallback fn) {
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _gridFocusNode = FocusNode(debugLabel: 'FdcGrid')
      ..addListener(_handleGridFocusChanged);
    _fdcGridKeyboardFocusRoots.add(_gridFocusNode);
    HardwareKeyboard.instance.addHandler(_handleGlobalRangeSelectionKeyEvent);
    _interactionState = ValueNotifier<FdcGridInteractionState>(
      const FdcGridInteractionState(),
    );
    _cellCallbacks = _createCellCallbacks();
    _headerCallbacks = _createHeaderCallbacks();
    _viewportCallbacks = _createViewportCallbacks();
    _valueFormatter = _createValueFormatter(_formatSettings);
    _showColumnFilters = _headerFiltersInitiallyVisible;
    widget.dataSet.addListener(_handleDataSetChanged);
    widget.dataSet.work.addListener(_handleDataSetWorkChanged);
    FdcDataSetInternal.addErrorListener(widget.dataSet, _handleDataSetError);
    FdcDataSetInternal.addFilterChangedListener(
      widget.dataSet,
      _handleDataSetFilterChanged,
    );
    _runtime.addVerticalScrollListener(_handleVerticalScrollControllerChanged);
    _rangeSelectionHost = _FdcGridRangeSelectionHostAdapter(this);
    _rangeSelectionSession = _createGridRangeSelectionSession();
    _rows = _rowsFromDataSet();
    _lastObservedDataSetState = widget.dataSet.state;
    _lastObservedDataSetRecordCount = widget.dataSet.recordCount;
    _columnDefinitionsSignature = _columnDefinitionsSignatureFor(
      widget.columns,
    );
    _columnGroupsSignature = _columnGroupsSignatureFor(widget.columnGroups);
    _refreshColumnCache();
    _attachGridLayoutStateFeature();
    _attachGridRangeSelectionFeature();
    _syncHeaderSortFromDataSet();
    _refreshRowsFromSource(
      notifyDataSet: false,
      applyFilters: _hasGridManagedFilterState,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleGridDependenciesChanged(context);
  }

  @override
  void didUpdateWidget(covariant FdcGridHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleGridWidgetUpdated(oldWidget);
  }

  @override
  void dispose() {
    _disposeGridRuntimeResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    widget.options.validate();
    widget.cellIndicator.validate();
    return _buildGridRuntime(context);
  }
}
