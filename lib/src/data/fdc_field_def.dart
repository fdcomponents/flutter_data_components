// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_data_type.dart';
import 'fdc_data_validation.dart';

/// Storage/persistence metadata for a dataset field.
///
/// FDC keeps field names as a strict storage contract: a field name must match
/// the name exposed by the adapter, database column, or JSON key. Adapters do
/// not perform field-name mapping or aliasing. This metadata only describes
/// write/generation behavior for that same field name.
class FdcFieldStorage {
  /// Creates a [FdcFieldStorage].
  const FdcFieldStorage({
    this.generated = false,
    this.insertable = true,
    this.updateable = true,
  });

  /// Whether the storage layer generates this value.
  ///
  /// Generated fields are effectively read-only and are excluded from regular
  /// INSERT/UPDATE writes.
  final bool generated;

  /// Whether the field participates in INSERT statements.
  final bool insertable;

  /// Whether the field participates in UPDATE statements.
  final bool updateable;

  /// True when adapter persistence may write this field during inserts.
  ///
  /// Generated fields are never insertable even when [insertable] is `true`.
  /// This flag controls persistence writes; editor availability is determined by
  /// the field definition and grid/editor configuration.
  bool get isInsertable => insertable && !generated;

  /// True when adapter persistence may write this field during updates.
  ///
  /// Generated fields are never updateable even when [updateable] is `true`.
  /// This flag controls persistence writes and does not by itself enable or
  /// disable an editing widget.
  bool get isUpdateable => updateable && !generated;

  /// True when storage metadata allows neither insert nor update writes.
  ///
  /// Generated fields are always storage-read-only. A field that participates
  /// in only one write phase, such as insert-only or update-only, is not reported
  /// as fully read-only by this getter.
  bool get isReadOnly => generated || (!insertable && !updateable);
}

/// Factory used by field default values that must be evaluated for each newly
/// inserted/appended record.
typedef FdcFieldDefaultValueFactory = Object? Function();

/// Base metadata definition for a dataset field.
///
/// This class is intentionally abstract and contains only metadata that is
/// valid for every field type. Type-specific options such as string size,
/// decimal precision/scale, and numeric min/max constraints live on concrete
/// field classes from `fields/`.
abstract class FdcFieldDef {
  /// Creates a [FdcFieldDef].
  const FdcFieldDef({
    required this.name,
    required this.dataType,
    this.label,
    this.required = false,
    this.isKey = false,
    this.defaultValue,
    this.calculatedValue,
    this.persistent,
    this.validator,
    this.storage = const FdcFieldStorage(),
  });

  /// Original field name casing used for export/display metadata.
  final String name;

  /// Logical data type used for normalization, validation, filtering, and editors.
  final FdcDataType dataType;

  /// Display label shown to the user.
  final String? label;

  /// Whether null or empty values are rejected by built-in validation.
  final bool required;

  /// Whether this field participates in the dataset record identity.
  ///
  /// Multiple fields with [isKey] set form one composite identity, in field
  /// declaration order.
  final bool isKey;

  /// Static default value or a zero-argument default factory.
  ///
  /// Static defaults are reused as-is. A [FdcFieldDefaultValueFactory], for
  /// example `FdcGuid.newGuid`, is evaluated each time a new inserted/appended
  /// record is materialized. Defaults are not applied when loading existing
  /// rows.
  ///
  /// GUID fields intentionally reject static non-null defaults during new-record
  /// materialization. Use `defaultValue: FdcGuid.newGuid` for primary/foreign-key
  /// style defaults that must be unique per inserted/appended record.
  final Object? defaultValue;

  /// Optional expression used to derive this field from the current row.
  ///
  /// Calculated fields are read-only to normal dataset writes and are
  /// non-persistent by default unless [persistent] explicitly overrides that.
  final FdcCalculatedFieldValue? calculatedValue;

  /// Controls whether the field participates in persistence-oriented outputs
  /// such as `FdcDataSet.changeSet` and `FdcDataSet.toMaps`.
  ///
  /// When omitted, regular fields are persistent and calculated fields are not.
  final bool? persistent;

  /// Optional field-level validator executed after built-in validation.
  final FdcFieldValidator? validator;

  /// Persistence/storage metadata consumed by adapters.
  final FdcFieldStorage storage;

  /// True when the field value is derived by [calculatedValue].
  ///
  /// Calculated fields are recomputed from row data and are read-only to normal
  /// dataset writes. They are non-persistent by default unless [persistent]
  /// explicitly overrides that default.
  bool get isCalculated => calculatedValue != null;

  /// True when the field participates in persistence-oriented dataset output.
  ///
  /// Regular fields default to persistent. Calculated fields default to
  /// non-persistent unless [persistent] explicitly overrides the default.
  bool get isPersistent => persistent ?? !isCalculated;

  /// True when normal dataset editing must not write this field.
  ///
  /// Calculated fields are always read-only. Non-calculated fields are read-only
  /// when their [storage] metadata permits neither insert nor update writes. Grid
  /// columns may impose additional UI-level read-only policy independently.
  bool get isReadOnly => isCalculated || storage.isReadOnly;

  /// Validates runtime schema invariants that cannot rely on debug-only asserts.
  ///
  /// Field definitions keep `const` constructors for ergonomic schema
  /// declarations, so the dataset calls this during schema indexing to enforce
  /// public field metadata rules in debug and release builds.
  void validateSchema() {
    if (name.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'FdcFieldDef.name is required and must not be empty.',
      );
    }
    if (isKey && (isCalculated || !isPersistent)) {
      throw ArgumentError.value(
        isKey,
        'isKey',
        'Key field "$name" must be persistent and non-calculated.',
      );
    }
    if (name.trim() != name) {
      throw ArgumentError.value(
        name,
        'name',
        'FdcFieldDef.name must not have leading or trailing whitespace.',
      );
    }
  }
}
