// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../fdc_data_type.dart';
import '../fdc_field_def.dart';
import '../types/fdc_guid.dart';

/// GUID/UUID scalar field.
///
/// Stored values are [FdcGuid] instances. String input is accepted by the
/// dataset normalizer and converted to canonical lowercase GUID text.
class FdcGuidField extends FdcFieldDef {
  /// Creates a [FdcGuidField].
  const FdcGuidField({
    required super.name,
    super.label,
    super.required = false,
    super.isKey,
    super.defaultValue,
    super.calculatedValue,
    super.persistent,
    super.validator,
    super.storage,
  }) : super(dataType: FdcDataType.guid);
}
