// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Marker base type for format-specific writer configuration.
///
/// Pass an instance through `FdcExporter.exportDataSet` or
/// `FdcExporter.exportRows`; the selected writer is responsible for validating
/// and interpreting the concrete subtype.
///
/// Extension packages can define strongly typed option objects without making
/// the Community package depend on those packages.
abstract class FdcExportWriterOptions {
  /// Creates a [FdcExportWriterOptions].
  const FdcExportWriterOptions();
}
