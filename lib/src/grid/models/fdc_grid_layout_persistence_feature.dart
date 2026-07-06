// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'fdc_grid_layout_snapshot.dart';

/// Extension contract for loading, saving, and deleting grid layout snapshots.
///
/// The Community grid calls this seam at lifecycle and layout-change boundaries;
/// add-on packages decide where and how snapshots are persisted.
abstract class FdcGridLayoutPersistenceFeature {
  /// Creates a [FdcGridLayoutPersistenceFeature].
  const FdcGridLayoutPersistenceFeature();

  /// Whether the grid should load a persisted snapshot during initialization.
  bool get autoLoad;

  /// Whether layout changes should schedule automatic persistence.
  bool get autoSave;

  /// Debounce interval used before an automatic save is performed.
  Duration get autoSaveDelay;

  /// Loads the persisted snapshot, returning `null` when none is available.
  ///
  /// [rethrowError] controls whether storage failures propagate to the caller.
  FutureOr<FdcGridLayoutSnapshot?> loadSnapshot({required bool rethrowError});

  /// Persists [snapshot].
  ///
  /// [rethrowError] controls whether storage failures propagate to the caller.
  FutureOr<void> saveSnapshot(
    FdcGridLayoutSnapshot snapshot, {
    required bool rethrowError,
  });

  /// Deletes any persisted snapshot.
  ///
  /// [rethrowError] controls whether storage failures propagate to the caller.
  FutureOr<void> deleteSnapshot({required bool rethrowError});

  /// Records that [snapshot] is the latest successfully persisted layout state.
  void markSnapshotSaved(FdcGridLayoutSnapshot snapshot) {}
}
