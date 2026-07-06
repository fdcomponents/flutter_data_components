// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../fdc_data_type.dart';
import '../fdc_field_def.dart';

/// Dataset field metadata for text values.
///
/// String fields can define length, validation, formatting, and editor behavior
/// used by data-aware controls and grids.
class FdcStringField extends FdcFieldDef {
  /// Creates a [FdcStringField].
  const FdcStringField({
    required super.name,
    required this.size,
    super.label,
    super.required = false,
    super.isKey,
    String? defaultValue,
    super.calculatedValue,
    super.persistent,
    super.validator,
    super.storage,
  }) : super(dataType: FdcDataType.string, defaultValue: defaultValue);

  /// Maximum accepted string length.
  final int size;

  @override
  void validateSchema() {
    super.validateSchema();
    if (size <= 0) {
      throw ArgumentError.value(
        size,
        'size',
        'FdcStringField "$name" size must be greater than zero.',
      );
    }
  }
}
