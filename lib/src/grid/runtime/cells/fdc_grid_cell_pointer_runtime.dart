// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridCellPointerRuntime on _FdcGridState {
  T _runCellPointerViewportLocked<T>(
    T Function() action, {
    double? horizontalOffset,
    double? verticalOffset,
    int? settleFrameCount,
  }) {
    final horizontalOffsetToPreserve =
        horizontalOffset ?? _scrollCoordinator.liveHorizontalOffset;
    final verticalOffsetToPreserve =
        verticalOffset ?? _scrollCoordinator.liveVerticalOffset;

    _scrollCoordinator.beginHorizontalOffsetRestore(horizontalOffsetToPreserve);
    _scrollCoordinator.beginVerticalOffsetRestore(verticalOffsetToPreserve);
    _restoreHorizontalScrollOffsetNow(horizontalOffsetToPreserve);
    _restoreVerticalScrollOffsetNow(verticalOffsetToPreserve);

    try {
      return action();
    } finally {
      _restoreViewportOffsetsAfterLayout(
        horizontalOffset: horizontalOffsetToPreserve,
        verticalOffset: verticalOffsetToPreserve,
        settleAfterNextFrame: true,
        settleFrameCount: settleFrameCount,
        horizontalOffsetRestoreAlreadyLocked: true,
        verticalOffsetRestoreAlreadyLocked: true,
      );
    }
  }

  T _runMouseCellControlScrollGuarded<T>(
    T Function() action, {
    double? horizontalOffset,
    double? verticalOffset,
    int? suppressFrameCount,
  }) {
    final horizontalOffsetToPreserve =
        horizontalOffset ?? _scrollCoordinator.liveHorizontalOffset;
    final verticalOffsetToPreserve =
        verticalOffset ?? _scrollCoordinator.liveVerticalOffset;

    _scrollCoordinator.beginHorizontalOffsetRestore(horizontalOffsetToPreserve);
    _scrollCoordinator.beginVerticalJumpSuppression(verticalOffsetToPreserve);
    _restoreHorizontalScrollOffsetNow(horizontalOffsetToPreserve);

    try {
      return action();
    } finally {
      _restoreHorizontalOffsetAfterLayout(
        horizontalOffsetToPreserve,
        settleAfterNextFrame: true,
        settleFrameCount: suppressFrameCount,
        horizontalOffsetRestoreAlreadyLocked: true,
      );
      _endVerticalJumpSuppressionAfterLayout(
        frameCount: suppressFrameCount ?? 2,
      );
    }
  }

  void _endVerticalJumpSuppressionAfterLayout({required int frameCount}) {
    final framesToSettle = math.max(1, frameCount);

    void endFrame(int remainingFrames) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || remainingFrames <= 1) {
          _scrollCoordinator.endVerticalJumpSuppression();
          return;
        }

        endFrame(remainingFrames - 1);
      });
    }

    endFrame(framesToSettle);
  }

  void _handleCellTap(
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
  ) {
    _cancelDirectSelectionGuard();
    final previousCell = _selectedCell;
    final extendRange =
        _rangeSelectionEnabled && HardwareKeyboard.instance.isShiftPressed;
    if (!extendRange) {
      _clearCellRange();
    }
    final cell = _cellRef(rowIndex, columnIndex);
    if (!_unfocusActiveEditorBeforeCellChange(cell)) {
      return;
    }
    _selectCell(column, rowIndex, columnIndex);
    if (extendRange && previousCell != null) {
      _beginOrExtendCellRange(previousCell);
    }
    if (widget.detailRow?.toggleOnRowTap ?? false) {
      _toggleDetailRow(rowIndex);
    }
  }

  void _handleCellPointerTap(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
    Offset globalPosition,
  ) {
    _cancelDirectSelectionGuard();
    final visualResolution = _visualRowResolutionFromGlobalPosition(
      globalPosition,
    );
    final effectiveRowIndex = visualResolution.rowIndex ?? rowIndex;
    final cellLocalPosition = _cellLocalPosition(context, globalPosition);

    _notifyCellPointerEvent(
      widget.onCellTapDown,
      column: column,
      rowIndex: effectiveRowIndex,
      columnIndex: columnIndex,
      globalPosition: globalPosition,
      localPosition: cellLocalPosition ?? Offset.zero,
    );

    if (_hasCellControlPointerViewport(effectiveRowIndex, columnIndex)) {
      return;
    }

    _runCellPointerViewportLocked(() {
      final cell = _cellRef(effectiveRowIndex, columnIndex);
      final wasSelectedCell = _selectedCell == cell && _editingCell == null;
      final now = DateTime.now();
      final previousTapTime = _lastCellTapTime;
      final doubleTap =
          _lastTappedCell == cell &&
          previousTapTime != null &&
          now.difference(previousTapTime) <= fdcGridCellDoubleTapTimeout;

      if (_isDropdownEditor(column)) {
        if (wasSelectedCell || doubleTap) {
          if (doubleTap) {
            _notifyCellPointerEvent(
              widget.onCellDoubleTap,
              column: column,
              rowIndex: effectiveRowIndex,
              columnIndex: columnIndex,
              globalPosition: globalPosition,
              localPosition: cellLocalPosition ?? Offset.zero,
            );
          }
          _lastTappedCell = null;
          _lastCellTapTime = null;
          _openDropdownCell(column, effectiveRowIndex, columnIndex);
          return;
        }

        _lastTappedCell = cell;
        _lastCellTapTime = now;
        _handleCellTap(column, effectiveRowIndex, columnIndex);
        return;
      }

      _lastTappedCell = cell;
      _lastCellTapTime = now;

      if (doubleTap) {
        _notifyCellPointerEvent(
          widget.onCellDoubleTap,
          column: column,
          rowIndex: effectiveRowIndex,
          columnIndex: columnIndex,
          globalPosition: globalPosition,
          localPosition: cellLocalPosition ?? Offset.zero,
        );
        _lastTappedCell = null;
        _lastCellTapTime = null;
        if (widget.detailRow?.toggleOnRowTap ?? false) {
          _handleCellTap(column, effectiveRowIndex, columnIndex);
          return;
        }
        _handleCellDoubleTap(column, effectiveRowIndex, columnIndex);
        return;
      }

      _handleCellTap(column, effectiveRowIndex, columnIndex);
    });
  }

  void _notifyCellPointerEvent(
    FdcGridCellPointerEvent? callback, {
    required FdcGridColumn<dynamic> column,
    required int rowIndex,
    required int columnIndex,
    required Offset globalPosition,
    required Offset localPosition,
  }) {
    if (callback == null || rowIndex < 0 || rowIndex >= _rows.length) {
      return;
    }
    callback(
      FdcGridCellPointerContext(
        dataSet: widget.dataSet,
        row: _gridRowAt(rowIndex),
        column: column,
        rowIndex: rowIndex,
        columnIndex: columnIndex,
        recordId: _recordIdForGridRow(rowIndex),
        value: _dataSetFieldValueAt(rowIndex, column.fieldName),
        globalPosition: globalPosition,
        localPosition: localPosition,
      ),
    );
  }

  _FdcGridVisualRowResolution _visualRowResolutionFromGlobalPosition(
    Offset globalPosition,
  ) {
    if (widget.options.resolvedRowHeight <= 0) {
      return const _FdcGridVisualRowResolution(
        rowIndex: null,
        localPosition: null,
        viewportSize: null,
        reason: 'invalid-row-height',
      );
    }
    if (_rows.isEmpty) {
      return const _FdcGridVisualRowResolution(
        rowIndex: null,
        localPosition: null,
        viewportSize: null,
        reason: 'empty-rows',
      );
    }

    final viewportContext =
        _runtime.domains.core.bodyViewportKey.currentContext;
    final renderObject = viewportContext?.findRenderObject();
    if (renderObject is! RenderBox) {
      return const _FdcGridVisualRowResolution(
        rowIndex: null,
        localPosition: null,
        viewportSize: null,
        reason: 'missing-render-box',
      );
    }
    if (!renderObject.hasSize) {
      return const _FdcGridVisualRowResolution(
        rowIndex: null,
        localPosition: null,
        viewportSize: null,
        reason: 'render-box-has-no-size',
      );
    }

    final localPosition = renderObject.globalToLocal(globalPosition);
    if (localPosition.dy < 0 ||
        localPosition.dy >= renderObject.size.height ||
        localPosition.dx < 0 ||
        localPosition.dx >= renderObject.size.width) {
      return _FdcGridVisualRowResolution(
        rowIndex: null,
        localPosition: localPosition,
        viewportSize: renderObject.size,
        reason: 'outside-body-viewport',
      );
    }

    final contentOffset =
        localPosition.dy + _scrollCoordinator.liveVerticalOffset;
    final rowIndex = _gridRowIndexAtOffset(contentOffset);
    if (rowIndex < 0 || rowIndex >= _rows.length) {
      return _FdcGridVisualRowResolution(
        rowIndex: null,
        localPosition: localPosition,
        viewportSize: renderObject.size,
        reason:
            'resolved-row-out-of-range offset=${contentOffset.toStringAsFixed(3)}',
      );
    }

    return _FdcGridVisualRowResolution(
      rowIndex: rowIndex,
      localPosition: localPosition,
      viewportSize: renderObject.size,
      reason:
          'resolved offset=${contentOffset.toStringAsFixed(3)} '
          'rowTop=${_gridRowTop(rowIndex).toStringAsFixed(3)}',
    );
  }

  Offset? _cellLocalPosition(BuildContext context, Offset globalPosition) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return null;
    }
    return renderObject.globalToLocal(globalPosition);
  }

  void _captureCellControlPointerViewport(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
    Offset globalPosition,
  ) {
    _cancelDirectSelectionGuard();
    final viewport = _FdcGridCellControlPointerViewport(
      // The in-cell control is built for the exact grid row it represents.
      // Keep that row as the source of truth; mouse control callbacks can
      // run while the scrollable is still settling from a smooth wheel
      // interaction.
      rowIndex: rowIndex,
      columnIndex: columnIndex,
      horizontalOffset: _scrollCoordinator.liveHorizontalOffset,
      verticalOffset: _cellControlPointerVerticalOffset(context, rowIndex),
      capturedAt: DateTime.now(),
    );
    _ui.cells.interaction.cellControlPointerViewport = viewport;
  }

  double _cellControlPointerVerticalOffset(BuildContext context, int rowIndex) {
    final liveOffset = _scrollCoordinator.liveVerticalOffset;
    final visualOffset = _visualVerticalOffsetFromCellContext(
      context,
      rowIndex,
    );

    // Prefer the live controller offset so ordinary in-cell control clicks stay
    // completely inert vertically. The render-derived offset is only a fallback
    // when the first mouse action observes a transient zero-position controller.
    if (visualOffset == null) {
      return liveOffset;
    }

    if (liveOffset <= 0.5 && rowIndex >= math.max(1, _visibleRowCount)) {
      return visualOffset;
    }

    return liveOffset;
  }

  double? _visualVerticalOffsetFromCellContext(
    BuildContext context,
    int rowIndex,
  ) {
    if (widget.options.resolvedRowHeight <= 0 ||
        !_isLiveGridRowIndex(rowIndex)) {
      return null;
    }

    final bodyContext = _runtime.domains.core.bodyViewportKey.currentContext;
    final bodyObject = bodyContext?.findRenderObject();
    final cellObject = context.findRenderObject();
    if (bodyObject is! RenderBox ||
        cellObject is! RenderBox ||
        !bodyObject.hasSize ||
        !cellObject.hasSize) {
      return null;
    }

    final cellTopGlobal = cellObject.localToGlobal(Offset.zero);
    final cellTopLocal = bodyObject.globalToLocal(cellTopGlobal).dy;
    if (!cellTopLocal.isFinite) {
      return null;
    }

    final offset = _gridRowTop(rowIndex) - cellTopLocal;
    final layoutMaxOffset = math.max(
      0.0,
      _gridRowsContentHeight - _visibleRowsViewportHeight,
    );
    final maxOffset = math.max(
      _scrollCoordinator.verticalMaxScrollExtent,
      layoutMaxOffset,
    );
    return offset.clamp(0.0, math.max(maxOffset, offset)).toDouble();
  }

  bool _hasCellControlPointerViewport(int rowIndex, int columnIndex) {
    final snapshot = _ui.cells.interaction.cellControlPointerViewport;
    if (!_isFreshCellControlPointerViewport(snapshot) || snapshot == null) {
      return false;
    }
    return snapshot.rowIndex == rowIndex &&
        snapshot.columnIndex == columnIndex &&
        _isLiveGridRowIndex(snapshot.rowIndex);
  }

  bool _isFreshCellControlPointerViewport(
    _FdcGridCellControlPointerViewport? snapshot,
  ) {
    if (snapshot == null) {
      return false;
    }
    return DateTime.now().difference(snapshot.capturedAt) <=
        const Duration(seconds: 2);
  }

  _FdcGridCellControlPointerViewport? _takeCellControlPointerViewport(
    int rowIndex,
    int columnIndex,
  ) {
    final snapshot = _ui.cells.interaction.cellControlPointerViewport;
    _ui.cells.interaction.cellControlPointerViewport = null;
    if (!_isFreshCellControlPointerViewport(snapshot) || snapshot == null) {
      return null;
    }
    if (snapshot.columnIndex != columnIndex) {
      return null;
    }
    if (!_isLiveGridRowIndex(snapshot.rowIndex)) {
      return null;
    }
    return snapshot;
  }

  void _cancelDirectSelectionGuard() {
    _verticalSettleGeneration++;
    // A direct cell click/tap is an explicit selection command. Pending
    // record-scroll settle timers from a preceding drag must not run after the
    // tap and move the active record to the viewport center, which is most
    // visible in manually rendered pinned regions.
    _pendingScrollbarSelectionRowIndex = null;
    _scroll.cancelVerticalSnap();
    if (_scroll.verticalDragActive) {
      _scroll.clearVerticalScrollOrigin();
    }
  }

  void _clearDraggingColumn(int columnIndex) {
    if (_draggingColumnIndex == null) {
      return;
    }

    _invalidDropTargetHoverNotifier.value = false;
    _setGridState(() {
      _draggingColumnIndex = null;
      _clearLiveSwapTargetBlock();
      _clearLiveSwapLock();
      _invalidColumnDropTargetHovering = false;
    });
  }

  bool _unfocusActiveEditorBeforeCellChange(FdcGridCellRef cell) {
    final editingCell = _editingCell;
    if (editingCell == null || editingCell == cell) {
      return true;
    }

    if (_activeCellEditorState?.finalizeEditing() == false) {
      return false;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    return true;
  }

  void _selectCell(
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
  ) {
    final cell = _cellRef(rowIndex, columnIndex);
    final current = _editingCell ?? _selectedCell;
    final preferLeadingColumnContext = current?.rowIndex != rowIndex;
    if (!_postCurrentRowIfLeaving(
      rowIndex,
      continueToCellAfterImmediatePost: cell,
      preferLeadingColumnContext: preferLeadingColumnContext,
      focusReasonAfterImmediatePost: FdcGridFocusChangeReason.mouse,
    )) {
      return;
    }
    _activateCell(
      cell,
      editIfPossible: false,
      revealColumn: false,
      focusReason: FdcGridFocusChangeReason.mouse,
    );
  }

  bool _activateActionRow(int rowIndex, int? recordId, int columnIndex) {
    final liveRowIndex = _resolveLiveRowIndex(rowIndex, recordId);
    if (!_isLiveGridRowIndex(liveRowIndex)) {
      _refreshRowsAndValidateState();
      return false;
    }
    final column = columnIndex >= 0 && columnIndex < _visibleColumns.length
        ? _visibleColumns[columnIndex]
        : null;
    if (column == null) {
      return false;
    }
    if (!_postCurrentRowIfLeaving(liveRowIndex)) {
      return false;
    }
    _activateCell(
      _cellRef(liveRowIndex, columnIndex),
      editIfPossible: false,
      revealColumn: false,
      focusReason: FdcGridFocusChangeReason.mouse,
    );
    return true;
  }

  bool _deleteActionRow(int rowIndex, int? recordId, int columnIndex) {
    if (widget.options.readOnly ||
        FdcDataSetInternal.isReadOnly(widget.dataSet) ||
        _showingDeleteConfirmDialog) {
      return false;
    }

    final liveRowIndex = _resolveLiveRowIndex(rowIndex, recordId);
    if (!_isLiveGridRowIndex(liveRowIndex)) {
      _refreshRowsAndValidateState();
      return false;
    }
    if (!_postCurrentRowIfLeaving(liveRowIndex)) {
      return false;
    }

    if (widget.options.confirmDelete &&
        widget.dataSet.state != FdcDataSetState.insert) {
      unawaited(
        _confirmAndDeleteActionRow(liveRowIndex, recordId, columnIndex),
      );
      return true;
    }

    return _deleteActionRowCore(liveRowIndex, recordId, columnIndex);
  }

  Future<void> _confirmAndDeleteActionRow(
    int rowIndex,
    int? recordId,
    int columnIndex,
  ) async {
    if (_showingDeleteConfirmDialog || !mounted) {
      return;
    }

    _showingDeleteConfirmDialog = true;
    var confirmed = false;
    try {
      final translations = FdcApp.translationsOf(context);
      confirmed = await showFdcConfirmationDialog(
        context,
        title: translations.dialogs.confirmDelete,
        message: translations.dialogs.deleteCurrentRecord,
        yesText: translations.common.delete,
        noText: translations.common.cancel,
      );
    } on Object catch (_) {
      confirmed = false;
    } finally {
      _showingDeleteConfirmDialog = false;
    }

    if (!mounted) {
      return;
    }

    if (!confirmed) {
      _focusGridForSelectedCell();
      return;
    }

    _deleteActionRowCore(rowIndex, recordId, columnIndex);
  }

  bool _deleteActionRowCore(int rowIndex, int? recordId, int columnIndex) {
    final liveRowIndex = _resolveLiveRowIndex(rowIndex, recordId);
    if (!_isLiveGridRowIndex(liveRowIndex)) {
      _refreshRowsAndValidateState();
      return false;
    }

    final sourceIndex = _sourceRowIndex(liveRowIndex);
    if (sourceIndex == null ||
        sourceIndex < 0 ||
        sourceIndex >= widget.dataSet.recordCount) {
      _refreshRowsAndValidateState();
      return false;
    }

    _updatingDataSetFromGrid = true;
    try {
      if (FdcDataSetInternal.activeIndex(widget.dataSet) != sourceIndex) {
        FdcDataSetInternal.moveToIndex(widget.dataSet, sourceIndex);
      }
      if (FdcDataSetInternal.activeIndex(widget.dataSet) != sourceIndex) {
        _syncInteractionState();
        _showGridOperationErrorsIfNeeded();
        return false;
      }
      widget.dataSet.delete();
    } on Object catch (error, stackTrace) {
      unawaited(_handleDataSetPostError(error, stackTrace));
      return false;
    } finally {
      _updatingDataSetFromGrid = false;
    }

    if (widget.dataSet.errors.messages.isNotEmpty) {
      _syncInteractionState();
      _showGridOperationErrorsIfNeeded();
      return false;
    }

    _setGridState(() {
      _refreshRowsFromDataSet();
      _validateCellState();
      _syncGridSelectionFromDataSetCurrent(preferredColumnIndex: columnIndex);
      _rememberDeleteSelectionRestore();
    });
    _focusGridForSelectedCellAfterLayout();
    return true;
  }

  void _handleCellDoubleTap(
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
  ) {
    final cell = _cellRef(rowIndex, columnIndex);
    if (!_unfocusActiveEditorBeforeCellChange(cell)) {
      return;
    }
    final current = _editingCell ?? _selectedCell;
    final preferLeadingColumnContext = current?.rowIndex != rowIndex;
    if (!_postCurrentRowIfLeaving(
      rowIndex,
      continueToCellAfterImmediatePost: cell,
      editIfPossibleAfterImmediatePost: true,
      preferLeadingColumnContext: preferLeadingColumnContext,
      focusReasonAfterImmediatePost: FdcGridFocusChangeReason.mouse,
    )) {
      return;
    }
    _activateCell(
      cell,
      editIfPossible: true,
      placeCursorAtEnd: true,
      revealColumn: false,
      focusReason: FdcGridFocusChangeReason.mouse,
    );
  }
}

class _FdcGridVisualRowResolution {
  const _FdcGridVisualRowResolution({
    required this.rowIndex,
    required this.localPosition,
    required this.viewportSize,
    required this.reason,
  });

  final int? rowIndex;
  final Offset? localPosition;
  final Size? viewportSize;
  final String reason;
}
