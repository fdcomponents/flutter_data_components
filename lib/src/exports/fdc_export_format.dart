// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

/// Export output format descriptor.
///
/// Core FDC ships built-in [json], [csv], and [xml] formats. The type is a
/// const value object instead of an enum so extension packages can define
/// additional formats without requiring the core package to know about them.
class FdcExportFormat {
  /// Creates a [FdcExportFormat].
  const FdcExportFormat(
    this.id, {
    required this.label,
    required this.fileExtension,
    required this.mimeType,
    this.icon,
  });

  /// Stable machine-readable format id.
  final String id;

  /// Human-readable label shown in menus and diagnostics.
  final String label;

  /// Default file extension without a leading dot.
  final String fileExtension;

  /// MIME type produced by this format.
  final String mimeType;

  /// Optional icon used by export menus and other format-aware UI.
  ///
  /// Custom formats may omit the icon; consumers should provide a generic
  /// file/export fallback in that case. Icon metadata is intentionally not
  /// part of format equality because it does not affect the export contract.
  final IconData? icon;

  /// Built-in JSON export format.
  static const FdcExportFormat json = FdcExportFormat(
    'json',
    label: 'JSON',
    fileExtension: 'json',
    mimeType: 'application/json',
    icon: Icons.data_object,
  );

  /// Built-in CSV export format.
  static const FdcExportFormat csv = FdcExportFormat(
    'csv',
    label: 'CSV',
    fileExtension: 'csv',
    mimeType: 'text/csv',
    icon: Icons.table_rows_outlined,
  );

  /// Built-in XML export format.
  static const FdcExportFormat xml = FdcExportFormat(
    'xml',
    label: 'XML',
    fileExtension: 'xml',
    mimeType: 'application/xml',
    icon: Icons.code_outlined,
  );

  /// Built-in formats provided by the core package.
  static const List<FdcExportFormat> builtInFormats = <FdcExportFormat>[
    csv,
    json,
    xml,
  ];

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcExportFormat &&
            id == other.id &&
            label == other.label &&
            fileExtension == other.fileExtension &&
            mimeType == other.mimeType;
  }

  @override
  int get hashCode => Object.hash(id, label, fileExtension, mimeType);

  @override
  String toString() => 'FdcExportFormat($id)';
}
