// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart' show internal, listEquals;
import 'package:flutter/material.dart';

import '../../common/events/fdc_field_events.dart';
import '../../common/fdc_aggregate.dart';
import '../../common/fdc_option.dart';
import '../../common/input/fdc_keyboard_shortcut.dart';
import '../../common/lookup/fdc_lookup_context.dart';
import '../../common/lookup/fdc_lookup_result.dart';
import '../../common/menu/fdc_menu_entry.dart';
import '../../data/fdc_data.dart';
import '../models/fdc_grid_row_context.dart';

/// Supported visual editor modes.
enum FdcEditorType {
  /// Text option.
  text,

  /// Integer option.
  integer,

  /// Decimal option.
  decimal,

  /// Checkbox option.
  checkbox,

  /// Switcher option.
  switcher,

  /// Date option.
  date,

  /// Date time option.
  dateTime,

  /// Time option.
  time,

  /// Memo option.
  memo,

  /// Combo option.
  combo,

  /// Badge option.
  badge,

  /// Progress option.
  progress,

  /// Custom option.
  custom,

  /// Action option.
  action,
}

/// Built-in header filter editor modes.
///
/// `search` and `combo` are the currently polished modes. `list` and
/// `checkbox` are intentionally available as lightweight configurable modes
/// so the header filter layer can evolve without changing the public config
/// shape again.
enum FdcFilterEditor {
  /// Free text search input.
  search,

  /// Combo-box filter input.
  combo,

  /// List based filter input.
  list,

  /// Two-ended range filter input.
  range,

  /// Boolean checkbox filter input.
  checkbox,
}

/// Raw two-ended value used by the grid header range filter editor.
///
/// Endpoints intentionally remain unparsed until the grid resolves the bound
/// field type and format settings.
@immutable
class FdcFilterRangeValue {
  /// Creates a [FdcFilterRangeValue].
  const FdcFilterRangeValue({required this.from, required this.to});

  /// Lower endpoint entered by the range filter.
  final Object? from;

  /// Upper endpoint entered by the range filter.
  final Object? to;

  /// Whether both range endpoints are null or blank.
  bool get isEmpty =>
      (from == null || from.toString().trim().isEmpty) &&
      (to == null || to.toString().trim().isEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FdcFilterRangeValue && from == other.from && to == other.to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => '${from ?? ''}..${to ?? ''}';
}

/// How a grid column participates in automatic width changes.
///
/// `none` keeps the column width fixed except for explicit/manual resize.
/// `viewport` lets the column absorb grid viewport width deltas. This is a
/// layout auto-size mode, not content measurement, and pinned columns are not
/// considered by the scrollable viewport auto-size pass.
enum FdcGridColumnAutoSizeMode {
  /// Do not auto-size the column.
  none,

  /// Let the column absorb viewport width deltas.
  viewport,
}

/// Horizontal pinning mode for a grid column.
///
/// Pinned columns stay visible while the scrollable column band moves
/// horizontally. `none` keeps the column in the normal scrollable band.
///
/// `start` and `end` define the initial/API pin edge but still allow the user
/// to unpin or move the column through the grid UI. `startFixed` and
/// `endFixed` define locked API pinning: the column stays pinned to that edge
/// and UI unpin/re-pin actions are not offered.
enum FdcGridColumnPin {
  /// Column is not pinned.
  none,

  /// Column is pinned to the logical start edge and can be unpinned.
  start,

  /// Column is pinned to the logical end edge and can be unpinned.
  end,

  /// Column is locked to the logical start edge.
  startFixed,

  /// Column is locked to the logical end edge.
  endFixed,
}

/// Layout of an optional summary label inside its summary cell.
///
/// [inline] keeps the label in the same text flow as the summary value.
/// [startAligned] pins the label to the logical start edge of the summary
/// cell and keeps the summary value aligned by the cell's normal summary
/// alignment.
enum FdcSummaryLabelAlignment {
  /// Render the label inline with the summary value.
  inline,

