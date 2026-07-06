// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/widgets.dart';

import '../../data/fdc_data.dart';

/// Identifies the UI surface that emitted a field event.
enum FdcFieldEventHost {
  /// Event originated from a standalone editor control.
  editor,

  /// Event originated from a grid cell editor.
  grid,
}

/// Describes why focus entered or left a dataset-bound field host.
enum FdcFieldFocusChangeReason {
  /// Focus changed because of pointer interaction.
  mouse,

  /// Focus changed because of direct keyboard navigation.
  keyboard,

  /// Focus changed through row-indicator navigation.
  rowIndicator,

  /// Focus changed because the dataset current record moved.
  datasetScroll,

  /// Focus changed after an editor committed its value.
  editCommit,

  /// Focus changed after an editor canceled its local edit.
  editCancel,

  /// Focus was changed explicitly by application or framework code.
  programmatic,

  /// Focus moved through the configured traversal policy.
  focusTraversal,
}

/// Callback invoked when focus enters or leaves a bound dataset field.
typedef FdcFieldFocusCallback<T> =
    void Function(FdcFieldFocusContext<T> context);

/// Callback invoked before a proposed field value is committed.
///
/// Return `null` or [FdcFieldValueChangeResult.accept] to accept the value,
/// return [FdcFieldValueChangeResult.replaceValue] to substitute another value,
/// or return [FdcFieldValueChangeResult.cancel] to reject the change.
typedef FdcFieldValueChangingCallback<T> =
    FdcFieldValueChangeResult<T>? Function(
      FdcFieldValueChangingContext<T> context,
    );

/// Callback invoked after an accepted field value change has been applied.
typedef FdcFieldValueChangedCallback<T> =
    void Function(FdcFieldValueChangedContext<T> context);

void _requireEventField(FdcDataSet dataSet, String fieldName, String accessor) {
  if (!dataSet.hasField(fieldName)) {
    throw ArgumentError.value(
      fieldName,
      'fieldName',
      '$accessor field does not exist in the dataset.',
    );
  }
}

/// Context supplied when a dataset-bound field gains or loses focus.
///
/// The same context model is shared by standalone editors and grid cell
/// editors. Grid-specific row and column coordinates are populated only when
/// [host] is [FdcFieldEventHost.grid].
class FdcFieldFocusContext<T> {
  /// Creates a [FdcFieldFocusContext].
  const FdcFieldFocusContext({
    this.buildContext,
    required this.dataSet,
    required this.host,
    required this.fieldName,
    this.field,
    this.rowIndex,
    this.columnIndex,
    this.row,
    this.column,
    this.value,
    this.rawValue,
    this.fromRowIndex,
    this.toRowIndex,
    this.fromColumnIndex,
    this.toColumnIndex,
    this.fromFieldName,
    this.toFieldName,
    this.reason = FdcFieldFocusChangeReason.programmatic,
    Object? Function(String fieldName)? valueOf,
  }) : _valueOf = valueOf;

  /// Flutter context of the editor or grid surface that emitted the event.
  final BuildContext? buildContext;

  /// Dataset that owns the field and current edit state.
  final FdcDataSet dataSet;

  /// UI surface that emitted the event.
  final FdcFieldEventHost host;

  /// Name of the dataset field involved in the event.
  final String? fieldName;

  /// Resolved field metadata when available.
  final FdcFieldDef? field;

  /// Zero-based row index in the current view.
  final int? rowIndex;

  /// Zero-based column index in the current grid layout.
  final int? columnIndex;

  /// Host-specific row object when the event originated from a grid.
  final Object? row;

  /// Host-specific column object when the event originated from a grid.
  final Object? column;

  /// Accepted logical field value after the change.
  final T? value;

  /// Unformatted source value before display conversion.
  final Object? rawValue;

  /// Previous grid row index when focus moved between cells.
  final int? fromRowIndex;

  /// Destination grid row index when focus moved between cells.
  final int? toRowIndex;

  /// Previous grid column index when focus moved between cells.
  final int? fromColumnIndex;

  /// Destination grid column index when focus moved between cells.
  final int? toColumnIndex;

  /// Dataset field name that previously owned focus.
  final String? fromFieldName;

  /// Dataset field name receiving focus.
  final String? toFieldName;

  /// Reason focus entered or left the field host.
  final FdcFieldFocusChangeReason reason;

  /// Internal field-value accessor used by [valueOf] and [tryValueOf].
  final Object? Function(String fieldName)? _valueOf;

  void _requireField(String fieldName, String accessor) =>
      _requireEventField(dataSet, fieldName, accessor);

  /// Returns the value of [fieldName], or throws when the field is unknown.
  V? valueOf<V>(String fieldName) {
    _requireField(fieldName, 'FdcFieldFocusContext.valueOf');
    return _valueOf?.call(fieldName) as V?;
  }

