// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/fdc_grid_internal_models.dart';
import 'fdc_grid_cell_frame.dart';
import 'fdc_grid_control_theme.dart';
import 'fdc_grid_header_menus.dart';
import 'fdc_grid_header_metrics.dart';
import 'fdc_grid_row_indicator_header_layout.dart';
import 'fdc_grid_separators.dart';
import 'header_filters/fdc_grid_header_filter_cell.dart';

class FdcGridRowIndicatorHeader extends StatelessWidget {
  const FdcGridRowIndicatorHeader({
    super.key,
    required this.model,
    required this.callbacks,
    required this.width,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: model.height,
      decoration: BoxDecoration(
        color: model.headerBackgroundColor,
        border: Border(
          right: BorderSide(color: model.effectiveVerticalGridLineColor),
        ),
      ),
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: LayoutBuilder(
          builder: (context, outerConstraints) {
            final filterHeight = model.showsFilterRow
                ? math.min(model.filterRowHeight, outerConstraints.maxHeight)
                : 0.0;
            final labelHeight = math.max(
              0.0,
              outerConstraints.maxHeight - filterHeight,
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                FdcGridCellFrame(
                  width: width,
                  alignment: Alignment.centerLeft,
                  contentHorizontalInset: 0.0,
                  child: Column(
                    children: [
                      SizedBox(
                        height: labelHeight,
                        child: _rowIndicatorHeaderLabel(context),
                      ),
                      if (model.showsFilterRow)
                        SizedBox(
                          height: filterHeight,
                          child: _rowIndicatorHeaderFilter(context),
                        ),
                    ],
                  ),
                ),
                if (model.showsFilterRow && filterHeight > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: labelHeight,
                    child: FdcGridHorizontalSeparator(
                      width: outerConstraints.maxWidth,
                      color: model.headerSeparatorColor,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _rowIndicatorHeaderLabel(BuildContext context) {
    final layout = _rowIndicatorHeaderLayout();

    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (layout.showSelectAllInLabelRow)
            Positioned(
              left: layout.selectAllLeft,
              top: _labelRowControlTopInset(),
              width: FdcGridHeaderMetrics.rowIndicatorSelectWidth,
              height: _labelRowControlHeight(),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: _buildSelectAllCheckbox(context),
                ),
              ),
            ),
          if (model.showMainMenuInHeader && _centerMainMenuAcrossFullHeader())
            Positioned.fill(
              child: Center(
                child: FdcGridHeaderMainMenuButton(callbacks: callbacks),
              ),
            )
          else if (model.showMainMenuInHeader &&
              _centerMainMenuHorizontallyAcrossHeader())
            Positioned(
              left: 0,
              right: 0,
              top: _mainMenuControlTopInset(),
              height: _mainMenuControlHeight(),
              child: Center(
                child: FdcGridHeaderMainMenuButton(callbacks: callbacks),
              ),
            )
          else if (model.showMainMenuInHeader &&
              layout.centerMainMenuInHeaderLabel)
            Positioned.fill(
              child: Center(
                child: FdcGridHeaderMainMenuButton(callbacks: callbacks),
              ),
            )
          else if (model.showMainMenuInHeader &&
              layout.centerMainMenuInRowNumberSlot)
            Positioned(
              left: layout.mainMenuLeft,
              top: _mainMenuControlTopInset(),
              width: _rowNumberMainMenuWidth(layout),
              height: _mainMenuControlHeight(),
              child: Center(
                child: FdcGridHeaderMainMenuButton(callbacks: callbacks),
              ),
            )
          else if (model.showMainMenuInHeader)
            Positioned(
              right: 0,
              top: _mainMenuControlTopInset(),
              width: FdcGridHeaderMetrics.menuButtonWidth,
              height: _mainMenuControlHeight(),
              child: Center(
                child: FdcGridHeaderMainMenuButton(callbacks: callbacks),
              ),
            ),
        ],
      ),
    );
  }

  double _rowNumberMainMenuWidth(FdcGridRowIndicatorHeaderLayout layout) {
    return math.max(
      FdcGridHeaderMetrics.menuButtonWidth,
      width - layout.mainMenuLeft,
    );
  }

  double _mainMenuControlTopInset() {
    if (_centerMainMenuAcrossFullHeader()) {
      return 0.0;
    }
    return _labelRowControlTopInset();
  }

  double _mainMenuControlHeight() {
    if (_centerMainMenuAcrossFullHeader()) {
      return math.max(0.0, model.height);
    }
    return _labelRowControlHeight();
  }

  bool _centerMainMenuAcrossFullHeader() {
    if (model.showsFilterRow) {
      return false;
    }

    final options = model.rowIndicator.options;
    return options.showRecordStatus &&
        !options.showRowSelect &&
        !options.showRowNumbers;
  }

  bool _centerMainMenuHorizontallyAcrossHeader() {
    if (model.showsFilterRow) {
      return false;
    }

    final options = model.rowIndicator.options;
    return options.showRecordStatus &&
        !options.showRowSelect &&
        options.showRowNumbers;
  }

  Widget _rowIndicatorHeaderFilter(BuildContext context) {
    final layout = _rowIndicatorHeaderLayout();
    return FdcGridHeaderFilterRowFrame(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (layout.showSelectAllInFilterRow)
            Positioned(
              left: layout.selectAllLeft,
              top: 0,
              bottom: 0,
              width: FdcGridHeaderMetrics.rowIndicatorSelectWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: _buildSelectAllCheckbox(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _labelRowControlTopInset() {
    if (model.showsFilterRow || model.groupHeaderHeight <= 0) {
      return 0.0;
    }
    return model.groupHeaderHeight;
  }

  double _labelRowControlHeight() {
    if (model.showsFilterRow) {
      return model.height;
    }
    if (model.groupHeaderHeight > 0) {
      return math.max(0.0, model.height - model.groupHeaderHeight);
    }
    return math.max(0.0, model.height);
  }

  FdcGridRowIndicatorHeaderLayout _rowIndicatorHeaderLayout() {
    return FdcGridRowIndicatorHeaderLayout.resolve(
      options: model.rowIndicator.options,
      showsFilterRow: model.showsFilterRow,
    );
  }

  Widget _buildSelectAllCheckbox(BuildContext context) {
    return SizedBox(
      width: FdcGridHeaderMetrics.rowIndicatorCheckboxSize,
      height: FdcGridHeaderMetrics.rowIndicatorCheckboxSize,
      child: Checkbox(
        tristate: true,
        value: callbacks.selectAllRowIndicatorValue(),
        fillColor: FdcGridControlTheme.checkboxFillColor(model.controlsStyle),
        checkColor: FdcGridControlTheme.checkboxCheckColor(
          context,
          model.controlsStyle,
          enabled: callbacks.canSelectAllRows(),
        ),
        side: FdcGridControlTheme.checkboxSide(
          context,
          model.controlsStyle,
          enabled: callbacks.canSelectAllRows(),
        ),
        onChanged: callbacks.canSelectAllRows()
            ? (value) {
                callbacks.onClearFocusedCell();
                final currentValue = callbacks.selectAllRowIndicatorValue();
                callbacks.onSelectAllRows(currentValue != true);
              }
            : null,
      ),
    );
  }
}