  /// Render the label at the logical start edge of the summary cell.
  startAligned,
}

/// Per-column visual style override for grid summary row values.
///
/// The grid-level `FdcGridSummaryStyle` remains the default for the whole
/// summary row. Columns can use this style to align, emphasize, or color their
/// own summary cell without affecting normal data cells.
class FdcGridSummaryCellStyle {
  /// Creates a [FdcGridSummaryCellStyle].
  const FdcGridSummaryCellStyle({
    this.backgroundColor,
    this.textStyle,
    this.alignment,
    this.padding,
  });

  /// Optional background color for this column's summary cell.
  final Color? backgroundColor;

  /// Optional text style for this column's summary value.
  final TextStyle? textStyle;

  /// Optional alignment for this column's summary value.
  final Alignment? alignment;

  /// Optional cell padding for this column's summary value.
  final EdgeInsetsGeometry? padding;

  /// Creates a copy with selected values replaced.
  FdcGridSummaryCellStyle copyWith({
    Color? backgroundColor,
    TextStyle? textStyle,
    Alignment? alignment,
    EdgeInsetsGeometry? padding,
  }) {
    return FdcGridSummaryCellStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textStyle: textStyle ?? this.textStyle,
      alignment: alignment ?? this.alignment,
      padding: padding ?? this.padding,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridSummaryCellStyle &&
            backgroundColor == other.backgroundColor &&
            textStyle == other.textStyle &&
            alignment == other.alignment &&
            padding == other.padding;
  }

  @override
  int get hashCode {
    return Object.hash(backgroundColor, textStyle, alignment, padding);
  }
}

/// Per-column summary configuration.
///
/// Keeps summary behavior grouped as one column property instead of spreading
/// aggregate, label, menu and style options across every column constructor.
class FdcColumnSummary {
  /// Creates a [FdcColumnSummary].
  const FdcColumnSummary({
    this.aggregate,
    this.label,
    this.labelVisible = true,
    this.labelAlignment = FdcSummaryLabelAlignment.inline,
    this.allowAggregateChange = false,
    this.style,
  });

  /// Aggregate operation displayed for this column in the optional summary row.
  ///
  /// Supported operations depend on the column data type. Unsupported
  /// combinations render `N/A` instead of affecting grid layout.
  final FdcAggregate? aggregate;

  /// Optional label displayed next to this column's summary value.
  ///
  /// The label is shown when it is explicitly configured and the column has an
  /// active summary aggregate. Runtime aggregate changes replace this label
  /// only while a different aggregate is selected. When the user selects the
  /// column's
  /// configured aggregate again, this label is restored.
  final String? label;

  /// Controls whether summary labels are rendered in the summary row.
  ///
  /// Defaults to `true`. When set to `false`, neither [label] nor runtime
  /// aggregate labels selected from the summary menu are displayed; the summary
  /// cell renders only the aggregate value.
  final bool labelVisible;

  /// Alignment/layout behavior for [label] inside the summary cell.
  final FdcSummaryLabelAlignment labelAlignment;

  /// Enables the summary row cell popup menu that lets users change this
  /// column's active aggregate at runtime.
  final bool allowAggregateChange;

  /// Optional per-column style used only by this column's summary row cell.
  final FdcGridSummaryCellStyle? style;

  /// Creates a copy with selected values replaced.
  FdcColumnSummary copyWith({
    FdcAggregate? aggregate,
    String? label,
    bool? labelVisible,
    FdcSummaryLabelAlignment? labelAlignment,
    bool? allowAggregateChange,
    FdcGridSummaryCellStyle? style,
  }) {
    return FdcColumnSummary(
      aggregate: aggregate ?? this.aggregate,
      label: label ?? this.label,
      labelVisible: labelVisible ?? this.labelVisible,
      labelAlignment: labelAlignment ?? this.labelAlignment,
      allowAggregateChange: allowAggregateChange ?? this.allowAggregateChange,
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcColumnSummary &&
            aggregate == other.aggregate &&
            label == other.label &&
            labelVisible == other.labelVisible &&
            labelAlignment == other.labelAlignment &&
            allowAggregateChange == other.allowAggregateChange &&
            style == other.style;
  }

  @override
  int get hashCode {
    return Object.hash(
      aggregate,
      label,
      labelVisible,
      labelAlignment,
      allowAggregateChange,
      style,
    );
  }
}

/// Adds grid column pin properties convenience APIs.
extension FdcGridColumnPinProperties on FdcGridColumnPin {
  /// Whether this mode pins the column to the logical start edge.
  bool get isStart =>
      /// The this.
      this == FdcGridColumnPin.start || this == FdcGridColumnPin.startFixed;

