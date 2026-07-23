// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart' show listEquals, mapEquals;

import '../../common/theme/fdc_grid_styles.dart';
import '../../common/widgets/validation/fdc_error_indicator.dart';
import '../../data/fdc_dataset_search.dart';
import '../../exports/fdc_export.dart';
import '../widgets/fdc_grid_status_bar_items.dart';
import 'fdc_grid_options.dart';
import 'fdc_grid_types.dart';

/// Configures the leading grid region used for row status, numbering, selection, and the main menu.
class FdcGridRowIndicator {
  /// Creates a [FdcGridRowIndicator].
  const FdcGridRowIndicator({
    this.visible = false,
    this.options = const FdcGridRowIndicatorOptions(),
  });

  /// Controls whether the leading row indicator component is rendered.
  ///
  /// The row indicator hosts row status, row numbers, row selection, and the
  /// main grid menu when enabled. When this is false, the main grid menu
  /// actions are exposed through each column header menu.
  final bool visible;

  /// Configures the content shown inside the leading row indicator component.
  final FdcGridRowIndicatorOptions options;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridRowIndicator &&
            visible == other.visible &&
            options == other.options;
  }

  @override
  int get hashCode => Object.hash(visible, options);
}

/// Configures the visual indicator drawn around or beside the focused grid cell.
class FdcGridCellIndicator {
  /// Creates a [FdcGridCellIndicator].
  const FdcGridCellIndicator({
    this.visible = true,
    this.mode = FdcGridCellIndicatorMode.line,
    this.style = const FdcGridCellIndicatorStyle(),
    this.errorIndicator = const FdcErrorIndicatorOptions(),
  });

  /// Controls whether the active/current cell indicator is rendered.
  ///
  /// Existing column-level `showIndicator: false` still suppresses the
  /// indicator for that column.
  final bool visible;

  /// Active/current cell indicator rendering mode.
  final FdcGridCellIndicatorMode mode;

  /// Visual styling applied to the active/current cell indicator.
  final FdcGridCellIndicatorStyle style;

  /// Validates grid-specific indicator constraints in all build modes.
  void validate() {
    if (errorIndicator.mode == FdcErrorIndicatorMode.inline) {
      throw ArgumentError.value(
        errorIndicator.mode,
        'errorIndicator.mode',
        'FdcGrid supports marker or none; inline is standalone-editor only.',
      );
    }
  }

  /// Configures cell-level error markers.
  ///
  /// Grid cells support [FdcErrorIndicatorMode.none] and
  /// [FdcErrorIndicatorMode.marker]. [FdcErrorIndicatorMode.inline] is reserved
  /// for standalone editors and is rejected by [validate].
  final FdcErrorIndicatorOptions errorIndicator;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridCellIndicator &&
            visible == other.visible &&
            mode == other.mode &&
            style == other.style &&
            errorIndicator == other.errorIndicator;
  }

  @override
  int get hashCode => Object.hash(visible, mode, style, errorIndicator);
}

/// Configures visibility and styling of the grid-managed header filter row.
class FdcGridHeaderFilters {
  /// Creates a [FdcGridHeaderFilters].
  const FdcGridHeaderFilters({
    this.visible = false,
    this.initiallyVisible = true,
    this.options = const FdcGridFilterOptions(),
    this.style,
  });

  /// Controls whether grid-managed column filters are available.
  ///
  /// When this is false, the header filter row and its menu actions are
  /// disabled. Dataset-level filters can still be applied programmatically.
  final bool visible;

  /// Controls whether the header filter row is visible when the grid starts.
  ///
  /// Users can still show or hide the row at runtime through the grid menu
  /// while [visible] is true.
  final bool initiallyVisible;

  /// Header filter behavior and debounce configuration.
  final FdcGridFilterOptions options;

  /// Visual styling applied to header filter controls.
  final FdcGridHeaderFilterStyle? style;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridHeaderFilters &&
            visible == other.visible &&
            initiallyVisible == other.initiallyVisible &&
            options == other.options &&
            style == other.style;
  }

  @override
  int get hashCode => Object.hash(visible, initiallyVisible, options, style);
}

