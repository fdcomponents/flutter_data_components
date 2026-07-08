// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/fdc_app.dart';
import '../../common/menu/fdc_menu.dart';
import '../../common/theme/fdc_grid_styles.dart';
import '../../data/fdc_dataset.dart';
import '../../data/fdc_dataset_search.dart';
import '../../exports/fdc_export.dart';
import '../core/fdc_grid_core.dart';
import '../models/fdc_grid_header_models.dart';
import 'fdc_grid_header_menus.dart';
import 'fdc_grid_items.dart';
import 'fdc_grid_responsive_item_layout.dart';
import 'fdc_grid_toolbar_items.dart';
import 'fdc_grid_toolbar_search.dart';

export 'fdc_grid_toolbar_search.dart' show FdcGridToolbarSearchController;

class FdcGridToolbarShell extends StatelessWidget {
  const FdcGridToolbarShell({
    super.key,
    this.searchController,
    required this.style,
    required this.separatorColor,
    required this.toolbar,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.recordCountProvider,
    required this.dataSet,
    required this.canSearch,
    required this.canExport,
    this.headerCallbacks,
    this.onExportRequested,
  });

  final FdcGridToolbarSearchController? searchController;
  final FdcGridToolbarStyle style;
  final Color separatorColor;
  final FdcGridToolbar toolbar;
  final void Function(
    String text, {
    required FdcSearchMode mode,
    required bool caseSensitive,
  })
  onSearchChanged;
  final VoidCallback onSearchCleared;
  final int Function() recordCountProvider;
  final FdcDataSet dataSet;
  final bool canSearch;
  final bool canExport;
  final FdcGridHeaderCallbacks? headerCallbacks;
  final Future<void> Function(
    FdcGridExportButton button,
    FdcExportFormat format,
  )?
  onExportRequested;

