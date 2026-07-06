// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart'
    show ValueChanged, ValueListenable, VoidCallback;
import 'package:flutter/material.dart';

import '../../common/menu/fdc_menu_entry.dart';
import '../../common/theme/fdc_grid_styles.dart';
import '../../common/widgets/counter/fdc_counter_style.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';
import '../../data/fdc_data.dart';
import '../columns/fdc_grid_columns.dart';
import '../core/fdc_grid_core.dart';
import '../format/fdc_value_formatter.dart';
import 'fdc_column_identity.dart';
import 'fdc_grid_cell_ref.dart';
import 'fdc_grid_layout_models.dart';
import 'fdc_grid_row_context.dart';

enum FdcGridFocusState { none, cell, editor, headerFilter }

class FdcGridInteractionState {
  const FdcGridInteractionState({
    this.selectedCell,
    this.editingCell,
    this.pendingEditCell,
    this.editAtEndCell,
    this.selectedRowIndex,
    this.currentRowIndex,
    this.focusState = FdcGridFocusState.none,
  });

  final FdcGridCellRef? selectedCell;
  final FdcGridCellRef? editingCell;
  final FdcGridCellRef? pendingEditCell;
  final FdcGridCellRef? editAtEndCell;
  final int? selectedRowIndex;
  final int? currentRowIndex;
  final FdcGridFocusState focusState;

  bool get cellFocusVisible {
    return focusState == FdcGridFocusState.cell ||
        focusState == FdcGridFocusState.editor;
  }

  bool isSelected(
    int rowIndex,
    int columnIndex, {
    int? recordId,
    FdcColumnIdentity? runtimeColumnId,
  }) {
    return cellFocusVisible &&
        selectedCell?.matchesCell(
              rowIndex,
              columnIndex,
              recordId: recordId,
              runtimeColumnId: runtimeColumnId,
            ) ==
            true;
  }

  bool isEditing(
    int rowIndex,
    int columnIndex, {
    int? recordId,
    FdcColumnIdentity? runtimeColumnId,
  }) {
    return editingCell?.matchesCell(
          rowIndex,
          columnIndex,
          recordId: recordId,
          runtimeColumnId: runtimeColumnId,
        ) ==
        true;
  }

  bool isPendingEdit(
    int rowIndex,
    int columnIndex, {
    int? recordId,
    FdcColumnIdentity? runtimeColumnId,
  }) {
    return pendingEditCell?.matchesCell(
          rowIndex,
          columnIndex,
          recordId: recordId,
          runtimeColumnId: runtimeColumnId,
        ) ==
        true;
  }

  bool isEditAtEnd(
    int rowIndex,
    int columnIndex, {
    int? recordId,
    FdcColumnIdentity? runtimeColumnId,
  }) {
    return editAtEndCell?.matchesCell(
          rowIndex,
          columnIndex,
          recordId: recordId,
          runtimeColumnId: runtimeColumnId,
        ) ==
        true;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridInteractionState &&
            selectedCell == other.selectedCell &&
            editingCell == other.editingCell &&
            pendingEditCell == other.pendingEditCell &&
            editAtEndCell == other.editAtEndCell &&
            selectedRowIndex == other.selectedRowIndex &&
            currentRowIndex == other.currentRowIndex &&
            focusState == other.focusState;
  }

  @override
  int get hashCode => Object.hash(
    selectedCell,
    editingCell,
    pendingEditCell,
    editAtEndCell,
    selectedRowIndex,
    currentRowIndex,
    focusState,
  );
}

class FdcGridRowIndicatorCellModel {
  const FdcGridRowIndicatorCellModel({
    required this.rowIndex,
    required this.rowNumber,
    required this.options,
    required this.selected,
    required this.selectionEnabled,
    required this.recordId,
    required this.status,
    required this.textStyle,
    required this.controlsStyle,
  });

  final int rowIndex;
  final int rowNumber;
  final FdcGridRowIndicatorOptions options;
  final bool selected;
  final bool selectionEnabled;
  final int? recordId;

