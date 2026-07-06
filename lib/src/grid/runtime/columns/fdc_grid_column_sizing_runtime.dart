// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateColumnSizingRuntime on _FdcGridState {
  void _refreshEffectiveColumnWidthsIfNeeded(
    double? availableWidth, {
    required List<FdcGridColumn<dynamic>> columns,
    required List<FdcColumnIdentity> runtimeColumnIds,
  }) {
    final viewportChanged = _columnWidthViewportChanged(availableWidth);
    if (!_columnWidthsDirty && !viewportChanged) {
      return;
    }

    if (!_columnWidthsDirty && viewportChanged) {
      // Menu/filter overlays can trigger a transient LayoutBuilder pass with a
      // different outer constraint even though the grid column model did not
      // change. Treating that clean viewport delta as an autosize request makes
      // `autoSizeMode: viewport` columns redistribute after ordinary menu
      // actions. Column widths should only be recalculated during explicit
      // dirty layout transactions; clean viewport deltas merely update the
      // observed viewport baseline so the next build does not repeatedly enter
      // this branch.
      return;
    }

    _refreshEffectiveColumnWidths(
      availableWidth,
      columns: columns,
      runtimeColumnIds: runtimeColumnIds,
    );
    _columnWidthsDirty = false;
    _lastColumnWidthViewport = availableWidth;
  }

  bool _columnWidthViewportChanged(double? availableWidth) {
    final previous = _lastColumnWidthViewport;
    if (previous == null || availableWidth == null) {
      return previous != availableWidth;
    }
    return (previous - availableWidth).abs() >= 0.5;
  }

  void _refreshEffectiveColumnWidths(
    double? availableWidth, {
    required List<FdcGridColumn<dynamic>> columns,
    required List<FdcColumnIdentity> runtimeColumnIds,
  }) {
    _columnSizing.refreshEffectiveColumnWidths(
      availableWidth: availableWidth,
      columns: columns,
      runtimeColumnIds: runtimeColumnIds,
      defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
      minimumResizableColumnWidth: fdcGridMinimumResizableColumnWidth,
    );
  }

  void _markColumnWidthsDirty() {
    _columnWidthsDirty = true;
  }

  void _markColumnWidthsDirtyFor(FdcGridColumn<dynamic> column) {
    if (column.autoSizeMode == FdcGridColumnAutoSizeMode.viewport) {
      _markColumnWidthsDirty();
    }
  }
}
