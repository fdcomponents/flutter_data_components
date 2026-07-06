// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateColumnResizeRuntime on _FdcGridState {
  void _startColumnResize(
    int columnIndex,
    FdcColumnIdentity runtimeColumnId,
    double globalX,
    double deltaFactor,
  ) {
    _blurGrid();
    _scrollCoordinator.beginColumnResizeLock();
    final resolvedColumnIndex = _columnIndexForRuntimeColumnId(
      runtimeColumnId,
      fallbackColumnIndex: columnIndex,
    );
    _setGridState(() {
      _resizingRuntimeColumnId = runtimeColumnId;
      _resizingColumnStartWidth = _columnWidthForRuntimeColumnId(
        runtimeColumnId,
        fallbackColumnIndex: resolvedColumnIndex,
      );
      _resizingColumnDragStartGlobalX = globalX;
      _ui.columnResize.lastAppliedDelta = 0.0;
    });
    _ui.columnResize.armGlobalResizeSession(
      deltaFactor: deltaFactor,
      onMove: (globalX) {
        final deltaFactor = _ui.columnResize.globalResizeDeltaFactor;
        if (deltaFactor == null) {
          return;
        }
        _updateColumnResize(columnIndex, runtimeColumnId, globalX, deltaFactor);
      },
      onEnd: () => _clearResizingColumn(runtimeColumnId),
    );
  }

  void _updateColumnResize(
    int columnIndex,
    FdcColumnIdentity runtimeColumnId,
    double globalX,
    double deltaFactor,
  ) {
    if (_resizingRuntimeColumnId != runtimeColumnId) {
      return;
    }
    _ui.columnResize.globalResizeDeltaFactor = deltaFactor;
    final resolvedColumnIndex = _columnIndexForRuntimeColumnId(
      runtimeColumnId,
      fallbackColumnIndex: columnIndex,
    );
    final previousGlobalX = _resizingColumnDragStartGlobalX;
    if (previousGlobalX == null ||
        resolvedColumnIndex < 0 ||
        resolvedColumnIndex >= _visibleColumns.length) {
      return;
    }
    final pointerDelta = (globalX - previousGlobalX) * deltaFactor;
    // Advance the pointer baseline even when the width is saturated. Any
    // movement beyond min/max is intentionally discarded so reversing the
    // pointer direction resumes resizing immediately without a dead zone.
    _resizingColumnDragStartGlobalX = globalX;
    final requestedDelta =
        (_ui.columnResize.lastAppliedDelta ?? 0.0) + pointerDelta;
    final column = _visibleColumns[resolvedColumnIndex];
    if (column is FdcActionColumn || !column.allowResize) {
      return;
    }
    final minDelta = _minimumColumnWidth(column) - _resizingColumnStartWidth;
    final maxDelta = _maximumColumnWidth(column) - _resizingColumnStartWidth;
    final totalDelta = requestedDelta.clamp(minDelta, maxDelta).toDouble();
    final lastAppliedDelta = _ui.columnResize.lastAppliedDelta;
    final nextWidth = _resizingColumnStartWidth + totalDelta;
    if (lastAppliedDelta != null &&
        (lastAppliedDelta - totalDelta).abs() < 0.01) {
      return;
    }
    _ui.columnResize.lastAppliedDelta = totalDelta;
    _resizeColumnByRuntimeId(runtimeColumnId, resolvedColumnIndex, nextWidth);
  }

  void _endColumnResize(int columnIndex, FdcColumnIdentity runtimeColumnId) {
    _clearResizingColumn(runtimeColumnId);
    _notifyGridLayoutChanged();
  }

  void _startColumnGroupResize(
    List<int> columnIndexes,
    List<FdcColumnIdentity> runtimeColumnIds,
    FdcColumnIdentity resizeRuntimeColumnId,
    double globalX,
    double deltaFactor,
  ) {
    _blurGrid();
    _scrollCoordinator.beginColumnResizeLock();
    _setGridState(() {
      _resizingRuntimeColumnId = resizeRuntimeColumnId;
      _resizingGroupRuntimeColumnIds = List<FdcColumnIdentity>.unmodifiable(
        runtimeColumnIds,
      );
      _resizingGroupStartWidths = List<double>.unmodifiable(<double>[
        for (var index = 0; index < runtimeColumnIds.length; index++)
          _columnWidthForRuntimeColumnId(
            runtimeColumnIds[index],
            fallbackColumnIndex: index < columnIndexes.length
                ? columnIndexes[index]
                : index,
          ),
      ]);
      _resizingColumnStartWidth = _resizingGroupStartWidths.fold<double>(
        0.0,
        (sum, width) => sum + width,
      );
      _resizingColumnDragStartGlobalX = globalX;
      _ui.columnResize.lastAppliedDelta = 0.0;
    });
    _ui.columnResize.armGlobalResizeSession(
      deltaFactor: deltaFactor,
      onMove: (globalX) {
        final deltaFactor = _ui.columnResize.globalResizeDeltaFactor;
        if (deltaFactor == null) {
          return;
        }
        _updateColumnGroupResize(
          columnIndexes,
          runtimeColumnIds,
          resizeRuntimeColumnId,
          globalX,
          deltaFactor,
        );
      },
      onEnd: () {
        _clearResizingColumn(resizeRuntimeColumnId);
        _notifyGridLayoutChanged();
      },
    );
  }

  void _updateColumnGroupResize(
    List<int> columnIndexes,
    List<FdcColumnIdentity> runtimeColumnIds,
    FdcColumnIdentity resizeRuntimeColumnId,
    double globalX,
    double deltaFactor,
  ) {
    if (_resizingRuntimeColumnId != resizeRuntimeColumnId) {
      return;
    }
    _ui.columnResize.globalResizeDeltaFactor = deltaFactor;
    final previousGlobalX = _resizingColumnDragStartGlobalX;
    if (previousGlobalX == null) {
      return;
    }
    final pointerDelta = (globalX - previousGlobalX) * deltaFactor;
    // Consume pointer motion incrementally. Overshoot after every resizable
    // group member reaches min/max must not accumulate into a reverse-drag
    // dead zone.
    _resizingColumnDragStartGlobalX = globalX;
    final requestedDelta =
        (_ui.columnResize.lastAppliedDelta ?? 0.0) + pointerDelta;
    var minDelta = 0.0;
    var maxDelta = 0.0;
    for (var index = 0; index < runtimeColumnIds.length; index++) {
      final runtimeColumnId = runtimeColumnIds[index];
      final fallbackColumnIndex = index < columnIndexes.length
          ? columnIndexes[index]
          : index;
      final columnIndex = _columnIndexForRuntimeColumnId(
        runtimeColumnId,
        fallbackColumnIndex: fallbackColumnIndex,
      );
      if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
        continue;
      }
      final column = _visibleColumns[columnIndex];
      if (column is FdcActionColumn || !column.allowResize) {
        continue;
      }
      final startWidth =
          index < _resizingGroupStartWidths.length &&
              index < _resizingGroupRuntimeColumnIds.length &&
              _resizingGroupRuntimeColumnIds[index] == runtimeColumnId
          ? _resizingGroupStartWidths[index]
          : _columnWidthForRuntimeColumnId(
              runtimeColumnId,
              fallbackColumnIndex: columnIndex,
            );
      minDelta += _minimumColumnWidth(column) - startWidth;
      maxDelta += _maximumColumnWidth(column) - startWidth;
    }
    final totalDelta = requestedDelta.clamp(minDelta, maxDelta).toDouble();
    final lastAppliedDelta = _ui.columnResize.lastAppliedDelta;
    if (lastAppliedDelta != null &&
        (lastAppliedDelta - totalDelta).abs() < 0.01) {
      return;
    }
    _ui.columnResize.lastAppliedDelta = totalDelta;
    _resizeGroupProportionally(runtimeColumnIds, columnIndexes, totalDelta);
  }

  void _endColumnGroupResize(FdcColumnIdentity resizeRuntimeColumnId) {
    _clearResizingColumn(resizeRuntimeColumnId);
    _notifyGridLayoutChanged();
  }

  void _resizeColumnByRuntimeId(
    FdcColumnIdentity runtimeColumnId,
    int fallbackColumnIndex,
    double width,
  ) {
    final columnIndex = _columnIndexForRuntimeColumnId(
      runtimeColumnId,
      fallbackColumnIndex: fallbackColumnIndex,
    );
    if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
      return;
    }

    final column = _visibleColumns[columnIndex];
    if (column is FdcActionColumn || !column.allowResize) {
      return;
    }
    final liveResize = _resizingRuntimeColumnId == runtimeColumnId;

    var widthChanged = false;
    void applyWidth() {
      final nextWidth = _constrainColumnWidth(column, width);
      final currentWidth = _columnWidthForRuntimeColumnId(
        runtimeColumnId,
        fallbackColumnIndex: columnIndex,
      );
      if ((currentWidth - nextWidth).abs() < 0.5) {
        return;
      }
      _suspendAutoSizeAtCurrentWidth(runtimeColumnId, column, nextWidth);
      widthChanged = true;
    }

    if (liveResize) {
      applyWidth();
      if (widthChanged) {
        _notifyLiveResizeLayoutChanged();
      }
    } else {
      _setGridState(applyWidth);
    }

    if (widthChanged) {
      _scrollCoordinator.notifyHorizontalResizeVisualChange();
      _scrollCoordinator.restoreResizeLockedOffsetAfterLayout();
    }
  }

  void _resizeGroupProportionally(
    List<FdcColumnIdentity> runtimeColumnIds,
    List<int> fallbackColumnIndexes,
    double totalDelta,
  ) {
    if (runtimeColumnIds.length < 2 || totalDelta.abs() < 0.01) {
      return;
    }

    final resolved = <FdcGridResizeColumn>[];
    for (var index = 0; index < runtimeColumnIds.length; index++) {
      final runtimeColumnId = runtimeColumnIds[index];
      final fallbackColumnIndex = index < fallbackColumnIndexes.length
          ? fallbackColumnIndexes[index]
          : index;
      final columnIndex = _columnIndexForRuntimeColumnId(
        runtimeColumnId,
        fallbackColumnIndex: fallbackColumnIndex,
      );
      if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
        continue;
      }
      final column = _visibleColumns[columnIndex];
      if (column is FdcActionColumn || !column.allowResize) {
        continue;
      }
      final startWidth =
          index < _resizingGroupStartWidths.length &&
              index < _resizingGroupRuntimeColumnIds.length &&
              _resizingGroupRuntimeColumnIds[index] == runtimeColumnId
          ? _resizingGroupStartWidths[index]
          : _columnWidthForRuntimeColumnId(
              runtimeColumnId,
              fallbackColumnIndex: columnIndex,
            );
      resolved.add(
        FdcGridResizeColumn(
          runtimeColumnId: runtimeColumnId,
          column: column,
          columnIndex: columnIndex,
          fallbackColumnIndex: fallbackColumnIndex,
          startWidth: _constrainColumnWidth(column, startWidth),
          minWidth: _minimumColumnWidth(column),
          maxWidth: _maximumColumnWidth(column),
        ),
      );
    }

    if (resolved.isEmpty) {
      return;
    }

    final nextWidths = _distributedGroupResizeWidths(resolved, totalDelta);

    final liveResize = _resizingRuntimeColumnId != null;

    var widthChanged = false;
    void applyWidths() {
      for (var index = 0; index < resolved.length; index++) {
        final resizeColumn = resolved[index];
        final nextWidth = _constrainColumnWidth(
          resizeColumn.column,
          nextWidths[index],
        );
        final currentWidth = _columnWidthForRuntimeColumnId(
          resizeColumn.runtimeColumnId,
          fallbackColumnIndex: resizeColumn.columnIndex,
        );
        if ((currentWidth - nextWidth).abs() < 0.5) {
          continue;
        }
        _suspendAutoSizeAtCurrentWidth(
          resizeColumn.runtimeColumnId,
          resizeColumn.column,
          nextWidth,
        );
        widthChanged = true;
      }
    }

    if (liveResize) {
      applyWidths();
      if (widthChanged) {
        _notifyLiveResizeLayoutChanged();
      }
    } else {
      _setGridState(applyWidths);
    }

    if (widthChanged) {
      _scrollCoordinator.notifyHorizontalResizeVisualChange();
      _scrollCoordinator.restoreResizeLockedOffsetAfterLayout();
    }
  }

  List<double> _distributedGroupResizeWidths(
    List<FdcGridResizeColumn> columns,
    double totalDelta,
  ) {
    final nextWidths = <double>[
      for (final column in columns) column.startWidth,
    ];
    final grow = totalDelta > 0;
    var remaining = totalDelta.abs();
    final activeIndexes = <int>{
      for (var index = 0; index < columns.length; index++)
        if (_resizeCapacity(columns[index], nextWidths[index], grow) > 0.01)
          index,
    };

    while (remaining > 0.01 && activeIndexes.isNotEmpty) {
      final totalWeight = activeIndexes.fold<double>(
        0.0,
        (sum, index) => sum + math.max(columns[index].startWidth, 1.0),
      );
      if (totalWeight <= 0) {
        break;
      }

      var appliedThisPass = 0.0;
      final saturatedIndexes = <int>[];
      for (final index in activeIndexes) {
        final column = columns[index];
        final capacity = _resizeCapacity(column, nextWidths[index], grow);
        if (capacity <= 0.01) {
          saturatedIndexes.add(index);
          continue;
        }
        final share =
            remaining * math.max(column.startWidth, 1.0) / totalWeight;
        final applied = math.min(share, capacity);
        nextWidths[index] += grow ? applied : -applied;
        appliedThisPass += applied;
        if (capacity - applied <= 0.01) {
          saturatedIndexes.add(index);
        }
      }

      for (final index in saturatedIndexes) {
        activeIndexes.remove(index);
      }
      if (appliedThisPass <= 0.01) {
        break;
      }
      remaining -= appliedThisPass;
    }

    for (var index = 0; index < columns.length; index++) {
      nextWidths[index] = nextWidths[index]
          .clamp(columns[index].minWidth, columns[index].maxWidth)
          .toDouble();
    }
    return nextWidths;
  }

  double _resizeCapacity(
    FdcGridResizeColumn column,
    double currentWidth,
    bool grow,
  ) {
    if (grow) {
      return math.max(0.0, column.maxWidth - currentWidth);
    }
    return math.max(0.0, currentWidth - column.minWidth);
  }

  double _minimumColumnWidth(FdcGridColumn<dynamic> column) {
    return math.max(
      column.minWidth > 0 ? column.minWidth : 0.0,
      fdcGridMinimumResizableColumnWidth,
    );
  }

  double _maximumColumnWidth(FdcGridColumn<dynamic> column) {
    final lowerBound = _minimumColumnWidth(column);
    return column.maxWidth > 0
        ? math.max(column.maxWidth, lowerBound)
        : double.infinity;
  }

  void _suspendAutoSizeAtCurrentWidth(
    FdcColumnIdentity resizedRuntimeColumnId,
    FdcGridColumn<dynamic> resizedColumn,
    double resizedWidth,
  ) {
    _columnSizing.setColumnWidth(
      resizedRuntimeColumnId,
      resizedColumn,
      resizedWidth,
      columns: _visibleColumnsCache,
      runtimeColumnIds: _visibleRuntimeColumnIdsCache,
      defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
    );
  }

  double _constrainColumnWidth(FdcGridColumn<dynamic> column, double width) {
    final lowerBound = math.max(
      column.minWidth > 0 ? column.minWidth : 0.0,
      fdcGridMinimumResizableColumnWidth,
    );
    final upperBound = column.maxWidth > 0
        ? math.max(column.maxWidth, lowerBound)
        : double.infinity;
    return width.clamp(lowerBound, upperBound).toDouble();
  }

  void _clearResizingColumn(FdcColumnIdentity runtimeColumnId) {
    if (_resizingRuntimeColumnId != runtimeColumnId) {
      return;
    }
    _ui.columnResize.disarmGlobalResizeSession();
    _cancelPendingLiveResizeLayout();
    _setGridState(() {
      _resizingRuntimeColumnId = null;
      _resizingColumnStartWidth = 0;
      _resizingColumnDragStartGlobalX = null;
      _resizingGroupRuntimeColumnIds = const <FdcColumnIdentity>[];
      _resizingGroupStartWidths = const <double>[];
      _ui.columnResize.lastAppliedDelta = null;
    });
    _scrollCoordinator.endColumnResizeLock();
  }
}
