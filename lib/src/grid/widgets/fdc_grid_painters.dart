// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/theme/fdc_grid_styles.dart';
import '../columns/fdc_grid_columns.dart';
import '../managers/fdc_grid_scroll_coordinator.dart';
import '../models/fdc_column_identity.dart';

class HorizontalGridLinePainter extends CustomPainter {
  HorizontalGridLinePainter({
    required this.rowHeight,
    required this.rowCount,
    required this.color,
    required this.scrollCoordinator,
    this.lineWidth,
  }) : super(
         repaint: Listenable.merge([
           scrollCoordinator.verticalOffset,
           scrollCoordinator.verticalViewportTick,
         ]),
       );

  final double rowHeight;
  final int rowCount;
  final Color color;
  final FdcGridScrollCoordinator scrollCoordinator;

  /// Optional horizontal paint extent.
  ///
  /// The scrollable body can temporarily have a wider painted content extent
  /// than its actual column content while a resize lock preserves the current
  /// horizontal offset. Row separators must still stop at the last real
  /// scrollable column so a gap before right-pinned columns stays visually
  /// empty. Pinned/indicator regions omit this and paint their full region.
  final double? lineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (rowHeight <= 0 || rowCount <= 0) {
      return;
    }

    final contentHeight = rowHeight * rowCount;
    final scrollOffset = scrollCoordinator.liveVerticalOffset;
    final visibleContentHeight = (contentHeight - scrollOffset).clamp(
      0.0,
      size.height,
    );
    if (visibleContentHeight <= 0) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final resolvedLineWidth = lineWidth == null
        ? size.width
        : lineWidth!.clamp(0.0, size.width).toDouble();
    if (resolvedLineWidth <= 0) {
      return;
    }
    final pixelOffset = (paint.strokeWidth / 2).clamp(0.0, 1.0);
    final firstVisibleRowOffset = scrollOffset % rowHeight;
    var y = rowHeight - firstVisibleRowOffset;

    // Draw every visible row separator, including the bottom border under the
    // last visible data row. Before the grid was allowed to fill parent height,
    // this line coincided with the viewport bottom. With an empty area below
    // the last row it must be painted explicitly.
    while (y <= visibleContentHeight + pixelOffset) {
      final alignedY = y - pixelOffset;
      if (alignedY >= 0 && alignedY < size.height) {
        canvas.drawLine(
          Offset(0, alignedY),
          Offset(resolvedLineWidth, alignedY),
          paint,
        );
      }
      y += rowHeight;
    }
  }

  @override
  bool shouldRepaint(covariant HorizontalGridLinePainter oldDelegate) {
    return oldDelegate.rowHeight != rowHeight ||
        oldDelegate.rowCount != rowCount ||
        oldDelegate.color != color ||
        oldDelegate.scrollCoordinator != scrollCoordinator ||
        oldDelegate.lineWidth != lineWidth;
  }

  @override
  bool shouldRebuildSemantics(covariant HorizontalGridLinePainter oldDelegate) {
    return false;
  }
}

class VerticalGridLinePainter extends CustomPainter {
  VerticalGridLinePainter({
    required this.columns,
    this.columnCount,
    this.ignoreHorizontalOffset = false,
    required this.defaultColumnWidth,
    required this.columnWidths,
    this.runtimeColumnIds = const <FdcColumnIdentity>[],
    this.activeResizeRuntimeColumnId,
    this.activeResizeDeltaFactor,
    this.suppressTrailingSeparator = false,
    required this.topInset,
    required this.headerHeight,
    required this.visibleRowsHeight,
    required this.rowHeight,
    required this.rowCount,
    this.contentHeightOverride,
    required this.verticalLines,
    required this.color,
    required this.scrollCoordinator,
  }) : super(
         repaint: ignoreHorizontalOffset
             ? Listenable.merge([
                 scrollCoordinator.verticalOffset,
                 scrollCoordinator.verticalViewportTick,
               ])
             : Listenable.merge([
                 scrollCoordinator.horizontalOffset,
                 scrollCoordinator.horizontalResizeTick,
                 scrollCoordinator.verticalOffset,
                 scrollCoordinator.verticalViewportTick,
               ]),
       );

  final List<FdcGridColumn<dynamic>> columns;
  final int? columnCount;
  final bool ignoreHorizontalOffset;
  final double defaultColumnWidth;
  final List<double> columnWidths;
  final List<FdcColumnIdentity> runtimeColumnIds;
  final FdcColumnIdentity? activeResizeRuntimeColumnId;
  final double? activeResizeDeltaFactor;
  final bool suppressTrailingSeparator;
  final double topInset;
  final double headerHeight;
  final double visibleRowsHeight;
  final double rowHeight;
  final int rowCount;
  final double? contentHeightOverride;
  final FdcGridVerticalLines verticalLines;
  final Color color;
  final FdcGridScrollCoordinator scrollCoordinator;

