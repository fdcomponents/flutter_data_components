// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../fdc_export_payload.dart';
import '../fdc_export_writer.dart';
import 'fdc_export_value.dart';
import 'fdc_export_writer_context.dart';

/// Serializes export rows as RFC-style escaped CSV text using the delimiter,
/// line terminator, header and spreadsheet-formula sanitization options from
/// the export options carried by the writer context.
class FdcCsvExportWriter implements FdcExportWriter {
  /// Creates a CSV export writer.
  const FdcCsvExportWriter();

  @override
  FdcExportPayload write(FdcExportWriterContext context) {
    final buffer = StringBuffer();
    final delimiter = context.options.csvDelimiter;
    final lineTerminator = context.options.lineTerminator;

    if (context.options.includeHeaders) {
      buffer
        ..writeAll([
          for (final column in context.columns)
            _escape(
              _sanitizeSpreadsheetFormula(
                context.headerFor(column),
                enabled: context.options.sanitizeSpreadsheetFormulas,
              ),
              delimiter,
            ),
        ], delimiter)
        ..write(lineTerminator);
    }

    for (final row in context.rows) {
      buffer
        ..writeAll([
          for (final column in context.columns)
            _escape(
              _sanitizeSpreadsheetFormula(
                exportTextValue(
                  context.valueFor(row, column),
                  context.options.valueMode,
                ),
                enabled:
                    context.options.sanitizeSpreadsheetFormulas &&
                    context.valueFor(row, column) is String,
              ),
              delimiter,
            ),
        ], delimiter)
        ..write(lineTerminator);
    }

    return FdcTextExportPayload(buffer.toString());
  }

  String _sanitizeSpreadsheetFormula(String value, {required bool enabled}) {
    if (!enabled || !RegExp(r'^[\u0000-\u0020]*[=+\-@]').hasMatch(value)) {
      return value;
    }
    return "'$value";
  }

  String _escape(String value, String delimiter) {
    final mustQuote =
        value.contains(delimiter) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!mustQuote) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }
}
