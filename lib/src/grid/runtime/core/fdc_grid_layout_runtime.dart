// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateLayoutRuntime on _FdcGridState {
  FdcGridRowIndicatorLayout get _rowIndicatorLayout {
    final localRowCount = FdcDataSetInternal.loadedRecordCount(widget.dataSet);
    final maxVisibleRowNumber = widget.dataSet.paging.enabled
        ? widget.dataSet.paging.totalRecordCount ??
              (widget.dataSet.paging.pageOffset + localRowCount)
        : localRowCount;
    final stableRowNumberCount = _resolveRowIndicatorWidthRowCount(
      maxVisibleRowNumber,
    );

    return _runtime.domains.rows.rowIndicator.layout(
      options: widget.options,
      rowIndicator: widget.rowIndicator,
      rowCount: stableRowNumberCount,
      showsFilterRow: _showsHeaderFilterRow,
      mainMenuInToolbar: _showsToolbarMainMenu(),
    );
  }

  int _resolveRowIndicatorWidthRowCount(int visibleRowNumberCount) {
    if (!widget.rowIndicator.visible ||
        !widget.rowIndicator.options.showRowNumbers) {
      _rowIndicatorWidthAnchorRowCount = null;
      _holdRowIndicatorWidthUntilCountRestores = false;
      return visibleRowNumberCount;
    }

    final viewIsNarrowed =
        widget.dataSet.filter.active || widget.dataSet.search.active;
    final anchor = _rowIndicatorWidthAnchorRowCount;

    if (viewIsNarrowed) {
      _holdRowIndicatorWidthUntilCountRestores = true;
      if (anchor == null || visibleRowNumberCount > anchor) {
        _rowIndicatorWidthAnchorRowCount = visibleRowNumberCount;
        return visibleRowNumberCount;
      }
      return anchor;
    }

    if (_holdRowIndicatorWidthUntilCountRestores &&
        anchor != null &&
        visibleRowNumberCount < anchor) {
      return anchor;
    }

    _holdRowIndicatorWidthUntilCountRestores = false;
    _rowIndicatorWidthAnchorRowCount = visibleRowNumberCount;
    return visibleRowNumberCount;
  }

  double _resolveGridHeight(
    BoxConstraints constraints, {
    required double resolvedToolbarHeight,
    required double resolvedSummaryRowHeight,
    required double resolvedStatusBarHeight,
  }) {
    if (constraints.hasBoundedHeight) {
      return math.max(0.0, constraints.maxHeight);
    }

    final toolbarHeight = widget.toolbar.visible
        ? math.max(0.0, resolvedToolbarHeight)
        : 0.0;
    final summaryRowHeight = _showsSummaryRow
        ? math.max(0.0, resolvedSummaryRowHeight)
        : 0.0;
    final statusBarHeight = widget.statusBar.visible
        ? math.max(0.0, resolvedStatusBarHeight)
        : 0.0;
    final fallbackRows = _rows.isEmpty ? 1 : _rows.length.clamp(1, 5).toInt();
    return toolbarHeight +
        _effectiveHeaderHeight +
        widget.options.resolvedRowHeight * fallbackRows +
        summaryRowHeight +
        statusBarHeight;
  }

  double _resolveVisibleRowsViewportHeight(double availableRowsHeight) {
    switch (widget.options.verticalScrollMode) {
      case FdcGridVerticalScrollMode.smooth:
        // Smooth mode is a true pixel viewport: consume every available pixel.
        // A partially visible final row is valid and there must be no
        // row-alignment remainder left below the body.
        return availableRowsHeight;
      case FdcGridVerticalScrollMode.recordScroll:
        // Record scroll owns row alignment. Restrict the viewport to complete
        // rows so every settled offset can map to a record boundary.
        return _resolveWholeRowViewportHeight(availableRowsHeight);
    }
  }

  double _resolveWholeRowViewportHeight(double availableRowsHeight) {
    if (availableRowsHeight <= 0) {
      return 0;
    }

    final rowHeight = widget.options.resolvedRowHeight;
    if (rowHeight <= 0) {
      return availableRowsHeight;
    }

    final wholeRows = (availableRowsHeight / rowHeight).floor();
    return wholeRows <= 0 ? 0 : wholeRows * rowHeight;
  }
}
