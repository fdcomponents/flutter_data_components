// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Owns non-widget runtime collaborators for a concrete grid.
///
/// `_FdcGridState` remains the Flutter host for `mounted`, `context`, lifecycle
/// callbacks, and rebuild scheduling. This controller owns durable services and
/// the root transient UI-state holder, giving runtime-owned resources one
/// central dispose boundary.
class _FdcGridRuntimeController {
  _FdcGridRuntimeController()
    : toolbarSearchController = FdcGridToolbarSearchController(),
      bodyViewportKey = GlobalKey(debugLabel: 'fdc-grid-body-viewport') {
    domains = _FdcGridRuntimeDomains(
      core: _FdcGridCoreRuntimeDomain(
        styles: styles,
        bodyViewportKey: bodyViewportKey,
      ),
      columns: _FdcGridColumnRuntimeDomain(
        columns: columns,
        sizing: columnSizing,
      ),
      header: _FdcGridHeaderRuntimeDomain(sort: sort),
      cells: _FdcGridCellRuntimeDomain(cells: cells),
      editing: _FdcGridEditingRuntimeDomain(
        typing: typing,
        editorKeys: editorKeys,
      ),
      navigation: _FdcGridNavigationRuntimeDomain(navigation: navigation),
      scroll: _FdcGridScrollRuntimeDomain(
        scroll: scroll,
        coordinator: scrollCoordinator,
      ),
      rows: _FdcGridRowRuntimeDomain(rowIndicator: rowIndicator),
      toolbar: _FdcGridToolbarRuntimeDomain(
        searchController: toolbarSearchController,
      ),
    );
  }

  final FdcGridScrollManager scroll = FdcGridScrollManager();
  final FdcGridScrollCoordinator scrollCoordinator = FdcGridScrollCoordinator();
  final FdcGridColumnManager columns = FdcGridColumnManager();
  final FdcGridColumnSizingManager columnSizing = FdcGridColumnSizingManager();
  final FdcGridTypingManager typing = FdcGridTypingManager();
  final FdcGridCellManager cells = FdcGridCellManager();
  final FdcGridRowIndicatorManager rowIndicator = FdcGridRowIndicatorManager();
  final FdcGridNavigationManager navigation = FdcGridNavigationManager();
  final FdcGridStyleManager styles = FdcGridStyleManager();
  final FdcGridEditorKeyManager editorKeys = FdcGridEditorKeyManager();
  final FdcGridSortManager sort = FdcGridSortManager();
  final FdcGridToolbarSearchController toolbarSearchController;
  final GlobalKey bodyViewportKey;
  final _FdcGridUiState ui = _FdcGridUiState();
  late final _FdcGridRuntimeDomains domains;

  void addVerticalScrollListener(VoidCallback listener) {
    domains.scroll.addVerticalScrollListener(listener);
  }

  void removeVerticalScrollListener(VoidCallback listener) {
    domains.scroll.removeVerticalScrollListener(listener);
  }

  void dispose() {
    ui.dispose();
    domains.scroll.dispose();
  }
}
