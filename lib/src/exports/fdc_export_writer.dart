// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'fdc_export_payload.dart';
import 'writers/fdc_export_writer_context.dart';

/// Contract implemented by built-in and extension export format writers.
///
/// Writers receive fully resolved columns and rows through
/// [FdcExportWriterContext] and return either text or binary payload content.
abstract interface class FdcExportWriter {
  /// Serializes [context] into an export payload.
  FutureOr<FdcExportPayload> write(FdcExportWriterContext context);
}
