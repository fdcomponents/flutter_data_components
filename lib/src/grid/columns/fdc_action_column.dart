// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../app/fdc_app.dart';
import '../../data/fdc_data.dart';
import '../models/fdc_grid_row_context.dart';
import 'fdc_column_base.dart';

/// Callback used by [FdcRowAction] to execute row-level commands.
typedef FdcRowActionCallback = void Function(FdcRowActionContext context);

/// Predicate used by [FdcRowAction] to resolve row-level state.
typedef FdcRowActionPredicate = bool Function(FdcRowActionContext context);

/// Context passed to row actions rendered by [FdcActionColumn].
class FdcRowActionContext {
  /// Creates a [FdcRowActionContext].
  const FdcRowActionContext({
    required this.buildContext,
    required this.dataSet,
    required this.row,
    required this.rowIndex,
    required this.sourceRowIndex,
    required this.recordId,
    required this.columnIndex,
    required this.dataSetReadOnly,
    required bool Function() activateRow,
    required bool Function() deleteRow,
    required void Function(PointerDownEvent event) handleControlPointerDown,
  }) : _activateRow = activateRow,
       _deleteRow = deleteRow,
       _handleControlPointerDown = handleControlPointerDown;

  /// Flutter build context for the action cell.
  final BuildContext buildContext;

  /// Dataset displayed by the owning grid.
  final FdcDataSet dataSet;

  /// Read-only row value accessor for the current row.
  final FdcGridRowContext row;

  /// Visual row index in the current grid view.
  final int rowIndex;

  /// Source dataset row index for [rowIndex], when available.
  final int? sourceRowIndex;

  /// Stable dataset record id for the current row, when available.
  final int? recordId;

  /// Visual column index of the action column.
  final int columnIndex;

  /// Whether the owning dataset is currently read-only.
  final bool dataSetReadOnly;

  /// Internal row-activation callback provided by the owning grid.
  final bool Function() _activateRow;

  /// Internal delete callback provided by the owning grid.
  final bool Function() _deleteRow;

  /// Internal pointer-routing callback provided by the owning grid.
  final void Function(PointerDownEvent event) _handleControlPointerDown;

  /// Reads another field value from the same row.
  V? valueOf<V>(String fieldName) => row.valueOf(fieldName) as V?;

  /// Reads another field value when it is assignable to [V].
  V? tryValueOf<V>(String fieldName) {
    if (!row.containsField(fieldName)) {
      return null;
    }
    final value = row.valueOf(fieldName);
    if (value == null || value is V) {
      return value as V?;
    }
    return null;
  }

  /// Activates this action's row in the grid/dataset.
  bool activateRow() => _activateRow();

  /// Deletes this action's row through the owning grid/dataset pipeline.
  bool deleteRow() => _deleteRow();

  /// Marks a pointer down as belonging to an in-cell action control.
  void handleControlPointerDown(PointerDownEvent event) {
    _handleControlPointerDown(event);
  }
}

/// A standardized row-level action rendered by [FdcActionColumn].
class FdcRowAction {
  /// Creates a [FdcRowAction].
  const FdcRowAction({
    required this.icon,
    this.tooltip,
    this.onPressed,
    this.enabled,
    this.visible,
    this.activateRowOnPressed = true,
    this.color,
    this.disabledColor,
  }) : _deleteAction = false;

  /// Creates a built-in delete action.
  const FdcRowAction.delete({
    this.tooltip = deleteTooltip,
    this.enabled,
    this.visible,
    this.activateRowOnPressed = false,
    this.color = const Color(0xFFD32F2F),
    this.disabledColor,
  }) : icon = Icons.delete_outline,
       onPressed = null,
       _deleteAction = true;

  /// Default tooltip for the built-in delete row action.
  static const deleteTooltip = 'Delete';

  /// Icon displayed for this action.
  final IconData icon;

  /// Optional tooltip displayed for the action button.
  final String? tooltip;

  /// Custom command executed when this action is pressed.
  ///
  /// Built-in actions leave this null and use their predefined behavior.
  final FdcRowActionCallback? onPressed;

  /// Optional per-row enabled predicate.
  final FdcRowActionPredicate? enabled;

  /// Optional per-row visibility predicate.
  final FdcRowActionPredicate? visible;

