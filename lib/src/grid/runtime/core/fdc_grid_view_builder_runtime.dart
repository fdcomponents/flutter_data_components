// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateViewBuilders on _FdcGridState {
  FdcGridViewportCallbacks _createViewportCallbacks() {
    return FdcGridViewportCallbacks(
      onPointerSignal: _handlePointerSignal,
      onRangePointerCellChanged: _updateRangePointerHoverCell,
      onRangeDragStart: _startCellRangeFromPointer,
      onRangeDragUpdate: _updateCellRangeFromPointer,
      onRangeDragEnd: _endCellRangePointerDrag,
      onRangeOverlayDismiss: () => _clearCellRange(),
      onRangeSelectionCopy: () => unawaited(_copySelectedCellToClipboard()),
      onRangeSelectionPaste: () => unawaited(_pasteClipboardIntoSelectedCell()),
      onColumnScrollUpdate: _handleColumnScrollUpdate,
      onColumnScrollEnd: _handleColumnScrollEnd,
      onRowScrollStart: _handleRowScrollStart,
      onRowScrollUpdate: _handleRowScrollUpdate,
      onRowScrollEnd: _handleRowScrollEnd,
      onBodyVerticalDragStart: _handleBodyVerticalDragStart,
      onBodyVerticalDragUpdate: _handleBodyVerticalDragUpdate,
      onBodyVerticalDragEnd: _handleBodyVerticalDragEnd,
      onHeaderHorizontalDragStart: _handleHeaderHorizontalDragStart,
      onHeaderHorizontalDragUpdate: _handleHeaderHorizontalDragUpdate,
      onHeaderHorizontalDragEnd: _handleHeaderHorizontalDragEnd,
      onColumnResizeStart: _headerCallbacks.onColumnResizeStart,
      onColumnResizeUpdate: _headerCallbacks.onColumnResizeUpdate,
      onColumnResizeEnd: _headerCallbacks.onColumnResizeEnd,
      buildHeader: _buildHeader,
      buildRow: _buildRow,
      buildRowIndicatorRegionHeader: _buildRowIndicatorRegionHeader,
      buildRowIndicatorRegionRow: _buildRowIndicatorRegionRow,
      buildDetailRow: _buildDetailRow,
      onDetailRowSizeChanged: _handleDetailRowSizeChanged,
    );
  }

  Widget _buildGridViewport(
    BuildContext context, {
    required FdcValueFormatter valueFormatter,
    required FdcGridColumnBandLayouts columnBandLayouts,
    required FdcGridLayoutRegions layoutRegions,
    required double topInset,
    required double bottomInset,
    required double visibleRowsHeight,
    required double paintedGridWidth,
    required double centerViewportWidth,
    required double paintedGridHeight,
  }) {
    final gridLines = _gridLines();
    final horizontalGridLineColor = _styles.horizontalGridLineColor(_gridStyle);
    final verticalGridLineColor = _styles.verticalGridLineColor(_gridStyle);

    return FdcGridViewport(
      model: FdcGridViewportModel(
        columnBandLayouts: columnBandLayouts,
        valueFormatter: valueFormatter,
        layoutRegions: layoutRegions,
        defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
        rowHeight: widget.options.resolvedRowHeight,
        effectiveHeaderHeight: _effectiveHeaderHeight,
        headerFilterRowHeight: _showsHeaderFilterRow
            ? _headerFilterRowHeight
            : 0.0,
        topInset: topInset,
        bottomInset: bottomInset,
        visibleRowsHeight: visibleRowsHeight,
        paintedGridWidth: paintedGridWidth,
        centerViewportWidth: centerViewportWidth,
        paintedGridHeight: paintedGridHeight,
        rowsLength: _rows.length,
        expandedDetailRows: _expandedDetailRowIndices(),
        visibleDetailRows: _visibleDetailRowIndices(),
        detailRowHeight: _detailRowHeight,
        detailRowHeights: _expandedDetailRowHeights(),
        detailRowContentSized: _detailRowContentSized,
        backgroundColor: _gridBackgroundColor(),
        rowIndicatorBackgroundColor: _styles.rowIndicatorBackgroundColor(
          _gridStyle,
        ),
        headerSeparatorColor: _styles.headerSeparatorColor(
          _gridStyle,
          _headerStyle,
        ),
        gridLines: gridLines,
        options: widget.options,
        horizontalGridLineColor: horizontalGridLineColor,
        verticalGridLineColor: verticalGridLineColor,
        pinnedSeparatorColor: verticalGridLineColor,
        pinnedSeparatorInset: _resolveNonNegativeGridLineInset(
          _gridStyle.pinnedSeparatorInset,
        ),
        verticalLineExtent:
            _gridStyle.verticalGridLines ?? FdcGridVerticalLines.rowsOnly,
        scrollCoordinator: _scrollCoordinator,
        resizingRuntimeColumnId: _resizingRuntimeColumnId,
        resizingDeltaFactor: _ui.columnResize.globalResizeDeltaFactor,
        draggingColumnIndex: _draggingColumnIndex,
        hasActiveCellEditor: _editingCell != null,
        recordScroll:
            widget.options.verticalScrollMode ==
            FdcGridVerticalScrollMode.recordScroll,
        bodyKey: _runtime.domains.core.bodyViewportKey,
        selectedRangeBounds: _selectedRangeOverlayBounds(),
        rangeSelectionModifierActive: _rangeSelectionModifierActive,
        rangeSelectionCopyEnabled: _rangeSelectionCopyEnabled,
        rangeSelectionPasteEnabled: _rangeSelectionPasteEnabled,
        rangeSelectionContextMenuBuilder:
            widget.rangeSelection?.canShowContextMenu(_rangeSelectionHost) ==
                true
            ? _rangeSelectionSession.buildContextMenuEntries
            : null,
        rangeSelectionContainsCell: _rangeSelectionEnabled
            ? _rangeSelectionContainsCell
            : null,
        rangeSelectionOverlayBuilder: _rangeSelectionEnabled
            ? _rangeSelectionSession.buildOverlay
            : null,
        rangeOutlineStyle: _rangeSelectionEnabled
            ? FdcGridResolvedCellIndicatorStyle(
                color: widget.rangeSelection!.resolveBorderColor(
                  _rangeSelectionHost,
                ),
                thickness: widget.rangeSelection!.resolveBorderThickness(
                  _rangeSelectionHost,
                ),
              )
            : null,
        rangeBackgroundColor: _rangeSelectionEnabled
            ? widget.rangeSelection!.resolveBackgroundColor(_rangeSelectionHost)
            : null,
      ),
      callbacks: _viewportCallbacks,
    );
  }

  double _resolveNonNegativeGridLineInset(double? value) {
    return math.max(0.0, value ?? 0.0);
  }

  Widget _buildHeader(
    BuildContext context,
    FdcGridColumnBandLayout columnLayout,
  ) {
    return FdcGridHeaderShell(
      model: _buildHeaderModel(context, columnLayout),
      callbacks: _headerCallbacks,
    );
  }
}

extension _FdcRowIndicatorViewBuilders on _FdcGridState {
  Widget _buildRowIndicatorRegionHeader(BuildContext context, double width) {
    return FdcGridRowIndicatorHeader(
      model: _buildHeaderModel(context, FdcGridColumnBandLayout.empty),
      callbacks: _headerCallbacks,
      width: width,
    );
  }

  Widget _buildRowIndicatorRegionRow(
    BuildContext context,
    int rowIndex,
    double width,
  ) {
    return FdcGridRowIndicatorRow(
      width: width,
      rowHeight: widget.options.resolvedRowHeight,
      model: _buildRowIndicatorCellModel(context, rowIndex),
      interactionState: _interactionState,
      selectedRowBackgroundColor: _selectedRowBackgroundColor(),
      onTap: () => _activateRowIndicatorRow(rowIndex),
      onSelectedChanged: (selected) {
        _activateRowIndicatorSelectionRow(rowIndex);
        _setRowIndicatorSelected(rowIndex, selected);
      },
    );
  }
}