  /// Whether this mode pins the column to the logical end edge.
  bool get isEnd =>
      /// The this.
      this == FdcGridColumnPin.end || this == FdcGridColumnPin.endFixed;

  /// Whether this mode places the column in either pinned region.
  bool get isPinned => isStart || isEnd;

  /// Whether this mode prevents the user from unpinning the column.
  bool get isFixed =>
      /// The this.
      this == FdcGridColumnPin.startFixed || this == FdcGridColumnPin.endFixed;
}

/// Builds the text displayed by a badge column for the current cell value.
///
/// The grid calls the builder during cell rendering. Keep it side-effect free
/// because visible cells may be rebuilt repeatedly.
typedef FdcBadgeTextBuilder<T> = String Function(T? value);

/// Selects the badge color for the current cell value.
///
/// The grid calls the builder during cell rendering. Keep it side-effect free
/// because visible cells may be rebuilt repeatedly.
typedef FdcBadgeColorBuilder<T> = Color Function(T? value);

/// Formats the label shown for a progress-column value.
///
/// The grid calls the builder during rendering and may call it repeatedly for
/// the same value as cells rebuild.
typedef FdcProgressTextBuilder = String Function(num? value);

/// Builds the widget shown for one option in a column filter selector.
///
/// The grid owns option selection and filtering state; the builder controls only
/// the visual representation of the supplied option and may be called again on
/// rebuild.
typedef FdcFilterOptionBuilder =
    Widget Function(BuildContext context, FdcOption<Object?> option);

/// Per-column configuration for grid-managed header filtering.
class FdcColumnFilterConfig {
  /// Creates a [FdcColumnFilterConfig].
  const FdcColumnFilterConfig({
    this.enabled = true,
    this.editor = FdcFilterEditor.search,
    this.values,
    this.defaultOperator,
    this.operators,
    this.caseSensitive = false,
    this.comboSearchable = false,
    this.comboSearchHintText,
    this.comboMaxPopupItems = 8,
    this.comboOptionBuilder,
  });

  /// Enables grid-managed filtering for this column.
  final bool enabled;

  /// Header filter editor used for this column.
  final FdcFilterEditor editor;

  /// Field values carried by this object.
  final List<FdcOption<Object?>>? values;

  /// Operator selected when this column first creates a filter.
  final FdcFilterOperator? defaultOperator;

  /// Optional allow-list of operators exposed by the column filter UI.
  final List<FdcFilterOperator>? operators;

  /// Whether text comparisons performed by this column filter are case-sensitive.
  final bool caseSensitive;

  /// Enables text search inside combo-based filter popups.
  final bool comboSearchable;

  /// Optional hint shown in the combo filter search field.
  final String? comboSearchHintText;

  /// Maximum number of options shown in the combo filter popup before scrolling.
  final int comboMaxPopupItems;

  /// Optional builder used to render combo filter options.
  final FdcFilterOptionBuilder? comboOptionBuilder;

