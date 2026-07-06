// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridHeaderActionRuntime on _FdcGridState {
  bool get _rowSelectionControlsVisible =>
      widget.rowIndicator.visible && widget.rowIndicator.options.showRowSelect;

  FdcGridHeaderCallbacks _createHeaderCallbacks() {
    return FdcGridHeaderCallbacks(
      columnLabelOf: _columnLabel,
      sortIconOf: _sortIcon,
      sortIconColorOf: _sortIconColor,
      onHeaderSortTap: (columnIndex) =>
          _runViewAction(() => _handleHeaderSortTap(columnIndex)),
      onHeaderSortAscending: (columnIndex) =>
          _runViewAction(() => _handleHeaderSortAscending(columnIndex)),
      onHeaderSortDescending: (columnIndex) =>
          _runViewAction(() => _handleHeaderSortDescending(columnIndex)),
      onHeaderAddSortAscending: (columnIndex) =>
          _runViewAction(() => _handleHeaderAddSortAscending(columnIndex)),
      onHeaderAddSortDescending: (columnIndex) =>
          _runViewAction(() => _handleHeaderAddSortDescending(columnIndex)),
      onHeaderClearSort: (columnIndex) =>
          _runViewAction(() => _handleHeaderClearSort(columnIndex)),
      onHeaderClearAllSorts: () => _runViewAction(_handleHeaderClearAllSorts),
      hasGridLayoutChanges: _hasGridLayoutChanges,
      onResetGridLayout: () => _runHeaderAction(_resetGridLayout),
      hasUserPinnedColumns: _hasUserPinnedColumns,
      onUnpinAllUserColumns: () => _runHeaderAction(_unpinAllUserColumns),
      canHeaderSort: _canHeaderSort,
      canChangeView: _canChangeView,
      headerSortCount: () => _sort.count,
      hasDataSetSortState: () => widget.dataSet.sort.active,
      headerSortPosition: _headerSortPosition,
      isHeaderSortAscending: _isHeaderSortAscending,
      isHeaderSortDescending: _isHeaderSortDescending,
      isHeaderSortActive: _isHeaderSortActive,
      headerColumnPinOf: _headerColumnPin,
      onSetHeaderColumnPin: (columnIndex, pin) =>
          _runHeaderAction(() => _setHeaderColumnPin(columnIndex, pin)),
      canHeaderColumnPin: _canHeaderColumnPin,
      canMoveColumn: _canMoveColumn,
      onColumnDragHoverTarget: _swapDraggingColumnWithTarget,
      onColumnDragStarted: (columnIndex) {
        _blurGrid();
        _invalidDropTargetHoverNotifier.value = false;
        _setGridState(() {
          _draggingColumnIndex = columnIndex;
          _clearLiveSwapTargetBlock();
          _clearLiveSwapLock();
          _invalidColumnDropTargetHovering = false;
        });
      },
      onColumnDragEnded: _clearDraggingColumn,
      onColumnDragInvalidTargetHoverChanged: (hovering) {
        if (_invalidColumnDropTargetHovering == hovering) {
          return;
        }
        _invalidDropTargetHoverNotifier.value = hovering;
        _setGridState(() {
          _invalidColumnDropTargetHovering = hovering;
        });
      },
      onColumnResizeStart: _startColumnResize,
      onColumnResizeUpdate: _updateColumnResize,
      onColumnResizeEnd: _endColumnResize,
      onColumnGroupResizeStart: _startColumnGroupResize,
      onColumnGroupResizeUpdate: _updateColumnGroupResize,
      onColumnGroupResizeEnd: _endColumnGroupResize,
      headerFilterFocusNodeOf: _headerFilterFocusNode,
      onFocusHeaderFilterField: _focusHeaderFilterField,
      onFocusNextHeaderFilter: _focusNextHeaderFilter,
      onFocusGridCellFromHeaderFilter: _focusGridCellFromHeaderFilter,
      onSetHeaderFilterTextValue: _setHeaderFilterTextValue,
      onSetHeaderFilterValue: _setHeaderFilterValue,
      parseHeaderFilterValue: (column, runtimeColumnId, value) =>
          _parseHeaderFilterValue(
            column,
            value,
            runtimeColumnId: runtimeColumnId,
          ),
      formatHeaderFilterValue: (column, runtimeColumnId, value) =>
          _formatHeaderFilterDisplayValue(
            column,
            value,
            runtimeColumnId: runtimeColumnId,
          ),
      onCancelHeaderFilterDebounce: _cancelHeaderFilterDebounce,
      onSetHeaderFilterOperator: (column, runtimeColumnId, operator) =>
          _runFilterAction(
            () => _setHeaderFilterOperator(column, runtimeColumnId, operator),
          ),
      onRangeAutoOpenHandled: _clearHeaderFilterRangeAutoOpen,
      onCancelHeaderFilterRangeEdit: (column, runtimeColumnId) =>
          _cancelHeaderFilterRangeEdit(column, runtimeColumnId),
      onClearHeaderFilter: (column, runtimeColumnId) =>
          _runFilterAction(() => _clearHeaderFilter(column, runtimeColumnId)),
      onClearFocusedCell: _blurGrid,
      onOpenHeaderMenu: _openHeaderMenu,
      canOpenFilterMenu: _canOpenFilterMenu,
      onOpenFilterMenu: _openFilterMenu,
      selectAllRowIndicatorValue: _selectAllRowIndicatorValue,
      canSelectAllRows: () =>
          widget.dataSet.recordCount > 0 &&
          !FdcDataSetInternal.hasActiveEdit(widget.dataSet),
      onSelectAllRows: (selected) =>
          _runHeaderAction(() => _setAllRowIndicatorRowsSelected(selected)),
      rowSelectionFilterValue: () => _rowSelectionFilter,
      hasRowSelectionControls: () => _rowSelectionControlsVisible,
      onSetRowSelectionFilter: (selected) =>
          _runFilterAction(() => _setRowSelectionFilter(selected)),
      hasHeaderFilterState: () =>
          _hasGridManagedFilterState || widget.dataSet.filter.active,
      headerFilterStateCount: () => _gridManagedFilterStateCount,
      onClearHeaderFilters: () => _runFilterAction(_clearHeaderFilters),
      canToggleColumnFilters: () =>
          _columnFilteringAllowed &&
          _visibleColumns.any((column) => column.filterEnabled),
      columnFiltersVisible: () => _showsHeaderFilterRow,
      onToggleColumnFilters: _toggleColumnFilters,
      headerFilterOperatorOf: _headerFilterOperator,
      hasHeaderFilterStateForColumn: _hasHeaderFilterStateForColumn,
      isHeaderFilterActive: _isHeaderFilterActive,
      operatorsForColumn: _operatorsForColumn,
      headerFilterOptions: _headerFilterOptionItems,
      filterOperatorLabel: _filterOperatorLabel,
      filterIconColorOf: _filterIconColor,
      headerFilterTextStyleOf: _headerFilterTextStyle,
      dataTypeOf: _fieldDataTypeFor,
      decimalScaleOf: _headerFilterDecimalScaleOf,
      decimalPrecisionOf: _headerFilterDecimalPrecisionOf,
    );
  }

  void _runHeaderAction(VoidCallback action) {
    _blurGrid();
    action();
    _blurGrid();
  }

  bool get _hasActiveViewQueryState {
    return _hasGridManagedFilterState ||
        widget.dataSet.filter.active ||
        widget.dataSet.search.active ||
        widget.dataSet.sort.active;
  }

  bool get _hasRowsOrActiveViewQueryState {
    return FdcDataSetInternal.loadedRecordCount(widget.dataSet) > 0 ||
        _hasActiveViewQueryState;
  }

  bool _canChangeView() {
    return widget.dataSet.isOpen &&
        _hasRowsOrActiveViewQueryState &&
        !FdcDataSetInternal.hasDirtyEdit(widget.dataSet);
  }

  bool _canSearch() {
    return widget.dataSet.isOpen &&
        _hasRowsOrActiveViewQueryState &&
        !FdcDataSetInternal.hasActiveEdit(widget.dataSet);
  }

  void _runViewAction(VoidCallback action) {
    if (!_canChangeView()) {
      _blurGrid();
      return;
    }
    _runHeaderAction(action);
  }

  bool _openHeaderMenu() {
    final horizontalOffsetToPreserve = _scrollCoordinator
        .horizontalOffsetSnapshotForViewAction();
    final shouldPreserveHorizontalOffset =
        horizontalOffsetToPreserve > 0 &&
        _scrollCoordinator.hasHorizontalScrollableRange;
    _headerMenuHorizontalOffsetToPreserve = shouldPreserveHorizontalOffset
        ? horizontalOffsetToPreserve
        : null;

    if (!shouldPreserveHorizontalOffset) {
      _blurGrid();
      return true;
    }

    _scrollCoordinator.beginHorizontalOffsetRestore(horizontalOffsetToPreserve);
    _blurGrid();
    _restoreHorizontalScrollOffsetNow(horizontalOffsetToPreserve);

    void settleRestore(int remainingFrames) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _scrollCoordinator.endHorizontalOffsetRestore();
          return;
        }

        _restoreHorizontalScrollOffsetNow(horizontalOffsetToPreserve);
        if (remainingFrames <= 0) {
          _scrollCoordinator.endHorizontalOffsetRestore();
          return;
        }
        settleRestore(remainingFrames - 1);
      });
    }

    settleRestore(3);
    return true;
  }

  bool _canMoveColumn(int fromIndex, int toIndex) {
    final columns = _visibleColumns;
    if (!widget.options.allowColumnReordering ||
        fromIndex == toIndex ||
        fromIndex < 0 ||
        fromIndex >= columns.length ||
        toIndex < 0 ||
        toIndex >= columns.length) {
      return false;
    }

    final fromPin = _headerColumnPin(fromIndex);
    final toPin = _headerColumnPin(toIndex);
    if (fromPin != toPin) {
      return false;
    }

    if (widget.columnGroups.isEmpty) {
      return true;
    }

    final fromGroup = _columnGroupOf(columns[fromIndex]);
    final toGroup = _columnGroupOf(columns[toIndex]);

    if (fromGroup == null && toGroup == null) {
      return true;
    }

    if (fromGroup == null || toGroup == null) {
      return false;
    }

    return identical(fromGroup, toGroup);
  }

  FdcGridColumnGroup? _columnGroupOf(
    FdcGridColumn<dynamic> column, {
    Map<String, FdcGridColumnGroup>? groupsById,
  }) {
    final groupId = column.groupId;
    if (groupId == null) {
      return null;
    }
    final groups =
        groupsById ??
        <String, FdcGridColumnGroup>{
          for (final group in widget.columnGroups) group.id: group,
        };
    return groups[groupId];
  }

  bool _canHeaderColumnPin(int columnIndex) {
    return widget.pinning.enabled &&
        columnIndex >= 0 &&
        columnIndex < _visibleColumns.length &&
        !_isGroupedColumn(_visibleColumns[columnIndex]);
  }

  FdcGridColumnPin _headerColumnPin(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
      return FdcGridColumnPin.none;
    }
    final runtimeColumnId = _runtimeColumnIdAt(columnIndex);
    if (runtimeColumnId == null) {
      return _visibleColumns[columnIndex].pin;
    }
    return _effectiveColumnPin(_visibleColumns[columnIndex], runtimeColumnId);
  }

  void _blurGrid() {
    _setGridState(() {
      _selectedCell = null;
      _selectedRowIndex = null;
      _editingCell = null;
      _editAtEndCell = null;
      _clearPendingEditText();
    });
    _gridFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  bool _readyView() {
    if (!_canChangeView()) {
      _blurGrid();
      return false;
    }
    return _clearFocusedCell(cancelCleanEdit: true);
  }

  bool _clearFocusedCell({bool cancelCleanEdit = false}) {
    if (_activeCellEditorState?.finalizeEditing() == false) {
      return false;
    }

    if (cancelCleanEdit) {
      final activeIndex = FdcDataSetInternal.activeIndex(widget.dataSet);
      if (activeIndex >= 0 && !_cancelCleanEditOrInsert(activeIndex)) {
        if (FdcDataSetInternal.hasDirtyEdit(widget.dataSet)) {
          return false;
        }
      }
    }

    _setGridState(() {
      _selectedCell = null;
      _selectedRowIndex = null;
      _editingCell = null;
      _editAtEndCell = null;
      _clearPendingEditText();
    });
    _gridFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    return true;
  }
}
