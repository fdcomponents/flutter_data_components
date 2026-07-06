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
    final button = IconButton(
      onPressed: onPressed,
      icon: Icon(Icons.calendar_today_outlined, color: iconColor),
      iconSize: compact ? compactIconSize ?? 18 : null,
      constraints: compact
          ? BoxConstraints.tightFor(
              width: compactSize ?? 32,
              height: compactSize ?? 32,
            )
          : null,
      splashRadius: compact ? compactSplashRadius ?? 16 : null,
      padding: compact ? EdgeInsets.zero : null,
      tooltip: tooltip ?? FdcApp.translationsOf(context).common.pickDate,
    );

    return ExcludeFocus(child: button);
  }
}
