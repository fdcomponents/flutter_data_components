// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/input/fdc_key_utils.dart';
import '../../../common/theme/fdc_grid_styles.dart';
import '../../../data/fdc_data.dart';
import '../../columns/fdc_grid_columns.dart';
import '../../filtering/fdc_header_filter_input_behavior.dart';
import '../../models/fdc_grid_internal_models.dart';
import 'fdc_grid_header_filter_shell.dart';
import 'fdc_grid_header_filter_value_editors.dart';

class FdcGridHeaderFilterEditor extends StatelessWidget {
  const FdcGridHeaderFilterEditor({
    super.key,
    required this.model,
    required this.callbacks,
    required this.column,
    required this.runtimeColumnId,
    required this.fillColor,
    required this.style,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final FdcGridColumn<dynamic> column;
  final FdcColumnIdentity? runtimeColumnId;
  final Color fillColor;
  final FdcGridHeaderFilterStyle style;

  FdcColumnIdentity get _runtimeId => runtimeColumnId!;

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!FdcKeyUtils.isKeyDownOrRepeat(event)) {
      return KeyEventResult.ignored;
    }
    return FdcKeyUtils.isEnter(event)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.tab): () =>
            callbacks.onFocusNextHeaderFilter(_runtimeId, forward: true),
        const SingleActivator(LogicalKeyboardKey.tab, shift: true): () =>
            callbacks.onFocusNextHeaderFilter(_runtimeId, forward: false),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            callbacks.onFocusGridCellFromHeaderFilter(_runtimeId),
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _handleKeyEvent,
        child: FdcGridHeaderFilterValueEditor(
          model: model,
          callbacks: callbacks,
          column: column,
          runtimeColumnId: _runtimeId,
          fillColor: fillColor,
          style: style,
        ),
      ),
    );
  }
}

class FdcGridHeaderFilterValueEditor extends StatelessWidget {
  const FdcGridHeaderFilterValueEditor({
    super.key,
    required this.model,
    required this.callbacks,
    required this.column,
    required this.runtimeColumnId,
    required this.fillColor,
    required this.style,
  });

  final FdcGridHeaderModel model;
  final FdcGridHeaderCallbacks callbacks;
  final FdcGridColumn<dynamic> column;
  final FdcColumnIdentity runtimeColumnId;
  final Color fillColor;
  final FdcGridHeaderFilterStyle style;

  @override
  Widget build(BuildContext context) {
    if (!column.filterEnabled) {
      return FdcGridHeaderFilterShell(
        label: '',
        fillColor: fillColor,
        style: style,
        child: const SizedBox.shrink(),
      );
    }

    final editor = column.filterConfig?.editor ?? FdcFilterEditor.search;
    final operator = callbacks.headerFilterOperatorOf(column, runtimeColumnId);
    final inputBehavior = FdcHeaderFilterInputBehavior.resolve(
      column: column,
      dataType: callbacks.dataTypeOf(column),
      operator: operator,
      canOpenFilterMenu: callbacks.canOpenFilterMenu(),
    );

    final pendingRangePopup = model.rangeAutoOpenColumnId == runtimeColumnId;

    if (inputBehavior.operatorDisplayOnly) {
      final baseEditor = FdcGridHeaderTextFilterEditor(
        model: model,
        callbacks: callbacks,
        column: column,
        runtimeColumnId: runtimeColumnId,
        fillColor: fillColor,
        style: style,
      );
      if (!pendingRangePopup) {
        return baseEditor;
      }
      return FdcGridHeaderRangeFilterEditor(
        model: model,
        callbacks: callbacks,
        column: column,
        runtimeColumnId: runtimeColumnId,
        fillColor: fillColor,
        style: style,
        deferredAnchorChild: baseEditor,
      );
    }

    if (operator == FdcFilterOperator.between) {
      return FdcGridHeaderRangeFilterEditor(
        model: model,
        callbacks: callbacks,
        column: column,
        runtimeColumnId: runtimeColumnId,
        fillColor: fillColor,
        style: style,
      );
    }

    final baseEditor = switch (editor) {
      FdcFilterEditor.search => FdcGridHeaderTextFilterEditor(
        model: model,
        callbacks: callbacks,
        column: column,
        runtimeColumnId: runtimeColumnId,
        fillColor: fillColor,
        style: style,
      ),
      FdcFilterEditor.combo => FdcGridHeaderComboFilterEditor(
        model: model,
        callbacks: callbacks,
        column: column,
        runtimeColumnId: runtimeColumnId,
        fillColor: fillColor,
        style: style,
      ),
      FdcFilterEditor.list => FdcGridHeaderListFilterEditor(
        model: model,
        callbacks: callbacks,
        column: column,
        runtimeColumnId: runtimeColumnId,
        fillColor: fillColor,
        style: style,
      ),
      FdcFilterEditor.range => FdcGridHeaderRangeFilterEditor(
        model: model,
        callbacks: callbacks,
        column: column,
        runtimeColumnId: runtimeColumnId,
        fillColor: fillColor,
        style: style,
      ),
      FdcFilterEditor.checkbox => FdcGridHeaderCheckboxFilterEditor(
        model: model,
        callbacks: callbacks,
        column: column,
        runtimeColumnId: runtimeColumnId,
        fillColor: fillColor,
        style: style,
      ),
    };

    if (!pendingRangePopup) {
      return baseEditor;
    }

    return FdcGridHeaderRangeFilterEditor(
      model: model,
      callbacks: callbacks,
      column: column,
      runtimeColumnId: runtimeColumnId,
      fillColor: fillColor,
      style: style,
      deferredAnchorChild: baseEditor,
    );
  }
}
