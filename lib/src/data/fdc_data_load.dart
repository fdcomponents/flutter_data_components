// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_data_adapter_filter.dart';
import 'fdc_dataset_search.dart' show FdcDataSetSearchState;
import 'fdc_field_def.dart';

class _FdcUnsetLoadRequestValue {
  const _FdcUnsetLoadRequestValue();
}

const Object _fdcUnsetLoadRequestValue = _FdcUnsetLoadRequestValue();

/// Stable dataset/business key used for adapter-aware row selection.
///
/// The key preserves dataset key-field order through [fieldNames] and stores the
/// corresponding field values in [values]. It is intentionally JSON-friendly so
/// Adapters can forward selected keys to backend services without exposing
/// internal row ids.
class FdcDataRecordKey {
  /// Creates a [FdcDataRecordKey].
  FdcDataRecordKey({
    required List<String> fieldNames,
    required List<Object?> values,
  }) : fieldNames = List<String>.unmodifiable(fieldNames),

       /// Field values carried by this object.
       values = List<Object?>.unmodifiable(values) {
    if (fieldNames.length != values.length) {
      throw ArgumentError(
        'FdcDataRecordKey.fieldNames and values must have the same length.',
      );
    }
  }

  /// Dataset field names included in this object.
  final List<String> fieldNames;

  /// Field values carried by this object.
  final List<Object?> values;

  /// Converts the ordered key fields and values to a field-name map.
  Map<String, Object?> toMap() => <String, Object?>{
    for (var i = 0; i < fieldNames.length; i++) fieldNames[i]: values[i],
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! FdcDataRecordKey ||
        other.fieldNames.length != fieldNames.length ||
        other.values.length != values.length) {
      return false;
    }
    for (var i = 0; i < fieldNames.length; i++) {
      if (other.fieldNames[i] != fieldNames[i] ||
          other.values[i] != values[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    for (var i = 0; i < fieldNames.length; i++) ...<Object?>[
      fieldNames[i],
      values[i],
    ],
  ]);

  @override
  String toString() => toMap().toString();
}

/// Navigation intent for adapter paging.
///
/// Adapters may use this hint to replace deep OFFSET scans with an optimized
/// cursor/keyset query. Unsupported adapters can ignore it and keep using
/// [FdcDataLoadRequest.offset].
enum FdcDataPageNavigation {
  /// Navigate to an arbitrary page.
  random,

  /// Navigate to the first page.
  first,

  /// Navigate to the previous page.
  previous,

  /// Navigate to the next page.
  next,

  /// Navigate to the last page.
  last,
}

/// Query request sent by a dataset to an adapter.
///
/// The request carries effective filters, sorts, search criteria, paging
/// bounds, and total-count requirements. Adapters should treat it as an
/// immutable description of one load operation.
class FdcDataLoadRequest {
  /// Creates a [FdcDataLoadRequest].
  const FdcDataLoadRequest({
    this.filters = const <FdcDataAdapterFilter>[],
    this.sorts = const <FdcDataAdapterSort>[],
    this.search = const FdcDataSetSearchState(),
    this.offset,
    this.limit,
    this.includeFields = false,
    this.includeTotalCount = true,
    this.fields = const <FdcFieldDef>[],
    this.pageNavigation = FdcDataPageNavigation.random,
    this.pageCursor,
    this.selectedKeysOnly = false,
    this.selectedKeys = const <FdcDataRecordKey>[],
  });

  /// Effective backend field predicates for this load.
  final List<FdcDataAdapterFilter> filters;

  /// Effective backend ordering rules in priority order.
  final List<FdcDataAdapterSort> sorts;

  /// Optional global-search criterion for this load.
  final FdcDataSetSearchState search;

  /// Zero-based row offset for paged loads.
  final int? offset;

  /// Maximum number of rows requested, or `null` for an unbounded load.
  final int? limit;

  /// Whether adapters should compute and return [FdcDataLoadResult.totalCount].
  ///
  /// Paged datasets request an exact count when their paging options require it
  /// or when no dataset search is active. While search is active and an exact
  /// count is not required, they set this to false so expensive backends may
  /// skip the count query. Adapters may still return a cheap count when false.
  final bool includeTotalCount;

  /// Requests optional schema metadata from adapters that can provide it.
  ///
  /// Dataset open APIs enable this automatically when the dataset was created
  /// without explicit fields. Adapters may ignore it when they cannot
  /// cheaply provide schema metadata.
  final bool includeFields;

  /// Dataset schema fields available to adapters.
  final List<FdcFieldDef> fields;

  /// Optional navigation intent used by adapters that support cursor paging.
  final FdcDataPageNavigation pageNavigation;

  /// Opaque adapter cursor for [FdcDataPageNavigation.previous] or
  /// [FdcDataPageNavigation.next]. The dataset stores and returns this value
  /// without interpreting it.
  final Object? pageCursor;

