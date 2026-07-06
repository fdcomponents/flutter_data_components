// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../data/bindings/fdc_bindings.dart';
import '../../data/fdc_data.dart';
import '../../data/fdc_dataset.dart' show FdcDataSetInternal;

/// Dataset field metadata resolved for a grid column.
///
/// The grid may decide how a value is displayed or edited, but schema facts
/// such as string size, decimal precision/scale, and calculated state come
/// from the dataset field definition. Keeping that lookup in one
/// place prevents grid/editor code from growing parallel schema rules.
class FdcGridFieldMetadata {
  const FdcGridFieldMetadata({
    required this.exists,
    this.dataType,
    this.label,
    this.calculated = false,
    this.readOnly = false,
    this.stringSize,
    this.decimalPrecision,
    this.decimalScale,
  });

  const FdcGridFieldMetadata.missing()
    : exists = false,
      dataType = null,
      label = null,
      calculated = false,
      readOnly = false,
      stringSize = null,
      decimalPrecision = null,
      decimalScale = null;

  factory FdcGridFieldMetadata.fromDataSet(
    FdcDataSet dataSet,
    String fieldName,
  ) {
    if (fieldName.isEmpty) {
      return const FdcGridFieldMetadata.missing();
    }

    final binding = FdcFieldBindingResolver.tryResolveAny(dataSet, fieldName);
    if (binding == null) {
      return const FdcGridFieldMetadata.missing();
    }

    final field = binding.fieldDef;
    return FdcGridFieldMetadata(
      exists: true,
      dataType: field.dataType,
      label: field.label,
      calculated: field.isCalculated,
      readOnly: FdcDataSetInternal.isReadOnly(dataSet) || field.isReadOnly,
      stringSize: field is FdcStringField ? field.size : null,
      decimalPrecision: field is FdcDecimalField ? field.precision : null,
      decimalScale: field is FdcDecimalField ? field.scale : null,
    );
  }

  final bool exists;
  final FdcDataType? dataType;
  final String? label;
  final bool calculated;
  final bool readOnly;
  final int? stringSize;
  final int? decimalPrecision;
  final int? decimalScale;

  bool get isReadOnlyForEditing => calculated || readOnly;
}
