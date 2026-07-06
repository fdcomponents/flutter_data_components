// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Row scope used by dataset/grid export operations.
enum FdcExportScope {
  /// Export all non-deleted dataset rows, ignoring the current
  /// filter/sort/search view.
  allRows,

  /// Export the current dataset view, respecting filter, sort and search state.
  currentView,

  /// Export selected rows from the current dataset view.
  selectedRows,

  /// Export only the current dataset row.
  currentRow,

  /// Export pending cached-update rows from `FdcDataSet.changeSet`.
  changedRows,
}
