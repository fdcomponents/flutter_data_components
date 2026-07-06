// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../app/fdc_app.dart';
import '../../common/menu/fdc_menu.dart';
import '../../i18n/fdc_translations.dart';
import '../columns/fdc_grid_columns.dart';
import '../models/fdc_grid_internal_models.dart';
import 'fdc_grid_header_hover_icon.dart';
import 'fdc_grid_header_metrics.dart';
import 'header_filters/fdc_grid_header_filter_menu_builder.dart';

class FdcGridHeaderMainMenuButton extends StatelessWidget {
  const FdcGridHeaderMainMenuButton({super.key, required this.callbacks});

  final FdcGridHeaderCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final iconColor = callbacks.filterIconColorOf(context, active: false);

    return SizedBox(
      width: FdcGridHeaderMetrics.menuButtonWidth,
      height: FdcGridHeaderMetrics.headerControlHeight,
      child: FdcMenuAnchor(
        openOnTap: true,
        materialFeedback: true,
        openOnSecondaryTap: false,
        consumeSecondaryTap: false,
        canOpen: callbacks.onOpenHeaderMenu,
        entries: FdcGridHeaderMainMenuEntries(
          callbacks,
          translations: FdcApp.translationsOf(context),
        ).build(),
        child: Center(
          child: FdcGridHeaderHoverIcon(
            icon: Icons.menu,
            size: FdcGridHeaderMetrics.menuIconSize,
            color: iconColor,
            enabled: true,
          ),
        ),
      ),
    );
  }
}

class FdcGridSelectionFilterMenuEntries {
  const FdcGridSelectionFilterMenuEntries(
    this.callbacks, {
    this.translations = const FdcTranslations(),
  });

  final FdcGridHeaderCallbacks callbacks;
  final FdcTranslations translations;

  List<FdcMenuEntry> build() {
    final value = callbacks.rowSelectionFilterValue();
    final canView = callbacks.canChangeView();
    return <FdcMenuEntry>[
      FdcMenuCheckAction(
        text: translations.grid.showSelectedRows,
        checked: value == true,
        icon: Icons.check_box_outlined,
        enabled: canView,
        onPressed: canView
            ? () => callbacks.onSetRowSelectionFilter(true)
            : null,
      ),
      FdcMenuCheckAction(
        text: translations.grid.showUnselectedRows,
        checked: value == false,
        icon: Icons.check_box_outline_blank,
        enabled: canView,
        onPressed: canView
            ? () => callbacks.onSetRowSelectionFilter(false)
            : null,
      ),
      const FdcMenuSeparator(),
      FdcMenuAction(
        text: translations.grid.clearSelectionFilter,
        icon: Icons.filter_alt_off,
        enabled: value != null && canView,
        onPressed: value == null || !canView
            ? null
            : () => callbacks.onSetRowSelectionFilter(null),
      ),
    ];
  }
}

class FdcGridHeaderMainMenuEntries {
  const FdcGridHeaderMainMenuEntries(
    this.callbacks, {
    this.translations = const FdcTranslations(),
  });

  final FdcGridHeaderCallbacks callbacks;
  final FdcTranslations translations;

  bool get hasSortActions => callbacks.hasDataSetSortState();
  bool get hasColumnFilterActions => callbacks.canToggleColumnFilters();
  bool get hasSelectionFilterActions =>
      hasColumnFilterActions && callbacks.hasRowSelectionControls();
  bool get hasClearFilterAction =>
      hasColumnFilterActions && callbacks.hasHeaderFilterState();
  bool get hasUnpinAllColumnsAction => callbacks.hasUserPinnedColumns();
  bool get hasResetLayoutAction => callbacks.hasGridLayoutChanges();

  bool get hasActions =>
      hasSortActions ||
      hasColumnFilterActions ||
      hasSelectionFilterActions ||
      hasClearFilterAction ||
      hasUnpinAllColumnsAction ||
      hasResetLayoutAction;

