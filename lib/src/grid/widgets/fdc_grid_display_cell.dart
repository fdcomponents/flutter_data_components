// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../app/fdc_app.dart';
import '../../common/input/fdc_picker_button.dart';
import '../../data/fdc_dataset.dart' show FdcDataSetInternal;
import '../columns/fdc_grid_columns.dart';
import '../models/fdc_grid_internal_models.dart';
import 'fdc_grid_control_theme.dart';
import 'fdc_grid_display_cells.dart';

class FdcGridDisplayCell extends StatelessWidget {
  const FdcGridDisplayCell({
    super.key,
    required this.model,
    required this.callbacks,
  });

  final FdcGridCellModel model;
  final FdcGridCellCallbacks callbacks;
  @override
  Widget build(BuildContext context) {
    final column = model.column;
    final value = model.value;

    if (column.effectiveEditor == FdcEditorType.checkbox) {
      return Listener(
        onPointerDown: model.booleanCanToggle
            ? (event) => callbacks.onCellControlPointerDown(
                context,
                column,
                model.rowIndex,
                model.columnIndex,
                event.position,
              )
            : null,
        child: ExcludeFocus(
          child: Checkbox(
            value: value is bool
                ? value
                : (model.booleanAllowsNull ? null : false),
            tristate: model.booleanAllowsNull,
            fillColor: FdcGridControlTheme.checkboxFillColor(
              model.controlsStyle,
            ),
            checkColor: FdcGridControlTheme.checkboxCheckColor(
              context,
              model.controlsStyle,
              enabled: model.booleanCanToggle,
            ),
            side: FdcGridControlTheme.checkboxSide(
              context,
              model.controlsStyle,
              enabled: model.booleanCanToggle,
            ),
            onChanged: model.booleanCanToggle
                ? (value) => callbacks.onBooleanCellChanged(
                    column,
                    model.rowIndex,
                    model.columnIndex,
                    value,
                  )
                : null,
          ),
        ),
      );
    }

    if (column.effectiveEditor == FdcEditorType.switcher) {
      return Listener(
        onPointerDown: model.booleanCanToggle
            ? (event) => callbacks.onCellControlPointerDown(
                context,
                column,
                model.rowIndex,
                model.columnIndex,
                event.position,
              )
            : null,
        child: ExcludeFocus(
          child: Switch(
            value: value == true,
            thumbColor: FdcGridControlTheme.switchThumbColor(
              model.controlsStyle,
            ),
            trackColor: FdcGridControlTheme.switchTrackColor(
              model.controlsStyle,
            ),
            onChanged: model.booleanCanToggle
                ? (value) => callbacks.onBooleanCellChanged(
                    column,
                    model.rowIndex,
                    model.columnIndex,
                    value,
                  )
                : null,
          ),
        ),
      );
    }

    if (column.effectiveEditor == FdcEditorType.badge) {
      return FdcGridBadge(
        column: column,
        value: value,
        cellTextStyle: model.textStyle,
        alignment: model.alignment,
      );
    }

    if (column.effectiveEditor == FdcEditorType.progress) {
      return FdcGridProgress(
        column: column,
        value: value,
        cellTextStyle: model.textStyle,
        style: model.progressStyle,
      );
    }

    if (column is FdcActionColumn) {
      return column.buildCell(
        FdcRowActionContext(
          buildContext: context,
          dataSet: model.dataSet,
          row: model.row,
          rowIndex: model.rowIndex,
          sourceRowIndex: model.sourceRowIndex,
          recordId: model.recordId,
          columnIndex: model.columnIndex,
          dataSetReadOnly: FdcDataSetInternal.isReadOnly(model.dataSet),
          activateRow: () => callbacks.onActionActivateRow(
            model.rowIndex,
            model.recordId,
            model.columnIndex,
          ),
          deleteRow: () => callbacks.onActionDeleteRow(
            model.rowIndex,
            model.recordId,
            model.columnIndex,
          ),
          handleControlPointerDown: (event) =>
              callbacks.onCellControlPointerDown(
                context,
                column,
                model.rowIndex,
                model.columnIndex,
                event.position,
              ),
        ),
      );
    }

    if (column is FdcCustomColumn<dynamic>) {
      return column.buildCell(
        rowIndex: model.rowIndex,
        columnIndex: model.columnIndex,
        value: value,
        cell: FdcCellContext(
          buildContext: context,
          rowIndex: model.rowIndex,
          columnIndex: model.columnIndex,
          selected: model.selected,
          editing: model.editing,
          canEdit: model.canEdit,
          readOnly: model.readOnly,
          backgroundColor: model.backgroundColor,
          textStyle: model.textStyle,
          alignment: model.alignment,
          textAlign: model.textAlign,
          valueFormatter: (column, value, {runtimeColumnId}) => model
              .valueFormatter
              .format(column, value, runtimeColumnId: runtimeColumnId),
          onControlPointerDown: (globalPosition) =>
              callbacks.onCellControlPointerDown(
                context,
                column,
                model.rowIndex,
                model.columnIndex,
                globalPosition,
              ),
        ),
        fieldExists: model.row.containsField,
        fieldValueResolver: (fieldName) => callbacks.onCellFieldValue(
          model.rowIndex,
          model.recordId,
          fieldName,
        ),
        fieldValueFormatter: (fieldName, value) => model.valueFormatter
            .formatField(model.dataSet.fieldDef(fieldName), value),
        fieldValueWriter: (fieldName, value) =>
            callbacks.onCellFieldValueChanged(
              model.rowIndex,
              model.recordId,
              model.columnIndex,
              fieldName,
              value,
            ),
      );
    }

    final text = Text(
      model.valueFormatter.format(
        column,
        value,
        runtimeColumnId: model.runtimeColumnId,
      ),
      overflow: TextOverflow.ellipsis,
      textAlign: model.textAlign,
      style: model.textStyle,
    );

    final trailingWidget = _trailingWidget(context);
    if (trailingWidget == null) {
      return text;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite) {
          return Row(
            children: [
              Expanded(child: text),
              trailingWidget,
            ],
          );
        }

        // When the column is squeezed below the compact picker/combo
        // affordance width, keeping the trailing widget in the Row can
        // overflow even though the text itself can ellipsize. In that
        // extreme layout, prefer a clipped/ellipsized value over a render
        // overflow. The editor still exposes the picker when the cell is
        // activated and there is enough room to render it.
        const minTrailingLayoutWidth = 34.0;
        if (constraints.maxWidth < minTrailingLayoutWidth) {
          return text;
        }

        return Row(
          children: [
            Expanded(child: text),
            trailingWidget,
          ],
        );
      },
    );
  }

  String _lookupTooltip(BuildContext context) {
    final lookup = FdcApp.translationsOf(context).common.lookup;
    final shortcut = model.column.lookupShortcut;
    return shortcut == null ? lookup : '$lookup (${shortcut.displayLabel})';
  }

  Widget? _trailingWidget(BuildContext context) {
    if (model.showLookupButton) {
      return Listener(
        onPointerDown: model.canEdit
            ? (event) => callbacks.onCellControlPointerDown(
                context,
                model.column,
                model.rowIndex,
                model.columnIndex,
                event.position,
              )
            : null,
        child: SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            key: const ValueKey<String>('fdc-grid-lookup-button'),
            onPressed: () => callbacks.onLookup(
              context,
              model.column,
              model.rowIndex,
              model.columnIndex,
              null,
              FdcLookupMode.search,
            ),
            icon: Icon(model.column.lookupIcon),
            iconSize: 18,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            splashRadius: 16,
            tooltip: _lookupTooltip(context),
          ),
        ),
      );
    }

    if (model.showPickerButton) {
      return Listener(
        onPointerDown: model.canEdit
            ? (event) => callbacks.onCellControlPointerDown(
                context,
                model.column,
                model.rowIndex,
                model.columnIndex,
                event.position,
              )
            : null,
        child: FdcPickerButton(
          onPressed: () => callbacks.onPickCellValue(
            context,
            model.column,
            model.rowIndex,
            model.columnIndex,
          ),
          compact: true,
          iconColor: FdcGridControlTheme.iconColor(
            context,
            model.controlsStyle,
          ),
        ),
      );
    }

    if (model.showComboButton) {
      final color = FdcGridControlTheme.iconColor(context, model.controlsStyle);
      return SizedBox(
        width: 32,
        height: 32,
        child: Icon(Icons.arrow_drop_down, size: 22, color: color),
      );
    }

    return null;
  }
}
