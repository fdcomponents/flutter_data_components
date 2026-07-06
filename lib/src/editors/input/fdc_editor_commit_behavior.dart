// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import '../core/fdc_editor_descriptor.dart';

/// Internal commit policy for standalone data-aware editors.
class FdcEditorCommitBehavior {
  const FdcEditorCommitBehavior({
    required this.commitOnBlur,
    required this.commitOnEnter,
    required this.commitOnCtrlEnter,
    required this.revertOnEscape,
  });

  /// Whether focus loss commits the current editor value.
  final bool commitOnBlur;

  /// Whether Enter commits and advances focus.
  final bool commitOnEnter;

  /// Whether Ctrl+Enter commits and advances focus.
  final bool commitOnCtrlEnter;

  /// Whether Escape reverts local editor changes.
  final bool revertOnEscape;

  /// Resolves the default commit behavior for [kind].
  static FdcEditorCommitBehavior forKind(FdcEditorKind kind) {
    return switch (kind) {
      FdcEditorKind.memo => const FdcEditorCommitBehavior(
        commitOnBlur: true,
        commitOnEnter: false,
        commitOnCtrlEnter: true,
        revertOnEscape: true,
      ),
      _ => const FdcEditorCommitBehavior(
        commitOnBlur: true,
        commitOnEnter: true,
        commitOnCtrlEnter: false,
        revertOnEscape: true,
      ),
    };
  }
}
