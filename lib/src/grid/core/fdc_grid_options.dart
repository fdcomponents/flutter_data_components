// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../data/fdc_filter_operator.dart';
import 'fdc_grid_types.dart';

/// Behavioral and layout options for an `FdcGrid`.
///
/// These options configure interaction and geometry defaults without owning
/// dataset state or column definitions.
class FdcGridOptions {
  /// Creates a [FdcGridOptions].
  const FdcGridOptions({
    this.readOnly = false,
    this.allowColumnSorting = false,
    this.allowColumnFiltering = true,
    this.allowColumnReordering = false,
    this.allowColumnResize = true,
    this.autoEdit = true,
    this.confirmDelete = true,
    this.defaultColumnWidth = fallbackDefaultColumnWidth,
    this.rowHeight = fallbackRowHeight,
    this.verticalScrollMode = FdcGridVerticalScrollMode.recordScroll,
    this.horizontalScrollMode = FdcGridHorizontalScrollMode.columnSnap,
    this.scrollbars = FdcGridScrollbars.both,
  }) : assert(
         defaultColumnWidth >= minimumDefaultColumnWidth &&
             defaultColumnWidth != double.infinity,
         'FdcGridOptions.defaultColumnWidth must be a finite value >= '
         'FdcGridOptions.minimumDefaultColumnWidth.',
       ),
       assert(
         rowHeight >= minimumRowHeight && rowHeight != double.infinity,
         'FdcGridOptions.rowHeight must be a finite value >= '
         'FdcGridOptions.minimumRowHeight.',
       );

  /// Default value for fallback default column width.
  static const double fallbackDefaultColumnWidth = 160;

  /// Default value for fallback row height.
  static const double fallbackRowHeight = 40;

  /// Default value for minimum default column width.
  static const double minimumDefaultColumnWidth = 32;

  /// Default value for minimum row height.
  static const double minimumRowHeight = 20;

  /// Validates values that cannot be enforced by a const constructor in
  /// release builds. The grid invokes this before using the configuration.
  void validate() {
    validateDimensions(
      defaultColumnWidth: defaultColumnWidth,
      rowHeight: rowHeight,
    );
  }

  /// Validates grid dimensions independently of constructor assertions.
  ///
  /// This is also the release-mode validation path used by [validate].
  static void validateDimensions({
    required double defaultColumnWidth,
    required double rowHeight,
  }) {
    if (!defaultColumnWidth.isFinite ||
        defaultColumnWidth < minimumDefaultColumnWidth) {
      throw ArgumentError.value(
        defaultColumnWidth,
        'defaultColumnWidth',
        'Must be finite and >= $minimumDefaultColumnWidth.',
      );
    }
    if (!rowHeight.isFinite || rowHeight < minimumRowHeight) {
      throw ArgumentError.value(
        rowHeight,
        'rowHeight',
        'Must be finite and >= $minimumRowHeight.',
      );
    }
  }

  /// Resolves a safe default column width from [value].
  static double resolveDefaultColumnWidth(double value) {
    return _resolveDimension(
      value,
      fallback: fallbackDefaultColumnWidth,
      minimum: minimumDefaultColumnWidth,
    );
  }

  /// Resolves a safe row height from [value].
  static double resolveRowHeight(double value) {
    return _resolveDimension(
      value,
      fallback: fallbackRowHeight,
      minimum: minimumRowHeight,
    );
  }

  static double _resolveDimension(
    double value, {
    required double fallback,
    required double minimum,
  }) {
    if (!value.isFinite) {
      return fallback;
    }
    if (value < minimum) {
      return minimum;
    }
    return value;
  }

  /// Prevents the grid from starting edit, insert, append, or delete operations.
  final bool readOnly;

  /// Enables interactive column sorting through headers and column menus.
  final bool allowColumnSorting;

  /// Controls whether column filter UI actions are available in grid menus.
  ///
  /// This only affects grid-managed column filter UI. Dataset-level filters
  /// can still be applied programmatically through the dataset API.
  final bool allowColumnFiltering;

  /// Enables pointer-driven column reordering.
  final bool allowColumnReordering;

  /// Enables interactive column width resizing.
  final bool allowColumnResize;

  /// Starts cell editing automatically when editable content receives direct input.
  final bool autoEdit;

