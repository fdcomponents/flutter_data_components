// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../data/fdc_data.dart';
import '../../i18n/fdc_translations.dart';
import '../columns/fdc_grid_columns.dart';

class FdcHeaderFilterOperatorPolicy {
  const FdcHeaderFilterOperatorPolicy._();

  static FdcFilterOperator resolveOperator({
    required FdcGridColumn<dynamic> column,
    required FdcDataType dataType,
    required FdcFilterOperator gridTextOperator,
    FdcFilterOperator? current,
    bool adapterBacked = false,
  }) {
    final operators = operatorsForColumn(
      column,
      dataType,
      adapterBacked: adapterBacked,
    );
    if (current != null && operators.contains(current)) {
      return current;
    }

    final columnDefault = column.filterConfig?.defaultOperator;
    if (columnDefault != null && operators.contains(columnDefault)) {
      return columnDefault;
    }

    final filterEditor = column.filterConfig?.editor ?? FdcFilterEditor.search;
    if (filterEditor == FdcFilterEditor.combo &&
        operators.contains(FdcFilterOperator.equals)) {
      return FdcFilterOperator.equals;
    }
    if (filterEditor == FdcFilterEditor.list &&
        operators.contains(FdcFilterOperator.inList)) {
      return FdcFilterOperator.inList;
    }
    if (filterEditor == FdcFilterEditor.range &&
        operators.contains(FdcFilterOperator.between)) {
      return FdcFilterOperator.between;
    }
    if (filterEditor == FdcFilterEditor.checkbox &&
        operators.contains(FdcFilterOperator.isTrue)) {
      return FdcFilterOperator.isTrue;
    }

    if (operators.contains(gridTextOperator)) {
      return gridTextOperator;
    }
    return operators.first;
  }

  static List<FdcFilterOperator> operatorsForColumn(
    FdcGridColumn<dynamic> column,
    FdcDataType dataType, {
    bool adapterBacked = false,
  }) {
    final configured = column.filterConfig?.operators;
    if (configured != null && configured.isNotEmpty) {
      final normalized = _normalizeConfiguredOperators(
        column,
        dataType,
        configured,
      );
      final compatible = _adapterCompatibleOperators(
        normalized,
        adapterBacked: adapterBacked,
      );
      if (compatible.isNotEmpty) {
        return compatible;
      }
    }
    return _adapterCompatibleOperators(
      defaultOperatorsForColumn(column, dataType),
      adapterBacked: adapterBacked,
    );
  }

  static List<FdcFilterOperator> _adapterCompatibleOperators(
    List<FdcFilterOperator> operators, {
    required bool adapterBacked,
  }) {
    if (!adapterBacked) {
      return operators;
    }

    // `between` is adapter-safe at grid level because the header-filter
    // runtime expands it into inclusive >= and <= predicates before the
    // dataset converts filters to the adapter DTO. `notContains` remains
    // local-only until the adapter contract grows equivalent semantics.
    return operators
        .where(isAdapterBackedOperatorSupported)
        .toList(growable: false);
  }

  static bool isAdapterBackedOperatorSupported(FdcFilterOperator operator) {
    return operator != FdcFilterOperator.notContains;
  }

  static List<FdcFilterOperator> _normalizeConfiguredOperators(
    FdcGridColumn<dynamic> column,
    FdcDataType dataType,
    List<FdcFilterOperator> configured,
  ) {
    if (column.filterConfig?.editor != FdcFilterEditor.list) {
      return configured;
    }

    final normalized = configured
        .where(
          (operator) =>
              operator != FdcFilterOperator.equals &&
              operator != FdcFilterOperator.notEquals,
        )
        .toList(growable: false);

    if (normalized.isNotEmpty) {
      return normalized;
    }
    return defaultOperatorsForColumn(column, dataType);
  }

