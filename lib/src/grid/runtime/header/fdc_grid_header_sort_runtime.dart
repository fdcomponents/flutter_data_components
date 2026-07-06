// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridHeaderSortRuntime on _FdcGridState {
  void _handleHeaderSortTap(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
      return;
    }

    final runtimeColumnId = _runtimeColumnIdAt(columnIndex);
    if (_isHeaderSortModifierPressed()) {
      _handleHeaderCtrlSortTap(columnIndex, runtimeColumnId);
      return;
    }

    final nextAscending = _sort.nextAscendingForRuntimeColumn(runtimeColumnId);
    _handleHeaderSortCommand(columnIndex, ascending: nextAscending);
  }

  void _handleHeaderCtrlSortTap(
    int columnIndex,
    FdcColumnIdentity? runtimeColumnId,
  ) {
    final currentAscending = _sort.ascendingForRuntimeColumn(runtimeColumnId);
    if (currentAscending == null) {
      _handleHeaderSortCommand(columnIndex, ascending: true, append: true);
      return;
    }

    if (currentAscending) {
      _handleHeaderSortCommand(columnIndex, ascending: false);
      return;
    }

    _handleHeaderClearSort(columnIndex);
  }

  bool _isHeaderSortModifierPressed() {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    return pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.controlRight);
  }

  void _handleHeaderSortAscending(int columnIndex) {
    _handleHeaderSortCommand(columnIndex, ascending: true);
  }

  void _handleHeaderSortDescending(int columnIndex) {
    _handleHeaderSortCommand(columnIndex, ascending: false);
  }

  void _handleHeaderAddSortAscending(int columnIndex) {
    _handleHeaderSortCommand(columnIndex, ascending: true, append: true);
  }

  void _handleHeaderAddSortDescending(int columnIndex) {
    _handleHeaderSortCommand(columnIndex, ascending: false, append: true);
  }

  void _handleHeaderSortCommand(
    int columnIndex, {
    required bool ascending,
    bool append = false,
  }) {
    if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
      return;
    }
    final column = _visibleColumns[columnIndex];
    final runtimeColumnId = _runtimeColumnIdAt(columnIndex);
    if (!widget.options.allowColumnSorting ||
        !column.allowSort ||
        runtimeColumnId == null) {
      return;
    }

    if (_activeCellEditorState?.finalizeEditing() == false) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    unawaited(
      _applySortToDataSet(
        column,
        runtimeColumnId: runtimeColumnId,
        ascending: ascending,
        append: append,
      ).then((applied) {
        if (!mounted || !applied) {
          return;
        }
      }),
    );
  }

  void _handleHeaderClearSort(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
      return;
    }
    final column = _visibleColumns[columnIndex];
    final runtimeColumnId = _runtimeColumnIdAt(columnIndex);
    if (!widget.options.allowColumnSorting ||
        !column.allowSort ||
        runtimeColumnId == null ||
        !_sort.isSortedRuntimeColumn(runtimeColumnId)) {
      return;
    }

    if (_activeCellEditorState?.finalizeEditing() == false) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    unawaited(
      _clearSortFromDataSet(runtimeColumnId: runtimeColumnId).then((applied) {
        if (!mounted || !applied) {
          return;
        }
      }),
    );
  }

  void _handleHeaderClearAllSorts() {
    // Clearing all sorts is a dataset-level action. The grid may expose this
    // action when the dataset was sorted through the public API even if
    // interactive column sorting is disabled for the grid. Therefore this
    // guard must not depend on allowColumnSorting. That option only controls
    // whether users can create/change sorts through grid header interactions.
    if (!_sort.hasSort && !widget.dataSet.sort.active) {
      return;
    }

    if (_activeCellEditorState?.finalizeEditing() == false) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    unawaited(
      _clearSortFromDataSet().then((applied) {
        if (!mounted || !applied) {
          return;
        }
      }),
    );
  }

  IconData? _sortIcon(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
      return null;
    }
    final column = _visibleColumns[columnIndex];
    if (!widget.options.allowColumnSorting || !column.allowSort) {
      return null;
    }
    if (!_sort.isSortedRuntimeColumn(_runtimeColumnIdAt(columnIndex))) {
      return null;
    }

    final ascending = _sort.ascendingForRuntimeColumn(
      _runtimeColumnIdAt(columnIndex),
    );
    return (ascending ?? true) ? Icons.north : Icons.south;
  }

  Color _sortIconColor(BuildContext context, int columnIndex) {
    return _headerTextStyle(context)?.color ??
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurface;
  }

  bool _canHeaderSort(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
      return false;
    }
    final column = _visibleColumns[columnIndex];
    return widget.options.allowColumnSorting && column.allowSort;
  }

  bool _isHeaderSortActive(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
      return false;
    }
    final column = _visibleColumns[columnIndex];
    if (!widget.options.allowColumnSorting || !column.allowSort) {
      return false;
    }
    return _sort.isSortedRuntimeColumn(_runtimeColumnIdAt(columnIndex));
  }

  int _headerSortPosition(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= _visibleColumns.length) {
      return 0;
    }
    return _sort.sortPositionForRuntimeColumn(_runtimeColumnIdAt(columnIndex));
  }

  bool _isHeaderSortAscending(int columnIndex) {
    return _isHeaderSortActive(columnIndex) &&
        (_sort.ascendingForRuntimeColumn(_runtimeColumnIdAt(columnIndex)) ??
            false);
  }

  bool _isHeaderSortDescending(int columnIndex) {
    return _isHeaderSortActive(columnIndex) &&
        !(_sort.ascendingForRuntimeColumn(_runtimeColumnIdAt(columnIndex)) ??
            true);
  }

  List<FdcDataSetSort> _effectiveDataSetSorts() {
    if (!widget.options.allowColumnSorting || !_sort.hasSort) {
      return const <FdcDataSetSort>[];
    }

    final sorts = <FdcDataSetSort>[];
    final usedFieldNames = <String>{};
    for (final item in _sort.items) {
      final columnIndex = _visibleRuntimeColumnIdsCache.indexOf(
        item.runtimeColumnId,
      );
      if (columnIndex == -1 || columnIndex >= _visibleColumns.length) {
        continue;
      }

      final column = _visibleColumns[columnIndex];
      if (!column.allowSort) {
        continue;
      }

      final normalizedFieldName = FdcFieldName.normalize(column.fieldName);
      if (!usedFieldNames.add(normalizedFieldName)) {
        continue;
      }

      sorts.add(
        FdcDataSetSort(
          fieldName: column.fieldName,
          sortType: item.ascending
              ? FdcSortType.ascending
              : FdcSortType.descending,
        ),
      );
    }

    return sorts;
  }

  FdcDataSetValueResolver? _dataSetValueResolverFor(
    FdcGridColumn<dynamic> column,
  ) {
    if (column.effectiveEditor == FdcEditorType.badge) {
      return _badgeComparableValue;
    }
    if (column.effectiveEditor == FdcEditorType.progress) {
      return _progressComparableValue;
    }
    return null;
  }

  static Object? _badgeComparableValue(Object? value) {
    if (value is FdcBadgeValue) {
      return value.text;
    }
    return value;
  }

  static Object? _progressComparableValue(Object? value) {
    if (value is FdcProgressValue) {
      return value.value;
    }
    return value;
  }

  Future<bool> _applySortToDataSet(
    FdcGridColumn<dynamic> column, {
    required FdcColumnIdentity runtimeColumnId,
    required bool ascending,
    bool append = false,
  }) async {
    if (!widget.dataSet.isOpen) {
      return false;
    }

    final horizontalOffsetToPreserve =
        _scrollCoordinator.currentHorizontalOffset;
    final previousSortItems = _sort.items;
    final activeIndexBeforeSort = FdcDataSetInternal.activeIndex(
      widget.dataSet,
    );

    if (append) {
      _removeSortsForField(
        column.fieldName,
        exceptRuntimeColumnId: runtimeColumnId,
      );
      _sort.addOrUpdate(runtimeColumnId: runtimeColumnId, ascending: ascending);
    } else if (_sort.isSortedRuntimeColumn(runtimeColumnId) && _sort.hasSort) {
      _sort.update(runtimeColumnId: runtimeColumnId, ascending: ascending);
    } else {
      _sort.setSingle(runtimeColumnId: runtimeColumnId, ascending: ascending);
    }

    var applied = false;
    _updatingDataSetFromGrid = true;
    try {
      applied = await widget.dataSet.sort.set(_effectiveDataSetSorts());
    } on Object catch (error, stackTrace) {
      _restoreSortStateAfterFailure(
        previousSortItems,
        activeIndexBeforeSort,
        showDataSetErrors: false,
      );
      unawaited(
        _handleDataSetPostError(
          error,
          stackTrace,
          focusActiveEditorAfterDialog: true,
        ),
      );
      return false;
    } finally {
      _updatingDataSetFromGrid = false;
    }

    if (!mounted) {
      return false;
    }

    if (!applied) {
      _restoreSortStateAfterFailure(previousSortItems, activeIndexBeforeSort);
      return false;
    }

    _setGridState(() {
      _rows = _rowsFromDataSet();
      _refreshRowsFromDataSet();
      _syncGridSelectionFromDataSetCurrent(scrollColumnIntoView: false);
      _validateCellState();
    });
    _restoreHorizontalOffsetAfterLayout(horizontalOffsetToPreserve);
    return true;
  }

  Future<bool> _clearSortFromDataSet({
    FdcColumnIdentity? runtimeColumnId,
  }) async {
    if (!widget.dataSet.isOpen) {
      return false;
    }

    final horizontalOffsetToPreserve =
        _scrollCoordinator.currentHorizontalOffset;
    final previousSortItems = _sort.items;
    final activeIndexBeforeSort = FdcDataSetInternal.activeIndex(
      widget.dataSet,
    );

    if (runtimeColumnId == null) {
      _sort.clear();
    } else {
      _sort.remove(runtimeColumnId);
    }

    var applied = false;
    _updatingDataSetFromGrid = true;
    try {
      final sorts = _effectiveDataSetSorts();
      if (sorts.isEmpty) {
        applied = await widget.dataSet.sort.clear();
      } else {
        applied = await widget.dataSet.sort.set(sorts);
      }
    } on Object catch (error, stackTrace) {
      _restoreSortStateAfterFailure(
        previousSortItems,
        activeIndexBeforeSort,
        showDataSetErrors: false,
      );
      unawaited(
        _handleDataSetPostError(
          error,
          stackTrace,
          focusActiveEditorAfterDialog: true,
        ),
      );
      return false;
    } finally {
      _updatingDataSetFromGrid = false;
    }

    if (!mounted) {
      return false;
    }

    if (!applied) {
      _restoreSortStateAfterFailure(previousSortItems, activeIndexBeforeSort);
      return false;
    }

    _setGridState(() {
      _rows = _rowsFromDataSet();
      _refreshRowsFromDataSet();
      _syncGridSelectionFromDataSetCurrent(scrollColumnIntoView: false);
      _validateCellState();
    });
    _restoreHorizontalOffsetAfterLayout(horizontalOffsetToPreserve);
    return true;
  }

  void _restoreSortStateAfterFailure(
    List<FdcGridSortItem> previousSortItems,
    int activeIndexBeforeSort, {
    bool showDataSetErrors = true,
  }) {
    if (!mounted) {
      return;
    }

    _setGridState(() {
      _sort.setAll(previousSortItems);
      _rows = _rowsFromDataSet();
      _refreshRowsFromDataSet();
      _validateCellState();
    });

    if (activeIndexBeforeSort >= 0) {
      _restoreCellAfterFailedRowPost(activeIndexBeforeSort);
    }
    if (showDataSetErrors && widget.dataSet.errors.messages.isNotEmpty) {
      _showGridOperationErrorsIfNeeded(focusActiveEditorAfterDialog: true);
    }
  }

  void _removeSortsForField(
    String fieldName, {
    FdcColumnIdentity? exceptRuntimeColumnId,
  }) {
    final normalizedFieldName = FdcFieldName.normalize(fieldName);
    for (final item in List<FdcGridSortItem>.from(_sort.items)) {
      if (exceptRuntimeColumnId != null &&
          item.runtimeColumnId == exceptRuntimeColumnId) {
        continue;
      }
      final columnIndex = _visibleRuntimeColumnIdsCache.indexOf(
        item.runtimeColumnId,
      );
      if (columnIndex == -1 || columnIndex >= _visibleColumns.length) {
        continue;
      }
      final column = _visibleColumns[columnIndex];
      if (FdcFieldName.normalize(column.fieldName) == normalizedFieldName) {
        _sort.remove(item.runtimeColumnId);
      }
    }
  }
}
