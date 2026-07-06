// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Supported filter operators used by data-aware components.
enum FdcFilterOperator {
  /// Text contains the comparison value.
  contains,

  /// Text does not contain the comparison value.
  notContains,

  /// Value equals the comparison value.
  equals,

  /// Value does not equal the comparison value.
  notEquals,

  /// Text starts with the comparison value.
  startsWith,

  /// Text ends with the comparison value.
  endsWith,

  /// Value is greater than the comparison value.
  greaterThan,

  /// Value is greater than or equal to the comparison value.
  greaterThanOrEqual,

  /// Value is less than the comparison value.
  lessThan,

  /// Value is less than or equal to the comparison value.
  lessThanOrEqual,

  /// Value lies between the lower and upper bounds.
  between,

  /// Value occurs in the supplied value list.
  inList,

  /// Value does not occur in the supplied value list.
  notInList,

  /// Value is null.
  isNull,

  /// Value is not null.
  isNotNull,

  /// Value is an empty string or empty supported value.
  isEmpty,

  /// Value is not empty.
  isNotEmpty,

  /// Value is null, empty, or whitespace-only text.
  isNullOrWhitespace,

  /// Value contains non-whitespace content.
  isNotNullOrWhitespace,

  /// Boolean value is true.
  isTrue,

  /// Boolean value is false.
  isFalse,
}
