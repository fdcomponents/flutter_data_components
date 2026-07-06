// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart' show internal;

import '../../../data/fdc_data.dart';
import '../../../data/fdc_dataset.dart' show FdcDataSetInternal;
import '../../../data/fdc_field_name.dart';
import '../../models/fdc_grid_row_context.dart';

/// Internal row-source abstraction used by FdcGrid.
///
/// The grid can render, navigate and edit rows without knowing whether values
/// come from a dataset view, a paged source, or a future virtual source.
@internal
abstract interface class IFdcGridRowSource {
  int get length;
  bool get isEmpty;
  bool get isNotEmpty;
  List<String> get fieldNames;

  Object? valueAt(int rowIndex, String fieldName);
  FdcGridRowContext rowAt(int rowIndex);

  FdcGridRowContext operator [](int index);
}

@internal
class FdcDataSetGridRowSource implements IFdcGridRowSource {
  const FdcDataSetGridRowSource(this.dataSet);

  final FdcDataSet dataSet;

  @override
  int get length => dataSet.recordCount;

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length > 0;

  @override
  List<String> get fieldNames => dataSet.fieldNames;

  @override
  Object? valueAt(int rowIndex, String fieldName) {
    if (!dataSet.hasField(fieldName)) {
      throw ArgumentError.value(
        fieldName,
        'fieldName',
        'FdcDataSetGridRowSource.valueAt field does not exist in the dataset.',
      );
    }
    if (rowIndex < 0 || rowIndex >= dataSet.recordCount) {
      return null;
    }

    try {
      return FdcDataSetInternal.fieldValueAt(dataSet, rowIndex, fieldName);
      // ignore: avoid_catching_errors
    } on RangeError {
      // A virtualized grid child can ask for a row once more after the dataset
      // physically removed an inserted/appended record in the same frame. Treat
      // that stale visual row as empty instead of surfacing an internal index
      // transition as a UI exception.
      return null;
    }
  }

  @override
  FdcGridRowContext rowAt(int rowIndex) {
    return _FdcDataSetGridRowContext(this, rowIndex);
  }

  @override
  FdcGridRowContext operator [](int index) => rowAt(index);
}

class _FdcDataSetGridRowContext implements FdcGridRowContext {
  const _FdcDataSetGridRowContext(this._source, this.rowIndex);

  final FdcDataSetGridRowSource _source;

  @override
  final int rowIndex;

  @override
  List<String> get fieldNames => _source.fieldNames;

  @override
  Object? valueOf(String fieldName) {
    if (!containsField(fieldName)) {
      throw ArgumentError.value(
        fieldName,
        'fieldName',
        'FdcGridRowContext.valueOf field does not exist in the row.',
      );
    }
    return _source.valueAt(rowIndex, fieldName);
  }

  @override
  bool containsField(String fieldName) {
    return _source.dataSet.hasField(fieldName);
  }

  @override
  Object? operator [](String fieldName) => valueOf(fieldName);
}

@internal
class FdcEmptyInsertGridRowSource implements IFdcGridRowSource {
  const FdcEmptyInsertGridRowSource(this.dataSet);

  final FdcDataSet dataSet;

  @override
  int get length => 1;

  @override
  bool get isEmpty => false;

  @override
  bool get isNotEmpty => true;

  @override
  List<String> get fieldNames => dataSet.fieldNames;

  @override
  Object? valueAt(int rowIndex, String fieldName) {
    if (!dataSet.hasField(fieldName)) {
      throw ArgumentError.value(
        fieldName,
        'fieldName',
        'FdcEmptyInsertGridRowSource.valueAt field does not exist in the dataset.',
      );
    }
    if (rowIndex != 0) {
      return null;
    }
    return null;
  }

  @override
  FdcGridRowContext rowAt(int rowIndex) {
    if (rowIndex != 0) {
      throw RangeError.index(rowIndex, this, 'rowIndex', null, length);
    }
    return FdcGridTransientRow(
      rowIndex: rowIndex,
      fieldNames: fieldNames,
      valueResolver: (_) => null,
    );
  }

  @override
  FdcGridRowContext operator [](int index) => rowAt(index);
}

@internal
class FdcGridTransientRow implements FdcGridRowContext {
  const FdcGridTransientRow({
    required this.rowIndex,
    required this.fieldNames,
    required Object? Function(String fieldName) valueResolver,
  }) : _valueResolver = valueResolver;

  @override
  final int rowIndex;

  @override
  final List<String> fieldNames;

  final Object? Function(String fieldName) _valueResolver;

  @override
  Object? valueOf(String fieldName) {
    final canonicalFieldName = _canonicalFieldName(fieldName);
    if (canonicalFieldName == null) {
      throw ArgumentError.value(
        fieldName,
        'fieldName',
        'FdcGridRowContext.valueOf field does not exist in the row.',
      );
    }
    return _valueResolver(canonicalFieldName);
  }

  @override
  bool containsField(String fieldName) =>
      _canonicalFieldName(fieldName) != null;

  String? _canonicalFieldName(String fieldName) {
    final normalizedFieldName = FdcFieldName.normalize(fieldName);
    for (final name in fieldNames) {
      if (FdcFieldName.normalize(name) == normalizedFieldName) {
        return name;
      }
    }
    return null;
  }

  @override
  Object? operator [](String fieldName) => valueOf(fieldName);
}