  /// Creates a copy with selected values replaced.
  FdcColumnFilterConfig copyWith({
    bool? enabled,
    FdcFilterEditor? editor,
    List<FdcOption<Object?>>? values,
    FdcFilterOperator? defaultOperator,
    List<FdcFilterOperator>? operators,
    bool? caseSensitive,
    bool? comboSearchable,
    String? comboSearchHintText,
    int? comboMaxPopupItems,
    FdcFilterOptionBuilder? comboOptionBuilder,
  }) {
    return FdcColumnFilterConfig(
      enabled: enabled ?? this.enabled,
      editor: editor ?? this.editor,
      values: values ?? this.values,
      defaultOperator: defaultOperator ?? this.defaultOperator,
      operators: operators ?? this.operators,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      comboSearchable: comboSearchable ?? this.comboSearchable,
      comboSearchHintText: comboSearchHintText ?? this.comboSearchHintText,
      comboMaxPopupItems: comboMaxPopupItems ?? this.comboMaxPopupItems,
      comboOptionBuilder: comboOptionBuilder ?? this.comboOptionBuilder,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcColumnFilterConfig &&
            enabled == other.enabled &&
            editor == other.editor &&
            listEquals(values, other.values) &&
            defaultOperator == other.defaultOperator &&
            listEquals(operators, other.operators) &&
            caseSensitive == other.caseSensitive &&
            comboSearchable == other.comboSearchable &&
            comboSearchHintText == other.comboSearchHintText &&
            comboMaxPopupItems == other.comboMaxPopupItems &&
            comboOptionBuilder == other.comboOptionBuilder;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      editor,
      Object.hashAll(values ?? const <FdcOption<Object?>>[]),
      defaultOperator,
      Object.hashAll(operators ?? const <FdcFilterOperator>[]),
      caseSensitive,
      comboSearchable,
      comboSearchHintText,
      comboMaxPopupItems,
      comboOptionBuilder,
    );
  }
}

/// Column-level pre-write interceptor.
///
/// The callback runs after the grid has accepted the editor/custom-cell action
/// but before the value is written into the dataset. Return `null` or
/// `context.accept()` to keep the incoming value,
/// `context.replaceValue(...)` to
/// transform it, or `context.cancel(...)` to reject it.
typedef FdcColumnValueChanging<T> =
    FdcColumnValueChangeResult<T>? Function(
      FdcColumnValueChangingContext<T> context,
    );

/// Asynchronous lookup callback for a grid column.
///
/// Return an [FdcLookupResult] to apply its field values. Return `null` to
/// cancel the lookup without changing the dataset.
typedef FdcGridLookup<T> =
    Future<FdcLookupResult?> Function(FdcLookupContext context);

/// Column-level post-write notification.
typedef FdcColumnValueChanged<T> =
    void Function(FdcColumnValueChangedContext<T> context);

/// Result returned by a column value-changing callback.
///
/// Use the inherited field-change result semantics to accept the proposed value,
/// replace it with a transformed value, or cancel the write before it reaches
/// the dataset.
typedef FdcColumnValueChangeResult<T> = FdcFieldValueChangeResult<T>;

/// Grid-column context supplied before an edited value is written to the dataset.
class FdcColumnValueChangingContext<T> extends FdcFieldValueChangingContext<T> {
  /// Creates a column-aware value-changing context.
  FdcColumnValueChangingContext({
    required super.column,
    required FdcGridRowContext row,
    required super.rowIndex,
    required super.columnIndex,
    required super.fieldName,
    required super.oldValue,
    required super.newValue,
    required super.dataSet,
  }) : super(
         row: row,
         host: FdcFieldEventHost.grid,
         oldRawValue: oldValue,
         newRawValue: newValue,
         valueOf: row.valueOf,
       );
}

/// Grid-column context supplied after the primary edited value has been written locally.
class FdcColumnValueChangedContext<T> extends FdcFieldValueChangedContext<T> {
  /// Creates a [FdcColumnValueChangedContext].
  FdcColumnValueChangedContext({
    required super.dataSet,
    required super.column,
    required FdcGridRowContext row,
    required super.rowIndex,
    required super.columnIndex,
    required super.fieldName,
    required super.oldValue,
    required super.value,
  }) : super(
         row: row,
         host: FdcFieldEventHost.grid,
         oldRawValue: oldValue,
         rawValue: value,
         valueOf: row.valueOf,
       );
}

/// Result of applying a lookup selection to the active grid edit session.
@internal
sealed class FdcGridLookupApplyResult {
  const FdcGridLookupApplyResult._({
    required this.accepted,
    this.values = const <String, Object?>{},
  });

  /// Whether the lookup selection should be committed.
  final bool accepted;