/// Configuration for the grid header region and its column-header behavior.
class FdcGridHeader {
  /// Creates a [FdcGridHeader].
  const FdcGridHeader({
    this.visible = true,
    this.height = 46,
    this.filters = const FdcGridHeaderFilters(),
    this.style = const FdcGridHeaderStyle(),
  });

  /// Controls whether the header component is rendered.
  final bool visible;

  /// Height of the leaf column header band.
  final double height;

  /// Header filter row configuration.
  final FdcGridHeaderFilters filters;

  /// Visual styling applied to the header component.
  final FdcGridHeaderStyle style;

  /// Creates a copy with selected values replaced.
  FdcGridHeader copyWith({
    bool? visible,
    double? height,
    FdcGridHeaderFilters? filters,
    FdcGridHeaderStyle? style,
  }) {
    return FdcGridHeader(
      visible: visible ?? this.visible,
      height: height ?? this.height,
      filters: filters ?? this.filters,
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridHeader &&
            visible == other.visible &&
            height == other.height &&
            filters == other.filters &&
            style == other.style;
  }

  @override
  int get hashCode => Object.hash(visible, height, filters, style);
}

/// Configuration for the optional toolbar displayed with an `FdcGrid`.
class FdcGridToolbar {
  /// Creates a [FdcGridToolbar].
  const FdcGridToolbar({
    this.visible = true,
    this.style,
    this.items = const <FdcGridItem>[FdcGridSearchBar()],
  });

  /// Controls whether the toolbar component is rendered.
  ///
  /// The default is true, so a grid renders the built-in toolbar search without
  /// requiring explicit toolbar configuration.
  final bool visible;

  /// Visual styling applied to the toolbar component.
  final FdcGridToolbarStyle? style;

  /// Ordered toolbar item list.
  ///
  /// Every toolbar component, including built-in search and export commands, is
  /// represented as an item. The list order is preserved inside each placement
  /// zone, so applications get full control over toolbar command ordering.
  final List<FdcGridItem> items;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridToolbar &&
            visible == other.visible &&
            style == other.style &&
            listEquals(items, other.items);
  }

  @override
  int get hashCode => Object.hash(visible, style, Object.hashAll(items));
}

/// Built-in toolbar item that exposes the grid main menu.
///
/// When a visible [FdcGridMainMenuButton] is present in a visible
/// [FdcGridToolbar], the grid hides the duplicate main menu from the header.
class FdcGridMainMenuButton extends FdcGridItem {
  /// Creates a [FdcGridMainMenuButton].
  const FdcGridMainMenuButton({
    super.id,
    super.visible = true,
    super.placement = FdcGridItemPlacement.start,
    this.label,
    this.tooltip = defaultTooltip,
  });

  /// Default toolbar/main-menu tooltip.
  static const defaultTooltip = 'Main menu';

  /// Optional toolbar button label. When omitted, an icon-only button is shown.
  final String? label;

  /// Toolbar/main-menu tooltip.
  final String tooltip;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridMainMenuButton &&
            id == other.id &&
            visible == other.visible &&
            placement == other.placement &&
            label == other.label &&
            tooltip == other.tooltip;
  }

  @override
  int get hashCode => Object.hash(id, visible, placement, label, tooltip);
}

/// Called after the built-in grid export command has generated an [FdcExportResult].
typedef FdcGridExportCompleted = void Function(FdcExportResult result);

/// Source used by the built-in grid toolbar export command.
enum FdcGridExportColumnMode {
  /// Export dataset field definitions, independent of current grid columns.
  dataSetFields,

  /// Export currently visible grid columns in runtime grid order.
  visibleColumns,
}

