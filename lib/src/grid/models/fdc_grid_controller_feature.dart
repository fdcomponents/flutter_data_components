// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'fdc_grid_layout_snapshot.dart';

/// Extension contract for attaching optional command surfaces to a grid controller.
///
/// Add-on packages use this seam to receive grid-owned command delegates while
/// keeping the Community controller independent from optional feature packages.
abstract class FdcGridControllerFeature {
  /// Creates a [FdcGridControllerFeature].
  const FdcGridControllerFeature();

  /// Connects the feature to one live grid and supplies its command delegates.
  void attach({
    required FdcGridLayoutSnapshot Function() capture,
    required void Function(FdcGridLayoutSnapshot snapshot) restore,
    required void Function() reset,
    required bool Function(String columnId) focusColumn,
    required bool Function(String columnId, bool visible) setColumnVisible,
    required Future<bool> Function() clearFilters,
    required bool Function() showFilters,
    required Future<bool> Function() hideFilters,
    required Future<bool> Function() clearSorting,
    required bool Function({int? rowIndex}) expandDetailRow,
    required bool Function({int? rowIndex}) collapseDetailRow,
    required bool Function() collapseAllDetailRows,
    required bool Function() clearRangeSelection,
    required Future<void> Function() saveLayout,
    required Future<bool> Function() loadLayout,
    required Future<void> Function() deleteLayout,
    required void Function() layoutChanged,
  });

  /// Notifies the feature that the current grid layout has changed.
  void layoutChanged();

  /// Disconnects the feature from its current grid attachment.
  void detach();
}
