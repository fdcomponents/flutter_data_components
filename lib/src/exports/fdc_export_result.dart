// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:typed_data';

import 'fdc_export_format.dart';
import 'fdc_export_payload.dart';

/// Completed export together with its format metadata and serialized payload.
class FdcExportResult {
  /// Creates a [FdcExportResult].
  const FdcExportResult({
    required this.format,
    required this.payload,
    required this.mimeType,
    required this.fileExtension,
    this.suggestedFileName,
  });

  /// Format requested for this export.
  final FdcExportFormat format;

  /// Serialized content produced by the resolved writer.
  final FdcExportPayload payload;

  /// MIME type advertised by [format].
  final String mimeType;

  /// File extension advertised by [format], without a leading dot.
  final String fileExtension;

  /// Optional caller-supplied file name hint for save/share UI.
  final String? suggestedFileName;

  /// Text content for textual formats.
  ///
  /// Throws when the writer produced a binary payload. Use [textOrNull] when
  /// handling both textual and binary formats.
  String get text =>
      payload.text ??
      (throw StateError('Export format ${format.id} produced binary content.'));

  /// Text content, or `null` for binary formats such as PDF.
  String? get textOrNull => payload.text;

  /// Serialized bytes for every export format.
  Uint8List get bytes => payload.bytes;

  /// Backwards-compatible alias for [bytes].
  Uint8List get utf8Bytes => bytes;
}
