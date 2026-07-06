// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Internal wrapper used by FDC dialogs to make modal keyboard ownership
/// independent from the grid or any other control that opened the dialog.
///
/// Flutter's modal barrier already blocks pointer input below the dialog. This
/// scope also owns keyboard focus while the dialog is open. If focus is forced
/// back to a control below the dialog, the scope reclaims focus on the next
/// frame and consumes leaked key events.
class FdcModalDialogScope extends StatefulWidget {
  const FdcModalDialogScope({
    super.key,
    required this.child,
    this.preferredFocusNode,
    this.onDismiss,
    this.onActivateDefault,
    this.onMovePrevious,
    this.onMoveNext,
  });

  final Widget child;
  final FocusNode? preferredFocusNode;
  final VoidCallback? onDismiss;
  final VoidCallback? onActivateDefault;
  final VoidCallback? onMovePrevious;
  final VoidCallback? onMoveNext;

  @override
  State<FdcModalDialogScope> createState() => _FdcModalDialogScopeState();
}

class _FdcModalDialogScopeState extends State<FdcModalDialogScope> {
  final FocusScopeNode _scopeNode = FocusScopeNode(
    debugLabel: 'FdcModalDialogScope',
  );

  bool _claimingFocus = false;
  bool _reclaimScheduled = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    FocusManager.instance.addListener(_handlePrimaryFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _claimDialogFocus();
    });
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handlePrimaryFocusChanged);
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _scopeNode.dispose();
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!mounted) {
      return false;
    }

    if (_isFocusInsideDialog(FocusManager.instance.primaryFocus)) {
      return false;
    }

    _claimDialogFocus();

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        final dismiss = widget.onDismiss;
        if (dismiss != null) {
          dismiss();
        } else {
          unawaited(Navigator.of(context).maybePop());
        }
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        widget.onActivateDefault?.call();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        widget.onMovePrevious?.call();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        widget.onMoveNext?.call();
        return true;
      }
    }

    return true;
  }

  void _handlePrimaryFocusChanged() {
    if (!mounted || _claimingFocus || _reclaimScheduled) {
      return;
    }

    if (_isFocusInsideDialog(FocusManager.instance.primaryFocus)) {
      return;
    }

    _scheduleFocusReclaim();
  }

  void _scheduleFocusReclaim() {
    _reclaimScheduled = true;

    unawaited(
      Future<void>.microtask(() {
        if (!mounted || _claimingFocus) {
          return;
        }

        if (!_isFocusInsideDialog(FocusManager.instance.primaryFocus)) {
          _claimDialogFocus();
        }
      }),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reclaimScheduled = false;
      if (!mounted || _claimingFocus) {
        return;
      }

      if (_isFocusInsideDialog(FocusManager.instance.primaryFocus)) {
        return;
      }

      _claimDialogFocus();
    });
  }

  bool _isFocusInsideDialog(FocusNode? node) {
    var current = node;
    while (current != null) {
      if (identical(current, _scopeNode)) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  void _claimDialogFocus() {
    if (!mounted || _claimingFocus) {
      return;
    }

    final primaryFocus = FocusManager.instance.primaryFocus;
    if (_isFocusInsideDialog(primaryFocus) &&
        primaryFocus != _scopeNode &&
        primaryFocus?.canRequestFocus == true) {
      return;
    }

    _claimingFocus = true;
    try {
      final preferred = widget.preferredFocusNode;
      if (preferred != null && preferred.canRequestFocus) {
        preferred.requestFocus();
        return;
      }

      final focusedChild = _scopeNode.focusedChild;
      if (focusedChild != null && focusedChild.canRequestFocus) {
        focusedChild.requestFocus();
        return;
      }

      FocusNode? focusableDescendant;
      for (final node in _scopeNode.traversalDescendants) {
        if (node.canRequestFocus) {
          focusableDescendant = node;
          break;
        }
      }

      if (focusableDescendant != null) {
        focusableDescendant.requestFocus();
        return;
      }

      _scopeNode.requestFocus();
    } finally {
      _claimingFocus = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _scopeNode,
      autofocus: true,
      canRequestFocus: true,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        },
        child: widget.child,
      ),
    );
  }
}
