// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:meta/meta.dart';

import '../../common/format/fdc_format_settings.dart';
import '../fdc_data_type.dart';
import '../fdc_dataset_filter.dart';
import '../fdc_filter_operator.dart';
import 'fdc_dataset_filter_controller.dart';

/// Fluent AND-only builder for dataset filters.
///
/// Use `FdcDataSet.filter.where` to create it:
///
/// ```dart
/// await dataSet.filter
///   .where('name').contains('ana')
///   .and('amount').greaterThan(100)
///   .apply();
///
/// ```
class FdcFilterBuilder {
  /// Creates a [FdcFilterBuilder].
  @internal
  FdcFilterBuilder.internal({
    required FdcDataSetFilters controller,
    required FdcDataSetFilterContext context,
  }) : _controller = controller,
       _context = context;

  final FdcDataSetFilters _controller;
  FdcDataSetFilterContext _context;
  final List<FdcDataSetFilter> _filters = <FdcDataSetFilter>[];
  final List<FdcDataSetSort> _sorts = <FdcDataSetSort>[];
  bool _orderByStarted = false;

  /// Field-level filter descriptors currently built by this fluent builder.
  ///
  /// This list intentionally excludes context filters such as [selectedFilter].
  List<FdcDataSetFilter> get fieldItems =>
      List<FdcDataSetFilter>.unmodifiable(_filters);

  /// Non-field filter context currently built by this fluent builder.
  FdcDataSetFilterContext get context => _context;

  /// Built row-selection-state filter, or `null` when no selection filter is
  /// part of the builder.
  bool? get selectedFilter => _context.selected;

  /// Returns the current sort items.
  List<FdcDataSetSort> get sortItems =>
      List<FdcDataSetSort>.unmodifiable(_sorts);

  /// Starts a condition for [fieldName].
  @useResult
  FdcFilterConditionBuilder where(String fieldName) {
    _ensureCanAddFilterCondition();
    return FdcFilterConditionBuilder._(this, fieldName);
  }

  /// Adds another AND condition for [fieldName].
  @useResult
  FdcFilterConditionBuilder and(String fieldName) {
    return where(fieldName);
  }

  /// Adds [fieldName] as the next ordering priority.
  @useResult
  FdcFilterOrderStep orderBy(String fieldName) {
    _orderByStarted = true;
    return FdcFilterOrderStep._(this, fieldName);
  }

  /// Adds a row-selection-state filter to the dataset query.
  ///
  /// This filters the current view by the internal record selection state; it
  /// does not select or unselect records. Like field conditions, it must be
  /// declared before orderBy().
  @useResult
  FdcFilterBuilder selected(bool value) {
    _ensureCanAddFilterCondition();
    _context = _context.copyWith(selected: value);
    return this;
  }

  /// Applies pending changes.
  Future<bool> apply() {
    return _controller.applyBuiltFilters(
      _filters,
      _context,
      sorts: _orderByStarted ? _sorts : null,
    );
  }

  void _ensureCanAddFilterCondition() {
    if (_orderByStarted) {
      throw StateError(
        'Filter conditions must be added before orderBy(). '
        'Call orderBy() only as the final clause before apply().',
      );
    }
  }

  FdcFilterBuilder _add(
    String fieldName,
    FdcFilterOperator operator, {
    Object? value,
    Object? secondValue,
    bool caseSensitive = false,
    FdcDataType? dataType,
    FdcFormatSettings? formatSettings,
    FdcDataSetValueResolver? valueResolver,
  }) {
    _ensureCanAddFilterCondition();
    _filters.add(
      FdcDataSetFilter(
        fieldName: fieldName,
        operator: operator,
        value: value,
        secondValue: secondValue,
        caseSensitive: caseSensitive,
        dataType: dataType,
        formatSettings: formatSettings,
        valueResolver: valueResolver,
      ),
    );
    return this;
  }

  FdcFilterBuilder _addSort(String fieldName, FdcSortType sortType) {
    _orderByStarted = true;
    _sorts.add(FdcDataSetSort(fieldName: fieldName, sortType: sortType));
    return this;
  }
}

/// Ordering step returned while composing a fluent filter query.
class FdcFilterOrderStep {
  FdcFilterOrderStep._(this._builder, this._fieldName);

  final FdcFilterBuilder _builder;
  final String _fieldName;

  /// Returns the current ascending.
  @useResult
  FdcFilterBuilder get ascending {
    return _builder._addSort(_fieldName, FdcSortType.ascending);
  }

  /// Returns the current descending.
  @useResult
  FdcFilterBuilder get descending {
    return _builder._addSort(_fieldName, FdcSortType.descending);
  }
}

/// Fluent condition step for one dataset field.
///
/// Calling an operator method adds the corresponding predicate and returns the
/// parent builder so additional conditions or ordering can be composed.
class FdcFilterConditionBuilder {
  FdcFilterConditionBuilder._(this._builder, this._fieldName);

  final FdcFilterBuilder _builder;
  final String _fieldName;

  /// Adds a case-configurable `contains` predicate.
  @useResult
  FdcFilterBuilder contains(
    Object? value, {
    bool caseSensitive = false,
    FdcDataType? dataType,
    FdcFormatSettings? formatSettings,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.contains,
      value: value,
      caseSensitive: caseSensitive,
      dataType: dataType,
      formatSettings: formatSettings,
      valueResolver: valueResolver,
    );
  }

