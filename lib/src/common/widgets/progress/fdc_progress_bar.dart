// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/fdc_app.dart';
import '../../../data/fdc_dataset.dart';
import '../../../data/fdc_dataset_work.dart';
import 'fdc_progress_bar_style.dart';

/// Dataset-aware progress bar for FDC shell/status surfaces.
///
/// The widget intentionally does not expose a public progress value. Progress is
/// owned by [FdcDataSet.work]; this widget only renders the dataset work state.
class FdcProgressBar extends StatefulWidget {
  /// Creates a [FdcProgressBar].
  const FdcProgressBar({
    super.key,
    required this.dataSet,
    this.width,
    this.style,
    this.semanticLabel,
  });

  /// Dataset whose work/progress state should be visualized.
  final FdcDataSet dataSet;

  /// Optional fixed width. When omitted, the bar expands to parent constraints
  /// once a dataset work state is available.
  final double? width;

  /// Visual styling for the bar.
  final FdcProgressBarStyle? style;

  /// Optional accessibility label.
  final String? semanticLabel;

  @override
  State<FdcProgressBar> createState() => _FdcProgressBarState();
}

class _FdcProgressBarState extends State<FdcProgressBar> {
  Timer? _visibilityTimer;
  Timer? _pollTimer;
  Timer? _closeTimer;
  bool _isVisuallyVisible = false;
  bool _isClosing = false;
  bool _visualWasIndeterminate = false;
  double? _visualProgress;
  int? _visualWorkId;

  @override
  void initState() {
    super.initState();
    widget.dataSet.work.addListener(_handleWorkChanged);
    if (widget.dataSet.work.isWorking) {
      _beginVisualWork();
      _startPolling();
      _scheduleVisibility();
    }
  }

  @override
  void didUpdateWidget(FdcProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dataSet != widget.dataSet) {
      oldWidget.dataSet.work.removeListener(_handleWorkChanged);
      _cancelVisibilityTimer();
      _stopPolling();
      _cancelCloseTimer();
      _isVisuallyVisible = false;
      _isClosing = false;
      _visualWasIndeterminate = false;
      _visualProgress = null;
      _visualWorkId = null;
      widget.dataSet.work.addListener(_handleWorkChanged);
      _handleWorkChanged();
      return;
    }

    final oldDelay =
        oldWidget.style?.visibilityDelay ??
        FdcProgressBarStyle.defaultVisibilityDelay;
    final newDelay =
        widget.style?.visibilityDelay ??
        FdcProgressBarStyle.defaultVisibilityDelay;

    if (oldDelay != newDelay &&
        widget.dataSet.work.isWorking &&
        !_isVisuallyVisible) {
      _cancelVisibilityTimer();
      _scheduleVisibility();
    }

