// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/theme/fdc_grid_styles.dart';
import '../../common/widgets/counter/fdc_counter_overlay.dart';
import '../../common/widgets/counter/fdc_counter_style.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';

class FdcGridCellFrame extends StatelessWidget {
  const FdcGridCellFrame({
    super.key,
    required this.width,
    required this.alignment,
    required this.child,
    this.color,
    this.indicatorMode,
    this.indicatorStyle,
    this.errorIndicatorMessage,
    this.errorIndicatorStyle,
    this.counterText,
    this.counterStyle,
    this.contentHorizontalInset,
    this.contentLeadingInset = 0,
    this.rangeTop = false,
    this.rangeRight = false,
    this.rangeBottom = false,
    this.rangeLeft = false,
    this.rangeOutlineStyle,
  });

  final double width;
  final Alignment alignment;
  final Widget child;
  final Color? color;
  final FdcGridCellIndicatorMode? indicatorMode;
  final FdcGridResolvedCellIndicatorStyle? indicatorStyle;
  final String? errorIndicatorMessage;
  final FdcErrorIndicatorMarkerStyle? errorIndicatorStyle;
  final String? counterText;
  final FdcCounterStyle? counterStyle;

  /// Overrides the horizontal content inset used inside the frame.
  ///
  /// Normal data/header cells keep the adaptive default inset. Compact
  /// control-only cells, such as the row indicator, can pass zero so their
  /// slot widths map directly to the visible control widths.
  final double? contentHorizontalInset;
  final double contentLeadingInset;
  final bool rangeTop;
  final bool rangeRight;
  final bool rangeBottom;
  final bool rangeLeft;
  final FdcGridResolvedCellIndicatorStyle? rangeOutlineStyle;

