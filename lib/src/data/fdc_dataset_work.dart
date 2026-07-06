// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';

/// Coarse kind for dataset work reporting.
///
/// The enum is intentionally small. It describes the kind of work currently
/// being performed without turning the dataset into a task framework.
enum FdcDataSetWorkPhase {
  /// No dataset work is active.
  idle,

  /// The dataset is opening or reloading from its source.
  open,

  /// A filter query or local filter rebuild is running.
  filter,

  /// A sort query or local sort rebuild is running.
  sort,

  /// A global-search query or local search rebuild is running.
  search,

  /// Pending changes are being applied through the adapter.
  applyUpdates,

  /// Rows are being loaded for an explicit data operation.
  load,

  /// Application-defined dataset work.
  custom,
}

/// Whether the current dataset work can report a real percentage.
enum FdcDataSetWorkMode {
  /// Work with measurable progress.
  determinate,

  /// Work whose progress cannot be measured.
  indeterminate,
}

/// How long-running dataset work should execute.
///
/// [auto] keeps small operations inline and lets the dataset move supported
/// large operations to a background isolate when that improves UI responsiveness.
enum FdcDataSetOperationExecutionMode {
  /// Chooses the execution strategy automatically.
  auto,

  /// Executes the operation on the current isolate.
  inline,

  /// Executes the operation on a worker isolate when supported.
  isolate,
}

/// Tunables for long-running dataset operations.
///
/// These options intentionally live on the dataset layer, not on the grid. The
/// grid only visualizes work state; the dataset owns how view operations execute.
class FdcDataSetOperationOptions {
  /// Creates a [FdcDataSetOperationOptions].
  const FdcDataSetOperationOptions({
    this.sortExecutionMode = FdcDataSetOperationExecutionMode.auto,
    this.isolateSortThreshold = 100000,
    this.cooperativeChunkSize = 8192,
    this.enableSortValueCache = true,
    this.sortValueCacheSize = 2,
  });

  /// Sort execution strategy for async view rebuilds.
  final FdcDataSetOperationExecutionMode sortExecutionMode;

  /// Minimum view row count before the automatic policy attempts isolate sorting.
  final int isolateSortThreshold;

  /// Number of records processed between cooperative async handoffs.
  final int cooperativeChunkSize;

  /// Whether normalized sort values/ranks should be cached between sorts.
  ///
  /// This helps repeated asc/desc toggles and repeated sorting on the same
  /// field avoid rebuilding expensive normalized values for large datasets.
  final bool enableSortValueCache;

  /// Maximum number of sort fields to keep in the sort value/rank cache.
  ///
  /// The cache is intentionally small by default because large datasets can
  /// make normalized value/rank arrays expensive in memory.
  final int sortValueCacheSize;

  /// Creates a copy with selected values replaced.
  FdcDataSetOperationOptions copyWith({
    FdcDataSetOperationExecutionMode? sortExecutionMode,
    int? isolateSortThreshold,
    int? cooperativeChunkSize,
    bool? enableSortValueCache,
    int? sortValueCacheSize,
  }) {
    return FdcDataSetOperationOptions(
      sortExecutionMode: sortExecutionMode ?? this.sortExecutionMode,
      isolateSortThreshold: isolateSortThreshold ?? this.isolateSortThreshold,
      cooperativeChunkSize: cooperativeChunkSize ?? this.cooperativeChunkSize,
      enableSortValueCache: enableSortValueCache ?? this.enableSortValueCache,
      sortValueCacheSize: sortValueCacheSize ?? this.sortValueCacheSize,
    );
  }
}

/// Immutable snapshot for a dataset work lifecycle transition.
class FdcDataSetWorkInfo {
  /// Creates a [FdcDataSetWorkInfo].
  const FdcDataSetWorkInfo({
    required this.id,
    required this.phase,
    required this.mode,
    required this.startedAt,
    this.message,
    this.error,
    this.stackTrace,
  });

  /// Monotonic dataset-local work id.
  final int id;

  /// High-level work kind.
  final FdcDataSetWorkPhase phase;

  /// Whether [FdcDataSetWork.progress] is real percentage progress.
  final FdcDataSetWorkMode mode;

  /// Start timestamp for this work operation.
  final DateTime startedAt;

  /// Optional user-facing or diagnostic work message.
  final String? message;

  /// Error captured for an error transition, when available.
  final Object? error;

  /// Stack trace captured for an error transition, when available.
  final StackTrace? stackTrace;