  List<FdcMenuEntry> build({
    bool includeEmptyState = true,
    bool includeFilterVisibilityToggle = true,
  }) {
    final entries = <FdcMenuEntry>[];

    _addClearSorts(entries);
    _addRowSelectionFilterSubMenu(entries);
    if (includeFilterVisibilityToggle) {
      _addFilterVisibilityToggle(entries);
    }
    _addClearFilters(entries);
    _addUnpinAllColumns(entries);
    _addResetLayout(entries);

    if (!hasActions && includeEmptyState) {
      entries.add(
        FdcMenuAction(
          text: translations.grid.noActionsAvailable,
          icon: Icons.info_outline,
          enabled: false,
        ),
      );
    }

    return entries;
  }

  void _addClearSorts(List<FdcMenuEntry> entries) {
    if (!hasSortActions) {
      return;
    }

    entries.add(
      FdcMenuAction(
        text: translations.grid.clearAllSorts,
        icon: Icons.clear_all,
        enabled: callbacks.canChangeView(),
        onPressed: callbacks.canChangeView()
            ? callbacks.onHeaderClearAllSorts
            : null,
      ),
    );
  }

  void _addRowSelectionFilterSubMenu(List<FdcMenuEntry> entries) {
    if (!hasSelectionFilterActions) {
      return;
    }

    final children = FdcGridSelectionFilterMenuEntries(
      callbacks,
      translations: translations,
    ).build();

    entries.add(
      FdcSubMenu(
        text: translations.grid.filters,
        icon: Icons.grading_outlined,
        children: children,
        enabled: callbacks.canChangeView(),
      ),
    );
  }

  void _addFilterVisibilityToggle(List<FdcMenuEntry> entries) {
    if (!hasColumnFilterActions) {
      return;
    }

    final filtersVisible = callbacks.columnFiltersVisible();
    final hideWouldClearFilters =
        filtersVisible && callbacks.hasHeaderFilterState();
    final enabled = !hideWouldClearFilters || callbacks.canChangeView();
    entries.add(
      FdcMenuAction(
        text: filtersVisible
            ? translations.grid.hideFilters
            : translations.grid.showFilters,
        icon: filtersVisible ? Icons.visibility_off : Icons.visibility,
        enabled: enabled,
        onPressed: enabled ? callbacks.onToggleColumnFilters : null,
      ),
    );
  }

  void _addClearFilters(List<FdcMenuEntry> entries) {
    if (!hasClearFilterAction) {
      return;
    }

    entries.add(
      FdcMenuAction(
        text: translations.grid.clearFilters,
        icon: Icons.filter_alt_off,
        enabled: callbacks.canChangeView(),
        onPressed: callbacks.canChangeView()
            ? callbacks.onClearHeaderFilters
            : null,
      ),
    );
  }

  void _addUnpinAllColumns(List<FdcMenuEntry> entries) {
    if (!hasUnpinAllColumnsAction) {
      return;
    }

    entries.add(
      FdcMenuAction(
        text: translations.grid.unpinAllColumns,
        icon: Icons.push_pin_outlined,
        onPressed: callbacks.onUnpinAllUserColumns,
      ),
    );
  }

  void _addResetLayout(List<FdcMenuEntry> entries) {
    if (!hasResetLayoutAction) {
      return;
    }

    _addResetLayoutSeparatorIfNeeded(entries);
    entries.add(
      FdcMenuAction(
        text: translations.grid.resetGridLayout,
        icon: Icons.restart_alt,
        onPressed: callbacks.onResetGridLayout,
      ),
    );
  }

  void _addResetLayoutSeparatorIfNeeded(List<FdcMenuEntry> entries) {
    if (entries.isNotEmpty) {
      entries.add(const FdcMenuSeparator());
    }
  }
}

class FdcGridHeaderColumnMenuState {
  const FdcGridHeaderColumnMenuState({
    required this.sortedAscending,
    required this.sortedDescending,
    required this.sortCount,
    required this.pin,
  });

  final bool sortedAscending;
  final bool sortedDescending;
  final int sortCount;
  final FdcGridColumnPin pin;

