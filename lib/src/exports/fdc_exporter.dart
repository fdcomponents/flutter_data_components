// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../data/fdc_data.dart';
import '../data/fdc_dataset.dart' show FdcDataSetInternal;
import 'fdc_export_column.dart';
import 'fdc_export_format.dart';
import 'fdc_export_options.dart';
import 'fdc_export_registry.dart';
import 'fdc_export_result.dart';
import 'fdc_export_scope.dart';
import 'fdc_export_style.dart';
import 'fdc_export_writer.dart';
import 'fdc_export_writer_options.dart';
import 'writers/fdc_export_writer_context.dart';

/// Coordinates FDC exports by resolving rows, columns and format writers.
///
/// Use [exportDataSet] for dataset-aware row scopes or [exportRows] when a grid
/// or custom source has already materialized the exact row and column shape to
/// export.
class FdcExporter {
  const FdcExporter._();

  /// Exports rows from [dataSet] using the requested [format].
  ///
  /// Pass [writer] for extension/custom formats. If [writer] is omitted, the
  /// exporter resolves the writer registered for the requested format.
  static Future<FdcExportResult> exportDataSet(
    FdcDataSet dataSet, {
    required FdcExportFormat format,
    FdcExportOptions? options,
    FdcExportWriter? writer,
    String? suggestedFileName,
    FdcExportWriterOptions? writerOptions,
    FdcExportStyle exportStyle = const FdcExportStyle(),
  }) {
    final resolvedOptions = options ?? FdcExportOptions();
    final columns = _resolveColumns(dataSet, resolvedOptions);
    final rows = _resolveRows(dataSet, resolvedOptions);
    return exportRows(
      format: format,
      columns: columns,
      rows: rows,
      options: resolvedOptions,
      writer: writer,
      suggestedFileName: suggestedFileName,
      writerOptions: writerOptions,
      exportStyle: exportStyle,
    );
  }

  /// Exports already resolved [rows] and [columns] using [format].
  ///
  /// Grid adapters and future data sources can use this when they need custom
  /// column ordering, visible-column export, computed values, or non-dataset
  /// row sources while still reusing registered format writers.
  static Future<FdcExportResult> exportRows({
    required FdcExportFormat format,
    required List<FdcExportColumn> columns,
    required Iterable<Map<String, Object?>> rows,
    FdcExportOptions? options,
    FdcExportWriter? writer,
    String? suggestedFileName,
    FdcExportWriterOptions? writerOptions,
    FdcExportStyle exportStyle = const FdcExportStyle(),
  }) async {
    final resolvedOptions = options ?? FdcExportOptions();
    final resolvedWriter = writer ?? FdcExportRegistry.writerFor(format);
    if (resolvedWriter == null) {
      throw UnsupportedError(
        'No FDC export writer is registered for ${format.id}. '
        'Pass a custom FdcExportWriter for extension formats.',
      );
    }

    final context = FdcExportWriterContext(
      format: format,
      options: resolvedOptions,
      columns: List<FdcExportColumn>.unmodifiable(columns),
      rows: List<Map<String, Object?>>.unmodifiable(rows),
      suggestedFileName: suggestedFileName,
      writerOptions: writerOptions,
      exportStyle: exportStyle,
    );

    return FdcExportResult(
      format: format,
      payload: await resolvedWriter.write(context),
      mimeType: format.mimeType,
      fileExtension: format.fileExtension,
      suggestedFileName: suggestedFileName,
    );
  }

  static List<FdcExportColumn> _resolveColumns(
    FdcDataSet dataSet,
    FdcExportOptions options,
  ) {
    if (options.columns.isNotEmpty) {
      return List<FdcExportColumn>.unmodifiable(options.columns);
    }

    return List<FdcExportColumn>.unmodifiable(
      dataSet.fields
          .where(
            (field) => options.includeNonPersistentFields || field.isPersistent,
          )
          .map(
            (field) => FdcExportColumn(
              fieldName: field.name,
              label: field.label ?? field.name,
            ),
          ),
    );
  }

  static List<Map<String, Object?>> _resolveRows(
    FdcDataSet dataSet,
    FdcExportOptions options,
  ) {
    final includeNonPersistent =
        options.includeNonPersistentFields || options.columns.isNotEmpty;

    switch (options.scope) {
      case FdcExportScope.allRows:
        return FdcDataSetInternal.allRows(
          dataSet,
          includeNonPersistent: includeNonPersistent,
        );
      case FdcExportScope.currentView:
        return dataSet.toMaps(includeNonPersistent: includeNonPersistent);
      case FdcExportScope.selectedRows:
        return dataSet.selection.rows(
          includeNonPersistent: includeNonPersistent,
        );
      case FdcExportScope.currentRow:
        if (!FdcDataSetInternal.hasCurrentRecord(dataSet)) {
          return const <Map<String, Object?>>[];
        }
        return <Map<String, Object?>>[
          FdcDataSetInternal.rowMapAt(
            dataSet,
            FdcDataSetInternal.activeIndex(dataSet),
            includeNonPersistent: includeNonPersistent,
          ),
        ];
      case FdcExportScope.changedRows:
        return _changedRows(dataSet);
    }
  }

  static List<Map<String, Object?>> _changedRows(FdcDataSet dataSet) {
    final changeSet = dataSet.changeSet;
    return <Map<String, Object?>>[
      for (final row in changeSet.inserts) row.values,
      for (final row in changeSet.updates) row.values,
      for (final row in changeSet.deletes) row.values,
    ];
  }
}
