// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateScrollColumns on _FdcGridState {
  VoidCallback _beginKeyboardMoveGuard({bool suppressColumnReveal = true}) {
    final horizontalOffsetToPreserve = _scrollCoordinator.liveHorizontalOffset;
    if (suppressColumnReveal) {
      _suppressKeyboardColumnReveal = true;
    }
    _scrollCoordinator.beginHorizontalOffsetRestore(horizontalOffsetToPreserve);
    _restoreHorizontalScrollOffsetNow(horizontalOffsetToPreserve);

    var ended = false;
    return () {
      if (ended) {
        return;
      }
      ended = true;
      _restoreHorizontalOffsetAfterLayout(
        horizontalOffsetToPreserve,
        settleAfterNextFrame: true,
        settleFrameCount: 4,
        horizontalOffsetRestoreAlreadyLocked: true,
      );
      if (suppressColumnReveal) {
        _clearKeyboardRevealSuppression(remainingFrames: 5);
      }
    };
  }

  void _clearKeyboardRevealSuppression({required int remainingFrames}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (remainingFrames > 0) {
        _clearKeyboardRevealSuppression(remainingFrames: remainingFrames - 1);
        return;
      }
      _suppressKeyboardColumnReveal = false;
    });
  }

  void _scrollRowIntoView(int rowIndex) {
    if (!_scrollCoordinator.hasVerticalClients) {
      return;
    }

    final rowTop = _gridRowTop(rowIndex);
    final rowBottom = rowTop + widget.options.resolvedRowHeight;

    _scroll.runRowSnap(() {
      final bodyViewportHeight = _visibleRowsViewportHeight;
      if (bodyViewportHeight > 0 && widget.options.resolvedRowHeight > 0) {
        // The visible vertical viewport for row navigation is the body rows
        // region only. Footer panels such as the summary row and status bar
        // live below it and must not be counted when revealing an appended row.
        // Relying only on ScrollMetrics can be stale for one frame after an
        // append, so calculate the target against the current grid layout.
        final maxOffset = math.max(
          0.0,
          _gridRowsContentHeight - bodyViewportHeight,
        );
        final currentOffset = _scrollCoordinator.currentVerticalOffset;
        final currentBottom = currentOffset + bodyViewportHeight;

        var targetOffset = currentOffset;
        if (rowTop < currentOffset) {
          targetOffset = rowTop;
        } else if (rowIndex == _rows.length - 1 &&
            !_isDetailRowExpanded(rowIndex)) {
          // Boundary navigation and append must land on the actual end of the
          // scrollable content. When the final row itself owns an expanded
          // detail panel, however, maxOffset points into that panel and can
          // hide the owning row during record navigation. The dedicated
          // detail-row reveal path owns panel visibility in that case.
          targetOffset = maxOffset;
        } else if (rowBottom > currentBottom) {
          final minimumOffset = rowBottom - bodyViewportHeight;
          targetOffset =
              widget.options.verticalScrollMode ==
                  FdcGridVerticalScrollMode.recordScroll
              ? _gridRowTopAtOrAfter(minimumOffset)
              : minimumOffset;
        }

        final nextOffset = targetOffset.clamp(0.0, maxOffset).toDouble();
        if ((nextOffset - currentOffset).abs() >= 0.5) {
          _scrollCoordinator.jumpVerticalTo(nextOffset);
        }
        return;
      }

      _scrollCoordinator.revealVerticalRange(
        leadingEdge: rowTop,
        trailingEdge: rowBottom,
      );
    });
  }

  void _scrollRowIntoViewAfterLayout(int rowIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || rowIndex < 0 || rowIndex >= _rows.length) {
        return;
      }
      _scrollRowIntoView(rowIndex);
    });
  }

  void _scrollColumnIntoView(
    int columnIndex, {
    bool preferLeadingContext = false,
  }) {
    if (!_scrollCoordinator.hasHorizontalClients ||
        columnIndex < 0 ||
        columnIndex >= _visibleColumns.length) {
      return;
    }

    if (_isPinnedColumnIndex(columnIndex)) {
      return;
    }

    final columnLeft = _columnOffset(columnIndex);
    final columnRight = columnLeft + _columnWidthAt(columnIndex);

    _scroll.cancelHorizontalSnap();
    _scroll.runColumnSnap(() {
      _scrollCoordinator.revealHorizontalRange(
        leadingEdge: columnLeft,
        trailingEdge: columnRight,
        preferLeadingContext: preferLeadingContext,
      );
    });
  }

  void _scrollColumnIntoViewIfOutside(
    int columnIndex, {
    bool preferLeadingContext = false,
  }) {
    if (!_scrollCoordinator.hasHorizontalClients ||
        columnIndex < 0 ||
        columnIndex >= _visibleColumns.length) {
      return;
    }

    if (_isPinnedColumnIndex(columnIndex)) {
      return;
    }

    final columnLeft = _columnOffset(columnIndex);
    final columnRight = columnLeft + _columnWidthAt(columnIndex);

    if (!_scrollCoordinator.isHorizontalRangeOutside(
      leadingEdge: columnLeft,
      trailingEdge: columnRight,
    )) {
      return;
    }

    _scrollColumnIntoView(
      columnIndex,
      preferLeadingContext: preferLeadingContext,
    );
  }

  void _scrollToFirstColumn() {
    if (!_scrollCoordinator.hasHorizontalClients) {
      return;
    }

    _scroll.cancelHorizontalSnap();
    _scrollCoordinator.jumpHorizontalToStart();
  }

  void _scrollToFirstColumnAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollToFirstColumn();
    });
  }

  void _revealColumnIfNeededAfterLayout(
    int columnIndex, {
    bool preferLeadingContext = false,
    int delayFrameCount = 0,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (delayFrameCount > 0) {
        _revealColumnIfNeededAfterLayout(
          columnIndex,
          preferLeadingContext: preferLeadingContext,
          delayFrameCount: delayFrameCount - 1,
        );
        return;
      }

      if (!_scrollCoordinator.hasHorizontalClients ||
          columnIndex < 0 ||
          columnIndex >= _visibleColumns.length) {
        return;
      }

      if (_isPinnedColumnIndex(columnIndex)) {
        return;
      }

      final columnLeft = _columnOffset(columnIndex);
      final columnRight = columnLeft + _columnWidthAt(columnIndex);

      if (_scrollCoordinator.isHorizontalRangeOutside(
        leadingEdge: columnLeft,
        trailingEdge: columnRight,
      )) {
        _scrollColumnIntoView(
          columnIndex,
          preferLeadingContext: preferLeadingContext,
        );
      }
    });
  }

  void _scrollToLastColumn() {
    if (!_scrollCoordinator.hasHorizontalClients) {
      return;
    }

    _scroll.cancelHorizontalSnap();
    _scrollCoordinator.jumpHorizontalToEnd();
  }

  void _scrollColumnIntoViewAfterLayout(
    int columnIndex, {
    bool preferLeadingContext = false,
    int delayFrameCount = 0,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (delayFrameCount > 0) {
        _scrollColumnIntoViewAfterLayout(
          columnIndex,
          preferLeadingContext: preferLeadingContext,
          delayFrameCount: delayFrameCount - 1,
        );
        return;
      }
      _scrollColumnIntoView(
        columnIndex,
        preferLeadingContext: preferLeadingContext,
      );
    });
  }

  void _restoreHorizontalScrollOffsetNow(double offset) {
    _scroll.cancelHorizontalSnap();
    _scrollCoordinator.restoreHorizontalOffset(offset);
  }

  void _restoreVerticalScrollOffsetNow(double offset) {
    _scroll.cancelVerticalSnap();
    _scroll.clearVerticalScrollOrigin();
    _scrollCoordinator.restoreVerticalOffset(offset);
  }

  void _restoreVerticalOffsetAfterLayout(
    double offset, {
    bool settleAfterNextFrame = false,
    int? settleFrameCount,
    bool verticalOffsetRestoreAlreadyLocked = false,
  }) {
    final restoreGeneration = _verticalOffsetRestoreGeneration;
    if (!verticalOffsetRestoreAlreadyLocked) {
      _scrollCoordinator.beginVerticalOffsetRestore(offset);
    }
    _restoreVerticalScrollOffsetNow(offset);

    final framesToSettle = math.max(
      1,
      settleFrameCount ?? (settleAfterNextFrame ? 2 : 1),
    );

    void restoreFrame(int remainingFrames) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (restoreGeneration != _verticalOffsetRestoreGeneration) {
          return;
        }

        if (!mounted) {
          _scrollCoordinator.endVerticalOffsetRestore();
          return;
        }

        _restoreVerticalScrollOffsetNow(offset);

        if (remainingFrames <= 1) {
          _scrollCoordinator.endVerticalOffsetRestore();
          return;
        }

        restoreFrame(remainingFrames - 1);
      });
    }

    restoreFrame(framesToSettle);
  }

  void _cancelVerticalRestoreForUserInput() {
    _verticalOffsetRestoreGeneration++;
    _scrollCoordinator.cancelVerticalOffsetRestore();
  }

  void _restoreViewportOffsetsAfterLayout({
    required double horizontalOffset,
    required double verticalOffset,
    bool settleAfterNextFrame = false,
    int? settleFrameCount,
    bool horizontalOffsetRestoreAlreadyLocked = false,
    bool verticalOffsetRestoreAlreadyLocked = false,
  }) {
    _restoreHorizontalOffsetAfterLayout(
      horizontalOffset,
      settleAfterNextFrame: settleAfterNextFrame,
      settleFrameCount: settleFrameCount,
      horizontalOffsetRestoreAlreadyLocked:
          horizontalOffsetRestoreAlreadyLocked,
    );
    _restoreVerticalOffsetAfterLayout(
      verticalOffset,
      settleAfterNextFrame: settleAfterNextFrame,
      settleFrameCount: settleFrameCount,
      verticalOffsetRestoreAlreadyLocked: verticalOffsetRestoreAlreadyLocked,
    );
  }

  void _preserveHorizontalOffsetAfterLayout(
    double offset, {
    bool horizontalOffsetRestoreAlreadyLocked = false,
  }) {
    if (!horizontalOffsetRestoreAlreadyLocked) {
      _scrollCoordinator.beginHorizontalOffsetRestore(offset);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (!mounted) {
          return;
        }

        if (_horizontalOffsetNeedsRestore(offset)) {
          _restoreHorizontalScrollOffsetNow(offset);
        }
      } finally {
        _scrollCoordinator.endHorizontalOffsetRestore();
      }
    });
  }

  bool _horizontalOffsetNeedsRestore(double offset) {
    final targetOffset = offset
        .clamp(
          _scrollCoordinator.horizontalMinScrollExtent,
          math.max(_scrollCoordinator.horizontalMaxScrollExtent, offset),
        )
        .toDouble();
    return (_scrollCoordinator.currentHorizontalOffset - targetOffset).abs() >
            0.5 ||
        (_scrollCoordinator.liveHorizontalOffset - targetOffset).abs() > 0.5;
  }

  void _restoreHorizontalOffsetAfterLayout(
    double offset, {
    bool settleAfterNextFrame = false,
    int? settleFrameCount,
    bool horizontalOffsetRestoreAlreadyLocked = false,
  }) {
    if (!horizontalOffsetRestoreAlreadyLocked) {
      _scrollCoordinator.beginHorizontalOffsetRestore(offset);
    }
    _restoreHorizontalScrollOffsetNow(offset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _scrollCoordinator.endHorizontalOffsetRestore();
        return;
      }

      _restoreHorizontalScrollOffsetNow(offset);

      final framesToSettle = math.max(
        1,
        settleFrameCount ?? (settleAfterNextFrame ? 2 : 1),
      );

      void restoreFrame(int remainingFrames) {
        if (remainingFrames <= 1) {
          _scrollCoordinator.endHorizontalOffsetRestore();
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            _scrollCoordinator.endHorizontalOffsetRestore();
            return;
          }
          _restoreHorizontalScrollOffsetNow(offset);
          restoreFrame(remainingFrames - 1);
        });
      }

      restoreFrame(framesToSettle);
    });
  }

  bool _isPinnedColumnIndex(int columnIndex) {
    final bands = _columnBandsCache;
    return bands.pinnedLeft.columnIndexes.contains(columnIndex) ||
        bands.pinnedRight.columnIndexes.contains(columnIndex);
  }

  int _localColumnIndexInLayout(
    FdcGridColumnBandLayout layout,
    int columnIndex,
  ) {
    return layout.columnIndexes.indexOf(columnIndex);
  }

  double _columnOffset(int columnIndex) {
    final scrollableLayout = _columnBandLayouts().scrollable;
    final localIndex = _localColumnIndexInLayout(scrollableLayout, columnIndex);
    if (localIndex == -1) {
      return 0.0;
    }
    return scrollableLayout.columnOffsetAt(
      localIndex,
      fallbackWidth: widget.options.resolvedDefaultColumnWidth,
    );
  }

  double _columnWidthAt(int columnIndex) {
    final layouts = _columnBandLayouts();
    for (final layout in [
      layouts.pinnedLeft,
      layouts.scrollable,
      layouts.pinnedRight,
    ]) {
      final localIndex = _localColumnIndexInLayout(layout, columnIndex);
      if (localIndex != -1) {
        return layout.columnWidthAt(
          localIndex,
          fallbackWidth: widget.options.resolvedDefaultColumnWidth,
        );
      }
    }
    return widget.options.resolvedDefaultColumnWidth;
  }

  double _baseScrollableDataWidth() {
    final scrollableBand = _columnBandsCache.scrollable;
    return _columnSizing.baseGridWidth(
      scrollableBand.columns,
      runtimeColumnIds: scrollableBand.runtimeColumnIds,
      defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
    );
  }

  double _basePinnedDataWidth() {
    double bandWidth(FdcGridColumnBand band) {
      return _columnSizing.baseGridWidth(
        band.columns,
        runtimeColumnIds: band.runtimeColumnIds,
        defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
      );
    }

    return bandWidth(_columnBandsCache.pinnedLeft) +
        bandWidth(_columnBandsCache.pinnedRight);
  }

  void _clampVerticalScrollOffsetAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCoordinator.hasVerticalClients) {
        return;
      }

      _scroll.runRowSnap(() {
        _scrollCoordinator.clampVerticalToExtents();
      });
    });
  }

  void _resetVerticalScrollToTopAfterLayout({
    String reason = 'unspecified',
    double? preserveHorizontalOffset,
    bool horizontalOffsetRestoreAlreadyLocked = false,
  }) {
    if (preserveHorizontalOffset != null) {
      if (!horizontalOffsetRestoreAlreadyLocked) {
        _scrollCoordinator.beginHorizontalOffsetRestore(
          preserveHorizontalOffset,
        );
      }
      _restoreHorizontalScrollOffsetNow(preserveHorizontalOffset);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        if (preserveHorizontalOffset != null) {
          _scrollCoordinator.endHorizontalOffsetRestore();
        }
        return;
      }

      if (_scrollCoordinator.hasVerticalClients) {
        _scrollCoordinator.jumpVerticalToStart();
      }

      if (preserveHorizontalOffset == null) {
        return;
      }

      _restoreHorizontalScrollOffsetNow(preserveHorizontalOffset);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _restoreHorizontalScrollOffsetNow(preserveHorizontalOffset);
        }
        _scrollCoordinator.endHorizontalOffsetRestore();
      });
    });
  }
}