/// Built-in toolbar item that exports dataset rows through the FDC export pipeline.
class FdcGridExportButton extends FdcGridItem {
  /// Creates a [FdcGridExportButton].
  const FdcGridExportButton({
    super.id,
    super.visible = false,
    super.placement = FdcGridItemPlacement.start,
    this.formats,
    this.scope = FdcExportScope.currentView,
    this.valueMode = FdcExportValueMode.raw,
    this.columnMode = FdcGridExportColumnMode.visibleColumns,
    this.includeHeaders = true,
    this.includeNonPersistentFields = false,
    this.writerOptions = const <FdcExportFormat, FdcExportWriterOptions>{},
    this.label,
    this.tooltip = defaultTooltip,
    this.onExport,
  });

  /// Default toolbar/export menu tooltip.
  static const defaultTooltip = 'Export';

  /// Formats shown in the built-in export menu.
  ///
  /// When `null`, every format currently registered in [FdcExportRegistry] is
  /// shown. A non-null list restricts the menu to exactly those formats. An
  /// empty list disables the export item.
  final List<FdcExportFormat>? formats;

  /// Effective formats shown by the built-in export menu.
  List<FdcExportFormat> get effectiveFormats =>
      List<FdcExportFormat>.unmodifiable(
        formats == null
            ? FdcExportRegistry.formats
            : <FdcExportFormat>{...formats!},
      );

  /// Dataset row scope exported by the built-in grid command.
  final FdcExportScope scope;

  /// Value conversion used by the built-in grid command.
  final FdcExportValueMode valueMode;

  /// Column source used by the built-in grid command.
  ///
  /// [FdcGridExportColumnMode.visibleColumns] exports only visible grid
  /// columns in runtime grid order. [FdcGridExportColumnMode.dataSetFields]
  /// delegates column resolution to [FdcExporter] and uses dataset fields.
  final FdcGridExportColumnMode columnMode;

  /// Includes column labels as the first row when the selected writer format supports headers.
  final bool includeHeaders;

  /// Includes calculated/non-persistent dataset fields in dataset-level export.
  ///
  /// Grid-visible column export remains a later adapter step; this flag keeps
  /// the current dataset-backed toolbar export aligned with [FdcExporter].
  final bool includeNonPersistentFields;

  /// Per-format writer options applied only by this export button.
  final Map<FdcExportFormat, FdcExportWriterOptions> writerOptions;

  /// Optional toolbar button label. When omitted, an icon-only button is shown.
  final String? label;

  /// Toolbar/export menu tooltip.
  final String tooltip;

  /// Called with the generated text export result.
  ///
  /// The core package intentionally does not save files directly, so apps can
  /// route the result to download/share/file-picker code appropriate for the
  /// target platform.
  final FdcGridExportCompleted? onExport;

  /// Builds dataset export options from this toolbar configuration and optional resolved [columns].
  FdcExportOptions toExportOptions({List<FdcExportColumn>? columns}) {
    return FdcExportOptions(
      scope: scope,
      valueMode: valueMode,
      includeHeaders: includeHeaders,
      includeNonPersistentFields: includeNonPersistentFields,
      columns: columns ?? const <FdcExportColumn>[],
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridExportButton &&
            id == other.id &&
            visible == other.visible &&
            placement == other.placement &&
            listEquals(formats, other.formats) &&
            scope == other.scope &&
            valueMode == other.valueMode &&
            columnMode == other.columnMode &&
            includeHeaders == other.includeHeaders &&
            includeNonPersistentFields == other.includeNonPersistentFields &&
            mapEquals(writerOptions, other.writerOptions) &&
            label == other.label &&
            tooltip == other.tooltip &&
            onExport == other.onExport;
  }

  @override
  int get hashCode => Object.hash(
    id,
    visible,
    placement,
    formats == null ? null : Object.hashAll(formats!),
    scope,
    valueMode,
    columnMode,
    includeHeaders,
    includeNonPersistentFields,
    Object.hashAllUnordered(
      writerOptions.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    label,
    tooltip,
    onExport,
  );
}

/// Configuration for the grid summary region and aggregate presentation.
class FdcGridSummary {
  /// Creates a [FdcGridSummary].
  const FdcGridSummary({
    this.visible = true,
    this.style = const FdcGridSummaryStyle(),
  });

  /// Controls whether the grid summary component may be rendered.
  ///
  /// Defaults to `true`. The grid still hides the panel automatically when no
  /// visible column has an active summary aggregate.
  final bool visible;

  /// Visual styling applied to the summary component.
  final FdcGridSummaryStyle style;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridSummary &&
            visible == other.visible &&
            style == other.style;
  }

  @override
  int get hashCode => Object.hash(visible, style);
}

/// Configures the optional grid status bar and its ordered item collection.
class FdcGridStatusBar {
  /// Creates a [FdcGridStatusBar].
  const FdcGridStatusBar({
    this.visible = false,
    this.height,
    this.style = const FdcGridStatusBarStyle(),
    this.items = const <FdcGridItem>[FdcGridStatusText(), FdcGridProgressBar()],
  });

