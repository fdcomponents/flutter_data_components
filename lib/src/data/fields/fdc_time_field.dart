// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../fdc_data_type.dart';
import '../fdc_field_def.dart';
import '../types/fdc_time.dart';

/// Dataset field metadata for time-of-day values.
///
/// Time fields store and validate the time component independently of a
/// calendar date.
class FdcTimeField extends FdcFieldDef {
  /// Creates a [FdcTimeField].
  const FdcTimeField({
    required super.name,
    super.label,
    super.required = false,
    super.isKey,
    FdcTime? defaultValue,
    super.calculatedValue,
    super.persistent,
    super.validator,
    super.storage,
    this.scale = 7,
  }) : super(dataType: FdcDataType.time, defaultValue: defaultValue);

  /// Fractional second scale, compatible with SQL Server `time(n)`.
  ///
  /// Valid range is `0..7`. The default is `7`, matching SQL Server's default
  /// `time(7)` 100ns precision.
  final int scale;

  @override
  void validateSchema() {
    super.validateSchema();
    if (scale < 0 || scale > 7) {
      throw ArgumentError.value(
        scale,
        'scale',
        'FdcTimeField "$name" scale must be in range 0..7.',
      );
    }
  }
}
