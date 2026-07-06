// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../data/bindings/fdc_bindings.dart';
import '../../data/fdc_data.dart';
import '../models/fdc_column_identity.dart';
import 'fdc_column_base.dart';

/// Builds a custom grid cell for a field-bound [FdcCustomColumn].
typedef FdcCustomCellBuilder<T> =
    Widget Function(FdcFieldContext<T> field, FdcCellContext cell);

/// Formats an arbitrary grid cell value for display text.
///
/// The grid calls this formatter from custom-cell rendering paths. The optional
/// runtime column identity distinguishes repeated/runtime column instances when
/// layout state requires it. Keep the formatter side-effect free.
typedef FdcCellValueFormatter =
    String Function(
      FdcGridColumn<dynamic> column,
      Object? value, {
      FdcColumnIdentity? runtimeColumnId,
    });

/// Formats a field value by dataset field name.
///
/// Custom cells use this callback when they need the grid's normal field-aware
/// display formatting without rendering a standard cell. Keep it side-effect
/// free because formatting may occur repeatedly during rebuilds.
typedef FdcFieldValueFormatter =
    String Function(String fieldName, Object? value);

/// Runtime cell context passed to [FdcCustomColumn.cellBuilder].
///
/// This context contains visual/layout/interaction state for the grid cell.
/// Keep value access and writes on [FdcFieldContext]; keep styling, alignment,
/// selection, editability and Flutter cell context here.
class FdcCellContext {
  /// Creates a [FdcCellContext].
  const FdcCellContext({
    required this.buildContext,
    required this.rowIndex,
    required this.columnIndex,
    required this.selected,
    required this.editing,
    required this.canEdit,
    required this.readOnly,
    required this.alignment,
    required this.textAlign,
    required FdcCellValueFormatter valueFormatter,
    this.backgroundColor,
    this.textStyle,
    this.onControlPointerDown,
  }) : _valueFormatter = valueFormatter;

  final FdcCellValueFormatter _valueFormatter;

  /// Flutter build context for the cell.
  final BuildContext buildContext;

  /// Visual row index in the current grid view.
  final int rowIndex;

  /// Visual column index in the current grid view.
  final int columnIndex;

  /// Whether this cell is selected in the grid.
  final bool selected;

  /// Whether this cell is currently in the grid editing state.
  final bool editing;

  /// Whether the grid/dataset currently allow editing this cell.
  final bool canEdit;

  /// Whether this cell should be treated as read-only by custom UI.
  final bool readOnly;

  /// Resolved cell background color, including read-only/disabled/selected
  /// state when the active grid style defines one.
  final Color? backgroundColor;

  /// Resolved text style for the cell, including grid-level and column-level
  /// text style overrides.
  final TextStyle? textStyle;

  /// Resolved alignment used by built-in display cells.
  final Alignment alignment;

  /// Resolved text alignment used by built-in display cells.
  final TextAlign textAlign;

  /// Internal hook used by custom in-cell mouse controls to preserve the grid
  /// viewport while activating/writing the owning cell.
  ///
  /// Application code should usually call [control] instead of this callback.
  final void Function(Offset globalPosition)? onControlPointerDown;

  /// Convenience accessor for `textStyle.color`.
  Color? get foregroundColor => textStyle?.color;

  /// Formats [value] exactly as the grid would format it for [column].
  String formatValue(
    FdcGridColumn<dynamic> column,
    Object? value, {
    FdcColumnIdentity? runtimeColumnId,
  }) {
    return _valueFormatter(column, value, runtimeColumnId: runtimeColumnId);
  }

  /// Marks a pointer-down event as belonging to an interactive control inside
  /// the custom cell.
  ///
  /// Use this when building custom controls manually. This lets the grid select
  /// and update the owning row/cell without running the generic cell tap path
  /// or
  /// moving the horizontal/vertical viewport.
  void handleControlPointerDown(PointerDownEvent event) {
    onControlPointerDown?.call(event.position);
  }

