// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/services.dart';

import '../../common/input/fdc_key_utils.dart';
import '../core/fdc_editor_descriptor.dart';
import 'fdc_editor_commit_behavior.dart';

/// Editor-level keyboard actions resolved from raw key events.
enum FdcEditorKeyboardAction {
  /// Let Flutter's native text/input handling process the key.
  none,

  /// Consume the key without any editor action.
  block,

  /// Commit the editor and move focus to the next focusable widget.
  moveNext,

  /// Commit the editor and move focus to the previous focusable widget.
  movePrevious,

  /// Revert the local editor buffer.
  revert,
}

/// Converts Flutter key events into editor commit/navigation actions.
class FdcEditorKeyboardHandler {
  /// Creates a keyboard handler for an editor kind and commit policy.
  const FdcEditorKeyboardHandler({
    required this.kind,
    required this.commitBehavior,
  });

  /// Editor kind whose keyboard behavior is being resolved.
  final FdcEditorKind kind;

  /// Commit policy applied to Enter, Tab and Escape handling.
  final FdcEditorCommitBehavior commitBehavior;

  /// Resolves the editor action for [event].
  FdcEditorKeyboardAction handle(KeyEvent event) {
    if (!FdcKeyUtils.isKeyDownOrRepeat(event)) {
      return FdcEditorKeyboardAction.none;
    }

    if (FdcKeyUtils.isEnter(event)) {
      return _handleEnter();
    }

    if (FdcKeyUtils.isTab(event)) {
      return FdcKeyUtils.isShiftPressed
          ? FdcEditorKeyboardAction.movePrevious
          : FdcEditorKeyboardAction.moveNext;
    }

    if (FdcKeyUtils.isEscape(event)) {
      return commitBehavior.revertOnEscape
          ? FdcEditorKeyboardAction.revert
          : FdcEditorKeyboardAction.none;
    }

    if (FdcKeyUtils.isArrow(event)) {
      // Standalone editors never use arrow keys for field traversal. Keep all
      // arrows native so text controls can handle caret movement/selection.
      return FdcEditorKeyboardAction.none;
    }

    if (FdcKeyUtils.isPageKey(event)) {
      // Standalone editors do not use PageUp/PageDown for field traversal.
      // Keep them native/no-op at the editor layer, matching arrow key policy.
      return FdcEditorKeyboardAction.none;
    }

    return FdcEditorKeyboardAction.none;
  }

  FdcEditorKeyboardAction _handleEnter() {
    if (kind == FdcEditorKind.memo) {
      if (FdcKeyUtils.hasControlOrMetaPressed) {
        return commitBehavior.commitOnCtrlEnter
            ? FdcEditorKeyboardAction.moveNext
            : FdcEditorKeyboardAction.none;
      }

      // Plain Enter in memo is a native newline.
      return FdcEditorKeyboardAction.none;
    }

    return commitBehavior.commitOnEnter
        ? FdcEditorKeyboardAction.moveNext
        : FdcEditorKeyboardAction.none;
  }
}