  /// Field values carried by this object.
  final Map<String, Object?> values;
}

/// Accepted lookup result carrying field values to write.
@internal
final class FdcGridLookupApplyAccepted extends FdcGridLookupApplyResult {
  /// Creates a [FdcGridLookupApplyAccepted].
  const FdcGridLookupApplyAccepted({required super.values})
    : super._(accepted: true);
}

/// Canceled lookup result that leaves field values unchanged.
@internal
final class FdcGridLookupApplyCanceled extends FdcGridLookupApplyResult {
  /// Creates a [FdcGridLookupApplyCanceled].
  const FdcGridLookupApplyCanceled() : super._(accepted: false);
}

/// Horizontal alignment applied to a grid column.
///
/// The value controls the built-in data cell, editor, summary cell, and header
/// label alignment. `null` keeps the column's default behavior.
enum FdcGridHorizontalAlignment {
  /// Start option.
  start,

  /// Center option.
  center,

  /// End option.
  end,
}

/// Visual style applied to data cells in a column.
class FdcGridCellStyle {
  /// Creates a [FdcGridCellStyle].
  const FdcGridCellStyle({
    this.textStyle,
    this.backgroundColor,
    this.alignment,
  });

  /// Optional text style override for this value.
  final TextStyle? textStyle;

  /// Optional background color override for this value.
  final Color? backgroundColor;

  /// Optional alignment override for this value.
  final Alignment? alignment;

  /// Creates a copy with selected values replaced.
  FdcGridCellStyle copyWith({
    TextStyle? textStyle,
    Color? backgroundColor,
    Alignment? alignment,
  }) {
    return FdcGridCellStyle(
      textStyle: textStyle ?? this.textStyle,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      alignment: alignment ?? this.alignment,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridCellStyle &&
            textStyle == other.textStyle &&
            backgroundColor == other.backgroundColor &&
            alignment == other.alignment;
  }

  @override
  int get hashCode => Object.hash(textStyle, backgroundColor, alignment);
}

/// Value object for badge editors when text, color, icon, or text style
/// varies per row.
class FdcBadgeValue {
  /// Creates a [FdcBadgeValue].
  const FdcBadgeValue({
    required this.text,
    this.color,
    this.icon,
    this.textStyle,
  });

  /// Text displayed to the user.
  final String text;

  /// Optional foreground color associated with this value.
  final Color? color;

  /// Optional icon shown with the item.
  final IconData? icon;

  /// Optional text style override for this value.
  final TextStyle? textStyle;

  @override
  String toString() => text;
}

/// Value object for progress editors when styling varies per row.
class FdcProgressValue {
  /// Creates a [FdcProgressValue].
  const FdcProgressValue(
    this.value, {
    this.text,
    this.color,
    this.backgroundColor,
  });

  /// Current value carried by this object.
  final num value;

  /// Text displayed to the user.
  final String? text;

  /// Optional foreground color associated with this value.
  final Color? color;

  /// Optional background color override for this value.
  final Color? backgroundColor;
}

/// Builds body-cell context-menu entries.
typedef FdcGridMenuBuilder =
    List<FdcMenuEntry> Function(FdcGridMenuContext context);

/// Read-only context supplied to grid and column body-cell context menus.
class FdcGridMenuContext {
  /// Creates a [FdcGridMenuContext].
  const FdcGridMenuContext({
    required this.buildContext,
    required this.dataSet,
    required this.row,
    required this.rowIndex,
    required this.sourceRowIndex,
    required this.recordId,
    required this.column,
    required this.columnIndex,
    required this.value,
    required this.isEditing,
    required this.isCellSelected,
    required this.isRowSelected,
    required this.canInsertRecord,
    required this.canAppendRecord,
    required this.canCancelEdit,
    required this.insertRecord,
    required this.appendRecord,
    required this.cancelEdit,
  });

  /// Flutter build context associated with this object.
  final BuildContext buildContext;

  /// Dataset associated with this object.
  final FdcDataSet dataSet;

  /// Row context associated with this object.
  final FdcGridRowContext row;

