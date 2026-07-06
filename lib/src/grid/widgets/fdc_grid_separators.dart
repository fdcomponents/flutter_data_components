// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fdc_grid_header_metrics.dart';

class FdcGridVerticalSeparator extends StatelessWidget {
  const FdcGridVerticalSeparator({
    super.key,
    required this.height,
    required this.color,
    this.isActive = false,
    this.activeColor,
    this.thickness = FdcGridHeaderMetrics.verticalSeparatorWidth,
    this.topInset = 0,
    this.bottomInset = 0,
    this.alignment = Alignment.centerRight,
  });

  final double height;
  final Color color;
  final bool isActive;
  final Color? activeColor;
  final double thickness;
  final double topInset;
  final double bottomInset;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final resolvedTopInset = math.max(0.0, topInset);
    final resolvedBottomInset = math.max(0.0, bottomInset);
    final separatorHeight = math.max(
      0.0,
      height - resolvedTopInset - resolvedBottomInset,
    );
    if (separatorHeight <= 0 || thickness <= 0) {
      return const SizedBox.shrink();
    }

    final effectiveColor = _resolveFdcGridSeparatorColor(
      color: color,
      isActive: isActive,
      activeColor: activeColor,
    );

    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.only(
            top: resolvedTopInset,
            bottom: resolvedBottomInset,
          ),
          child: SizedBox(
            width: thickness,
            height: separatorHeight,
            child: ColoredBox(color: effectiveColor),
          ),
        ),
      ),
    );
  }
}

class FdcGridHorizontalSeparator extends StatelessWidget {
  const FdcGridHorizontalSeparator({
    super.key,
    required this.width,
    required this.color,
    this.isActive = false,
    this.activeColor,
    this.thickness = FdcGridHeaderMetrics.verticalSeparatorWidth,
    this.leftInset = 0,
    this.rightInset = 0,
    this.alignment = Alignment.topCenter,
  });

  final double width;
  final Color color;
  final bool isActive;
  final Color? activeColor;
  final double thickness;
  final double leftInset;
  final double rightInset;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final resolvedLeftInset = math.max(0.0, leftInset);
    final resolvedRightInset = math.max(0.0, rightInset);
    final separatorWidth = math.max(
      0.0,
      width - resolvedLeftInset - resolvedRightInset,
    );
    if (separatorWidth <= 0 || thickness <= 0) {
      return const SizedBox.shrink();
    }

    final effectiveColor = _resolveFdcGridSeparatorColor(
      color: color,
      isActive: isActive,
      activeColor: activeColor,
    );

    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.only(
            left: resolvedLeftInset,
            right: resolvedRightInset,
          ),
          child: SizedBox(
            width: separatorWidth,
            height: thickness,
            child: ColoredBox(color: effectiveColor),
          ),
        ),
      ),
    );
  }
}

Color _resolveFdcGridSeparatorColor({
  required Color color,
  required bool isActive,
  Color? activeColor,
}) {
  if (!isActive) {
    return color;
  }
  return activeColor ?? Color.lerp(color, Colors.black, 0.18) ?? color;
}
