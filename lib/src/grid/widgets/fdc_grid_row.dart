// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart'
    show ValueChanged, ValueListenable, VoidCallback;
import 'package:flutter/material.dart';

import '../../app/fdc_app.dart';
import '../../common/menu/fdc_menu_renderer.dart';
import '../../common/theme/fdc_grid_theme.dart';
import '../columns/fdc_grid_columns.dart';
import '../core/fdc_grid_runtime_constants.dart';
import '../editors/fdc_grid_cell_editor.dart';
import '../models/fdc_grid_internal_models.dart';
import 'fdc_grid_cell_frame.dart';
import 'fdc_grid_display_cell.dart';
import 'fdc_grid_row_indicator_cell.dart';

class FdcGridRowWidget extends StatelessWidget {
  const FdcGridRowWidget({
    super.key,
    required this.columnLayout,
    required this.rowIndex,
    required this.rowHeight,
    required this.animateColumnReorder,
    required this.interactionState,
    required this.selectedRowBackgroundColor,
    required this.cellModelBuilder,
    required this.callbacks,
    this.detailExpanderColumnId,
    this.canExpandDetail = false,
    this.detailExpanded = false,
    this.onToggleDetail,
  });

  final FdcGridColumnBandLayout columnLayout;
  final int rowIndex;
  final double rowHeight;
  final bool animateColumnReorder;
  final ValueListenable<FdcGridInteractionState> interactionState;
  final Color? selectedRowBackgroundColor;
  final FdcGridCellModel Function(
    BuildContext context,
    FdcGridColumn<dynamic> column,
    int rowIndex,
    int columnIndex,
    double columnWidth,
  )
  cellModelBuilder;
  final FdcGridCellCallbacks callbacks;
  final FdcColumnIdentity? detailExpanderColumnId;
  final bool canExpandDetail;
  final bool detailExpanded;
  final VoidCallback? onToggleDetail;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _FdcGridRowSelectionLayer(
        rowIndex: rowIndex,
        interactionState: interactionState,
        selectedRowBackgroundColor: selectedRowBackgroundColor,
        child: SizedBox(
          width: columnLayout.width,
          height: rowHeight,
          child: Stack(
            children: [
              for (
                var localColumnIndex = 0;
                localColumnIndex < columnLayout.geometries.length;
                localColumnIndex++
              )
                AnimatedPositioned(
                  key: ValueKey<Object?>(
                    'fdc-grid-row-$rowIndex-cell-${columnLayout.geometries[localColumnIndex].runtimeColumnId}',
                  ),
                  duration: animateColumnReorder
                      ? fdcGridColumnReorderAnimationDuration
                      : Duration.zero,
                  curve: Curves.easeOutCubic,
                  left: columnLayout.geometries[localColumnIndex].offset,
                  top: 0,
                  width: columnLayout.geometries[localColumnIndex].width,
                  height: rowHeight,
                  child: _FdcGridRowCellSlot(
                    showExpander:
                        canExpandDetail &&
                        columnLayout
                                .geometries[localColumnIndex]
                                .runtimeColumnId ==
                            detailExpanderColumnId,
                    expanded: detailExpanded,
                    onToggle: onToggleDetail,
                    child: FdcGridCell(
                      model: cellModelBuilder(
                        context,
                        columnLayout.geometries[localColumnIndex].column,
                        rowIndex,
                        columnLayout
                            .geometries[localColumnIndex]
                            .sourceColumnIndex,
                        columnLayout.geometries[localColumnIndex].width,
                      ),
                      callbacks: callbacks,
                      contentLeadingInset:
                          columnLayout
                                  .geometries[localColumnIndex]
                                  .runtimeColumnId ==
                              detailExpanderColumnId
                          ? 24
                          : 0,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FdcGridRowCellSlot extends StatelessWidget {
  const _FdcGridRowCellSlot({
    required this.showExpander,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final bool showExpander;
  final bool expanded;
  final VoidCallback? onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!showExpander) {
      return child;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          left: 2,
          top: 0,
          bottom: 0,
          width: 24,
          child: Center(
            child: _FdcGridDetailExpanderButton(
              expanded: expanded,
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}

class _FdcGridDetailExpanderButton extends StatefulWidget {
  const _FdcGridDetailExpanderButton({
    required this.expanded,
    required this.onPressed,
  });

  final bool expanded;
  final VoidCallback? onPressed;

  @override
  State<_FdcGridDetailExpanderButton> createState() =>
      _FdcGridDetailExpanderButtonState();
}

class _FdcGridDetailExpanderButtonState
    extends State<_FdcGridDetailExpanderButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final popupStyle = FdcGridTheme.resolveData(
      context,
      null,
    ).popupMenu.resolve();
    final background = _pressed
        ? popupStyle.pressedColor
        : _hovered
        ? popupStyle.hoverColor
        : Colors.transparent;

    return MouseRegion(
      cursor: widget.onPressed == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onPressed == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: widget.onPressed == null
            ? null
            : () => setState(() => _pressed = false),
        onTapUp: widget.onPressed == null
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              },
        child: Container(
          key: const ValueKey<String>('fdc-grid-detail-expander'),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(2),
          ),
          alignment: Alignment.center,
          child: AnimatedRotation(
            turns: widget.expanded ? 0.25 : 0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Icon(
              Icons.keyboard_arrow_right,
              size: 19,
              color: popupStyle.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _FdcGridRowSelectionLayer extends StatefulWidget {
  const _FdcGridRowSelectionLayer({
    required this.rowIndex,
    required this.interactionState,
    required this.selectedRowBackgroundColor,
    required this.child,
  });

  final int rowIndex;
  final ValueListenable<FdcGridInteractionState> interactionState;
  final Color? selectedRowBackgroundColor;
  final Widget child;

  @override
  State<_FdcGridRowSelectionLayer> createState() =>
      _FdcGridRowSelectionLayerState();
}

class _FdcGridRowSelectionLayerState extends State<_FdcGridRowSelectionLayer> {
  late bool _selected;
  bool _interactionDirty = false;

  @override
  void initState() {
    super.initState();
    _selected = _isSelected(widget.interactionState.value);
    widget.interactionState.addListener(_handleInteractionChanged);
  }

  @override
  void didUpdateWidget(covariant _FdcGridRowSelectionLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interactionState != widget.interactionState) {
      oldWidget.interactionState.removeListener(_handleInteractionChanged);
      widget.interactionState.addListener(_handleInteractionChanged);
    }
    _selected = _isSelected(widget.interactionState.value);
  }

  @override
  void dispose() {
    widget.interactionState.removeListener(_handleInteractionChanged);
    super.dispose();
  }

  bool _isSelected(FdcGridInteractionState interaction) {
    return interaction.selectedRowIndex == widget.rowIndex;
  }

  void _handleInteractionChanged() {
    if (!mounted) {
      return;
    }
    final nextSelected = _isSelected(widget.interactionState.value);
    if (nextSelected == _selected) {
      return;
    }

    _interactionDirty = true;
    setState(() {
      _selected = nextSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_interactionDirty) {
      _interactionDirty = false;
    }
    final color = _selected
        ? widget.selectedRowBackgroundColor
        : Colors.transparent;
    return ColoredBox(color: color ?? Colors.transparent, child: widget.child);
  }
}

class FdcGridCell extends StatefulWidget {
  const FdcGridCell({
    super.key,
    required this.model,
    required this.callbacks,
    this.contentLeadingInset = 0,
  });

  final FdcGridCellModel model;
  final FdcGridCellCallbacks callbacks;
  final double contentLeadingInset;

  @override
  State<FdcGridCell> createState() => _FdcGridCellState();
}

class _FdcGridCellState extends State<FdcGridCell> {
  late _CellInteractionSnapshot _interaction;
  bool _interactionDirty = false;

  @override
  void initState() {
    super.initState();
    _interaction = _snapshotFor(widget.model.interactionState.value);
    widget.model.interactionState.addListener(_handleInteractionChanged);
  }

  @override
  void didUpdateWidget(covariant FdcGridCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.interactionState != widget.model.interactionState) {
      oldWidget.model.interactionState.removeListener(
        _handleInteractionChanged,
      );
      widget.model.interactionState.addListener(_handleInteractionChanged);
    }
    _interaction = _snapshotFor(widget.model.interactionState.value);
  }

  @override
  void dispose() {
    widget.model.interactionState.removeListener(_handleInteractionChanged);
    super.dispose();
  }

  _CellInteractionSnapshot _snapshotFor(FdcGridInteractionState interaction) {
    final model = widget.model;
    return _CellInteractionSnapshot(
      selected: interaction.isSelected(
        model.rowIndex,
        model.columnIndex,
        recordId: model.recordId,
        runtimeColumnId: model.runtimeColumnId,
      ),
      editing: interaction.isEditing(
        model.rowIndex,
        model.columnIndex,
        recordId: model.recordId,
        runtimeColumnId: model.runtimeColumnId,
      ),
      pendingEdit: interaction.isPendingEdit(
        model.rowIndex,
        model.columnIndex,
        recordId: model.recordId,
        runtimeColumnId: model.runtimeColumnId,
      ),
      editAtEnd: interaction.isEditAtEnd(
        model.rowIndex,
        model.columnIndex,
        recordId: model.recordId,
        runtimeColumnId: model.runtimeColumnId,
      ),
    );
  }

  void _handleInteractionChanged() {
    if (!mounted) {
      return;
    }
    final next = _snapshotFor(widget.model.interactionState.value);
    if (next == _interaction) {
      return;
    }

    _interactionDirty = true;
    setState(() {
      _interaction = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_interactionDirty) {
      _interactionDirty = false;
    }

    final model = widget.model;
    final selected = _interaction.selected;
    final editing = _interaction.editing;
    final editorOwnsCounter =
        editing &&
        !model.usesDisplayCellInEdit &&
        model.editorCounterMaxLength != null;
    final counterText = editorOwnsCounter
        ? null
        : selected || editing
        ? model.counterText
        : null;
    final backgroundColor = selected
        ? model.selectedBackgroundColor
        : model.backgroundColor;
    final indicatorStyle = editing
        ? model.editingIndicatorStyle
        : selected
        ? model.selectedIndicatorStyle
        : model.indicatorStyle;
    final interactionModel = model.withInteractionVisuals(
      selected: selected,
      editing: editing,
      backgroundColor: backgroundColor,
      indicatorStyle: indicatorStyle,
      showPickerButton:
          !model.suppressCellControls &&
          selected &&
          model.canEdit &&
          model.pickerButtonAvailable,
      showLookupButton:
          !model.suppressCellControls &&
          selected &&
          model.canEdit &&
          model.column.lookupSignatureToken != null,
      showComboButton:
          !model.suppressCellControls &&
          selected &&
          model.canEdit &&
          model.comboButtonAvailable,
    );

    final editingCell = FdcGridCellEditor(
      key: interactionModel.editorKey,
      column: interactionModel.column,
      runtimeColumnId: interactionModel.runtimeColumnId,
      value: interactionModel.value,
      enabled: interactionModel.canEdit,
      readOnly: interactionModel.readOnly,
      selectAllOnFocus: _interaction.pendingEdit
          ? false
          : interactionModel.selectAllOnFocus,
      placeCursorAtEndOnFocus:
          _interaction.editAtEnd || interactionModel.placeCursorAtEndOnFocus,
      initialText: interactionModel.editorInitialText,
      originalValue: interactionModel.editorOriginalValue,
      originalText: interactionModel.editorOriginalText,
      updateInitialText: interactionModel.updateInitialText,
      counterMaxLength: interactionModel.editorCounterMaxLength,
      editorMaxLength: interactionModel.editorMaxLength,
      decimalScale: interactionModel.editorDecimalScale,
      decimalPrecision: interactionModel.editorDecimalPrecision,
      dataType: interactionModel.effectiveDataType,
      counterStyle: interactionModel.counterStyle,
      textStyle: interactionModel.textStyle,
      controlsStyle: interactionModel.controlsStyle,
      onChanged: (value) => widget.callbacks.onCellValueChanged(
        interactionModel.column,
        interactionModel.rowIndex,
        value,
      ),
      onLookup: interactionModel.column.lookupSignatureToken == null
          ? null
          : (editorText, mode) => widget.callbacks.onLookup(
              context,
              interactionModel.column,
              interactionModel.rowIndex,
              interactionModel.columnIndex,
              editorText,
              mode,
            ),
      lookupCommittedText: () => _lookupCommittedText(interactionModel),
      onMoveNext: widget.callbacks.onMoveNext,
      onMovePrevious: widget.callbacks.onMovePrevious,
      onMoveNextTab: widget.callbacks.onMoveNextTab,
      onMovePreviousTab: widget.callbacks.onMovePreviousTab,
      onMoveDown: widget.callbacks.onMoveDown,
      onMoveUp: widget.callbacks.onMoveUp,
      onMovePageDown: widget.callbacks.onMovePageDown,
      onMovePageUp: widget.callbacks.onMovePageUp,
      onBeginKeyboardMoveScrollGuard:
          widget.callbacks.onBeginKeyboardMoveScrollGuard,
      onCancelEditing: widget.callbacks.onCancelEditing,
    );

    final cellContent = editing && !interactionModel.usesDisplayCellInEdit
        ? _withLookupButton(
            context,
            interactionModel,
            editingCell,
            editing: true,
          )
        : FdcGridDisplayCell(
            model: interactionModel,
            callbacks: widget.callbacks,
          );

    final frame = FdcGridCellFrame(
      width: interactionModel.width,
      alignment: interactionModel.alignment,
      contentLeadingInset: widget.contentLeadingInset,
      color: interactionModel.backgroundColor,
      indicatorMode: interactionModel.indicatorMode,
      indicatorStyle: interactionModel.indicatorStyle,
      errorIndicatorMessage: interactionModel.errorIndicatorMessage,
      errorIndicatorStyle: interactionModel.errorIndicatorStyle,
      counterText: counterText,
      counterStyle: interactionModel.counterStyle,
      child: cellContent,
    );

    if (editing && !interactionModel.usesDisplayCellInEdit) {
      return frame;
    }

    // Boolean display controls handle value changes from their own hit target,
    // but the rest of the cell must still behave like an ordinary grid cell:
    // a pointer down on the cell background selects/activates the row. The
    // control pointer snapshot captured by FdcGridDisplayCell prevents the
    // outer cell tap from interfering with checkbox/switch toggles.
    final cell = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => widget.callbacks.onCellPointerTap(
        context,
        interactionModel.column,
        interactionModel.rowIndex,
        interactionModel.columnIndex,
        details.globalPosition,
      ),
      child: frame,
    );

    final entriesBuilder = interactionModel.contextMenuEntriesBuilder;
    if (entriesBuilder == null) {
      return cell;
    }
    return FdcMenuAnchor(entriesBuilder: entriesBuilder, child: cell);
  }

  String _lookupCommittedText(FdcGridCellModel model) {
    final value = widget.callbacks.onCellFieldValue(
      model.rowIndex,
      model.recordId,
      model.column.fieldName,
    );
    if (value == null) {
      return '';
    }
    return model.valueFormatter.format(model.column, value);
  }

  String _lookupTooltip(BuildContext context, FdcGridCellModel model) {
    final lookup = FdcApp.translationsOf(context).common.lookup;
    final shortcut = model.column.lookupShortcut;
    return shortcut == null ? lookup : '$lookup (${shortcut.displayLabel})';
  }

  Widget _withLookupButton(
    BuildContext context,
    FdcGridCellModel model,
    Widget child, {
    required bool editing,
  }) {
    if (!model.showLookupButton) {
      return child;
    }
    return Row(
      children: [
        Expanded(child: child),
        Builder(
          builder: (context) {
            String? editorTextOnPointerDown;
            return Listener(
              onPointerDown: (event) {
                final key = model.editorKey;
                if (editing && key is GlobalKey<FdcGridCellEditorState>) {
                  final editorState = key.currentState;
                  editorTextOnPointerDown = editorState?.lookupEditorText;
                  editorState?.beginExternalLookupSearch();
                }
                widget.callbacks.onCellControlPointerDown(
                  context,
                  model.column,
                  model.rowIndex,
                  model.columnIndex,
                  event.position,
                );
              },
              child: SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  key: const ValueKey<String>('fdc-grid-lookup-button'),
                  onPressed: () async {
                    String? editorText;
                    FdcGridCellEditorState? editorState;
                    final key = model.editorKey;
                    if (editing && key is GlobalKey<FdcGridCellEditorState>) {
                      editorState = key.currentState;
                      editorText = editorState?.lookupEditorText;
                      editorState?.beginExternalLookupSearch();
                    }
                    editorText ??= editorTextOnPointerDown;
                    final accepted = await widget.callbacks.onLookup(
                      context,
                      model.column,
                      model.rowIndex,
                      model.columnIndex,
                      editorText,
                      FdcLookupMode.search,
                    );
                    editorState?.endExternalLookupSearch(
                      accepted: accepted,
                      acceptedText: accepted
                          ? _lookupCommittedText(model)
                          : null,
                    );
                  },
                  icon: Icon(model.column.lookupIcon),
                  iconSize: 18,
                  constraints: const BoxConstraints.tightFor(
                    width: 32,
                    height: 32,
                  ),
                  padding: EdgeInsets.zero,
                  splashRadius: 16,
                  tooltip: _lookupTooltip(context, model),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CellInteractionSnapshot {
  const _CellInteractionSnapshot({
    required this.selected,
    required this.editing,
    required this.pendingEdit,
    required this.editAtEnd,
  });

  final bool selected;
  final bool editing;
  final bool pendingEdit;
  final bool editAtEnd;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _CellInteractionSnapshot &&
            selected == other.selected &&
            editing == other.editing &&
            pendingEdit == other.pendingEdit &&
            editAtEnd == other.editAtEnd;
  }

  @override
  int get hashCode => Object.hash(selected, editing, pendingEdit, editAtEnd);
}

class FdcGridRowIndicatorRow extends StatefulWidget {
  const FdcGridRowIndicatorRow({
    super.key,
    required this.width,
    required this.rowHeight,
    required this.model,
    required this.interactionState,
    required this.selectedRowBackgroundColor,
    required this.onTap,
    required this.onSelectedChanged,
  });

  final double width;
  final double rowHeight;
  final FdcGridRowIndicatorCellModel model;
  final ValueListenable<FdcGridInteractionState> interactionState;
  final Color? selectedRowBackgroundColor;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelectedChanged;

  @override
  State<FdcGridRowIndicatorRow> createState() => _FdcGridRowIndicatorRowState();
}

class _FdcGridRowIndicatorRowState extends State<FdcGridRowIndicatorRow> {
  late _RowIndicatorInteractionSnapshot _interaction;
  bool _interactionDirty = false;

  @override
  void initState() {
    super.initState();
    _interaction = _snapshotFor(widget.interactionState.value);
    widget.interactionState.addListener(_handleInteractionChanged);
  }

  @override
  void didUpdateWidget(covariant FdcGridRowIndicatorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interactionState != widget.interactionState) {
      oldWidget.interactionState.removeListener(_handleInteractionChanged);
      widget.interactionState.addListener(_handleInteractionChanged);
    }
    _interaction = _snapshotFor(widget.interactionState.value);
  }

  @override
  void dispose() {
    widget.interactionState.removeListener(_handleInteractionChanged);
    super.dispose();
  }

  _RowIndicatorInteractionSnapshot _snapshotFor(
    FdcGridInteractionState interaction,
  ) {
    return _RowIndicatorInteractionSnapshot(
      selected: interaction.selectedRowIndex == widget.model.rowIndex,
      current: interaction.currentRowIndex == widget.model.rowIndex,
      editing: interaction.editingCell?.rowIndex == widget.model.rowIndex,
    );
  }

  void _handleInteractionChanged() {
    if (!mounted) {
      return;
    }
    final next = _snapshotFor(widget.interactionState.value);
    if (next == _interaction) {
      return;
    }

    _interactionDirty = true;
    setState(() {
      _interaction = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_interactionDirty) {
      _interactionDirty = false;
    }
    final selectedColor = _interaction.selected
        ? widget.selectedRowBackgroundColor
        : Colors.transparent;

    return RepaintBoundary(
      child: SizedBox(
        height: widget.rowHeight,
        child: ColoredBox(
          color: selectedColor ?? Colors.transparent,
          child: FdcGridCellFrame(
            width: widget.width,
            alignment: Alignment.center,
            contentHorizontalInset: 0.0,
            child: FdcGridRowIndicatorCell(
              model: _modelForInteraction(),
              onTap: widget.onTap,
              onSelectedChanged: widget.onSelectedChanged,
            ),
          ),
        ),
      ),
    );
  }

  FdcGridRowIndicatorCellModel _modelForInteraction() {
    final model = widget.model;
    final status = model.status;

    // `model.status` is derived from the dataset current record, not from the
    // grid cell-focus state. Keep that current-record marker visible when focus
    // moves elsewhere, but still hide stale status from recycled row widgets.
    if (_interaction.current) {
      if (_interaction.editing &&
          status != FdcGridRowIndicatorStatus.insert &&
          status != FdcGridRowIndicatorStatus.modified) {
        return model.copyWith(status: FdcGridRowIndicatorStatus.edit);
      }
      return status == null
          ? model.copyWith(status: FdcGridRowIndicatorStatus.browse)
          : model;
    }

    if (_interaction.selected) {
      return status == null
          ? model.copyWith(status: FdcGridRowIndicatorStatus.browse)
          : model;
    }

    return status == null ? model : model.withoutStatus();
  }
}

class _RowIndicatorInteractionSnapshot {
  const _RowIndicatorInteractionSnapshot({
    required this.selected,
    required this.current,
    required this.editing,
  });

  final bool selected;
  final bool current;
  final bool editing;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _RowIndicatorInteractionSnapshot &&
            selected == other.selected &&
            current == other.current &&
            editing == other.editing;
  }

  @override
  int get hashCode => Object.hash(selected, current, editing);
}
