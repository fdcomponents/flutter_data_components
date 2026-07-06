// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;

import '../models/fdc_grid_internal_models.dart';

const double fdcGridHorizontalColumnOverscan = 96.0;

@immutable
class FdcGridVisibleColumnWindow {
  const FdcGridVisibleColumnWindow({
    required this.layout,
    required this.firstLocalColumnIndex,
    required this.lastLocalColumnIndex,
  });

  final FdcGridColumnBandLayout layout;
  final int firstLocalColumnIndex;
  final int lastLocalColumnIndex;

  bool get virtualized => layout.length != layout.geometries.length;

  int get skippedColumnCount => layout.length - layout.geometries.length;

  bool sameRangeAs(FdcGridVisibleColumnWindow other) {
    return firstLocalColumnIndex == other.firstLocalColumnIndex &&
        lastLocalColumnIndex == other.lastLocalColumnIndex &&
        layout.columnSignature == other.layout.columnSignature &&
        layout.width == other.layout.width;
  }
}

FdcGridVisibleColumnWindow resolveFdcGridVisibleColumnWindow(
  FdcGridColumnBandLayout layout, {
  required double horizontalOffset,
  required double viewportWidth,
}) {
  if (layout.geometries.isEmpty ||
      viewportWidth <= 0 ||
      viewportWidth + fdcGridHorizontalColumnOverscan * 2 >= layout.width) {
    return FdcGridVisibleColumnWindow(
      layout: layout,
      firstLocalColumnIndex: 0,
      lastLocalColumnIndex: layout.length,
    );
  }

  final maxOffset = math.max(0.0, layout.width - viewportWidth);
  final effectiveHorizontalOffset = horizontalOffset
      .clamp(0.0, maxOffset)
      .toDouble();
  final windowStart = math.max(
    0.0,
    effectiveHorizontalOffset - fdcGridHorizontalColumnOverscan,
  );
  final windowEnd = math.min(
    layout.width,
    effectiveHorizontalOffset + viewportWidth + fdcGridHorizontalColumnOverscan,
  );
  final visibleGeometries = <FdcGridColumnGeometry>[];
  var firstLocalColumnIndex = -1;
  var lastLocalColumnIndex = -1;

  for (final geometry in layout.geometries) {
    final columnStart = geometry.offset;
    final columnEnd = geometry.offset + geometry.width;
    if (columnEnd >= windowStart && columnStart <= windowEnd) {
      firstLocalColumnIndex = firstLocalColumnIndex < 0
          ? geometry.localColumnIndex
          : firstLocalColumnIndex;
      lastLocalColumnIndex = geometry.localColumnIndex + 1;
      visibleGeometries.add(geometry);
    }
  }

  if (visibleGeometries.length == layout.geometries.length ||
      visibleGeometries.isEmpty ||
      firstLocalColumnIndex < 0 ||
      lastLocalColumnIndex < 0) {
    return FdcGridVisibleColumnWindow(
      layout: layout,
      firstLocalColumnIndex: 0,
      lastLocalColumnIndex: layout.length,
    );
  }

  final windowLayout = FdcGridColumnBandLayout(
    band: layout.band,
    geometries: List<FdcGridColumnGeometry>.unmodifiable(visibleGeometries),
    columnWidths: layout.columnWidths,
    columnOffsets: layout.columnOffsets,
    width: layout.width,
    resizeTargetLocalColumnIndexes: layout.resizeTargetLocalColumnIndexes,
    resizeTargetColumns: layout.resizeTargetColumns,
    resizeTargetRuntimeColumnIds: layout.resizeTargetRuntimeColumnIds,
    resizeTargetColumnIndexes: layout.resizeTargetColumnIndexes,
    resizeDeltaFactors: layout.resizeDeltaFactors,
  );

  return FdcGridVisibleColumnWindow(
    layout: windowLayout,
    firstLocalColumnIndex: firstLocalColumnIndex,
    lastLocalColumnIndex: lastLocalColumnIndex,
  );
}
