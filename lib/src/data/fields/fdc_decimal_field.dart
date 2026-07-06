// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../fdc_data_type.dart';
import '../fdc_field_def.dart';

/// Decimal field metadata.
///
/// [precision] and [scale] are required because decimal capacity is part of
/// the dataset schema, not a grid/editor formatting preference.
class FdcDecimalField extends FdcFieldDef {
  /// Creates a [FdcDecimalField].
  const FdcDecimalField({
    required super.name,
    super.label,
    super.required = false,
    super.isKey,
    required this.precision,
    required this.scale,
    super.defaultValue,
    this.minValue,
    this.maxValue,
    super.calculatedValue,
    super.persistent,
    super.validator,
    super.storage,
  }) : super(dataType: FdcDataType.decimal);

  /// The precision.
  final int precision;

  /// The scale.
  final int scale;

  /// The min value.
  final num? minValue;

  /// The max value.
  final num? maxValue;

  @override
  void validateSchema() {
    super.validateSchema();
    if (precision < 1 || precision > 38) {
      throw ArgumentError.value(
        precision,
        'precision',
        'FdcDecimalField "$name" precision must be in range 1..38.',
      );
    }
    if (scale < 0 || scale > 38) {
      throw ArgumentError.value(
        scale,
        'scale',
        'FdcDecimalField "$name" scale must be in range 0..38.',
      );
    }
    if (scale > precision) {
      throw ArgumentError.value(
        scale,
        'scale',
        'FdcDecimalField "$name" scale must be less than or equal to precision.',
      );
    }
    final min = minValue;
    final max = maxValue;
    if (min != null && !min.isFinite) {
      throw ArgumentError.value(
        min,
        'minValue',
        'FdcDecimalField "$name" minValue must be finite.',
      );
    }
    if (max != null && !max.isFinite) {
      throw ArgumentError.value(
        max,
        'maxValue',
        'FdcDecimalField "$name" maxValue must be finite.',
      );
    }
    if (min != null && max != null && min > max) {
      throw ArgumentError.value(
        max,
        'maxValue',
        'FdcDecimalField "$name" maxValue must be greater than or equal to minValue.',
      );
    }
  }
}
