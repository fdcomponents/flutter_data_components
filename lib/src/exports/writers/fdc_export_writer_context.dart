// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../data/fdc_field_name.dart';
import '../fdc_export_column.dart';
import '../fdc_export_format.dart';
import '../fdc_export_options.dart';
import '../fdc_export_style.dart';
import '../fdc_export_writer_options.dart';
import 'fdc_export_value.dart';

/// Immutable export request passed to an `FdcExportWriter`.
///
/// The exporter resolves row scope and column order before creating this
/// context. Writers can then focus exclusively on format serialization.
class FdcExportWriterContext {
  /// Creates a [FdcExportWriterContext].
  const FdcExportWriterContext({
    required this.format,
    required this.options,
    required this.columns,
    required this.rows,
    this.suggestedFileName,
    this.writerOptions,
    this.exportStyle = const FdcExportStyle(),
  });

  /// Requested output format.
  final FdcExportFormat format;

  /// Cross-format export options for this request.
  final FdcExportOptions options;

  /// Export columns in output order.
  final List<FdcExportColumn> columns;

  /// Materialized row values in export order.
  final List<Map<String, Object?>> rows;

  /// Optional file name hint propagated from the export caller.
  final String? suggestedFileName;

  /// Format-specific options supplied by the export caller.
  final FdcExportWriterOptions? writerOptions;

  /// App/subtree-level format styles supplied by the UI export host.
  final FdcExportStyle exportStyle;

  /// Resolves the source value for [column] from [row].
  ///
  /// Resolution first checks [FdcExportColumn.fieldName], then the computed
  /// output key, then the normalized field name used by FDC field lookup.
  Object? valueFor(Map<String, Object?> row, FdcExportColumn column) {
    final sourceKey = column.fieldName;
    if (row.containsKey(sourceKey)) {
      return row[sourceKey];
    }

    final outputKey = keyFor(column);
    if (row.containsKey(outputKey)) {
      return row[outputKey];
    }

    return row[FdcFieldName.normalize(sourceKey)];
  }

  /// Returns presentation text for writers such as PDF.
  String displayTextFor(Map<String, Object?> row, FdcExportColumn column) {
    final value = valueFor(row, column);
    final formatter = column.valueFormatter;
    if (formatter != null) {
      return formatter(value);
    }
    return exportTextValue(value, options.valueMode);
  }

  /// Returns the object-oriented output key for [column].
  String keyFor(FdcExportColumn column) {
    return column.key ?? column.label ?? column.fieldName;
  }

  /// Returns the XML-oriented element name candidate for [column].
  String elementNameFor(FdcExportColumn column) {
    return column.key ?? column.fieldName;
  }

  /// Returns the human-readable tabular header for [column].
  String headerFor(FdcExportColumn column) {
    return column.label ?? column.key ?? column.fieldName;
  }
}
