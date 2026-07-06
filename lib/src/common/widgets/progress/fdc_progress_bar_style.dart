// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Controls how `FdcProgressBar` visualizes active dataset work.
///
/// [indeterminate] is the default for grid/status surfaces because large
/// dataset operations can span mixed phases where a true percentage is either
/// unavailable or misleading, especially around isolate transfer/publish work.
enum FdcProgressBarDisplayMode {
  /// Always render active work as indeterminate, ignoring sampled percentage.
  indeterminate,

  /// Render sampled dataset percentage when available; fall back to
  /// indeterminate if the dataset does not currently expose progress.
  determinate,

  /// Use dataset progress semantics: non-null progress is determinate, null is
  /// indeterminate.
  auto,
}

/// Visual style for `FdcProgressBar`.
///
/// The progress bar is intentionally generic and reusable. Dataset/grid code
/// should provide progress state; this style only controls rendering.
class FdcProgressBarStyle {
  /// Creates a [FdcProgressBarStyle].
  const FdcProgressBarStyle({
    this.height,
    this.borderRadius,
    this.trackColor,
    this.valueColor,
    this.indeterminateValueColor,
    this.backgroundBorder,
    this.animationDuration,
    this.reserveSpaceWhenIdle,
    this.visibilityDelay,
    this.pollInterval,
    this.displayMode,
  });

  /// Default track height in logical pixels.
  static const double defaultHeight = 4.0;

  /// Default corner radius used to create the pill-shaped track.
  static const double defaultBorderRadius = 999.0;

  /// Default duration for determinate value transitions and indeterminate motion.
  static const Duration defaultAnimationDuration = Duration(milliseconds: 900);

  /// Default delay used to suppress progress UI for short operations.
  static const Duration defaultVisibilityDelay = Duration(milliseconds: 300);

  /// Default interval for sampling dataset progress while work is active.
  static const Duration defaultPollInterval = Duration(milliseconds: 80);

  /// Default rendering mode used when no style override is supplied.
  static const FdcProgressBarDisplayMode defaultDisplayMode =
      FdcProgressBarDisplayMode.indeterminate;

  /// Fully populated baseline style used for resolution and interpolation.
  static const FdcProgressBarStyle defaults = FdcProgressBarStyle(
    height: defaultHeight,
    borderRadius: BorderRadius.all(Radius.circular(defaultBorderRadius)),
    animationDuration: defaultAnimationDuration,
    visibilityDelay: defaultVisibilityDelay,
    pollInterval: defaultPollInterval,
    displayMode: defaultDisplayMode,
  );

  /// Height of the progress track.
  final double? height;

  /// Border radius applied to the track and filled region.
  final BorderRadiusGeometry? borderRadius;

  /// Track color behind the progress value.
  final Color? trackColor;

  /// Filled color for determinate progress.
  final Color? valueColor;

  /// Filled color for indeterminate progress.
  ///
  /// When omitted, [valueColor] is used.
  final Color? indeterminateValueColor;

  /// Optional border around the progress track.
  final BoxBorder? backgroundBorder;

  /// Animation duration for value changes and indeterminate movement.
  final Duration? animationDuration;

  /// Whether the widget should keep its configured footprint while the dataset
  /// is idle or while a work operation is waiting for [visibilityDelay].
  ///
  /// This is useful in compact shell surfaces such as grid status bars where
  /// the text should not shift horizontally when dataset work starts or ends.
  final bool? reserveSpaceWhenIdle;

  /// Delay before the progress bar becomes visually visible after dataset work
  /// starts.
  ///
  /// If the work finishes before this delay expires, the progress bar is never
  /// shown. This avoids flicker for short operations while still reporting
  /// longer-running dataset work.
  final Duration? visibilityDelay;

  /// How often a dataset-aware progress bar polls `FdcDataSet.work.progress`
  /// while work is active. Dataset progress updates do not emit notifications,
  /// so polling keeps UI updates throttled and independent from dataset loops.
  ///
  /// Polling is only needed for [FdcProgressBarDisplayMode.determinate] and
  /// [FdcProgressBarDisplayMode.auto]. Pure indeterminate rendering does not
  /// sample progress values.
  final Duration? pollInterval;

  /// Visual mode used while dataset work is active.
  ///
  /// Defaults to [FdcProgressBarDisplayMode.indeterminate], which favors a
  /// stable "working" signal over potentially misleading percentages for large
  /// dataset operations.
  final FdcProgressBarDisplayMode? displayMode;

