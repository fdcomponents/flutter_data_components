// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridLayoutStateRuntime on _FdcGridState {
  void _notifyGridLayoutChanged() {
    widget.controller?.layoutChanged();
  }

  void _attachGridLayoutStateFeature() {
    final controller = widget.controller;
    if (controller == null) {
      return;
    }
    controller.attach(
      capture: _captureGridLayoutSnapshot,
      restore: _restoreGridLayoutSnapshotAndMarkSaved,
      reset: _resetGridLayoutWithPersistenceGuard,
      focusColumn: _focusGridControllerColumn,
      setColumnVisible: _setGridControllerColumnVisible,
      clearFilters: _clearGridControllerFilters,
      showFilters: _showGridControllerFilters,
      hideFilters: _hideGridControllerFilters,
      clearSorting: _clearGridControllerSorting,
      expandDetailRow: _expandGridControllerDetailRow,
      collapseDetailRow: _collapseGridControllerDetailRow,
      collapseAllDetailRows: _collapseGridControllerAllDetailRows,
      clearRangeSelection: _clearGridControllerRangeSelection,
      saveLayout: _saveGridLayoutNow,
      loadLayout: _loadGridLayoutNow,
      deleteLayout: _deleteGridLayoutSnapshot,
      layoutChanged: _handleGridLayoutChanged,
    );

    final generation = ++_layoutPersistenceGeneration;
    if (widget.layoutPersistence?.autoLoad ?? false) {
      unawaited(_autoLoadGridLayout(generation));
    }
  }

  void _detachGridLayoutStateFeature(
    FdcGridControllerFeature? feature, {
    FdcGridLayoutPersistenceFeature? layoutPersistence,
  }) {
    _layoutPersistenceGeneration++;
    final persistence = layoutPersistence ?? widget.layoutPersistence;
    final timerWasPending = _layoutAutoSaveTimer?.isActive ?? false;
    _layoutAutoSaveTimer?.cancel();
    _layoutAutoSaveTimer = null;

    if (timerWasPending &&
        (persistence?.autoSave ?? false) &&
        feature != null &&
        mounted) {
      unawaited(
        _saveGridLayoutSnapshot(
          rethrowError: false,
          layoutPersistence: persistence,
        ),
      );
    }

    feature?.detach();
  }

  void _restoreGridLayoutSnapshotAndMarkSaved(FdcGridLayoutSnapshot snapshot) {
    _layoutAutoSaveTimer?.cancel();
    _layoutAutoSaveTimer = null;
    _suppressLayoutAutoSave = true;
    try {
      _restoreGridLayoutSnapshot(snapshot);
      widget.layoutPersistence?.markSnapshotSaved(snapshot);
    } finally {
      _suppressLayoutAutoSave = false;
    }
  }

  void _resetGridLayoutWithPersistenceGuard() {
    _layoutAutoSaveTimer?.cancel();
    _layoutAutoSaveTimer = null;
    _suppressLayoutAutoSave = true;
    try {
      _resetGridLayout();
    } finally {
      _suppressLayoutAutoSave = false;
    }
  }

  Future<void> _saveGridLayoutNow() async {
    _layoutAutoSaveTimer?.cancel();
    _layoutAutoSaveTimer = null;
    await _saveGridLayoutSnapshot(rethrowError: true);
  }

  Future<bool> _loadGridLayoutNow() async {
    final snapshot = await _loadGridLayoutSnapshot(rethrowError: true);
    if (snapshot == null) {
      return false;
    }
    _restoreGridLayoutSnapshotAndMarkSaved(snapshot);
    return true;
  }

  Future<void> _deleteGridLayoutSnapshot() async {
    final persistence = widget.layoutPersistence;
    if (persistence == null) {
      return;
    }
    await Future<void>.sync(
      () => persistence.deleteSnapshot(rethrowError: true),
    );
  }

  void _handleGridLayoutChanged() {
    final persistence = widget.layoutPersistence;
    if (persistence == null ||
        !persistence.autoSave ||
        _suppressLayoutAutoSave ||
        widget.controller == null ||
        !mounted) {
      return;
    }
    _layoutAutoSaveTimer?.cancel();
    _layoutAutoSaveTimer = Timer(persistence.autoSaveDelay, () {
      _layoutAutoSaveTimer = null;
      if (!mounted || widget.controller == null) {
        return;
      }
      unawaited(_saveGridLayoutSnapshot(rethrowError: false));
    });
  }

  Future<void> _autoLoadGridLayout(int generation) async {
    final persistence = widget.layoutPersistence;
    if (persistence == null) {
      return;
    }
    final snapshot = await _loadGridLayoutSnapshot(rethrowError: false);
    if (snapshot == null ||
        generation != _layoutPersistenceGeneration ||
        !mounted ||
        widget.controller == null ||
        !identical(persistence, widget.layoutPersistence)) {
      return;
    }
    _restoreGridLayoutSnapshotAndMarkSaved(snapshot);
  }

  Future<FdcGridLayoutSnapshot?> _loadGridLayoutSnapshot({
    required bool rethrowError,
  }) async {
    final persistence = widget.layoutPersistence;
    if (persistence == null) {
      return null;
    }
    return Future<FdcGridLayoutSnapshot?>.sync(
      () => persistence.loadSnapshot(rethrowError: rethrowError),
    );
  }

  Future<void> _saveGridLayoutSnapshot({
    required bool rethrowError,
    FdcGridLayoutPersistenceFeature? layoutPersistence,
  }) async {
    final persistence = layoutPersistence ?? widget.layoutPersistence;
    if (persistence == null) {
      return;
    }
    final snapshot = _captureGridLayoutSnapshot();
    await Future<void>.sync(
      () => persistence.saveSnapshot(snapshot, rethrowError: rethrowError),
    );
  }

  ({FdcGridColumn<dynamic> column, FdcColumnIdentity runtimeId})?
  _gridControllerColumnEntry(String columnId) {
    final id = columnId.trim();
    if (id.isEmpty) {
      return null;
    }
    final resolvedColumns = _runtime.domains.columns.columns.resolveColumns(
      widget.columns,
      _rows,
      widget.dataSet,
    );
    final keys = _identityKeysForResolvedColumns(resolvedColumns);
    for (var index = 0; index < resolvedColumns.length; index++) {
      final candidate = resolvedColumns[index];
      if (candidate.id == id) {
        return (
          column: candidate,
          runtimeId: _columnIdentityForKey(keys[index]),
        );
      }
    }
    return null;
  }

  bool _focusGridControllerColumn(String columnId) {
    final entry = _gridControllerColumnEntry(columnId);
    if (entry == null) {
      return false;
    }
    final columnIndex = _visibleRuntimeColumnIdsCache.indexOf(entry.runtimeId);
    if (columnIndex < 0) {
      return false;
    }
    final rowIndex = _currentRowIndex ?? _selectedRowIndex ?? 0;
    if (rowIndex < 0 || rowIndex >= _rows.length) {
      return false;
    }
    _activateCell(_cellRef(rowIndex, columnIndex), editIfPossible: false);
    return true;
  }

  bool _setGridControllerColumnVisible(String columnId, bool visible) {
    final entry = _gridControllerColumnEntry(columnId);
    if (entry == null) {
      return false;
    }
    final wasVisible =
        _runtimeColumnVisibilityOverrides[entry.runtimeId] ??
        entry.column.visible;
    if (wasVisible == visible) {
      return true;
    }
    _setGridState(() {
      _runtimeColumnVisibilityOverrides[entry.runtimeId] = visible;
      _refreshColumnCache();
      _columnSizing.syncRuntimeColumns(
        columns: _visibleColumnsCache,
        runtimeColumnIds: _visibleRuntimeColumnIdsCache,
        defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
      );
      _markColumnWidthsDirty();
      _lastColumnWidthViewport = null;
      _summaryDisplayedValueCache.clear();
      _summaryAggregateValueCache.clear();
      _resetRangeSelectionState(rebuild: false);
      if (!visible && _selectedCell?.runtimeColumnId == entry.runtimeId) {
        _editingCell = null;
        _editAtEndCell = null;
        _pendingEditCell = null;
        _clearPendingEditText();
        _clearEditingOriginalValue();
        if (_visibleColumnsCache.isEmpty || _rows.isEmpty) {
          _selectedCell = null;
        } else {
          final nextColumnIndex = columnIndexClamped(columnIndex: 0);
          final nextRowIndex = (_selectedRowIndex ?? _currentRowIndex ?? 0)
              .clamp(0, _rows.length - 1)
              .toInt();
          _selectedCell = _cellRef(nextRowIndex, nextColumnIndex);
        }
      }
    });
    _notifyGridLayoutChanged();
    if (visible) {
      _scrollColumnIntoViewAfterLayout(
        _visibleRuntimeColumnIdsCache.indexOf(entry.runtimeId),
      );
    }
    return true;
  }

  int columnIndexClamped({required int columnIndex}) {
    if (_visibleColumnsCache.isEmpty) {
      return 0;
    }
    return columnIndex.clamp(0, _visibleColumnsCache.length - 1).toInt();
  }

  Future<bool> _clearGridControllerFilters() {
    return widget.dataSet.filter.clear();
  }

  bool _showGridControllerFilters() {
    if (!_columnFilteringAllowed || !widget.header.filters.visible) {
      return false;
    }
    if (_showColumnFilters) {
      return true;
    }
    _blurGrid();
    _setGridState(() {
      _showColumnFilters = true;
      _markColumnWidthsDirty();
    });
    _notifyGridLayoutChanged();
    return true;
  }

  Future<bool> _hideGridControllerFilters() async {
    if (!_columnFilteringAllowed || !_showColumnFilters) {
      return false;
    }

    final clearsAppliedFilters =
        _hasGridManagedFilterState || widget.dataSet.filter.active;
    if (clearsAppliedFilters) {
      if (!_readyView()) {
        return false;
      }

      final horizontalOffsetToPreserve =
          _headerFilterHorizontalOffsetSnapshot();
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
        return false;
      } finally {
        _updatingDataSetFromGrid = false;
      }

      if (!mounted || !cleared) {
        return false;
      }

      _setGridState(() {
        _refreshRowsFromDataSet(updateColumnWidths: false);
        _validateCellState();
      });
      _resetVerticalScrollToTopAfterLayout(
        reason: 'controller-hide-filters-clear-filters',
        preserveHorizontalOffset: horizontalOffsetToPreserve,
      );
      return true;
    }

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
    return true;
  }

  Future<bool> _clearGridControllerSorting() {
    return widget.dataSet.sort.clear();
  }

  int? _gridControllerDetailRowIndex(int? rowIndex) {
    final index = rowIndex ?? _currentRowIndex ?? _selectedRowIndex;
    if (index == null || index < 0 || index >= _rows.length) {
      return null;
    }
    return index;
  }

  bool _expandGridControllerDetailRow({int? rowIndex}) {
    final index = _gridControllerDetailRowIndex(rowIndex);
    if (index == null || !_canExpandDetailRow(index)) {
      return false;
    }
    if (_isDetailRowExpanded(index)) {
      _revealExpandedDetailRowAfterLayout(_recordIdForGridRow(index)!);
      return true;
    }
    _toggleDetailRow(index);
    return _isDetailRowExpanded(index);
  }

  bool _collapseGridControllerDetailRow({int? rowIndex}) {
    final index = _gridControllerDetailRowIndex(rowIndex);
    if (index == null || !_isDetailRowExpanded(index)) {
      return false;
    }
    _toggleDetailRow(index);
    return true;
  }

  bool _collapseGridControllerAllDetailRows() {
    return _collapseAllDetailRowsImmediately();
  }

  bool _clearGridControllerRangeSelection() {
    final hadRange = _rangeSelectionSession.hasRangeState;
    _resetRangeSelectionState();
    _notifyRangeSelectionReset();
    return hadRange;
  }

  String _layoutStorageId(FdcColumnIdentityKey key) {
    final explicitId = key.id;
    if (explicitId != null) {
      return explicitId;
    }
    return '${key.columnType}|${key.fieldName}|${key.occurrence}';
  }

  FdcGridLayoutSnapshot _captureGridLayoutSnapshot() {
    final resolvedColumns = _runtime.domains.columns.columns.resolveColumns(
      widget.columns,
      _rows,
      widget.dataSet,
    );
    final keys = _identityKeysForResolvedColumns(resolvedColumns);
    final runtimeOrder = <FdcColumnIdentity, int>{
      for (var i = 0; i < _runtimeColumnOrderIds.length; i++)
        _runtimeColumnOrderIds[i]: i,
    };
    final snapshots = <FdcGridColumnLayoutSnapshot>[];
    for (
      var sourceIndex = 0;
      sourceIndex < resolvedColumns.length;
      sourceIndex++
    ) {
      final column = resolvedColumns[sourceIndex];
      final key = keys[sourceIndex];
      final runtimeId = _columnIdentityForKey(key);
      snapshots.add(
        FdcGridColumnLayoutSnapshot(
          id: _layoutStorageId(key),
          order:
              runtimeOrder[runtimeId] ??
              (_runtimeColumnOrderIds.length + sourceIndex),
          width: _columnSizing.baseColumnWidth(
            runtimeId,
            column,
            defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
          ),
          visible:
              _runtimeColumnVisibilityOverrides[runtimeId] ?? column.visible,
          pin: _effectiveColumnPin(column, runtimeId),
          summaryAggregate: _effectiveSummaryAggregateForColumn(
            column,
            runtimeColumnId: runtimeId,
          ),
        ),
      );
    }
    snapshots.sort((a, b) => a.order.compareTo(b.order));
    return FdcGridLayoutSnapshot(
      columns: List<FdcGridColumnLayoutSnapshot>.unmodifiable(snapshots),
      headerFiltersVisible: _showColumnFilters,
    );
  }

  void _restoreGridLayoutSnapshot(FdcGridLayoutSnapshot snapshot) {
    final resolvedColumns = _runtime.domains.columns.columns.resolveColumns(
      widget.columns,
      _rows,
      widget.dataSet,
    );
    final keys = _identityKeysForResolvedColumns(resolvedColumns);
    final entriesByStorageId =
        <
          String,
          ({FdcGridColumn<dynamic> column, FdcColumnIdentity runtimeId})
        >{};
    for (var index = 0; index < resolvedColumns.length; index++) {
      final key = keys[index];
      entriesByStorageId[_layoutStorageId(key)] = (
        column: resolvedColumns[index],
        runtimeId: _columnIdentityForKey(key),
      );
    }

    final orderedIds = <FdcColumnIdentity>[];
    final sortedColumns = [...snapshot.columns]
      ..sort((a, b) => a.order.compareTo(b.order));
    _setGridState(() {
      _runtimeColumnPinOverrides.clear();
      _runtimeColumnVisibilityOverrides.clear();
      _runtimeSummaryAggregateOverrides.clear();
      _columnSizing.resetUserColumnWidths();

      for (final saved in sortedColumns) {
        final entry = entriesByStorageId[saved.id];
        if (entry == null) {
          continue;
        }
        final column = entry.column;
        final runtimeId = entry.runtimeId;
        orderedIds.add(runtimeId);
        _runtimeColumnVisibilityOverrides[runtimeId] = saved.visible;

        final minWidth = math.max(0.0, column.minWidth);
        final maxWidth = column.maxWidth > 0
            ? column.maxWidth
            : double.infinity;
        final width = saved.width.clamp(minWidth, maxWidth).toDouble();
        _columnSizing.columnWidths[runtimeId] = width;

        if (!_isGroupedColumn(column)) {
          final declaredPin = column.pin;
          if (declaredPin.isFixed) {
            _runtimeColumnPinOverrides.remove(runtimeId);
          } else if (widget.pinning.enabled) {
            final restoredPin = switch (saved.pin) {
              FdcGridColumnPin.startFixed => FdcGridColumnPin.start,
              FdcGridColumnPin.endFixed => FdcGridColumnPin.end,
              _ => saved.pin,
            };
            if (restoredPin != declaredPin) {
              _runtimeColumnPinOverrides[runtimeId] = restoredPin;
            }
          }
        }
        _runtimeSummaryAggregateOverrides[runtimeId] = saved.summaryAggregate;
      }

      _runtimeColumnOrderIds
        ..clear()
        ..addAll(orderedIds);
      _hasUserColumnOrderOverride = orderedIds.isNotEmpty;
      _showColumnFilters =
          widget.header.filters.visible && snapshot.headerFiltersVisible;
      _refreshColumnCache();
      _columnSizing.syncRuntimeColumns(
        columns: _visibleColumnsCache,
        runtimeColumnIds: _visibleRuntimeColumnIdsCache,
        defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
      );
      _summaryDisplayedValueCache.clear();
      _summaryAggregateValueCache.clear();
      _lastColumnWidthViewport = null;
      _markColumnWidthsDirty();
    });
  }
}
