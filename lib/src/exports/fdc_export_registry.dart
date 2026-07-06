// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_export_format.dart';
import 'fdc_export_writer.dart';
import 'writers/fdc_csv_export_writer.dart';
import 'writers/fdc_json_export_writer.dart';
import 'writers/fdc_xml_export_writer.dart';

/// Global registry of export writers available to FDC.
///
/// The Community package registers its built-in CSV, JSON, and XML writers.
/// Extension packages can add formats without coupling the core package to
/// those packages.
class FdcExportRegistry {
  FdcExportRegistry._();

  static final Map<FdcExportFormat, FdcExportWriter> _writers =
      <FdcExportFormat, FdcExportWriter>{
        FdcExportFormat.csv: const FdcCsvExportWriter(),
        FdcExportFormat.json: const FdcJsonExportWriter(),
        FdcExportFormat.xml: const FdcXmlExportWriter(),
      };

  /// Registers or replaces the writer for [format].
  static void register(FdcExportFormat format, FdcExportWriter writer) {
    _writers[format] = writer;
  }

  /// Returns whether a writer is registered for [format].
  static bool contains(FdcExportFormat format) => _writers.containsKey(format);

  /// Returns the writer registered for [format], or `null` when none exists.
  static FdcExportWriter? writerFor(FdcExportFormat format) => _writers[format];

  /// Immutable snapshot of all currently registered export formats.
  static List<FdcExportFormat> get formats =>
      List<FdcExportFormat>.unmodifiable(_writers.keys);
}
