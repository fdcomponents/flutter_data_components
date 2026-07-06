// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/services.dart';

/// Small internal helper for editor text-session bookkeeping.
///
/// Standalone editors and grid cell editors both need the same low-level
/// semantics: a committed/baseline text value, local dirty/error state, and
/// collapsed controller updates after commit/revert/picker flows. Keep those
/// mechanics centralized so higher-level widgets can focus on their own data
/// binding and focus policies.
class FdcEditorTextSession {
  const FdcEditorTextSession._();

  /// Creates a collapsed text editing value with the caret at the end.
  static TextEditingValue collapsedValue(String text) {
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Whether local editor state differs from the committed baseline.
  static bool hasLocalEditToRevert({
    required bool dirty,
    required String? localErrorText,
    required String controllerText,
    required String baselineText,
  }) {
    return dirty || localErrorText != null || controllerText != baselineText;
  }

  /// Whether the editor has no local changes that need committing.
  static bool isCleanForCommit({
    required bool dirty,
    required String? localErrorText,
    required bool localErrorBlocksCommit,
  }) {
    return !dirty && (localErrorText == null || !localErrorBlocksCommit);
  }
}