  /// Returns the value of [fieldName], or `null` when the field is unavailable.
  V? tryValueOf<V>(String fieldName) {
    if (!dataSet.hasField(fieldName)) {
      return null;
    }
    final value = _valueOf?.call(fieldName);
    if (value == null || value is V) {
      return value as V?;
    }
    return null;
  }
}

/// Decision returned from an `onValueChanging` callback.
///
/// A callback may accept the proposed value, replace it, or cancel the change.
/// [additionalValues] can apply related field updates as part of the same
/// logical edit operation.
sealed class FdcFieldValueChangeResult<T> {
  const FdcFieldValueChangeResult._({
    this.message,
    this.additionalValues = const <String, Object?>{},
  });

  const factory FdcFieldValueChangeResult.accept() =
      FdcFieldValueChangeAccepted<T>;

  const factory FdcFieldValueChangeResult.replaceValue(T? value) =
      FdcFieldValueChangeReplacement<T>;

  const factory FdcFieldValueChangeResult.cancel([String? message]) =
      FdcFieldValueChangeCanceled<T>;

  /// User-facing message text.
  final String? message;

  /// Related field values to apply with the primary value change.
  final Map<String, Object?> additionalValues;

  /// Whether the proposed value change should proceed.
  bool get accepted;

  /// Whether [value] replaces the originally proposed value.
  bool get hasReplacement;

  /// Replacement value when [hasReplacement] is `true`.
  T? get value;

  /// Returns the same decision enriched with related field updates.
  FdcFieldValueChangeResult<T> withAdditionalValues(
    Map<String, Object?> values,
  );
}

/// Accepts the proposed field value without replacing it.
final class FdcFieldValueChangeAccepted<T>
    extends FdcFieldValueChangeResult<T> {
  /// Creates an accepted value-change result.
  const FdcFieldValueChangeAccepted({
    super.additionalValues = const <String, Object?>{},
  }) : super._();

  @override
  bool get accepted => true;

  @override
  bool get hasReplacement => false;

  @override
  T? get value => null;

  @override
  FdcFieldValueChangeResult<T> withAdditionalValues(
    Map<String, Object?> values,
  ) {
    if (values.isEmpty) {
      return this;
    }

    return FdcFieldValueChangeAccepted<T>(
      additionalValues: Map<String, Object?>.unmodifiable(values),
    );
  }
}

/// Accepts a field change but substitutes a different value.
final class FdcFieldValueChangeReplacement<T>
    extends FdcFieldValueChangeResult<T> {
  /// Creates a result that replaces the proposed value.
  const FdcFieldValueChangeReplacement(
    this.replacementValue, {
    super.additionalValues = const <String, Object?>{},
  }) : super._();

  /// Replacement value that should be committed.
  final T? replacementValue;

  @override
  bool get accepted => true;

  @override
  bool get hasReplacement => true;

  @override
  T? get value => replacementValue;

  @override
  FdcFieldValueChangeResult<T> withAdditionalValues(
    Map<String, Object?> values,
  ) {
    if (values.isEmpty) {
      return this;
    }

    return FdcFieldValueChangeReplacement<T>(
      replacementValue,
      additionalValues: Map<String, Object?>.unmodifiable(values),
    );
  }
}

/// Rejects a proposed field change, optionally with a user-facing message.
final class FdcFieldValueChangeCanceled<T>
    extends FdcFieldValueChangeResult<T> {
  /// Creates a canceled value-change result with an optional [message].
  const FdcFieldValueChangeCanceled([String? message])
    : this._(message: message);

  const FdcFieldValueChangeCanceled._({
    super.message,
    super.additionalValues = const <String, Object?>{},
  }) : super._();

  @override
  bool get accepted => false;

  @override
  bool get hasReplacement => false;

  @override
  T? get value => null;

  @override
  FdcFieldValueChangeResult<T> withAdditionalValues(
    Map<String, Object?> values,
  ) {
    if (values.isEmpty) {
      return this;
    }

    return FdcFieldValueChangeCanceled<T>._(
      message: message,
      additionalValues: Map<String, Object?>.unmodifiable(values),
    );
  }
}

/// Mutable context supplied before a proposed field value is committed.
///
/// Use [valueOf] to inspect related fields and [setValueOf] to stage additional
/// field changes that should accompany the primary value change.
class FdcFieldValueChangingContext<T> {
  /// Creates a [FdcFieldValueChangingContext].
  FdcFieldValueChangingContext({
    this.buildContext,
    required this.dataSet,
    required this.host,
    required this.fieldName,
    this.field,
    required this.rowIndex,
    this.columnIndex,
    this.row,
    this.column,
    this.oldValue,
    this.newValue,
    this.oldRawValue,
    this.newRawValue,
    Object? Function(String fieldName)? valueOf,
  }) : _valueOf = valueOf;

  /// Flutter context of the editor or grid surface that emitted the event.
  final BuildContext? buildContext;

  /// Dataset that owns the field and current edit state.
  final FdcDataSet dataSet;

  /// UI surface that emitted the event.
  final FdcFieldEventHost host;

  /// Name of the dataset field involved in the event.
  final String fieldName;

