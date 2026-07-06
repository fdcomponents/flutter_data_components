// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart' show listEquals;

import 'fdc_export_column.dart';
import 'fdc_export_scope.dart';
import 'fdc_export_value_mode.dart';

/// Cross-format options that control row selection, column selection and text
/// serialization behavior for FDC exports.
///
/// Format-specific settings belong in writer-specific option types; these options
/// define behavior shared by dataset/grid export orchestration and the built-in
/// CSV, JSON and XML writers.
class FdcExportOptions {
  /// Creates a [FdcExportOptions].
  FdcExportOptions({
    this.scope = FdcExportScope.currentView,
    this.valueMode = FdcExportValueMode.raw,
    this.includeHeaders = true,
    this.includeNonPersistentFields = false,
    this.columns = const <FdcExportColumn>[],
    this.csvDelimiter = ',',
    this.lineTerminator = '\n',
    this.rootElementName = 'rows',
    this.rowElementName = 'row',
    this.sanitizeSpreadsheetFormulas = true,
  }) {
    _validateCsvDelimiter(csvDelimiter);
    _validateLineTerminator(lineTerminator);
    _validateXmlElementName(rootElementName, 'rootElementName');
    _validateXmlElementName(rowElementName, 'rowElementName');
  }

  /// Selects which dataset rows are included when exporting through
  /// `FdcExporter.exportDataSet`.
  final FdcExportScope scope;

  /// Controls whether writers preserve typed values where possible or convert
  /// them to display-oriented text.
  final FdcExportValueMode valueMode;

  /// Whether tabular writers emit a header row before the exported data rows.
  final bool includeHeaders;

  /// Whether automatically inferred columns may include non-persistent fields.
  ///
  /// This option affects only automatic column resolution. Explicit [columns]
  /// are exported as supplied.
  final bool includeNonPersistentFields;

  /// Optional explicit export column list.
  ///
  /// When empty, columns are inferred from the dataset field definitions.
  final List<FdcExportColumn> columns;

  /// CSV field delimiter. Must be non-empty and cannot contain quotes or line
  /// breaks. Defaults to `,`.
  final String csvDelimiter;

  /// Line terminator used by built-in text writers.
  ///
  /// Valid values are `\n`, `\r\n` and `\r`.
  final String lineTerminator;

  /// Root element name used by the built-in XML writer.
  final String rootElementName;

  /// Element name used for each exported row by the built-in XML writer.
  final String rowElementName;

  /// Prefixes spreadsheet-like text formulas with an apostrophe.
  ///
  /// This protects CSV and spreadsheet exports from interpreting untrusted text
  /// that starts with `=`, `+`, `-`, or `@` as an executable formula.
  final bool sanitizeSpreadsheetFormulas;

  /// Returns a copy with the supplied properties replaced.
  FdcExportOptions copyWith({
    FdcExportScope? scope,
    FdcExportValueMode? valueMode,
    bool? includeHeaders,
    bool? includeNonPersistentFields,
    List<FdcExportColumn>? columns,
    String? csvDelimiter,
    String? lineTerminator,
    String? rootElementName,
    String? rowElementName,
    bool? sanitizeSpreadsheetFormulas,
  }) {
    return FdcExportOptions(
      scope: scope ?? this.scope,
      valueMode: valueMode ?? this.valueMode,
      includeHeaders: includeHeaders ?? this.includeHeaders,
      includeNonPersistentFields:
          includeNonPersistentFields ?? this.includeNonPersistentFields,
      columns: columns ?? this.columns,
      csvDelimiter: csvDelimiter ?? this.csvDelimiter,
      lineTerminator: lineTerminator ?? this.lineTerminator,
      rootElementName: rootElementName ?? this.rootElementName,
      rowElementName: rowElementName ?? this.rowElementName,
      sanitizeSpreadsheetFormulas:
          sanitizeSpreadsheetFormulas ?? this.sanitizeSpreadsheetFormulas,
    );
  }

  static void _validateCsvDelimiter(String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'csvDelimiter', 'must not be empty.');
    }
    if (value.contains('\r') || value.contains('\n')) {
      throw ArgumentError.value(
        value,
        'csvDelimiter',
        'must not contain line-break characters.',
      );
    }
    if (value.contains('"')) {
      throw ArgumentError.value(
        value,
        'csvDelimiter',
        'must not contain the CSV quote character.',
      );
    }
  }

  static void _validateLineTerminator(String value) {
    if (value != '\n' && value != '\r\n' && value != '\r') {
      throw ArgumentError.value(
        value,
        'lineTerminator',
        r'must be "\n", "\r\n", or "\r".',
      );
    }
  }

  static void _validateXmlElementName(String value, String argumentName) {
    final isValid =
        RegExp(r'^[A-Za-z_][A-Za-z0-9._-]*$').hasMatch(value) &&
        !value.toLowerCase().startsWith('xml');
    if (!isValid) {
      throw ArgumentError.value(
        value,
        argumentName,
        'must be a valid simple XML element name and must not start with xml.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcExportOptions &&
            scope == other.scope &&
            valueMode == other.valueMode &&
            includeHeaders == other.includeHeaders &&
            includeNonPersistentFields == other.includeNonPersistentFields &&
            listEquals(columns, other.columns) &&
            csvDelimiter == other.csvDelimiter &&
            lineTerminator == other.lineTerminator &&
            rootElementName == other.rootElementName &&
            rowElementName == other.rowElementName &&
            sanitizeSpreadsheetFormulas == other.sanitizeSpreadsheetFormulas;
  }

  @override
  int get hashCode => Object.hash(
    scope,
    valueMode,
    includeHeaders,
    includeNonPersistentFields,
    Object.hashAll(columns),
    csvDelimiter,
    lineTerminator,
    rootElementName,
    rowElementName,
    sanitizeSpreadsheetFormulas,
  );
}
