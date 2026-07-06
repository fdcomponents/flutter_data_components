// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Formats a source value as presentation text for presentation-oriented writers.
///
/// The formatter is typically supplied by a grid column so exports such as PDF
/// can preserve the same display formatting, prefixes and suffixes shown in the
/// UI.
typedef FdcExportValueFormatter = String Function(Object? value);

/// Horizontal alignment hint used by presentation-oriented export writers.
enum FdcExportTextAlignment {
  /// Align exported text to the logical start edge.
  left,

  /// Center exported text.
  center,

  /// Align exported text to the logical end edge.
  right,
}

/// Maps one source field to its exported identity and presentation metadata.
///
/// [fieldName] identifies the value in each source row. Object-oriented writers
/// can use [key], tabular writers can use [label] as a header, and
/// presentation-oriented writers can honor [valueFormatter] and
/// [textAlignment].
class FdcExportColumn {
  /// Creates a [FdcExportColumn].
  const FdcExportColumn({
    required this.fieldName,
    this.key,
    this.label,
    this.valueFormatter,
    this.textAlignment = FdcExportTextAlignment.left,
  });

  /// Source field name used to resolve the value from each row.
  final String fieldName;

  /// Stable output key used by object-oriented formats such as JSON.
  ///
  /// When omitted, writers fall back to [label] or [fieldName], depending on
  /// the format-specific contract.
  final String? key;

  /// Human-readable header used by tabular and presentation-oriented writers.
  final String? label;

  /// Optional display formatter supplied by a presentation source such as a
  /// grid.
  ///
  /// Raw/object-oriented writers may continue to use the original value.
  /// Presentation writers such as PDF can use this formatter to preserve the
  /// exact FDC format settings and column display affixes.
  final FdcExportValueFormatter? valueFormatter;

  /// Preferred text alignment for writers that render positioned text.
  final FdcExportTextAlignment textAlignment;

  /// Returns a copy with the supplied properties replaced.
  FdcExportColumn copyWith({
    String? fieldName,
    String? key,
    String? label,
    FdcExportValueFormatter? valueFormatter,
    FdcExportTextAlignment? textAlignment,
  }) {
    return FdcExportColumn(
      fieldName: fieldName ?? this.fieldName,
      key: key ?? this.key,
      label: label ?? this.label,
      valueFormatter: valueFormatter ?? this.valueFormatter,
      textAlignment: textAlignment ?? this.textAlignment,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcExportColumn &&
            fieldName == other.fieldName &&
            key == other.key &&
            label == other.label &&
            valueFormatter == other.valueFormatter &&
            textAlignment == other.textAlignment;
  }

  @override
  int get hashCode =>
      Object.hash(fieldName, key, label, valueFormatter, textAlignment);
}
