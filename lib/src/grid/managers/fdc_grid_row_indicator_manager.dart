// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import '../core/fdc_grid_core.dart';
import '../models/fdc_grid_row_indicator_models.dart';
import '../widgets/fdc_grid_header_metrics.dart';

class FdcGridRowIndicatorManager {
  FdcGridRowIndicatorLayout layout({
    required FdcGridOptions options,
    required FdcGridRowIndicator rowIndicator,
    required int rowCount,
    required bool showsFilterRow,
    bool mainMenuInToolbar = false,
  }) {
    if (!rowIndicator.visible) {
      return FdcGridRowIndicatorLayout.none;
    }

    final content = FdcGridRowIndicatorContent.fromOptions(
      rowIndicator.options,
    );
    final reserved = content.hasContent || options.allowColumnFiltering;
    if (!reserved) {
      return FdcGridRowIndicatorLayout.none;
    }

    return FdcGridRowIndicatorLayout(
      reserved: true,
      width: columnWidth(
        rowIndicator: rowIndicator,
        rowCount: rowCount,
        showsFilterRow: showsFilterRow,
        mainMenuInToolbar: mainMenuInToolbar,
        content: content,
      ),
      content: content,
    );
  }

  double columnWidth({
    required FdcGridRowIndicator rowIndicator,
    required int rowCount,
    required bool showsFilterRow,
    bool mainMenuInToolbar = false,
    FdcGridRowIndicatorContent? content,
  }) {
    final rowIndicatorContent =
        content ?? FdcGridRowIndicatorContent.fromOptions(rowIndicator.options);
    const mainMenuWidth = FdcGridHeaderMetrics.menuButtonWidth;
    const mainMenuGap = FdcGridHeaderMetrics.menuGap;

    final bodyContentWidth = _slotContentWidth(
      rowIndicatorContent,
      rowCount: rowCount,
    );

    final selectAllWidth = rowIndicatorContent.showRowSelect
        ? FdcGridHeaderMetrics.rowIndicatorSelectLeadingWidth(
                showRecordStatus: rowIndicatorContent.showRecordStatus,
                showRowSelect: rowIndicatorContent.showRowSelect,
                showRowNumbers: rowIndicatorContent.showRowNumbers,
              ) +
              FdcGridHeaderMetrics.rowIndicatorSelectWidth
        : 0.0;

    final headerWidth = mainMenuInToolbar
        ? selectAllWidth
        : showsFilterRow
        ? math.max(mainMenuWidth, selectAllWidth)
        : rowIndicatorContent.showRowSelect
        ? selectAllWidth + mainMenuGap + mainMenuWidth
        : mainMenuWidth;

    final contentWidth = math.max(bodyContentWidth, headerWidth);
    if (contentWidth > 0) {
      return contentWidth;
    }

    // Keep a tiny alignment region for filter-only layouts when the row
    // indicator is visible but every row-indicator slot is disabled.
    return mainMenuInToolbar
        ? FdcGridHeaderMetrics.rowIndicatorSelectWidth
        : mainMenuWidth;
  }

  double _slotContentWidth(
    FdcGridRowIndicatorContent content, {
    required int rowCount,
  }) {
    var width = 0.0;

    width += FdcGridHeaderMetrics.rowIndicatorStatusSlotWidth(
      showRecordStatus: content.showRecordStatus,
      showRowSelect: content.showRowSelect,
      showRowNumbers: content.showRowNumbers,
    );

    if (content.showRowSelect) {
      width += FdcGridHeaderMetrics.rowIndicatorSelectWidth;
    }

    if (content.showRowNumbers) {
      width += FdcGridHeaderMetrics.rowIndicatorNumberWidth(rowCount);
    }

    return width;
  }
}
