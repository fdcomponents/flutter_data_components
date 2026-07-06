// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Dataset paging options and state helpers.
///
/// Paging is adapter-driven. By default the dataset keeps only the active page
/// in memory. With [FdcDataPagingMode.infinite], sequential next-page loads
/// append rows while the adapter contract remains unchanged.
///
/// The adapter contract is offset based: `offset = pageIndex * pageSize` and
/// `limit = pageSize`. Offsets must be zero or positive and limits must be
/// greater than zero.
enum FdcDataPagingMode {
  /// Keeps only the active page in the dataset view.
  standard,

  /// Appends sequential next pages to the current dataset view.
  infinite,
}

/// Configures adapter-backed dataset paging.
///
/// When [enabled] is `false`, the dataset requests the full adapter result set.
/// When enabled, [pageSize] controls the requested page size, [mode] selects
/// replacement or accumulating infinite paging, and [requireTotalCount]
/// requests a backend total for page navigation and record information.
class FdcDataPagingOptions {
  /// Creates a [FdcDataPagingOptions].
  const FdcDataPagingOptions({
    this.enabled = false,
    this.pageSize = 1000,
    this.maxPageSize = 10000,
    this.requireTotalCount = false,
    this.mode = FdcDataPagingMode.standard,
    this.infiniteLoadThreshold = 0.70,
  });

  /// Creates a [FdcDataPagingOptions].
  const FdcDataPagingOptions.disabled()
    : enabled = false,

      /// Default page size retained by the disabled configuration.
      pageSize = 1000,

      /// Default maximum page size retained by the disabled configuration.
      maxPageSize = 10000,

      /// Disabled configurations do not require a total count.
      requireTotalCount = false,

      /// Disabled configurations retain standard replacement mode.
      mode = FdcDataPagingMode.standard,

      /// The infinite load threshold.
      infiniteLoadThreshold = 0.70;

  /// Whether adapter-backed paging is enabled.
  final bool enabled;

  /// Number of rows requested for each page.
  final int pageSize;

  /// Maximum page size accepted by [normalizePageSize].
  final int maxPageSize;

  /// Whether page loads must request the total number of matching rows.
  ///
  /// Enable this when UI features need exact page counts or global record
  /// information. Infinite paging can operate without an exact total.
  final bool requireTotalCount;

  /// Paging behavior used when [enabled] is `true`.
  final FdcDataPagingMode mode;

  /// Fraction of the currently loaded row extent that must be visible before
  /// an infinite-paging dataset preloads the next page.
  ///
  /// The default value of `0.70` starts the request when the trailing edge of
  /// the grid viewport reaches approximately 70% of the loaded content.
  final double infiniteLoadThreshold;

  /// Whether paging is enabled in accumulating infinite mode.
  bool get usesInfinitePaging => mode == FdcDataPagingMode.infinite;

  /// Validates paging configuration in runtime builds.
  ///
  /// Application config can be assembled dynamically in release builds. Dataset
  /// construction calls this method so invalid public paging options fail
  /// predictably outside debug mode.
  void validate() {
    if (pageSize <= 0) {
      throw RangeError.value(
        pageSize,
        'pageSize',
        'Page size must be greater than zero.',
      );
    }
    if (maxPageSize <= 0) {
      throw RangeError.value(
        maxPageSize,
        'maxPageSize',
        'Maximum page size must be greater than zero.',
      );
    }
    if (pageSize > maxPageSize) {
      throw RangeError.range(
        pageSize,
        1,
        maxPageSize,
        'pageSize',
        'Page size cannot exceed maxPageSize.',
      );
    }
    if (!infiniteLoadThreshold.isFinite ||
        infiniteLoadThreshold <= 0 ||
        infiniteLoadThreshold > 1) {
      throw RangeError.range(
        infiniteLoadThreshold,
        0,
        1,
        'infiniteLoadThreshold',
        'Infinite load threshold must be greater than zero and no greater than one.',
      );
    }
  }

  /// Validates and returns a requested page size.
  ///
  /// Throws [ArgumentError] when [value] is not positive or exceeds
  /// [maxPageSize].
  int normalizePageSize(int value) {
    if (value <= 0) {
      throw ArgumentError.value(
        value,
        'pageSize',
        'Page size must be greater than zero.',
      );
    }
    if (value > maxPageSize) {
      throw ArgumentError.value(
        value,
        'pageSize',
        'Page size cannot exceed maxPageSize ($maxPageSize).',
      );
    }
    return value;
  }
}

/// Controls which page is opened by `FdcDataSet.paging.refreshPage`.
///
/// [keepPage] reloads the current page index. It does not attempt to relocate
/// the current record if backend changes moved that record to another page.
/// [firstPage] reloads from page zero.
enum FdcPageRefreshMode {
  /// Reloads the current page index.
  keepPage,

  /// Reloads from page zero.
  firstPage,
}