  @override
  Widget build(BuildContext context) {
    final mode = indicatorMode;
    final indicator = indicatorStyle;
    final indicatorColor = indicator?.color;
    final indicatorThickness = indicator?.thickness ?? 0;
    final indicatorBorderRadius = indicator?.borderRadius;
    final showIndicator =
        mode != null && indicatorColor != null && indicatorThickness > 0;

    return Container(
      width: width,
      height: double.infinity,
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: mode == FdcGridCellIndicatorMode.outline
            ? indicatorBorderRadius
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalInset =
              contentHorizontalInset ?? math.min(8.0, constraints.maxWidth / 2);
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: horizontalInset + contentLeadingInset,
                    right: horizontalInset,
                  ),
                  child: Align(alignment: alignment, child: child),
                ),
              ),
              if (showIndicator && mode == FdcGridCellIndicatorMode.line)
                Positioned(
                  left: horizontalInset + contentLeadingInset,
                  right: horizontalInset,
                  bottom: 4,
                  child: IgnorePointer(
                    child: Container(
                      height: indicatorThickness,
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        borderRadius:
                            indicatorBorderRadius ?? BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              if (showIndicator && mode == FdcGridCellIndicatorMode.outline)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CellOutlinePainter(
                        color: indicatorColor,
                        thickness: indicatorThickness,
                        borderRadius: indicatorBorderRadius,
                      ),
                    ),
                  ),
                ),
              if ((rangeTop || rangeRight || rangeBottom || rangeLeft) &&
                  rangeOutlineStyle?.color != null &&
                  (rangeOutlineStyle?.thickness ?? 0) > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _RangeOutlinePainter(
                        color: rangeOutlineStyle!.color,
                        thickness: rangeOutlineStyle!.thickness,
                        top: rangeTop,
                        right: rangeRight,
                        bottom: rangeBottom,
                        left: rangeLeft,
                      ),
                    ),
                  ),
                ),
              if (errorIndicatorMessage != null &&
                  errorIndicatorMessage!.isNotEmpty &&
                  errorIndicatorStyle != null)
                Positioned(
                  left: 0,
                  top: 0,
                  width:
                      errorIndicatorStyle!.size ??
                      FdcErrorIndicatorMarkerStyle.defaults.size ??
                      9,
                  height:
                      errorIndicatorStyle!.size ??
                      FdcErrorIndicatorMarkerStyle.defaults.size ??
                      9,
                  child: FdcErrorIndicatorMarker(
                    message: errorIndicatorMessage!,
                    color:
                        errorIndicatorStyle!.color ??
                        FdcErrorIndicatorMarkerStyle.defaults.color!,
                    size:
                        errorIndicatorStyle!.size ??
                        FdcErrorIndicatorMarkerStyle.defaults.size ??
                        9,
                  ),
                ),
              if (counterText != null && counterStyle != null)
                Positioned.fill(
                  child: FdcCounterOverlay(
                    visible: true,
                    text: counterText!,
                    style: counterStyle!,
                    fit: StackFit.expand,
                    child: const SizedBox.expand(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CellOutlinePainter extends CustomPainter {
  const _CellOutlinePainter({
    required this.color,
    required this.thickness,
    this.borderRadius,
  });

  final Color color;
  final double thickness;
  final BorderRadius? borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (thickness <= 0 || size.isEmpty) {
      return;
    }

    // Draw the outline as an inside-filled frame, not as a centered stroke.
    // A centered stroke still lands on the shared right/bottom cell edges and
    // can be covered by neighbouring cells/rows that paint later. Filling the
    // border area inside this cell keeps all four sides visible.
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Body grid lines are painted as foreground painters above row/cell
    // content. Keep the right and bottom outline edges one logical pixel
    // inside the cell so they are not covered by the normal grid separators.
    const gridLineInset = 1.0;
    final right = math.max(0.0, size.width - gridLineInset);
    final bottom = math.max(0.0, size.height - gridLineInset);
    final rect = Rect.fromLTRB(0, 0, right, bottom);
    if (rect.isEmpty) {
      return;
    }

    final safeThickness = math.min(
      thickness,
      math.min(rect.width, rect.height) / 2,
    );
    if (safeThickness <= 0) {
      return;
    }

    final radius = borderRadius;
    if (radius == null) {
      canvas
        ..drawRect(
          Rect.fromLTWH(rect.left, rect.top, rect.width, safeThickness),
          paint,
        )
        ..drawRect(
          Rect.fromLTWH(
            rect.left,
            rect.bottom - safeThickness,
            rect.width,
            safeThickness,
          ),
          paint,
        )
        ..drawRect(
          Rect.fromLTWH(rect.left, rect.top, safeThickness, rect.height),
          paint,
        )
        ..drawRect(
          Rect.fromLTWH(
            rect.right - safeThickness,
            rect.top,
            safeThickness,
            rect.height,
          ),
          paint,
        );
      return;
    }

    final outer = radius.toRRect(rect);
    final innerRect = rect.deflate(safeThickness);
    if (innerRect.isEmpty) {
      canvas.drawRRect(outer, paint);
      return;
    }

    final innerRadius = BorderRadius.only(
      topLeft: _shrinkRadius(radius.topLeft, safeThickness),
      topRight: _shrinkRadius(radius.topRight, safeThickness),
      bottomLeft: _shrinkRadius(radius.bottomLeft, safeThickness),
      bottomRight: _shrinkRadius(radius.bottomRight, safeThickness),
    ).toRRect(innerRect);

    canvas.drawDRRect(outer, innerRadius, paint);
  }

  static Radius _shrinkRadius(Radius radius, double amount) {
    return Radius.elliptical(
      math.max(0, radius.x - amount),
      math.max(0, radius.y - amount),
    );
  }

  @override
  bool shouldRepaint(covariant _CellOutlinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thickness != thickness ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class _RangeOutlinePainter extends CustomPainter {
  const _RangeOutlinePainter({
    required this.color,
    required this.thickness,
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  final Color color;
  final double thickness;
  final bool top;
  final bool right;
  final bool bottom;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    if (thickness <= 0 || size.isEmpty) {
      return;
    }

    // Paint filled strips fully inside the cell. A centered stroke on the
    // shared right/bottom boundary is covered by the neighbouring cell or the
    // grid foreground separator, which made those range edges disappear.
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const separatorInset = 1.0;
    final rightEdge = math.max(0.0, size.width - separatorInset);
    final bottomEdge = math.max(0.0, size.height - separatorInset);
    final safeThickness = math.min(thickness, math.min(rightEdge, bottomEdge));
    if (safeThickness <= 0) {
      return;
    }

    if (top) {
      canvas.drawRect(Rect.fromLTWH(0, 0, rightEdge, safeThickness), paint);
    }
    if (right) {
      canvas.drawRect(
        Rect.fromLTWH(
          math.max(0.0, rightEdge - safeThickness),
          0,
          safeThickness,
          bottomEdge,
        ),
        paint,
      );
    }
    if (bottom) {
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          math.max(0.0, bottomEdge - safeThickness),
          rightEdge,
          safeThickness,
        ),
        paint,
      );
    }
    if (left) {
      canvas.drawRect(Rect.fromLTWH(0, 0, safeThickness, bottomEdge), paint);
    }
  }

  @override
  bool shouldRepaint(_RangeOutlinePainter oldDelegate) =>
      color != oldDelegate.color ||
      thickness != oldDelegate.thickness ||
      top != oldDelegate.top ||
      right != oldDelegate.right ||
      bottom != oldDelegate.bottom ||
      left != oldDelegate.left;
}