  /// Null means this row has no active record indicator status.
  ///
  /// The enum only models actual current-row lifecycle states. A non-current
  /// row intentionally has no status instead of a synthetic `none` value.
  final FdcGridRowIndicatorStatus? status;
  final TextStyle? textStyle;
  final FdcGridControlsStyle controlsStyle;

  FdcGridRowIndicatorCellModel copyWith({FdcGridRowIndicatorStatus? status}) {
    return FdcGridRowIndicatorCellModel(
      rowIndex: rowIndex,
      rowNumber: rowNumber,
      options: options,
      selected: selected,
      selectionEnabled: selectionEnabled,
      recordId: recordId,
      status: status ?? this.status,
      textStyle: textStyle,
      controlsStyle: controlsStyle,
    );
  }

  FdcGridRowIndicatorCellModel withoutStatus() {
    return FdcGridRowIndicatorCellModel(
      rowIndex: rowIndex,
      rowNumber: rowNumber,
      options: options,
      selected: selected,
      selectionEnabled: selectionEnabled,
      recordId: recordId,
      status: null,
      textStyle: textStyle,
      controlsStyle: controlsStyle,
    );
  }
}

class FdcGridColumnCellRenderInfo {
  const FdcGridColumnCellRenderInfo({
    required this.dataType,
    required this.alignment,
    required this.textAlign,
    required this.counterMaxLength,
    required this.editorMaxLength,
    required this.editorDecimalScale,
    required this.editorDecimalPrecision,
    required this.metadataReadOnly,
    required this.usesDisplayCellInEdit,
  });

  final FdcDataType dataType;
  final Alignment alignment;
  final TextAlign textAlign;
  final int? counterMaxLength;
  final int? editorMaxLength;
  final int? editorDecimalScale;
  final int? editorDecimalPrecision;
  final bool metadataReadOnly;
  final bool usesDisplayCellInEdit;
}

class FdcGridColumnCellTextStyles {
  const FdcGridColumnCellTextStyles({required this.textStyle});

  final TextStyle? textStyle;
}

class FdcGridCellModel {
  const FdcGridCellModel({
    required this.column,
    required this.rowIndex,
    required this.columnIndex,
    required this.sourceRowIndex,
    required this.dataSet,
    required this.row,
    required this.recordId,
    required this.runtimeColumnId,
    required this.value,
    required this.width,
    required this.alignment,
    required this.backgroundColor,
    required this.selectedBackgroundColor,
    required this.indicatorMode,
    required this.indicatorStyle,
    required this.selectedIndicatorStyle,
    required this.editingIndicatorStyle,
    required this.errorIndicatorMessage,
    required this.errorIndicatorStyle,
    required this.counterText,
    required this.counterStyle,
    required this.editorCounterMaxLength,
    required this.editorMaxLength,
    required this.editorDecimalScale,
    required this.editorDecimalPrecision,
    required this.effectiveDataType,
    required this.selected,
    required this.rangeTop,
    required this.rangeRight,
    required this.rangeBottom,
    required this.rangeLeft,
    required this.editing,
    required this.canEdit,
    required this.readOnly,
    required this.usesDisplayCellInEdit,
    required this.editorKey,
    required this.selectAllOnFocus,
    required this.placeCursorAtEndOnFocus,
    required this.editorInitialText,
    required this.editorOriginalValue,
    required this.editorOriginalText,
    required this.updateInitialText,
    required this.textStyle,
    required this.textAlign,
    required this.controlsStyle,
    required this.progressStyle,
    required this.booleanCanToggle,
    required this.booleanAllowsNull,
    required this.suppressCellControls,
    required this.showPickerButton,
    required this.showLookupButton,
    required this.showComboButton,
    required this.pickerButtonAvailable,
    required this.comboButtonAvailable,
    required this.valueFormatter,
    required this.interactionState,
    this.contextMenuEntriesBuilder,
  });

