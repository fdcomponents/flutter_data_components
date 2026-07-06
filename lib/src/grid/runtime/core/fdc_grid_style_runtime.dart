// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStyleRuntime on _FdcGridState {
  Color _gridBackgroundColor() {
    return _styles.gridBackgroundColor(style: _gridStyle);
  }

  Color? _selectedRowBackgroundColor() {
    return _styles.selectedRowBackgroundColor(_gridStyle);
  }

  FdcGridLines _gridLines() {
    return _styles.gridLines(_gridStyle);
  }

  Color _gridBorderColor() {
    return _styles.gridBorderColor(_gridStyle);
  }

  TextStyle? _headerTextStyle(BuildContext context) {
    return _styles.headerTextStyle(context, _headerStyle);
  }

  TextStyle? _cellTextStyle(BuildContext context) {
    return _styles.cellTextStyle(context, _gridStyle);
  }

  TextStyle _headerFilterTextStyle(BuildContext context) {
    return (_cellTextStyle(context) ?? DefaultTextStyle.of(context).style)
        .copyWith(fontSize: 14);
  }

  FdcGridControlsStyle _controlsStyle(BuildContext context) {
    return _styles.controlsStyle(context, theme: _gridTheme);
  }

  FdcGridHeaderFilterStyle _headerFilterStyle(BuildContext context) {
    return _styles.headerFilterStyle(
      context,
      widget.header.filters,
      theme: _gridTheme,
      gridBackgroundColor: _gridBackgroundColor(),
    );
  }

  double _headerSeparatorTopInset() {
    return _headerStyle.verticalSeparatorInset ??
        FdcGridHeaderStyle.defaults.verticalSeparatorInset ??
        FdcGridHeaderMetrics.verticalSeparatorInset;
  }

  double _headerSeparatorBottomInset() {
    return _headerStyle.verticalSeparatorInset ??
        FdcGridHeaderStyle.defaults.verticalSeparatorInset ??
        FdcGridHeaderMetrics.verticalSeparatorInset;
  }
}
