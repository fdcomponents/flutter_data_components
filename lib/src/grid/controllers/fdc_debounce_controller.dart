// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/fdc_grid_core.dart';

/// Schedules debounced grid actions based on the configured debounce policy.
class FdcDebounceController {
  /// Creates a debounce controller.
  FdcDebounceController({
    required FdcDebouncePolicy policy,
    required Duration baseDelay,
    required int Function() recordCountProvider,
  }) : _policy = policy,
       _baseDelay = baseDelay,
       _recordCountProvider = recordCountProvider;

  Timer? _timer;
  FdcDebouncePolicy _policy;
  Duration _baseDelay;
  int Function() _recordCountProvider;

  /// Updates the debounce policy and record count provider.
  void update({
    required FdcDebouncePolicy policy,
    required Duration baseDelay,
    required int Function() recordCountProvider,
  }) {
    _policy = policy;
    _baseDelay = baseDelay;
    _recordCountProvider = recordCountProvider;
  }

  /// Schedules [action] after the resolved debounce delay.
  void schedule(VoidCallback action, {String? inputText}) {
    if (_policy == FdcDebouncePolicy.disabled) {
      cancel();
      return;
    }

    cancel();
    final delay = FdcDebounceDelay.resolve(
      policy: _policy,
      baseDelay: _baseDelay,
      recordCount: _safeRecordCount(),
      inputText: inputText,
    );
    if (delay <= Duration.zero) {
      action();
      return;
    }

    _timer = Timer(delay, action);
  }

  /// Cancels pending work and runs [action] immediately.
  void submit(VoidCallback action) {
    cancel();
    action();
  }

  /// Cancels any pending debounced action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Releases timer resources owned by this controller.
  void dispose() {
    cancel();
  }

  int _safeRecordCount() {
    try {
      return math.max(0, _recordCountProvider());
    } on Object {
      return 0;
    }
  }
}

/// Resolves debounce delays for fixed and adaptive grid policies.
class FdcDebounceDelay {
  static const int _lowRecordThreshold = 5000;
  static const int _highRecordThreshold = 250000;
  static const int _adaptiveGuardMultiplier = 3;

  /// Resolves the debounce delay for the current policy and input state.
  static Duration resolve({
    required FdcDebouncePolicy policy,
    required Duration baseDelay,
    required int recordCount,
    String? inputText,
  }) {
    if (policy == FdcDebouncePolicy.disabled) {
      return Duration.zero;
    }

    if (policy == FdcDebouncePolicy.fixed || baseDelay <= Duration.zero) {
      return baseDelay;
    }

    final baseMicros = baseDelay.inMicroseconds;
    if (baseMicros <= 0 || recordCount <= _lowRecordThreshold) {
      return baseDelay;
    }

    final maxMicros = baseMicros * _adaptiveGuardMultiplier;
    final recordFactor = _recordFactor(recordCount);
    final recordDelayMicros =
        baseMicros + ((maxMicros - baseMicros) * recordFactor).round();
    final textFactor = _textSpecificityFactor(inputText);
    final resolvedMicros = (recordDelayMicros * textFactor).round();
    return Duration(
      microseconds: resolvedMicros.clamp(baseMicros, maxMicros).toInt(),
    );
  }

  static double _recordFactor(int recordCount) {
    if (recordCount <= _lowRecordThreshold) {
      return 0.0;
    }

    if (recordCount >= _highRecordThreshold) {
      return 1.0;
    }

    return ((recordCount - _lowRecordThreshold) /
            (_highRecordThreshold - _lowRecordThreshold))
        .clamp(0.0, 1.0);
  }

  static double _textSpecificityFactor(String? inputText) {
    if (inputText == null) {
      return 1.0;
    }

    final length = inputText.trim().replaceAll(RegExp(r'\s+'), ' ').length;
    if (length <= 1) {
      return 1.0;
    }

    if (length >= 8) {
      return 0.45;
    }

    return 1.0 - ((length - 1) / 7.0) * 0.55;
  }
}