  bool get sorted => sortedAscending || sortedDescending;
  bool get hasAnySort => sortCount > 0;
  bool get hasMultipleSorts => sortCount > 1;
  bool get isPinned => pin.isPinned;
  bool get canChangePin => !pin.isFixed;
  bool get canUnpin => isPinned && canChangePin;

  bool get shouldShowAdditiveSortActions => !sorted && hasAnySort;
  bool get shouldShowClearSortAction => sorted;
  bool get shouldShowClearAllSortsAction => hasMultipleSorts;
  bool get shouldShowPinActions => canChangePin;
  bool get shouldShowUnpinAction => canUnpin;
  bool get shouldShowSortAscendingAction => !sortedAscending;
  bool get shouldShowSortDescendingAction => !sortedDescending;
}

class FdcGridHeaderColumnMenuButton extends StatelessWidget {
  const FdcGridHeaderColumnMenuButton({
    super.key,
    required this.callbacks,
    required this.columnIndex,
    required this.column,
    required this.runtimeColumnId,
    required this.includeMainMenuEntries,
  });

  final FdcGridHeaderCallbacks callbacks;
  final int columnIndex;
  final FdcGridColumn<dynamic> column;
  final FdcColumnIdentity? runtimeColumnId;
  final bool includeMainMenuEntries;

  @override
  Widget build(BuildContext context) {
    final iconColor = callbacks.filterIconColorOf(context, active: false);

    return SizedBox(
      width: FdcGridHeaderMetrics.menuButtonWidth,
      height: FdcGridHeaderMetrics.headerControlHeight,
      child: FdcMenuAnchor(
        openOnTap: true,
        materialFeedback: true,
        openOnSecondaryTap: false,
        consumeSecondaryTap: false,
        canOpen: callbacks.onOpenHeaderMenu,
        entries: FdcGridHeaderColumnMenuEntries(
          callbacks: callbacks,
          columnIndex: columnIndex,
          column: column,
          runtimeColumnId: runtimeColumnId,
          includeMainMenuEntries: includeMainMenuEntries,
          textDirection: Directionality.of(context),
          translations: FdcApp.translationsOf(context),
        ).build(),
        child: Center(
          child: FdcGridHeaderHoverIcon(
            icon: Icons.more_vert,
            size: FdcGridHeaderMetrics.menuIconSize,
            color: iconColor,
            enabled: true,
          ),
        ),
      ),
    );
  }
}

class FdcGridHeaderColumnMenuEntries {
  const FdcGridHeaderColumnMenuEntries({
    required this.callbacks,
    required this.columnIndex,
    required this.column,
    required this.runtimeColumnId,
    required this.includeMainMenuEntries,
    this.textDirection = TextDirection.ltr,
    this.translations = const FdcTranslations(),
  });

  final FdcGridHeaderCallbacks callbacks;
  final int columnIndex;
  final FdcGridColumn<dynamic> column;
  final FdcColumnIdentity? runtimeColumnId;
  final bool includeMainMenuEntries;
  final TextDirection textDirection;
  final FdcTranslations translations;

  bool get hasColumnSortActions => callbacks.canHeaderSort(columnIndex);
  bool get hasColumnPinActions =>
      callbacks.canHeaderColumnPin(columnIndex) &&
      _menuState.shouldShowPinActions;
  bool get hasFilterActions =>
      column.filterEnabled &&
      runtimeColumnId != null &&
      callbacks.canToggleColumnFilters();
  bool get hasMainMenuActions =>
      includeMainMenuEntries &&
      FdcGridHeaderMainMenuEntries(
        callbacks,
        translations: translations,
      ).hasActions;

  bool get hasColumnActions =>
      hasColumnSortActions || hasFilterActions || hasColumnPinActions;

  bool get hasActions => hasColumnActions || hasMainMenuActions;

