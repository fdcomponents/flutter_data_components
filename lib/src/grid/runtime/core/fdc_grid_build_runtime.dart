// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridBuildRuntime on _FdcGridState {
  Widget _buildGridRuntime(BuildContext context) {
    _gridTheme = FdcGridTheme.resolveData(context, widget.theme);
    _gridStyle = FdcGridTheme.resolveGridStyle(
      context,
      widget.theme,
      widget.style,
    );
    _headerStyle = _styles.headerStyle(
      context,
      widget.header,
      theme: _gridTheme,
    );
    _cellBackgroundColorCache.clear();
    _cellTextStyleCache.clear();

    final gridContent = TapRegion(
      groupId: fdcGridTapRegionGroup,
      onTapOutside: (_) {
        _blurGrid();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final toolbarStyle = _styles.toolbarStyle(
            context,
            _gridStyle,
            widget.toolbar,
            widget.header,
            _headerStyle,
            theme: _gridTheme,
          );
          final resolvedToolbarHeight = math.max(
            0.0,
            toolbarStyle.height ?? FdcGridToolbarStyle.defaultHeight,
          );
          final summaryRowStyle = _styles.summaryRowStyle(
            context,
            _gridStyle,
            widget.summary,
            theme: _gridTheme,
            rowHeight: widget.options.resolvedRowHeight,
          );
          final resolvedSummaryRowHeight = math.max(
            0.0,
            summaryRowStyle.height ?? widget.options.resolvedRowHeight,
          );
          final statusBarStyle = _styles.statusBarStyle(
            context,
            _gridStyle,
            widget.header,
            _headerStyle,
            widget.statusBar,
            theme: _gridTheme,
          );
          final statusBarProgressBarStyle = _styles.statusBarProgressBarStyle(
            context,
            widget.statusBar,
            theme: _gridTheme,
          );
          final horizontalGridLineColor = _styles.horizontalGridLineColor(
            _gridStyle,
          );
          final resolvedStatusBarHeight = math.max(
            0.0,
            widget.statusBar.height ??
                statusBarStyle.height ??
                FdcGridStatusBarStyle.defaultHeight,
          );
          final summaryVerticalGridLineColor = _styles.verticalGridLineColor(
            _gridStyle,
          );
          final showSummaryVerticalGridLines =
              (summaryRowStyle.showVerticalSeparators ?? true) &&
              _styles.showVerticalGridLines(_gridStyle);
          final toolbarShell = widget.toolbar.visible
              ? FdcGridToolbarShell(
                  searchController: _runtime.domains.toolbar.searchController,
                  style: toolbarStyle,
                  separatorColor: horizontalGridLineColor,
                  toolbar: widget.toolbar,
                  onSearchChanged: _handleToolbarSearchChanged,
                  onSearchCleared: _handleToolbarSearchCleared,
                  recordCountProvider: () => widget.dataSet.recordCount,
                  dataSet: widget.dataSet,
                  canSearch: _canSearch(),
                  canExport: _canExport(),
                  headerCallbacks: _headerCallbacks,
                  onExportRequested: _handleToolbarExportRequested,
                )
              : null;
          final statusBarShell = widget.statusBar.visible
              ? FdcGridStatusBarShell(
                  dataSet: widget.dataSet,
                  statusBar: widget.statusBar,
                  style: statusBarStyle,
                  separatorColor: horizontalGridLineColor,
                  progressBarStyle: statusBarProgressBarStyle,
                )
              : null;
          final runtimeSummaryAggregateOverrides =
              _runtimeSummaryAggregateOverrides.keys.toSet();
          final canEditSummary = _canChangeView();

          return ValueListenableBuilder<int>(
            valueListenable: _columnResizeLiveLayoutRevision,
            builder: (context, _, _) {
              // Keep the older counter name for log continuity and add a
              // clearer builder-scope counter for newer diagnostics.
              final layout = _resolveGridShellLayout(
                constraints,
                resolvedToolbarHeight: resolvedToolbarHeight,
                resolvedSummaryRowHeight: resolvedSummaryRowHeight,
                resolvedStatusBarHeight: resolvedStatusBarHeight,
              );
              final summaryValues = _summaryValuesForLayouts(
                layout.columnBandLayouts,
              );
              final summaryAggregates = _summaryAggregatesForLayouts(
                layout.columnBandLayouts,
              );

              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: layout.viewportWidth,
                  height: layout.gridHeight,
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.f2):
                          _handleF2Key,
                    },
                    child: MouseRegion(
                      cursor: _gridMouseCursor,
                      child: ClipRect(
                        child: DecoratedBox(
                          position: DecorationPosition.foreground,
                          decoration: BoxDecoration(
                            border: Border.all(color: _gridBorderColor()),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (toolbarShell != null &&
                                  layout.toolbarHeight > 0)
                                SizedBox(
                                  height: layout.toolbarHeight,
                                  child: toolbarShell,
                                ),
                              Expanded(
                                child: Focus(
                                  focusNode: _gridFocusNode,
                                  onKeyEvent: _handleGridKeyEvent,
                                  child: _buildGridViewport(
                                    context,
                                    valueFormatter: _valueFormatter,
                                    columnBandLayouts: layout.columnBandLayouts,
                                    layoutRegions: layout.layoutRegions,
                                    topInset: layout.topInset,
                                    bottomInset: layout.bottomInset,
                                    visibleRowsHeight: layout.visibleRowsHeight,
                                    paintedGridWidth: layout.paintedGridWidth,
                                    centerViewportWidth:
                                        layout.centerViewportWidth,
                                    paintedGridHeight:
                                        layout.gridViewportHeight,
                                  ),
                                ),
                              ),
                              if (_showsSummaryRow &&
                                  layout.summaryRowHeight > 0)
                                SizedBox(
                                  height: layout.summaryRowHeight,
                                  child: RepaintBoundary(
                                    child: FdcGridSummaryRow(
                                      style: summaryRowStyle,
                                      topSeparatorColor:
                                          horizontalGridLineColor,
                                      height: layout.summaryRowHeight,
                                      columnBandLayouts:
                                          layout.columnBandLayouts,
                                      layoutRegions: layout.layoutRegions,
                                      centerViewportWidth:
                                          layout.centerViewportWidth,
                                      scrollCoordinator: _scrollCoordinator,
                                      values: summaryValues,
                                      aggregates: summaryAggregates,
                                      runtimeAggregateOverrides:
                                          runtimeSummaryAggregateOverrides,
                                      showVerticalGridLines:
                                          showSummaryVerticalGridLines,
                                      verticalGridLineColor:
                                          summaryVerticalGridLineColor,
                                      allowColumnResize:
                                          widget.options.allowColumnResize,
                                      resizingRuntimeColumnId:
                                          _resizingRuntimeColumnId,
                                      animateColumnReorder:
                                          _draggingColumnIndex != null,
                                      onColumnResizeStart:
                                          _headerCallbacks.onColumnResizeStart,
                                      onColumnResizeUpdate:
                                          _headerCallbacks.onColumnResizeUpdate,
                                      onColumnResizeEnd:
                                          _headerCallbacks.onColumnResizeEnd,
                                      onPointerSignal:
                                          _handleSummaryPointerSignal,
                                      onHorizontalDragStart:
                                          _handleHeaderHorizontalDragStart,
                                      onHorizontalDragUpdate:
                                          _handleHeaderHorizontalDragUpdate,
                                      onHorizontalDragEnd:
                                          _handleHeaderHorizontalDragEnd,
                                      onSummaryMenuOpen: _blurGrid,
                                      canEditSummary: canEditSummary,
                                      onSummaryAggregateChanged:
                                          _setRuntimeSummaryAggregate,
                                    ),
                                  ),
                                ),
                              if (statusBarShell != null &&
                                  layout.statusBarHeight > 0)
                                SizedBox(
                                  height: layout.statusBarHeight,
                                  child: statusBarShell,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    if (widget.formatSettings == null) {
      return gridContent;
    }

    return FdcApp(formatSettings: widget.formatSettings, child: gridContent);
  }
}
