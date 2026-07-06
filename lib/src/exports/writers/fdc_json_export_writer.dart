// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';

import '../fdc_export_payload.dart';
import '../fdc_export_writer.dart';
import 'fdc_export_value.dart';
import 'fdc_export_writer_context.dart';

/// Serializes export rows as an indented JSON array of objects.
///
/// Column output keys come from [FdcExportWriterContext.keyFor], and values are
/// normalized according to the configured export value mode.
class FdcJsonExportWriter implements FdcExportWriter {
  /// Creates a JSON export writer.
  const FdcJsonExportWriter();

  @override
  FdcExportPayload write(FdcExportWriterContext context) {
    final rows = <Map<String, Object?>>[
      for (final row in context.rows)
        <String, Object?>{
          for (final column in context.columns)
            context.keyFor(column): normalizeExportValue(
              context.valueFor(row, column),
              context.options.valueMode,
            ),
        },
    ];
    return FdcTextExportPayload(
      const JsonEncoder.withIndent('  ').convert(rows),
    );
  }
}
