// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateHeader on _FdcGridState {
  FdcGridHeaderModel _buildHeaderModel(
    BuildContext context,
    FdcGridColumnBandLayout columnLayout,
  ) {
    final horizontalGridLineColor = _styles.horizontalGridLineColor(_gridStyle);
    final verticalGridLineColor = _styles.verticalGridLineColor(_gridStyle);
    final showVerticalGridLines = _styles.showVerticalGridLines(_gridStyle);
    final bandLayouts = _columnBandLayouts();
    final isPinnedLeftBand = _isSameColumnBandLayout(
      columnLayout,
      bandLayouts.pinnedLeft,
    );
    final isPinnedRightBand = _isSameColumnBandLayout(
      columnLayout,
      bandLayouts.pinnedRight,
    );
    final fullHeightTrailingSeparator =
        _isSameColumnBandLayout(columnLayout, bandLayouts.scrollable) ||
        isPinnedRightBand;
    final leftPinnedGroupLabel = _textDirection == TextDirection.ltr
        ? widget.pinning.startPinnedGroupLabel
        : widget.pinning.endPinnedGroupLabel;
    final rightPinnedGroupLabel = _textDirection == TextDirection.ltr
        ? widget.pinning.endPinnedGroupLabel
        : widget.pinning.startPinnedGroupLabel;
    final ungroupedLabel = isPinnedLeftBand
        ? leftPinnedGroupLabel
        : isPinnedRightBand
        ? rightPinnedGroupLabel
        : widget.pinning.unpinnedGroupLabel;
    return FdcGridHeaderModel(
      geometries: columnLayout.geometries,
      columns: columnLayout.columns,
      columnWidths: columnLayout.columnWidths,
      columnOffsets: columnLayout.columnOffsets,
      contentWidth: columnLayout.width,
      runtimeColumnIds: columnLayout.runtimeColumnIds,
      columnIndexes: columnLayout.columnIndexes,
      resizeTargetLocalColumnIndexes:
          columnLayout.resizeTargetLocalColumnIndexes,
      resizeTargetColumns: columnLayout.resizeTargetColumns,
      resizeTargetRuntimeColumnIds: columnLayout.resizeTargetRuntimeColumnIds,
      resizeTargetColumnIndexes: columnLayout.resizeTargetColumnIndexes,
      resizeDeltaFactors: columnLayout.resizeDeltaFactors,
      columnGroupCells: _columnGroupCellsFor(
        columnLayout,
        ungroupedLabel: ungroupedLabel,
      ),
      groupHeaderHeight: _columnGroupHeaderHeight(),
      groupHeaderBackgroundColor: _columnGroupHeaderBackgroundColor(),
      groupHeaderTextStyle: _columnGroupHeaderTextStyle(context),
      groupHeaderAlignment: _columnGroupHeaderAlignment(),
      groupHeaderPadding: _columnGroupHeaderPadding(),
      groupHeaderBottomSeparatorColor: _columnGroupHeaderBottomSeparatorColor(),
      groupHeaderVerticalSeparatorColor: _groupHeaderVerticalSeparatorColor(),
      groupHeaderSeparatorTopInset: _columnGroupHeaderSeparatorTopInset(),
      groupHeaderSeparatorBottomInset: _columnGroupHeaderSeparatorBottomInset(),
      options: widget.options,
      rowIndicator: widget.rowIndicator,
      filterOptions: _headerFilterOptions,
      mainMenuInToolbar: _showsToolbarMainMenu(),
      height: _effectiveHeaderHeight,
      filterRowHeight: _headerFilterRowHeight,
      showsFilterRow: _showsHeaderFilterRow,
      headerBackgroundColor: _styles.headerBackgroundColor(_headerStyle),
      headerSeparatorColor: _styles.headerSeparatorColor(
        _gridStyle,
        _headerStyle,
      ),
      horizontalGridLineColor: horizontalGridLineColor,
      verticalGridLineColor: verticalGridLineColor,
      showVerticalGridLines: showVerticalGridLines,
      headerTextStyle: _headerTextStyle(context),
      headerFilterStyle: _headerFilterStyle(context),
      controlsStyle: _controlsStyle(context),
      headerSeparatorTopInset: _headerSeparatorTopInset(),
      headerSeparatorBottomInset: _headerSeparatorBottomInset(),
      fullHeightTrailingSeparator: fullHeightTrailingSeparator,
      headerFilterResetGeneration: _headerFilterResetGeneration,
      headerFilterRangeAutoOpenGeneration: _headerFilterRangeAutoOpenGeneration,
      rangeAutoOpenColumnId: _rangeAutoOpenColumnId,
      headerFilterValues: Map<FdcColumnIdentity, Object?>.from(
        _headerFilterValues,
      ),
      draggingColumnIndex: _draggingColumnIndex,
      invalidColumnDropTargetHovering: _invalidColumnDropTargetHovering,
      invalidColumnDropTargetHoverListenable: _invalidDropTargetHoverNotifier,
      resizingRuntimeColumnId: _resizingRuntimeColumnId,
      resizingDeltaFactor: _ui.columnResize.globalResizeDeltaFactor,
      visibleColumnCount: columnLayout.length,
      suppressTrailingEdgeAffordances: columnLayout.stretchesLastColumn,
      suppressTrailingSeparator:
          _isSameColumnBandLayout(columnLayout, bandLayouts.scrollable) &&
          bandLayouts.pinnedRight.isNotEmpty,
    );
  }

  double _columnGroupHeaderHeight() {
    if (widget.columnGroups.isEmpty) {
      return 0.0;
    }
    return math.max(0.0, _headerStyle.groupHeight ?? 0.0);
  }

  Color _columnGroupHeaderBackgroundColor() {
    return _styles.columnGroupHeaderBackgroundColor(_headerStyle);
  }

  TextStyle? _columnGroupHeaderTextStyle(BuildContext context) {
    return _headerStyle.groupTextStyle ??
        _headerTextStyle(context)?.copyWith(fontWeight: FontWeight.w600);
  }

  Alignment _columnGroupHeaderAlignment() {
    return _headerStyle.groupAlignment ?? Alignment.center;
  }

  EdgeInsetsGeometry _columnGroupHeaderPadding() {
    return _headerStyle.groupPadding ??
        const EdgeInsets.symmetric(horizontal: 8);
  }

  Color _columnGroupHeaderBottomSeparatorColor() {
    return _styles.columnGroupHeaderBottomSeparatorColor(
      _gridStyle,
      _headerStyle,
    );
  }

  Color _groupHeaderVerticalSeparatorColor() {
    return _styles.groupHeaderVerticalSeparatorColor(_gridStyle, _headerStyle);
  }

  double _columnGroupHeaderSeparatorTopInset() {
    return math.max(
      0.0,
      _headerStyle.groupVerticalSeparatorInset ??
          _headerStyle.verticalSeparatorInset ??
          FdcGridHeaderMetrics.verticalSeparatorInset,
    );
  }

  double _columnGroupHeaderSeparatorBottomInset() {
    return math.max(
      0.0,
      _headerStyle.groupVerticalSeparatorInset ??
          _headerStyle.verticalSeparatorInset ??
          FdcGridHeaderMetrics.verticalSeparatorInset,
    );
  }

  List<FdcGridColumnGroupCell> _columnGroupCellsFor(
    FdcGridColumnBandLayout columnLayout, {
    String ungroupedLabel = '',
  }) {
    if (widget.columnGroups.isEmpty || columnLayout.isEmpty) {
      return const <FdcGridColumnGroupCell>[];
    }

    final visibleLocalIndexes = <int>{
      for (final geometry in columnLayout.geometries) geometry.localColumnIndex,
    };
    if (visibleLocalIndexes.isEmpty) {
      return const <FdcGridColumnGroupCell>[];
    }

    final groupsById = <String, FdcGridColumnGroup>{
      for (final group in widget.columnGroups) group.id: group,
    };

    final cells = <FdcGridColumnGroupCell>[];
    var start = 0;
    while (start < columnLayout.length) {
      final column = columnLayout.columns[start];
      final group = _columnGroupOf(column, groupsById: groupsById);
      var end = start + 1;
      while (end < columnLayout.length) {
        final nextColumn = columnLayout.columns[end];
        if (_columnGroupOf(nextColumn, groupsById: groupsById) != group) {
          break;
        }
        end++;
      }

      final visibleSegmentIndexes = <int>[];
      for (var index = start; index < end; index++) {
        if (visibleLocalIndexes.contains(index)) {
          visibleSegmentIndexes.add(index);
        } else if (visibleSegmentIndexes.isNotEmpty) {
          _addColumnGroupCell(
            cells,
            columnLayout,
            group,
            visibleSegmentIndexes,
            resizeStartLocalColumnIndex: start,
            resizeColumnSpan: end - start,
            ungroupedLabel: ungroupedLabel,
          );
          visibleSegmentIndexes.clear();
        }
      }
      if (visibleSegmentIndexes.isNotEmpty) {
        _addColumnGroupCell(
          cells,
          columnLayout,
          group,
          visibleSegmentIndexes,
          resizeStartLocalColumnIndex: start,
          resizeColumnSpan: end - start,
          ungroupedLabel: ungroupedLabel,
        );
      }

      start = end;
    }

    return List<FdcGridColumnGroupCell>.unmodifiable(cells);
  }

  void _addColumnGroupCell(
    List<FdcGridColumnGroupCell> cells,
    FdcGridColumnBandLayout columnLayout,
    FdcGridColumnGroup? group,
    List<int> visibleIndexes, {
    required int resizeStartLocalColumnIndex,
    required int resizeColumnSpan,
    required String ungroupedLabel,
  }) {
    if (visibleIndexes.isEmpty) {
      return;
    }

    final start = visibleIndexes.first;
    final end = visibleIndexes.last + 1;
    final left = columnLayout.columnOffsetAt(
      start,
      fallbackWidth: widget.options.resolvedDefaultColumnWidth,
    );
    var width = 0.0;
    for (var index = start; index < end; index++) {
      width += columnLayout.columnWidthAt(
        index,
        fallbackWidth: widget.options.resolvedDefaultColumnWidth,
      );
    }

    final fullGroupLeft = columnLayout.columnOffsetAt(
      resizeStartLocalColumnIndex,
      fallbackWidth: widget.options.resolvedDefaultColumnWidth,
    );
    var fullGroupWidth = 0.0;
    final fullGroupEnd = math.min(
      columnLayout.length,
      resizeStartLocalColumnIndex + resizeColumnSpan,
    );
    for (
      var index = resizeStartLocalColumnIndex;
      index < fullGroupEnd;
      index++
    ) {
      fullGroupWidth += columnLayout.columnWidthAt(
        index,
        fallbackWidth: widget.options.resolvedDefaultColumnWidth,
      );
    }

    cells.add(
      FdcGridColumnGroupCell(
        label: group?.label ?? ungroupedLabel,
        style: group?.style ?? const FdcGridColumnGroupStyle(),
        startLocalColumnIndex: start,
        columnSpan: end - start,
        left: left,
        width: width,
        labelLeftOffset: fullGroupLeft - left,
        labelWidth: fullGroupWidth,
        resizeStartLocalColumnIndex: resizeStartLocalColumnIndex,
        resizeColumnSpan: resizeColumnSpan,
      ),
    );
  }

  bool _isSameColumnBandLayout(
    FdcGridColumnBandLayout first,
    FdcGridColumnBandLayout second,
  ) {
    if (first.length != second.length || first.isEmpty) {
      return false;
    }
    return first.columnSignature == second.columnSignature;
  }
}
