// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_dataset_filter.dart' show FdcSortType;

/// Source-level filter descriptor passed to a data adapter.
///
/// Adapter filters represent backend query predicates and are also used for
/// adapter defaults that remain active independently of dataset/grid filters.
class FdcDataAdapterFilter {
  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter({
    required this.fieldName,
    required this.value,
    this.operator = FdcDataAdapterFilterOperator.equals,
    this.caseSensitive = false,
  });

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.equals(
    this.fieldName,
    this.value, {
    this.caseSensitive = false,
  }) : operator = FdcDataAdapterFilterOperator.equals;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.notEquals(
    this.fieldName,
    this.value, {
    this.caseSensitive = false,
  }) : operator = FdcDataAdapterFilterOperator.notEquals;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.contains(
    this.fieldName,
    this.value, {
    this.caseSensitive = false,
  }) : operator = FdcDataAdapterFilterOperator.contains;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.startsWith(
    this.fieldName,
    this.value, {
    this.caseSensitive = false,
  }) : operator = FdcDataAdapterFilterOperator.startsWith;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.endsWith(
    this.fieldName,
    this.value, {
    this.caseSensitive = false,
  }) : operator = FdcDataAdapterFilterOperator.endsWith;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.greaterThan(this.fieldName, this.value)
    : caseSensitive = false,

      /// Backend comparison operator.
      operator = FdcDataAdapterFilterOperator.greaterThan;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.greaterThanOrEqual(this.fieldName, this.value)
    : caseSensitive = false,

      /// Backend comparison operator.
      operator = FdcDataAdapterFilterOperator.greaterThanOrEqual;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.lessThan(this.fieldName, this.value)
    : caseSensitive = false,

      /// Backend comparison operator.
      operator = FdcDataAdapterFilterOperator.lessThan;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.lessThanOrEqual(this.fieldName, this.value)
    : caseSensitive = false,

      /// Backend comparison operator.
      operator = FdcDataAdapterFilterOperator.lessThanOrEqual;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.inList(
    this.fieldName,
    this.value, {
    this.caseSensitive = false,
  }) : operator = FdcDataAdapterFilterOperator.inList;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.notInList(
    this.fieldName,
    this.value, {
    this.caseSensitive = false,
  }) : operator = FdcDataAdapterFilterOperator.notInList;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.isEmpty(this.fieldName)
    : value = null,

      /// Whether textual comparison is case-sensitive.
      caseSensitive = false,

      /// Backend comparison operator.
      operator = FdcDataAdapterFilterOperator.isEmpty;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.isNotEmpty(this.fieldName)
    : value = null,

      /// Whether textual comparison is case-sensitive.
      caseSensitive = false,

      /// Backend comparison operator.
      operator = FdcDataAdapterFilterOperator.isNotEmpty;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.isNull(this.fieldName)
    : value = null,

      /// Whether textual comparison is case-sensitive.
      caseSensitive = false,

      /// Backend comparison operator.
      operator = FdcDataAdapterFilterOperator.isNull;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.isNotNull(this.fieldName)
    : value = null,

      /// Whether textual comparison is case-sensitive.
      caseSensitive = false,

      /// Backend comparison operator.
      operator = FdcDataAdapterFilterOperator.isNotNull;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.isNullOrWhitespace(this.fieldName)
    : value = null,

      /// Whether textual comparison is case-sensitive.
      caseSensitive = false,

      /// Backend comparison operator.
      operator = FdcDataAdapterFilterOperator.isNullOrWhitespace;

  /// Creates a [FdcDataAdapterFilter].
  const FdcDataAdapterFilter.isNotNullOrWhitespace(this.fieldName)
    : value = null,

      /// Whether textual comparison is case-sensitive.
      caseSensitive = false,

      /// Backend comparison operator.
      operator = FdcDataAdapterFilterOperator.isNotNullOrWhitespace;

  /// Dataset field name associated with this object.
  final String fieldName;

  /// Current value carried by this object.
  final Object? value;

  /// Backend comparison operator.
  final FdcDataAdapterFilterOperator operator;

  /// Whether textual comparison is case-sensitive.
  final bool caseSensitive;
}

/// Operators that an adapter may receive in [FdcDataAdapterFilter].
///
/// Custom adapters should validate requested operators against their declared
/// `FdcDataAdapterCapabilities` before translating them to backend queries.
enum FdcDataAdapterFilterOperator {
  /// Equals option.
  equals,

  /// Not equals option.
  notEquals,

  /// Contains option.
  contains,

  /// Starts with option.
  startsWith,

  /// Ends with option.
  endsWith,

  /// Greater than option.
  greaterThan,

  /// Greater than or equal option.
  greaterThanOrEqual,

  /// Less than option.
  lessThan,

  /// Less than or equal option.
  lessThanOrEqual,

  /// In list option.
  inList,

  /// Not in list option.
  notInList,

  /// Is empty option.
  isEmpty,

  /// Is not empty option.
  isNotEmpty,

  /// Is null option.
  isNull,

  /// Is not null option.
  isNotNull,

  /// Is null or whitespace option.
  isNullOrWhitespace,

  /// Is not null or whitespace option.
  isNotNullOrWhitespace,
}

/// Source-level ordering descriptor passed to a data adapter.
///
/// Adapter default sorts are used when the dataset has no active user sort;
/// dataset sorts override that default ordering for the current query.
class FdcDataAdapterSort {
  /// Creates a [FdcDataAdapterSort].
  const FdcDataAdapterSort({
    required this.fieldName,
    this.sortType = FdcSortType.ascending,
  });

  /// Creates a [FdcDataAdapterSort].
  const FdcDataAdapterSort.asc(this.fieldName)
    : sortType = FdcSortType.ascending;

  /// Creates a [FdcDataAdapterSort].
  const FdcDataAdapterSort.desc(this.fieldName)
    : sortType = FdcSortType.descending;

  /// Dataset field name associated with this object.
  final String fieldName;

  /// Direction of this adapter ordering rule.
  final FdcSortType sortType;
}