  List<FdcMenuEntry> build() {
    final state = _menuState;
    final entries = <FdcMenuEntry>[];

    if (hasColumnSortActions) {
      _addSortSubMenu(entries, state);
    }

    if (hasFilterActions) {
      _addFilterEntries(entries);
    }

    if (hasColumnPinActions) {
      _addPinSubMenu(entries, state);
    }

    _addMainMenuEntries(entries);

    return entries;
  }

  void _addFilterEntries(List<FdcMenuEntry> entries) {
    final runtimeId = runtimeColumnId;
    if (runtimeId == null || !column.filterEnabled) {
      return;
    }

    final filtersVisible = callbacks.columnFiltersVisible();
    final hideWouldClearFilters =
        filtersVisible && callbacks.hasHeaderFilterState();
    final canToggleFilters =
        !hideWouldClearFilters || callbacks.canChangeView();
    final filterEntries = filtersVisible && callbacks.canOpenFilterMenu()
        ? FdcGridHeaderFilterMenuBuilder(
            callbacks: callbacks,
            column: column,
            runtimeColumnId: runtimeId,
            translations: translations,
          ).buildEntries()
        : const <FdcMenuEntry>[];

    if (entries.isNotEmpty && !filtersVisible) {
      entries.add(const FdcMenuSeparator());
    }
    entries.add(
      FdcMenuAction(
        text: filtersVisible
            ? translations.grid.hideFilters
            : translations.grid.showFilters,
        icon: filtersVisible ? Icons.visibility_off : Icons.visibility,
        enabled: canToggleFilters,
        onPressed: canToggleFilters ? callbacks.onToggleColumnFilters : null,
      ),
    );
    if (filterEntries.isNotEmpty) {
      entries.add(const FdcMenuSeparator());
      entries.add(FdcMenuTitle(text: translations.grid.filters));
      entries.addAll(filterEntries);
    }
  }

  void _addMainMenuEntries(List<FdcMenuEntry> entries) {
    if (!includeMainMenuEntries) {
      return;
    }

    final mainMenuEntries = FdcGridHeaderMainMenuEntries(
      callbacks,
      translations: translations,
    ).build(includeEmptyState: false, includeFilterVisibilityToggle: false);

    if (mainMenuEntries.isEmpty) {
      return;
    }

    if (entries.isNotEmpty) {
      entries.add(const FdcMenuSeparator());
    }
    entries.addAll(mainMenuEntries);
  }

  FdcGridHeaderColumnMenuState get _menuState {
    return FdcGridHeaderColumnMenuState(
      sortedAscending: callbacks.isHeaderSortAscending(columnIndex),
      sortedDescending: callbacks.isHeaderSortDescending(columnIndex),
      sortCount: callbacks.headerSortCount(),
      pin: callbacks.headerColumnPinOf(columnIndex),
    );
  }

  void _addSortSubMenu(
    List<FdcMenuEntry> entries,
    FdcGridHeaderColumnMenuState state,
  ) {
    final sortEntries = <FdcMenuEntry>[];
    _addSortEntries(sortEntries, state);
    _addClearColumnSortEntry(sortEntries, state);
    _addClearAllSortsEntry(sortEntries, state);
    if (sortEntries.isEmpty) {
      return;
    }

    entries.add(
      FdcSubMenu(
        text: translations.grid.sorting,
        icon: Icons.sort,
        children: sortEntries,
      ),
    );
  }

  void _addSortEntries(
    List<FdcMenuEntry> entries,
    FdcGridHeaderColumnMenuState state,
  ) {
    if (state.shouldShowAdditiveSortActions) {
      entries.addAll(<FdcMenuEntry>[
        FdcMenuAction(
          text: translations.grid.addAscendingSort,
          icon: Icons.north,
          enabled: callbacks.canChangeView(),
          onPressed: callbacks.canChangeView()
              ? () => callbacks.onHeaderAddSortAscending(columnIndex)
              : null,
        ),
        FdcMenuAction(
          text: translations.grid.addDescendingSort,
          icon: Icons.south,
          enabled: callbacks.canChangeView(),
          onPressed: callbacks.canChangeView()
              ? () => callbacks.onHeaderAddSortDescending(columnIndex)
              : null,
        ),
      ]);
      return;
    }

    if (state.shouldShowSortAscendingAction) {
      entries.add(
        FdcMenuAction(
          text: translations.grid.sortAscending,
          icon: Icons.north,
          enabled: callbacks.canChangeView(),
          onPressed: callbacks.canChangeView()
              ? () => callbacks.onHeaderSortAscending(columnIndex)
              : null,
        ),
      );
    }
    if (state.shouldShowSortDescendingAction) {
      entries.add(
        FdcMenuAction(
          text: translations.grid.sortDescending,
          icon: Icons.south,
          enabled: callbacks.canChangeView(),
          onPressed: callbacks.canChangeView()
              ? () => callbacks.onHeaderSortDescending(columnIndex)
              : null,
        ),
      );
    }
  }

