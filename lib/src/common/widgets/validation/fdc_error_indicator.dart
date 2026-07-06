// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Selects how a component presents validation/data-entry errors.
///
/// Editors support all modes. Grid cells support [none] and [marker]; using
/// [inline] in grid cell indicator options is rejected by debug assertions.
enum FdcErrorIndicatorMode {
  /// Do not render an error indicator.
  none,

  /// Render a compact marker for the validation error.
  marker,

  /// Render the validation message inline.
  inline,
}

/// Configures how a component presents validation and data-entry errors.
class FdcErrorIndicatorOptions {
  /// Creates a [FdcErrorIndicatorOptions].
  const FdcErrorIndicatorOptions({
    this.mode = FdcErrorIndicatorMode.marker,
    this.markerStyle = const FdcErrorIndicatorMarkerStyle(),
  });

  /// Mutually exclusive error presentation mode.
  final FdcErrorIndicatorMode mode;

  /// Visual styling applied when [mode] is [FdcErrorIndicatorMode.marker].
  final FdcErrorIndicatorMarkerStyle markerStyle;

  /// Whether [mode] selects compact marker presentation.
  bool get showsMarker => mode == FdcErrorIndicatorMode.marker;

  /// Whether [mode] selects inline message presentation.
  bool get showsInline => mode == FdcErrorIndicatorMode.inline;

  /// Whether validation feedback is disabled.
  bool get showsNothing => mode == FdcErrorIndicatorMode.none;

  /// Creates a copy with selected values replaced.
  FdcErrorIndicatorOptions copyWith({
    FdcErrorIndicatorMode? mode,
    FdcErrorIndicatorMarkerStyle? markerStyle,
  }) {
    return FdcErrorIndicatorOptions(
      mode: mode ?? this.mode,
      markerStyle: markerStyle ?? this.markerStyle,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcErrorIndicatorOptions &&
            mode == other.mode &&
            markerStyle == other.markerStyle;
  }

  @override
  int get hashCode => Object.hash(mode, markerStyle);
}

/// Visual styling for the compact triangular validation marker.
class FdcErrorIndicatorMarkerStyle {
  /// Creates a [FdcErrorIndicatorMarkerStyle].
  const FdcErrorIndicatorMarkerStyle({this.color, this.size});

  /// Default marker appearance used when no theme override is supplied.
  static const FdcErrorIndicatorMarkerStyle defaults =
      /// Creates a [FdcErrorIndicatorMarkerStyle].
      FdcErrorIndicatorMarkerStyle(color: Color(0xFFD32F2F), size: 9);

  /// Marker fill color, or `null` to inherit from merged defaults.
  final Color? color;

  /// Marker square extent in logical pixels, or `null` to inherit.
  final double? size;

  /// Creates a copy with selected values replaced.
  FdcErrorIndicatorMarkerStyle copyWith({Color? color, double? size}) {
    return FdcErrorIndicatorMarkerStyle(
      color: color ?? this.color,
      size: size ?? this.size,
    );
  }

  /// Merges non-null properties from [override] over this style.
  FdcErrorIndicatorMarkerStyle merge(FdcErrorIndicatorMarkerStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcErrorIndicatorMarkerStyle(
      color: override.color ?? color,
      size: override.size ?? size,
    );
  }

  /// Linearly interpolates this style toward [other] by [t].
  FdcErrorIndicatorMarkerStyle lerp(
    FdcErrorIndicatorMarkerStyle other,
    double t,
  ) {
    return FdcErrorIndicatorMarkerStyle(
      color: Color.lerp(color, other.color, t),
      size: lerpDouble(size, other.size, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcErrorIndicatorMarkerStyle &&
            color == other.color &&
            size == other.size;
  }

  @override
  int get hashCode => Object.hash(color, size);
}

/// Small top-left error marker shared by grid cells and standalone editors.
class FdcErrorIndicatorMarker extends StatelessWidget {
  /// Creates a [FdcErrorIndicatorMarker].
  const FdcErrorIndicatorMarker({
    super.key,
    required this.message,
    required this.color,
    required this.size,
    this.waitDuration = const Duration(milliseconds: 350),
  });

  /// User-facing message text.
  final String message;

  /// Marker fill color, or `null` to inherit from merged defaults.
  final Color color;

  /// Marker square extent in logical pixels, or `null` to inherit.
  final double size;

  /// Delay before the validation tooltip is shown.
  final Duration waitDuration;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      waitDuration: waitDuration,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _ErrorMarkerPainter(color: color)),
      ),
    );
  }
}

class _ErrorMarkerPainter extends CustomPainter {
  const _ErrorMarkerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ErrorMarkerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
