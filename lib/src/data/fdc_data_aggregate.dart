// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../common/fdc_aggregate.dart';
import 'fdc_data_adapter_filter.dart';
import 'fdc_data_load.dart' show FdcDataRecordKey;
import 'fdc_dataset_search.dart' show FdcDataSetSearchState;
import 'fdc_field_def.dart';

/// One aggregate expression requested from an adapter.
///
/// The item identifies the field and aggregate function. Optional aliases allow
/// multiple expressions to be correlated with result values.
class FdcDataAggregateItem {
  /// Creates a [FdcDataAggregateItem].
  const FdcDataAggregateItem({
    required this.fieldName,
    required this.aggregate,
  });

  /// Dataset field name associated with this object.
  final String fieldName;

  /// Aggregate function to calculate for the field.
  final FdcAggregate aggregate;
}

/// Stable key identifying one aggregate expression and its result value.
class FdcDataAggregateKey {
  /// Creates a [FdcDataAggregateKey].
  const FdcDataAggregateKey({required this.fieldName, required this.aggregate});

  /// Dataset field name associated with this object.
  final String fieldName;

  /// Aggregate function to calculate for the field.
  final FdcAggregate aggregate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FdcDataAggregateKey &&
          other.fieldName == fieldName &&
          other.aggregate == aggregate;

  @override
  int get hashCode => Object.hash(fieldName, aggregate);
}

/// Adapter aggregate request over the full effective query result set.
///
/// Filter and search criteria match the dataset query, but paging limits are
/// intentionally absent so aggregates describe all matching rows.
class FdcDataAggregateRequest {
  /// Creates a [FdcDataAggregateRequest].
  const FdcDataAggregateRequest({
    this.filters = const <FdcDataAdapterFilter>[],
    this.search = const FdcDataSetSearchState(),
    this.aggregates = const <FdcDataAggregateItem>[],
    this.fields = const <FdcFieldDef>[],
    this.selectedKeysOnly = false,
    this.selectedKeys = const <FdcDataRecordKey>[],
  });

  /// Effective query filters applied before aggregation.
  final List<FdcDataAdapterFilter> filters;

  /// Optional global-search criterion applied before aggregation.
  final FdcDataSetSearchState search;

  /// Aggregate expressions requested from the adapter.
  final List<FdcDataAggregateItem> aggregates;

  /// Field definitions included in this object.
  final List<FdcFieldDef> fields;

  /// Whether aggregation is restricted to explicitly selected record keys.
  final bool selectedKeysOnly;

  /// Record keys used when [selectedKeysOnly] is true.
  final List<FdcDataRecordKey> selectedKeys;
}

/// Values returned for an [FdcDataAggregateRequest].
///
/// Results are keyed by [FdcDataAggregateKey] so callers can correlate values
/// with requested field/function pairs.
class FdcDataAggregateResult {
  /// Creates a [FdcDataAggregateResult].
  const FdcDataAggregateResult({
    this.values = const <FdcDataAggregateKey, Object?>{},
  });

  /// Field values carried by this object.
  final Map<FdcDataAggregateKey, Object?> values;

  /// Returns the value for the [fieldName] and [aggregate] pair, or `null` when the adapter omitted it.
  Object? valueFor(String fieldName, FdcAggregate aggregate) =>
      values[FdcDataAggregateKey(fieldName: fieldName, aggregate: aggregate)];
}