  final FdcGridColumn<dynamic> column;
  final int rowIndex;
  final int columnIndex;
  final int? sourceRowIndex;
  final FdcDataSet dataSet;
  final FdcGridRowContext row;
  final int? recordId;
  final FdcColumnIdentity? runtimeColumnId;
  final Object? value;

  final double width;
  final Alignment alignment;

  /// Inactive cell background. Selection-specific visuals are applied from
  /// [selectedBackgroundColor] inside the interaction listener so record-scroll
  /// selection can move without rebuilding the whole grid shell.
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final FdcGridCellIndicatorMode? indicatorMode;
  final FdcGridResolvedCellIndicatorStyle? indicatorStyle;
  final FdcGridResolvedCellIndicatorStyle? selectedIndicatorStyle;
  final FdcGridResolvedCellIndicatorStyle? editingIndicatorStyle;
  final String? errorIndicatorMessage;
  final FdcErrorIndicatorMarkerStyle? errorIndicatorStyle;

  final String? counterText;
  final FdcCounterStyle counterStyle;
  final int? editorCounterMaxLength;
  final int? editorMaxLength;
  final int? editorDecimalScale;
  final int? editorDecimalPrecision;
  final FdcDataType effectiveDataType;

  final bool selected;

  final bool rangeTop;
  final bool rangeRight;
  final bool rangeBottom;
  final bool rangeLeft;
  final bool editing;
  final bool canEdit;
  final bool readOnly;
  final bool usesDisplayCellInEdit;

  final Key editorKey;
  final bool selectAllOnFocus;
  final bool placeCursorAtEndOnFocus;
  final String? editorInitialText;
  final Object? editorOriginalValue;
  final String? editorOriginalText;
  final bool updateInitialText;

  final TextStyle? textStyle;
  final TextAlign textAlign;
  final FdcGridControlsStyle controlsStyle;
  final FdcGridProgressStyle progressStyle;

  final bool booleanCanToggle;
  final bool booleanAllowsNull;

  /// Suppresses transient focused-cell controls while a range selection is
  /// active or visible. Picker, lookup and combo affordances must not overlap
  /// the range overlay or intercept range gestures.
  final bool suppressCellControls;

  final bool showPickerButton;
  final bool showLookupButton;
  final bool showComboButton;
  final bool pickerButtonAvailable;
  final bool comboButtonAvailable;

  final FdcValueFormatter valueFormatter;
  final ValueListenable<FdcGridInteractionState> interactionState;
  final List<FdcMenuEntry> Function()? contextMenuEntriesBuilder;

