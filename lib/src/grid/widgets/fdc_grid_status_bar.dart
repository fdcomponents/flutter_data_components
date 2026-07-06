// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/fdc_app.dart';
import '../../common/theme/fdc_grid_styles.dart';
import '../../common/widgets/progress/fdc_progress_widgets.dart';
import '../../data/fdc_data.dart';
import '../../i18n/fdc_translations.dart';
import '../core/fdc_grid_core.dart';
import 'fdc_grid_items.dart';
import 'fdc_grid_responsive_item_layout.dart';
import 'fdc_grid_status_bar_items.dart';
import 'toolbar/fdc_grid_paging_navigator.dart';

class FdcGridStatusBarShell extends StatelessWidget {
  const FdcGridStatusBarShell({
    super.key,
    required this.dataSet,
    required this.statusBar,
    required this.style,
    required this.separatorColor,
    required this.progressBarStyle,
  });

  final FdcDataSet dataSet;
  final FdcGridStatusBar statusBar;
  final FdcGridStatusBarStyle style;
  final Color separatorColor;
  final FdcProgressBarStyle progressBarStyle;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: dataSet,
      builder: (context, _) {
        final textStyle =
            style.textStyle ?? Theme.of(context).textTheme.bodySmall;
        final itemColor =
            textStyle?.color ?? Theme.of(context).colorScheme.onSurface;
        final disabledColor = itemColor.withValues(alpha: 0.45);

        return DecoratedBox(
          key: const ValueKey('fdc_grid_status_bar'),
          decoration: BoxDecoration(
            color: style.backgroundColor,
            border: Border(top: BorderSide(color: separatorColor)),
          ),
          child: Padding(
            padding:
                style.padding ??
                FdcGridStatusBarStyle.defaults.padding ??
                const EdgeInsets.symmetric(horizontal: 10),
            child: Theme(
              data: Theme.of(context).copyWith(
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: itemColor,
                    disabledForegroundColor: disabledColor,
                    textStyle: textStyle,
                  ),
                ),
                iconButtonTheme: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    foregroundColor: itemColor,
                    disabledForegroundColor: disabledColor,
                  ),
                ),
              ),
              child: FdcGridItemTheme(
                textStyle: textStyle ?? const TextStyle(fontSize: 12),
                textColor: itemColor,
                iconColor: itemColor,
                disabledTextColor: disabledColor,
                disabledIconColor: disabledColor,
                child: DefaultTextStyle.merge(
                  style: textStyle?.copyWith(color: itemColor),
                  child: IconTheme.merge(
                    data: IconThemeData(size: 16, color: itemColor),
                    child: LayoutBuilder(
                      builder: (context, constraints) =>
                          _buildItems(context, constraints.maxWidth),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItems(BuildContext context, double maxWidth) {
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

    for (final item in statusBar.items) {
      if (!item.visible) continue;
      if (item is FdcGridPagingNavigator && dataSet.paging.isInfinite) {
        continue;
      }
      addItem(item.placement, _buildItem(context, item, maxWidth));
    }

    return FdcGridResponsiveItemLayout(
      startItems: startItems,
      centerItems: centerItems,
      endItems: endItems,
    );
  }

  Widget _buildItem(BuildContext context, FdcGridItem item, double maxWidth) {
    if (item is FdcGridStatusText) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Text(
          _statusText(context, dataSet),
          key: item.id == null
              ? const ValueKey('fdc_grid_status_text')
              : ValueKey<String>('fdc_grid_status_text_${item.id}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    if (item is FdcGridProgressBar) {
      final width = math.min(
        item.width ?? FdcGridProgressBar.defaultWidth,
        maxWidth,
      );
      return FdcProgressBar(
        key: item.id == null
            ? const ValueKey('fdc_grid_status_progress')
            : ValueKey<String>('fdc_grid_status_progress_${item.id}'),
        dataSet: dataSet,
        width: width,
        style: progressBarStyle.merge(item.style),
      );
    }
    if (dataSet.paging.isInfinite) {
      if (item is FdcGridPagingNavigator ||
          item is FdcGridPagingRecordInfo ||
          item is FdcGridPageSizeSelector) {
        return const SizedBox.shrink();
      }
    }
    if (item is FdcGridPagingNavigator) {
      return item.buildForDataSet(context, dataSet);
    }
    if (item is FdcGridPagingRecordInfo) {
      return item.buildForDataSet(context, dataSet);
    }
    if (item is FdcGridPageSizeSelector) {
      return item.buildForDataSet(context, dataSet);
    }
    return item.buildItem(context);
  }

  String _statusText(BuildContext context, FdcDataSet dataSet) {
    final translations = FdcApp.translationsOf(context).grid;
    final parts = <String>[
      _recordText(dataSet, translations),
      '${translations.state}: ${_stateText(dataSet.state, translations)}',
    ];
    if (dataSet.filter.active) parts.add(translations.filtered);
    if (dataSet.sort.active) parts.add(translations.sorted);
    return parts.join(' · ');
  }

  String _recordText(FdcDataSet dataSet, FdcGridTranslations translations) {
    final recordCount = dataSet.recordCount;
    if (recordCount == 0) return translations.noRecords;
    final localRecordNumber = dataSet.recordNumber;
    final safeLocalRecordNumber = localRecordNumber < 1 ? 1 : localRecordNumber;
    if (!dataSet.paging.enabled) {
      return translations.record(safeLocalRecordNumber, recordCount);
    }
    final globalRecordNumber = dataSet.paging.isInfinite
        ? safeLocalRecordNumber
        : dataSet.paging.pageOffset + safeLocalRecordNumber;
    return translations.record(
      globalRecordNumber,
      dataSet.paging.totalRecordCount,
    );
  }

  String _stateText(FdcDataSetState state, FdcGridTranslations translations) {
    switch (state) {
      case FdcDataSetState.closed:
        return translations.closed;
      case FdcDataSetState.browse:
        return translations.browse;
      case FdcDataSetState.edit:
        return translations.edit;
      case FdcDataSetState.insert:
        return translations.insert;
      case FdcDataSetState.loading:
        return translations.loading;
      case FdcDataSetState.applyingUpdates:
        return translations.applyingUpdates;
    }
  }
}