  /// When true, Ctrl+Delete asks for confirmation before deleting the
  /// current record from the dataset.
  final bool confirmDelete;

  /// Fallback width used by columns that do not define an explicit width.
  ///
  /// This value must be finite and at least [minimumDefaultColumnWidth].
  /// Runtime layout code uses
  /// [resolvedDefaultColumnWidth] as a final safety net.
  final double defaultColumnWidth;

  /// Fixed height used by data rows.
  ///
  /// This value must be finite and at least [minimumRowHeight]. Runtime
  /// layout code uses [resolvedRowHeight] as a
  /// final safety net.
  final double rowHeight;

  /// Layout-safe fallback column width.
  ///
  /// This returns [fallbackDefaultColumnWidth] for non-finite values and clamps
  /// finite values below [minimumDefaultColumnWidth] to that minimum.
  double get resolvedDefaultColumnWidth =>
      resolveDefaultColumnWidth(defaultColumnWidth);

  /// Layout-safe row height.
  ///
  /// This returns [fallbackRowHeight] for non-finite values and clamps finite
  /// values below [minimumRowHeight] to that minimum.
  double get resolvedRowHeight => resolveRowHeight(rowHeight);

  /// Controls vertical row scrolling behavior.
  final FdcGridVerticalScrollMode verticalScrollMode;

  /// Controls horizontal column scrolling behavior.
  final FdcGridHorizontalScrollMode horizontalScrollMode;

  /// Controls which scrollbar thumbs are rendered by the grid.
  ///
  /// This is visual chrome only. Pointer dragging, wheel/trackpad scrolling,
  /// keyboard navigation, and programmatic scrolling remain enabled even when
  /// one or both scrollbar thumbs are hidden.
  final FdcGridScrollbars scrollbars;

  /// Creates a copy with selected values replaced.
  FdcGridOptions copyWith({
    bool? readOnly,
    bool? allowColumnSorting,
    bool? allowColumnFiltering,
    bool? allowColumnReordering,
    bool? allowColumnResize,
    bool? autoEdit,
    bool? confirmDelete,
    double? defaultColumnWidth,
    double? rowHeight,
    FdcGridVerticalScrollMode? verticalScrollMode,
    FdcGridHorizontalScrollMode? horizontalScrollMode,
    FdcGridScrollbars? scrollbars,
  }) {
    return FdcGridOptions(
      readOnly: readOnly ?? this.readOnly,
      allowColumnSorting: allowColumnSorting ?? this.allowColumnSorting,
      allowColumnFiltering: allowColumnFiltering ?? this.allowColumnFiltering,
      allowColumnReordering:
          allowColumnReordering ?? this.allowColumnReordering,
      allowColumnResize: allowColumnResize ?? this.allowColumnResize,
      autoEdit: autoEdit ?? this.autoEdit,
      confirmDelete: confirmDelete ?? this.confirmDelete,
      defaultColumnWidth: defaultColumnWidth ?? this.defaultColumnWidth,
      rowHeight: rowHeight ?? this.rowHeight,
      verticalScrollMode: verticalScrollMode ?? this.verticalScrollMode,
      horizontalScrollMode: horizontalScrollMode ?? this.horizontalScrollMode,
      scrollbars: scrollbars ?? this.scrollbars,
    );
  }

  /// Whether the configured scrollbar mode includes a vertical thumb.
  bool get showVerticalScrollbar =>
      scrollbars == FdcGridScrollbars.both ||
      scrollbars == FdcGridScrollbars.vertical;

  /// Whether the configured scrollbar mode includes a horizontal thumb.
  bool get showHorizontalScrollbar =>
      scrollbars == FdcGridScrollbars.both ||
      scrollbars == FdcGridScrollbars.horizontal;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridOptions &&
            readOnly == other.readOnly &&
            allowColumnSorting == other.allowColumnSorting &&
            allowColumnFiltering == other.allowColumnFiltering &&
            allowColumnReordering == other.allowColumnReordering &&
            allowColumnResize == other.allowColumnResize &&
            autoEdit == other.autoEdit &&
            confirmDelete == other.confirmDelete &&
            defaultColumnWidth == other.defaultColumnWidth &&
            rowHeight == other.rowHeight &&
            verticalScrollMode == other.verticalScrollMode &&
            horizontalScrollMode == other.horizontalScrollMode &&
            scrollbars == other.scrollbars;
  }

  @override
  int get hashCode => Object.hash(
    readOnly,
    allowColumnSorting,
    allowColumnFiltering,
    allowColumnReordering,
    allowColumnResize,
    autoEdit,
    confirmDelete,
    defaultColumnWidth,
    rowHeight,
    verticalScrollMode,
    horizontalScrollMode,
    scrollbars,
  );
}