  /// Resolved field metadata when available.
  final FdcFieldDef? field;

  /// Zero-based row index in the current view.
  final int rowIndex;

  /// Zero-based column index in the current grid layout.
  final int? columnIndex;

  /// Host-specific row object when the event originated from a grid.
  final Object? row;

  /// Host-specific column object when the event originated from a grid.
  final Object? column;

  /// Logical field value before the proposed or completed change.
  final T? oldValue;

  /// Proposed logical value before the change decision is applied.
  final T? newValue;

  /// Previous unformatted source value.
  final Object? oldRawValue;

  /// New unformatted source value.
  final Object? newRawValue;

  /// Internal field-value accessor used by [valueOf] and [tryValueOf].
  final Object? Function(String fieldName)? _valueOf;
  final Map<String, Object?> _additionalValues = <String, Object?>{};

  void _requireField(String fieldName, String accessor) =>
      _requireEventField(dataSet, fieldName, accessor);

  /// Returns the typed value of [fieldName], throwing if the field is unknown.
  V? valueOf<V>(String fieldName) {
    _requireField(fieldName, 'FdcFieldValueChangingContext.valueOf');
    return _valueOf?.call(fieldName) as V?;
  }

  /// Returns the value of [fieldName], or `null` when the field is unavailable.
  V? tryValueOf<V>(String fieldName) {
    if (!dataSet.hasField(fieldName)) {
      return null;
    }
    final value = _valueOf?.call(fieldName);
    if (value == null || value is V) {
      return value as V?;
    }
    return null;
  }

  /// Adds or replaces the pending value for [fieldName].
  void setValueOf<V>(String fieldName, V? value) {
    _requireField(fieldName, 'FdcFieldValueChangingContext.setValueOf');
    _additionalValues[fieldName] = value;
  }

  /// Immutable snapshot of related field updates staged with [setValueOf].
  Map<String, Object?> get additionalValueSnapshot =>
      Map<String, Object?>.unmodifiable(_additionalValues);

  /// Accepts the proposed value without replacement.
  FdcFieldValueChangeResult<T> accept() =>
      FdcFieldValueChangeResult<T>.accept();

  /// Accepts the change and commits [value] instead of the proposed value.
  FdcFieldValueChangeResult<T> replaceValue(T? value) =>
      FdcFieldValueChangeResult<T>.replaceValue(value);

  /// Cancels the current operation or edit state.
  FdcFieldValueChangeResult<T> cancel([String? message]) =>
      FdcFieldValueChangeResult<T>.cancel(message);
}

/// Read-only context emitted after a field value change has been accepted.
///
/// It exposes both logical and raw values together with dataset and host
/// metadata so application code can react consistently across editors and
/// grid cell editing.
class FdcFieldValueChangedContext<T> {
  /// Creates a [FdcFieldValueChangedContext].
  const FdcFieldValueChangedContext({
    this.buildContext,
    required this.dataSet,
    required this.host,
    required this.fieldName,
    this.field,
    required this.rowIndex,
    this.columnIndex,
    this.row,
    this.column,
    this.oldValue,
    this.value,
    this.oldRawValue,
    this.rawValue,
    Object? Function(String fieldName)? valueOf,
  }) : _valueOf = valueOf;

  /// Flutter context of the editor or grid surface that emitted the event.
  final BuildContext? buildContext;

  /// Dataset that owns the field and current edit state.
  final FdcDataSet dataSet;

  /// UI surface that emitted the event.
  final FdcFieldEventHost host;

  /// Name of the dataset field involved in the event.
  final String fieldName;

  /// Resolved field metadata when available.
  final FdcFieldDef? field;

  /// Zero-based row index in the current view.
  final int rowIndex;

  /// Zero-based column index in the current grid layout.
  final int? columnIndex;

  /// Host-specific row object when the event originated from a grid.
  final Object? row;

  /// Host-specific column object when the event originated from a grid.
  final Object? column;

  /// Logical field value before the proposed or completed change.
  final T? oldValue;

  /// Accepted logical field value after the change.
  final T? value;

  /// Previous unformatted source value.
  final Object? oldRawValue;

  /// Unformatted source value before display conversion.
  final Object? rawValue;

  /// Internal field-value accessor used by [valueOf] and [tryValueOf].
  final Object? Function(String fieldName)? _valueOf;

  void _requireField(String fieldName, String accessor) =>
      _requireEventField(dataSet, fieldName, accessor);

  /// Returns the typed value of [fieldName], throwing if the field is unknown.
  V? valueOf<V>(String fieldName) {
    _requireField(fieldName, 'FdcFieldValueChangedContext.valueOf');
    return _valueOf?.call(fieldName) as V?;
  }

  /// Returns the value of [fieldName], or `null` when the field is unavailable.
  V? tryValueOf<V>(String fieldName) {
    if (!dataSet.hasField(fieldName)) {
      return null;
    }
    final value = _valueOf?.call(fieldName);
    if (value == null || value is V) {
      return value as V?;
    }
    return null;
  }
}
