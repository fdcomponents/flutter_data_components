// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Export orchestration, format contracts, writers, and export value models.
///
/// Use this entrypoint when a feature only needs to transform dataset or row
/// data into export payloads. The Community package includes text-oriented
/// formats and the writer extension seam used by add-on formats.
///
/// ```dart
/// import 'package:flutter_data_components/fdc_export.dart';
/// ```
///
/// `FdcExporter` resolves rows and columns, then delegates serialization to a
/// registered `FdcExportWriter`. Custom writers can be registered for extension
/// formats without changing the dataset or grid layer.
library;

export 'src/exports/fdc_export.dart';
