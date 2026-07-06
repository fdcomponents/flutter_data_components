// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';
import 'dart:typed_data';

/// Serialized content produced by an `FdcExportWriter`.
///
/// Consumers can always read [bytes]. [text] is non-null only for textual
/// payloads.
sealed class FdcExportPayload {
  /// Creates a [FdcExportPayload].
  const FdcExportPayload();

  /// Serialized bytes for this payload.
  Uint8List get bytes;

  /// Text content, or `null` when the payload is binary.
  String? get text;
}

/// UTF-8 text payload returned by text-based export writers.
final class FdcTextExportPayload extends FdcExportPayload {
  /// Creates a [FdcTextExportPayload].
  const FdcTextExportPayload(this.value);

  /// Unencoded text content.
  final String value;
  @override
  String get text => value;

  @override
  Uint8List get bytes => Uint8List.fromList(utf8.encode(value));
}

/// Binary payload returned by writers such as PDF or spreadsheet exporters.
final class FdcBinaryExportPayload extends FdcExportPayload {
  /// Creates a [FdcBinaryExportPayload].
  FdcBinaryExportPayload(List<int> value) : value = Uint8List.fromList(value);

  /// Binary content carried by this payload.
  final Uint8List value;

  @override
  String? get text => null;

  @override
  Uint8List get bytes => value;
}
