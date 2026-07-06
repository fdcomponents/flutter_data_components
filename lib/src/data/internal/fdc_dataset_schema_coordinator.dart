// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../i18n/fdc_translations.dart';
import '../fdc_data_adapter.dart';
import '../fdc_data_errors.dart';
import '../fdc_data_validation.dart';
import '../fdc_dataset_field_writer.dart';
import '../fdc_dataset_record_mapper.dart';
import '../fdc_dataset_update_applier.dart';
import '../fdc_dataset_validator.dart';
import '../fdc_field_def.dart';
import '../fdc_field_name.dart';

/// Owns the configured dataset schema and all schema-derived runtime services.
final class FdcDataSetSchemaCoordinator {
  FdcDataSetSchemaCoordinator({
    required void Function(int fieldIndex) invalidateComparableCacheForField,
    required FdcRecordValidator? recordValidator,
    required String ownerDescription,
    required FdcValidationTranslations validationTranslations,
  }) : _invalidateComparableCacheForField = invalidateComparableCacheForField,
       _recordValidator = recordValidator,
       _ownerDescription = ownerDescription,
       _validationTranslations = validationTranslations;

  final void Function(int fieldIndex) _invalidateComparableCacheForField;
  final FdcRecordValidator? _recordValidator;
  final String _ownerDescription;
  final FdcValidationTranslations _validationTranslations;

  List<FdcFieldDef> _fields = const <FdcFieldDef>[];
  Map<String, int> _fieldIndexByName = const <String, int>{};
  List<String> _fieldNames = const <String>[];

  late FdcDataSetValidator _validator;
  late FdcDataSetRecordMapper _recordMapper;
  late FdcDataSetFieldWriter _fieldWriter;
  late FdcDataSetUpdateApplier _updateApplier;

  List<FdcFieldDef> get fields => _fields;
  Map<String, int> get fieldIndexByName => _fieldIndexByName;
  List<String> get fieldNames => _fieldNames;
  FdcDataSetValidator get validator => _validator;
  FdcDataSetRecordMapper get recordMapper => _recordMapper;
  FdcDataSetFieldWriter get fieldWriter => _fieldWriter;
  FdcDataSetUpdateApplier get updateApplier => _updateApplier;

  void configure(List<FdcFieldDef> fields) {
    _fields = List<FdcFieldDef>.unmodifiable(fields);
    _buildFieldIndex();
    _validator = FdcDataSetValidator(
      fields: _fields,
      fieldIndexByName: _fieldIndexByName,
      recordValidator: _recordValidator,
      validationTranslations: _validationTranslations,
    );
    _recordMapper = FdcDataSetRecordMapper(
      fields: _fields,
      applyCalculatedFields: _validator.applyCalculatedFields,
    );
    _fieldWriter = FdcDataSetFieldWriter(
      fields: _fields,
      fieldIndexByName: _fieldIndexByName,
      applyCalculatedFields: _validator.applyCalculatedFields,
    );
    _updateApplier = FdcDataSetUpdateApplier(
      fields: _fields,
      fieldIndexByName: _fieldIndexByName,
      applyCalculatedFields: _validator.applyCalculatedFields,
      invalidateComparableCacheForField: _invalidateComparableCacheForField,
    );
  }

  void adoptLoadResultFieldsIfNeeded(FdcDataLoadResult result) {
    if (_fields.isNotEmpty) {
      return;
    }
    final resultFields = result.fields;
    if (resultFields != null && resultFields.isNotEmpty) {
      configure(resultFields);
    }
  }

  void _buildFieldIndex() {
    final result = <String, int>{};
    for (var i = 0; i < _fields.length; i++) {
      final field = _fields[i];
      field.validateSchema();
      final normalizedName = FdcFieldName.normalize(field.name);
      final existingIndex = result[normalizedName];
      if (existingIndex != null) {
        final existingName = _fields[existingIndex].name;
        throw FdcDataSetException(
          message:
              'Duplicate field name "${field.name}" '
              'in dataset $_ownerDescription. '
              'Field name "$existingName" already exists.',
        );
      }
      result[normalizedName] = i;
    }
    _fieldIndexByName = Map<String, int>.unmodifiable(result);
    _fieldNames = List<String>.unmodifiable([
      for (final field in _fields) field.name,
    ]);
  }
}