  @override
  void paint(Canvas canvas, Size size) {
    final resolvedColumnCount = columnCount ?? columns.length;
    if (resolvedColumnCount <= 0 || headerHeight < 0 || visibleRowsHeight < 0) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final pixelOffset = paint.strokeWidth / 2;
    final leftEdge = pixelOffset;
    final rightEdge = size.width - pixelOffset;
    final top = topInset;
    final headerBottom = topInset + headerHeight;
    final bottom = _resolveBottom(size.height);
    if (bottom <= top) {
      return;
    }
    var columnOffset = 0.0;

    for (var i = 0; i < resolvedColumnCount; i++) {
      columnOffset += i < columnWidths.length
          ? columnWidths[i]
          : i < columns.length
          ? columns[i].width ?? defaultColumnWidth
          : defaultColumnWidth;
      final x = columnOffset - pixelOffset;
      if (x <= leftEdge || x > rightEdge) {
        continue;
      }
      if (suppressTrailingSeparator && i == resolvedColumnCount - 1) {
        continue;
      }

      _drawVerticalSeparator(
        canvas,
        paint..color = _lineColorForColumn(i),
        x: x,
        headerBottom: headerBottom,
        bottom: bottom,
      );
    }
  }

  Color _lineColorForColumn(int columnIndex) {
    final activeRuntimeColumnId = activeResizeRuntimeColumnId;
    if (activeRuntimeColumnId == null ||
        columnIndex < 0 ||
        columnIndex >= runtimeColumnIds.length) {
      return color;
    }

    final leadingResize = (activeResizeDeltaFactor ?? 1) < 0;
    final boundaryMatches = leadingResize
        ? columnIndex + 1 < runtimeColumnIds.length &&
              runtimeColumnIds[columnIndex + 1] == activeRuntimeColumnId
        : runtimeColumnIds[columnIndex] == activeRuntimeColumnId;
    if (!boundaryMatches) {
      return color;
    }
    return Color.lerp(color, Colors.black, 0.18) ?? color;
  }

  void _drawVerticalSeparator(
    Canvas canvas,
    Paint paint, {
    required double x,
    required double headerBottom,
    required double bottom,
  }) {
    if (bottom > headerBottom) {
      canvas.drawLine(Offset(x, headerBottom), Offset(x, bottom), paint);
    }
  }

  double _resolveBottom(double canvasHeight) {
    final fullViewportBottom = topInset + headerHeight + visibleRowsHeight;
    if (verticalLines == FdcGridVerticalLines.fullHeight) {
      return math.min(canvasHeight, fullViewportBottom);
    }

    final contentHeight =
        contentHeightOverride ?? (rowHeight <= 0 ? 0.0 : rowHeight * rowCount);
    final verticalOffset = scrollCoordinator.liveVerticalOffset;
    final visibleContentHeight = (contentHeight - verticalOffset).clamp(
      0.0,
      visibleRowsHeight,
    );
    final rowsOnlyBottom = topInset + headerHeight + visibleContentHeight;
    return math.min(canvasHeight, rowsOnlyBottom);
  }

  @override
  bool shouldRepaint(covariant VerticalGridLinePainter oldDelegate) {
    return oldDelegate.columns != columns ||
        oldDelegate.columnCount != columnCount ||
        oldDelegate.ignoreHorizontalOffset != ignoreHorizontalOffset ||
        oldDelegate.defaultColumnWidth != defaultColumnWidth ||
        oldDelegate.columnWidths != columnWidths ||
        oldDelegate.runtimeColumnIds != runtimeColumnIds ||
        oldDelegate.activeResizeRuntimeColumnId !=
            activeResizeRuntimeColumnId ||
        oldDelegate.activeResizeDeltaFactor != activeResizeDeltaFactor ||
        oldDelegate.suppressTrailingSeparator != suppressTrailingSeparator ||
        oldDelegate.topInset != topInset ||
        oldDelegate.headerHeight != headerHeight ||
        oldDelegate.visibleRowsHeight != visibleRowsHeight ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.rowCount != rowCount ||
        oldDelegate.contentHeightOverride != contentHeightOverride ||
        oldDelegate.verticalLines != verticalLines ||
        oldDelegate.color != color ||
        oldDelegate.scrollCoordinator != scrollCoordinator;
  }

  @override
  bool shouldRebuildSemantics(covariant VerticalGridLinePainter oldDelegate) {
    return false;
  }
}