  /// Adds a local `notContains` predicate.
  ///
  /// Adapter-backed paging does not currently translate this operator.
  @useResult
  FdcFilterBuilder notContains(
    Object? value, {
    bool caseSensitive = false,
    FdcDataType? dataType,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.notContains,
      value: value,
      caseSensitive: caseSensitive,
      dataType: dataType,
      valueResolver: valueResolver,
    );
  }

  /// Adds a case-configurable `startsWith` predicate.
  @useResult
  FdcFilterBuilder startsWith(
    Object? value, {
    bool caseSensitive = false,
    FdcDataType? dataType,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.startsWith,
      value: value,
      caseSensitive: caseSensitive,
      dataType: dataType,
      valueResolver: valueResolver,
    );
  }

  /// Adds a case-configurable `endsWith` predicate.
  @useResult
  FdcFilterBuilder endsWith(
    Object? value, {
    bool caseSensitive = false,
    FdcDataType? dataType,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.endsWith,
      value: value,
      caseSensitive: caseSensitive,
      dataType: dataType,
      valueResolver: valueResolver,
    );
  }

  /// Adds an equality predicate.
  @useResult
  FdcFilterBuilder equals(
    Object? value, {
    FdcDataType? dataType,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.equals,
      value: value,
      dataType: dataType,
      valueResolver: valueResolver,
    );
  }

  /// Adds an inequality predicate.
  @useResult
  FdcFilterBuilder notEquals(
    Object? value, {
    FdcDataType? dataType,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.notEquals,
      value: value,
      dataType: dataType,
      valueResolver: valueResolver,
    );
  }

  /// Adds a `greaterThan` predicate.
  @useResult
  FdcFilterBuilder greaterThan(
    Object? value, {
    FdcDataType? dataType,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.greaterThan,
      value: value,
      dataType: dataType,
      valueResolver: valueResolver,
    );
  }

  /// Adds a `greaterThanOrEqual` predicate.
  @useResult
  FdcFilterBuilder greaterThanOrEqual(
    Object? value, {
    FdcDataType? dataType,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.greaterThanOrEqual,
      value: value,
      dataType: dataType,
      valueResolver: valueResolver,
    );
  }

  /// Adds a `lessThan` predicate.
  @useResult
  FdcFilterBuilder lessThan(
    Object? value, {
    FdcDataType? dataType,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.lessThan,
      value: value,
      dataType: dataType,
      valueResolver: valueResolver,
    );
  }

  /// Adds a `lessThanOrEqual` predicate.
  @useResult
  FdcFilterBuilder lessThanOrEqual(
    Object? value, {
    FdcDataType? dataType,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.lessThanOrEqual,
      value: value,
      dataType: dataType,
      valueResolver: valueResolver,
    );
  }

  /// Adds an inclusive local range predicate.
  ///
  /// Adapter-backed paging does not currently translate this compound
  /// operator directly. Grid range filters use separate `>=` and `<=`
  /// predicates when adapter-side paging is active.
  @useResult
  FdcFilterBuilder between(
    Object? value,
    Object? secondValue, {
    FdcDataType? dataType,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.between,
      value: value,
      secondValue: secondValue,
      dataType: dataType,
      valueResolver: valueResolver,
    );
  }

  /// Adds an `inList` predicate for [values].
  @useResult
  FdcFilterBuilder inList(
    Iterable<Object?> values, {
    bool caseSensitive = false,
    FdcDataType? dataType,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.inList,
      value: List<Object?>.unmodifiable(values),
      caseSensitive: caseSensitive,
      dataType: dataType,
      valueResolver: valueResolver,
    );
  }

  /// Adds a `notInList` predicate for [values].
  @useResult
  FdcFilterBuilder notInList(
    Iterable<Object?> values, {
    bool caseSensitive = false,
    FdcDataType? dataType,
    FdcDataSetValueResolver? valueResolver,
  }) {
    return _builder._add(
      _fieldName,
      FdcFilterOperator.notInList,
      value: List<Object?>.unmodifiable(values),
      caseSensitive: caseSensitive,
      dataType: dataType,
      valueResolver: valueResolver,
    );
  }

  /// Adds an `isNull` predicate.
  @useResult
  FdcFilterBuilder isNull() {
    return _builder._add(_fieldName, FdcFilterOperator.isNull);
  }

  /// Adds an `isNotNull` predicate.
  @useResult
  FdcFilterBuilder isNotNull() {
    return _builder._add(_fieldName, FdcFilterOperator.isNotNull);
  }

  /// Adds an `isEmpty` predicate.
  @useResult
  FdcFilterBuilder isEmpty() {
    return _builder._add(_fieldName, FdcFilterOperator.isEmpty);
  }

  /// Adds an `isNotEmpty` predicate.
  @useResult
  FdcFilterBuilder isNotEmpty() {
    return _builder._add(_fieldName, FdcFilterOperator.isNotEmpty);
  }

  /// Adds an `isNullOrWhitespace` predicate.
  @useResult
  FdcFilterBuilder isNullOrWhitespace() {
    return _builder._add(_fieldName, FdcFilterOperator.isNullOrWhitespace);
  }

  /// Adds an `isNotNullOrWhitespace` predicate.
  @useResult
  FdcFilterBuilder isNotNullOrWhitespace() {
    return _builder._add(_fieldName, FdcFilterOperator.isNotNullOrWhitespace);
  }

  /// Adds an `is true` predicate for the current boolean field.
  @useResult
  FdcFilterBuilder isTrue() {
    return _builder._add(_fieldName, FdcFilterOperator.isTrue);
  }

  /// Adds an `is false` predicate for the current boolean field.
  @useResult
  FdcFilterBuilder isFalse() {
    return _builder._add(_fieldName, FdcFilterOperator.isFalse);
  }
}
