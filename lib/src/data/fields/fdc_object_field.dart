// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../fdc_data_type.dart';
import '../fdc_field_def.dart';

/// Field for custom object values that should be stored as-is in the dataset.
///
/// Use this for framework/application value objects such as badges, images,
/// binary wrappers, JSON wrappers, or other non-scalar values. Scalar data
/// should use the typed field classes such as `FdcStringField`,
/// `FdcIntegerField`, `FdcDecimalField`, etc.
class FdcObjectField extends FdcFieldDef {
  /// Creates a [FdcObjectField].
  const FdcObjectField({
    required super.name,
    super.label,
    super.required = false,
    super.isKey,
    super.defaultValue,
    super.calculatedValue,
    super.persistent,
    super.validator,
    super.storage,
  }) : super(dataType: FdcDataType.object);
}
