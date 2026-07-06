// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Defines how combo popup search matches option labels.
enum FdcComboSearchMode {
  /// Match option labels that start with the search text.
  startsWith,

  /// Match option labels that contain the search text.
  contains,
}

/// Search configuration for combo editors and combo grid columns.
class FdcComboSearchOptions {
  /// Creates a [FdcComboSearchOptions].
  const FdcComboSearchOptions({
    this.searchable = false,
    this.searchableInline = false,
    this.mode = FdcComboSearchMode.startsWith,
  });

  /// Shows a search text field inside the popup.
  final bool searchable;

  /// Enables type-to-search while the popup list has focus.
  final bool searchableInline;

  /// Defines how option labels are matched.
  final FdcComboSearchMode mode;

  /// Creates a copy with selected values replaced.
  FdcComboSearchOptions copyWith({
    bool? searchable,
    bool? searchableInline,
    FdcComboSearchMode? mode,
  }) {
    return FdcComboSearchOptions(
      searchable: searchable ?? this.searchable,
      searchableInline: searchableInline ?? this.searchableInline,
      mode: mode ?? this.mode,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcComboSearchOptions &&
            searchable == other.searchable &&
            searchableInline == other.searchableInline &&
            mode == other.mode;
  }

  @override
  int get hashCode => Object.hash(searchable, searchableInline, mode);
}
