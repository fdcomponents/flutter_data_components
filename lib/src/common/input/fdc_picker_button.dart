// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/fdc_app.dart';

@internal
class FdcPickerButton extends StatelessWidget {
  const FdcPickerButton({
    super.key,
    required this.onPressed,
    this.compact = false,
    this.tooltip,
    this.iconColor,
    this.compactSplashRadius,
    this.compactSize,
    this.compactIconSize,
  });

  final VoidCallback? onPressed;
  final bool compact;
  final String? tooltip;
  final Color? iconColor;
  final double? compactSplashRadius;
  final double? compactSize;
  final double? compactIconSize;

  @override
  Widget build(BuildContext context) {
    if (!compact) {
      return ExcludeFocus(
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(Icons.calendar_today_outlined, color: iconColor),
          tooltip: tooltip ?? FdcApp.translationsOf(context).common.pickDate,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final resolvedSize =
            compactSize ??
            (availableHeight.isFinite
                ? (availableHeight - 4).clamp(20.0, 32.0).toDouble()
                : 32.0);
        final resolvedIconSize =
            compactIconSize ??
            (resolvedSize * 0.5625).clamp(14.0, 18.0).toDouble();
        final resolvedSplashRadius =
            compactSplashRadius ??
            (resolvedSize / 2).clamp(10.0, 16.0).toDouble();

        return ExcludeFocus(
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(Icons.calendar_today_outlined, color: iconColor),
            iconSize: resolvedIconSize,
            constraints: BoxConstraints.tightFor(
              width: resolvedSize,
              height: resolvedSize,
            ),
            splashRadius: resolvedSplashRadius,
            padding: EdgeInsets.zero,
            tooltip: tooltip ?? FdcApp.translationsOf(context).common.pickDate,
          ),
        );
      },
    );
  }
}
