// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../data/fdc_dataset.dart';
import 'fdc_lookup_result.dart';

/// Shared context passed to grid and standalone editor lookup callbacks.
///
/// The context intentionally exposes only neutral lookup state. It does not
/// expose grid/editor-specific coordinates so the same callback can be reused
/// from a grid column or a standalone data-aware editor.
class FdcLookupContext {
  /// Creates a [FdcLookupContext].
  FdcLookupContext({
    required this.buildContext,
    required this.dataSet,
    required this.fieldName,
    required this.lookupText,
    required this.lookupMode,
    Object? Function(String fieldName)? valueOf,
  }) : _valueOf = valueOf;

  /// Flutter context of the editor or grid surface invoking the lookup.
  final BuildContext buildContext;

  /// Dataset whose current record is being edited.
  final FdcDataSet dataSet;

  /// Name of the field that initiated the lookup.
  final String fieldName;

  /// Text used as lookup input.
  ///
  /// When a lookup is invoked from an active editor this is the current raw
  /// editor text, including an empty string when the user cleared the editor.
  /// When interactive search is invoked without an active editor this is the
  /// current field contents formatted as text, or `null` when the field value
  /// itself is `null`/not textually available.
  final String? lookupText;

  /// Whether the lookup was invoked for interactive search UI or silent
  /// resolve-on-commit behavior.
  final FdcLookupMode lookupMode;

  /// Field-value resolver used to expose the active edit buffer consistently.
  final Object? Function(String fieldName)? _valueOf;

  /// Returns the current value of [fieldName].
  V? valueOf<V>(String fieldName) {
    final resolver = _valueOf;
    if (resolver != null) {
      return resolver(fieldName) as V?;
    }
    return dataSet.fieldValue(fieldName) as V?;
  }

  /// Returns the current value of [fieldName], or `null` if unavailable.
  V? tryValueOf<V>(String fieldName) {
    try {
      final resolver = _valueOf;
      final value = resolver != null
          ? resolver(fieldName)
          : dataSet.fieldValue(fieldName);
      if (value == null || value is V) {
        return value as V?;
      }
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return null;
      // ignore: avoid_catching_errors
    } on StateError {
      return null;
    }
    return null;
  }
}