  /// Zero-based row index in the current view.
  final int rowIndex;

  /// Source-adapter row index when available for this row.
  final int? sourceRowIndex;

  /// Internal record identifier.
  final int? recordId;

  /// Column configuration associated with this object.
  final FdcGridColumn<dynamic> column;

  /// Zero-based column index in the current grid layout.
  final int columnIndex;

  /// Current value carried by this object.
  final Object? value;

  /// Whether the grid is currently editing this cell.
  final bool isEditing;

  /// Whether this exact cell is the current grid selection.
  final bool isCellSelected;

  /// Whether the row is included in the grid row-selection set.
  final bool isRowSelected;

  /// Whether the grid can start an inserted record from this menu context.
  final bool canInsertRecord;

  /// Whether the grid can append a new record from this menu context.
  final bool canAppendRecord;

  /// Whether the grid can cancel the current edit/insert buffer.
  final bool canCancelEdit;

  /// Starts a grid-owned insert operation and focuses the first editable field.
  final VoidCallback? insertRecord;

  /// Starts a grid-owned append operation and focuses the first editable field.
  final VoidCallback? appendRecord;

  /// Cancels the current grid/dataset edit or insert operation.
  final VoidCallback? cancelEdit;
}

/// Base metadata shared by every grid column type.
abstract class FdcGridColumn<T> {
  /// Creates a [FdcGridColumn].
  const FdcGridColumn({
    this.id,
    this.groupId,
    required this.fieldName,
    this.label,
    this.hint,
    this.visible = true,
    this.exportable = true,
    this.enabled = true,
    this.readOnly = false,
    this.focusOrder,
    this.tabStop = true,
    this.width,
    this.minWidth = 0,
    this.maxWidth = 0,
    this.autoSizeMode = FdcGridColumnAutoSizeMode.none,
    this.allowSort = true,
    this.filterConfig,
    this.allowResize = true,
    this.horizontalAlignment,
    this.showIndicator = true,
    this.onValueChanging,
    this.onLookup,
    this.lookupIcon = Icons.more_horiz,
    this.lookupShortcut = FdcKeyboardShortcut.f4,
    this.onValueChanged,
    this.cellStyle,
    this.pin = FdcGridColumnPin.none,
    this.summary = const FdcColumnSummary(),
    this.menuBuilder,
  });

  /// Stable developer-defined column identity.
  ///
  /// When provided, the grid uses this value to preserve column runtime state
  /// such as width, pinning, sorting, filtering and summary overrides across
  /// parent rebuilds, inserts, removes and reorders. Public grid controller
  /// column commands also target columns by this id. If omitted, the grid falls
  /// back to a best-effort identity for internal layout state, but the column
  /// cannot be targeted by controller column commands.
  final String? id;

  /// Whether this column is backed by a dataset field.
  ///
  /// Standard columns are field-bound. UI-only columns such as
  /// action columns override this to opt out of dataset field binding,
  /// sorting, filtering, searching and validation metadata lookups.
  bool get isDataBound => true;

  /// Optional id of the visual column group this column belongs to.
  ///
  /// When set, the value must match a unique `FdcGridColumnGroup.id` on the
  /// owning grid. Group membership is column-based, not field-name-based, so
  /// duplicate field-bound columns can belong to different groups.
  final String? groupId;

  /// Dataset field name associated with this object.
  final String fieldName;

  /// Display label shown to the user.
  final String? label;

  /// Optional tooltip or contextual hint associated with this column.
  final String? hint;

  /// Whether the column participates in the current grid layout.
  final bool visible;

  /// Whether this field-bound column participates in grid-driven exports.
  ///
  /// Defaults to `true`. Set to `false` to keep the column visible in the grid
  /// while excluding it from exports that use
  /// `FdcGridExportColumnMode.visibleColumns`. Dataset-field exports are not
  /// affected because they do not use grid column configuration.
  final bool exportable;

  /// Enables grid-managed filtering for this column.
  final bool enabled;

  /// Prevents editing through this column while keeping the field visible.
  final bool readOnly;