  /// Creates a copy with selected values replaced.
  FdcDataSetWorkInfo copyWith({
    FdcDataSetWorkPhase? phase,
    FdcDataSetWorkMode? mode,
    String? message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return FdcDataSetWorkInfo(
      id: id,
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      startedAt: startedAt,
      message: message ?? this.message,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}

/// Lightweight observable work state owned by a dataset.
///
/// The dataset emits lifecycle notifications only when work starts, completes
/// or fails. Progress updates intentionally do not notify listeners; UI widgets
/// that want live progress should poll [progress] while [isWorking] is true.
class FdcDataSetWork extends ChangeNotifier {
  bool _isWorking = false;
  double? _progress;
  String? _message;
  FdcDataSetWorkPhase _phase = FdcDataSetWorkPhase.idle;
  FdcDataSetWorkMode? _mode;
  int _lastWorkId = 0;
  FdcDataSetWorkInfo? _current;
  Object? _error;
  StackTrace? _stackTrace;

  /// Whether the dataset is currently performing a reported work operation.
  bool get isWorking => _isWorking;

  /// Current work progress.
  ///
  /// `null` means indeterminate progress. Non-null values are normalized to the
  /// `0.0..1.0` range.
  double? get progress => _progress;

  /// Optional user-facing or diagnostic work message.
  String? get message => _message;

  /// Current high-level work phase.
  FdcDataSetWorkPhase get phase => _phase;

  /// Current progress mode, or `null` while idle.
  FdcDataSetWorkMode? get mode => _mode;

  /// Last/current work id. This increments every time [begin] is called.
  int get id => _lastWorkId;

  /// Snapshot of the currently active work operation, or `null` while idle.
  FdcDataSetWorkInfo? get current => _current;

  /// Last captured work error, if the most recent transition failed.
  Object? get error => _error;

  /// Last captured work error stack trace, if available.
  StackTrace? get stackTrace => _stackTrace;

  /// Starts a dataset work operation.
  ///
  /// Internal API: package code may use this while public application code
  /// should treat [FdcDataSetWork] as read-only observable state.
  @internal
  FdcDataSetWorkInfo begin({
    FdcDataSetWorkPhase phase = FdcDataSetWorkPhase.custom,
    FdcDataSetWorkMode? mode,
    double? progress,
    String? message,
  }) {
    final resolvedMode =
        mode ??
        (progress == null
            ? FdcDataSetWorkMode.indeterminate
            : FdcDataSetWorkMode.determinate);
    final normalizedProgress = resolvedMode == FdcDataSetWorkMode.determinate
        ? _normalizeProgress(progress ?? 0.0)
        : null;

    _lastWorkId++;
    _isWorking = true;
    _phase = phase;
    _mode = resolvedMode;
    _progress = normalizedProgress;
    _message = message;
    _error = null;
    _stackTrace = null;
    _current = FdcDataSetWorkInfo(
      id: _lastWorkId,
      phase: phase,
      mode: resolvedMode,
      startedAt: DateTime.now(),
      message: message,
    );
    notifyListeners();
    return _current!;
  }

  /// Updates the current dataset work operation.
  ///
  /// This is intentionally a silent state update. It does not call
  /// [notifyListeners], so progress polling does not create a notification storm.
  @internal
  void update({
    double? progress,
    String? message,
    FdcDataSetWorkPhase? phase,
    FdcDataSetWorkMode? mode,
  }) {
    if (!_isWorking) {
      begin(
        phase: phase ?? FdcDataSetWorkPhase.custom,
        mode: mode,
        progress: progress,
        message: message,
      );
      return;
    }

    final resolvedMode =
        mode ??
        (progress == null
            ? FdcDataSetWorkMode.indeterminate
            : FdcDataSetWorkMode.determinate);
    _phase = phase ?? _phase;
    _mode = resolvedMode;
    _progress = resolvedMode == FdcDataSetWorkMode.determinate
        ? _normalizeProgress(progress ?? _progress ?? 0.0)
        : null;
    _message = message ?? _message;
    _current = _current?.copyWith(
      phase: _phase,
      mode: resolvedMode,
      message: _message,
    );
  }

  /// Ends the current dataset work operation and resets state to idle.
  ///
  /// Internal API: package code may use this while public application code
  /// should treat [FdcDataSetWork] as read-only observable state.
  @internal
  FdcDataSetWorkInfo? end() {
    final completed = _current;
    _isWorking = false;
    _phase = FdcDataSetWorkPhase.idle;
    _mode = null;
    _progress = null;
    _message = null;
    _current = null;
    notifyListeners();
    return completed;
  }

  /// Marks the current work operation as failed and resets state to idle.
  @internal
  FdcDataSetWorkInfo? fail(Object error, StackTrace stackTrace) {
    final failed = _current?.copyWith(error: error, stackTrace: stackTrace);
    _error = error;
    _stackTrace = stackTrace;
    _isWorking = false;
    _phase = FdcDataSetWorkPhase.idle;
    _mode = null;
    _progress = null;
    _message = null;
    _current = null;
    notifyListeners();
    return failed;
  }

  double? _normalizeProgress(double? value) {
    if (value == null) {
      return null;
    }
    return value.clamp(0.0, 1.0).toDouble();
  }
}