    final oldPollInterval =
        oldWidget.style?.pollInterval ??
        FdcProgressBarStyle.defaultPollInterval;
    final newPollInterval =
        widget.style?.pollInterval ?? FdcProgressBarStyle.defaultPollInterval;
    final oldDisplayMode =
        oldWidget.style?.displayMode ?? FdcProgressBarStyle.defaultDisplayMode;
    final newDisplayMode = _displayMode;
    if ((oldPollInterval != newPollInterval ||
            oldDisplayMode != newDisplayMode) &&
        widget.dataSet.work.isWorking) {
      _stopPolling();
      _startPolling();
    }
  }

  @override
  void dispose() {
    widget.dataSet.work.removeListener(_handleWorkChanged);
    _cancelVisibilityTimer();
    _stopPolling();
    _cancelCloseTimer();
    super.dispose();
  }

  FdcProgressBarDisplayMode get _displayMode {
    return widget.style?.displayMode ?? FdcProgressBarStyle.defaultDisplayMode;
  }

  bool get _rendersIndeterminate {
    return _displayMode == FdcProgressBarDisplayMode.indeterminate ||
        (_displayMode == FdcProgressBarDisplayMode.auto &&
            widget.dataSet.work.progress == null) ||
        (_displayMode == FdcProgressBarDisplayMode.determinate &&
            widget.dataSet.work.progress == null &&
            _visualProgress == null);
  }

  bool get _shouldPollProgress {
    return _displayMode != FdcProgressBarDisplayMode.indeterminate;
  }

  void _handleWorkChanged() {
    if (!mounted) {
      return;
    }

    if (widget.dataSet.work.isWorking) {
      _cancelCloseTimer();
      _isClosing = false;
      _beginVisualWork();
      _startPolling();
      _visualWasIndeterminate = _rendersIndeterminate;

      if (_isVisuallyVisible) {
        _pollProgress();
        setState(() {});
        return;
      }

      _scheduleVisibility();
      setState(() {});
      return;
    }

    _cancelVisibilityTimer();
    _stopPolling();
    if (_isVisuallyVisible) {
      _beginVisualClose();
      return;
    }

    _isClosing = false;
    _visualWasIndeterminate = false;
    _visualProgress = null;
    _visualWorkId = null;
    setState(() {});
  }

  void _beginVisualWork() {
    final workId = widget.dataSet.work.id;
    if (_visualWorkId == workId) {
      return;
    }

    _visualWorkId = workId;
    _visualWasIndeterminate = _rendersIndeterminate;
    final progress = widget.dataSet.work.progress;
    _visualProgress = progress?.clamp(0.0, 1.0).toDouble();
  }

  void _beginVisualClose() {
    if (_isClosing) {
      return;
    }

    _isClosing = true;

    if (!_visualWasIndeterminate) {
      _visualProgress = 1.0;
      final duration =
          widget.style?.animationDuration ??
          FdcProgressBarStyle.defaultAnimationDuration;
      _closeTimer = Timer(
        duration <= Duration.zero ? Duration.zero : duration,
        _completeVisualClose,
      );
    }

    setState(() {});
  }

  void _completeVisualClose() {
    _closeTimer = null;
    if (!mounted || widget.dataSet.work.isWorking) {
      return;
    }

    setState(() {
      _isVisuallyVisible = false;
      _isClosing = false;
      _visualWasIndeterminate = false;
      _visualProgress = null;
      _visualWorkId = null;
    });
  }

  void _pollProgress() {
    if (!widget.dataSet.work.isWorking) {
      return;
    }

    final progress = widget.dataSet.work.progress;
    _visualProgress = progress?.clamp(0.0, 1.0).toDouble();
  }

  void _scheduleVisibility() {
    if (_visibilityTimer != null) {
      return;
    }

    final delay =
        widget.style?.visibilityDelay ??
        FdcProgressBarStyle.defaultVisibilityDelay;

    if (delay <= Duration.zero) {
      _isVisuallyVisible = widget.dataSet.work.isWorking;
      if (_isVisuallyVisible) {
        _pollProgress();
      }
      return;
    }

    _visibilityTimer = Timer(delay, () {
      _visibilityTimer = null;
      if (!mounted || !widget.dataSet.work.isWorking) {
        return;
      }

      setState(() {
        _isVisuallyVisible = true;
        _pollProgress();
      });
    });
  }

  void _cancelVisibilityTimer() {
    _visibilityTimer?.cancel();
    _visibilityTimer = null;
  }

  void _cancelCloseTimer() {
    _closeTimer?.cancel();
    _closeTimer = null;
  }

  void _startPolling() {
    if (!_shouldPollProgress) {
      return;
    }

    if (_pollTimer != null) {
      return;
    }

    final interval =
        widget.style?.pollInterval ?? FdcProgressBarStyle.defaultPollInterval;
    if (interval <= Duration.zero) {
      return;
    }

    _pollTimer = Timer.periodic(interval, (_) {
      if (!mounted || !widget.dataSet.work.isWorking) {
        _stopPolling();
        return;
      }
      if (_isVisuallyVisible) {
        setState(() {
          _pollProgress();
        });
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedStyle = _resolveStyle(theme);

    final shouldPaintActiveProgress =
        (widget.dataSet.work.isWorking || _isClosing) && _isVisuallyVisible;

    if (!shouldPaintActiveProgress) {
      return _sizedFootprint(
        resolvedStyle,
        reserveFootprint: resolvedStyle.reserveSpaceWhenIdle == true,
        visibleChild: null,
      );
    }

    return _sizedFootprint(
      resolvedStyle,
      visibleChild: _FdcProgressBarRenderer(
        value: _resolveRenderedProgressValue(resolvedStyle),
        isClosing: _isClosing,
        style: resolvedStyle,
        semanticLabel: widget.semanticLabel ?? _workSemanticLabel(context),
        onCloseComplete: _completeVisualClose,
      ),
    );
  }

  String _workSemanticLabel(BuildContext context) {
    final work = widget.dataSet.work;
    if (work.phase == FdcDataSetWorkPhase.custom) {
      final message = work.message;
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return FdcApp.translationsOf(context).grid.workPhaseLabel(work.phase.name);
  }

  double? _resolveRenderedProgressValue(FdcProgressBarStyle resolvedStyle) {
    if (_isClosing) {
      return _visualWasIndeterminate ? null : 1.0;
    }

    final displayMode =
        resolvedStyle.displayMode ?? FdcProgressBarStyle.defaultDisplayMode;

    switch (displayMode) {
      case FdcProgressBarDisplayMode.indeterminate:
        return null;
      case FdcProgressBarDisplayMode.determinate:
        return (_visualProgress ?? widget.dataSet.work.progress)
            ?.clamp(0.0, 1.0)
            .toDouble();
      case FdcProgressBarDisplayMode.auto:
        return (_visualProgress ?? widget.dataSet.work.progress)
            ?.clamp(0.0, 1.0)
            .toDouble();
    }
  }

  Widget _sizedFootprint(
    FdcProgressBarStyle resolvedStyle, {
    required Widget? visibleChild,
    bool reserveFootprint = false,
  }) {
    if (visibleChild == null && !reserveFootprint) {
      return const SizedBox.shrink();
    }

    final height = resolvedStyle.height ?? FdcProgressBarStyle.defaultHeight;
    final child = SizedBox(
      height: height,
      child: visibleChild ?? const SizedBox.shrink(),
    );

    if (widget.width == null) {
      return child;
    }

    // In a tight parent (for example a MaterialApp test surface), a bare
    // SizedBox can still be expanded by incoming constraints. Keep the public
    // progress footprint explicitly sized by loosening the constraints around
    // the actual bar while preserving left alignment for shell/status surfaces.
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(width: widget.width, height: height, child: child),
    );
  }

  FdcProgressBarStyle _resolveStyle(ThemeData theme) {
    final defaults = FdcProgressBarStyle.defaults.merge(
      FdcProgressBarStyle(
        trackColor: theme.colorScheme.surfaceContainerHighest,
        valueColor: theme.colorScheme.primary,
      ),
    );

    return defaults.merge(widget.style);
  }
}

class _FdcProgressBarRenderer extends StatelessWidget {
  const _FdcProgressBarRenderer({
    required this.value,
    required this.isClosing,
    required this.style,
    required this.semanticLabel,
    required this.onCloseComplete,
  });

  /// Internal normalized progress value.
  ///
  /// `null` means indeterminate. This stays private so application code cannot
  /// drive progress manually; the public widget remains dataset-driven.
  final double? value;
  final bool isClosing;
  final FdcProgressBarStyle style;
  final String? semanticLabel;
  final VoidCallback onCloseComplete;

  @override
  Widget build(BuildContext context) {
    final height = style.height ?? FdcProgressBarStyle.defaultHeight;
    final borderRadius =
        style.borderRadius ??
        const BorderRadius.all(
          Radius.circular(FdcProgressBarStyle.defaultBorderRadius),
        );
    final theme = Theme.of(context);
    final trackColor =
        style.trackColor ?? theme.colorScheme.surfaceContainerHighest;
    final valueColor = style.valueColor ?? theme.colorScheme.primary;
    final animationDuration =
        style.animationDuration ?? FdcProgressBarStyle.defaultAnimationDuration;
    final progressValue = value?.clamp(0.0, 1.0).toDouble();

    final child = progressValue == null
        ? _IndeterminateProgressBar(
            height: height,
            borderRadius: borderRadius,
            trackColor: trackColor,
            valueColor: style.indeterminateValueColor ?? valueColor,
            backgroundBorder: style.backgroundBorder,
            animationDuration: animationDuration,
            isClosing: isClosing,
            onCloseComplete: onCloseComplete,
          )
        : _DeterminateProgressBar(
            value: progressValue,
            height: height,
            borderRadius: borderRadius,
            trackColor: trackColor,
            valueColor: valueColor,
            backgroundBorder: style.backgroundBorder,
            animationDuration: animationDuration,
          );

    return Semantics(
      container: true,
      label: semanticLabel,
      value: progressValue == null ? null : '${(progressValue * 100).round()}%',
      child: ExcludeSemantics(child: child),
    );
  }
}

class _DeterminateProgressBar extends StatelessWidget {
  const _DeterminateProgressBar({
    required this.value,
    required this.height,
    required this.borderRadius,
    required this.trackColor,
    required this.valueColor,
    required this.backgroundBorder,
    required this.animationDuration,
  });

  final double value;
  final double height;
  final BorderRadiusGeometry borderRadius;
  final Color trackColor;
  final Color valueColor;
  final BoxBorder? backgroundBorder;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    if (animationDuration <= Duration.zero) {
      return CustomPaint(
        size: Size.fromHeight(height),
        painter: _FdcProgressBarPainter(
          value: value,
          trackColor: trackColor,
          valueColor: valueColor,
          borderRadius: borderRadius,
          backgroundBorder: backgroundBorder,
          textDirection: Directionality.of(context),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      tween: Tween<double>(end: value),
      builder: (context, animatedValue, _) {
        return CustomPaint(
          size: Size.fromHeight(height),
          painter: _FdcProgressBarPainter(
            value: animatedValue,
            trackColor: trackColor,
            valueColor: valueColor,
            borderRadius: borderRadius,
            backgroundBorder: backgroundBorder,
            textDirection: Directionality.of(context),
          ),
        );
      },
    );
  }
}

class _IndeterminateProgressBar extends StatefulWidget {
  const _IndeterminateProgressBar({
    required this.height,
    required this.borderRadius,
    required this.trackColor,
    required this.valueColor,
    required this.backgroundBorder,
    required this.animationDuration,
    required this.isClosing,
    required this.onCloseComplete,
  });

  final double height;
  final BorderRadiusGeometry borderRadius;
  final Color trackColor;
  final Color valueColor;
  final BoxBorder? backgroundBorder;
  final Duration animationDuration;
  final bool isClosing;
  final VoidCallback onCloseComplete;

  @override
  State<_IndeterminateProgressBar> createState() =>
      _IndeterminateProgressBarState();
}

class _IndeterminateProgressBarState extends State<_IndeterminateProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration get _effectiveRepeatDuration {
    final duration = widget.animationDuration;
    if (duration > Duration.zero) {
      return duration;
    }

    // A zero duration is valid for determinate progress because it disables
    // value tweening. Indeterminate progress still needs a positive repeat
    // period because AnimationController.repeat() asserts otherwise.
    return FdcProgressBarStyle.defaultAnimationDuration;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _effectiveRepeatDuration,
    );
    if (widget.isClosing) {
      _runCloseOut();
    } else {
      unawaited(_controller.repeat());
    }
  }

  @override
  void didUpdateWidget(_IndeterminateProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldRepeatDuration = oldWidget.animationDuration > Duration.zero
        ? oldWidget.animationDuration
        : FdcProgressBarStyle.defaultAnimationDuration;
    final newRepeatDuration = _effectiveRepeatDuration;

    if (oldRepeatDuration != newRepeatDuration) {
      _controller.duration = newRepeatDuration;
    }

    if (widget.isClosing && !oldWidget.isClosing) {
      _runCloseOut();
      return;
    }

    if (!widget.isClosing && oldWidget.isClosing) {
      unawaited(_controller.repeat());
      return;
    }

    if (!widget.isClosing && oldRepeatDuration != newRepeatDuration) {
      unawaited(_controller.repeat());
    }
  }

  void _runCloseOut() {
    _controller.stop();

    final remaining = 1.0 - _controller.value.clamp(0.0, 1.0);
    if (remaining <= 0.001) {
      widget.onCloseComplete();
      return;
    }

    final remainingDuration = Duration(
      microseconds: (_effectiveRepeatDuration.inMicroseconds * remaining)
          .round(),
    );
    unawaited(
      _controller
          .animateTo(
            1.0,
            duration: remainingDuration <= Duration.zero
                ? Duration.zero
                : remainingDuration,
          )
          .whenComplete(() {
            if (mounted && widget.isClosing) {
              widget.onCloseComplete();
            }
          }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.fromHeight(widget.height),
          painter: _FdcProgressBarPainter(
            indeterminatePhase: _controller.value,
            trackColor: widget.trackColor,
            valueColor: widget.valueColor,
            borderRadius: widget.borderRadius,
            backgroundBorder: widget.backgroundBorder,
            textDirection: Directionality.of(context),
          ),
        );
      },
    );
  }
}