  /// Wraps a custom in-cell control so mouse/touch interaction keeps the grid
  /// viewport stable while [FdcFieldContext.setValue] or
  /// [FdcFieldContext.setValueOf] writes through the grid pipeline.
  ///
  /// This is recommended for custom buttons, checkboxes, switches, picker
  /// buttons, and similar controls embedded inside [FdcCustomColumn] cells.
  Widget control(Widget child, {bool enabled = true}) {
    return Listener(
      onPointerDown: enabled ? handleControlPointerDown : null,
      child: child,
    );
  }
}

/// Runtime field context passed to [FdcCustomColumn.cellBuilder].
///
/// The context is intentionally field-bound: [value] and [setValue] operate on
/// the column's own [FdcCustomColumn.fieldName], while [valueOf],
/// [tryValueOf], and [setValueOf] allow a custom widget to inspect or update
/// other fields on the same row. Writes are routed through the grid/dataset
/// edit pipeline, so
/// validators, edit buffers, lifecycle events and field-change notifications
/// keep the same behavior as built-in columns.
class FdcFieldContext<T> {
  /// Creates a [FdcFieldContext].
  const FdcFieldContext({
    required this.column,
    required this.rowIndex,
    required this.columnIndex,
    required this.value,
    required bool Function(String fieldName) fieldExists,
    required Object? Function(String fieldName) fieldValueResolver,
    required bool Function(String fieldName, Object? value) fieldValueWriter,
    required FdcFieldValueFormatter fieldValueFormatter,
  }) : _fieldExists = fieldExists,
       _fieldValueResolver = fieldValueResolver,
       _fieldValueWriter = fieldValueWriter,
       _fieldValueFormatter = fieldValueFormatter;

  /// Custom column that owns this cell.
  final FdcCustomColumn<T> column;

  /// Visual row index in the current grid view.
  final int rowIndex;

  /// Visual column index in the current grid view.
  final int columnIndex;

  /// Current field value for `column.fieldName`.
  final T? value;

  /// Internal value reader supplied by the owning grid.
  final bool Function(String fieldName) _fieldExists;

  /// Internal value writer supplied by the owning grid.
  final Object? Function(String fieldName) _fieldValueResolver;

  /// Internal edit-state callback supplied by the owning grid.
  final bool Function(String fieldName, Object? value) _fieldValueWriter;
  final FdcFieldValueFormatter _fieldValueFormatter;

  /// Reads another field value from the same visual row.
  ///
  /// This is a strict typed accessor: it casts the resolved value to [V?] and
  /// throws a [TypeError] when the value is not assignable to [V]. Use
  /// [tryValueOf] when a type mismatch should be treated as a missing value.
  V? valueOf<V>(String fieldName) {
    _requireField(fieldName, 'FdcFieldContext.valueOf');
    return _fieldValueResolver(fieldName) as V?;
  }

  /// Reads another field value from the same visual row when it is assignable
  /// to [V].
  ///
  /// Returns `null` when the field value is `null` or when the runtime value is
  /// not assignable to [V]. This is useful for optional custom-cell lookups
  /// where mismatched data should not throw during build.
  V? tryValueOf<V>(String fieldName) {
    if (!_fieldExists(fieldName)) {
      return null;
    }
    final value = _fieldValueResolver(fieldName);
    if (value == null || value is V) {
      return value as V?;
    }
    return null;
  }

  /// Formats this column's current value using the grid formatter.
  String formatValue([T? value]) {
    return formatValueOf(column.fieldName, value ?? this.value);
  }

  /// Formats another field value from the same row using its dataset schema.
  ///
  /// When [value] is omitted, the current row value is resolved first.
  String formatValueOf(String fieldName, [Object? value]) {
    _requireField(fieldName, 'FdcFieldContext.formatValueOf');
    return _fieldValueFormatter(
      fieldName,
      value ?? _fieldValueResolver(fieldName),
    );
  }

  /// Writes this column's field value through the normal grid/dataset pipeline.
  bool setValue(T? value) => setValueOf<T>(column.fieldName, value);

  /// Writes another field value on the same visual row through the normal
  /// grid/dataset pipeline.
  ///
  /// The write request is always routed to the grid first, even when the
  /// current cell is read-only. The grid still needs to activate/focus the
  /// owning cell deterministically; it then rejects the value change if the
  /// target field is not editable.
  bool setValueOf<V>(String fieldName, V? value) {
    _requireField(fieldName, 'FdcFieldContext.setValueOf');
    return _fieldValueWriter(fieldName, value);
  }