  /// Creates a copy with selected values replaced.
  FdcProgressBarStyle copyWith({
    double? height,
    BorderRadiusGeometry? borderRadius,
    Color? trackColor,
    Color? valueColor,
    Color? indeterminateValueColor,
    BoxBorder? backgroundBorder,
    Duration? animationDuration,
    bool? reserveSpaceWhenIdle,
    Duration? visibilityDelay,
    Duration? pollInterval,
    FdcProgressBarDisplayMode? displayMode,
  }) {
    return FdcProgressBarStyle(
      height: height ?? this.height,
      borderRadius: borderRadius ?? this.borderRadius,
      trackColor: trackColor ?? this.trackColor,
      valueColor: valueColor ?? this.valueColor,
      indeterminateValueColor:
          indeterminateValueColor ?? this.indeterminateValueColor,
      backgroundBorder: backgroundBorder ?? this.backgroundBorder,
      animationDuration: animationDuration ?? this.animationDuration,
      reserveSpaceWhenIdle: reserveSpaceWhenIdle ?? this.reserveSpaceWhenIdle,
      visibilityDelay: visibilityDelay ?? this.visibilityDelay,
      pollInterval: pollInterval ?? this.pollInterval,
      displayMode: displayMode ?? this.displayMode,
    );
  }

  /// Interpolates between two progress styles for animated theme transitions.
  static FdcProgressBarStyle lerp(
    FdcProgressBarStyle? a,
    FdcProgressBarStyle? b,
    double t,
  ) {
    final left = a ?? defaults;
    final right = b ?? defaults;
    return FdcProgressBarStyle(
      height: lerpDouble(left.height, right.height, t),
      borderRadius: t < 0.5 ? left.borderRadius : right.borderRadius,
      trackColor: Color.lerp(left.trackColor, right.trackColor, t),
      valueColor: Color.lerp(left.valueColor, right.valueColor, t),
      indeterminateValueColor: Color.lerp(
        left.indeterminateValueColor,
        right.indeterminateValueColor,
        t,
      ),
      backgroundBorder: t < 0.5
          ? left.backgroundBorder
          : right.backgroundBorder,
      animationDuration: t < 0.5
          ? left.animationDuration
          : right.animationDuration,
      reserveSpaceWhenIdle: t < 0.5
          ? left.reserveSpaceWhenIdle
          : right.reserveSpaceWhenIdle,
      visibilityDelay: t < 0.5 ? left.visibilityDelay : right.visibilityDelay,
      pollInterval: t < 0.5 ? left.pollInterval : right.pollInterval,
      displayMode: t < 0.5 ? left.displayMode : right.displayMode,
    );
  }

  /// Returns this style with non-null values from [override] applied.
  FdcProgressBarStyle merge(FdcProgressBarStyle? override) {
    if (override == null) {
      return this;
    }

    return FdcProgressBarStyle(
      height: override.height ?? height,
      borderRadius: override.borderRadius ?? borderRadius,
      trackColor: override.trackColor ?? trackColor,
      valueColor: override.valueColor ?? valueColor,
      indeterminateValueColor:
          override.indeterminateValueColor ?? indeterminateValueColor,
      backgroundBorder: override.backgroundBorder ?? backgroundBorder,
      animationDuration: override.animationDuration ?? animationDuration,
      reserveSpaceWhenIdle:
          override.reserveSpaceWhenIdle ?? reserveSpaceWhenIdle,
      visibilityDelay: override.visibilityDelay ?? visibilityDelay,
      pollInterval: override.pollInterval ?? pollInterval,
      displayMode: override.displayMode ?? displayMode,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcProgressBarStyle &&
            height == other.height &&
            borderRadius == other.borderRadius &&
            trackColor == other.trackColor &&
            valueColor == other.valueColor &&
            indeterminateValueColor == other.indeterminateValueColor &&
            backgroundBorder == other.backgroundBorder &&
            animationDuration == other.animationDuration &&
            reserveSpaceWhenIdle == other.reserveSpaceWhenIdle &&
            visibilityDelay == other.visibilityDelay &&
            pollInterval == other.pollInterval &&
            displayMode == other.displayMode;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    height,
    borderRadius,
    trackColor,
    valueColor,
    indeterminateValueColor,
    backgroundBorder,
    animationDuration,
    reserveSpaceWhenIdle,
    visibilityDelay,
    pollInterval,
    displayMode,
  ]);
}
