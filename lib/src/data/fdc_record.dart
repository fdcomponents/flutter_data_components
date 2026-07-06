// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'fdc_dataset_state.dart';
import 'types/fdc_decimal.dart';

/// Internal row representation used by `FdcDataSet`.
///
/// Values are stored positionally, by field index, instead of a per-row map.
/// This keeps row storage compact and makes grid access faster. Conversion to
/// and from `Map<String, Object?>` is handled by the dataset/adapter boundary.
class FdcRecord {
  FdcRecord({
    required this.id,
    required List<Object?> values,
    List<Object?>? originalValues,
    this.state = FdcRecordState.unchanged,
    this.selected = false,
  }) : _values = List<Object?>.of(values) {
    if (originalValues != null) {
      if (originalValues.length != _values.length) {
        throw ArgumentError.value(
          originalValues.length,
          'originalValues.length',
          'Original snapshot length does not match record field count.',
        );
      }
      _originalValues = List<Object?>.of(originalValues);
    } else {
      // Most records are loaded/read-only and never modified. Keep the
      // original-value snapshot aliased to current values until a write occurs.
      // setValueAt/restoreValues detach it first, preserving change tracking
      // without eagerly duplicating row storage for every loaded record.
      _originalValues = _values;
    }
  }

  final int id;
  FdcRecordState state;

  /// Runtime UI selection metadata owned by the dataset record.
  ///
  /// This is not a field value and must not be serialized through adapters or
  /// row map conversion. It lets all data-aware visual components observe the
  /// same row selection state without maintaining grid-local row-index state.
  bool selected;

  final List<Object?> _values;
  late List<Object?> _originalValues;

  int get fieldCount => _values.length;

  Object? valueAt(int fieldIndex) => _values[fieldIndex];

  num? numValueAt(int fieldIndex) => _toNum(valueAt(fieldIndex));

  double? doubleValueAt(int fieldIndex) => numValueAt(fieldIndex)?.toDouble();

  int? intValueAt(int fieldIndex) => numValueAt(fieldIndex)?.toInt();

  void setValueAt(int fieldIndex, Object? value) {
    if (_values[fieldIndex] == value) {
      return;
    }
    _detachOriginalValuesIfShared();
    _values[fieldIndex] = value;
  }

  Object? originalValueAt(int fieldIndex) => _originalValues[fieldIndex];

  bool isFieldChanged(int fieldIndex) {
    if (identical(_originalValues, _values)) {
      return false;
    }
    return _values[fieldIndex] != _originalValues[fieldIndex];
  }

  List<Object?> valuesSnapshot() => List<Object?>.of(_values);

  List<Object?> originalValuesSnapshot() => List<Object?>.of(_originalValues);

  void restoreValues(List<Object?> values) {
    if (values.length != _values.length) {
      throw ArgumentError.value(
        values.length,
        'values.length',
        'Snapshot length does not match record field count.',
      );
    }

    if (!identical(values, _values)) {
      _detachOriginalValuesIfShared();
    }
    for (var i = 0; i < values.length; i++) {
      _values[i] = values[i];
    }
  }

  void restoreOriginalValues() {
    if (!identical(_originalValues, _values)) {
      restoreValues(_originalValues);
      _originalValues = _values;
    }
  }

  void acceptChanges() {
    _originalValues = _values;
    state = FdcRecordState.unchanged;
  }

  void _detachOriginalValuesIfShared() {
    if (identical(_originalValues, _values)) {
      _originalValues = List<Object?>.of(_values);
    }
  }

  static num? _toNum(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is FdcDecimal) {
      return value.toNum();
    }
    if (value is num) {
      return value;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return num.tryParse(trimmed.replaceAll(',', '.'));
    }
    return null;
  }

  Set<int> changedFieldIndexes() {
    final changed = <int>{};
    for (var i = 0; i < _values.length; i++) {
      if (isFieldChanged(i)) {
        changed.add(i);
      }
    }
    return changed;
  }
}
