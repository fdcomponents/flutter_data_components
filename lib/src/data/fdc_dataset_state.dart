// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Current lifecycle/editing state of an FdcDataSet.
enum FdcDataSetState {
  /// The dataset is closed and has no active records.
  closed,

  /// The dataset is open for browsing without an active edit operation.
  browse,

  /// The current record is being edited.
  edit,

  /// A new record is being inserted or appended.
  insert,

  /// The dataset is loading data from its source or adapter.
  loading,

  /// Posted changes are being applied through the adapter.
  applyingUpdates,
}

/// State of a single record inside an FdcDataSet.
enum FdcRecordState {
  /// The record has no pending local changes.
  unchanged,

  /// The record was inserted locally and has not been accepted yet.
  inserted,

  /// The record was modified locally and has not been accepted yet.
  modified,

  /// The record is marked for deletion.
  deleted,
}

/// How dataset changes are persisted through an adapter.
enum FdcUpdateMode {
  /// Changes are kept locally until applyUpdates() is called.
  ///
  /// This is an explicit opt-in mode for batch editing/review workflows.
  cachedUpdates,

  /// Posted and deleted changes are automatically applied through the adapter.
  ///
  /// This is the default dataset update mode.
  ///
  /// Because adapters are asynchronous, post/delete remain synchronous local
  /// dataset operations and schedule the apply operation immediately after the
  /// local change is committed. Use onError/onWorkError to observe persistence
  /// failures.
  immediate,
}
