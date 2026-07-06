// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../columns/fdc_grid_columns.dart';
import 'fdc_column_identity.dart';

/// Runtime column resize snapshot used while processing header resize gestures.
class FdcGridResizeColumn {
  const FdcGridResizeColumn({
    required this.runtimeColumnId,
    required this.column,
    required this.columnIndex,
    required this.fallbackColumnIndex,
    required this.startWidth,
    required this.minWidth,
    required this.maxWidth,
  });

  final FdcColumnIdentity runtimeColumnId;
  final FdcGridColumn<dynamic> column;
  final int columnIndex;
  final int fallbackColumnIndex;
  final double startWidth;
  final double minWidth;
  final double maxWidth;
}

/// Cache key for resolving column cell background colors.
class FdcGridCellBackgroundKey {
  const FdcGridCellBackgroundKey({
    required this.column,
    required this.selected,
  });

  final FdcGridColumn<dynamic> column;
  final bool selected;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridCellBackgroundKey &&
            identical(column, other.column) &&
            selected == other.selected;
  }

  @override
  int get hashCode => Object.hash(identityHashCode(column), selected);
}

/// Visible source-record range resolved from the current vertical scroll offset.
class FdcVisibleRecordScrollRange {
  const FdcVisibleRecordScrollRange(this.firstRow, this.lastRow);

  final int firstRow;
  final int lastRow;
}

/// Result of applying a grid column value-changing callback.
sealed class FdcGridColumnValueChangeOutcome {
  const FdcGridColumnValueChangeOutcome._();

  const factory FdcGridColumnValueChangeOutcome.accepted(
    Object? value, {
    Map<String, Object?>? additionalValues,
  }) = FdcGridColumnValueChangeAccepted;

  const factory FdcGridColumnValueChangeOutcome.cancelled() =
      FdcGridColumnValueChangeCancelled;

  bool get accepted;

  Object? get value;

  Map<String, Object?> get additionalValues;
}

final class FdcGridColumnValueChangeAccepted
    extends FdcGridColumnValueChangeOutcome {
  const FdcGridColumnValueChangeAccepted(
    this.value, {
    Map<String, Object?>? additionalValues,
  }) : additionalValues = additionalValues ?? const <String, Object?>{},
       super._();

  @override
  bool get accepted => true;

  @override
  final Object? value;

  @override
  final Map<String, Object?> additionalValues;
}

final class FdcGridColumnValueChangeCancelled
    extends FdcGridColumnValueChangeOutcome {
  const FdcGridColumnValueChangeCancelled() : super._();

  @override
  bool get accepted => false;

  @override
  Object? get value => null;

  @override
  Map<String, Object?> get additionalValues => const <String, Object?>{};
}