  /// Whether a custom action should activate its row before [onPressed].
  final bool activateRowOnPressed;

  /// Optional icon color override.
  ///
  /// The built-in delete action uses a destructive red color by default.
  /// Pass another color, including colors from the application theme, to
  /// override action-level styling.
  final Color? color;

  /// Optional disabled icon color override.
  final Color? disabledColor;

  final bool _deleteAction;

  /// Resolves whether this action is visible for [context].
  bool isVisible(FdcRowActionContext context) => visible?.call(context) ?? true;

  /// Resolves whether this action is enabled for [context].
  bool isEnabled(FdcRowActionContext context) {
    if (_deleteAction && context.dataSetReadOnly) {
      return false;
    }
    return enabled?.call(context) ?? true;
  }

  /// Executes this action for [context] when it is enabled.
  void invoke(FdcRowActionContext context) {
    if (!isEnabled(context)) {
      return;
    }

    if (_deleteAction) {
      context.deleteRow();
      return;
    }

    if (activateRowOnPressed && !context.activateRow()) {
      return;
    }
    onPressed?.call(context);
  }
}

/// Grid column that renders standardized row-level actions.
///
/// This is a UI-only column: it is not bound to a dataset field and does not
/// participate in sorting, filtering, search, summaries, editing or export.
class FdcActionColumn extends FdcGridColumn<void> {
  /// Creates a [FdcActionColumn].
  const FdcActionColumn({
    required this.actions,
    super.id,
    super.groupId,
    super.label,
    super.hint,
    super.visible = true,
    super.enabled = true,
    super.focusOrder,
    super.tabStop = false,
    super.width = 40,
    super.minWidth = 32,
    super.maxWidth = 0,
    super.autoSizeMode = FdcGridColumnAutoSizeMode.none,
    super.horizontalAlignment = FdcGridHorizontalAlignment.center,
    super.cellStyle,
    super.pin = FdcGridColumnPin.none,
    super.menuBuilder,
    this.iconSize = 18,
    this.spacing = 0,
    this.padding = EdgeInsets.zero,
  }) : super(
         fieldName: id ?? '__fdc_action_column',
         exportable: false,
         readOnly: true,
         allowSort: false,
         filterConfig: const FdcColumnFilterConfig(enabled: false),
         allowResize: false,
         showIndicator: false,
         summary: const FdcColumnSummary(),
       );

  /// Actions rendered for each grid row.
  final List<FdcRowAction> actions;

  /// Icon size used by action buttons.
  final double iconSize;

  /// Horizontal spacing between action buttons.
  final double spacing;

  /// Padding around the action row.
  final EdgeInsetsGeometry padding;

  @override
  bool get isDataBound => false;

  @override
  bool get isInherentlyReadOnly => true;

  @override
  FdcDataType get dataType => FdcDataType.object;

  @override
  FdcEditorType get effectiveEditor => FdcEditorType.action;

  @override
  void validateBinding(FdcDataSet dataSet) {
    throw StateError('FdcActionColumn is not bound to a dataset field.');
  }

  /// Builds this action column's cell content.
  Widget buildCell(FdcRowActionContext context) {
    final visibleActions = [
      for (final action in actions)
        if (action.isVisible(context)) action,
    ];
    if (visibleActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < visibleActions.length; i++) ...[
              _ActionButton(
                action: visibleActions[i],
                context: context,
                iconSize: iconSize,
              ),
              if (spacing > 0 && i < visibleActions.length - 1)
                SizedBox(width: spacing),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.action,
    required this.context,
    required this.iconSize,
  });

  final FdcRowAction action;
  final FdcRowActionContext context;
  final double iconSize;

  @override
  Widget build(BuildContext buildContext) {
    final enabled = action.isEnabled(context);
    final tooltip =
        action._deleteAction && action.tooltip == FdcRowAction.deleteTooltip
        ? FdcApp.translationsOf(buildContext).common.delete
        : action.tooltip;
    return Listener(
      onPointerDown: enabled ? context.handleControlPointerDown : null,
      child: IconButton(
        icon: Icon(action.icon),
        tooltip: tooltip,
        color: action.color,
        disabledColor: action.disabledColor,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        visualDensity: VisualDensity.compact,
        iconSize: iconSize,
        onPressed: enabled ? () => action.invoke(context) : null,
      ),
    );
  }
}
