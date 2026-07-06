// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateRecordScrollRuntime on _FdcGridState {
  void _handleVerticalScrollControllerChanged() {
    if (!mounted ||
        widget.options.verticalScrollMode !=
            FdcGridVerticalScrollMode.recordScroll ||
        _scroll.snappingRows ||
        !_scrollCoordinator.hasVerticalClients) {
      return;
    }

    // In record-scroll mode the vertical scrollbar is allowed to move the
    // ScrollController freely while the user is dragging. Snapping from this
    // low-level listener can fight the Scrollbar drag recognizer and leave the
    // thumb unresponsive for the next drag. Snap only from ScrollEnd instead.
  }

  void _handleBodyVerticalDragStart() {
    _bodyVerticalDragDistance = 0.0;
    _bodyVerticalDragStartOffset = _scrollCoordinator.currentVerticalOffset;
    if (widget.options.verticalScrollMode ==
        FdcGridVerticalScrollMode.recordScroll) {
      _verticalSettleGeneration++;
      _pendingScrollbarSelectionRowIndex = null;
      _scroll.cancelVerticalSnap();
      _scroll.markVerticalDrag();
    }
  }

  void _handleBodyVerticalDragUpdate(DragUpdateDetails details) {
    _bodyVerticalDragDistance += details.delta.dy.abs();
    if (!_scrollCoordinator.hasVerticalClients) {
      return;
    }
    _scrollCoordinator.scrollVerticalBy(-details.delta.dy);
  }

  void _handleBodyVerticalDragEnd(DragEndDetails? details) {
    if (widget.options.verticalScrollMode ==
        FdcGridVerticalScrollMode.recordScroll) {
      final scrollDelta =
          (_scrollCoordinator.currentVerticalOffset -
                  _bodyVerticalDragStartOffset)
              .abs();
      final selectionSettleThreshold = math.max(
        8.0,
        widget.options.resolvedRowHeight * 0.5,
      );
      final shouldSettleSelection =
          scrollDelta >= selectionSettleThreshold &&
          _bodyVerticalDragDistance >= selectionSettleThreshold;
      _scheduleVerticalSnap(
        settleRowIndex: shouldSettleSelection
            ? _recordScrollViewportCenterRowIndex()
            : null,
      );
      _scroll.clearVerticalScrollOrigin();
    } else if (details != null) {
      // Pinned columns and the row-indicator band are detached from the center
      // ListView, so their drag gesture is forwarded through the coordinator.
      // Preserve the native ListView feel in smooth mode by handing the release
      // velocity to the attached ScrollPosition instead of ending with the last
      // manual jumpTo performed during drag updates.
      _scrollCoordinator.flingVertical(-details.velocity.pixelsPerSecond.dy);
    }
    _bodyVerticalDragDistance = 0.0;
    _bodyVerticalDragStartOffset = 0.0;
  }

  void _handleHeaderHorizontalDragStart() {
    _gridFocusNode.requestFocus();
    _headerHorizontalDragScrolling = true;
    _scroll.cancelHorizontalSnap();
  }

  void _handleHeaderHorizontalDragUpdate(double deltaX) {
    if (!_scrollCoordinator.hasHorizontalClients || deltaX == 0) {
      return;
    }

    // Header-drag scrolling is a continuous drag gesture. Do not schedule the
    // column-snap timer on every pointer move: repeatedly rearming snap while
    // the user is dragging fights the body Scrollable and makes the detached
    // header appear one step ahead of the rows. Keep the gesture purely live
    // here and perform the normal horizontal snap once, on drag end.
    _scrollCoordinator.scrollHorizontalBy(-deltaX);
  }

  void _handleHeaderHorizontalDragEnd() {
    if (!_headerHorizontalDragScrolling) {
      return;
    }

    _headerHorizontalDragScrolling = false;
    if (_scrollCoordinator.hasHorizontalClients) {
      _scheduleHorizontalSnap();
    }
  }

  bool _handleRowScrollStart(ScrollStartNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (widget.options.verticalScrollMode ==
        FdcGridVerticalScrollMode.recordScroll) {
      _verticalSettleGeneration++;
      _pendingScrollbarSelectionRowIndex = null;
      _scroll.cancelVerticalSnap();
      if (notification.dragDetails != null) {
        _scroll.markVerticalDrag();
      }
    }
    return false;
  }

  bool _handleRowScrollUpdate(ScrollUpdateNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      _maybeLoadNextAccumulatedPage(notification.metrics);
    }
    if (notification.metrics.axis != Axis.vertical ||
        widget.options.verticalScrollMode !=
            FdcGridVerticalScrollMode.recordScroll ||
        _scroll.snappingRows ||
        !_scrollCoordinator.hasVerticalClients) {
      return false;
    }

    if (_suppressEditorRecordScroll(notification)) {
      return true;
    }

    // A ScrollUpdate with dragDetails belongs to a real drag gesture. In our
    // case that means the vertical scrollbar thumb / touch drag and it should
    // remain viewport-only. Programmatic jumps from keyboard navigation
    // (PageUp/PageDown/arrow handling) also arrive with null dragDetails, so
    // only convert a null-drag update into record navigation when it was
    // preceded by a real PointerScrollEvent.
    if (notification.dragDetails != null) {
      _trackScrollbarDragSelectionCandidate(notification);
      return false;
    }

    if (!_scroll.verticalPointerWheelActive) {
      return false;
    }

    final delta = notification.scrollDelta;
    if (delta == null ||
        delta.abs() < 0.5 ||
        widget.options.resolvedRowHeight <= 0) {
      return false;
    }

    final previousOffset = (notification.metrics.pixels - delta)
        .clamp(
          notification.metrics.minScrollExtent,
          notification.metrics.maxScrollExtent,
        )
        .toDouble();

    if ((_scrollCoordinator.currentVerticalOffset - previousOffset).abs() >=
        0.5) {
      _scroll.runRowSnap(() {
        _scrollCoordinator.jumpVerticalTo(previousOffset);
      });
    }

    _scroll.markVerticalPointerWheel();
    _scrollCurrentRecordBy(delta > 0 ? 1 : -1);
    return true;
  }

  bool _suppressEditorRecordScroll(ScrollUpdateNotification notification) {
    if (_editingCell == null ||
        notification.dragDetails != null ||
        _scroll.verticalPointerWheelActive ||
        widget.options.resolvedRowHeight <= 0) {
      return false;
    }

    final delta = notification.scrollDelta;
    if (delta == null || delta.abs() < 0.5) {
      return false;
    }

    // Focused EditableText/RenderEditable can call showOnScreen when the
    // editor is on the bottom visible row. In record-scroll mode that produces
    // a small pixel scroll, briefly exposing part of the next row, and the
    // normal row snap then moves it back. Treat only small non-user, non-wheel
    // scroll deltas as implicit editor reveal attempts; keyboard/page
    // navigation still uses explicit row-sized jumps and remains untouched.
    if (delta.abs() >= widget.options.resolvedRowHeight * 0.75) {
      return false;
    }

    final previousOffset = (notification.metrics.pixels - delta)
        .clamp(
          notification.metrics.minScrollExtent,
          notification.metrics.maxScrollExtent,
        )
        .toDouble();

    _scroll.runRowSnap(() {
      _scrollCoordinator.jumpVerticalTo(previousOffset);
    });
    return true;
  }

  bool _handleRowScrollEnd(ScrollEndNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (widget.options.verticalScrollMode ==
        FdcGridVerticalScrollMode.recordScroll) {
      final verticalDragActive = _scroll.verticalDragActive;
      final settleRowIndex = verticalDragActive
          ? _pendingScrollbarSelectionRowIndex
          : null;

      if (!verticalDragActive || settleRowIndex != null) {
        _scheduleVerticalSnap(settleRowIndex: settleRowIndex);
      } else {
        // A plain click/tap can produce a ScrollStart/ScrollEnd pair without a
        // meaningful drag update. Do not settle selection to the viewport
        // center in that case; it makes the active cell jump to an unrelated
        // visible row, especially at the top of a record-scroll grid. Real
        // scrollbar/list drags set _pendingScrollbarSelectionRowIndex from
        // ScrollUpdateNotification, while pinned/body drags schedule their own
        // threshold-guarded center-row settle in _handleBodyVerticalDragEnd.
        _pendingScrollbarSelectionRowIndex = null;
      }

      if (verticalDragActive) {
        _scroll.clearVerticalScrollOrigin();
      }
    }
    return false;
  }

  void _trackScrollbarDragSelectionCandidate(
    ScrollUpdateNotification notification,
  ) {
    if (widget.options.resolvedRowHeight <= 0 || _rows.isEmpty) {
      _pendingScrollbarSelectionRowIndex = null;
      return;
    }

    final dragDetails = notification.dragDetails;
    if (dragDetails == null) {
      return;
    }

    final viewport = notification.metrics.viewportDimension;
    final localY = dragDetails.localPosition.dy
        .clamp(0.0, math.max(0.0, viewport - 0.1))
        .toDouble();
    final rowIndex = _gridRowIndexAtOffset(
      notification.metrics.pixels + localY,
    );

    _pendingScrollbarSelectionRowIndex = rowIndex;
  }

  int? _recordScrollViewportCenterRowIndex() {
    if (!_scrollCoordinator.hasVerticalClients ||
        widget.options.resolvedRowHeight <= 0 ||
        _rows.isEmpty) {
      return null;
    }

    final centerOffset =
        _scrollCoordinator.currentVerticalOffset +
        _scrollCoordinator.verticalViewportDimension(0.0) / 2;
    return _gridRowIndexAtOffset(centerOffset);
  }

  void _snapVerticalScrollOffset({bool updateCurrentRecord = false}) {
    if (widget.options.verticalScrollMode !=
            FdcGridVerticalScrollMode.recordScroll ||
        _scroll.snappingRows ||
        !_scrollCoordinator.hasVerticalClients ||
        widget.options.resolvedRowHeight <= 0) {
      return;
    }

    final currentOffset = _scrollCoordinator.currentVerticalOffset;
    final minOffset = _scrollCoordinator.verticalMinScrollExtent;
    final maxOffset = _scrollCoordinator.verticalMaxScrollExtent;
    final targetOffset = (currentOffset - minOffset).abs() < 0.5
        ? minOffset
        : (currentOffset - maxOffset).abs() < 0.5
        ? maxOffset
        : _nearestGridRowTop(currentOffset);
    final nextOffset = targetOffset.clamp(minOffset, maxOffset).toDouble();

    if ((nextOffset - currentOffset).abs() >= 0.5) {
      _scroll.runRowSnap(() {
        _scrollCoordinator.jumpVerticalTo(nextOffset);
      });
    }

    if (updateCurrentRecord) {
      _syncCurrentRecordFromVerticalScroll(nextOffset);
    }
  }

  void _syncCurrentRecordFromVerticalScroll(double scrollOffset) {
    if (widget.options.verticalScrollMode !=
            FdcGridVerticalScrollMode.recordScroll ||
        widget.options.resolvedRowHeight <= 0 ||
        _rows.isEmpty) {
      return;
    }

    final rowIndex = _gridRowIndexAtOffset(scrollOffset);
    final columnIndex = _currentScrollableSelectionColumnIndex();
    _activateRecordScrollSelection(
      rowIndex,
      columnIndex,
      focusReason: FdcGridFocusChangeReason.datasetScroll,
    );
  }

  int? _currentScrollableSelectionColumnIndex() {
    final columns = _visibleColumns;
    if (columns.isEmpty) {
      return null;
    }

    final current = _selectedCell?.columnIndex;
    if (current != null && current >= 0 && current < columns.length) {
      return current;
    }

    return columns.isEmpty ? null : 0;
  }

  bool _isPointerOverColumnHeader(PointerScrollEvent event) {
    if (_effectiveHeaderHeight <= 0) {
      return false;
    }

    final localY = event.localPosition.dy;
    return localY >= 0 && localY <= _effectiveHeaderHeight;
  }

  void _handleSummaryPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }

    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      if (event is! PointerScrollEvent) {
        return;
      }

      _gridFocusNode.requestFocus();
      final horizontalDelta = event.scrollDelta.dx != 0
          ? event.scrollDelta.dx
          : _isShiftPressed()
          ? event.scrollDelta.dy
          : 0.0;
      if (horizontalDelta != 0) {
        _scrollHorizontalBy(horizontalDelta);
      }
    });
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }
    if (_rangeSelectionModifierActive ||
        _rangeSelectionSession.pointerDragActive) {
      GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
      return;
    }

    if (_isPointerOverColumnHeader(event)) {
      GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
      return;
    }

    // Cancel a pending viewport restore as soon as vertical user input is
    // observed. This only invalidates the restore generation; focus, scrolling,
    // and detached-region repaint side effects remain inside the resolver
    // winner below so nested scrollables stay isolated.
    if (event.scrollDelta.dy != 0) {
      _cancelVerticalRestoreForUserInput();
    }

    final verticalRecordWheel =
        widget.options.verticalScrollMode ==
            FdcGridVerticalScrollMode.recordScroll &&
        event.scrollDelta.dy != 0 &&
        event.scrollDelta.dx == 0 &&
        !_isShiftPressed();
    if (verticalRecordWheel) {
      // Mark the origin before the ListView can translate the pointer signal
      // into a native pixel ScrollUpdate. If the resolver callback below wins,
      // it will perform the same record navigation directly; if it does not,
      // _handleRowScrollUpdate can still recognize the update as mouse-wheel
      // originated instead of confusing it with PageUp/PageDown jumpTo calls.
      _scroll.markVerticalPointerWheel();
    }

    GestureBinding.instance.pointerSignalResolver.register(event, (event) {
      if (event is PointerScrollEvent) {
        _handleResolvedPointerScroll(event);
      }
    });
  }

  void _handleResolvedPointerScroll(PointerScrollEvent event) {
    // Side effects belong exclusively to the resolver winner. A scrollable
    // hosted inside detail content registers for the same pointer signal; if
    // it wins, the parent grid must not cancel restores, request focus, or
    // repaint its detached vertical regions.
    _gridFocusNode.requestFocus();

    final horizontalDelta = event.scrollDelta.dx != 0
        ? event.scrollDelta.dx
        : _isShiftPressed()
        ? event.scrollDelta.dy
        : 0.0;
    if (horizontalDelta != 0) {
      _scrollHorizontalBy(horizontalDelta);
      return;
    }

    final verticalDelta = event.scrollDelta.dy;
    if (verticalDelta != 0) {
      if (widget.options.verticalScrollMode ==
          FdcGridVerticalScrollMode.recordScroll) {
        final rowDelta = verticalDelta > 0 ? 1 : -1;
        _scroll.markVerticalPointerWheel();
        _scrollCurrentRecordBy(rowDelta);
      } else {
        _scrollVerticalBy(verticalDelta);
      }
    }
  }

  void _scrollHorizontalBy(double delta) {
    if (_scrollCoordinator.scrollHorizontalBy(delta)) {
      _scheduleHorizontalSnap();
    }
  }

  void _scrollVerticalBy(double delta) {
    if (!_scrollCoordinator.scrollVerticalBy(delta)) {
      return;
    }
    if (widget.options.verticalScrollMode ==
        FdcGridVerticalScrollMode.recordScroll) {
      _scheduleVerticalSnap();
    }
  }

  void _scrollCurrentRecordBy(int rowDelta) {
    if (rowDelta == 0 ||
        widget.options.verticalScrollMode !=
            FdcGridVerticalScrollMode.recordScroll ||
        !_scrollCoordinator.hasVerticalClients ||
        widget.options.resolvedRowHeight <= 0 ||
        _rows.isEmpty) {
      return;
    }

    final currentRow =
        _selectedCell?.rowIndex ??
        FdcDataSetInternal.activeIndex(widget.dataSet);
    if (currentRow < 0 || currentRow >= _rows.length) {
      final visible = _visibleRecordScrollRange();
      if (visible != null) {
        _activateVisibleRecordScrollRow(
          rowDelta > 0 ? visible.firstRow : visible.lastRow,
        );
        return;
      }
      _activateVisibleRecordScrollRow(rowDelta > 0 ? 0 : _rows.length - 1);
      return;
    }

    final visible = _visibleRecordScrollRange();
    if (visible != null &&
        (currentRow < visible.firstRow || currentRow > visible.lastRow)) {
      _activateVisibleRecordScrollRow(
        rowDelta > 0 ? visible.firstRow : visible.lastRow,
      );
      return;
    }

    final nextRow = (currentRow + rowDelta).clamp(0, _rows.length - 1).toInt();
    if (nextRow == currentRow) {
      return;
    }

    if (visible == null) {
      _activateVisibleRecordScrollRow(nextRow);
      return;
    }

    _activateVisibleRecordScrollRow(nextRow);
    _scrollRowIntoView(nextRow);
  }

  bool _activateVisibleRecordScrollRow(
    int rowIndex, {
    FdcGridFocusChangeReason focusReason =
        FdcGridFocusChangeReason.datasetScroll,
  }) {
    final columnIndex = _currentScrollableSelectionColumnIndex();
    if (!_postCurrentRowIfLeaving(rowIndex)) {
      return false;
    }
    if (!_activateRecordScrollSelection(
      rowIndex,
      columnIndex,
      focusReason: focusReason,
    )) {
      return false;
    }
    return true;
  }

  bool _activateRecordScrollSelection(
    int rowIndex,
    int? columnIndex, {
    required FdcGridFocusChangeReason focusReason,
  }) {
    if (!_syncDataSetCurrentRow(rowIndex)) {
      return false;
    }

    final previousFocus = _currentGridFocusSnapshot();
    final cell = columnIndex == null ? null : _cellRef(rowIndex, columnIndex);
    _selectedRowIndex = rowIndex;
    _selectedCell = cell;
    _editingCell = null;
    _editAtEndCell = null;
    _clearPendingEditText();
    _clearEditingOriginalValue();
    _syncInteractionState();
    _emitGridFocusEvents(
      previousFocus,
      _currentGridFocusSnapshot(),
      focusReason,
    );
    _focusGridForSelectedCell();
    return true;
  }

  FdcVisibleRecordScrollRange? _visibleRecordScrollRange() {
    if (!_scrollCoordinator.hasVerticalClients ||
        widget.options.resolvedRowHeight <= 0) {
      return null;
    }

    final firstRow = _gridRowIndexAtOffset(
      _scrollCoordinator.currentVerticalOffset,
    );
    final viewportBottom =
        _scrollCoordinator.currentVerticalOffset +
        _scrollCoordinator.verticalViewportDimension(0.0);
    final lastRow = _gridRowIndexAtOffset(
      math.max(_scrollCoordinator.currentVerticalOffset, viewportBottom - 0.1),
    );
    return FdcVisibleRecordScrollRange(firstRow, lastRow);
  }

  bool _isShiftPressed() {
    return FdcKeyUtils.isShiftPressed;
  }

  void _scheduleVerticalSnap({int? settleRowIndex}) {
    if (widget.options.verticalScrollMode !=
        FdcGridVerticalScrollMode.recordScroll) {
      return;
    }

    final settleGeneration = _verticalSettleGeneration;
    _scroll.scheduleVerticalSnap(() {
      if (!mounted || settleGeneration != _verticalSettleGeneration) {
        return;
      }

      // A scrollbar drag is viewport-only while the user is dragging. Once the
      // drag ends, settle selection to the row nearest the mouse/thumb position
      // so the active record does not remain hidden outside the viewport.
      _snapVerticalScrollOffset();

      final rowIndex = settleRowIndex;
      _pendingScrollbarSelectionRowIndex = null;
      if (rowIndex != null) {
        _activateVisibleRecordScrollRow(
          rowIndex.clamp(0, _rows.length - 1).toInt(),
        );
      }
    });
  }

  void _scheduleHorizontalSnap() {
    if (widget.options.horizontalScrollMode !=
        FdcGridHorizontalScrollMode.columnSnap) {
      return;
    }

    _scroll.scheduleHorizontalSnap(() {
      if (!mounted) {
        return;
      }
      _snapHorizontalScrollOffset();
    });
  }

  bool _handleColumnScrollUpdate(ScrollUpdateNotification _) {
    return false;
  }

  bool _handleColumnScrollEnd(ScrollEndNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) {
      return false;
    }

    // A horizontal ScrollEndNotification can be dispatched from
    // ScrollPosition.applyNewDimensions() while Flutter is relaying out the
    // center scrollable during a column resize. Snapping from that path calls
    // jumpTo()/ValueNotifier.notifyListeners() during layout and triggers
    // "Build scheduled during frame". While the resize lock is active, the
    // locked horizontal offset is already the visual source of truth; the final
    // clamp/restore happens when the resize lock is released.
    if (_scrollCoordinator.horizontalResizeLocked) {
      return false;
    }

    // Header-drag scrolling drives the real horizontal ScrollController through
    // coordinator.jumpTo(). Flutter can emit ScrollEndNotification after those
    // programmatic jumps while the pointer is still moving. Do not treat those
    // transient ends as completed user scrolls; otherwise column snap can fire
    // during the drag and the detached header/body can temporarily diverge.
    // The drag-end callback schedules one final snap once the gesture is done.
    if (_headerHorizontalDragScrolling) {
      return true;
    }

    if (widget.options.horizontalScrollMode !=
        FdcGridHorizontalScrollMode.columnSnap) {
      return false;
    }

    _snapHorizontalScrollOffset();
    return false;
  }

  void _snapHorizontalScrollOffset() {
    if (widget.options.horizontalScrollMode !=
            FdcGridHorizontalScrollMode.columnSnap ||
        _scroll.snappingColumns ||
        _scrollCoordinator.horizontalResizeLocked ||
        !_scrollCoordinator.hasHorizontalClients) {
      return;
    }

    final currentOffset = _scrollCoordinator.currentHorizontalOffset;
    final targetOffset = _nearestColumnSnapOffset(
      currentOffset,
      _scrollCoordinator.horizontalMaxScrollExtent,
    );
    final nextOffset = targetOffset
        .clamp(
          _scrollCoordinator.horizontalMinScrollExtent,
          _scrollCoordinator.horizontalMaxScrollExtent,
        )
        .toDouble();
    if ((nextOffset - currentOffset).abs() < 0.5) {
      return;
    }

    _scroll.runColumnSnap(() {
      _scrollCoordinator.jumpHorizontalTo(nextOffset);
    });
  }

  double _nearestColumnSnapOffset(double currentOffset, double maxOffset) {
    var bestOffset = 0.0;
    var bestDistance = currentOffset.abs();
    var columnOffset = 0.0;

    void consider(double offset) {
      final distance = (currentOffset - offset).abs();
      if (distance < bestDistance) {
        bestOffset = offset;
        bestDistance = distance;
      }
    }

    final scrollableLayout = _columnBandLayouts().scrollable;
    for (
      var localIndex = 0;
      localIndex < scrollableLayout.length;
      localIndex++
    ) {
      columnOffset += scrollableLayout.columnWidthAt(
        localIndex,
        fallbackWidth: widget.options.resolvedDefaultColumnWidth,
      );
      if (columnOffset <= maxOffset) {
        consider(columnOffset);
      } else {
        break;
      }
    }

    consider(maxOffset);
    return bestOffset;
  }

  void _maybeLoadNextAccumulatedPage(ScrollMetrics metrics) {
    final dataSet = widget.dataSet;
    if (!mounted ||
        !dataSet.paging.isInfinite ||
        !dataSet.isOpen ||
        dataSet.state != FdcDataSetState.browse ||
        dataSet.paging.isLoadingNextPage ||
        !dataSet.paging.hasNextPage ||
        dataSet.work.isWorking) {
      return;
    }
    final loadedExtent = metrics.maxScrollExtent + metrics.viewportDimension;
    if (loadedExtent <= 0) {
      unawaited(dataSet.paging.nextPage());
      return;
    }
    final visibleTrailingEdge = metrics.pixels + metrics.viewportDimension;
    final visibleRatio = (visibleTrailingEdge / loadedExtent).clamp(0.0, 1.0);
    if (visibleRatio >= dataSet.paging.infiniteLoadThreshold) {
      unawaited(dataSet.paging.nextPage());
    }
  }

  void _scheduleAccumulatedPageFillCheck() {
    if (!widget.dataSet.paging.isInfinite) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCoordinator.hasVerticalClients) {
        return;
      }
      _maybeLoadNextAccumulatedPage(
        _scrollCoordinator.verticalFlutterController.position,
      );
    });
  }
}
