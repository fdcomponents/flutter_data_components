// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../fdc_data_type.dart';
import '../fdc_field_def.dart';

/// Date-and-time dataset field definition storing full [DateTime] values.
class FdcDateTimeField extends FdcFieldDef {
  /// Creates a [FdcDateTimeField].
  const FdcDateTimeField({
    required super.name,
    super.label,
    super.required = false,
    super.isKey,
    DateTime? defaultValue,
    super.calculatedValue,
    super.persistent,
    super.validator,
    super.storage,
  }) : super(dataType: FdcDataType.dateTime, defaultValue: defaultValue);
}
