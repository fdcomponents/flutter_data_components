// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridWidgetLifecycleRuntime on _FdcGridState {
  void _handleGridDependenciesChanged(BuildContext context) {
    final nextTextDirection = Directionality.of(context);
    if (_textDirection != nextTextDirection) {
      _textDirection = nextTextDirection;
      _refreshColumnBandsCache();
      _columnCellRenderInfoCache.clear();
      _markColumnWidthsDirty();
    }
    final formatSettings = _effectiveFormatSettings(context);
    final translations = FdcApp.translationsOf(context);
    if (_formatSettings == formatSettings && _translations == translations) {
      return;
    }

    _formatSettings = formatSettings;
    _translations = translations;
    _valueFormatter = _createValueFormatter(formatSettings);
    _refreshRowsFromSource(
      notifyDataSet: false,
      applyFilters: _hasGridManagedFilterState,
    );
    _validateCellState();
  }

  void _handleGridWidgetUpdated(FdcGridHost oldWidget) {
    final oldRangeSelectionConfigured =
        oldWidget.rangeSelection?.enabled ?? false;
    final rangeSelectionConfigured = widget.rangeSelection?.enabled ?? false;
    if (oldRangeSelectionConfigured && !rangeSelectionConfigured) {
      _resetRangeSelectionState(rebuild: false);
      _notifyRangeSelectionReset(rebuild: false);
    }

    if (oldWidget.rangeSelection != widget.rangeSelection) {
      _resetRangeSelectionState(rebuild: false);
      _notifyRangeSelectionReset(rebuild: false);
      _detachGridRangeSelectionFeature(oldWidget.rangeSelection);
      _rangeSelectionSession = _createGridRangeSelectionSession();
      _attachGridRangeSelectionFeature();
    }

    if (oldWidget.controller != widget.controller ||
        oldWidget.layoutPersistence != widget.layoutPersistence) {
      _detachGridLayoutStateFeature(
        oldWidget.controller,
        layoutPersistence: oldWidget.layoutPersistence,
      );
      _attachGridLayoutStateFeature();
    }

    if (oldWidget.dataSet != widget.dataSet) {
      _resetRangeSelectionState(rebuild: false);
      _notifyRangeSelectionReset(rebuild: false);
      _clearDetailRowState();
      _handleGridDataSetWidgetChanged(oldWidget);
    } else if (oldWidget.detailRow != widget.detailRow) {
      final oldDetailRow = oldWidget.detailRow;
      final newDetailRow = widget.detailRow;
      if (newDetailRow == null) {
        _clearDetailRowState();
      } else if (oldDetailRow == null ||
          _detailRowExtentConfigurationChanged(oldDetailRow, newDetailRow)) {
        _detailRowMeasuredHeights.clear();
      }
    }

    final filterOptionsChanged =
        oldWidget.header.filters.options != widget.header.filters.options;
    final columnFilteringCapabilityChanged =
        oldWidget.options.allowColumnFiltering !=
            widget.options.allowColumnFiltering ||
        oldWidget.header.filters.visible != widget.header.filters.visible;

    _handleGridHeaderFilterWidgetChanged(
      oldWidget,
      filterOptionsChanged: filterOptionsChanged,
      columnFilteringCapabilityChanged: columnFilteringCapabilityChanged,
    );

    final nextColumnDefinitionsSignature = _columnDefinitionsSignatureFor(
      widget.columns,
    );
    final nextColumnGroupsSignature = _columnGroupsSignatureFor(
      widget.columnGroups,
    );
    final columnDefinitionsChanged = !_signatureEquals(
      _columnDefinitionsSignature,
      nextColumnDefinitionsSignature,
    );
    final columnGroupsChanged = !_signatureEquals(
      _columnGroupsSignature,
      nextColumnGroupsSignature,
    );

    if (_columnStructureChanged(
      oldWidget,
      columnDefinitionsChanged: columnDefinitionsChanged,
      columnGroupsChanged: columnGroupsChanged,
    )) {
      _resetRangeSelectionState(rebuild: false);
      _notifyRangeSelectionReset(rebuild: false);
      _handleColumnStructureChanged(
        columnDefinitionsChanged: columnDefinitionsChanged,
        refreshRowsFromSource: _hasGridManagedFilterState,
      );
      _columnDefinitionsSignature = nextColumnDefinitionsSignature;
      _columnGroupsSignature = nextColumnGroupsSignature;
    }

    if (oldWidget.options.allowColumnSorting &&
        !widget.options.allowColumnSorting) {
      _sort.clear();
      _refreshRowsFromSource(notifyDataSet: false, applyFilters: false);
    }
  }

  bool _detailRowExtentConfigurationChanged(
    FdcGridDetailRowFeature oldFeature,
    FdcGridDetailRowFeature newFeature,
  ) {
    return oldFeature.height != newFeature.height ||
        oldFeature.minHeight != newFeature.minHeight ||
        oldFeature.maxHeight != newFeature.maxHeight ||
        oldFeature.padding != newFeature.padding;
  }

  void _handleGridDataSetWidgetChanged(FdcGridHost oldWidget) {
    _clearFieldMetadataCache();
    _rowIndicatorWidthAnchorRowCount = null;
    _holdRowIndicatorWidthUntilCountRestores = false;
    oldWidget.dataSet.removeListener(_handleDataSetChanged);
    oldWidget.dataSet.work.removeListener(_handleDataSetWorkChanged);
    FdcDataSetInternal.removeErrorListener(
      oldWidget.dataSet,
      _handleDataSetError,
    );
    FdcDataSetInternal.removeFilterChangedListener(
      oldWidget.dataSet,
      _handleDataSetFilterChanged,
    );
    widget.dataSet.addListener(_handleDataSetChanged);
    widget.dataSet.work.addListener(_handleDataSetWorkChanged);
    FdcDataSetInternal.addErrorListener(widget.dataSet, _handleDataSetError);
    FdcDataSetInternal.addFilterChangedListener(
      widget.dataSet,
      _handleDataSetFilterChanged,
    );
    _rows = _rowsFromDataSet();
    _lastObservedDataSetState = widget.dataSet.state;
    _lastObservedDataSetRecordCount = widget.dataSet.recordCount;
    _refreshColumnCache();
    _syncHeaderSortFromDataSet();
    _refreshRowsFromSource(
      notifyDataSet: false,
      applyFilters: _hasGridManagedFilterState,
    );
    _validateCellState();
    _syncInteractionState();
  }

  void _handleGridHeaderFilterWidgetChanged(
    FdcGridHost oldWidget, {
    required bool filterOptionsChanged,
    required bool columnFilteringCapabilityChanged,
  }) {
    final initialVisibilityChanged =
        oldWidget.header.filters.initiallyVisible !=
        widget.header.filters.initiallyVisible;
    if (columnFilteringCapabilityChanged || initialVisibilityChanged) {
      _showColumnFilters = _headerFiltersInitiallyVisible;
    }

    final oldColumnFilteringAllowed =
        oldWidget.header.visible &&
        oldWidget.header.filters.visible &&
        oldWidget.options.allowColumnFiltering;
    if ((filterOptionsChanged || columnFilteringCapabilityChanged) &&
        oldColumnFilteringAllowed &&
        !_columnFilteringAllowed &&
        _hasHeaderFilterState) {
      _clearHeaderFilterUiState();
      _refreshRowsFromSource(
        notifyDataSet: false,
        applyFilters: _hasGridManagedFilterState,
      );
      _validateCellState();
    }

    if (filterOptionsChanged || columnFilteringCapabilityChanged) {
      _refreshRowsFromSource(notifyDataSet: false, applyFilters: false);
      _validateCellState();
    }
  }

  bool _columnStructureChanged(
    FdcGridHost oldWidget, {
    required bool columnDefinitionsChanged,
    required bool columnGroupsChanged,
  }) {
    final defaultColumnWidthChanged =
        oldWidget.options.resolvedDefaultColumnWidth !=
        widget.options.resolvedDefaultColumnWidth;
    final rowIndicatorVisibleChanged =
        oldWidget.rowIndicator.visible != widget.rowIndicator.visible;
    final headerFiltersVisibleChanged =
        oldWidget.header.filters.visible != widget.header.filters.visible ||
        oldWidget.header.filters.initiallyVisible !=
            widget.header.filters.initiallyVisible;
    final headerFiltersStyleChanged =
        oldWidget.header.filters.style != widget.header.filters.style;
    final allowColumnFilteringChanged =
        oldWidget.options.allowColumnFiltering !=
        widget.options.allowColumnFiltering;
    final rowIndicatorOptionsChanged =
        oldWidget.rowIndicator.options != widget.rowIndicator.options;
    final changed =
        columnDefinitionsChanged ||
        columnGroupsChanged ||
        defaultColumnWidthChanged ||
        rowIndicatorVisibleChanged ||
        headerFiltersVisibleChanged ||
        headerFiltersStyleChanged ||
        allowColumnFilteringChanged ||
        rowIndicatorOptionsChanged;
    return changed;
  }

  void _handleColumnStructureChanged({
    required bool columnDefinitionsChanged,
    required bool refreshRowsFromSource,
  }) {
    if (columnDefinitionsChanged) {
      _columnSizing.resetAutoSize();
    }
    _refreshColumnCache();
    _syncHeaderSortFromDataSet();
    if (refreshRowsFromSource) {
      _refreshRowsFromSource(
        notifyDataSet: false,
        applyFilters: _hasGridManagedFilterState,
      );
    } else {}
    _validateCellState();
  }

  bool _signatureEquals(List<Object?> left, List<Object?> right) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  List<Object?> _columnGroupsSignatureFor(List<FdcGridColumnGroup> groups) {
    return <Object?>[
      groups.length,
      for (final group in groups) ...<Object?>[
        group.id,
        group.label,
        group.style,
      ],
    ];
  }

  List<Object?> _columnDefinitionsSignatureFor(
    List<FdcGridColumn<dynamic>> columns,
  ) {
    return <Object?>[
      columns.length,
      for (final column in columns) ..._columnDefinitionSignatureFor(column),
    ];
  }

  List<Object?> _columnDefinitionSignatureFor(FdcGridColumn<dynamic> column) {
    return <Object?>[
      column.runtimeType,
      column.id,
      column.groupId,
      column.fieldName,
      column.label,
      column.hint,
      column.visible,
      column.exportable,
      column.enabled,
      column.readOnly,
      column.focusOrder,
      column.tabStop,
      column.width,
      column.minWidth,
      column.maxWidth,
      column.autoSizeMode,
      column.allowSort,
      ..._filterConfigSignatureFor(column.filterConfig),
      column.allowResize,
      column.horizontalAlignment,
      column.showIndicator,
      column.lookupSignatureToken != null,
      column.lookupIcon,
      column.lookupShortcut,
      ..._cellStyleSignatureFor(column.cellStyle),
      column.pin,
      column.summary.aggregate,
      column.summary.label,
      column.summary.labelVisible,
      column.summary.labelAlignment,
      column.summary.allowAggregateChange,
      ..._summaryStyleSignatureFor(column.summary.style),
      column.effectiveEditor,
      column.dataType,
      column.isInherentlyReadOnly,
      column.showCounter,
      ..._counterStyleSignatureFor(column.counterStyle),
      column.allowNegative,
      ..._formatSettingsSignatureFor(column.formatSettings),
      column.showPicker,
      ..._optionsSignatureFor(column.options),
      column.showSelectedOptionCheckmark,
      ..._comboSearchSignatureFor(column.comboSearch),
      column.comboSearchHintText,
      column.comboMaxPopupItems,
      column.badgeText,
      column.badgeColor,
      column.badgeTextStyle,
      column.progressMin,
      column.progressMax,
      column.progressStyle,
      if (column is FdcBooleanColumn<dynamic>) column.control,
      if (column is FdcActionColumn) ..._actionColumnSignatureFor(column),
    ];
  }

  List<Object?> _actionColumnSignatureFor(FdcActionColumn column) {
    return <Object?>[
      column.iconSize,
      column.spacing,
      column.padding,
      column.actions.length,
      for (final action in column.actions) ...<Object?>[
        action.icon,
        action.tooltip,
        action.activateRowOnPressed,
        action.color,
        action.disabledColor,
      ],
    ];
  }

  List<Object?> _filterConfigSignatureFor(FdcColumnFilterConfig? config) {
    if (config == null) {
      return const <Object?>[null];
    }
    return <Object?>[
      config.enabled,
      config.editor,
      ..._optionsSignatureFor(config.values ?? const <FdcOption<Object?>>[]),
      config.defaultOperator,
      ..._listSignatureFor(config.operators ?? const <FdcFilterOperator>[]),
      config.caseSensitive,
      config.comboSearchable,
      config.comboSearchHintText,
      config.comboMaxPopupItems,
    ];
  }

  List<Object?> _cellStyleSignatureFor(FdcGridCellStyle? style) {
    if (style == null) {
      return const <Object?>[null];
    }
    return <Object?>[style.textStyle, style.backgroundColor, style.alignment];
  }

  List<Object?> _summaryStyleSignatureFor(FdcGridSummaryCellStyle? style) {
    if (style == null) {
      return const <Object?>[null];
    }
    return <Object?>[
      style.backgroundColor,
      style.textStyle,
      style.alignment,
      style.padding,
    ];
  }

  List<Object?> _counterStyleSignatureFor(FdcCounterStyle style) {
    return <Object?>[
      style.textStyle,
      style.alignment,
      style.offset,
      style.height,
    ];
  }

  List<Object?> _formatSettingsSignatureFor(FdcFormatSettings? settings) {
    if (settings == null) {
      return const <Object?>[null];
    }
    return <Object?>[
      settings.locale,
      settings.dateFormat,
      settings.timeFormat,
      settings.dateTimeFormat,
      settings.decimalSeparator,
      settings.thousandSeparator,
      settings.showThousandSeparator,
    ];
  }

  List<Object?> _comboSearchSignatureFor(FdcComboSearchOptions search) {
    return <Object?>[search.searchable, search.searchableInline, search.mode];
  }

  List<Object?> _optionsSignatureFor(Iterable<FdcOption<dynamic>> options) {
    return <Object?>[
      options.length,
      for (final option in options) ...<Object?>[option.value, option.label],
    ];
  }

  List<Object?> _listSignatureFor(Iterable<Object?> values) {
    return <Object?>[values.length, ...values];
  }

  void _disposeGridRuntimeResources() {
    // A window close, hot restart, or widget removal can happen while Shift is
    // still held. Release range-owned restore locks before disposing the
    // coordinator so no nested lock depth survives the grid lifecycle.
    _resetRangeSelectionState(rebuild: false);
    _notifyRangeSelectionReset(rebuild: false);

    _detachGridRangeSelectionFeature(widget.rangeSelection);
    _detachGridLayoutStateFeature(widget.controller);
    widget.dataSet.removeListener(_handleDataSetChanged);
    widget.dataSet.work.removeListener(_handleDataSetWorkChanged);
    FdcDataSetInternal.removeErrorListener(widget.dataSet, _handleDataSetError);
    FdcDataSetInternal.removeFilterChangedListener(
      widget.dataSet,
      _handleDataSetFilterChanged,
    );
    _runtime.removeVerticalScrollListener(
      _handleVerticalScrollControllerChanged,
    );
    _fdcGridKeyboardFocusRoots.remove(_gridFocusNode);
    HardwareKeyboard.instance.removeHandler(
      _handleGlobalRangeSelectionKeyEvent,
    );
    _gridFocusNode.removeListener(_handleGridFocusChanged);
    _gridFocusNode.dispose();
    _interactionState.dispose();
    _runtime.dispose();
  }
}
