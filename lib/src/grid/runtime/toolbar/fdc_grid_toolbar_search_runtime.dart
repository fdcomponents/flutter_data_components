// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridToolbarSearchRuntime on _FdcGridState {
  List<String> _toolbarSearchFieldNames() {
    final result = <String>[];
    final seen = <String>{};
    for (final column in _visibleColumns) {
      if (!column.isDataBound) {
        continue;
      }
      final dataType = _fieldDataTypeFor(column);
      if (dataType == FdcDataType.object) {
        continue;
      }
      final normalizedFieldName = FdcFieldName.normalize(column.fieldName);
      if (seen.add(normalizedFieldName)) {
        result.add(column.fieldName);
      }
    }
    return List<String>.unmodifiable(result);
  }

  Map<String, FdcSearchFieldTextFormatter> _toolbarSearchFieldTextFormatters() {
    final columnsByFieldName = <String, List<FdcGridColumn<dynamic>>>{};
    for (final column in _visibleColumns) {
      if (!column.isDataBound) {
        continue;
      }
      final dataType = _fieldDataTypeFor(column);
      if (dataType == FdcDataType.object) {
        continue;
      }
      columnsByFieldName
          .putIfAbsent(
            FdcFieldName.normalize(column.fieldName),
            () => <FdcGridColumn<dynamic>>[],
          )
          .add(column);
    }

    final result = <String, FdcSearchFieldTextFormatter>{};
    for (final entry in columnsByFieldName.entries) {
      final searchColumns = List<FdcGridColumn<dynamic>>.unmodifiable(
        entry.value,
      );
      result[entry.key] = (value) {
        final values = <String>[];
        for (final column in searchColumns) {
          final formatted = _valueFormatter.format(column, value).trim();
          if (formatted.isNotEmpty && !values.contains(formatted)) {
            values.add(formatted);
          }
        }
        return values.join('\n');
      };
    }
    return Map<String, FdcSearchFieldTextFormatter>.unmodifiable(result);
  }

  Map<String, FdcFormatSettings> _toolbarSearchFieldFormatSettings(
    FdcFormatSettings gridFormatSettings,
  ) {
    final result = <String, FdcFormatSettings>{};
    for (final column in _visibleColumns) {
      if (!column.isDataBound) {
        continue;
      }
      final dataType = _fieldDataTypeFor(column);
      if (dataType == FdcDataType.object) {
        continue;
      }
      result[FdcFieldName.normalize(column.fieldName)] =
          column.formatSettings ?? gridFormatSettings;
    }
    return Map<String, FdcFormatSettings>.unmodifiable(result);
  }

  FdcFormatSettings _effectiveFormatSettings(BuildContext context) {
    return widget.formatSettings ?? FdcApp.formatsOf(context);
  }

  void _handleToolbarSearchChanged(
    String text, {
    required FdcSearchMode mode,
    required bool caseSensitive,
  }) {
    if (!widget.dataSet.isOpen) {
      return;
    }

    final generation = ++_toolbarSearchGeneration;
    final formatSettings = _effectiveFormatSettings(context);
    if (_formatSettings != formatSettings) {
      _formatSettings = formatSettings;
      _valueFormatter = _createValueFormatter(formatSettings);
    }
    final fields = _toolbarSearchFieldNames();
    final fieldTextFormatters = _toolbarSearchFieldTextFormatters();
    final fieldFormatSettings = _toolbarSearchFieldFormatSettings(
      formatSettings,
    );

    _queueToolbarSearchApply(
      generation: generation,
      apply: () => widget.dataSet.search.apply(
        text,
        mode: mode,
        caseSensitive: caseSensitive,
        fields: fields,
        fieldTextFormatters: fieldTextFormatters,
        fieldFormatSettings: fieldFormatSettings,
        formatSettings: formatSettings,
      ),
    );
  }

  void _handleToolbarSearchCleared() {
    if (!widget.dataSet.isOpen) {
      return;
    }

    final generation = ++_toolbarSearchGeneration;
    _queueToolbarSearchApply(
      generation: generation,
      apply: widget.dataSet.search.clear,
    );
  }

  void _queueToolbarSearchApply({
    required int generation,
    required Future<void> Function() apply,
  }) {
    if (!mounted || !widget.dataSet.isOpen) {
      return;
    }

    Future<void> run() =>
        _runToolbarSearchApplyAsync(generation: generation, apply: apply);

    if (_ui.toolbarSearch.applyInFlight) {
      _ui.toolbarSearch.queuedApply = run;
      return;
    }

    unawaited(run());
  }

  Future<void> _runToolbarSearchApplyAsync({
    required int generation,
    required Future<void> Function() apply,
  }) async {
    if (!mounted || !widget.dataSet.isOpen) {
      return;
    }
    if (generation != _toolbarSearchGeneration) {
      return;
    }

    _ui.toolbarSearch.applyInFlight = true;
    try {
      await apply();
      if (!mounted || generation != _toolbarSearchGeneration) {
        return;
      }
      _applyGridState(() {});
    } on Object catch (error, stackTrace) {
      if (!mounted || generation != _toolbarSearchGeneration) {
        return;
      }
      _handleGridAsyncOperationError(
        error,
        stackTrace,
        operation: 'applying a grid toolbar search',
      );
    } finally {
      _ui.toolbarSearch.applyInFlight = false;
      final queuedApply = _ui.toolbarSearch.queuedApply;
      _ui.toolbarSearch.queuedApply = null;
      if (queuedApply != null && mounted && widget.dataSet.isOpen) {
        scheduleMicrotask(() {
          if (!mounted || !widget.dataSet.isOpen) {
            return;
          }
          unawaited(queuedApply());
        });
      }
    }
  }

  bool _openToolbarSearchFromShortcut() {
    if (!widget.toolbar.visible ||
        _firstVisibleToolbarSearchBar() == null ||
        !_canSearch()) {
      return false;
    }

    return _runtime.domains.toolbar.searchController.openAndFocus(
      onClosedByEscape: _restoreGridFocusAfterToolbarSearch,
    );
  }

  FdcGridSearchBar? _firstVisibleToolbarSearchBar() {
    for (final item in widget.toolbar.items) {
      if (item is FdcGridSearchBar && item.visible) {
        return item;
      }
    }
    return null;
  }

  void _restoreGridFocusAfterToolbarSearch() {
    if (!mounted || _editingCell != null) {
      return;
    }

    _focusGridForSelectedCellAfterLayout();
  }

  FdcValueFormatter _createValueFormatter(FdcFormatSettings settings) {
    return FdcValueFormatter(
      settings: settings,
      translations: _translations,
      decimalScaleResolver: (column, {runtimeColumnId}) =>
          _fieldMetadata(column.fieldName).decimalScale,
    );
  }
}