  void _addClearColumnSortEntry(
    List<FdcMenuEntry> entries,
    FdcGridHeaderColumnMenuState state,
  ) {
    if (!state.shouldShowClearSortAction) {
      return;
    }

    entries.addAll(<FdcMenuEntry>[
      const FdcMenuSeparator(),
      FdcMenuAction(
        text: translations.grid.clearSort,
        icon: Icons.clear,
        enabled: callbacks.canChangeView(),
        onPressed: callbacks.canChangeView()
            ? () => callbacks.onHeaderClearSort(columnIndex)
            : null,
      ),
    ]);
  }

  void _addClearAllSortsEntry(
    List<FdcMenuEntry> entries,
    FdcGridHeaderColumnMenuState state,
  ) {
    if (!state.shouldShowClearAllSortsAction) {
      return;
    }

    entries.add(
      FdcMenuAction(
        text: translations.grid.clearAllSorts,
        icon: Icons.clear_all,
        enabled: callbacks.canChangeView(),
        onPressed: callbacks.canChangeView()
            ? callbacks.onHeaderClearAllSorts
            : null,
      ),
    );
  }

  void _addPinSubMenu(
    List<FdcMenuEntry> entries,
    FdcGridHeaderColumnMenuState state,
  ) {
    if (!state.shouldShowPinActions) {
      return;
    }

    final pinEntries = <FdcMenuEntry>[];
    _addPinEntries(pinEntries, state);
    if (pinEntries.isEmpty) {
      return;
    }

    if (callbacks.columnFiltersVisible() &&
        entries.isNotEmpty &&
        entries.last is! FdcMenuSeparator) {
      entries.add(const FdcMenuSeparator());
    }

    entries.add(
      FdcSubMenu(
        text: translations.grid.columnPinning,
        icon: Icons.push_pin,
        children: pinEntries,
      ),
    );
  }

  void _addPinEntries(
    List<FdcMenuEntry> entries,
    FdcGridHeaderColumnMenuState state,
  ) {
    final leftPin = textDirection == TextDirection.ltr
        ? FdcGridColumnPin.start
        : FdcGridColumnPin.end;
    final rightPin = textDirection == TextDirection.ltr
        ? FdcGridColumnPin.end
        : FdcGridColumnPin.start;

    entries.addAll(<FdcMenuEntry>[
      FdcMenuCheckAction(
        text: translations.grid.pinLeft,
        checked: state.pin == leftPin,
        icon: Icons.push_pin,
        onPressed: state.pin == leftPin
            ? null
            : () => callbacks.onSetHeaderColumnPin(columnIndex, leftPin),
      ),
      FdcMenuCheckAction(
        text: translations.grid.pinRight,
        checked: state.pin == rightPin,
        icon: Icons.push_pin,
        onPressed: state.pin == rightPin
            ? null
            : () => callbacks.onSetHeaderColumnPin(columnIndex, rightPin),
      ),
    ]);

    if (!state.shouldShowUnpinAction) {
      return;
    }

    entries.add(
      FdcMenuAction(
        text: translations.grid.unpin,
        icon: Icons.close,
        onPressed: () =>
            callbacks.onSetHeaderColumnPin(columnIndex, FdcGridColumnPin.none),
      ),
    );
  }
}
