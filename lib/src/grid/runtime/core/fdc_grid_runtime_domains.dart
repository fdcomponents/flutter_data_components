// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Groups durable runtime collaborators by grid domain.
///
/// The concrete services are still owned by `_FdcGridRuntimeController`; this
/// map is the first explicit internal boundary between the Flutter host and
/// the runtime domains that will eventually absorb more extension logic.
class _FdcGridRuntimeDomains {
  const _FdcGridRuntimeDomains({
    required this.core,
    required this.columns,
    required this.header,
    required this.cells,
    required this.editing,
    required this.navigation,
    required this.scroll,
    required this.rows,
    required this.toolbar,
  });

  final _FdcGridCoreRuntimeDomain core;
  final _FdcGridColumnRuntimeDomain columns;
  final _FdcGridHeaderRuntimeDomain header;
  final _FdcGridCellRuntimeDomain cells;
  final _FdcGridEditingRuntimeDomain editing;
  final _FdcGridNavigationRuntimeDomain navigation;
  final _FdcGridScrollRuntimeDomain scroll;
  final _FdcGridRowRuntimeDomain rows;
  final _FdcGridToolbarRuntimeDomain toolbar;
}

class _FdcGridCoreRuntimeDomain {
  const _FdcGridCoreRuntimeDomain({
    required this.styles,
    required this.bodyViewportKey,
  });

  final FdcGridStyleManager styles;
  final GlobalKey bodyViewportKey;
}

class _FdcGridColumnRuntimeDomain {
  const _FdcGridColumnRuntimeDomain({
    required this.columns,
    required this.sizing,
  });

  final FdcGridColumnManager columns;
  final FdcGridColumnSizingManager sizing;
}

class _FdcGridHeaderRuntimeDomain {
  const _FdcGridHeaderRuntimeDomain({required this.sort});

  final FdcGridSortManager sort;
}

class _FdcGridCellRuntimeDomain {
  const _FdcGridCellRuntimeDomain({required this.cells});

  final FdcGridCellManager cells;
}

class _FdcGridEditingRuntimeDomain {
  const _FdcGridEditingRuntimeDomain({
    required this.typing,
    required this.editorKeys,
  });

  final FdcGridTypingManager typing;
  final FdcGridEditorKeyManager editorKeys;
}

class _FdcGridNavigationRuntimeDomain {
  const _FdcGridNavigationRuntimeDomain({required this.navigation});

  final FdcGridNavigationManager navigation;
}

class _FdcGridScrollRuntimeDomain {
  const _FdcGridScrollRuntimeDomain({
    required this.scroll,
    required this.coordinator,
  });

  final FdcGridScrollManager scroll;
  final FdcGridScrollCoordinator coordinator;

  void addVerticalScrollListener(VoidCallback listener) {
    coordinator.addVerticalScrollListener(listener);
  }

  void removeVerticalScrollListener(VoidCallback listener) {
    coordinator.removeVerticalScrollListener(listener);
  }

  void dispose() {
    scroll.dispose();
    coordinator.dispose();
  }
}

class _FdcGridRowRuntimeDomain {
  const _FdcGridRowRuntimeDomain({required this.rowIndicator});

  final FdcGridRowIndicatorManager rowIndicator;
}

class _FdcGridToolbarRuntimeDomain {
  const _FdcGridToolbarRuntimeDomain({required this.searchController});

  final FdcGridToolbarSearchController searchController;
}
