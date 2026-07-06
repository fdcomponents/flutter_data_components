// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateColumnLayoutRuntime on _FdcGridState {
  bool _hasUserPinnedColumns() {
    if (!widget.pinning.enabled) {
      return false;
    }

    for (var index = 0; index < _visibleRuntimeColumnIdsCache.length; index++) {
      final runtimeColumnId = _visibleRuntimeColumnIdsCache[index];
      final overridePin = _runtimeColumnPinOverrides[runtimeColumnId];
      if (overridePin == null || !overridePin.isPinned) {
        continue;
      }
      final column = _visibleColumns[index];
      if (overridePin != column.pin) {
        return true;
      }
    }
    return false;
  }

  void _unpinAllUserColumns() {
    if (!_hasUserPinnedColumns()) {
      return;
    }

    final horizontalOffsetToPreserve =
        _scrollCoordinator.currentHorizontalOffset;

    _beginColumnBandTransaction(preserveHorizontalOffset: true);

    _setGridState(() {
      for (
        var index = 0;
        index < _visibleRuntimeColumnIdsCache.length;
        index++
      ) {
        final runtimeColumnId = _visibleRuntimeColumnIdsCache[index];
        final overridePin = _runtimeColumnPinOverrides[runtimeColumnId];
        if (overridePin == null || !overridePin.isPinned) {
          continue;
        }
        final column = _visibleColumns[index];
        if (overridePin != column.pin) {
          _runtimeColumnPinOverrides.remove(runtimeColumnId);
        }
      }
      _refreshColumnBandsCache();
      _columnSizing.syncRuntimeColumns(
        columns: _visibleColumnsCache,
        runtimeColumnIds: _visibleRuntimeColumnIdsCache,
        defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
      );
    });

    _restoreHorizontalOffsetAfterLayout(
      horizontalOffsetToPreserve,
      settleAfterNextFrame: true,
    );
    _notifyGridLayoutChanged();
  }

  bool _hasGridLayoutChanges() {
    return _runtimeColumnVisibilityOverrides.isNotEmpty ||
        _runtimeColumnPinOverrides.isNotEmpty ||
        _runtimeSummaryAggregateOverrides.isNotEmpty ||
        _hasRuntimeColumnOrderChanges() ||
        _columnSizing.hasUserColumnWidths ||
        _showColumnFilters != _headerFiltersInitiallyVisible;
  }

  void _beginColumnBandTransaction({bool preserveHorizontalOffset = false}) {
    // Pinning/unpinning moves columns between the center scrollable band and
    // the fixed pinned bands. Treat that as a full column-band transaction:
    // old suspended viewport autosize state belongs to the previous band model
    // and can visually desynchronize widths for one frame, especially when
    // pinning to the right while horizontally scrolled.
    //
    // Most layout-reset operations intentionally move to the leading edge, but
    // interactive pin/unpin should preserve the user's current horizontal
    // viewport just like reorder, sort, and filter operations do.
    _scroll.cancelHorizontalSnap();
    if (!preserveHorizontalOffset) {
      _scrollCoordinator.jumpHorizontalToStart();
    }
    _columnSizing.resetAutoSize();
    _lastColumnWidthViewport = null;
    _markColumnWidthsDirty();
    _resyncScrollAfterBandTransaction();
  }

  void _resyncScrollAfterBandTransaction() {
    if (widget.options.verticalScrollMode !=
        FdcGridVerticalScrollMode.recordScroll) {
      return;
    }

    // Pinning/unpinning rebuilds the split viewport: the center body owns the
    // real ListView, while pinned body bands render rows from the coordinator's
    // cached vertical offset. Resync that cache after the new layout attaches
    // so wheel input over pinned bands starts from the same record position as
    // the center body.
    _pendingScrollbarSelectionRowIndex = null;
    _scroll.cancelVerticalSnap();
    _scroll.clearVerticalScrollOrigin();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.options.verticalScrollMode !=
              FdcGridVerticalScrollMode.recordScroll) {
        return;
      }
      _scrollCoordinator.syncVerticalOffsetFromAttachedPosition();
      _snapVerticalScrollOffset();
    });
  }

  bool _hasRuntimeColumnOrderChanges() {
    if (!_hasUserColumnOrderOverride) {
      return false;
    }
    if (_visibleRuntimeColumnIdsCache.length !=
        _declarativeRuntimeColumnIdsCache.length) {
      return true;
    }
    for (var index = 0; index < _visibleRuntimeColumnIdsCache.length; index++) {
      if (_visibleRuntimeColumnIdsCache[index] !=
          _declarativeRuntimeColumnIdsCache[index]) {
        return true;
      }
    }
    return false;
  }

  void _resetGridLayout() {
    if (!_hasGridLayoutChanges()) {
      return;
    }

    final selectedRuntimeColumnId = _cells.runtimeColumnIdForCell(
      _selectedCell,
      _visibleRuntimeColumnIdsCache,
    );
    final editingRuntimeColumnId = _cells.runtimeColumnIdForCell(
      _editingCell,
      _visibleRuntimeColumnIdsCache,
    );
    final pendingRuntimeColumnId = _cells.runtimeColumnIdForCell(
      _pendingEditCell,
      _visibleRuntimeColumnIdsCache,
    );
    final editAtEndRuntimeColumnId = _cells.runtimeColumnIdForCell(
      _editAtEndCell,
      _visibleRuntimeColumnIdsCache,
    );

    // Reset is a full layout transaction: column order, pin overrides, user
    // widths, and viewport autosize state all return to their declarative
    // defaults. Keep the horizontal viewport out of the transaction by moving
    // it to the leading edge before and after the relayout. Otherwise an old
    // scroll offset can be applied to a freshly reset column model for one
    // frame, which visually desynchronizes header/body columns.
    _scroll.cancelHorizontalSnap();
    _scrollCoordinator.jumpHorizontalToStart();

    _setGridState(() {
      _runtimeColumnVisibilityOverrides.clear();
      _runtimeColumnPinOverrides.clear();
      _runtimeSummaryAggregateOverrides.clear();
      _summaryDisplayedValueCache.clear();
      _summaryAggregateValueCache.clear();
      _runtimeColumnOrderIds.clear();
      _hasUserColumnOrderOverride = false;
      _columnSizing.resetUserColumnWidths();
      _lastColumnWidthViewport = null;
      _showColumnFilters = _headerFiltersInitiallyVisible;
      _refreshColumnCache();
      _markColumnWidthsDirty();

      _selectedCell = _enrichCellRef(
        _cells.cellForRuntimeColumnId(
          _selectedCell,
          selectedRuntimeColumnId,
          _visibleRuntimeColumnIdsCache,
        ),
      );
      _editingCell = _enrichCellRef(
        _cells.cellForRuntimeColumnId(
          _editingCell,
          editingRuntimeColumnId,
          _visibleRuntimeColumnIdsCache,
        ),
      );
      _editAtEndCell = _enrichCellRef(
        _cells.cellForRuntimeColumnId(
          _editAtEndCell,
          editAtEndRuntimeColumnId,
          _visibleRuntimeColumnIdsCache,
        ),
      );
      _pendingEditCell = _enrichCellRef(
        _cells.cellForRuntimeColumnId(
          _pendingEditCell,
          pendingRuntimeColumnId,
          _visibleRuntimeColumnIdsCache,
        ),
      );
    });

    _scrollToFirstColumnAfterLayout();
    _notifyGridLayoutChanged();
  }

  void _setHeaderColumnPin(int columnIndex, FdcGridColumnPin pin) {
    if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
      return;
    }

    final runtimeColumnId = _runtimeColumnIdAt(columnIndex);
    if (runtimeColumnId == null) {
      return;
    }

    final column = _visibleColumns[columnIndex];
    if (_isGroupedColumn(column)) {
      return;
    }
    if (column.pin.isFixed && pin != column.pin) {
      return;
    }

    final currentPin = _effectiveColumnPin(column, runtimeColumnId);
    if (currentPin == pin) {
      return;
    }

    final horizontalOffsetToPreserve =
        _scrollCoordinator.currentHorizontalOffset;

    _beginColumnBandTransaction(preserveHorizontalOffset: true);

    _setGridState(() {
      if (pin == column.pin) {
        _runtimeColumnPinOverrides.remove(runtimeColumnId);
      } else {
        _runtimeColumnPinOverrides[runtimeColumnId] = pin;
      }
      _refreshColumnBandsCache();
      _columnSizing.syncRuntimeColumns(
        columns: _visibleColumnsCache,
        runtimeColumnIds: _visibleRuntimeColumnIdsCache,
        defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
      );
    });

    _restoreHorizontalOffsetAfterLayout(
      horizontalOffsetToPreserve,
      settleAfterNextFrame: true,
    );
    _notifyGridLayoutChanged();
  }

  void _swapDraggingColumnWithTarget(int targetIndex) {
    final fromIndex = _draggingColumnIndex;
    if (fromIndex == null) {
      return;
    }
    if (targetIndex < 0 ||
        targetIndex >= _visibleRuntimeColumnIdsCache.length) {
      return;
    }

    final targetRuntimeColumnId = _visibleRuntimeColumnIdsCache[targetIndex];
    final draggingRuntimeColumnId = _visibleRuntimeColumnIdsCache[fromIndex];

    if (fromIndex == targetIndex) {
      _pendingSwapTargetColumnId = null;
      return;
    }

    if (_liveSwapLocked) {
      // While a swap animation is settling, remember the last target under the
      // pointer instead of swapping immediately. The just-swapped column remains
      // cooldown-blocked only for a short period, so it cannot ping-pong during
      // the unsafe animation window but becomes a valid target again after a
      // deliberate pause and a fresh hover event.
      final blockedTargetRuntimeColumnId =
          _ui.header.interaction.liveSwapBlockedTargetRuntimeColumnId;
      if (targetRuntimeColumnId == draggingRuntimeColumnId ||
          targetRuntimeColumnId == blockedTargetRuntimeColumnId) {
        _pendingSwapTargetColumnId = null;
      } else {
        _pendingSwapTargetColumnId = targetRuntimeColumnId;
      }
      return;
    }

    _pendingSwapTargetColumnId = null;
    if (_ui.header.interaction.liveSwapBlockedTargetRuntimeColumnId ==
        targetRuntimeColumnId) {
      return;
    }

    _moveColumn(fromIndex, targetIndex);
    _blockLiveSwapTarget(targetRuntimeColumnId);
    _lockLiveSwapUntilAnimationEnds();
  }

  void _flushPendingLiveSwapHoverTarget() {
    if (!mounted || _draggingColumnIndex == null) {
      _pendingSwapTargetColumnId = null;
      return;
    }

    final targetRuntimeColumnId = _pendingSwapTargetColumnId;
    if (targetRuntimeColumnId == null) {
      return;
    }

    _pendingSwapTargetColumnId = null;
    final targetIndex = _visibleRuntimeColumnIdsCache.indexOf(
      targetRuntimeColumnId,
    );
    if (targetIndex == -1) {
      return;
    }

    _swapDraggingColumnWithTarget(targetIndex);
  }

  void _moveColumn(int fromIndex, int toIndex) {
    final columns = _visibleColumns;
    if (!widget.options.allowColumnReordering ||
        fromIndex == toIndex ||
        fromIndex < 0 ||
        fromIndex >= columns.length ||
        toIndex < 0 ||
        toIndex >= columns.length) {
      return;
    }

    final horizontalOffsetToPreserve =
        _scrollCoordinator.currentHorizontalOffset;
    final selectedRuntimeColumnId = _cells.runtimeColumnIdForCell(
      _selectedCell,
      _visibleRuntimeColumnIdsCache,
    );
    final editingRuntimeColumnId = _cells.runtimeColumnIdForCell(
      _editingCell,
      _visibleRuntimeColumnIdsCache,
    );
    final pendingRuntimeColumnId = _cells.runtimeColumnIdForCell(
      _pendingEditCell,
      _visibleRuntimeColumnIdsCache,
    );
    final editAtEndRuntimeColumnId = _cells.runtimeColumnIdForCell(
      _editAtEndCell,
      _visibleRuntimeColumnIdsCache,
    );

    _setGridState(() {
      final target = _visibleColumnsCache[toIndex];
      _visibleColumnsCache[toIndex] = _visibleColumnsCache[fromIndex];
      _visibleColumnsCache[fromIndex] = target;
      final targetId = _visibleRuntimeColumnIdsCache[toIndex];
      _visibleRuntimeColumnIdsCache[toIndex] =
          _visibleRuntimeColumnIdsCache[fromIndex];
      _visibleRuntimeColumnIdsCache[fromIndex] = targetId;
      if (_draggingColumnIndex == fromIndex) {
        _draggingColumnIndex = toIndex;
      } else if (_draggingColumnIndex == toIndex) {
        _draggingColumnIndex = fromIndex;
      }
      _runtimeColumnOrderIds
        ..clear()
        ..addAll(_visibleRuntimeColumnIdsCache);
      _hasUserColumnOrderOverride = true;
      _refreshColumnBandsCache();
      _columnSizing.syncRuntimeColumns(
        columns: _visibleColumnsCache,
        runtimeColumnIds: _visibleRuntimeColumnIdsCache,
        defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
      );
      _markColumnWidthsDirty();
      _selectedCell = _enrichCellRef(
        _cells.cellForRuntimeColumnId(
          _selectedCell,
          selectedRuntimeColumnId,
          _visibleRuntimeColumnIdsCache,
        ),
      );
      _editingCell = _enrichCellRef(
        _cells.cellForRuntimeColumnId(
          _editingCell,
          editingRuntimeColumnId,
          _visibleRuntimeColumnIdsCache,
        ),
      );
      _editAtEndCell = _enrichCellRef(
        _cells.cellForRuntimeColumnId(
          _editAtEndCell,
          editAtEndRuntimeColumnId,
          _visibleRuntimeColumnIdsCache,
        ),
      );
      _pendingEditCell = _enrichCellRef(
        _cells.cellForRuntimeColumnId(
          _pendingEditCell,
          pendingRuntimeColumnId,
          _visibleRuntimeColumnIdsCache,
        ),
      );
    });

    _restoreHorizontalOffsetAfterLayout(horizontalOffsetToPreserve);
    _notifyGridLayoutChanged();
  }
}

extension _FdcColumnGeometryDebug on _FdcGridState {
  int _columnIndexForRuntimeColumnId(
    FdcColumnIdentity runtimeColumnId, {
    required int fallbackColumnIndex,
  }) {
    final index = _visibleRuntimeColumnIdsCache.indexOf(runtimeColumnId);
    if (index != -1) {
      return index;
    }
    return fallbackColumnIndex;
  }

  double _columnWidthForRuntimeColumnId(
    FdcColumnIdentity runtimeColumnId, {
    required int fallbackColumnIndex,
  }) {
    final layouts = _columnBandLayouts();
    for (final layout in [
      layouts.pinnedLeft,
      layouts.scrollable,
      layouts.pinnedRight,
    ]) {
      final localIndex = layout.runtimeColumnIds.indexOf(runtimeColumnId);
      if (localIndex != -1) {
        return layout.columnWidthAt(
          localIndex,
          fallbackWidth: widget.options.resolvedDefaultColumnWidth,
        );
      }
    }
    if (fallbackColumnIndex >= 0 &&
        fallbackColumnIndex < _visibleColumns.length) {
      return _columnWidthAt(fallbackColumnIndex);
    }
    return widget.options.resolvedDefaultColumnWidth;
  }
}