  /// Controls whether the status bar component is rendered.
  ///
  /// The default is false to preserve the grid's compact default layout.
  final bool visible;

  /// Fixed status bar height.
  ///
  /// When omitted, the height is resolved from [style] and then from the
  /// default status bar style.
  final double? height;

  /// Visual styling applied to the status bar component.
  final FdcGridStatusBarStyle style;

  /// Ordered status bar item list.
  ///
  /// Items are grouped into start, center, and end placement zones while
  /// preserving their list order inside each zone.
  final List<FdcGridItem> items;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridStatusBar &&
            visible == other.visible &&
            height == other.height &&
            style == other.style &&
            listEquals(items, other.items);
  }

  @override
  int get hashCode =>
      Object.hash(visible, height, style, Object.hashAll(items));
}

/// Toolbar UI mode for the built-in grid search item.
enum FdcGridSearchBarMode {
  /// Shows only the search field and clear action.
  ///
  /// The configured [FdcGridSearchBar.matchMode] and
  /// [FdcGridSearchBar.caseSensitive] values still define how search is
  /// applied, but end users cannot change them from the toolbar UI.
  simple,

  /// Shows search field, case-sensitivity toggle, and match-mode menu.
  advanced,
}

/// Built-in toolbar item for dataset-wide grid search.
class FdcGridSearchBar extends FdcGridItem {
  /// Creates a [FdcGridSearchBar].
  const FdcGridSearchBar({
    super.id,
    super.visible = true,
    super.placement = FdcGridItemPlacement.start,
    this.mode = FdcGridSearchBarMode.advanced,
    this.matchMode = FdcSearchMode.anyWord,
    this.caseSensitive = false,
    this.debounceDuration = const Duration(milliseconds: 350),
    this.debouncePolicy = FdcDebouncePolicy.adaptive,
  });

  /// Toolbar search UI mode.
  ///
  /// [FdcGridSearchBarMode.simple] hides the case-sensitivity toggle and
  /// search-mode menu. [FdcGridSearchBarMode.advanced] exposes both
  /// controls to the user.
  final FdcGridSearchBarMode mode;

  /// Global search match mode used by the built-in toolbar search box.
  final FdcSearchMode matchMode;

  /// Case sensitivity used by the built-in toolbar search box.
  final bool caseSensitive;

  /// Base/minimum debounce applied before toolbar search changes are sent to
  /// the dataset.
  ///
  /// When [debouncePolicy] is [FdcDebouncePolicy.adaptive], the effective
  /// delay may grow internally but is guarded to stay within a bounded range.
  final Duration debounceDuration;

  /// Controls how toolbar search input is applied.
  ///
  /// [FdcDebouncePolicy.disabled] keeps text edits local until the search field
  /// is submitted explicitly, for example with Enter/Search.
  final FdcDebouncePolicy debouncePolicy;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcGridSearchBar &&
            id == other.id &&
            visible == other.visible &&
            placement == other.placement &&
            mode == other.mode &&
            matchMode == other.matchMode &&
            caseSensitive == other.caseSensitive &&
            debounceDuration == other.debounceDuration &&
            debouncePolicy == other.debouncePolicy;
  }

  @override
  int get hashCode => Object.hash(
    id,
    visible,
    placement,
    mode,
    matchMode,
    caseSensitive,
    debounceDuration,
    debouncePolicy,
  );
}
