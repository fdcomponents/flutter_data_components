// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/widgets.dart' show Offset;

import '../../common/events/fdc_field_events.dart';
import '../../data/fdc_dataset.dart' show FdcDataSet;
import '../columns/fdc_grid_columns.dart';
import '../models/fdc_grid_row_context.dart';

export '../../common/events/fdc_field_events.dart';

/// Immutable context supplied by grid cell pointer callbacks.
class FdcGridCellPointerContext {
  /// Creates a [FdcGridCellPointerContext].
  const FdcGridCellPointerContext({
    required this.dataSet,
    required this.row,
    required this.column,
    required this.rowIndex,
    required this.columnIndex,
    required this.recordId,
    required this.value,
    required this.globalPosition,
    required this.localPosition,
  });

  /// Dataset associated with this object.
  final FdcDataSet dataSet;

  /// Row context associated with this object.
  final FdcGridRowContext row;

  /// Column configuration associated with this object.
  final FdcGridColumn<dynamic> column;

  /// Zero-based row index in the current view.
  final int rowIndex;

  /// Zero-based column index in the current grid layout.
  final int columnIndex;

  /// Internal record identifier.
  final int? recordId;

  /// Current value carried by this object.
  final Object? value;

  /// Pointer position in global screen coordinates.
  final Offset globalPosition;

  /// Pointer position relative to the grid body cell.
  final Offset localPosition;
}

/// Receives a completed grid cell pointer gesture notification.
///
/// The context identifies the row and column in the current grid view and
/// layout. Pointer callbacks are notification hooks: the grid has already
/// resolved the target cell, and applications may perform normal dataset or UI
/// actions without returning a decision to the gesture pipeline.
typedef FdcGridCellPointerEvent =
    void Function(FdcGridCellPointerContext context);

/// Receives notification after an accepted grid cell value has been committed.
///
/// The aliased [FdcFieldValueChangedContext] contains the accepted logical value
/// and grid coordinates. The callback is observational; use value-changing hooks
/// when a proposed value must be replaced or rejected before commit.
typedef FdcGridCellChanged = FdcFieldValueChangedCallback<Object?>;

/// Receives row focus enter/exit notifications emitted by grid navigation.
///
/// Row indexes are zero-based indexes in the current grid view. When a focus move
/// crosses multiple scopes, exit callbacks run before enter callbacks.
typedef FdcGridRowFocusEvent = FdcFieldFocusCallback<Object?>;

/// Receives column focus enter/exit notifications emitted by grid navigation.
///
/// Column indexes use the current grid layout order. A callback can inspect or
/// update application state, but it does not decide whether the focus move is
/// accepted.
typedef FdcGridColumnFocusEvent = FdcFieldFocusCallback<Object?>;

/// Receives cell focus enter/exit notifications after the grid resolves a focus
/// transition.
///
/// The context reports source and destination row/column coordinates plus the
/// focus-change reason. The callback is notification-only and has no return value
/// for cancelling the transition.
typedef FdcGridCellFocusEvent = FdcFieldFocusCallback<Object?>;

/// Decides whether the row at [rowIndex] may enter edit traversal.
///
/// [rowIndex] is zero-based in the current grid view and [row] is the matching
/// row context. Return `false` to prevent editing cells in that row. The predicate
/// may inspect application state but should remain fast and side-effect free
/// because traversal can evaluate it repeatedly.
typedef FdcGridCanEditRow = bool Function(int rowIndex, FdcGridRowContext row);

/// Decides whether a specific column may be edited for a row.
///
/// [rowIndex] is zero-based in the current view, [column] is the resolved grid
/// column configuration, and [row] describes the same row. Return `false` to
/// exclude that cell from edit traversal. Keep the predicate fast and
/// side-effect free because navigation may evaluate it repeatedly.
typedef FdcGridCanEditColumn =
    bool Function(
      int rowIndex,
      FdcGridColumn<dynamic> column,
      FdcGridRowContext row,
    );

/// Grid specialization of the context delivered after an accepted cell change.
typedef FdcGridCellChangedContext = FdcFieldValueChangedContext<Object?>;

/// Grid specialization of focus context used by row enter/exit callbacks.
typedef FdcGridRowFocusEventContext = FdcFieldFocusContext<Object?>;

/// Grid specialization of focus context used by column enter/exit callbacks.
typedef FdcGridColumnFocusEventContext = FdcFieldFocusContext<Object?>;

/// Grid specialization of focus context used by cell enter/exit callbacks.
typedef FdcGridCellFocusEventContext = FdcFieldFocusContext<Object?>;

/// Reason associated with a grid focus transition.
typedef FdcGridFocusChangeReason = FdcFieldFocusChangeReason;
