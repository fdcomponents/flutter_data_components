// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../fdc_data_type.dart';
import '../fdc_field_def.dart';

/// Integer dataset field definition with optional inclusive range validation.
class FdcIntegerField extends FdcFieldDef {
  /// Creates a [FdcIntegerField].
  const FdcIntegerField({
    required super.name,
    super.label,
    super.required = false,
    super.isKey,
    int? defaultValue,
    this.minValue,
    this.maxValue,
    super.calculatedValue,
    super.persistent,
    super.validator,
    super.storage,
  }) : super(dataType: FdcDataType.integer, defaultValue: defaultValue);

  /// The min value.
  final int? minValue;

  /// The max value.
  final int? maxValue;

  @override
  void validateSchema() {
    super.validateSchema();
    final min = minValue;
    final max = maxValue;
    if (min != null && max != null && min > max) {
      throw ArgumentError.value(
        max,
        'maxValue',
        'FdcIntegerField "$name" maxValue must be greater than or equal to minValue.',
      );
    }
  }
}
