// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Lightweight, read-only row callback context used by FdcGrid callbacks.
///
/// It deliberately does not expose a `Map<String, Object?>` storage contract.
/// Use [valueOf] or the `[]` operator to read field values by name.
abstract interface class FdcGridRowContext {
  /// Zero-based row index in the current grid view.
  int get rowIndex;

  /// Field names available through this context.
  List<String> get fieldNames;

  /// Returns the value of [fieldName], or `null` when its value is null.
  Object? valueOf(String fieldName);

  /// Whether [fieldName] is available through this context.
  bool containsField(String fieldName);

  /// Returns the value of [fieldName].
  Object? operator [](String fieldName);
}