  /// Optional explicit keyboard focus order among focusable grid columns.
  final int? focusOrder;

  /// Whether Tab navigation may stop on this column.
  final bool tabStop;

  /// Optional initial column width; grid defaults are used when omitted.
  final double? width;

  /// Minimum width allowed during layout and interactive resize.
  final double minWidth;

  /// Maximum width allowed during layout and resize; zero means no explicit maximum.
  final double maxWidth;

  /// Automatic width behavior used when the grid viewport changes size.
  final FdcGridColumnAutoSizeMode autoSizeMode;

  /// Whether allow sort.
  final bool allowSort;

  /// Optional per-column header filter configuration.
  final FdcColumnFilterConfig? filterConfig;

  /// Whether allow resize.
  final bool allowResize;

  /// Optional horizontal alignment for the entire column.
  ///
  /// When set, the alignment is applied consistently to built-in data cells,
  /// text editors, summary values, custom cell context, badge cells, and the
  /// header label. When omitted, existing defaults are preserved.
  final FdcGridHorizontalAlignment? horizontalAlignment;

  /// Controls whether this column renders the active-cell indicator overlay.
  ///
  /// Defaults to `true`. Set to `false` for visual/custom columns where the
  /// indicator would cover important content, such as thumbnails, images,
  /// badges, progress bars, or custom action widgets.
  final bool showIndicator;

  /// Optional column-level interceptor invoked before values are written into
  /// the dataset. Useful for cell-level validation and transformations such as
  /// barcode-to-article-code lookup.
  final FdcColumnValueChanging<T>? onValueChanging;

  /// Optional asynchronous lookup invoked by the focused-cell lookup button.
  final FdcGridLookup<T>? onLookup;

  /// Icon used by the focused-cell lookup button.
  ///
  /// Defaults to [Icons.more_horiz]. This value is only used when [onLookup] is
  /// provided.
  final IconData lookupIcon;

  /// Keyboard shortcut that invokes [onLookup] for the focused cell.
  ///
  /// Defaults to F4. Set to `null` to disable keyboard lookup activation.
  /// A configured shortcut takes precedence over built-in grid handling for
  /// the same key while this column is focused.
  final FdcKeyboardShortcut? lookupShortcut;

  /// Optional column-level notification invoked after a value was successfully
  /// written for this column.
  ///
  /// This callback is local to the edited column. Additional same-row field
  /// writes requested through [onValueChanging] are reported by the grid-level
  /// `onCellChanged`, but do not invoke other columns' [onValueChanged]
  /// callbacks.
  final FdcColumnValueChanged<T>? onValueChanged;

  /// Internal identity token used by grid lifecycle signatures.
  ///
  /// This intentionally exposes the callback as [Object?] from inside the
  /// concrete generic column instance. Reading [onValueChanging] through an
  /// erased `FdcGridColumn<dynamic>` reference can otherwise trigger runtime
  /// function-type checks for callbacks such as
  /// `FdcColumnValueChanging<String>`.
  @internal
  Object? get valueChangingSignatureToken => onValueChanging;

  /// Returns the current lookup signature token.
  @internal
  Object? get lookupSignatureToken => onLookup;

  /// Internal identity token used by grid lifecycle signatures.
  @internal
  Object? get valueChangedSignatureToken => onValueChanged;

  /// Internal identity token for custom-cell builder callbacks.
  @internal
  Object? get customCellBuilderSignatureToken => null;

  /// Internal identity token for badge text builder callbacks.
  @internal
  Object? get badgeTextBuilderSignatureToken => null;

  /// Internal identity token for badge color builder callbacks.
  @internal
  Object? get badgeColorBuilderSignatureToken => null;

  /// Internal identity token for progress text builder callbacks.
  @internal
  Object? get progressTextBuilderSignatureToken => null;

  /// Optional visual overrides applied to body cells in this column.
  final FdcGridCellStyle? cellStyle;

