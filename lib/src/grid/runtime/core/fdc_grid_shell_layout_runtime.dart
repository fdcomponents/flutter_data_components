// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Resolved shell layout values for a single grid build pass.
///
/// The build runtime composes widgets; this object keeps the shell sizing,
/// column-band layout, and viewport extents calculated by the layout runtime.
class _FdcGridShellLayout {
  const _FdcGridShellLayout({
    required this.gridHeight,
    required this.toolbarHeight,
    required this.summaryRowHeight,
    required this.statusBarHeight,
    required this.gridViewportHeight,
    required this.viewportWidth,
    required this.topInset,
    required this.bottomInset,
    required this.visibleRowsHeight,
    required this.paintedGridWidth,
    required this.centerViewportWidth,
    required this.columnBandLayouts,
    required this.layoutRegions,
  });

  final double gridHeight;
  final double toolbarHeight;
  final double summaryRowHeight;
  final double statusBarHeight;
  final double gridViewportHeight;
  final double viewportWidth;
  final double topInset;
  final double bottomInset;
  final double visibleRowsHeight;
  final double paintedGridWidth;
  final double centerViewportWidth;
  final FdcGridColumnBandLayouts columnBandLayouts;
  final FdcGridLayoutRegions layoutRegions;
}

extension _FdcGridShellLayoutRuntime on _FdcGridState {
  _FdcGridShellLayout _resolveGridShellLayout(
    BoxConstraints constraints, {
    required double resolvedToolbarHeight,
    required double resolvedSummaryRowHeight,
    required double resolvedStatusBarHeight,
  }) {
    final gridHeight = _resolveGridHeight(
      constraints,
      resolvedToolbarHeight: resolvedToolbarHeight,
      resolvedSummaryRowHeight: resolvedSummaryRowHeight,
      resolvedStatusBarHeight: resolvedStatusBarHeight,
    );
    var remainingContentHeight = gridHeight;
    final toolbarHeight = widget.toolbar.visible
        ? math.min(resolvedToolbarHeight, remainingContentHeight)
        : 0.0;
    remainingContentHeight = math.max(
      0.0,
      remainingContentHeight - toolbarHeight,
    );
    final statusBarHeight = widget.statusBar.visible
        ? math.min(resolvedStatusBarHeight, remainingContentHeight)
        : 0.0;
    remainingContentHeight = math.max(
      0.0,
      remainingContentHeight - statusBarHeight,
    );
    final summaryRowHeight = _showsSummaryRow
        ? math.min(resolvedSummaryRowHeight, remainingContentHeight)
        : 0.0;
    final gridViewportHeight = math.max(
      0.0,
      gridHeight - toolbarHeight - summaryRowHeight - statusBarHeight,
    );
    final headerHeight = _effectiveHeaderHeight;
    final bodyHeight = math.max(0.0, gridViewportHeight - headerHeight);
    final verticalInset = bodyHeight > 0
        ? math.min(fdcGridFrameInset * 2, bodyHeight)
        : 0.0;
    final topInset = math.min(fdcGridFrameInset, verticalInset / 2);
    final bottomInset = verticalInset - topInset;
    final rowIndicatorLayout = _rowIndicatorLayout;
    final rowIndicatorWidth = rowIndicatorLayout.isVisible
        ? rowIndicatorLayout.width
        : 0.0;

    _columnSizing.syncRuntimeColumns(
      columns: _visibleColumnsCache,
      runtimeColumnIds: _visibleRuntimeColumnIdsCache,
      defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
    );
    final baseGridWidth = _baseScrollableDataWidth();
    final basePinnedDataWidth = _basePinnedDataWidth();
    final viewportWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : baseGridWidth + basePinnedDataWidth + rowIndicatorWidth;

    // Auto/effective column widths must be resolved against the center
    // scrollable viewport only. Pinned regions are outside the horizontal
    // scroll band, so including their width here makes auto/filler math
    // inflate the trailing scrollable column after horizontal scroll or
    // manual resize.
    final provisionalScrollableViewportWidth = constraints.hasBoundedWidth
        ? math.max(0.0, viewportWidth - rowIndicatorWidth - basePinnedDataWidth)
        : null;
    final scrollableSizingBand = _columnBandsCache.scrollable;
    _refreshEffectiveColumnWidthsIfNeeded(
      provisionalScrollableViewportWidth,
      columns: scrollableSizingBand.columns,
      runtimeColumnIds: scrollableSizingBand.runtimeColumnIds,
    );
    final rawColumnBandLayouts = _columnBandLayouts();
    final pinnedDataWidth =
        rawColumnBandLayouts.pinnedLeftWidth +
        rawColumnBandLayouts.pinnedRightWidth;
    final scrollableViewportWidth = constraints.hasBoundedWidth
        ? math.max(0.0, viewportWidth - rowIndicatorWidth - pinnedDataWidth)
        : null;

    // Resolve the complete horizontal projection once per shell layout pass.
    // Header, filter, body, summary, hit testing, and resize rendering all
    // receive this exact immutable band layout instead of independently
    // stretching/reprojecting the center band.
    final resolvedCenterViewportWidth =
        scrollableViewportWidth ?? rawColumnBandLayouts.scrollableWidth;
    final resolvedCenterContentWidth = _scrollCoordinator
        .effectiveHorizontalContentWidth(
          math.max(
            rawColumnBandLayouts.scrollableWidth,
            resolvedCenterViewportWidth,
          ),
          viewportWidth: resolvedCenterViewportWidth,
        );
    final resolvedScrollableLayout = rawColumnBandLayouts.pinnedRight.isNotEmpty
        ? rawColumnBandLayouts.scrollable.stretchLastColumnToWidth(
            resolvedCenterContentWidth,
          )
        : rawColumnBandLayouts.scrollable;
    final columnBandLayouts = FdcGridColumnBandLayouts(
      pinnedLeft: rawColumnBandLayouts.pinnedLeft,
      scrollable: resolvedScrollableLayout,
      pinnedRight: rawColumnBandLayouts.pinnedRight,
    );
    final paintedGridWidth = columnBandLayouts.scrollableWidth;
    final layoutRegions = FdcGridLayoutRegions.fromColumnBandLayouts(
      rowIndicator: rowIndicatorLayout,
      columnBandLayouts: columnBandLayouts,
    );
    final availableRowsHeight = math.max(
      0.0,
      bodyHeight - topInset - bottomInset,
    );
    final visibleRowsHeight = _resolveVisibleRowsViewportHeight(
      availableRowsHeight,
    );
    final visibleRows = widget.options.resolvedRowHeight <= 0
        ? _rows.length
        : (visibleRowsHeight / widget.options.resolvedRowHeight).floor();
    _visibleRowCount = visibleRows < 1 ? 1 : visibleRows;
    _visibleRowsViewportHeight = visibleRowsHeight;
    _scrollCoordinator.updateVerticalLayoutExtents(
      viewportDimension: visibleRowsHeight,
      contentExtent: _gridRowsContentHeight,
    );

    return _FdcGridShellLayout(
      gridHeight: gridHeight,
      toolbarHeight: toolbarHeight,
      summaryRowHeight: summaryRowHeight,
      statusBarHeight: statusBarHeight,
      gridViewportHeight: gridViewportHeight,
      viewportWidth: viewportWidth,
      topInset: topInset,
      bottomInset: bottomInset,
      visibleRowsHeight: visibleRowsHeight,
      paintedGridWidth: paintedGridWidth,
      centerViewportWidth: resolvedCenterViewportWidth,
      columnBandLayouts: columnBandLayouts,
      layoutRegions: layoutRegions,
    );
  }
}
