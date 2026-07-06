// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../fdc_data_type.dart';
import '../fdc_field_def.dart';

/// Boolean dataset field definition.
class FdcBooleanField extends FdcFieldDef {
  /// Creates a [FdcBooleanField].
  const FdcBooleanField({
    required super.name,
    super.label,
    super.required = false,
    super.isKey,
    bool? defaultValue,
    super.calculatedValue,
    super.persistent,
    super.validator,
    super.storage,
  }) : super(dataType: FdcDataType.boolean, defaultValue: defaultValue);
}
