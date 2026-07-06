// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridDetailRowRuntime on _FdcGridState {
  bool get _hasDetailRowFeature => widget.detailRow != null;

  bool get _hasExpandedDetailRows =>
      _hasDetailRowFeature && _expandedDetailRecordIds.isNotEmpty;

  bool get _detailRowContentSized => widget.detailRow?.height == null;

  double get _detailRowHeight {
    final feature = widget.detailRow;
    if (feature == null) {
      return 0.0;
    }
    final configuredHeight = feature.height ?? feature.minHeight;
    return _normalizeDetailRowHeight(configuredHeight);
  }

  double _normalizeDetailRowHeight(double height) {
    if (height <= 0 ||
        widget.options.verticalScrollMode !=
            FdcGridVerticalScrollMode.recordScroll) {
      return height;
    }
    final rowHeight = widget.options.resolvedRowHeight;
    if (rowHeight <= 0) {
      return height;
    }
    return (height / rowHeight).ceil() * rowHeight;
  }

  double _detailHeightForRecordId(int recordId) {
    final feature = widget.detailRow;
    if (feature == null) {
      return 0.0;
    }
    final fixedHeight = feature.height;
    if (fixedHeight != null) {
      return _normalizeDetailRowHeight(fixedHeight);
    }
    // Content-sized detail rows must preserve their committed measured extent.
    // Record-scroll snapping applies to fixed panels only; rounding measured
    // content would violate size-to-content semantics (for example 96 -> 126).
    return _detailRowMeasuredHeights[recordId] ?? feature.minHeight;
  }

  double _detailHeightForRow(int rowIndex) {
    final recordId = _recordIdForGridRow(rowIndex);
    return recordId == null
        ? _detailRowHeight
        : _detailHeightForRecordId(recordId);
  }

  Map<int, double> _expandedDetailRowHeights() {
    if (!_detailRowContentSized || _expandedDetailRecordIds.isEmpty) {
      return const <int, double>{};
    }
    final result = <int, double>{};
    for (final rowIndex in _expandedDetailIndices()) {
      result[rowIndex] = _detailHeightForRow(rowIndex);
    }
    return result;
  }

  Set<int> _visibleDetailRowIndices() {
    if (_visibleDetailRecordIds.isEmpty) {
      return const <int>{};
    }
    final result = <int>{};
    for (var rowIndex = 0; rowIndex < _rows.length; rowIndex++) {
      final recordId = _recordIdForGridRow(rowIndex);
      if (recordId != null && _visibleDetailRecordIds.contains(recordId)) {
        result.add(rowIndex);
      }
    }
    return result;
  }

  void _showFixedDetailRowAfterLayout(int recordId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_expandedDetailRecordIds.contains(recordId) ||
          _detailRowContentSized ||
          _visibleDetailRecordIds.contains(recordId)) {
        return;
      }
      _applyGridState(() {
        _visibleDetailRecordIds.add(recordId);
      });
    });
  }

  FdcColumnIdentity? get _detailExpanderColumnId {
    if (!_hasDetailRowFeature) {
      return null;
    }
    final layouts = _columnBandLayouts();
    final visualLayouts = <FdcGridColumnBandLayout>[
      layouts.pinnedLeft,
      layouts.scrollable,
      layouts.pinnedRight,
    ];
    for (final layout in visualLayouts) {
      for (var index = 0; index < layout.length; index++) {
        if (layout.columns[index].isDataBound) {
          return layout.runtimeColumnIds[index];
        }
      }
    }
    for (final layout in visualLayouts) {
      for (var index = 0; index < layout.length; index++) {
        if (layout.columns[index] is! FdcActionColumn) {
          return layout.runtimeColumnIds[index];
        }
      }
    }
    return null;
  }

  FdcGridDetailRowContext? _detailContextForRow(
    int rowIndex, {
    required bool expanded,
  }) {
    final sourceRowIndex = _sourceRowIndex(rowIndex);
    final recordId = _recordIdForGridRow(rowIndex);
    if (sourceRowIndex == null || recordId == null) {
      return null;
    }
    return FdcGridDetailRowContext(
      dataSet: widget.dataSet,
      rowIndex: rowIndex,
      sourceRowIndex: sourceRowIndex,
      recordId: recordId,
      expanded: expanded,
    );
  }

  FdcGridDetailRowContext? _detailContextForRecordId(
    int recordId, {
    required bool expanded,
  }) {
    for (var rowIndex = 0; rowIndex < _rows.length; rowIndex++) {
      if (_recordIdForGridRow(rowIndex) == recordId) {
        return _detailContextForRow(rowIndex, expanded: expanded);
      }
    }
    return null;
  }

  void _dispatchDetailExpanded(int recordId) {
    final feature = widget.detailRow;
    final context = _detailContextForRecordId(recordId, expanded: true);
    if (feature != null && context != null) {
      feature.onExpanded?.call(context);
    }
  }

  void _dispatchDetailCollapsed(int recordId) {
    final feature = widget.detailRow;
    final context = _detailContextForRecordId(recordId, expanded: false);
    if (feature != null && context != null) {
      feature.onCollapsed?.call(context);
    }
  }

  bool _canExpandDetailRow(int rowIndex) {
    final feature = widget.detailRow;
    if (feature == null) {
      return false;
    }
    final recordId = _recordIdForGridRow(rowIndex);
    final context = _detailContextForRow(
      rowIndex,
      expanded: recordId != null && _expandedDetailRecordIds.contains(recordId),
    );
    return context != null && feature.canExpand(context);
  }

  bool _isDetailRowExpanded(int rowIndex) {
    final recordId = _recordIdForGridRow(rowIndex);
    return recordId != null && _expandedDetailRecordIds.contains(recordId);
  }

  bool _isDetailRowVisuallyExpanded(int rowIndex) {
    return _isDetailRowExpanded(rowIndex);
  }

  Set<int> _expandedDetailRowIndices() {
    if (!_hasDetailRowFeature || _expandedDetailRecordIds.isEmpty) {
      _expandedDetailRowIndicesCache = const <int>[];
      _expandedDetailRowIndicesDirty = false;
      return const <int>{};
    }
    if (_expandedDetailRowIndicesDirty) {
      final result = <int>[];
      for (var rowIndex = 0; rowIndex < _rows.length; rowIndex++) {
        final recordId = _recordIdForGridRow(rowIndex);
        if (recordId != null && _expandedDetailRecordIds.contains(recordId)) {
          result.add(rowIndex);
        }
      }
      _expandedDetailRowIndicesCache = List<int>.unmodifiable(result);
      _expandedDetailRowIndicesDirty = false;
    }
    return _expandedDetailRowIndicesCache.toSet();
  }

  List<int> _expandedDetailIndices() {
    _expandedDetailRowIndices();
    return _expandedDetailRowIndicesCache;
  }

  void _invalidateDetailRowIndices() {
    _expandedDetailRowIndicesDirty = true;
  }

  bool _collapseDetailRowsForCurrentRowChange(int rowIndex) {
    final feature = widget.detailRow;
    if (feature == null ||
        !feature.collapseOnCurrentRowChange ||
        _expandedDetailRecordIds.isEmpty) {
      return false;
    }

    final targetRecordId = _recordIdForGridRow(rowIndex);
    final collapsedRecordIds = _expandedDetailRecordIds
        .where((recordId) => recordId != targetRecordId)
        .toList(growable: false);
    if (collapsedRecordIds.isEmpty) {
      return false;
    }

    _detailRevealGeneration++;
    _applyGridState(() {
      _expandedDetailRecordIds.removeAll(collapsedRecordIds);
      _visibleDetailRecordIds.removeAll(collapsedRecordIds);
      _invalidateDetailRowIndices();
    });
    for (final recordId in collapsedRecordIds) {
      _dispatchDetailCollapsed(recordId);
    }
    return true;
  }

  bool _collapseAllDetailRowsImmediately() {
    if (_expandedDetailRecordIds.isEmpty) {
      return false;
    }

    final collapsedRecordIds = _expandedDetailRecordIds.toList(growable: false);
    _applyGridState(() {
      _expandedDetailRecordIds.clear();
      _visibleDetailRecordIds.clear();
      _invalidateDetailRowIndices();
    });
    for (final recordId in collapsedRecordIds) {
      _dispatchDetailCollapsed(recordId);
    }
    return true;
  }

  void _toggleDetailRow(int rowIndex) {
    final feature = widget.detailRow;
    final recordId = _recordIdForGridRow(rowIndex);
    if (feature == null || recordId == null || !_canExpandDetailRow(rowIndex)) {
      return;
    }

    final activated = _activateVisibleRecordScrollRow(
      rowIndex,
      focusReason: FdcGridFocusChangeReason.mouse,
    );
    if (!activated) {
      return;
    }

    if (_expandedDetailRecordIds.contains(recordId)) {
      _detailRevealGeneration++;
      _applyGridState(() {
        _expandedDetailRecordIds.remove(recordId);
        _visibleDetailRecordIds.remove(recordId);
        _invalidateDetailRowIndices();
      });
      _dispatchDetailCollapsed(recordId);
      return;
    }

    final previousRecordIds = feature.singleExpanded
        ? _expandedDetailRecordIds
              .where((expandedId) => expandedId != recordId)
              .toList(growable: false)
        : const <int>[];
    final hasCommittedContentExtent =
        _detailRowContentSized &&
        _detailRowMeasuredHeights.containsKey(recordId);

    _applyGridState(() {
      _resetRangeSelectionState(rebuild: false);
      if (previousRecordIds.isNotEmpty) {
        _expandedDetailRecordIds.removeAll(previousRecordIds);
        _visibleDetailRecordIds.removeAll(previousRecordIds);
      }
      if (hasCommittedContentExtent) {
        // The measured extent cache belongs to layout only. Re-expanding the
        // same record must still reactivate the panel subtree immediately;
        // otherwise the size observer can correctly deduplicate the unchanged
        // size while the panel remains permanently transparent.
        _visibleDetailRecordIds.add(recordId);
      } else {
        _visibleDetailRecordIds.remove(recordId);
      }
      _expandedDetailRecordIds.add(recordId);
      _invalidateDetailRowIndices();
    });
    for (final previousRecordId in previousRecordIds) {
      _dispatchDetailCollapsed(previousRecordId);
    }
    _dispatchDetailExpanded(recordId);
    if (_detailRowContentSized) {
      if (hasCommittedContentExtent) {
        _revealExpandedDetailRowAfterLayout(recordId);
      }
      // A first-time content-sized panel remains hidden until its measured
      // extent has been committed to every detached vertical region.
    } else {
      // Expansion itself commits the additional row extent immediately. Start
      // reveal from that state, independently of the one-frame delayed panel
      // paint used to synchronize detached row regions.
      _revealExpandedDetailRowAfterLayout(recordId);
      _showFixedDetailRowAfterLayout(recordId);
    }
  }

  void _revealExpandedDetailRowAfterLayout(int recordId) {
    final revealGeneration = ++_detailRevealGeneration;

    void reveal({required int remainingFrames}) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            revealGeneration != _detailRevealGeneration ||
            !_expandedDetailRecordIds.contains(recordId)) {
          return;
        }

        var rowIndex = -1;
        for (var index = 0; index < _rows.length; index++) {
          if (_recordIdForGridRow(index) == recordId) {
            rowIndex = index;
            break;
          }
        }
        if (rowIndex < 0) {
          return;
        }

        final viewportHeight = _visibleRowsViewportHeight;
        if (!_scrollCoordinator.hasVerticalClients || viewportHeight <= 0) {
          if (remainingFrames > 0) {
            reveal(remainingFrames: remainingFrames - 1);
          }
          return;
        }

        final detailTop =
            _gridRowTop(rowIndex) + widget.options.resolvedRowHeight;
        final detailHeight = _detailHeightForRow(rowIndex);
        final detailBottom = detailTop + detailHeight;
        final currentOffset = _scrollCoordinator.currentVerticalOffset;
        final currentBottom = currentOffset + viewportHeight;
        final computedMaxOffset = math.max(
          0.0,
          _gridRowsContentHeight - viewportHeight,
        );

        var targetOffset = currentOffset;
        if (detailBottom > currentBottom) {
          targetOffset = detailHeight >= viewportHeight
              ? detailTop
              : detailBottom - viewportHeight;
        } else if (detailTop < currentOffset) {
          targetOffset = detailTop;
        }
        targetOffset = targetOffset.clamp(0.0, computedMaxOffset).toDouble();

        // The variable ListView extent is committed during layout. If this
        // callback runs before ScrollPosition has accepted the new extent,
        // defer the reveal instead of letting jumpTo clamp to the old end.
        if (remainingFrames > 0 &&
            _scrollCoordinator.verticalMaxScrollExtent + 0.5 < targetOffset) {
          reveal(remainingFrames: remainingFrames - 1);
          return;
        }

        if ((targetOffset - currentOffset).abs() < 0.5) {
          return;
        }

        var jumpAccepted = false;
        _scroll.runRowSnap(() {
          jumpAccepted = _scrollCoordinator.jumpVerticalTo(targetOffset);
        });

        // A pointer-driven expander tap can keep vertical jumps suppressed for
        // the current frame. Do not lose the reveal request in that case: the
        // expanded extent is already valid, so retry after the pointer lock has
        // been released. This also covers a controller that temporarily has no
        // usable position while detached regions rebuild.
        if (!jumpAccepted && remainingFrames > 0) {
          reveal(remainingFrames: remainingFrames - 1);
        }
      });
    }

    reveal(remainingFrames: 3);
  }

  void _handleDetailRowSizeChanged(int rowIndex, Size size) {
    if (!_detailRowContentSized || !mounted) {
      return;
    }
    final feature = widget.detailRow;
    final recordId = _recordIdForGridRow(rowIndex);
    if (feature == null ||
        recordId == null ||
        !_expandedDetailRecordIds.contains(recordId)) {
      return;
    }
    var height = size.height;
    if (height < feature.minHeight) {
      height = feature.minHeight;
    }
    final maxHeight = feature.maxHeight;
    if (maxHeight != null && height > maxHeight) {
      height = maxHeight;
    }
    if (!height.isFinite || height < 0) {
      return;
    }
    final previous = _detailRowMeasuredHeights[recordId];
    if (previous != null && (previous - height).abs() < 0.5) {
      if (!_visibleDetailRecordIds.contains(recordId)) {
        _applyGridState(() {
          _visibleDetailRecordIds.add(recordId);
        });
        _revealExpandedDetailRowAfterLayout(recordId);
      }
      return;
    }
    _applyGridState(() {
      _detailRowMeasuredHeights[recordId] = height;
      _visibleDetailRecordIds.add(recordId);
    });
    _revealExpandedDetailRowAfterLayout(recordId);
  }

  Widget _buildDetailRow(BuildContext context, int rowIndex) {
    final feature = widget.detailRow;
    final detailContext = _detailContextForRow(rowIndex, expanded: true);
    if (feature == null || detailContext == null) {
      return const SizedBox.shrink();
    }

    final background = feature.backgroundColor ?? Colors.transparent;
    return KeyedSubtree(
      key: ValueKey<String>('fdc-grid-detail-${detailContext.recordId}'),
      child: ColoredBox(
        color: background,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: feature.height == null ? feature.minHeight : 0,
            maxHeight: feature.height == null
                ? (feature.maxHeight ?? double.infinity)
                : double.infinity,
          ),
          child: Padding(
            padding: feature.padding,
            child: feature.build(context, detailContext),
          ),
        ),
      ),
    );
  }

  double _gridRowTop(int rowIndex) {
    final rowHeight = widget.options.resolvedRowHeight;
    if (!_hasDetailRowFeature || _expandedDetailRecordIds.isEmpty) {
      return rowIndex * rowHeight;
    }
    var top = rowIndex * rowHeight;
    for (final expandedIndex in _expandedDetailIndices()) {
      if (expandedIndex >= rowIndex) {
        break;
      }
      top += _detailHeightForRow(expandedIndex);
    }
    return top;
  }

  double _gridRowExtent(int rowIndex) {
    return widget.options.resolvedRowHeight +
        (_isDetailRowExpanded(rowIndex) ? _detailHeightForRow(rowIndex) : 0.0);
  }

  double get _gridRowsContentHeight {
    var detailHeight = 0.0;
    for (final rowIndex in _expandedDetailIndices()) {
      detailHeight += _detailHeightForRow(rowIndex);
    }
    return _rows.length * widget.options.resolvedRowHeight + detailHeight;
  }

  int _gridRowIndexAtOffset(double offset) {
    if (_rows.isEmpty) {
      return 0;
    }
    var low = 0;
    var high = _rows.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final top = _gridRowTop(mid);
      final bottom = top + _gridRowExtent(mid);
      if (offset < top) {
        high = mid - 1;
      } else if (offset >= bottom) {
        low = mid + 1;
      } else {
        return mid;
      }
    }
    return low.clamp(0, _rows.length - 1);
  }

  double _gridRowTopAtOrAfter(double offset) {
    if (_rows.isEmpty || offset <= 0) {
      return 0.0;
    }

    var low = 0;
    var high = _rows.length - 1;
    var result = _gridRowTop(high);
    while (low <= high) {
      final mid = (low + high) >> 1;
      final top = _gridRowTop(mid);
      if (top >= offset) {
        result = top;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    return result;
  }

  double _nearestGridRowTop(double offset) {
    if (_rows.isEmpty) {
      return 0.0;
    }
    final rowIndex = _gridRowIndexAtOffset(offset);
    final top = _gridRowTop(rowIndex);
    final nextTop = rowIndex + 1 < _rows.length
        ? _gridRowTop(rowIndex + 1)
        : top;
    if (nextTop > top && (offset - top).abs() > (nextTop - offset).abs()) {
      return nextTop;
    }
    return top;
  }

  void _clearDetailRowState() {
    _detailRevealGeneration++;
    _expandedDetailRecordIds.clear();
    _visibleDetailRecordIds.clear();
    _detailRowMeasuredHeights.clear();
    _expandedDetailRowIndicesCache = const <int>[];
    _expandedDetailRowIndicesDirty = false;
  }
}