/// Configures interactive column pinning and labels for pinned header bands.
class FdcGridColumnPinning {
  /// Creates a [FdcGridColumnPinning].
  const FdcGridColumnPinning({
    this.enabled = false,
    this.startPinnedGroupLabel = '',
    this.unpinnedGroupLabel = '',
    this.endPinnedGroupLabel = '',
  });

  /// Controls whether column pin/unpin actions are available in grid menus.
  ///
  /// This only affects interactive pinning. Columns can still define an
  /// initial pin programmatically through `FdcGridColumn.pin`.
  final bool enabled;

  /// Optional label rendered across the start-pinned header band while the
  /// column-group header row is active.
  final String startPinnedGroupLabel;

  /// Optional label rendered across ungrouped columns in the scrollable
  /// header band while the column-group header row is active.
  final String unpinnedGroupLabel;

  /// Optional label rendered across the end-pinned header band while the
  /// column-group header row is active.
  final String endPinnedGroupLabel;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridColumnPinning &&
            enabled == other.enabled &&
            startPinnedGroupLabel == other.startPinnedGroupLabel &&
            unpinnedGroupLabel == other.unpinnedGroupLabel &&
            endPinnedGroupLabel == other.endPinnedGroupLabel;
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    startPinnedGroupLabel,
    unpinnedGroupLabel,
    endPinnedGroupLabel,
  );
}

/// Configures default operator and debounce behavior for grid-managed filters.
class FdcGridFilterOptions {
  /// Creates a [FdcGridFilterOptions].
  const FdcGridFilterOptions({
    this.defaultTextOperator = FdcFilterOperator.contains,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.debouncePolicy = FdcDebouncePolicy.adaptive,
  });

  /// Default operator used by grid-managed text header filters when a column
  /// does not provide `FdcColumnFilterConfig.defaultOperator`.
  final FdcFilterOperator defaultTextOperator;

  /// Base/minimum delay before grid-managed header filter changes rebuild the
  /// dataset view.
  ///
  /// A new filter edit cancels any pending rebuild, so rapid input only applies
  /// the latest filter state. Set to [Duration.zero] for immediate filtering.
  final Duration debounceDuration;

  /// Controls how header text filter input is applied.
  ///
  /// [FdcDebouncePolicy.disabled] keeps text edits local until the filter field
  /// is submitted explicitly, for example with Enter/Search.
  final FdcDebouncePolicy debouncePolicy;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridFilterOptions &&
            defaultTextOperator == other.defaultTextOperator &&
            debounceDuration == other.debounceDuration &&
            debouncePolicy == other.debouncePolicy;
  }

  @override
  int get hashCode =>
      Object.hash(defaultTextOperator, debounceDuration, debouncePolicy);
}

/// Selects which status, numbering, and row-selection affordances appear in the row indicator.
class FdcGridRowIndicatorOptions {
  /// Creates a [FdcGridRowIndicatorOptions].
  const FdcGridRowIndicatorOptions({
    this.showRecordStatus = true,
    this.showRowNumbers = false,
    this.showRowSelect = false,
  });

  /// Shows the current record state indicator, such as edit or insert status.
  final bool showRecordStatus;

  /// Shows row numbers in the leading row indicator area.
  final bool showRowNumbers;

  /// Shows row-selection controls in the leading row indicator area.
  final bool showRowSelect;

  /// Whether at least one row-indicator element is enabled.
  bool get visible => showRecordStatus || showRowNumbers || showRowSelect;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridRowIndicatorOptions &&
            showRecordStatus == other.showRecordStatus &&
            showRowNumbers == other.showRowNumbers &&
            showRowSelect == other.showRowSelect;
  }

  @override
  int get hashCode =>
      Object.hash(showRecordStatus, showRowNumbers, showRowSelect);
}
