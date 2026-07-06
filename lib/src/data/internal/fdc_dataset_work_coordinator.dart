// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../fdc_dataset_work.dart';

/// Internal owner of dataset work/progress lifecycle orchestration.
final class FdcDataSetWorkCoordinator {
  FdcDataSetWorkCoordinator({
    required int Function() captureLifecycleGeneration,
    required bool Function(int generation) isLifecycleCurrent,
    required void Function(FdcDataSetWorkInfo work) onStarted,
    required void Function(FdcDataSetWorkInfo work) onCompleted,
    required void Function(
      FdcDataSetWorkInfo work,
      Object error,
      StackTrace stackTrace,
    )
    onError,
  }) : _captureLifecycleGeneration = captureLifecycleGeneration,
       _isLifecycleCurrent = isLifecycleCurrent,
       _onStarted = onStarted,
       _onCompleted = onCompleted,
       _onError = onError;

  final int Function() _captureLifecycleGeneration;
  final bool Function(int generation) _isLifecycleCurrent;
  final void Function(FdcDataSetWorkInfo work) _onStarted;
  final void Function(FdcDataSetWorkInfo work) _onCompleted;
  final void Function(
    FdcDataSetWorkInfo work,
    Object error,
    StackTrace stackTrace,
  )
  _onError;

  final FdcDataSetWork work = FdcDataSetWork();

  Completer<void>? _idleCompleter;

  /// Completes when the current dataset work operation returns to idle.
  ///
  /// If the dataset is already idle, the returned future is already complete.
  Future<void> waitUntilIdle() {
    if (!work.isWorking) {
      return Future<void>.value();
    }
    return (_idleCompleter ??= Completer<void>()).future;
  }

  void _prepareIdleSignal() {
    if (_idleCompleter == null || _idleCompleter!.isCompleted) {
      _idleCompleter = Completer<void>();
    }
  }

  void _completeIdleSignal() {
    final completer = _idleCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void update({
    double? progress,
    String? message,
    FdcDataSetWorkPhase? phase,
    FdcDataSetWorkMode? mode,
  }) {
    work.update(progress: progress, message: message, phase: phase, mode: mode);
  }

  T run<T>({
    required FdcDataSetWorkPhase phase,
    required T Function() body,
    String? message,
    double? progress,
    FdcDataSetWorkMode? mode,
  }) {
    _prepareIdleSignal();
    final started = work.begin(
      phase: phase,
      mode: mode,
      progress: progress,
      message: message,
    );
    _onStarted(started);
    try {
      final result = body();
      final completed = work.end();
      if (completed != null) {
        _onCompleted(completed);
      }
      _completeIdleSignal();
      return result;
    } on Object catch (error, stackTrace) {
      final failed = work.fail(error, stackTrace);
      if (failed != null) {
        _onError(failed, error, stackTrace);
      }
      _completeIdleSignal();
      rethrow;
    }
  }

  Future<T> runAsync<T>({
    required FdcDataSetWorkPhase phase,
    required Future<T> Function() body,
    String? message,
    double? progress,
    FdcDataSetWorkMode? mode,
    bool yieldAfterBegin = false,
    T Function()? onLifecycleInvalidated,
  }) async {
    final generation = _captureLifecycleGeneration();
    _prepareIdleSignal();
    final started = work.begin(
      phase: phase,
      mode: mode,
      progress: progress,
      message: message,
    );
    _onStarted(started);
    if (yieldAfterBegin) {
      await _yieldForPaint();
      if (!_isLifecycleCurrent(generation)) {
        final fallback = onLifecycleInvalidated;
        if (fallback != null) {
          _completeIdleSignal();
          return fallback();
        }
        _completeIdleSignal();
        throw StateError('Dataset was disposed while async work was yielding.');
      }
    }
    try {
      final result = await body();
      if (!_isLifecycleCurrent(generation)) {
        _completeIdleSignal();
        return result;
      }
      final completed = work.end();
      if (completed != null) {
        _onCompleted(completed);
      }
      _completeIdleSignal();
      return result;
    } on Object catch (error, stackTrace) {
      if (!_isLifecycleCurrent(generation)) {
        _completeIdleSignal();
        rethrow;
      }
      final failed = work.fail(error, stackTrace);
      if (failed != null) {
        _onError(failed, error, stackTrace);
      }
      _completeIdleSignal();
      rethrow;
    }
  }

  Future<void> _yieldForPaint() async {
    try {
      await SchedulerBinding.instance.endOfFrame;
      // ignore: avoid_catching_errors
    } on FlutterError {
      await Future<void>.value();
    }
  }

  void dispose() {
    _completeIdleSignal();
    work.dispose();
  }
}
