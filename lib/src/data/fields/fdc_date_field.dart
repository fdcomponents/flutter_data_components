// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../fdc_data_type.dart';
import '../fdc_field_def.dart';

/// Dataset field metadata for date-only values.
///
/// Values are normalized according to FDC date semantics and do not represent
/// an independent time-of-day component.
class FdcDateField extends FdcFieldDef {
  /// Creates a [FdcDateField].
  const FdcDateField({
    required super.name,
    super.label,
    super.required = false,
    super.isKey,
    DateTime? defaultValue,
    super.calculatedValue,
    super.persistent,
    super.validator,
    super.storage,
  }) : super(dataType: FdcDataType.date, defaultValue: defaultValue);
}
