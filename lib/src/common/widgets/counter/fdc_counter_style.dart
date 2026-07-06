// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Visual style for text-length counters used by editors and grid cells.
class FdcCounterStyle {
  /// Creates a [FdcCounterStyle].
  const FdcCounterStyle({
    this.textStyle,
    this.alignment = Alignment.bottomRight,
    this.offset = const Offset(0, -10),
    this.height = 12,
  });

  /// Text style used to render the counter label.
  final TextStyle? textStyle;

  /// Alignment of the counter within its available overlay area.
  final Alignment alignment;

  /// Positional offset applied after [alignment] is resolved.
  final Offset offset;

  /// Vertical extent reserved for the counter overlay.
  final double height;

  /// Creates a copy with selected values replaced.
  FdcCounterStyle copyWith({
    TextStyle? textStyle,
    Alignment? alignment,
    Offset? offset,
    double? height,
  }) {
    return FdcCounterStyle(
      textStyle: textStyle ?? this.textStyle,
      alignment: alignment ?? this.alignment,
      offset: offset ?? this.offset,
      height: height ?? this.height,
    );
  }

  /// Merges non-null properties from [override] over this style.
  FdcCounterStyle merge(FdcCounterStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcCounterStyle(
      textStyle: override.textStyle ?? textStyle,
      alignment: override.alignment,
      offset: override.offset,
      height: override.height,
    );
  }

  /// Linearly interpolates this style toward [other] by [t].
  FdcCounterStyle lerp(FdcCounterStyle other, double t) {
    return FdcCounterStyle(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      alignment: Alignment.lerp(alignment, other.alignment, t) ?? alignment,
      offset: Offset.lerp(offset, other.offset, t) ?? offset,
      height: lerpDouble(height, other.height, t) ?? height,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcCounterStyle &&
            textStyle == other.textStyle &&
            alignment == other.alignment &&
            offset == other.offset &&
            height == other.height;
  }

  @override
  int get hashCode => Object.hash(textStyle, alignment, offset, height);
}