  /// Whether [selectedKeys] should be applied as an adapter-side include-only
  /// predicate. When true and [selectedKeys] is empty, adapters must return an
  /// empty result set.
  final bool selectedKeysOnly;

  /// Dataset row keys that should be included by adapter-side selected-row
  /// filtering when [selectedKeysOnly] is true.
  final List<FdcDataRecordKey> selectedKeys;

  /// Creates a copy with selected values replaced.
  FdcDataLoadRequest copyWith({
    List<FdcDataAdapterFilter>? filters,
    List<FdcDataAdapterSort>? sorts,
    FdcDataSetSearchState? search,
    Object? offset = _fdcUnsetLoadRequestValue,
    Object? limit = _fdcUnsetLoadRequestValue,
    bool? includeFields,
    bool? includeTotalCount,
    List<FdcFieldDef>? fields,
    FdcDataPageNavigation? pageNavigation,
    Object? pageCursor = _fdcUnsetLoadRequestValue,
    bool? selectedKeysOnly,
    List<FdcDataRecordKey>? selectedKeys,
  }) {
    if (!identical(offset, _fdcUnsetLoadRequestValue) &&
        offset != null &&
        offset is! int) {
      throw ArgumentError.value(
        offset,
        'offset',
        'Expected int, null, or omitted value.',
      );
    }
    if (!identical(limit, _fdcUnsetLoadRequestValue) &&
        limit != null &&
        limit is! int) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Expected int, null, or omitted value.',
      );
    }

    return FdcDataLoadRequest(
      filters: filters ?? this.filters,
      sorts: sorts ?? this.sorts,
      search: search ?? this.search,
      offset: identical(offset, _fdcUnsetLoadRequestValue)
          ? this.offset
          : offset as int?,
      limit: identical(limit, _fdcUnsetLoadRequestValue)
          ? this.limit
          : limit as int?,
      includeFields: includeFields ?? this.includeFields,
      includeTotalCount: includeTotalCount ?? this.includeTotalCount,
      fields: fields ?? this.fields,
      pageNavigation: pageNavigation ?? this.pageNavigation,
      pageCursor: identical(pageCursor, _fdcUnsetLoadRequestValue)
          ? this.pageCursor
          : pageCursor,
      selectedKeysOnly: selectedKeysOnly ?? this.selectedKeysOnly,
      selectedKeys: selectedKeys ?? this.selectedKeys,
    );
  }

  /// Validates the adapter paging contract used by dataset and adapter load
  /// calls.
  ///
  /// Offset remains the universal paging fallback: `offset` is the zero-based
  /// number of records to skip and `limit` is the requested page size. Adapters
  /// may additionally use [pageNavigation] and [pageCursor] for keyset paging.
  /// When provided, `offset` must
  /// be greater than or equal to zero and `limit` must be greater than zero.
  void validatePagingContract() {
    final requestOffset = offset;
    if (requestOffset != null && requestOffset < 0) {
      throw ArgumentError.value(
        requestOffset,
        'offset',
        'FdcDataLoadRequest.offset cannot be negative.',
      );
    }

    final requestLimit = limit;
    if (requestLimit != null && requestLimit <= 0) {
      throw ArgumentError.value(
        requestLimit,
        'limit',
        'FdcDataLoadRequest.limit must be greater than zero.',
      );
    }
  }
}

/// Rows and paging metadata returned by an adapter load.
///
/// [rows] are materialized by field name. [totalCount], when requested, is the
/// total number of rows matching the effective query before paging.
class FdcDataLoadResult {
  /// Creates a [FdcDataLoadResult].
  const FdcDataLoadResult({
    required this.rows,
    this.totalCount,
    this.fields,
    this.internalRowIds,
    this.internalNextRowId,
    this.previousPageCursor,
    this.nextPageCursor,
  });

  /// Loaded row maps keyed by dataset field name.
  final List<Map<String, Object?>> rows;

  /// Total number of rows matching the query before paging, when requested.
  final int? totalCount;

  /// Optional schema metadata returned by the adapter.
  ///
  /// Dataset open APIs adopt these fields only when the dataset was created
  /// without explicit fields. Explicit dataset fields always remain
  /// authoritative.
  final List<FdcFieldDef>? fields;

  /// Optional stable adapter-local row identities.
  ///
  /// Memory-style adapters can provide these so datasets without explicit
  /// key fields still have a stable internal identity for update/delete
  /// matching. These ids are internal and are never exposed as dataset fields.
  final List<int>? internalRowIds;

  /// Optional next internal row id for adapters that expose [internalRowIds].
  ///
  /// This lets datasets allocate new inserted records without colliding with
  /// adapter rows that were not included in a filtered/paged load result.
  final int? internalNextRowId;

  /// Opaque adapter cursor for loading the page before this result.
  final Object? previousPageCursor;

  /// Opaque adapter cursor for loading the page after this result.
  final Object? nextPageCursor;
}
