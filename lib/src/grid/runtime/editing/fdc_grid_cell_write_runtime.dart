// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

class _FdcGridFieldWrite {
  const _FdcGridFieldWrite({
    required this.fieldName,
    required this.oldValue,
    required this.value,
  });

  final String fieldName;
  final Object? oldValue;
  final Object? value;
}

extension _FdcGridCellWriteRuntime on _FdcGridState {
  bool _applyCellEditWrite({
    required int rowIndex,
    required int? columnIndex,
    required String fieldName,
    required FdcGridColumn<dynamic>? column,
    required Object? oldValue,
    required Object? value,
    required Map<String, Object?> additionalValues,
    required bool Function() ensureEdit,
    required void Function(Object? value) emitValidation,
    required void Function() markLayoutDirty,
    bool handleInvalidFieldNames = false,
    bool focusActiveEditorAfterDialog = false,
  }) {
    if (handleInvalidFieldNames) {
      try {
        _validateAdditionalFieldNames(
          fieldName,
          additionalValues,
          userFacingMessage: true,
        );
      } on Object catch (error, stackTrace) {
        unawaited(
          _handleDataSetPostError(
            error,
            stackTrace,
            focusActiveEditorAfterDialog: focusActiveEditorAfterDialog,
          ),
        );
        return false;
      }
    } else {
      _validateAdditionalFieldNames(fieldName, additionalValues);
    }

    if (oldValue == value && additionalValues.isEmpty) {
      return true;
    }

    if (!ensureEdit()) {
      _setGridState(markLayoutDirty);
      return false;
    }

    final writes = _lookupWriteMap(
      primaryFieldName: fieldName,
      primaryValue: value,
      additionalValues: additionalValues,
    );
    if (writes.isEmpty) {
      return true;
    }

    final oldValues = <String, Object?>{};
    for (final fieldName in writes.keys) {
      oldValues[fieldName] = _dataSetFieldValueAt(rowIndex, fieldName);
    }

    final changed = <_FdcGridFieldWrite>[];
    _updatingDataSetFromGrid = true;
    try {
      for (final entry in writes.entries) {
        final oldFieldValue = oldValues[entry.key];
        if (oldFieldValue == entry.value) {
          continue;
        }
        widget.dataSet.setFieldValue(entry.key, entry.value);
        changed.add(
          _FdcGridFieldWrite(
            fieldName: entry.key,
            oldValue: oldFieldValue,
            value: entry.value,
          ),
        );
      }
    } on Object catch (error, stackTrace) {
      for (final change in changed.reversed) {
        try {
          widget.dataSet.setFieldValue(change.fieldName, change.oldValue);
        } on Object {
          // Best-effort rollback. Keep the original lookup/edit failure as the
          // operation error surfaced to the grid.
        }
      }
      unawaited(
        _handleDataSetPostError(
          error,
          stackTrace,
          focusActiveEditorAfterDialog: focusActiveEditorAfterDialog,
        ),
      );
      return false;
    } finally {
      _updatingDataSetFromGrid = false;
    }

    final dataSetChanged = changed.isNotEmpty;
    _setGridState(() {
      if (dataSetChanged) {
        // Keep the current dataset view stable while the user edits a visible
        // row. If filters are active and the edited value no longer matches
        // them, the row must not disappear immediately under the cursor.
        // The view is rebuilt when the filter/sort state is changed explicitly
        // or when the dataset changes externally.
        _refreshRowsFromDataSet();
      }
      markLayoutDirty();
    });

    for (final change in changed) {
      if (FdcFieldName.normalize(change.fieldName) ==
          FdcFieldName.normalize(fieldName)) {
        emitValidation(change.value);
        _emitColumnValueChanged(
          column,
          rowIndex: rowIndex,
          columnIndex: columnIndex,
          fieldName: fieldName,
          oldValue: change.oldValue,
          value: change.value,
        );
        _emitCellChanged(
          rowIndex,
          columnIndex,
          fieldName,
          change.oldValue,
          change.value,
        );
      } else {
        _emitDataSetFieldValidationByName(
          rowIndex,
          change.fieldName,
          change.value,
        );
        _emitCellChanged(
          rowIndex,
          null,
          change.fieldName,
          change.oldValue,
          change.value,
        );
      }
    }
    return true;
  }

  Map<String, Object?> _lookupWriteMap({
    required String primaryFieldName,
    required Object? primaryValue,
    required Map<String, Object?> additionalValues,
  }) {
    final normalizedPrimaryFieldName = FdcFieldName.normalize(primaryFieldName);
    final writes = <String, Object?>{primaryFieldName: primaryValue};
    final normalizedWriteNames = <String, String>{
      normalizedPrimaryFieldName: primaryFieldName,
    };

    for (final entry in additionalValues.entries) {
      final normalizedFieldName = FdcFieldName.normalize(entry.key);
      if (normalizedFieldName == normalizedPrimaryFieldName) {
        continue;
      }
      final previousFieldName = normalizedWriteNames[normalizedFieldName];
      if (previousFieldName != null) {
        writes.remove(previousFieldName);
      }
      normalizedWriteNames[normalizedFieldName] = entry.key;
      writes[entry.key] = entry.value;
    }
    return writes;
  }

  ArgumentError _unknownLookupFieldError(String fieldName) =>
      ArgumentError.value(fieldName, 'fieldName', 'Unknown field.');

  void _validateAdditionalFieldNames(
    String primaryFieldName,
    Map<String, Object?> values, {
    bool userFacingMessage = false,
  }) {
    if (values.isEmpty) {
      return;
    }

    final normalizedPrimaryFieldName = FdcFieldName.normalize(primaryFieldName);
    for (final fieldName in values.keys) {
      if (FdcFieldName.normalize(fieldName) == normalizedPrimaryFieldName) {
        continue;
      }
      if (!widget.dataSet.hasField(fieldName)) {
        if (userFacingMessage) {
          throw _unknownLookupFieldError(fieldName);
        }
        throw ArgumentError.value(
          fieldName,
          'fieldName',
          'Additional grid field write refers to an unknown dataset field.',
        );
      }
    }
  }
}