class _FdcProgressBarPainter extends CustomPainter {
  const _FdcProgressBarPainter({
    required this.trackColor,
    required this.valueColor,
    required this.borderRadius,
    required this.textDirection,
    this.value,
    this.indeterminatePhase,
    this.backgroundBorder,
  });

  final double? value;
  final double? indeterminatePhase;
  final Color trackColor;
  final Color valueColor;
  final BorderRadiusGeometry borderRadius;
  final BoxBorder? backgroundBorder;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final rect = Offset.zero & size;
    final radius = borderRadius.resolve(textDirection);
    final rrect = radius.toRRect(rect);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, trackPaint);

    if (backgroundBorder != null) {
      backgroundBorder!.paint(canvas, rect, textDirection: textDirection);
    }

    canvas.save();
    canvas.clipRRect(rrect);
    final fillPaint = Paint()
      ..color = valueColor
      ..style = PaintingStyle.fill;

    final determinateValue = value;
    if (determinateValue != null) {
      final fillRect = _determinateFillRectFor(size, determinateValue);
      if (fillRect.width > 0 && fillRect.height > 0) {
        canvas.drawRect(fillRect, fillPaint);
      }
      canvas.restore();
      return;
    }

    final phase = indeterminatePhase;
    if (phase != null) {
      _paintIndeterminateBar(canvas, size, fillPaint, phase);
    }

    canvas.restore();
  }

  Rect _determinateFillRectFor(Size size, double determinateValue) {
    final width = size.width * determinateValue.clamp(0.0, 1.0);
    return Rect.fromLTWH(0, 0, width, size.height);
  }

  void _paintIndeterminateBar(
    Canvas canvas,
    Size size,
    Paint fillPaint,
    double phase,
  ) {
    final segmentWidth = size.width * 0.22;
    if (segmentWidth <= 0) {
      return;
    }

    final left = size.width * phase;
    final segmentRect = Rect.fromLTWH(left, 0, segmentWidth, size.height);
    canvas.drawRect(segmentRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _FdcProgressBarPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.indeterminatePhase != indeterminatePhase ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.valueColor != valueColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.backgroundBorder != backgroundBorder ||
        oldDelegate.textDirection != textDirection;
  }
}
