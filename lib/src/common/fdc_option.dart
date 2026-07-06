// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Static value used by combo-like controls and filters.
class FdcOption<T> {
  /// Creates a [FdcOption].
  const FdcOption({required this.value, required this.label});

  /// Current value carried by this object.
  final T value;

  /// Display label shown to the user.
  final String label;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcOption && value == other.value && label == other.label;
  }

  @override
  int get hashCode => Object.hash(value, label);
}