  static List<FdcFilterOperator> defaultOperatorsForColumn(
    FdcGridColumn<dynamic> column,
    FdcDataType dataType,
  ) {
    final filterEditor = column.filterConfig?.editor;
    if (filterEditor == FdcFilterEditor.list) {
      return const [
        FdcFilterOperator.inList,
        FdcFilterOperator.notInList,
        FdcFilterOperator.isNull,
        FdcFilterOperator.isNotNull,
      ];
    }
    if (filterEditor == FdcFilterEditor.range) {
      return const [
        FdcFilterOperator.between,
        FdcFilterOperator.isNull,
        FdcFilterOperator.isNotNull,
      ];
    }
    if (filterEditor == FdcFilterEditor.checkbox) {
      return const [
        FdcFilterOperator.isTrue,
        FdcFilterOperator.isFalse,
        FdcFilterOperator.isNull,
        FdcFilterOperator.isNotNull,
      ];
    }
    if (column.effectiveEditor == FdcEditorType.combo ||
        column.effectiveEditor == FdcEditorType.badge) {
      if (dataType == FdcDataType.string) {
        return const [
          FdcFilterOperator.equals,
          FdcFilterOperator.notEquals,
          FdcFilterOperator.contains,
          FdcFilterOperator.isNull,
          FdcFilterOperator.isNotNull,
          FdcFilterOperator.isEmpty,
          FdcFilterOperator.isNotEmpty,
          FdcFilterOperator.isNullOrWhitespace,
          FdcFilterOperator.isNotNullOrWhitespace,
        ];
      }
      return const [
        FdcFilterOperator.equals,
        FdcFilterOperator.notEquals,
        FdcFilterOperator.isNull,
        FdcFilterOperator.isNotNull,
      ];
    }
    return switch (dataType) {
      FdcDataType.integer ||
      FdcDataType.decimal ||
      FdcDataType.date ||
      FdcDataType.dateTime ||
      FdcDataType.time => const [
        FdcFilterOperator.equals,
        FdcFilterOperator.notEquals,
        FdcFilterOperator.greaterThan,
        FdcFilterOperator.greaterThanOrEqual,
        FdcFilterOperator.lessThan,
        FdcFilterOperator.lessThanOrEqual,
        FdcFilterOperator.between,
        FdcFilterOperator.isNull,
        FdcFilterOperator.isNotNull,
      ],
      FdcDataType.boolean => const [
        FdcFilterOperator.isTrue,
        FdcFilterOperator.isFalse,
        FdcFilterOperator.isNull,
        FdcFilterOperator.isNotNull,
      ],
      FdcDataType.string => const [
        FdcFilterOperator.contains,
        FdcFilterOperator.notContains,
        FdcFilterOperator.equals,
        FdcFilterOperator.notEquals,
        FdcFilterOperator.startsWith,
        FdcFilterOperator.endsWith,
        FdcFilterOperator.isEmpty,
        FdcFilterOperator.isNotEmpty,
      ],
      FdcDataType.guid => const [
        FdcFilterOperator.contains,
        FdcFilterOperator.notContains,
        FdcFilterOperator.equals,
        FdcFilterOperator.notEquals,
        FdcFilterOperator.startsWith,
        FdcFilterOperator.endsWith,
        FdcFilterOperator.isNull,
        FdcFilterOperator.isNotNull,
      ],
      FdcDataType.object => const [
        FdcFilterOperator.equals,
        FdcFilterOperator.notEquals,
        FdcFilterOperator.isNull,
        FdcFilterOperator.isNotNull,
      ],
    };
  }

  static String labelOf(
    FdcFilterOperator operator, {
    FdcTranslations translations = const FdcTranslations(),
  }) {
    final labels = translations.grid.operatorLabels;
    return switch (operator) {
      FdcFilterOperator.contains => labels.contains,
      FdcFilterOperator.notContains => labels.notContains,
      FdcFilterOperator.equals => labels.equals,
      FdcFilterOperator.notEquals => labels.notEquals,
      FdcFilterOperator.startsWith => labels.startsWith,
      FdcFilterOperator.endsWith => labels.endsWith,
      FdcFilterOperator.greaterThan => labels.greaterThan,
      FdcFilterOperator.greaterThanOrEqual => labels.greaterThanOrEqual,
      FdcFilterOperator.lessThan => labels.lessThan,
      FdcFilterOperator.lessThanOrEqual => labels.lessThanOrEqual,
      FdcFilterOperator.between => labels.between,
      FdcFilterOperator.inList => labels.inList,
      FdcFilterOperator.notInList => labels.notInList,
      FdcFilterOperator.isNull => labels.isNull,
      FdcFilterOperator.isNotNull => labels.isNotNull,
      FdcFilterOperator.isEmpty => labels.isEmpty,
      FdcFilterOperator.isNotEmpty => labels.isNotEmpty,
      FdcFilterOperator.isNullOrWhitespace => labels.isNullOrWhitespace,
      FdcFilterOperator.isNotNullOrWhitespace => labels.isNotNullOrWhitespace,
      FdcFilterOperator.isTrue => labels.isTrue,
      FdcFilterOperator.isFalse => labels.isFalse,
    };
  }

  static bool ignoresValue(FdcFilterOperator operator) {
    return operator == FdcFilterOperator.isNull ||
        operator == FdcFilterOperator.isNotNull ||
        operator == FdcFilterOperator.isEmpty ||
        operator == FdcFilterOperator.isNotEmpty ||
        operator == FdcFilterOperator.isNullOrWhitespace ||
        operator == FdcFilterOperator.isNotNullOrWhitespace ||
        operator == FdcFilterOperator.isTrue ||
        operator == FdcFilterOperator.isFalse;
  }
}
