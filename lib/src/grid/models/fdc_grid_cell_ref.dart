// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_column_identity.dart';

/// Immutable identity of a grid cell used by selection and navigation logic.
class FdcGridCellRef {
  /// Creates a [FdcGridCellRef].
  const FdcGridCellRef(
    this.rowIndex,
    this.columnIndex, {
    this.recordId,
    this.runtimeColumnId,
  });

  /// Zero-based row index in the current view.
  final int rowIndex;

  /// Zero-based column index in the current grid layout.
  final int columnIndex;

  /// Internal record identifier.
  final int? recordId;

  /// Stable runtime identifier of the referenced column.
  final FdcColumnIdentity? runtimeColumnId;

  /// True when both stable record and runtime-column identifiers are available.
  ///
  /// When `true`, identity-aware comparisons use [recordId] and [runtimeColumnId]
  /// instead of view-relative row and column indexes. It is `false` when either
  /// identifier is absent, in which case callers must rely on the current-view
  /// row and current-layout column indexes.
  bool get hasCellIdentity => recordId != null && runtimeColumnId != null;

  /// Whether [other] refers to the same row and runtime column.
  bool hasSameCellIdentity(FdcGridCellRef other) {
    return hasCellIdentity &&
        other.hasCellIdentity &&
        recordId == other.recordId &&
        runtimeColumnId == other.runtimeColumnId;
  }

  /// Whether this reference matches the supplied row and runtime column.
  bool matchesCell(
    int rowIndex,
    int columnIndex, {
    int? recordId,
    FdcColumnIdentity? runtimeColumnId,
  }) {
    if (hasCellIdentity && recordId != null && runtimeColumnId != null) {
      return this.recordId == recordId &&
          this.runtimeColumnId == runtimeColumnId;
    }
    return this.rowIndex == rowIndex && this.columnIndex == columnIndex;
  }

  /// Whether this reference matches the supplied row and column indexes.
  bool matches(FdcGridCellRef other) {
    if (hasCellIdentity && other.hasCellIdentity) {
      return recordId == other.recordId &&
          runtimeColumnId == other.runtimeColumnId;
    }
    return rowIndex == other.rowIndex && columnIndex == other.columnIndex;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! FdcGridCellRef) {
      return false;
    }
    if (hasCellIdentity && other.hasCellIdentity) {
      return recordId == other.recordId &&
          runtimeColumnId == other.runtimeColumnId;
    }
    return rowIndex == other.rowIndex && columnIndex == other.columnIndex;
  }

  @override
  int get hashCode => hasCellIdentity
      ? Object.hash(recordId, runtimeColumnId)
      : Object.hash(rowIndex, columnIndex);

  @override
  String toString() =>
      'FdcGridCellRef(rowIndex: $rowIndex, columnIndex: $columnIndex, '
      'recordId: $recordId, runtimeColumnId: $runtimeColumnId)';
}
