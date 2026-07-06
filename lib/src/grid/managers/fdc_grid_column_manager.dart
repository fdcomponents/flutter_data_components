// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../../data/bindings/fdc_bindings.dart';
import '../../data/fdc_data.dart';
import '../columns/fdc_grid_columns.dart';
import '../runtime/data/fdc_grid_row_source.dart';

class FdcGridColumnManager {
  List<FdcGridColumn<dynamic>> resolveColumns(
    List<FdcGridColumn<dynamic>> columns,
    IFdcGridRowSource rows,
    FdcDataSet dataSet,
  ) {
    final rowKeys = rows.fieldNames;
    if (columns.isEmpty) {
      final autoColumns = <FdcGridColumn<dynamic>>[];
      for (final fieldName in rowKeys) {
        final column = _resolveAutoColumn(fieldName, dataSet);
        if (column != null) {
          autoColumns.add(column);
        }
      }
      return autoColumns;
    }
    return [
      for (final column in columns) _resolveExplicitColumn(column, dataSet),
    ];
  }

  String columnLabel(FdcGridColumn<dynamic> column) {
    final label = column.label;
    if (label != null && label.isNotEmpty) {
      return label;
    }
    if (!column.isDataBound) {
      return '';
    }
    return _labelFromFieldName(column.fieldName);
  }

