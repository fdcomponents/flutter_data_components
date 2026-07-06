// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:meta/meta.dart';

import '../fdc_dataset_filter.dart';
import '../fdc_field_name.dart';

/// Dataset-level sort API.
///
/// The dataset owns exactly one active sorted view. This object is the
/// public entry point for replacing, clearing and fluently building that active
/// sort definition. Built fluent expressions are applied only when `apply()`
/// is called. Direct command methods such as [set], [clear] and [toggleBy]
/// still rebuild the dataset view immediately.
class FdcDataSetSorts {
  /// Creates a [FdcDataSetSorts].
  @internal
  FdcDataSetSorts({
    required bool Function() canApplyViewOperation,
    required bool Function() useAsyncViewOperations,
    required List<FdcDataSetSort> Function() readSorts,
    required List<FdcDataSetSort> Function(List<FdcDataSetSort> sorts)
    normalizeSorts,
    required bool Function(List<FdcDataSetSort> sorts, {required bool notify})
    replaceSorts,
    required Future<bool> Function(
      List<FdcDataSetSort> sorts, {
      required bool notify,
    })
    replaceSortsAsync,
  }) : _canApplyViewOperation = canApplyViewOperation,
       _useAsyncViewOperations = useAsyncViewOperations,
       _readSorts = readSorts,
       _normalizeSorts = normalizeSorts,
       _replaceSorts = replaceSorts,
       _replaceSortsAsync = replaceSortsAsync;

  /// Runs the function operation.
  final bool Function() _canApplyViewOperation;

  /// Runs the function operation.
  final bool Function() _useAsyncViewOperations;

  /// Runs the function operation.
  final List<FdcDataSetSort> Function() _readSorts;

  /// Runs the function operation.
  final List<FdcDataSetSort> Function(List<FdcDataSetSort> sorts)
  _normalizeSorts;

  /// Runs the function operation.
  final bool Function(List<FdcDataSetSort> sorts, {required bool notify})
  _replaceSorts;

  /// Runs the function operation.
  final Future<bool> Function(
    List<FdcDataSetSort> sorts, {
    required bool notify,
  })
  _replaceSortsAsync;

  /// Active dataset sort descriptors in priority order.
  List<FdcDataSetSort> get items => _readSorts();

  /// Whether no dataset sort descriptors are active.
  bool get isEmpty => items.isEmpty;

  /// Whether at least one dataset sort descriptor is active.
  bool get isNotEmpty => items.isNotEmpty;

  /// True when the owning dataset has active sorts.
  bool get active => isNotEmpty;

  /// Starts a fluent multi-field sort expression.
  ///
  /// ```dart
  /// await dataSet.sort
  ///   .sortBy('lastName').ascending
  ///   .sortBy('firstName').descending
  ///   .apply();
  ///
  /// ```
  @useResult
  FdcSortOrderStep sortBy(String fieldName) {
    return FdcSortBuilder.internal(controller: this).sortBy(fieldName);
  }

  /// Replaces the active dataset sort and rebuilds the dataset view.
  Future<bool> set(List<FdcDataSetSort> sorts, {bool notify = true}) {
    if (!_canApplyViewOperation()) {
      return Future<bool>.value(false);
    }

    final normalizedSorts = _normalizeSorts(sorts);
    if (_useAsyncViewOperations()) {
      return _replaceSortsAsync(normalizedSorts, notify: notify);
    }

    return Future<bool>.value(_replaceSorts(normalizedSorts, notify: notify));
  }

  /// Clears the active dataset sort and rebuilds the dataset view.
  Future<bool> clear({bool notify = true}) {
    return set(const <FdcDataSetSort>[], notify: notify);
  }

  /// Toggles single-field sorting between ascending and descending order.
  ///
  /// If the current primary sort is not [fieldName], sorting starts in
  /// ascending order.
  Future<bool> toggleBy(String fieldName) {
    if (!_canApplyViewOperation()) {
      return Future<bool>.value(false);
    }

    final normalizedFieldName = FdcFieldName.normalize(fieldName);
    final current = items;
    final isCurrentPrimarySort =
        current.isNotEmpty &&
        FdcFieldName.normalize(current.first.fieldName) == normalizedFieldName;

    return set(<FdcDataSetSort>[
      FdcDataSetSort(
        fieldName: fieldName,
        sortType: isCurrentPrimarySort
            ? current.first.sortType.toggled
            : FdcSortType.ascending,
      ),
    ]);
  }

  /// Runs the apply built sorts operation.
  @internal
  Future<bool> applyBuiltSorts(List<FdcDataSetSort> sorts) {
    if (!_canApplyViewOperation()) {
      return Future<bool>.value(false);
    }

    return set(sorts);
  }
}

/// Fluent builder for dataset sorting.
///
/// Use `FdcDataSet.sort.sortBy` to create it:
///
/// ```dart
/// await dataSet.sort
///   .sortBy('lastName').ascending
///   .sortBy('firstName').descending
///   .apply();
///
/// ```
///
/// Direction properties only build the sort expression. Call `apply()` to
/// validate and rebuild the dataset view in one step.
class FdcSortBuilder {
  /// Creates a [FdcSortBuilder].
  @internal
  FdcSortBuilder.internal({required FdcDataSetSorts controller})
    : _controller = controller;

  final FdcDataSetSorts _controller;
  final List<FdcDataSetSort> _sorts = <FdcDataSetSort>[];

  /// Returns the current items.
  List<FdcDataSetSort> get items => List<FdcDataSetSort>.unmodifiable(_sorts);

  /// Adds [fieldName] as the next sort priority and returns its direction step.
  @useResult
  FdcSortOrderStep sortBy(String fieldName) {
    return FdcSortOrderStep._(this, fieldName);
  }

  /// Validates and applies the composed sort expression to the dataset.
  Future<bool> apply() {
    return _controller.applyBuiltSorts(_sorts);
  }

  FdcSortBuilder _add(String fieldName, FdcSortType sortType) {
    _sorts.add(FdcDataSetSort(fieldName: fieldName, sortType: sortType));
    return this;
  }
}

/// Direction step returned while composing a fluent dataset sort.
class FdcSortOrderStep {
  FdcSortOrderStep._(this._builder, this._fieldName);

  final FdcSortBuilder _builder;
  final String _fieldName;

  /// Adds ascending ordering for the pending field.
  @useResult
  FdcSortBuilder get ascending {
    return _builder._add(_fieldName, FdcSortType.ascending);
  }

  /// Adds descending ordering for the pending field.
  @useResult
  FdcSortBuilder get descending {
    return _builder._add(_fieldName, FdcSortType.descending);
  }
}
