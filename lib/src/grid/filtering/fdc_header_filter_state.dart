// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../data/fdc_filter_operator.dart';
import '../models/fdc_column_identity.dart';

class FdcHeaderFilterState {
  const FdcHeaderFilterState({
    required this.runtimeColumnId,
    required this.operator,
    required this.hasValue,
    required this.hasOperator,
    this.value,
  });

  final FdcColumnIdentity runtimeColumnId;
  final FdcFilterOperator operator;
  final bool hasValue;
  final bool hasOperator;
  final Object? value;

  bool get hasState => hasValue || hasOperator;
}

class FdcHeaderFilterStateSnapshot {
  const FdcHeaderFilterStateSnapshot._();

  static bool hasAny({
    required Map<FdcColumnIdentity, Object?> values,
    required Map<FdcColumnIdentity, FdcFilterOperator> operators,
  }) {
    return values.isNotEmpty || operators.isNotEmpty;
  }

  static String signature({
    required Map<FdcColumnIdentity, Object?> values,
    required Map<FdcColumnIdentity, FdcFilterOperator> operators,
  }) {
    final parts = <String>[];
    final keys = <FdcColumnIdentity>{...values.keys, ...operators.keys}.toList()
      ..sort((left, right) => left.toString().compareTo(right.toString()));

    for (final key in keys) {
      final value = values[key];
      final operator = operators[key];
      if (value == null && operator == null) {
        continue;
      }
      parts.add('$key:${operator?.name ?? ''}:${value ?? ''}');
    }

    return parts.join('|');
  }
}
