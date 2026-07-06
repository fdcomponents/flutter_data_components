// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../common/fdc_aggregate.dart';
import '../fdc_data_errors.dart';
import '../fdc_data_type.dart';
import '../fdc_dataset_filter.dart';
import '../fdc_field_def.dart';
import '../fdc_field_name.dart';
import '../types/fdc_decimal.dart';

typedef FdcAggregateValueReader =
    Object? Function(int rawIndex, int fieldIndex);

typedef FdcAggregateRecordPredicate = bool Function(int rawIndex);

/// Executes aggregate functions over the dataset's current flat view.
///
/// This class is intentionally internal infrastructure. `FdcDataSet` exposes
/// the public convenience methods such as `sum('amount')`, while this class
/// keeps aggregate iteration and type handling out of the main dataset file.
class FdcDataSetAggregator {
  const FdcDataSetAggregator({
    required this.fields,
    required this.fieldIndexByName,
    required this.viewIndexes,
    required this.valueReader,
    required this.isReadableRawIndex,
  });

  final List<FdcFieldDef> fields;
  final Map<String, int> fieldIndexByName;
  final List<int> viewIndexes;
  final FdcAggregateValueReader valueReader;
  final FdcAggregateRecordPredicate isReadableRawIndex;

  int count() {
    var result = 0;
    for (final rawIndex in viewIndexes) {
      if (isReadableRawIndex(rawIndex)) {
        result++;
      }
    }
    return result;
  }

  Object? aggregate(String fieldName, FdcAggregate aggregate) {
    return switch (aggregate) {
      FdcAggregate.sum => sum(fieldName),
      FdcAggregate.min => min(fieldName),
      FdcAggregate.max => max(fieldName),
      FdcAggregate.avg => avg(fieldName),
    };
  }

  FdcDecimal sum(String fieldName) {
    final resolved = _resolveAggregateField(fieldName, operation: 'sum');
    _ensureSummable(resolved, operation: 'sum');

    var result = FdcDecimal.zero;
    for (final rawIndex in viewIndexes) {
      if (!isReadableRawIndex(rawIndex)) {
        continue;
      }
      final value = valueReader(rawIndex, resolved.index);
      if (value == null) {
        continue;
      }
      result += _decimalValue(
        value,
        fieldName: resolved.field.name,
        operation: 'sum',
      );
    }
    return result;
  }

  FdcDecimal? avg(String fieldName) {
    return avgState(fieldName).value;
  }

  FdcAverageAggregateState avgState(String fieldName) {
    final resolved = _resolveAggregateField(fieldName, operation: 'avg');
    _ensureSummable(resolved, operation: 'avg');

    var result = FdcDecimal.zero;
    var valueCount = 0;
    for (final rawIndex in viewIndexes) {
      if (!isReadableRawIndex(rawIndex)) {
        continue;
      }
      final value = valueReader(rawIndex, resolved.index);
      if (value == null) {
        continue;
      }
      result += _decimalValue(
        value,
        fieldName: resolved.field.name,
        operation: 'avg',
      );
      valueCount++;
    }

    return FdcAverageAggregateState(sum: result, count: valueCount);
  }

  Object? min(String fieldName) {
    return _minMax(fieldName, operation: 'min', findMin: true);
  }

  Object? max(String fieldName) {
    return _minMax(fieldName, operation: 'max', findMin: false);
  }

  Object? _minMax(
    String fieldName, {
    required String operation,
    required bool findMin,
  }) {
    final resolved = _resolveAggregateField(fieldName, operation: operation);
    _ensureComparable(resolved, operation: operation);

    Object? best;
    var hasBest = false;
    for (final rawIndex in viewIndexes) {
      if (!isReadableRawIndex(rawIndex)) {
        continue;
      }
      final value = valueReader(rawIndex, resolved.index);
      if (value == null) {
        continue;
      }

      if (!hasBest) {
        best = value;
        hasBest = true;
        continue;
      }

      final compare = compareDataSetSortValues(
        value,
        best,
        resolved.field.dataType,
      );
      if ((findMin && compare < 0) || (!findMin && compare > 0)) {
        best = value;
      }
    }
    return best;
  }

  _ResolvedAggregateField _resolveAggregateField(
    String fieldName, {
    required String operation,
  }) {
    final index = fieldIndexByName[FdcFieldName.normalize(fieldName)];
    if (index == null) {
      throw FdcDataSetException(
        message: 'Unknown $operation field "$fieldName" in dataset FdcDataSet.',
      );
    }
    return _ResolvedAggregateField(index: index, field: fields[index]);
  }

  void _ensureSummable(
    _ResolvedAggregateField resolved, {
    required String operation,
  }) {
    final dataType = resolved.field.dataType;
    if (dataType == FdcDataType.integer || dataType == FdcDataType.decimal) {
      return;
    }
    throw FdcDataSetException(
      message:
          'Cannot calculate $operation for non-numeric field "${resolved.field.name}".',
    );
  }

  void _ensureComparable(
    _ResolvedAggregateField resolved, {
    required String operation,
  }) {
    final dataType = resolved.field.dataType;
    if (dataType == FdcDataType.integer ||
        dataType == FdcDataType.decimal ||
        dataType == FdcDataType.date ||
        dataType == FdcDataType.dateTime ||
        dataType == FdcDataType.time ||
        dataType == FdcDataType.string) {
      return;
    }
    throw FdcDataSetException(
      message:
          'Cannot calculate $operation for field "${resolved.field.name}" of type ${dataType.name}.',
    );
  }

  FdcDecimal _decimalValue(
    Object value, {
    required String fieldName,
    required String operation,
  }) {
    if (value is FdcDecimal) {
      return value;
    }
    if (value is int) {
      return FdcDecimal.fromScaled(BigInt.from(value), scale: 0);
    }
    if (value is num && value.isFinite) {
      return FdcDecimal.fromNum(value);
    }
    throw FdcDataSetException(
      message:
          'Cannot calculate $operation for field "$fieldName" because value "$value" is not numeric.',
    );
  }
}

class _ResolvedAggregateField {
  const _ResolvedAggregateField({required this.index, required this.field});

  final int index;
  final FdcFieldDef field;
}

class FdcAverageAggregateState {
  const FdcAverageAggregateState({required this.sum, required this.count});

  final FdcDecimal sum;
  final int count;

  FdcDecimal? get value {
    if (count == 0) {
      return null;
    }

    final average = sum / count;
    if (average is FdcDecimal) {
      return average;
    }
    throw const FdcDataSetException(message: 'Cannot calculate avg aggregate.');
  }
}