  /// Invokes [onValueChanging] using this column's concrete generic value type.
  ///
  /// Grid state code often stores columns through erased/dynamic references,
  /// but
  /// the interceptor callback is typed as [FdcColumnValueChangingContext<T>].
  /// Keeping the invocation on the column preserves the concrete `T` and avoids
  /// runtime function-type mismatches such as passing
  /// `FdcColumnValueChangingContext<dynamic>` to a `String` interceptor.
  FdcFieldValueChangeResult<T>? applyValueChanging({
    required FdcDataSet dataSet,
    required FdcGridRowContext row,
    required int rowIndex,
    required int columnIndex,
    required String fieldName,
    required Object? oldValue,
    required Object? newValue,
  }) {
    final callback = onValueChanging;
    if (callback == null) {
      return null;
    }

    final context = FdcColumnValueChangingContext<T>(
      dataSet: dataSet,
      column: this,
      row: row,
      rowIndex: rowIndex,
      columnIndex: columnIndex,
      fieldName: fieldName,
      oldValue: oldValue as T?,
      newValue: newValue as T?,
    );
    final result = callback(context) ?? context.accept();
    return result.withAdditionalValues(context.additionalValueSnapshot);
  }

  /// Runs the apply lookup operation.
  @internal
  Future<FdcGridLookupApplyResult> applyLookup({
    required BuildContext buildContext,
    required FdcDataSet dataSet,
    required FdcGridRowContext row,
    required String fieldName,
    required String? lookupText,
    required FdcLookupMode mode,
  }) async {
    final callback = onLookup;
    if (callback == null) {
      return const FdcGridLookupApplyCanceled();
    }
    final context = FdcLookupContext(
      buildContext: buildContext,
      dataSet: dataSet,
      fieldName: fieldName,
      lookupText: lookupText,
      lookupMode: mode,
      valueOf: row.valueOf,
    );
    final result = await callback(context);
    if (result == null) {
      return const FdcGridLookupApplyCanceled();
    }
    return FdcGridLookupApplyAccepted(values: result.values);
  }

  /// Invokes [onValueChanged] using this column's concrete generic value type.
  void applyValueChanged({
    required FdcDataSet dataSet,
    required FdcGridRowContext row,
    required int rowIndex,
    required int? columnIndex,
    required String fieldName,
    required Object? oldValue,
    required Object? value,
  }) {
    final callback = onValueChanged;
    if (callback == null) {
      return;
    }

    callback(
      FdcColumnValueChangedContext<T>(
        dataSet: dataSet,
        column: this,
        row: row,
        rowIndex: rowIndex,
        columnIndex: columnIndex,
        fieldName: fieldName,
        oldValue: oldValue as T?,
        value: value as T?,
      ),
    );
  }

  /// Optional body-cell context menu override for this column.
  ///
  /// When omitted, the owning grid-level builder is used.
  final FdcGridMenuBuilder? menuBuilder;

  /// Initial horizontal pinning mode for this column.
  final FdcGridColumnPin pin;

  /// Per-column summary row behavior and style.
  final FdcColumnSummary summary;

  /// Dataset value type represented by this column.
  FdcDataType get dataType;

  /// Built-in editor mode used when this column enters edit state.
  FdcEditorType get effectiveEditor;

  /// Validates this column's dataset field binding for the grid runtime.
  ///
  /// Standard typed columns require one expected `FdcFieldDef` subtype.
  /// UI-specialized columns can accept an explicitly supported set of field
  /// subtypes. This hook intentionally returns no package-internal binding
  /// object.
  @internal
  void validateBinding(FdcDataSet dataSet);

  /// True when the column type itself cannot support grid editing.
  ///
  /// Specialized display/action columns override this independently of the
  /// caller-configured [readOnly] flag.
  bool get isInherentlyReadOnly => false;

  /// True when grid editing is disabled by configuration or column semantics.
  ///
  /// This combines the caller-configured [readOnly] flag with
  /// [isInherentlyReadOnly]. Dataset field metadata may impose additional write
  /// restrictions when an edit is committed.
  bool get isEffectivelyReadOnly => readOnly || isInherentlyReadOnly;

  /// Whether grid-managed filtering is enabled for this column.
  bool get filterEnabled => filterConfig?.enabled ?? true;
}
