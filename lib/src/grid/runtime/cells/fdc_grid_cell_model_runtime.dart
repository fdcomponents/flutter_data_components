// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridCellModelRuntime on _FdcGridState {
  String? _cellValidationErrorMessage(
    FdcGridColumn<dynamic> column,
    int? recordId,
  ) {
    if (!column.isDataBound || recordId == null) {
      return null;
    }
    return FdcDataSetInternal.errorMessageForField(
      widget.dataSet,
      column.fieldName,
      recordId: recordId,
    );
  }

  FdcGridCellModel _buildCellModel(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
    double columnWidth,
    FdcValueFormatter valueFormatter,
  ) {
    final cell = _cellRef(rowIndex, columnIndex);
    final cellFocusVisible = _cellFocusVisible;
    final selected = cellFocusVisible && _selectedCell?.matches(cell) == true;
    final rangeMode = _rangeSelectionModifierActive;
    final suppressRangeCellControls = rangeMode || _hasExplicitCellRange;
    final suppressCellIndicator = suppressRangeCellControls;
    final editing = _editingCell?.matches(cell) == true;
    final canEdit = _isCellEditable(column, rowIndex);
    final pendingEdit =
        _pendingEditText != null && _pendingEditCell?.matches(cell) == true;
    final editAtEnd = _editAtEndCell?.matches(cell) == true;
    final value = _dataSetValueAt(rowIndex, column);
    final runtimeColumnId = cell.runtimeColumnId;
    final renderInfo = _columnCellRenderInfo(column, runtimeColumnId);
    final cellTextStyles = _cellTextStyles(
      context,
      column,
      runtimeColumnId: runtimeColumnId,
    );
    return FdcGridCellModel(
      column: column,
      rowIndex: rowIndex,
      columnIndex: columnIndex,
      sourceRowIndex: _sourceRowIndex(rowIndex),
      dataSet: widget.dataSet,
      row: _rows[rowIndex],
      recordId: cell.recordId,
      runtimeColumnId: cell.runtimeColumnId,
      value: value,
      width: columnWidth,
      alignment: renderInfo.alignment,
      backgroundColor: _cellBackgroundColor(column, selected: false),
      selectedBackgroundColor: _cellBackgroundColor(column, selected: true),
      indicatorMode:
          !suppressCellIndicator &&
              column.showIndicator &&
              widget.cellIndicator.visible
          ? widget.cellIndicator.mode
          : null,
      indicatorStyle: !suppressCellIndicator && column.showIndicator
          ? _cellIndicatorStyle(
              selected: false,
              editing: false,
              canEdit: canEdit,
            )
          : null,
      selectedIndicatorStyle: !suppressCellIndicator && column.showIndicator
          ? _cellIndicatorStyle(
              selected: true,
              editing: false,
              canEdit: canEdit,
            )
          : null,
      editingIndicatorStyle: !suppressCellIndicator && column.showIndicator
          ? _cellIndicatorStyle(selected: true, editing: true, canEdit: canEdit)
          : null,
      errorIndicatorMessage:
          !suppressCellIndicator &&
              column.showIndicator &&
              widget.cellIndicator.errorIndicator.showsMarker
          ? _cellValidationErrorMessage(column, cell.recordId)
          : null,
      errorIndicatorStyle:
          !suppressCellIndicator &&
              column.showIndicator &&
              widget.cellIndicator.errorIndicator.showsMarker
          ? _styles.cellErrorIndicatorStyle(
              theme: _gridTheme,
              indicator: widget.cellIndicator,
            )
          : null,
      counterText: _cellCounterText(value, renderInfo.counterMaxLength),
      counterStyle: _styles.counterStyle(
        context,
        column.counterStyle,
        theme: _gridTheme,
      ),
      editorCounterMaxLength: renderInfo.counterMaxLength,
      editorMaxLength: renderInfo.editorMaxLength,
      editorDecimalScale: renderInfo.editorDecimalScale,
      editorDecimalPrecision: renderInfo.editorDecimalPrecision,
      effectiveDataType: renderInfo.dataType,
      selected: selected,
      rangeTop: false,
      rangeRight: false,
      rangeBottom: false,
      rangeLeft: false,
      editing: editing,
      canEdit: canEdit,
      readOnly: column.isEffectivelyReadOnly || renderInfo.metadataReadOnly,
      usesDisplayCellInEdit: renderInfo.usesDisplayCellInEdit,
      editorKey: _runtime.domains.editing.editorKeys.keyForCell(cell),
      selectAllOnFocus: !pendingEdit && !editAtEnd,
      placeCursorAtEndOnFocus: pendingEdit || editAtEnd,
      editorInitialText: _cellEditorInitialText(
        context,
        column,
        value,
        rowIndex,
        columnIndex,
      ),
      editorOriginalValue: _cellEditorOriginalValue(
        rowIndex,
        columnIndex,
        value,
      ),
      editorOriginalText: _cellEditorOriginalText(
        context,
        column,
        rowIndex,
        columnIndex,
        valueFormatter,
        value,
      ),
      updateInitialText: pendingEdit,
      textStyle: cellTextStyles.textStyle,
      textAlign: renderInfo.textAlign,
      controlsStyle: _controlsStyle(context),
      progressStyle: _styles.progressStyle(
        context,
        column.progressStyle,
        theme: _gridTheme,
      ),
      booleanCanToggle:
          !suppressRangeCellControls &&
          _shouldToggleBooleanCell(column, rowIndex),
      booleanAllowsNull: _booleanCellAllowsNull(column),
      suppressCellControls: suppressRangeCellControls,
      // Date/time picker controls become visible when the cell is active.
      // showPicker controls whether the focused cell exposes the picker.
      showPickerButton:
          !suppressRangeCellControls &&
          _cellFocusVisible &&
          selected &&
          canEdit &&
          _pickerButtonAvailable(column),
      showLookupButton:
          !suppressRangeCellControls &&
          _cellFocusVisible &&
          selected &&
          canEdit &&
          column.lookupSignatureToken != null,
      showComboButton:
          !suppressRangeCellControls &&
          _showsDisplayComboButton(
            column,
            selected: selected,
            canEdit: canEdit,
          ),
      pickerButtonAvailable: _pickerButtonAvailable(column),
      comboButtonAvailable: _comboButtonAvailable(column),
      valueFormatter: valueFormatter,
      interactionState: _interactionState,
      contextMenuEntriesBuilder:
          !suppressRangeCellControls &&
              (column.menuBuilder != null || widget.menuBuilder != null)
          ? () => _contextMenuEntries(context, column, rowIndex, columnIndex)
          : null,
    );
  }

  bool _pickerButtonAvailable(FdcGridColumn<dynamic> column) {
    return column.showPicker &&
        (column.effectiveEditor == FdcEditorType.date ||
            column.effectiveEditor == FdcEditorType.dateTime ||
            column.effectiveEditor == FdcEditorType.time);
  }

  bool _comboButtonAvailable(FdcGridColumn<dynamic> column) {
    return _isDropdownEditor(column);
  }

  bool _showsDisplayComboButton(
    FdcGridColumn<dynamic> column, {
    required bool selected,
    required bool canEdit,
  }) {
    return _cellFocusVisible &&
        selected &&
        canEdit &&
        _comboButtonAvailable(column);
  }

  FdcGridColumnCellRenderInfo _columnCellRenderInfo(
    FdcGridColumn<dynamic> column,
    FdcColumnIdentity? runtimeColumnId,
  ) {
    if (runtimeColumnId == null) {
      return _createColumnCellRenderInfo(column);
    }

    return _columnCellRenderInfoCache.putIfAbsent(
      runtimeColumnId,
      () => _createColumnCellRenderInfo(column),
    );
  }

  FdcGridColumnCellRenderInfo _createColumnCellRenderInfo(
    FdcGridColumn<dynamic> column,
  ) {
    final metadata = column.isDataBound
        ? _fieldMetadata(column.fieldName)
        : const FdcGridFieldMetadata.missing();
    final dataType = metadata.dataType ?? column.dataType;
    final alignment = _columnCellAlignment(column, dataType);
    final textAlign = _columnTextAlign(column, dataType);
    final counterMaxLength = column.showCounter ? metadata.stringSize : null;
    final editorMaxLength = dataType == FdcDataType.string
        ? metadata.stringSize
        : dataType == FdcDataType.guid
        ? 36
        : null;

    return FdcGridColumnCellRenderInfo(
      dataType: dataType,
      alignment: alignment,
      textAlign: textAlign,
      counterMaxLength: counterMaxLength,
      editorMaxLength: editorMaxLength,
      editorDecimalScale: metadata.decimalScale,
      editorDecimalPrecision: metadata.decimalPrecision,
      metadataReadOnly:
          metadata.isReadOnlyForEditing || dataType == FdcDataType.guid,
      usesDisplayCellInEdit: _usesDisplayCellInEdit(column),
    );
  }

  bool _usesDisplayCellInEdit(FdcGridColumn<dynamic> column) {
    return switch (column.effectiveEditor) {
      FdcEditorType.checkbox ||
      FdcEditorType.switcher ||
      FdcEditorType.badge ||
      FdcEditorType.progress ||
      FdcEditorType.custom ||
      FdcEditorType.action => true,
      _ => false,
    };
  }

  Alignment _columnCellAlignment(
    FdcGridColumn<dynamic> column,
    FdcDataType dataType,
  ) {
    final styleAlignment = column.cellStyle?.alignment;
    if (styleAlignment != null) {
      return styleAlignment;
    }
    return _alignmentForHorizontal(
      column.horizontalAlignment ?? _defaultHorizontalAlignment(dataType),
    );
  }

  TextAlign _columnTextAlign(
    FdcGridColumn<dynamic> column,
    FdcDataType dataType,
  ) {
    final styleAlignment = column.cellStyle?.alignment;
    if (styleAlignment != null) {
      return _textAlignForAlignment(styleAlignment);
    }
    return _textAlignForHorizontal(
      column.horizontalAlignment ?? _defaultHorizontalAlignment(dataType),
    );
  }

  FdcGridHorizontalAlignment _defaultHorizontalAlignment(FdcDataType dataType) {
    return dataType == FdcDataType.decimal
        ? FdcGridHorizontalAlignment.end
        : FdcGridHorizontalAlignment.start;
  }

  Alignment _alignmentForHorizontal(FdcGridHorizontalAlignment alignment) {
    return switch (alignment) {
      FdcGridHorizontalAlignment.start =>
        _textDirection == TextDirection.ltr
            ? Alignment.centerLeft
            : Alignment.centerRight,
      FdcGridHorizontalAlignment.center => Alignment.center,
      FdcGridHorizontalAlignment.end =>
        _textDirection == TextDirection.ltr
            ? Alignment.centerRight
            : Alignment.centerLeft,
    };
  }

  TextAlign _textAlignForHorizontal(FdcGridHorizontalAlignment alignment) {
    return switch (alignment) {
      FdcGridHorizontalAlignment.start => TextAlign.start,
      FdcGridHorizontalAlignment.center => TextAlign.center,
      FdcGridHorizontalAlignment.end => TextAlign.end,
    };
  }

  TextAlign _textAlignForAlignment(Alignment alignment) {
    if (alignment.x > 0) {
      return TextAlign.right;
    }
    if (alignment.x == 0) {
      return TextAlign.center;
    }
    return TextAlign.left;
  }

  String? _cellCounterText(Object? value, int? size) {
    if (size == null) {
      return null;
    }

    final text = value?.toString() ?? '';
    return '${text.length}/$size';
  }

  FdcGridResolvedCellIndicatorStyle? _cellIndicatorStyle({
    required bool selected,
    required bool editing,
    required bool canEdit,
  }) {
    return _styles.cellIndicatorStyle(
      theme: _gridTheme,
      indicator: widget.cellIndicator,
      selected: selected,
      editing: editing,
      canEdit: canEdit,
    );
  }

  Color? _cellBackgroundColor(
    FdcGridColumn<dynamic> column, {
    required bool selected,
  }) {
    final key = FdcGridCellBackgroundKey(column: column, selected: selected);
    if (_cellBackgroundColorCache.containsKey(key)) {
      return _cellBackgroundColorCache[key];
    }

    final color = _styles.cellBackgroundColor(
      column: column,
      selected: selected,
      style: _gridStyle,
    );
    _cellBackgroundColorCache[key] = color;
    return color;
  }

  FdcGridColumnCellTextStyles _cellTextStyles(
    BuildContext context,
    FdcGridColumn<dynamic> column, {
    required FdcColumnIdentity? runtimeColumnId,
  }) {
    if (runtimeColumnId == null) {
      return _resolveCellTextStyles(context, column);
    }

    return _cellTextStyleCache.putIfAbsent(
      runtimeColumnId,
      () => _resolveCellTextStyles(context, column),
    );
  }

  FdcGridColumnCellTextStyles _resolveCellTextStyles(
    BuildContext context,
    FdcGridColumn<dynamic> column,
  ) {
    final textStyle = _styles.effectiveCellTextStyle(
      context,
      style: _gridStyle,
      column: column,
    );

    return FdcGridColumnCellTextStyles(textStyle: textStyle);
  }

  List<FdcMenuEntry> _contextMenuEntries(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
  ) {
    final builder = column.menuBuilder ?? widget.menuBuilder;
    if (builder == null || rowIndex < 0 || rowIndex >= _rows.length) {
      return const <FdcMenuEntry>[];
    }
    final cell = _cellRef(rowIndex, columnIndex);
    final sourceRowIndex = _sourceRowIndex(rowIndex);
    final canInsertRecord = _canInsertRecordFromMenu(rowIndex, cell.recordId);
    final canAppendRecord = _canAppendRecordFromMenu();
    final canCancelEdit = _canCancelEditFromMenu();
    return builder(
      FdcGridMenuContext(
        buildContext: context,
        dataSet: widget.dataSet,
        row: _rows[rowIndex],
        rowIndex: rowIndex,
        sourceRowIndex: sourceRowIndex,
        recordId: cell.recordId,
        column: column,
        columnIndex: columnIndex,
        value: _dataSetValueAt(rowIndex, column),
        isEditing: _editingCell?.matches(cell) == true,
        isCellSelected: _selectedCell?.matches(cell) == true,
        isRowSelected: _isRowIndicatorSelected(rowIndex),
        canInsertRecord: canInsertRecord,
        canAppendRecord: canAppendRecord,
        canCancelEdit: canCancelEdit,
        insertRecord: canInsertRecord
            ? () => _insertRecordFromMenu(rowIndex, cell.recordId, columnIndex)
            : null,
        appendRecord: canAppendRecord ? _appendRecordFromMenu : null,
        cancelEdit: canCancelEdit ? _cancelEditFromMenu : null,
      ),
    );
  }
}
