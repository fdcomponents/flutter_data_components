// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_field_def.dart';

/// Immutable collection of pending dataset insert, update, and delete actions.
///
/// Data adapters receive a change set when `FdcDataSet.apply()` persists pending
/// edits.
class FdcChangeSet {
  /// Creates a [FdcChangeSet].
  const FdcChangeSet({
    required this.inserts,
    required this.updates,
    required this.deletes,
    this.fields = const <FdcFieldDef>[],
  });

  /// Records pending insertion.
  final List<FdcChangeSetEntry> inserts;

  /// Records pending update.
  final List<FdcChangeSetEntry> updates;

  /// Records pending deletion.
  final List<FdcChangeSetEntry> deletes;

  /// Dataset schema fields used by persistence adapters.
  ///
  /// Identity fields are the entries whose [FdcFieldDef.isKey] is true.
  final List<FdcFieldDef> fields;

  /// Whether this change set contains no inserts, updates, or deletes.
  bool get isEmpty => inserts.isEmpty && updates.isEmpty && deletes.isEmpty;
}

/// One inserted, updated, or deleted record in an [FdcChangeSet].
///
/// [recordId] is the dataset identity used to correlate backend results,
/// `keys` identify the storage row, and `values` contain persistent field
/// values relevant to the operation.
class FdcChangeSetEntry {
  /// Creates a [FdcChangeSetEntry].
  const FdcChangeSetEntry({
    required this.recordId,
    required this.values,
    required this.originalValues,
    required this.changedFields,
  });

  /// Internal record identifier.
  final int recordId;

  /// Field values carried by this object.
  final Map<String, Object?> values;

  /// Original field values before the change.
  final Map<String, Object?> originalValues;

  /// Names of fields changed by this operation.
  final Set<String> changedFields;
}