  void _requireField(String fieldName, String accessor) {
    if (!_fieldExists(fieldName)) {
      throw ArgumentError.value(
        fieldName,
        'fieldName',
        '$accessor field does not exist in the row.',
      );
    }
  }
}

/// Field-bound custom column.
///
/// [FdcCustomColumn] stores and serializes the underlying dataset field value,
/// but lets application code fully customize the cell widget. Search, filters,
/// sorting and export continue to operate on [fieldName]'s dataset value.
class FdcCustomColumn<T> extends FdcGridColumn<T> {
  /// Creates a field-bound custom column.
  const FdcCustomColumn({
    required super.fieldName,
    required this.cellBuilder,
    this.allowedFieldTypes,
    super.id,
    super.groupId,
    super.label,
    super.hint,
    super.visible = true,
    super.exportable = true,
    super.enabled = true,
    super.readOnly = false,
    super.focusOrder,
    super.tabStop = true,
    super.width,
    super.minWidth = 0,
    super.maxWidth = 0,
    super.autoSizeMode = FdcGridColumnAutoSizeMode.none,
    super.allowSort = true,
    super.filterConfig,
    super.allowResize = true,
    super.horizontalAlignment,
    super.showIndicator = true,
    super.onValueChanging,
    super.onValueChanged,
    super.cellStyle,
    super.pin = FdcGridColumnPin.none,
    super.summary = const FdcColumnSummary(),
    super.menuBuilder,
  }) : super();

  /// Builds the custom cell widget for the current row.
  final FdcCustomCellBuilder<T> cellBuilder;

  /// Optional dataset field definition types accepted by this custom column.
  ///
  /// When omitted, any [FdcFieldDef] subtype is accepted. Specialized custom
  /// columns can use this to enforce strict schema binding without depending on
  /// package-internal binding APIs.
  final List<Type>? allowedFieldTypes;

  @override
  Object? get customCellBuilderSignatureToken => cellBuilder;

  /// Builds a cell context using this column's concrete generic value type.
  Widget buildCell({
    required int rowIndex,
    required int columnIndex,
    required Object? value,
    required FdcCellContext cell,
    required bool Function(String fieldName) fieldExists,
    required Object? Function(String fieldName) fieldValueResolver,
    required bool Function(String fieldName, Object? value) fieldValueWriter,
    required FdcFieldValueFormatter fieldValueFormatter,
  }) {
    return cellBuilder(
      FdcFieldContext<T>(
        column: this,
        rowIndex: rowIndex,
        columnIndex: columnIndex,
        value: value as T?,
        fieldExists: fieldExists,
        fieldValueResolver: fieldValueResolver,
        fieldValueWriter: fieldValueWriter,
        fieldValueFormatter: fieldValueFormatter,
      ),
      cell,
    );
  }

  @override
  FdcDataType get dataType => FdcDataType.object;

  @override
  FdcEditorType get effectiveEditor => FdcEditorType.custom;

  /// Validates any additional dataset fields used by a specialized custom
  /// column after the primary [fieldName] binding has been resolved.
  ///
  /// Most custom columns use only their primary field and do not need to
  /// override this hook. Multi-field columns can override it without
  /// depending on package-internal binding types.
  @protected
  void validateAdditionalBindings(FdcDataSet dataSet) {}

  @override
  void validateBinding(FdcDataSet dataSet) {
    final allowedTypes = allowedFieldTypes;
    if (allowedTypes == null || allowedTypes.isEmpty) {
      FdcFieldBindingResolver.resolve<FdcFieldDef>(
        dataSet,
        fieldName,
        ownerName: runtimeType.toString(),
      );
    } else {
      FdcFieldBindingResolver.resolveAnyOf(
        dataSet,
        fieldName,
        allowedFieldTypes: allowedTypes,
        ownerName: runtimeType.toString(),
      );
    }
    validateAdditionalBindings(dataSet);
  }
}
