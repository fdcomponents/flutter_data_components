// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateHeaderFilterRuntime on _FdcGridState {
  double _headerFilterHorizontalOffsetSnapshot() {
    final menuOffset = _headerMenuHorizontalOffsetToPreserve;
    if (menuOffset != null &&
        menuOffset > 0 &&
        _scrollCoordinator.hasHorizontalScrollableRange) {
      return menuOffset;
    }

    return _scrollCoordinator.horizontalOffsetSnapshotForViewAction();
  }

  void _runFilterAction(VoidCallback action) {
    if (!_readyView()) {
      return;
    }

    final horizontalOffsetToPreserve = _headerFilterHorizontalOffsetSnapshot();
    final shouldPreserveHorizontalOffset =
        horizontalOffsetToPreserve > 0 &&
        _scrollCoordinator.hasHorizontalScrollableRange;

    if (shouldPreserveHorizontalOffset) {
      _scrollCoordinator.beginHorizontalOffsetRestore(
        horizontalOffsetToPreserve,
      );
    }

    try {
      action();
      _blurGrid();
    } finally {
      if (shouldPreserveHorizontalOffset) {
        _restoreHorizontalScrollOffsetNow(horizontalOffsetToPreserve);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _restoreHorizontalScrollOffsetNow(horizontalOffsetToPreserve);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _restoreHorizontalScrollOffsetNow(horizontalOffsetToPreserve);
            }
            _scrollCoordinator.endHorizontalOffsetRestore();
            _headerMenuHorizontalOffsetToPreserve = null;
          });
        });
      } else {
        _headerMenuHorizontalOffsetToPreserve = null;
      }
    }
  }

  bool _canOpenFilterMenu() {
    return widget.dataSet.isOpen &&
        _hasRowsOrActiveViewQueryState &&
        !FdcDataSetInternal.hasActiveEdit(widget.dataSet);
  }

  bool _openFilterMenu() {
    if (!_canOpenFilterMenu()) {
      _blurGrid();
      return false;
    }
    return _readyView();
  }

  void _toggleColumnFilters() {
    if (!_columnFilteringAllowed) {
      return;
    }

    final nextVisible = !_showColumnFilters;

    if (!nextVisible) {
      _hideColumnFilters();
      return;
    }

    // Showing the header filter row is a layout/UI action. It must defocus the
    // grid editor, but it must not force the active edit/insert row to post
    // because no data-view mutation happens yet.
    _blurGrid();
    _setGridState(() {
      _showColumnFilters = true;
      _markColumnWidthsDirty();
    });
    _notifyGridLayoutChanged();
  }

  void _hideColumnFilters() {
    final clearsAppliedFilters =
        _hasGridManagedFilterState || widget.dataSet.filter.active;

    if (clearsAppliedFilters) {
      unawaited(_hideColumnFiltersAndClearFilters());
      return;
    }

    // Hiding an empty filter row is only a layout/UI action. Do not trigger the
    // edit/post guard here so external cancel flows can still work naturally.
    _cancelHeaderFilterDebounce();
    _blurGrid();
    _setGridState(() {
      _showColumnFilters = false;
      _headerFilterValues.clear();
      _headerFilterOperators.clear();
      _headerFilterRangeEditSnapshots.clear();
      _rowSelectionFilter = null;
      _lastAppliedHeaderFilterSignature = _headerFilterSignature();
      _headerFilterResetGeneration++;
      _markColumnWidthsDirty();
    });

    _notifyGridLayoutChanged();
  }

  Future<void> _hideColumnFiltersAndClearFilters() async {
    if (!_readyView()) {
      return;
    }

    final horizontalOffsetToPreserve = _headerFilterHorizontalOffsetSnapshot();

    _cancelHeaderFilterDebounce();

    _setGridState(() {
      _showColumnFilters = false;
      _headerFilterValues.clear();
      _headerFilterOperators.clear();
      _headerFilterRangeEditSnapshots.clear();
      _rowSelectionFilter = null;
      _lastAppliedHeaderFilterSignature = _headerFilterSignature();
      _headerFilterResetGeneration++;
      _markColumnWidthsDirty();
    });
    _notifyGridLayoutChanged();

    var cleared = false;
    _updatingDataSetFromGrid = true;
    try {
      cleared = await widget.dataSet.filter.clear();
    } on Object catch (error, stackTrace) {
      unawaited(_handleDataSetPostError(error, stackTrace));
      return;
    } finally {
      _updatingDataSetFromGrid = false;
    }

    if (!mounted || !cleared) {
      return;
    }

    _setGridState(() {
      _refreshRowsFromDataSet(updateColumnWidths: false);
      _validateCellState();
    });
    _resetVerticalScrollToTopAfterLayout(
      reason: 'hide-column-filters-clear-filters',
      preserveHorizontalOffset: horizontalOffsetToPreserve,
    );
  }

  int? _headerFilterDecimalScaleOf(FdcGridColumn<dynamic> column) {
    return _fieldMetadata(column.fieldName).decimalScale;
  }

  int? _headerFilterDecimalPrecisionOf(FdcGridColumn<dynamic> column) {
    return _fieldMetadata(column.fieldName).decimalPrecision;
  }

  bool _isHeaderFilterActive(
    FdcGridColumn<dynamic> column, [
    FdcColumnIdentity? runtimeColumnId,
  ]) {
    runtimeColumnId ??= _runtimeColumnIdForColumn(column);
    if (runtimeColumnId == null) {
      return false;
    }

    final state = _headerFilterStateFor(column, runtimeColumnId);
    if (!state.hasState) {
      return false;
    }

    if (_operatorIgnoresValue(state.operator)) {
      return true;
    }

    if (state.operator == FdcFilterOperator.between &&
        state.value is FdcFilterRangeValue) {
      final range = state.value as FdcFilterRangeValue;
      return _parseHeaderFilterValue(
                column,
                range.from,
                runtimeColumnId: runtimeColumnId,
              ) !=
              null &&
          _parseHeaderFilterValue(
                column,
                range.to,
                runtimeColumnId: runtimeColumnId,
              ) !=
              null;
    }

    final preparedValue = _parseHeaderFilterValue(
      column,
      state.value,
      runtimeColumnId: runtimeColumnId,
    );
    return preparedValue != null;
  }

  FdcHeaderFilterState _headerFilterStateFor(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  ) {
    return FdcHeaderFilterState(
      runtimeColumnId: runtimeColumnId,
      operator: _headerFilterOperator(column, runtimeColumnId),
      hasValue: _headerFilterValues.containsKey(runtimeColumnId),
      hasOperator: _headerFilterOperators.containsKey(runtimeColumnId),
      value: _headerFilterValues[runtimeColumnId],
    );
  }

  bool _hasHeaderFilterStateForColumn(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  ) {
    return _headerFilterStateFor(column, runtimeColumnId).hasState;
  }

  bool get _hasHeaderFilterState {
    return FdcHeaderFilterStateSnapshot.hasAny(
      values: _headerFilterValues,
      operators: _headerFilterOperators,
    );
  }

  bool get _hasGridManagedFilterState {
    return _hasHeaderFilterState || _rowSelectionFilter != null;
  }

  int get _gridManagedFilterStateCount {
    final keys = <FdcColumnIdentity>{
      ..._headerFilterValues.keys,
      ..._headerFilterOperators.keys,
    };
    return keys.length + (_rowSelectionFilter == null ? 0 : 1);
  }

  void _clearHeaderFilterUiState() {
    _cancelHeaderFilterDebounce();
    if (!_hasHeaderFilterState) {
      _lastAppliedHeaderFilterSignature = _headerFilterSignature();
      return;
    }
    _headerFilterValues.clear();
    _headerFilterOperators.clear();
    _lastAppliedHeaderFilterSignature = _headerFilterSignature();
    _headerFilterResetGeneration++;
  }

  Color _filterIconColor(BuildContext context, {required bool active}) {
    final filterStyle = _headerFilterStyle(context);
    final colorScheme = Theme.of(context).colorScheme;
    if (active) {
      return filterStyle.activeFilterIconColor ??
          filterStyle.focusedBorderColor ??
          colorScheme.primary;
    }
    return filterStyle.filterIconColor ?? colorScheme.onSurfaceVariant;
  }

  FocusNode _headerFilterFocusNode(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  ) {
    return _headerFilterFocusNodes.putIfAbsent(runtimeColumnId, () {
      final focusNode = FocusNode(
        debugLabel: 'FdcGrid header filter ${column.fieldName}',
      );
      focusNode.addListener(() {
        if (!mounted) {
          return;
        }
        if (!focusNode.hasFocus) {
          _commitHeaderFilterTextDisplayValue(column, runtimeColumnId);
        }
        _applyGridState(_syncInteractionState);
      });
      return focusNode;
    });
  }

  void _focusHeaderFilterField(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  ) {
    if (!_readyView()) {
      return;
    }
    _headerFilterFocusNode(column, runtimeColumnId).requestFocus();
  }

  void _removeMissingHeaderFilterFocusNodes(
    Set<FdcColumnIdentity> runtimeColumnIds,
  ) {
    final missing = _headerFilterFocusNodes.keys
        .where((runtimeColumnId) => !runtimeColumnIds.contains(runtimeColumnId))
        .toList();
    for (final runtimeColumnId in missing) {
      _headerFilterFocusNodes.remove(runtimeColumnId)?.dispose();
    }
  }

  void _focusNextHeaderFilter(
    FdcColumnIdentity runtimeColumnId, {
    required bool forward,
  }) {
    final currentIndex = _visibleRuntimeColumnIdsCache.indexOf(runtimeColumnId);
    if (currentIndex == -1) {
      return;
    }

    final step = forward ? 1 : -1;
    for (
      var index = currentIndex + step;
      index >= 0 && index < _visibleColumns.length;
      index += step
    ) {
      final next = _visibleColumns[index];
      final nextRuntimeColumnId = _runtimeColumnIdAt(index);
      if (nextRuntimeColumnId == null ||
          !_isHeaderFilterColumnFocusable(next, nextRuntimeColumnId)) {
        continue;
      }
      _scrollColumnIntoView(index);
      _headerFilterFocusNode(next, nextRuntimeColumnId).requestFocus();
      return;
    }
  }

  void _focusGridCellFromHeaderFilter(FdcColumnIdentity runtimeColumnId) {
    final columnIndex = _visibleRuntimeColumnIdsCache.indexOf(runtimeColumnId);
    if (columnIndex == -1 || _rows.isEmpty) {
      return;
    }

    _activateCell(
      _cellRef(_firstVisibleRowIndex(), columnIndex),
      editIfPossible: false,
    );
  }

  int _firstVisibleRowIndex() {
    if (_rows.isEmpty || widget.options.resolvedRowHeight <= 0) {
      return 0;
    }
    if (!_scrollCoordinator.hasVerticalClients) {
      return 0;
    }

    final rowIndex =
        (_scrollCoordinator.currentVerticalOffset /
                widget.options.resolvedRowHeight)
            .floor()
            .clamp(0, _rows.length - 1);
    return rowIndex.toInt();
  }

  void _setRowSelectionFilter(bool? selected) {
    final horizontalOffsetToPreserve = _headerFilterHorizontalOffsetSnapshot();

    if (!_readyView()) {
      return;
    }
    _cancelHeaderFilterDebounce();

    if (_rowSelectionFilter != selected) {
      _setGridState(() {
        _rowSelectionFilter = selected;
        _lastAppliedHeaderFilterSignature = _headerFilterSignature();
      });
    }

    unawaited(
      _refreshRowsFromSourceAsync(updateColumnWidths: false).then((_) {
        if (!mounted) {
          return;
        }
        _setGridState(() {
          _validateCellState();
        });
        _resetVerticalScrollToTopAfterLayout(
          reason: 'row-selection-filter-after-refresh-source',
          preserveHorizontalOffset: horizontalOffsetToPreserve,
        );
      }),
    );
  }

  void _clearHeaderFilter(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  ) {
    if (!_hasHeaderFilterStateForColumn(column, runtimeColumnId)) {
      return;
    }

    if (!_readyView()) {
      return;
    }

    final horizontalOffsetToPreserve = _headerFilterHorizontalOffsetSnapshot();

    _cancelHeaderFilterDebounce();
    _setGridState(() {
      _headerFilterValues.remove(runtimeColumnId);
      _headerFilterOperators.remove(runtimeColumnId);
      _headerFilterRangeEditSnapshots.remove(runtimeColumnId);
      _headerFilterResetGeneration++;
    });

    _applyHeaderFilterChangesNow(
      preserveHorizontalOffset: horizontalOffsetToPreserve,
    );
  }

  void _clearHeaderFilters() {
    if (!_hasHeaderFilterState &&
        _rowSelectionFilter == null &&
        !widget.dataSet.filter.active) {
      return;
    }

    if (!_readyView()) {
      return;
    }

    final horizontalOffsetToPreserve = _headerFilterHorizontalOffsetSnapshot();

    _cancelHeaderFilterDebounce();
    _setGridState(() {
      _headerFilterValues.clear();
      _headerFilterOperators.clear();
      _headerFilterRangeEditSnapshots.clear();
      _rowSelectionFilter = null;
      _headerFilterResetGeneration++;
    });

    _applyHeaderFilterChangesNow(
      preserveHorizontalOffset: horizontalOffsetToPreserve,
    );
  }

  void _cancelHeaderFilterDebounce() {
    _headerFilterRefreshGeneration++;
    _headerFilterDebounceTimer?.cancel();
    _headerFilterDebounceTimer = null;
  }

  bool _focusHeaderFilterFromFirstGridRow() {
    if (!_showsHeaderFilterRow) {
      return false;
    }

    final cell = _editingCell ?? _selectedCell;
    if (cell == null || cell.rowIndex != 0) {
      return false;
    }
    if (cell.columnIndex < 0 || cell.columnIndex >= _visibleColumns.length) {
      return false;
    }

    final column = _visibleColumns[cell.columnIndex];
    final runtimeColumnId = _runtimeColumnIdAt(cell.columnIndex);
    if (runtimeColumnId == null ||
        !_isHeaderFilterColumnFocusable(column, runtimeColumnId)) {
      return false;
    }

    if (!_readyView()) {
      return false;
    }
    _scrollColumnIntoView(cell.columnIndex);
    _headerFilterFocusNode(column, runtimeColumnId).requestFocus();
    return true;
  }

  bool _isHeaderFilterColumnFocusable(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  ) {
    return FdcHeaderFilterInputBehavior.resolve(
      column: column,
      dataType: _fieldDataTypeFor(column),
      operator: _headerFilterOperator(column, runtimeColumnId),
      canOpenFilterMenu: _canOpenFilterMenu(),
    ).hasFocusableInput;
  }

  void _commitHeaderFilterTextDisplayValue(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  ) {
    if ((column.filterConfig?.editor ?? FdcFilterEditor.search) !=
        FdcFilterEditor.search) {
      return;
    }

    final current = _headerFilterValues[runtimeColumnId];
    if (current == null) {
      return;
    }

    final text = current.toString().trim();
    if (text.isEmpty || !_isHeaderFilterTextReadyToApply(column, text)) {
      return;
    }

    final parsed = _parseHeaderFilterValue(
      column,
      text,
      runtimeColumnId: runtimeColumnId,
    );
    if (parsed == null) {
      return;
    }

    final display = _formatHeaderFilterDisplayValue(
      column,
      parsed,
      runtimeColumnId: runtimeColumnId,
    );
    if (display == text) {
      return;
    }

    final previousSignature = _headerFilterSignature();
    final wasApplied = _lastAppliedHeaderFilterSignature == previousSignature;

    _setGridState(() {
      _headerFilterValues[runtimeColumnId] = display;
      _headerFilterResetGeneration++;
      if (wasApplied) {
        _lastAppliedHeaderFilterSignature = _headerFilterSignature();
      }
    });
  }

  FdcHeaderFilterValueCodec get _headerFilterValueCodec =>
      FdcHeaderFilterValueCodec(
        formatSettings: _formatSettings,
        dataTypeOf: _fieldDataTypeFor,
        decimalScaleOf: (column) =>
            _fieldMetadata(column.fieldName).decimalScale,
        decimalPrecisionOf: (column) =>
            _fieldMetadata(column.fieldName).decimalPrecision,
        runtimeColumnIdOf: _runtimeColumnIdForColumn,
        translations: _translations,
      );

  String _formatHeaderFilterDisplayValue(
    FdcGridColumn<dynamic> column,
    Object? value, {
    FdcColumnIdentity? runtimeColumnId,
  }) {
    return _headerFilterValueCodec.formatDisplayValue(
      column,
      value,
      runtimeColumnId: runtimeColumnId,
    );
  }

  void _setHeaderFilterTextValue(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
    String value, {
    required bool submitted,
  }) {
    final normalized = value.trim();
    final previousValue =
        _headerFilterValues[runtimeColumnId]?.toString() ?? '';
    final nextOperator = _headerFilterOperator(column, runtimeColumnId);
    final previousOperator = _headerFilterOperators[runtimeColumnId];

    if (normalized.isEmpty) {
      final hadValue = _headerFilterValues.remove(runtimeColumnId) != null;
      // Clearing the text value must not clear an explicitly selected scalar
      // operator. The operator is part of the user's header-filter editor
      // preference, while the empty value only means there is no active
      // predicate to apply.
      final hadOperator = previousOperator != null;
      if (!hadValue && !hadOperator && previousValue.isEmpty) {
        return;
      }
      if (_headerTextFiltersApplyAutomatically || submitted) {
        _scheduleHeaderFilterRefresh(inputText: normalized);
      } else {
        _cancelHeaderFilterDebounce();
      }
      return;
    }

    if (previousValue == normalized && previousOperator == nextOperator) {
      if (submitted) {
        _scheduleHeaderFilterRefresh(inputText: normalized);
      }
      return;
    }

    _headerFilterValues[runtimeColumnId] = normalized;
    _headerFilterOperators[runtimeColumnId] = nextOperator;

    if (!_isHeaderFilterTextReadyToApply(column, normalized)) {
      _cancelHeaderFilterDebounce();
      return;
    }

    if (_headerTextFiltersApplyAutomatically || submitted) {
      _scheduleHeaderFilterRefresh(inputText: normalized);
    } else {
      _cancelHeaderFilterDebounce();
    }
  }

  bool get _headerTextFiltersApplyAutomatically =>
      _headerFilterOptions.debouncePolicy != FdcDebouncePolicy.disabled;

  bool _isHeaderFilterTextReadyToApply(
    FdcGridColumn<dynamic> column,
    String value,
  ) {
    return _headerFilterValueCodec.isTextReadyToApply(column, value);
  }

  Object? _parseHeaderFilterValue(
    FdcGridColumn<dynamic> column,
    Object? value, {
    FdcColumnIdentity? runtimeColumnId,
  }) {
    return _headerFilterValueCodec.parseValue(
      column,
      value,
      runtimeColumnId: runtimeColumnId,
    );
  }

  bool _areHeaderFiltersReadyToApply() {
    for (final entry in _headerFilterValues.entries) {
      final rawValue = entry.value;
      if (rawValue is FdcFilterRangeValue) {
        final column = _columnByRuntimeColumnId(entry.key);
        if (column == null) {
          continue;
        }
        if (_parseHeaderFilterValue(
                  column,
                  rawValue.from,
                  runtimeColumnId: entry.key,
                ) ==
                null ||
            _parseHeaderFilterValue(
                  column,
                  rawValue.to,
                  runtimeColumnId: entry.key,
                ) ==
                null) {
          return false;
        }
        continue;
      }
      if (rawValue is Iterable) {
        if (rawValue.isEmpty) {
          continue;
        }
        final column = _columnByRuntimeColumnId(entry.key);
        if (column == null) {
          continue;
        }
        if (_parseHeaderFilterValue(
              column,
              rawValue,
              runtimeColumnId: entry.key,
            ) ==
            null) {
          return false;
        }
        continue;
      }

      final value = rawValue?.toString().trim() ?? '';
      if (value.isEmpty) {
        continue;
      }

      final column = _columnByRuntimeColumnId(entry.key);
      if (column == null) {
        continue;
      }

      if (!_isHeaderFilterTextReadyToApply(column, value)) {
        return false;
      }
    }

    return true;
  }

  String _headerFilterSignature() {
    final base = FdcHeaderFilterStateSnapshot.signature(
      values: _headerFilterValues,
      operators: _headerFilterOperators,
    );
    return "$base|selected:${_rowSelectionFilter ?? 'any'}";
  }

  void _scheduleHeaderFilterRefresh({String? inputText}) {
    _cancelHeaderFilterDebounce();
    if (!widget.dataSet.isOpen) {
      return;
    }
    final generation = _headerFilterRefreshGeneration;
    final duration = FdcDebounceDelay.resolve(
      policy: _headerFilterOptions.debouncePolicy,
      baseDelay: _headerFilterOptions.debounceDuration,
      recordCount: widget.dataSet.recordCount,
      inputText: inputText,
    );
    if (duration <= Duration.zero) {
      _applyHeaderFilterChangesNow(generation: generation);
      return;
    }

    _headerFilterDebounceTimer = Timer(duration, () {
      _applyHeaderFilterChangesNow(generation: generation);
    });
  }

  void _applyHeaderFilterChangesNow({
    int? generation,
    double? preserveHorizontalOffset,
  }) {
    if (!mounted || !widget.dataSet.isOpen) {
      return;
    }

    if (generation != null && generation != _headerFilterRefreshGeneration) {
      return;
    }

    _cancelHeaderFilterDebounce();

    if (!_areHeaderFiltersReadyToApply()) {
      return;
    }

    final signature = _headerFilterSignature();
    if (_lastAppliedHeaderFilterSignature == signature) {
      return;
    }

    if (_headerFilterApplyInFlight) {
      _headerFilterApplyQueued = true;
      return;
    }

    final horizontalOffsetToPreserve =
        preserveHorizontalOffset ?? _headerFilterHorizontalOffsetSnapshot();

    _lastAppliedHeaderFilterSignature = signature;
    _headerFilterApplyInFlight = true;
    _headerFilterApplyQueued = false;
    _headerFilterInFlightSignature = signature;

    unawaited(
      _runHeaderFilterApplyAsync(
        signature: signature,
        horizontalOffsetToPreserve: horizontalOffsetToPreserve,
      ),
    );
  }

  Future<void> _runHeaderFilterApplyAsync({
    required String signature,
    required double horizontalOffsetToPreserve,
  }) async {
    try {
      await _refreshRowsFromSourceAsync(updateColumnWidths: false);
      if (!mounted) {
        return;
      }
      _setGridState(() {
        _validateCellState();
      });
      _resetVerticalScrollToTopAfterLayout(
        reason: 'apply-header-filter-changes-after-refresh-source',
        preserveHorizontalOffset: horizontalOffsetToPreserve,
      );
    } on Object catch (error, stackTrace) {
      if (_lastAppliedHeaderFilterSignature == signature) {
        _lastAppliedHeaderFilterSignature = null;
      }
      _handleGridAsyncOperationError(
        error,
        stackTrace,
        operation: 'applying a grid header filter',
      );
    } finally {
      if (_headerFilterInFlightSignature == signature) {
        _headerFilterInFlightSignature = null;
      }
      _headerFilterApplyInFlight = false;

      final shouldReplay =
          _headerFilterApplyQueued &&
          mounted &&
          widget.dataSet.isOpen &&
          _areHeaderFiltersReadyToApply() &&
          _headerFilterSignature() != _lastAppliedHeaderFilterSignature;
      _headerFilterApplyQueued = false;

      if (shouldReplay) {
        scheduleMicrotask(() {
          if (!mounted) {
            return;
          }
          _applyHeaderFilterChangesNow();
        });
      }
    }
  }

  void _setHeaderFilterValue(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
    Object? value,
  ) {
    final previousValue = _headerFilterValues[runtimeColumnId];
    final nextOperator = value == null
        ? null
        : value is FdcFilterRangeValue
        ? FdcFilterOperator.between
        : _headerFilterOperator(column, runtimeColumnId);
    final previousOperator = _headerFilterOperators[runtimeColumnId];

    if (previousValue == value && previousOperator == nextOperator) {
      return;
    }

    _setGridState(() {
      _headerFilterRangeEditSnapshots.remove(runtimeColumnId);
      if (_rangeAutoOpenColumnId == runtimeColumnId) {
        _rangeAutoOpenColumnId = null;
      }
      if (value == null) {
        _headerFilterValues.remove(runtimeColumnId);
        _headerFilterOperators.remove(runtimeColumnId);
      } else {
        _headerFilterValues[runtimeColumnId] = value;
        _headerFilterOperators[runtimeColumnId] = nextOperator!;
      }
    });

    _scheduleHeaderFilterRefresh();
  }

  void _setHeaderFilterOperator(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
    FdcFilterOperator operator,
  ) {
    final previousOperator = _headerFilterOperator(column, runtimeColumnId);
    if (previousOperator == operator &&
        _headerFilterOperators[runtimeColumnId] == operator) {
      if (operator == FdcFilterOperator.between) {
        _requestHeaderFilterRangeAutoOpen(runtimeColumnId);
      } else {
        _focusEmptyScalarHeaderFilterAfterOperatorSelection(
          column,
          runtimeColumnId,
          operator,
        );
      }
      return;
    }

    final hadRangeValue =
        _headerFilterValues[runtimeColumnId] is FdcFilterRangeValue;

    var shouldRefresh = false;
    _setGridState(() {
      if (operator == FdcFilterOperator.between) {
        // Selecting Between from the operator menu is only a popup request.
        // The visible header filter state must remain committed until the
        // range popup Apply button writes a FdcFilterRangeValue.
        _rangeAutoOpenColumnId = runtimeColumnId;
        _headerFilterRangeAutoOpenGeneration++;
        shouldRefresh = false;
        return;
      }
      _headerFilterRangeEditSnapshots.remove(runtimeColumnId);
      _headerFilterOperators[runtimeColumnId] = operator;
      if (_operatorIgnoresValue(operator) || hadRangeValue) {
        _headerFilterValues.remove(runtimeColumnId);
        _headerFilterResetGeneration++;
      }
      shouldRefresh =
          hadRangeValue ||
          _isHeaderFilterActive(column, runtimeColumnId) ||
          _operatorIgnoresValue(operator) ||
          _operatorIgnoresValue(previousOperator);
    });

    if (shouldRefresh) {
      _scheduleHeaderFilterRefresh();
    }

    _focusEmptyScalarHeaderFilterAfterOperatorSelection(
      column,
      runtimeColumnId,
      operator,
    );
  }

  void _focusEmptyScalarHeaderFilterAfterOperatorSelection(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
    FdcFilterOperator operator,
  ) {
    final value = _headerFilterValues[runtimeColumnId];
    final isEmpty = value == null || (value is String && value.isEmpty);
    if (!isEmpty) {
      return;
    }

    final behavior = FdcHeaderFilterInputBehavior.resolve(
      column: column,
      dataType: _fieldDataTypeFor(column),
      operator: operator,
      canOpenFilterMenu: _canOpenFilterMenu(),
    );
    if (!behavior.acceptsTextInput) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_showColumnFilters) {
        return;
      }
      if (_headerFilterOperator(column, runtimeColumnId) != operator) {
        return;
      }
      _headerFilterFocusNode(column, runtimeColumnId).requestFocus();
    });
  }

  void _cancelHeaderFilterRangeEdit(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity runtimeColumnId,
  ) {
    final snapshot = _headerFilterRangeEditSnapshots.remove(runtimeColumnId);
    if (snapshot == null) {
      return;
    }

    _setGridState(() {
      if (snapshot.hadValue) {
        _headerFilterValues[runtimeColumnId] = snapshot.value;
      } else {
        _headerFilterValues.remove(runtimeColumnId);
      }

      if (snapshot.hadOperator && snapshot.operator != null) {
        _headerFilterOperators[runtimeColumnId] = snapshot.operator!;
      } else {
        _headerFilterOperators.remove(runtimeColumnId);
      }

      if (_rangeAutoOpenColumnId == runtimeColumnId) {
        _rangeAutoOpenColumnId = null;
      }
    });
  }

  void _requestHeaderFilterRangeAutoOpen(FdcColumnIdentity runtimeColumnId) {
    _setGridState(() {
      _rangeAutoOpenColumnId = runtimeColumnId;
      _headerFilterRangeAutoOpenGeneration++;
    });
  }

  void _clearHeaderFilterRangeAutoOpen(FdcColumnIdentity runtimeColumnId) {
    if (_rangeAutoOpenColumnId != runtimeColumnId) {
      return;
    }

    _setGridState(() {
      if (_rangeAutoOpenColumnId == runtimeColumnId) {
        _rangeAutoOpenColumnId = null;
      }
    });
  }

  FdcFilterOperator _headerFilterOperator(
    FdcGridColumn<dynamic> column, [
    FdcColumnIdentity? runtimeColumnId,
  ]) {
    runtimeColumnId ??= _runtimeColumnIdForColumn(column);
    final current = runtimeColumnId == null
        ? null
        : _headerFilterOperators[runtimeColumnId];
    return FdcHeaderFilterOperatorPolicy.resolveOperator(
      column: column,
      dataType: _fieldDataTypeFor(column),
      gridTextOperator: _headerFilterOptions.defaultTextOperator,
      current: current,
      adapterBacked:
          widget.dataSet.paging.enabled && widget.dataSet.adapter != null,
    );
  }

  List<FdcFilterOperator> _operatorsForColumn(FdcGridColumn<dynamic> column) {
    return FdcHeaderFilterOperatorPolicy.operatorsForColumn(
      column,
      _fieldDataTypeFor(column),
      adapterBacked:
          widget.dataSet.paging.enabled && widget.dataSet.adapter != null,
    );
  }

  List<FdcOption<Object?>> _headerFilterOptionItems(
    BuildContext context,
    FdcGridColumn<dynamic> column,
  ) {
    return FdcHeaderFilterOptionsResolver(
      dataSet: widget.dataSet,
      formatSettings: FdcApp.formatsOf(context),
      runtimeColumnIdOf: _runtimeColumnIdForColumn,
      decimalScaleOf: _headerFilterDecimalScaleOf,
      decimalPrecisionOf: _headerFilterDecimalPrecisionOf,
      translations: FdcApp.translationsOf(context),
    ).resolve(column);
  }

  String _filterOperatorLabel(FdcFilterOperator operator) {
    return FdcHeaderFilterOperatorPolicy.labelOf(
      operator,
      translations: FdcApp.translationsOf(context),
    );
  }

  bool _operatorIgnoresValue(FdcFilterOperator operator) {
    return FdcHeaderFilterOperatorPolicy.ignoresValue(operator);
  }
}
