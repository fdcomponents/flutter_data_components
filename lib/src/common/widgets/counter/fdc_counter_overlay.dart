// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'fdc_counter.dart';
import 'fdc_counter_style.dart';

@internal
class FdcCounterOverlay extends StatelessWidget {
  const FdcCounterOverlay({
    super.key,
    required this.child,
    required this.visible,
    required this.style,
    this.text,
    this.textListenable,
    this.maxLength,
    this.fit = StackFit.loose,
    this.counterPadding,
  }) : assert(
         text != null || (textListenable != null && maxLength != null),
         'FdcCounterOverlay requires text or textListenable + maxLength.',
       );

  final Widget child;
  final bool visible;
  final FdcCounterStyle style;
  final String? text;
  final ValueListenable<TextEditingValue>? textListenable;
  final int? maxLength;
  final StackFit fit;
  final EdgeInsetsGeometry? counterPadding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: fit,
      children: [
        child,
        if (visible)
          Positioned.fill(child: IgnorePointer(child: _buildCounter())),
      ],
    );
  }

  Widget _buildCounter() {
    final fixedText = text;
    if (fixedText != null) {
      return FdcCounter(text: fixedText, style: style, padding: counterPadding);
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: textListenable!,
      builder: (context, value, _) {
        return FdcCounter(
          text: '${value.text.length}/$maxLength',
          style: style,
          padding: counterPadding,
        );
      },
    );
  }
}
