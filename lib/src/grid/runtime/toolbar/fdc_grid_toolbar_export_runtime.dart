// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridToolbarExportRuntime on _FdcGridState {
  bool _canExport() {
    return widget.dataSet.isOpen &&
        widget.dataSet.recordCount > 0 &&
        !FdcDataSetInternal.hasActiveEdit(widget.dataSet);
  }

  Future<void> _handleToolbarExportRequested(
    FdcGridExportButton exportButton,
    FdcExportFormat format,
  ) async {
    final callback = exportButton.onExport;
    if (callback == null || !_canExport()) {
      return;
    }

    final dataSet = widget.dataSet;
    try {
      final columns =
          exportButton.columnMode == FdcGridExportColumnMode.visibleColumns
          ? _toolbarVisibleExportColumns()
          : const <FdcExportColumn>[];
      final result = await FdcExporter.exportDataSet(
        dataSet,
        format: format,
        options: exportButton.toExportOptions(columns: columns),
        writerOptions: exportButton.writerOptions[format],
        exportStyle: FdcApp.exportStyleOf(context),
      );
      if (!mounted || !identical(widget.dataSet, dataSet) || !dataSet.isOpen) {
        return;
      }
      _runGridAppCallback(() {
        callback(result);
      });
    } on Object catch (error, stackTrace) {
      if (!mounted || !identical(widget.dataSet, dataSet)) {
        return;
      }
      _handleGridAsyncOperationError(
        error,
        stackTrace,
        operation: 'exporting grid data',
      );
    }
  }

  List<FdcExportColumn> _toolbarVisibleExportColumns() {
    final usedKeys = <String, int>{};
    return <FdcExportColumn>[
      for (final column in _visibleColumns)
        if (column.isDataBound && column.exportable)
          FdcExportColumn(
            fieldName: column.fieldName,
            key: _uniqueToolbarExportKey(_columnLabel(column), usedKeys),
            label: _columnLabel(column),
            valueFormatter: (value) => _valueFormatter.format(column, value),
            textAlignment: column is FdcDecimalColumn<dynamic>
                ? FdcExportTextAlignment.right
                : FdcExportTextAlignment.left,
          ),
    ];
  }

  String _uniqueToolbarExportKey(String label, Map<String, int> usedKeys) {
    final trimmed = label.trim();
    final base = trimmed.isEmpty ? 'Column' : trimmed;
    final next = (usedKeys[base] ?? 0) + 1;
    usedKeys[base] = next;
    if (next == 1) {
      return base;
    }
    return '${base}_$next';
  }
}
