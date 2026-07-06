// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../fdc_data_adapter.dart';
import '../fdc_data_paging.dart';

/// Internal owner of dataset paging state and page-navigation orchestration.
///
/// The dataset remains the public facade and owns adapter loading, row commit,
/// view rebuilding, and query conversion. This coordinator owns page runtime
/// state, validates navigation arguments, and serializes infinite next-page
/// loads.
final class FdcDataSetPagingCoordinator {
  FdcDataSetPagingCoordinator({
    required FdcDataPagingOptions options,
    required Future<void> Function({
      required int pageIndex,
      int? pageSize,
      required FdcDataLoadRequest request,
      required FdcDataPageNavigation navigation,
      Object? pageCursor,
      int? loadLimit,
      required bool appendPage,
    })
    openPageCore,
  }) : _options = options,
       _pageSize = options.pageSize,
       _openPageCore = openPageCore;

  final FdcDataPagingOptions _options;
  final Future<void> Function({
    required int pageIndex,
    int? pageSize,
    required FdcDataLoadRequest request,
    required FdcDataPageNavigation navigation,
    Object? pageCursor,
    int? loadLimit,
    required bool appendPage,
  })
  _openPageCore;

  int _pageIndex = 0;
  Object? _previousPageCursor;
  Object? _nextPageCursor;
  int _pageSize;
  int? _totalRecordCount;
  int _lastPageLoadRecordCount = 0;
  Future<void>? _nextPageLoadFuture;

  int get pageIndex => _pageIndex;
  int get pageSize => _pageSize;
  int get pageOffset => _pageIndex * _pageSize;
  int? get totalRecordCount => _totalRecordCount;
  bool get isLoadingNextPage => _nextPageLoadFuture != null;

  int? get pageCount {
    final total = _totalRecordCount;
    if (!_options.enabled || total == null) return null;
    if (total == 0) return 0;
    return ((total - 1) ~/ _pageSize) + 1;
  }

  bool get hasPreviousPage => _options.enabled && _pageIndex > 0;

  bool get hasNextPage {
    if (!_options.enabled) return false;
    final count = pageCount;
    if (count == null) return _lastPageLoadRecordCount >= _pageSize;
    return _pageIndex < count - 1;
  }

  Future<void> openPage({
    int pageIndex = 0,
    int? pageSize,
    FdcDataLoadRequest request = const FdcDataLoadRequest(),
  }) => _openPageCore(
    pageIndex: pageIndex,
    pageSize: pageSize,
    request: request,
    navigation: FdcDataPageNavigation.random,
    appendPage: false,
  );

  Future<void> firstPage() => _openPageCore(
    pageIndex: 0,
    request: const FdcDataLoadRequest(),
    navigation: FdcDataPageNavigation.first,
    appendPage: false,
  );

  Future<void> previousPage() {
    if (!hasPreviousPage) return Future<void>.value();
    return _openPageCore(
      pageIndex: _pageIndex - 1,
      request: const FdcDataLoadRequest(),
      navigation: FdcDataPageNavigation.previous,
      pageCursor: _previousPageCursor,
      appendPage: false,
    );
  }

  Future<void> nextPage() {
    if (!hasNextPage) {
      return Future<void>.value();
    }
    if (!_options.usesInfinitePaging) {
      return _openPageCore(
        pageIndex: _pageIndex + 1,
        request: const FdcDataLoadRequest(),
        navigation: FdcDataPageNavigation.next,
        pageCursor: _nextPageCursor,
        appendPage: false,
      );
    }
    final running = _nextPageLoadFuture;
    if (running != null) {
      return running;
    }
    Future<void>? future;
    future =
        _openPageCore(
          pageIndex: _pageIndex + 1,
          request: const FdcDataLoadRequest(),
          navigation: FdcDataPageNavigation.next,
          pageCursor: _nextPageCursor,
          appendPage: true,
        ).whenComplete(() {
          if (identical(_nextPageLoadFuture, future)) {
            _nextPageLoadFuture = null;
          }
        });
    _nextPageLoadFuture = future;
    return future;
  }

  Future<void> lastPage() {
    final count = pageCount;
    if (count == null) {
      throw StateError(
        'Cannot navigate to the last page when totalRecordCount is unknown.',
      );
    }
    if (count == 0) {
      return _openPageCore(
        pageIndex: 0,
        request: const FdcDataLoadRequest(),
        navigation: FdcDataPageNavigation.first,
        appendPage: false,
      );
    }
    final remainder = (_totalRecordCount ?? 0) % _pageSize;
    return _openPageCore(
      pageIndex: count - 1,
      request: const FdcDataLoadRequest(),
      navigation: FdcDataPageNavigation.last,
      loadLimit: remainder == 0 ? _pageSize : remainder,
      appendPage: false,
    );
  }

  Future<void> setPageSize(int pageSize) {
    final normalized = _options.normalizePageSize(pageSize);
    return openPage(pageSize: normalized);
  }

  Future<void> refreshPage({
    FdcPageRefreshMode mode = FdcPageRefreshMode.keepPage,
  }) => openPage(
    pageIndex: mode == FdcPageRefreshMode.firstPage ? 0 : _pageIndex,
  );

  void commitLoad({
    required int pageIndex,
    required int pageSize,
    required int loadedRecordCount,
    required int? totalRecordCount,
    required Object? previousPageCursor,
    required Object? nextPageCursor,
    required bool appendPage,
    required bool preserveTotalCount,
  }) {
    _pageIndex = pageIndex;
    _pageSize = pageSize;
    _lastPageLoadRecordCount = loadedRecordCount;
    if (!preserveTotalCount) {
      _totalRecordCount = appendPage
          ? totalRecordCount ?? _totalRecordCount
          : totalRecordCount;
    }
    _previousPageCursor = previousPageCursor;
    _nextPageCursor = nextPageCursor;
  }

  void setTotalRecordCount(int? value) => _totalRecordCount = value;

  void reset() {
    _pageIndex = 0;
    _pageSize = _options.pageSize;
    _totalRecordCount = null;
    _lastPageLoadRecordCount = 0;
    _previousPageCursor = null;
    _nextPageCursor = null;
    _nextPageLoadFuture = null;
  }

  void dispose() => _nextPageLoadFuture = null;
}