  @override
  Widget build(BuildContext context) {
    final itemTheme = _resolveItemTheme(context);

    return Material(
      key: const ValueKey('fdc_grid_toolbar'),
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: style.backgroundColor,
          border: Border(bottom: BorderSide(color: separatorColor)),
        ),
        child: Padding(
          padding:
              style.padding ??
              FdcGridToolbarStyle.defaults.padding ??
              const EdgeInsets.symmetric(horizontal: 8),
          child: Theme(
            data: _resolveMaterialTheme(context, itemTheme),
            child: FdcGridItemTheme(
              textStyle: itemTheme.textStyle,
              textColor: itemTheme.textColor,
              iconColor: itemTheme.iconColor,
              disabledTextColor: itemTheme.disabledTextColor,
              disabledIconColor: itemTheme.disabledIconColor,
              child: DefaultTextStyle.merge(
                style: itemTheme.textStyle.copyWith(color: itemTheme.textColor),
                child: IconTheme.merge(
                  data: IconThemeData(size: 16, color: itemTheme.iconColor),
                  child: _buildItems(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ResolvedToolbarItemTheme _resolveItemTheme(BuildContext context) {
    final materialTheme = Theme.of(context);
    final fallbackTextStyle =
        materialTheme.textTheme.labelMedium ?? const TextStyle(fontSize: 14);
    final baseTextStyle = fallbackTextStyle.merge(style.textStyle);
    final textColor =
        style.itemTextColor ??
        baseTextStyle.color ??
        materialTheme.colorScheme.onSurface;
    final iconColor = style.itemIconColor ?? style.searchIconColor ?? textColor;
    final disabledTextColor =
        style.disabledItemTextColor ?? textColor.withValues(alpha: 0.45);
    final disabledIconColor =
        style.disabledItemIconColor ??
        style.disabledItemTextColor ??
        disabledTextColor;

    return _ResolvedToolbarItemTheme(
      textStyle: baseTextStyle.copyWith(color: textColor),
      textColor: textColor,
      iconColor: iconColor,
      disabledTextColor: disabledTextColor,
      disabledIconColor: disabledIconColor,
    );
  }

  ThemeData _resolveMaterialTheme(
    BuildContext context,
    _ResolvedToolbarItemTheme itemTheme,
  ) {
    final materialTheme = Theme.of(context);
    return materialTheme.copyWith(
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: itemTheme.textColor,
          disabledForegroundColor: itemTheme.disabledTextColor,
          textStyle: itemTheme.textStyle,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: itemTheme.iconColor,
          disabledForegroundColor: itemTheme.disabledIconColor,
        ),
      ),
    );
  }

  Widget _buildItems(BuildContext context) {
    final startItems = <Widget>[];
    final centerItems = <Widget>[];
    final endItems = <Widget>[];

    void addItem(FdcGridItemPlacement placement, Widget item) {
      switch (placement) {
        case FdcGridItemPlacement.start:
          startItems.add(item);
          break;
        case FdcGridItemPlacement.center:
          centerItems.add(item);
          break;
        case FdcGridItemPlacement.end:
          endItems.add(item);
          break;
      }
    }

    var hasSearchBar = false;
    var hasMainMenuButton = false;

    for (final item in toolbar.items) {
      if (item is FdcGridSearchBar) {
        if (hasSearchBar) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
              'FdcGridToolbar.items contains multiple FdcGridSearchBar items.',
            ),
            ErrorDescription(
              'Toolbar global search is a singleton grid feature, so a grid '
              'toolbar can contain at most one FdcGridSearchBar.',
            ),
            ErrorHint(
              'Keep one FdcGridSearchBar and use other toolbar item types for '
              'additional controls.',
            ),
          ]);
        }
        hasSearchBar = true;
      }

      if (item is FdcGridMainMenuButton) {
        if (hasMainMenuButton) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
              'FdcGridToolbar.items contains multiple FdcGridMainMenuButton items.',
            ),
            ErrorDescription(
              'The grid main menu is a singleton command surface, so a grid '
              'toolbar can contain at most one FdcGridMainMenuButton.',
            ),
            ErrorHint(
              'Keep one FdcGridMainMenuButton and use other toolbar item types '
              'for additional controls.',
            ),
          ]);
        }
        hasMainMenuButton = true;
      }

      if (!item.visible) {
        continue;
      }

      if (item is FdcGridSearchBar) {
        addItem(item.placement, _buildSearchItem(item));
      } else if (item is FdcGridExportButton) {
        addItem(
          item.placement,
          Builder(builder: (context) => _buildExportItem(context, item)),
        );
      } else if (item is FdcGridMainMenuButton) {
        addItem(
          item.placement,
          Builder(builder: (context) => _buildMainMenuItem(context, item)),
        );
      } else if (item is FdcGridPagingNavigator ||
          item is FdcGridPagingRecordInfo ||
          item is FdcGridPageSizeSelector) {
        if (!dataSet.paging.isInfinite) {
          addItem(
            item.placement,
            Builder(
              builder: (context) => switch (item) {
                final FdcGridPagingNavigator value => value.buildForDataSet(
                  context,
                  dataSet,
                ),
                final FdcGridPagingRecordInfo value => value.buildForDataSet(
                  context,
                  dataSet,
                ),
                final FdcGridPageSizeSelector value => value.buildForDataSet(
                  context,
                  dataSet,
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          );
        }
      } else {
        addItem(item.placement, Builder(builder: item.buildItem));
      }
    }

    return FdcGridResponsiveItemLayout(
      startItems: startItems,
      centerItems: centerItems,
      endItems: endItems,
    );
  }

  Widget _buildMainMenuItem(
    BuildContext context,
    FdcGridMainMenuButton button,
  ) {
    final callbacks = headerCallbacks;
    if (callbacks == null) {
      throw StateError(
        'FdcGridToolbarShell requires headerCallbacks to render '
        'FdcGridMainMenuButton.',
      );
    }

    final menuEntries = FdcGridHeaderMainMenuEntries(
      callbacks,
      translations: FdcApp.translationsOf(context),
    );
    if (!menuEntries.hasActions) {
      return const SizedBox.shrink();
    }

    final itemTheme = FdcGridItemTheme.of(context);
    final label = button.label;
    final key = button.id == null
        ? const ValueKey('fdc_grid_toolbar_main_menu_button')
        : ValueKey<String>('fdc_grid_toolbar_main_menu_button_${button.id}');
    final entries = menuEntries.build();
    final child = label == null
        ? SizedBox(
            key: key,
            width: 32,
            height: 32,
            child: Icon(Icons.menu, size: 16, color: itemTheme.iconColor),
          )
        : Padding(
            key: key,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu, size: 16, color: itemTheme.iconColor),
                const SizedBox(width: 6),
                Text(label, style: itemTheme.textStyle),
              ],
            ),
          );

    final defaultTooltip =
        button.tooltip == FdcGridMainMenuButton.defaultTooltip
        ? FdcApp.translationsOf(context).grid.mainMenu
        : button.tooltip;

    return Tooltip(
      message: defaultTooltip,
      excludeFromSemantics: true,
      child: FdcMenuAnchor(
        openOnTap: true,
        openOnSecondaryTap: false,
        consumeSecondaryTap: false,
        materialFeedback: true,
        canOpen: callbacks.onOpenHeaderMenu,
        entries: entries,
        child: child,
      ),
    );
  }

  Widget _buildExportItem(BuildContext context, FdcGridExportButton button) {
    final itemTheme = FdcGridItemTheme.of(context);
    final enabled =
        canExport &&
        button.effectiveFormats.isNotEmpty &&
        button.onExport != null &&
        onExportRequested != null;
    final iconColor = enabled
        ? itemTheme.iconColor
        : itemTheme.disabledIconColor;
    final label = button.label;
    final entries = <FdcMenuEntry>[
      for (final format in button.effectiveFormats)
        FdcMenuAction(
          text: FdcApp.translationsOf(context).grid.exportTo(format.label),
          icon: format.icon ?? Icons.insert_drive_file_outlined,
          enabled: enabled,
          onPressed: enabled
              ? () {
                  final exportRequested = onExportRequested;
                  if (exportRequested == null) {
                    return;
                  }
                  unawaited(exportRequested(button, format));
                }
              : null,
        ),
    ];

    final child = label == null
        ? SizedBox(
            width: 32,
            height: 32,
            child: Icon(Icons.download_outlined, size: 16, color: iconColor),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_outlined, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: itemTheme.textStyle.copyWith(
                    color: enabled
                        ? itemTheme.textColor
                        : itemTheme.disabledTextColor,
                  ),
                ),
              ],
            ),
          );

    final defaultTooltip = button.tooltip == FdcGridExportButton.defaultTooltip
        ? FdcApp.translationsOf(context).grid.export
        : button.tooltip;

    return Tooltip(
      message: defaultTooltip,
      excludeFromSemantics: true,
      child: FdcMenuAnchor(
        openOnTap: true,
        openOnSecondaryTap: false,
        consumeSecondaryTap: false,
        materialFeedback: true,
        canOpen: () => enabled,
        entries: entries,
        child: child,
      ),
    );
  }

  Widget _buildSearchItem(FdcGridSearchBar searchBar) {
    return FdcGridToolbarSearch(
      controller: searchController,
      style: style,
      onSearchChanged: onSearchChanged,
      onSearchCleared: onSearchCleared,
      mode: searchBar.mode,
      matchMode: searchBar.matchMode,
      caseSensitive: searchBar.caseSensitive,
      debounceDuration: searchBar.debounceDuration,
      debouncePolicy: searchBar.debouncePolicy,
      recordCountProvider: recordCountProvider,
      enabled: canSearch,
    );
  }
}

class _ResolvedToolbarItemTheme {
  const _ResolvedToolbarItemTheme({
    required this.textStyle,
    required this.textColor,
    required this.iconColor,
    required this.disabledTextColor,
    required this.disabledIconColor,
  });

  final TextStyle textStyle;
  final Color textColor;
  final Color iconColor;
  final Color disabledTextColor;
  final Color disabledIconColor;
}