  String _labelFromFieldName(String fieldName) {
    if (fieldName.isEmpty) {
      return '';
    }
    final spaced = fieldName
        .replaceAllMapped(
          RegExp(r'(?<=[a-z0-9])([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();
    if (spaced.isEmpty) {
      return '';
    }
    return spaced
        .split(RegExp(r'\s+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  FdcGridColumn<dynamic> _resolveExplicitColumn(
    FdcGridColumn<dynamic> column,
    FdcDataSet dataSet,
  ) {
    if (column.isDataBound && column.fieldName.isEmpty) {
      throw ArgumentError(
        'Invalid grid column configuration: ${column.runtimeType}.fieldName '
        'is required and must not be empty.',
      );
    }

    if (column.isDataBound && !dataSet.hasField(column.fieldName)) {
      _validateColumnConfiguration(column);
      if (dataSet.fieldCount == 0 && dataSet.state != FdcDataSetState.browse) {
        // Adapter-backed datasets can temporarily have no fields before or
        // during open() while their schema is being inferred. Keep explicit
        // columns alive in that transient state so widgets mounted before the
        // async load completes do not fail before the adapter can provide
        // metadata. Once the dataset reaches browse state, an empty schema is
        // authoritative and the normal unknown-field error applies.
        return column;
      }
      throw ArgumentError(
        'Invalid grid column configuration: ${column.runtimeType}.fieldName '
        'references unknown dataset field "${column.fieldName}".',
      );
    }

    _validateColumnConfiguration(column);

    if (!column.isDataBound) {
      return column;
    }

    final binding = FdcFieldBindingResolver.tryResolveAny(
      dataSet,
      column.fieldName,
    );
    if (binding == null) {
      return column;
    }

    _validateColumnBinding(column, dataSet);
    return column;
  }

  FdcGridColumn<dynamic>? _resolveAutoColumn(
    String fieldName,
    FdcDataSet dataSet,
  ) {
    final binding = FdcFieldBindingResolver.tryResolveAny(dataSet, fieldName);
    if (binding == null) {
      return FdcTextColumn<dynamic>(fieldName: fieldName);
    }

    if (binding.fieldDef.dataType == FdcDataType.object) {
      return null;
    }

    final column = _columnForFieldType(
      FdcTextColumn<dynamic>(fieldName: fieldName),
      binding.fieldDef.dataType,
    );
    _validateColumnConfiguration(column);
    _validateColumnBinding(column, dataSet);
    return column;
  }

  void _validateColumnConfiguration(FdcGridColumn<dynamic> column) {
    final width = column.width;
    if (width != null && (!width.isFinite || width < 0)) {
      throw ArgumentError(
        'Invalid grid column configuration: ${column.runtimeType}.width '
        'must be a finite value greater than or equal to zero.',
      );
    }

    if (!column.minWidth.isFinite || column.minWidth < 0) {
      throw ArgumentError(
        'Invalid grid column configuration: ${column.runtimeType}.minWidth '
        'must be a finite value greater than or equal to zero.',
      );
    }

    if (!column.maxWidth.isFinite || column.maxWidth < 0) {
      throw ArgumentError(
        'Invalid grid column configuration: ${column.runtimeType}.maxWidth '
        'must be a finite value greater than or equal to zero.',
      );
    }

    if (column.maxWidth > 0 && column.maxWidth < column.minWidth) {
      throw ArgumentError(
        'Invalid grid column configuration: ${column.runtimeType}.maxWidth '
        'must be greater than or equal to minWidth, or zero for no maximum.',
      );
    }

    if (width != null && width < column.minWidth) {
      throw ArgumentError(
        'Invalid grid column configuration: ${column.runtimeType}.width '
        'must be greater than or equal to minWidth.',
      );
    }

    if (width != null && column.maxWidth > 0 && width > column.maxWidth) {
      throw ArgumentError(
        'Invalid grid column configuration: ${column.runtimeType}.width '
        'must be less than or equal to maxWidth.',
      );
    }

    final filterConfig = column.filterConfig;
    if (filterConfig != null && filterConfig.comboMaxPopupItems <= 0) {
      throw ArgumentError(
        'Invalid grid column configuration: ${column.runtimeType}.filterConfig.comboMaxPopupItems '
        'must be greater than zero.',
      );
    }
  }

  void _validateColumnBinding(
    FdcGridColumn<dynamic> column,
    FdcDataSet dataSet,
  ) {
    try {
      column.validateBinding(dataSet);
      // ignore: avoid_catching_errors
    } on ArgumentError {
      rethrow;
      // ignore: avoid_catching_errors
    } on StateError catch (error) {
      throw ArgumentError('Invalid grid column configuration: $error');
    }
  }

  FdcGridColumn<dynamic> _columnForFieldType(
    FdcGridColumn<dynamic> column,
    FdcDataType dataType,
  ) {
    if (_isExplicitUiSpecialization(column)) {
      return column;
    }

    return switch (dataType) {
      FdcDataType.string => _stringColumnFor(column),
      FdcDataType.integer =>
        column is FdcIntegerColumn<dynamic>
            ? column
            : _integerColumnFrom(column),
      FdcDataType.decimal =>
        column is FdcDecimalColumn<dynamic>
            ? column
            : _decimalColumnFrom(column),
      FdcDataType.boolean =>
        column is FdcBooleanColumn<dynamic>
            ? column
            : _booleanColumnFrom(column),
      FdcDataType.date =>
        column is FdcDateColumn<dynamic> ? column : _dateColumnFrom(column),
      FdcDataType.dateTime =>
        column is FdcDateTimeColumn<dynamic>
            ? column
            : _dateTimeColumnFrom(column),
      FdcDataType.time =>
        column is FdcTimeColumn<dynamic> ? column : _timeColumnFrom(column),
      FdcDataType.guid =>
        column is FdcTextColumn<dynamic> ? column : _textColumnFrom(column),
      FdcDataType.object => column,
    };
  }

  bool _isExplicitUiSpecialization(FdcGridColumn<dynamic> column) {
    return column is FdcComboColumn<dynamic> ||
        column is FdcBadgeColumn<dynamic> ||
        column is FdcProgressColumn<dynamic> ||
        column is FdcCustomColumn<dynamic> ||
        column is FdcActionColumn;
  }

  FdcGridColumn<dynamic> _stringColumnFor(FdcGridColumn<dynamic> column) {
    if (column is FdcTextColumn<dynamic> || column is FdcMemoColumn<dynamic>) {
      return column;
    }

    return _textColumnFrom(column);
  }

  FdcTextColumn<dynamic> _textColumnFrom(FdcGridColumn<dynamic> column) {
    return FdcTextColumn<dynamic>(
      fieldName: column.fieldName,
      id: column.id,
      groupId: column.groupId,
      label: column.label,
      hint: column.hint,
      visible: column.visible,
      exportable: column.exportable,
      enabled: column.enabled,
      readOnly: column.readOnly,
      focusOrder: column.focusOrder,
      tabStop: column.tabStop,
      width: column.width,
      minWidth: column.minWidth,
      maxWidth: column.maxWidth,
      autoSizeMode: column.autoSizeMode,
      allowSort: column.allowSort,
      filterConfig: column.filterConfig,
      allowResize: column.allowResize,
      showIndicator: column.showIndicator,
      onValueChanging: column.onValueChanging,
      onLookup: column.onLookup,
      lookupIcon: column.lookupIcon,
      lookupShortcut: column.lookupShortcut,
      onValueChanged: column.onValueChanged,
      cellStyle: column.cellStyle,
      pin: column.pin,
      summary: column.summary,
      showCounter: column.showCounter,
      counterStyle: column.counterStyle,
    );
  }

  FdcBooleanColumn<dynamic> _booleanColumnFrom(FdcGridColumn<dynamic> column) {
    return FdcBooleanColumn<dynamic>(
      fieldName: column.fieldName,
      id: column.id,
      groupId: column.groupId,
      label: column.label,
      hint: column.hint,
      visible: column.visible,
      exportable: column.exportable,
      enabled: column.enabled,
      readOnly: column.readOnly,
      focusOrder: column.focusOrder,
      tabStop: column.tabStop,
      width: column.width,
      minWidth: column.minWidth,
      maxWidth: column.maxWidth,
      autoSizeMode: column.autoSizeMode,
      allowSort: column.allowSort,
      filterConfig: column.filterConfig,
      allowResize: column.allowResize,
      showIndicator: column.showIndicator,
      onValueChanging: column.onValueChanging,
      onValueChanged: column.onValueChanged,
      cellStyle: column.cellStyle,
      pin: column.pin,
      summary: column.summary,
      control: column is FdcBooleanColumn<dynamic>
          ? column.control
          : FdcBooleanControl.checkbox,
    );
  }

  FdcIntegerColumn<dynamic> _integerColumnFrom(FdcGridColumn<dynamic> column) {
    return FdcIntegerColumn<dynamic>(
      fieldName: column.fieldName,
      id: column.id,
      groupId: column.groupId,
      label: column.label,
      hint: column.hint,
      visible: column.visible,
      exportable: column.exportable,
      enabled: column.enabled,
      readOnly: column.readOnly,
      focusOrder: column.focusOrder,
      tabStop: column.tabStop,
      width: column.width,
      minWidth: column.minWidth,
      maxWidth: column.maxWidth,
      autoSizeMode: column.autoSizeMode,
      allowSort: column.allowSort,
      filterConfig: column.filterConfig,
      allowResize: column.allowResize,
      showIndicator: column.showIndicator,
      onValueChanging: column.onValueChanging,
      onLookup: column.onLookup,
      lookupIcon: column.lookupIcon,
      lookupShortcut: column.lookupShortcut,
      onValueChanged: column.onValueChanged,
      cellStyle: column.cellStyle,
      pin: column.pin,
      summary: column.summary,
      allowNegative: column.allowNegative,
    );
  }

  FdcDecimalColumn<dynamic> _decimalColumnFrom(FdcGridColumn<dynamic> column) {
    return FdcDecimalColumn<dynamic>(
      fieldName: column.fieldName,
      id: column.id,
      groupId: column.groupId,
      label: column.label,
      hint: column.hint,
      visible: column.visible,
      exportable: column.exportable,
      enabled: column.enabled,
      readOnly: column.readOnly,
      focusOrder: column.focusOrder,
      tabStop: column.tabStop,
      width: column.width,
      minWidth: column.minWidth,
      maxWidth: column.maxWidth,
      autoSizeMode: column.autoSizeMode,
      allowSort: column.allowSort,
      filterConfig: column.filterConfig,
      allowResize: column.allowResize,
      showIndicator: column.showIndicator,
      onValueChanging: column.onValueChanging,
      onValueChanged: column.onValueChanged,
      cellStyle: column.cellStyle,
      pin: column.pin,
      summary: column.summary,
      allowNegative: column.allowNegative,
      formatSettings: column.formatSettings,
    );
  }

  FdcDateColumn<dynamic> _dateColumnFrom(FdcGridColumn<dynamic> column) {
    return FdcDateColumn<dynamic>(
      fieldName: column.fieldName,
      id: column.id,
      groupId: column.groupId,
      label: column.label,
      hint: column.hint,
      visible: column.visible,
      exportable: column.exportable,
      enabled: column.enabled,
      readOnly: column.readOnly,
      focusOrder: column.focusOrder,
      tabStop: column.tabStop,
      width: column.width,
      minWidth: column.minWidth,
      maxWidth: column.maxWidth,
      autoSizeMode: column.autoSizeMode,
      allowSort: column.allowSort,
      filterConfig: column.filterConfig,
      allowResize: column.allowResize,
      showIndicator: column.showIndicator,
      onValueChanging: column.onValueChanging,
      onValueChanged: column.onValueChanged,
      cellStyle: column.cellStyle,
      pin: column.pin,
      summary: column.summary,
      formatSettings: column.formatSettings,
    );
  }

  FdcDateTimeColumn<dynamic> _dateTimeColumnFrom(
    FdcGridColumn<dynamic> column,
  ) {
    return FdcDateTimeColumn<dynamic>(
      fieldName: column.fieldName,
      id: column.id,
      groupId: column.groupId,
      label: column.label,
      hint: column.hint,
      visible: column.visible,
      exportable: column.exportable,
      enabled: column.enabled,
      readOnly: column.readOnly,
      focusOrder: column.focusOrder,
      tabStop: column.tabStop,
      width: column.width,
      minWidth: column.minWidth,
      maxWidth: column.maxWidth,
      autoSizeMode: column.autoSizeMode,
      allowSort: column.allowSort,
      filterConfig: column.filterConfig,
      allowResize: column.allowResize,
      showIndicator: column.showIndicator,
      onValueChanging: column.onValueChanging,
      onValueChanged: column.onValueChanged,
      cellStyle: column.cellStyle,
      pin: column.pin,
      summary: column.summary,
      formatSettings: column.formatSettings,
    );
  }

  FdcTimeColumn<dynamic> _timeColumnFrom(FdcGridColumn<dynamic> column) {
    return FdcTimeColumn<dynamic>(
      fieldName: column.fieldName,
      id: column.id,
      groupId: column.groupId,
      label: column.label,
      hint: column.hint,
      visible: column.visible,
      exportable: column.exportable,
      enabled: column.enabled,
      readOnly: column.readOnly,
      focusOrder: column.focusOrder,
      tabStop: column.tabStop,
      width: column.width,
      minWidth: column.minWidth,
      maxWidth: column.maxWidth,
      autoSizeMode: column.autoSizeMode,
      allowSort: column.allowSort,
      filterConfig: column.filterConfig,
      allowResize: column.allowResize,
      showIndicator: column.showIndicator,
      onValueChanging: column.onValueChanging,
      onValueChanged: column.onValueChanged,
      cellStyle: column.cellStyle,
      pin: column.pin,
      summary: column.summary,
      formatSettings: column.formatSettings,
    );
  }
}
