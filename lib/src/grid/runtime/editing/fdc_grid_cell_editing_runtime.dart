// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridCellEditingRuntime on _FdcGridState {
  void _openDropdownCell(
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
  ) {
    final cell = _cellRef(rowIndex, columnIndex);
    if (!_unfocusActiveEditorBeforeCellChange(cell)) {
      return;
    }
    if (!_postCurrentRowIfLeaving(rowIndex)) {
      return;
    }
    _activateCell(
      cell,
      editIfPossible: true,
      revealColumn: false,
      focusReason: FdcGridFocusChangeReason.mouse,
    );
    _activateDropdownEditorAfterLayout();
  }

  Future<void> _pickCellValue(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
  ) async {
    final viewport = _takeCellControlPointerViewport(rowIndex, columnIndex);
    final targetRowIndex = viewport?.rowIndex ?? rowIndex;
    if (targetRowIndex < 0 ||
        targetRowIndex >= _rows.length ||
        !_isCellEditable(column, targetRowIndex)) {
      return;
    }

    var canOpenPicker = false;
    _runMouseCellControlScrollGuarded(
      () {
        if (!_postCurrentRowIfLeaving(targetRowIndex)) {
          return;
        }
        _activateCell(
          _cellRef(targetRowIndex, columnIndex),
          editIfPossible: false,
          revealColumn: false,
          focusReason: FdcGridFocusChangeReason.mouse,
        );
        canOpenPicker = true;
      },
      horizontalOffset: viewport?.horizontalOffset,
      verticalOffset: viewport?.verticalOffset,
      suppressFrameCount: 4,
    );
    if (!canOpenPicker) {
      return;
    }

    final pickedValue = await FdcValuePicker.pick(
      context: context,
      kind: _pickerKindForEditor(column.effectiveEditor),
      currentValue: _dataSetValueAt(targetRowIndex, column),
    );
    if (pickedValue == null || !mounted) {
      return;
    }

    _runMouseCellControlScrollGuarded(
      () => _updateCell(targetRowIndex, column, pickedValue),
      horizontalOffset: viewport?.horizontalOffset,
      verticalOffset: viewport?.verticalOffset,
      suppressFrameCount: 4,
    );
  }

  FdcValueCodecKind _pickerKindForEditor(FdcEditorType editor) {
    return switch (editor) {
      FdcEditorType.time => FdcValueCodecKind.time,
      FdcEditorType.dateTime => FdcValueCodecKind.dateTime,
      _ => FdcValueCodecKind.date,
    };
  }

  Future<bool> _lookupCellValue(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
    String? editorText,
    FdcLookupMode mode,
  ) async {
    if (column.lookupSignatureToken == null ||
        !_isCellEditable(column, rowIndex) ||
        _lookupCellInProgress != null) {
      return false;
    }

    final lookupCell = _cellRef(rowIndex, columnIndex);
    _lookupCellInProgress = lookupCell;

    final FdcGridLookupApplyResult lookup;
    try {
      lookup = await column.applyLookup(
        buildContext: context,
        dataSet: widget.dataSet,
        row: _gridRowAt(rowIndex),
        fieldName: column.fieldName,
        lookupText: editorText ?? _lookupTextAt(rowIndex, column),
        mode: mode,
      );
    } on Object catch (error, stackTrace) {
      if (mounted) {
        await _handleDataSetPostError(
          error,
          stackTrace,
          focusActiveEditorAfterDialog: true,
        );
      }
      return false;
    } finally {
      if (_lookupCellInProgress == lookupCell) {
        _lookupCellInProgress = null;
      }
    }
    final resolvedCell = _resolveCellRef(lookupCell);
    final activeCell = _editingCell ?? _selectedCell;
    if (!mounted ||
        resolvedCell == null ||
        (mode == FdcLookupMode.search &&
            activeCell?.matches(lookupCell) != true)) {
      return false;
    }

    final Map<String, Object?> lookupValues;
    switch (lookup) {
      case FdcGridLookupApplyAccepted(:final values):
        lookupValues = Map<String, Object?>.of(values);
      case FdcGridLookupApplyCanceled():
        return false;
    }
    final targetRowIndex = resolvedCell.rowIndex;
    final targetColumnIndex = resolvedCell.columnIndex;
    if (!_isLiveGridRowIndex(targetRowIndex) ||
        !_isCellEditable(column, targetRowIndex)) {
      return false;
    }

    final normalizedPrimaryFieldName = FdcFieldName.normalize(column.fieldName);
    String? primaryLookupFieldName;
    Object? primaryLookupValue;
    for (final entry in lookupValues.entries) {
      if (FdcFieldName.normalize(entry.key) == normalizedPrimaryFieldName) {
        primaryLookupFieldName = entry.key;
        primaryLookupValue = entry.value;
        break;
      }
    }

    final targetOldValue = _dataSetValueAt(targetRowIndex, column);
    Object? acceptedValue = targetOldValue;
    Map<String, Object?> valueChangingAdditionalValues =
        const <String, Object?>{};
    final resolveTextFallback = mode == FdcLookupMode.resolve
        ? _parseLookupResolveEditorText(
            column,
            targetRowIndex,
            targetColumnIndex,
            editorText,
          )
        : null;
    if (lookupValues.isEmpty && resolveTextFallback == null) {
      return false;
    }
    if (primaryLookupFieldName != null || resolveTextFallback != null) {
      final change = _applyColumnValueChanging(
        column,
        rowIndex: targetRowIndex,
        columnIndex: targetColumnIndex,
        fieldName: column.fieldName,
        oldValue: targetOldValue,
        newValue: primaryLookupFieldName != null
            ? primaryLookupValue
            : resolveTextFallback?.value,
      );
      switch (change) {
        case FdcGridColumnValueChangeCancelled():
          return false;

        case FdcGridColumnValueChangeAccepted(
          :final value,
          :final additionalValues,
        ):
          acceptedValue = value;
          valueChangingAdditionalValues = additionalValues;
      }
      if (primaryLookupFieldName != null) {
        lookupValues.remove(primaryLookupFieldName);
      }
    }

    final additionalValues = <String, Object?>{
      ...lookupValues,
      ...valueChangingAdditionalValues,
    };
    final accepted = _applyCellEditWrite(
      rowIndex: targetRowIndex,
      columnIndex: targetColumnIndex,
      fieldName: column.fieldName,
      column: column,
      oldValue: targetOldValue,
      value: acceptedValue,
      additionalValues: additionalValues,
      ensureEdit: () => _ensureDataSetEditForCell(
        targetRowIndex,
        column,
        focusActiveEditorAfterDialog: true,
      ),
      emitValidation: (value) =>
          _emitDataSetFieldValidation(targetRowIndex, column, value),
      markLayoutDirty: () => _markColumnWidthsDirtyFor(column),
      handleInvalidFieldNames: true,
      focusActiveEditorAfterDialog: true,
    );
    if (accepted) {
      _clearPendingEditText();
      _setGridState(() {});
    }
    return accepted;
  }

  String? _lookupTextAt(int rowIndex, FdcGridColumn<dynamic> column) {
    final value = _dataSetValueAt(rowIndex, column);
    if (value == null) {
      return null;
    }
    return _valueFormatter.format(column, value);
  }

  ({Object? value})? _parseLookupResolveEditorText(
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
    String? editorText,
  ) {
    if (editorText == null) {
      return null;
    }

    final metadata = _fieldMetadata(column.fieldName);
    final cell = _cellRef(rowIndex, columnIndex);
    final parsed =
        FdcFieldValueCodec(
          settings: column.formatSettings ?? _formatSettings,
        ).parseGridTextForCommit(
          column,
          editorText,
          runtimeColumnId: cell.runtimeColumnId,
          decimalScale: metadata.decimalScale,
          decimalPrecision: metadata.decimalPrecision,
        );
    if (parsed.errorText != null) {
      return null;
    }
    return (value: parsed.value);
  }

  bool _shouldToggleBooleanCell(FdcGridColumn<dynamic> column, int rowIndex) {
    return (column.effectiveEditor == FdcEditorType.checkbox ||
            column.effectiveEditor == FdcEditorType.switcher) &&
        _isCellEditable(column, rowIndex);
  }

  void _toggleBooleanCell(
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
  ) {
    if (!_postCurrentRowIfLeaving(rowIndex)) {
      return;
    }
    _activateCell(
      _cellRef(rowIndex, columnIndex),
      editIfPossible: false,
      focusReason: FdcGridFocusChangeReason.mouse,
    );
    _updateCell(
      rowIndex,
      column,
      _nextBooleanValue(
        _dataSetValueAt(rowIndex, column),
        allowsNull: _booleanCellAllowsNull(column),
      ),
    );
  }

  void _setBooleanCell(
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
    bool? value,
  ) {
    final viewport = _takeCellControlPointerViewport(rowIndex, columnIndex);
    final targetRowIndex = viewport?.rowIndex ?? rowIndex;
    _runMouseCellControlScrollGuarded(
      () {
        final targetCell = _cellRef(targetRowIndex, columnIndex);
        final normalizedValue =
            value ?? (_booleanCellAllowsNull(column) ? null : false);
        if (!_postCurrentRowIfLeaving(
          targetRowIndex,
          continueToCellAfterImmediatePost: targetCell,
          focusReasonAfterImmediatePost: FdcGridFocusChangeReason.mouse,
          suppressColumnRevealAfterImmediatePost: true,
        )) {
          _setPendingCellWrite(normalizedValue);
          return;
        }
        _activateCell(
          targetCell,
          editIfPossible: false,
          revealColumn: false,
          focusReason: FdcGridFocusChangeReason.mouse,
        );
        _updateCell(targetRowIndex, column, normalizedValue);
      },
      horizontalOffset: viewport?.horizontalOffset,
      verticalOffset: viewport?.verticalOffset,
      suppressFrameCount: 4,
    );
  }

  bool _booleanCellAllowsNull(FdcGridColumn<dynamic> column) {
    if (!column.isDataBound) {
      return true;
    }

    try {
      return !widget.dataSet.fieldDef(column.fieldName).required;
    } on Object {
      // Field binding validation should catch invalid data-bound columns before
      // editing. Keep the boolean fallback permissive so this helper never
      // masks the original binding/schema error path.
      return true;
    }
  }

  bool? _nextBooleanValue(Object? value, {required bool allowsNull}) {
    if (!allowsNull) {
      return value == true ? false : true;
    }

    return switch (value) {
      null => true,
      true => false,
      false => null,
      _ => true,
    };
  }

  Object? _cellEditorOriginalValue(
    int rowIndex,
    int columnIndex,
    Object? fallbackValue,
  ) {
    final cell = _cellRef(rowIndex, columnIndex);
    if (_hasEditingOriginalValue && _editingOriginalCell == cell) {
      return _editingOriginalValue;
    }
    return fallbackValue;
  }

  String? _cellEditorOriginalText(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
    FdcValueFormatter valueFormatter,
    Object? fallbackValue,
  ) {
    final value = _cellEditorOriginalValue(
      rowIndex,
      columnIndex,
      fallbackValue,
    );
    return valueFormatter.format(
      column,
      value,
      runtimeColumnId: _runtimeColumnIdAt(columnIndex),
      forEditing: true,
    );
  }

  String? _cellEditorInitialText(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    Object? value,
    int rowIndex,
    int columnIndex,
  ) {
    if (_isPendingEditCell(rowIndex, columnIndex)) {
      return _pendingEditText;
    }
    if (!_typing.isDateLikeEditor(column) &&
        column.effectiveEditor != FdcEditorType.decimal) {
      return null;
    }

    return FdcValueFormatter(
      settings: FdcApp.formatsOf(context),
      translations: FdcApp.translationsOf(context),
      decimalScaleResolver: (column, {runtimeColumnId}) =>
          _fieldMetadata(column.fieldName).decimalScale,
    ).format(
      column,
      value,
      runtimeColumnId: _runtimeColumnIdAt(columnIndex),
      forEditing: true,
    );
  }

  int _columnIndexForFieldWrite(String fieldName, int fallbackColumnIndex) {
    final normalizedFieldName = FdcFieldName.normalize(fieldName);
    final columns = _visibleColumns;
    if (fallbackColumnIndex >= 0 && fallbackColumnIndex < columns.length) {
      final fallbackColumn = columns[fallbackColumnIndex];
      if (FdcFieldName.normalize(fallbackColumn.fieldName) ==
          normalizedFieldName) {
        return fallbackColumnIndex;
      }
    }

    final index = columns.indexWhere(
      (column) =>
          FdcFieldName.normalize(column.fieldName) == normalizedFieldName,
    );
    return index >= 0 ? index : fallbackColumnIndex;
  }

  void _emitColumnValueChanged(
    FdcGridColumn<dynamic>? column, {
    required int rowIndex,
    required int? columnIndex,
    required String fieldName,
    required Object? oldValue,
    required Object? value,
  }) {
    if (column == null) {
      return;
    }

    final visibleColumnIndex =
        columnIndex != null &&
            columnIndex >= 0 &&
            columnIndex < _visibleColumns.length
        ? columnIndex
        : null;

    _runGridAppCallback(() {
      column.applyValueChanged(
        dataSet: widget.dataSet,
        row: _gridRowAt(rowIndex),
        rowIndex: rowIndex,
        columnIndex: visibleColumnIndex,
        fieldName: fieldName,
        oldValue: oldValue,
        value: value,
      );
    });
  }

  void _emitCellChanged(
    int rowIndex,
    int? columnIndex,
    String fieldName,
    Object? oldValue,
    Object? value,
  ) {
    final listener = widget.onCellChanged;
    if (listener == null) {
      return;
    }

    final resolvedColumnIndex = _columnIndexForFieldWrite(
      fieldName,
      columnIndex ?? -1,
    );
    final visibleColumnIndex =
        resolvedColumnIndex >= 0 && resolvedColumnIndex < _visibleColumns.length
        ? resolvedColumnIndex
        : null;
    final column = visibleColumnIndex == null
        ? null
        : _visibleColumns[visibleColumnIndex];

    _runGridAppCallback(() {
      listener(
        FdcFieldValueChangedContext<dynamic>(
          dataSet: widget.dataSet,
          host: FdcFieldEventHost.grid,
          rowIndex: rowIndex,
          columnIndex: visibleColumnIndex,
          fieldName: fieldName,
          oldValue: oldValue,
          value: value,
          oldRawValue: oldValue,
          rawValue: value,
          row: _gridRowAt(rowIndex),
          column: column,
          valueOf: _gridRowAt(rowIndex).valueOf,
        ),
      );
    });
  }

  int _resolveLiveRowIndex(int rowIndex, int? recordId) {
    if (recordId == null ||
        !FdcDataSetInternal.containsRecordId(widget.dataSet, recordId)) {
      return rowIndex;
    }

    final activeIndex = FdcDataSetInternal.activeIndexForRecordId(
      widget.dataSet,
      recordId,
    );
    if (activeIndex < 0 || activeIndex >= _rows.length) {
      return rowIndex;
    }

    return activeIndex;
  }

  FdcGridColumn<dynamic>? _columnForFieldWrite(
    String fieldName,
    int targetColumnIndex,
  ) {
    final normalizedFieldName = FdcFieldName.normalize(fieldName);
    if (targetColumnIndex >= 0 && targetColumnIndex < _visibleColumns.length) {
      final column = _visibleColumns[targetColumnIndex];
      if (FdcFieldName.normalize(column.fieldName) == normalizedFieldName) {
        return column;
      }
    }

    for (final column in widget.columns) {
      if (FdcFieldName.normalize(column.fieldName) == normalizedFieldName) {
        return column;
      }
    }

    return null;
  }

  FdcGridColumnValueChangeOutcome _cancelColumnValueChange(
    String fieldName,
    String? message,
  ) {
    if (message != null && message.trim().isNotEmpty) {
      unawaited(
        _showGridOperationErrorDialog(
          FdcDataSetValidationException(<FdcValidationError>[
            FdcValidationError(fieldName: fieldName, message: message.trim()),
          ]),
        ),
      );
    }
    return const FdcGridColumnValueChangeOutcome.cancelled();
  }

  FdcGridColumnValueChangeOutcome _applyColumnValueChanging(
    FdcGridColumn<dynamic>? column, {
    required int rowIndex,
    required int columnIndex,
    required String fieldName,
    required Object? oldValue,
    required Object? newValue,
  }) {
    if (column == null) {
      return FdcGridColumnValueChangeOutcome.accepted(newValue);
    }

    try {
      final result = column.applyValueChanging(
        dataSet: widget.dataSet,
        row: _gridRowAt(rowIndex),
        rowIndex: rowIndex,
        columnIndex: columnIndex,
        fieldName: fieldName,
        oldValue: oldValue,
        newValue: newValue,
      );

      if (result == null) {
        return FdcGridColumnValueChangeOutcome.accepted(newValue);
      }

      return switch (result) {
        FdcFieldValueChangeCanceled(:final message) => _cancelColumnValueChange(
          fieldName,
          message,
        ),

        FdcFieldValueChangeAccepted(:final additionalValues) =>
          FdcGridColumnValueChangeOutcome.accepted(
            newValue,
            additionalValues: additionalValues,
          ),

        FdcFieldValueChangeReplacement(
          :final replacementValue,
          :final additionalValues,
        ) =>
          FdcGridColumnValueChangeOutcome.accepted(
            replacementValue,
            additionalValues: additionalValues,
          ),
      };
    } on Object catch (error) {
      unawaited(_showGridOperationErrorDialog(error));
      return const FdcGridColumnValueChangeOutcome.cancelled();
    }
  }

  bool _updateFieldFromCell(
    int rowIndex,
    int? recordId,
    int columnIndex,
    String fieldName,
    Object? value,
  ) {
    final viewport = _takeCellControlPointerViewport(rowIndex, columnIndex);
    if (viewport == null) {
      return _updateFieldFromCellCore(
        rowIndex,
        recordId,
        columnIndex,
        fieldName,
        value,
      );
    }

    var accepted = false;
    _runMouseCellControlScrollGuarded(
      () {
        accepted = _updateFieldFromCellCore(
          viewport.rowIndex,
          recordId,
          columnIndex,
          fieldName,
          value,
        );
      },
      horizontalOffset: viewport.horizontalOffset,
      verticalOffset: viewport.verticalOffset,
      suppressFrameCount: 4,
    );
    return accepted;
  }

  bool _updateFieldFromCellCore(
    int rowIndex,
    int? recordId,
    int columnIndex,
    String fieldName,
    Object? value,
  ) {
    final liveRowIndex = _resolveLiveRowIndex(rowIndex, recordId);
    final targetColumnIndex = _columnIndexForFieldWrite(fieldName, columnIndex);
    final cell = _cellRef(liveRowIndex, targetColumnIndex);
    if (!_unfocusActiveEditorBeforeCellChange(cell)) {
      return false;
    }
    if (!_postCurrentRowIfLeaving(liveRowIndex)) {
      return false;
    }

    _activateCell(
      cell,
      editIfPossible: false,
      focusReason: FdcGridFocusChangeReason.mouse,
    );

    // Custom cell widgets such as TextButton can take focus during their own
    // tap handling after the grid has already activated the target cell.
    // Re-assert grid focus after the frame for both accepted and rejected
    // writes: even a read-only custom cell action must leave the owning cell
    // current and keyboard navigation must continue from that cell.
    _focusGridForSelectedCellAfterLayout();

    if (targetColumnIndex >= 0 &&
        targetColumnIndex < _visibleColumns.length &&
        !_isCellEditable(_visibleColumns[targetColumnIndex], liveRowIndex)) {
      return false;
    }

    final oldDataSetValue = _dataSetFieldValueAt(liveRowIndex, fieldName);
    final targetColumn = _columnForFieldWrite(fieldName, targetColumnIndex);

    final change = _applyColumnValueChanging(
      targetColumn,
      rowIndex: liveRowIndex,
      columnIndex: targetColumnIndex,
      fieldName: fieldName,
      oldValue: oldDataSetValue,
      newValue: value,
    );
    switch (change) {
      case FdcGridColumnValueChangeCancelled():
        return false;

      case FdcGridColumnValueChangeAccepted(
        :final value,
        :final additionalValues,
      ):
        return _applyCellEditWrite(
          rowIndex: liveRowIndex,
          columnIndex: targetColumnIndex,
          fieldName: fieldName,
          column: targetColumn,
          oldValue: oldDataSetValue,
          value: value,
          additionalValues: additionalValues,
          ensureEdit: () => _ensureDataSetEditForField(
            liveRowIndex,
            fieldName,
            focusActiveEditorAfterDialog: true,
          ),
          emitValidation: (value) =>
              _emitDataSetFieldValidationByName(liveRowIndex, fieldName, value),
          markLayoutDirty: () {
            _columnWidthsDirty = true;
          },
        );
    }
  }

  bool _updateCell(int rowIndex, FdcGridColumn<dynamic> column, Object? value) {
    final oldDataSetValue = _dataSetValueAt(rowIndex, column);

    final columnIndex = _visibleColumns.indexOf(column);
    final change = _applyColumnValueChanging(
      column,
      rowIndex: rowIndex,
      columnIndex: columnIndex,
      fieldName: column.fieldName,
      oldValue: oldDataSetValue,
      newValue: value,
    );
    switch (change) {
      case FdcGridColumnValueChangeCancelled():
        return false;

      case FdcGridColumnValueChangeAccepted(
        :final value,
        :final additionalValues,
      ):
        return _applyCellEditWrite(
          rowIndex: rowIndex,
          columnIndex: columnIndex,
          fieldName: column.fieldName,
          column: column,
          oldValue: oldDataSetValue,
          value: value,
          additionalValues: additionalValues,
          ensureEdit: () => _ensureDataSetEditForCell(
            rowIndex,
            column,
            focusActiveEditorAfterDialog: true,
          ),
          emitValidation: (value) =>
              _emitDataSetFieldValidation(rowIndex, column, value),
          markLayoutDirty: () => _markColumnWidthsDirtyFor(column),
        );
    }
  }
}
