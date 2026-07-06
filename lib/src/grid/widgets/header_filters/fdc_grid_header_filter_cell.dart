// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../columns/fdc_grid_columns.dart';
import '../../models/fdc_grid_internal_models.dart';
import '../fdc_grid_header_metrics.dart';
import 'fdc_grid_header_filter_editor.dart';

class FdcGridHeaderFilterCell extends StatelessWidget {
  const FdcGridHeaderFilterCell({
    super.key,
    required this.model,
    required this.callbacks,
    required this.column,
    required this.runtimeColumnId,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final FdcGridColumn<dynamic> column;
  final FdcColumnIdentity? runtimeColumnId;

  @override
  Widget build(BuildContext context) {
    return FdcGridHeaderFilterRowFrame(
      child: FdcGridHeaderFilterEditor(
        model: model,
        callbacks: callbacks,
        column: column,
        runtimeColumnId: runtimeColumnId,
        fillColor: model.headerBackgroundColor,
        style: model.headerFilterStyle,
      ),
    );
  }
}

class FdcGridHeaderFilterRowFrame extends StatelessWidget {
  const FdcGridHeaderFilterRowFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: FdcGridHeaderMetrics.filterRowTopPadding,
        bottom: FdcGridHeaderMetrics.filterRowBottomPadding,
      ),
      child: child,
    );
  }
}