  FdcGridCellModel withInteractionVisuals({
    required bool selected,
    required bool editing,
    required Color? backgroundColor,
    required FdcGridResolvedCellIndicatorStyle? indicatorStyle,
    required bool showPickerButton,
    required bool showLookupButton,
    required bool showComboButton,
  }) {
    if (this.selected == selected &&
        this.editing == editing &&
        this.backgroundColor == backgroundColor &&
        this.indicatorStyle == indicatorStyle &&
        this.showPickerButton == showPickerButton &&
        this.showLookupButton == showLookupButton &&
        this.showComboButton == showComboButton) {
      return this;
    }

    return FdcGridCellModel(
      column: column,
      rowIndex: rowIndex,
      columnIndex: columnIndex,
      sourceRowIndex: sourceRowIndex,
      dataSet: dataSet,
      row: row,
      recordId: recordId,
      runtimeColumnId: runtimeColumnId,
      value: value,
      width: width,
      alignment: alignment,
      backgroundColor: backgroundColor,
      selectedBackgroundColor: selectedBackgroundColor,
      indicatorMode: indicatorMode,
      indicatorStyle: indicatorStyle,
      selectedIndicatorStyle: selectedIndicatorStyle,
      editingIndicatorStyle: editingIndicatorStyle,
      errorIndicatorMessage: errorIndicatorMessage,
      errorIndicatorStyle: errorIndicatorStyle,
      counterText: counterText,
      counterStyle: counterStyle,
      editorCounterMaxLength: editorCounterMaxLength,
      editorMaxLength: editorMaxLength,
      editorDecimalScale: editorDecimalScale,
      editorDecimalPrecision: editorDecimalPrecision,
      effectiveDataType: effectiveDataType,
      selected: selected,
      rangeTop: rangeTop,
      rangeRight: rangeRight,
      rangeBottom: rangeBottom,
      rangeLeft: rangeLeft,
      editing: editing,
      canEdit: canEdit,
      readOnly: readOnly,
      usesDisplayCellInEdit: usesDisplayCellInEdit,
      editorKey: editorKey,
      selectAllOnFocus: selectAllOnFocus,
      placeCursorAtEndOnFocus: placeCursorAtEndOnFocus,
      editorInitialText: editorInitialText,
      editorOriginalValue: editorOriginalValue,
      editorOriginalText: editorOriginalText,
      updateInitialText: updateInitialText,
      textStyle: textStyle,
      textAlign: textAlign,
      controlsStyle: controlsStyle,
      progressStyle: progressStyle,
      booleanCanToggle: booleanCanToggle,
      booleanAllowsNull: booleanAllowsNull,
      suppressCellControls: suppressCellControls,
      showPickerButton: showPickerButton,
      showLookupButton: showLookupButton,
      showComboButton: showComboButton,
      pickerButtonAvailable: pickerButtonAvailable,
      comboButtonAvailable: comboButtonAvailable,
      valueFormatter: valueFormatter,
      interactionState: interactionState,
      contextMenuEntriesBuilder: contextMenuEntriesBuilder,
    );
  }
}

class FdcGridCellCallbacks {
  const FdcGridCellCallbacks({
    required this.onCellPointerTap,
    required this.onCellValueChanged,
    required this.onLookup,
    required this.onCellFieldValue,
    required this.onCellFieldValueChanged,
    required this.onMoveNext,
    required this.onMovePrevious,
    required this.onMoveNextTab,
    required this.onMovePreviousTab,
    required this.onMoveDown,
    required this.onMoveUp,
    required this.onMovePageDown,
    required this.onMovePageUp,
    required this.onBeginKeyboardMoveScrollGuard,
    required this.onCancelEditing,
    required this.onCellControlPointerDown,
    required this.onBooleanCellChanged,
    required this.onPickCellValue,
    required this.onRowIndicatorSelected,
    required this.onActionActivateRow,
    required this.onActionDeleteRow,
  });

  final void Function(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
    Offset globalPosition,
  )
  onCellPointerTap;

  final bool Function(
    FdcGridColumn<dynamic> column,
    int rowIndex,
    Object? value,
  )
  onCellValueChanged;

  final Future<bool> Function(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
    String? editorText,
    FdcLookupMode mode,
  )
  onLookup;

  final Object? Function(int rowIndex, int? recordId, String fieldName)
  onCellFieldValue;

  final bool Function(
    int rowIndex,
    int? recordId,
    int columnIndex,
    String fieldName,
    Object? value,
  )
  onCellFieldValueChanged;

  final VoidCallback onMoveNext;
  final VoidCallback onMovePrevious;
  final VoidCallback onMoveNextTab;
  final VoidCallback onMovePreviousTab;
  final VoidCallback onMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMovePageDown;
  final VoidCallback onMovePageUp;
  final VoidCallback Function() onBeginKeyboardMoveScrollGuard;
  final ValueChanged<Object?> onCancelEditing;

  final void Function(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
    Offset globalPosition,
  )
  onCellControlPointerDown;

  final void Function(
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
    bool? value,
  )
  onBooleanCellChanged;

  final void Function(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
  )
  onPickCellValue;

  final void Function(int rowIndex, bool selected) onRowIndicatorSelected;

  final bool Function(int rowIndex, int? recordId, int columnIndex)
  onActionActivateRow;

  final bool Function(int rowIndex, int? recordId, int columnIndex)
  onActionDeleteRow;
}
