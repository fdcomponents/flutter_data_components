// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../data/fdc_dataset.dart' show FdcDataSet, FdcDataSetInternal;
import '../data/fdc_dataset_filter.dart' show FdcDataSetFilter;

/// Dataset integration seam for extension packages.
///
/// Import this type through `package:flutter_data_components/fdc_ext.dart`.
/// This type is public so it can be re-exported by `fdc_ext.dart`,
/// but it is intended only for package-to-package integration. It is versioned
/// with `flutter_data_components` and may evolve between package releases.
abstract final class FdcDataSetExtensions {
  /// Registers [guard] to run before the dataset changes its current record.
  ///
  /// [owner] identifies the registration and must be reused when unregistering
  /// the guard. Extension packages can use this seam to finish or reject
  /// transient UI state before cursor movement.
  static void registerBeforeScrollGuard(
    FdcDataSet dataSet, {
    required Object owner,
    required void Function() guard,
  }) {
    FdcDataSetInternal.registerBeforeScrollGuard(
      dataSet,
      owner: owner,
      guard: guard,
    );
  }

  /// Removes the before-scroll guard registered by [owner].
  ///
  /// Calling this method for an owner without a current registration is safe.
  static void unregisterBeforeScrollGuard(
    FdcDataSet dataSet, {
    required Object owner,
  }) {
    FdcDataSetInternal.unregisterBeforeScrollGuard(dataSet, owner: owner);
  }

  /// Adds or replaces an extension-owned query constraint.
  ///
  /// Constraints are merged into the dataset query pipeline without becoming
  /// user-visible filters. Set [blocked] to prevent the constrained query from
  /// opening until the extension has sufficient relation or context data.
  ///
  /// Reusing the same [owner] replaces its previous constraint.
  static void updateQueryConstraint(
    FdcDataSet dataSet, {
    required Object owner,
    required List<FdcDataSetFilter> filters,
    bool blocked = false,
  }) {
    FdcDataSetInternal.updateQueryConstraint(
      dataSet,
      owner: owner,
      filters: filters,
      blocked: blocked,
    );
  }

  /// Re-runs the dataset query after extension-owned constraints have changed.
  ///
  /// The returned future completes when the constrained query refresh finishes.
  static Future<void> refreshQueryConstraints(FdcDataSet dataSet) {
    return FdcDataSetInternal.refreshQueryConstraints(dataSet);
  }

  /// Removes the query constraint associated with [owner].
  ///
  /// This changes the registered constraint set but does not itself refresh the
  /// dataset query; call [refreshQueryConstraints] when a refresh is required.
  static void clearQueryConstraint(
    FdcDataSet dataSet, {
    required Object owner,
  }) {
    FdcDataSetInternal.clearQueryConstraint(dataSet, owner: owner);
  }

  /// Returns the raw value of [fieldName] at visible [rowIndex].
  ///
  /// This extension seam is intended for feature packages that need read-only
  /// access to a visible row without moving the dataset cursor.
  static Object? fieldValueAt(
    FdcDataSet dataSet,
    int rowIndex,
    String fieldName,
  ) {
    return FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, fieldName);
  }
}
