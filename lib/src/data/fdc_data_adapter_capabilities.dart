// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Declares which query and aggregate operations an adapter can execute.
///
/// The dataset validates adapter-bound filter, sort, search, paging, and
/// aggregate requests against these flags before dispatching work. Custom
/// adapters should report only capabilities they can preserve semantically.
class FdcDataAdapterCapabilities {
  /// Creates a [FdcDataAdapterCapabilities].
  const FdcDataAdapterCapabilities({
    this.filtering = false,
    this.sorting = false,
    this.paging = false,
    this.totalCount = false,
    this.search = false,
    this.aggregates = false,
    this.selectedKeyFiltering = false,
  });

  /// Creates a [FdcDataAdapterCapabilities].
  const FdcDataAdapterCapabilities.none()
    : filtering = false,

      /// Whether the adapter can execute dataset sort descriptors.
      sorting = false,

      /// Whether the adapter can load bounded pages of rows.
      paging = false,

      /// Whether load responses can report the total matching row count.
      totalCount = false,

      /// The search.
      search = false,

      /// Whether the adapter can execute aggregate queries.
      aggregates = false,

      /// Whether key-based selected-row filtering is supported.
      selectedKeyFiltering = false;

  /// Whether the adapter can execute dataset filter predicates.
  final bool filtering;

  /// Whether the adapter can execute dataset sort descriptors.
  final bool sorting;

  /// Whether the adapter can load bounded pages of rows.
  final bool paging;

  /// Whether load responses can report the total matching row count.
  final bool totalCount;

  /// Whether the adapter accepts dataset search state in load and
  /// aggregate requests and applies an adapter-side search predicate.
  ///
  /// This does not promise full semantic parity with local in-memory search.
  /// Backend adapters may support only the field types and representations
  /// that can be translated safely by that backend. Adapter documentation
  /// must describe any such subset.
  final bool search;

  /// Whether the adapter can execute aggregate queries.
  final bool aggregates;

  /// Whether the adapter understands key-based selected-row filtering.
  ///
  /// When true, the adapter must apply `selectedKeysOnly` on load requests
  /// and aggregate requests as an include-only key
  /// predicate. An active request with an empty key set must return an empty
  /// result. Paged datasets use this for `selected(true)` filtering because
  /// the full selected row set may span pages and cannot be reconstructed from
  /// the currently loaded page alone.
  final bool selectedKeyFiltering;
}
