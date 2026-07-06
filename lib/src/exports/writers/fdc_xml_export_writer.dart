// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../fdc_export_payload.dart';
import '../fdc_export_writer.dart';
import 'fdc_export_value.dart';
import 'fdc_export_writer_context.dart';

/// Serializes export rows as XML using the configured root and row element
/// names and one child element per export column.
class FdcXmlExportWriter implements FdcExportWriter {
  /// Creates an XML export writer.
  const FdcXmlExportWriter();

  @override
  FdcExportPayload write(FdcExportWriterContext context) {
    final buffer = StringBuffer()
      ..write('<?xml version="1.0" encoding="utf-8"?>')
      ..write(context.options.lineTerminator)
      ..write('<${_name(context.options.rootElementName)}>')
      ..write(context.options.lineTerminator);

    for (final row in context.rows) {
      buffer
        ..write('  <${_name(context.options.rowElementName)}>')
        ..write(context.options.lineTerminator);
      for (final column in context.columns) {
        final elementName = _name(context.elementNameFor(column));
        final value = exportTextValue(
          context.valueFor(row, column),
          context.options.valueMode,
        );
        buffer
          ..write('    <$elementName>')
          ..write(_escape(value))
          ..write('</$elementName>')
          ..write(context.options.lineTerminator);
      }
      buffer
        ..write('  </${_name(context.options.rowElementName)}>')
        ..write(context.options.lineTerminator);
    }

    buffer.write('</${_name(context.options.rootElementName)}>');
    return FdcTextExportPayload(buffer.toString());
  }

  String _name(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    if (normalized.isEmpty) {
      return 'field';
    }
    if (RegExp(r'^[A-Za-z_]').hasMatch(normalized)) {
      return normalized;
    }
    return 'f_$normalized';
  }

  String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
