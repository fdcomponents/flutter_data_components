// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';

import '../fdc_export_value_mode.dart';

/// Normalizes a value for object-oriented export formats.
Object? normalizeExportValue(Object? value, FdcExportValueMode mode) {
  if (value == null) {
    return null;
  }
  if (mode == FdcExportValueMode.display) {
    return value.toString();
  }
  if (value is String || value is bool || value is int) {
    return value;
  }
  if (value is double) {
    return value.isFinite ? value : value.toString();
  }
  if (value is num) {
    return value;
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }
  if (value is Iterable) {
    return value.map((item) => normalizeExportValue(item, mode)).toList();
  }
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key.toString(): normalizeExportValue(entry.value, mode),
    };
  }
  return value.toString();
}

/// Converts a value to text for text-oriented export formats.
String exportTextValue(Object? value, FdcExportValueMode mode) {
  final normalized = normalizeExportValue(value, mode);
  if (normalized == null) {
    return '';
  }
  if (normalized is String) {
    return normalized;
  }
  if (normalized is DateTime) {
    return normalized.toIso8601String();
  }
  if (normalized is Iterable || normalized is Map) {
    return jsonEncode(normalized);
  }
  return normalized.toString();
}
