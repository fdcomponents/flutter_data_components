// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'fdc_counter_style.dart';

@internal
class FdcCounter extends StatelessWidget {
  const FdcCounter({
    super.key,
    required this.text,
    required this.style,
    EdgeInsetsGeometry? padding,
  }) : padding = padding ?? const EdgeInsets.symmetric(horizontal: 8);

  final String text;
  final FdcCounterStyle style;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final direction = Directionality.of(context);
    final resolvedPadding = padding.resolve(direction);
    final textStyle =
        style.textStyle ??
        theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 11,
          height: 1,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth.isFinite) {
          final availableTextWidth =
              maxWidth - resolvedPadding.left - resolvedPadding.right;
          if (availableTextWidth <= 0 ||
              _textExceedsWidth(
                text: text,
                style: textStyle,
                textDirection: direction,
                maxWidth: availableTextWidth,
              )) {
            return const SizedBox.shrink();
          }
        }

        return Transform.translate(
          offset: style.offset,
          child: Padding(
            padding: padding,
            child: SizedBox(
              height: style.height,
              child: Align(
                alignment: style.alignment,
                child: Text(
                  text,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: textStyle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _textExceedsWidth({
    required String text,
    required TextStyle? style,
    required TextDirection textDirection,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: textDirection,
    )..layout();

    return painter.width > maxWidth;
  }
}
