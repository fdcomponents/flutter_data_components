// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../data/fdc_data.dart';
import '../columns/fdc_grid_columns.dart';
import 'fdc_header_filter_operator_policy.dart';

class FdcHeaderFilterInputBehavior {
  const FdcHeaderFilterInputBehavior({
    required this.hasFocusableInput,
    required this.acceptsTextInput,
    required this.isMenuOnly,
    required this.operatorDisplayOnly,
  });

  final bool hasFocusableInput;
  final bool acceptsTextInput;
  final bool isMenuOnly;
  final bool operatorDisplayOnly;

  bool get acceptsValueInput => !isMenuOnly && !operatorDisplayOnly;

  static FdcHeaderFilterInputBehavior resolve({
    required FdcGridColumn<dynamic> column,
    required FdcDataType dataType,
    required FdcFilterOperator operator,
    required bool canOpenFilterMenu,
  }) {
    if (!column.filterEnabled || !canOpenFilterMenu) {
      return const FdcHeaderFilterInputBehavior(
        hasFocusableInput: false,
        acceptsTextInput: false,
        isMenuOnly: false,
        operatorDisplayOnly: false,
      );
    }

    final editor = column.filterConfig?.editor ?? FdcFilterEditor.search;
    final operatorIgnoresValue = FdcHeaderFilterOperatorPolicy.ignoresValue(
      operator,
    );
    final isBooleanCheckboxState =
        editor == FdcFilterEditor.checkbox &&
        (operator == FdcFilterOperator.isTrue ||
            operator == FdcFilterOperator.isFalse);
    if (operatorIgnoresValue && !isBooleanCheckboxState) {
      return const FdcHeaderFilterInputBehavior(
        hasFocusableInput: false,
        acceptsTextInput: false,
        isMenuOnly: false,
        operatorDisplayOnly: true,
      );
    }

    if (operator == FdcFilterOperator.between) {
      return const FdcHeaderFilterInputBehavior(
        hasFocusableInput: true,
        acceptsTextInput: false,
        isMenuOnly: false,
        operatorDisplayOnly: false,
      );
    }

    return switch (editor) {
      FdcFilterEditor.search => FdcHeaderFilterInputBehavior(
        hasFocusableInput: dataType != FdcDataType.boolean,
        acceptsTextInput: dataType != FdcDataType.boolean,
        isMenuOnly: false,
        operatorDisplayOnly: false,
      ),
      FdcFilterEditor.combo => const FdcHeaderFilterInputBehavior(
        hasFocusableInput: true,
        acceptsTextInput: false,
        isMenuOnly: false,
        operatorDisplayOnly: false,
      ),
      FdcFilterEditor.range => const FdcHeaderFilterInputBehavior(
        hasFocusableInput: true,
        acceptsTextInput: false,
        isMenuOnly: false,
        operatorDisplayOnly: false,
      ),
      FdcFilterEditor.list => const FdcHeaderFilterInputBehavior(
        hasFocusableInput: false,
        acceptsTextInput: false,
        isMenuOnly: true,
        operatorDisplayOnly: false,
      ),
      FdcFilterEditor.checkbox => const FdcHeaderFilterInputBehavior(
        hasFocusableInput: true,
        acceptsTextInput: false,
        isMenuOnly: false,
        operatorDisplayOnly: false,
      ),
    };
  }
}
