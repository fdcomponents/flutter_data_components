// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../data/fdc_data.dart';

/// Detail-row configuration and rendering contract for grid rows.
abstract class FdcGridDetailRowFeature {
  /// Creates a [FdcGridDetailRowFeature].
  const FdcGridDetailRowFeature();

  /// Fixed detail-row height, or `null` to size from built content.
  double? get height;

  /// Minimum height allowed for auto-sized detail content.
  double get minHeight;

  /// Maximum height allowed for auto-sized detail content, or `null` for no cap.
  double? get maxHeight;

  /// Whether expanding one row automatically collapses another expanded row.
  bool get singleExpanded;

  /// Whether changing the dataset current row collapses expanded detail content.
  bool get collapseOnCurrentRowChange;

  /// Whether tapping a body row toggles its detail panel after row activation.
  bool get toggleOnRowTap;

  /// Padding applied around built detail content.
  EdgeInsetsGeometry get padding;

  /// Optional background color painted behind the detail panel.
  Color? get backgroundColor;

  /// Returns whether the row described by [context] may be expanded.
  bool canExpand(FdcGridDetailRowContext context);

  /// Builds detail content for [detailContext].
  Widget build(BuildContext context, FdcGridDetailRowContext detailContext);

  /// Callback invoked after a detail row becomes expanded.
  void Function(FdcGridDetailRowContext context)? get onExpanded;

  /// Callback invoked after a detail row becomes collapsed.
  void Function(FdcGridDetailRowContext context)? get onCollapsed;
}

/// Immutable row identity and dataset context supplied to detail-row callbacks.
@immutable
class FdcGridDetailRowContext {
  /// Creates a [FdcGridDetailRowContext].
  const FdcGridDetailRowContext({
    required this.dataSet,
    required this.rowIndex,
    required this.sourceRowIndex,
    required this.recordId,
    required this.expanded,
  });

  /// Dataset associated with this object.
  final FdcDataSet dataSet;

  /// Zero-based row index in the current view.
  final int rowIndex;

  /// Zero-based row index in the underlying source record collection.
  final int sourceRowIndex;

  /// Internal record identifier.
  final int recordId;

  /// Whether the row is currently expanded.
  final bool expanded;
}
