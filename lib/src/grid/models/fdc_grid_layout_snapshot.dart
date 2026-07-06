// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/fdc_aggregate.dart';
import '../columns/fdc_column_base.dart';

/// Serializable snapshot of user-adjustable grid layout state.
class FdcGridLayoutSnapshot {
  /// Creates a [FdcGridLayoutSnapshot].
  const FdcGridLayoutSnapshot({
    required this.columns,
    required this.headerFiltersVisible,
  });

  /// Per-column layout state in runtime column order.
  final List<FdcGridColumnLayoutSnapshot> columns;

  /// Whether the header filter row was visible when the snapshot was captured.
  final bool headerFiltersVisible;
}

/// Persisted layout state for one grid column.
class FdcGridColumnLayoutSnapshot {
  /// Creates a [FdcGridColumnLayoutSnapshot].
  const FdcGridColumnLayoutSnapshot({
    required this.id,
    required this.order,
    required this.width,
    required this.visible,
    required this.pin,
    required this.summaryAggregate,
  });

  /// Identifier for this object.
  final String id;

  /// Zero-based runtime order of the column.
  final int order;

  /// Persisted column width.
  final double width;

  /// Persisted column visibility.
  final bool visible;

  /// Persisted column pinning mode.
  final FdcGridColumnPin pin;

  /// Persisted runtime summary aggregate override, when any.
  final FdcAggregate? summaryAggregate;
}
