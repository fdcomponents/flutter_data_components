// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import 'fdc_grid_header_metrics.dart';

class FdcGridHeaderHoverIcon extends StatelessWidget {
  const FdcGridHeaderHoverIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
    required this.enabled,
  });

  final IconData icon;
  final double size;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled ? color : _disabledIconColor(context, color);

    return SizedBox.square(
      dimension: FdcGridHeaderMetrics.headerIconHitTestSize,
      child: Center(
        child: Icon(icon, size: size, color: iconColor),
      ),
    );
  }

  Color _disabledIconColor(BuildContext context, Color enabledColor) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return enabledColor.withValues(alpha: 0.62);
    }

    return theme.disabledColor;
  }
}
