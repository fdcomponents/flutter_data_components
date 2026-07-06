// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/fdc_app.dart';
import 'fdc_modal_dialog_scope.dart';

enum FdcDialogButtonStyle { text, filled }

class FdcDialogButton<T> {
  const FdcDialogButton({
    required this.label,
    this.result,
    this.isDefault = false,
    this.isDismiss = false,
    this.style = FdcDialogButtonStyle.text,
  });

  final String label;
  final T? result;
  final bool isDefault;
  final bool isDismiss;
  final FdcDialogButtonStyle style;
}

class _FdcPreviousDialogButtonIntent extends Intent {
  const _FdcPreviousDialogButtonIntent();
}

class _FdcNextDialogButtonIntent extends Intent {
  const _FdcNextDialogButtonIntent();
}

class _ActivateDefaultButtonIntent extends Intent {
  const _ActivateDefaultButtonIntent();
}

/// Base implementation for FDC dialogs.
///
/// This widget owns only dialog behavior shared by all concrete dialogs:
///
/// * ESC dismiss behavior.
/// * Close-button dismiss behavior.
/// * Default button autofocus.
/// * Left/right keyboard movement between action buttons.
/// * Focus-aware button styling.
///
/// Modal keyboard ownership itself remains in [FdcModalDialogScope].
class FdcDialogBase<T> extends StatefulWidget {
  FdcDialogBase({
    super.key,
    required this.title,
    required this.content,
    required this.buttons,
    this.dismissResult,
    this.showCloseButton = true,
  }) {
    if (buttons.isEmpty) {
      throw ArgumentError.value(
        buttons,
        'buttons',
        'FdcDialogBase requires at least one button.',
      );
    }
  }

  final String title;
  final Widget content;
  final List<FdcDialogButton<T>> buttons;
  final T? dismissResult;
  final bool showCloseButton;

  @override
  State<FdcDialogBase<T>> createState() => _FdcDialogBaseState<T>();
}

class _FdcDialogBaseState<T> extends State<FdcDialogBase<T>> {
  static const double _dialogMaxWidth = 460;
  static const double _dialogMinWidth = 320;
  static const double _dialogRadius = 22;

  late final FocusNode _dialogFocusNode;
  late List<FocusNode> _buttonFocusNodes;
  int _defaultFocusRequestGeneration = 0;

  int get _defaultButtonIndex {
    final explicit = widget.buttons.indexWhere((button) => button.isDefault);
    return explicit >= 0 ? explicit : 0;
  }

  int get _dismissButtonIndex {
    final explicit = widget.buttons.indexWhere((button) => button.isDismiss);
    return explicit >= 0 ? explicit : _defaultButtonIndex;
  }

  @override
  void initState() {
    super.initState();
    _dialogFocusNode = FocusNode(debugLabel: 'FdcDialogBase');
    _buttonFocusNodes = _createButtonFocusNodes();
    _scheduleDefaultButtonFocus();
  }

  @override
  void didUpdateWidget(covariant FdcDialogBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buttons.length != widget.buttons.length) {
      _disposeButtonFocusNodes();
      _buttonFocusNodes = _createButtonFocusNodes();
      _scheduleDefaultButtonFocus();
    }
  }

  @override
  void dispose() {
    _defaultFocusRequestGeneration += 1;
    _disposeButtonFocusNodes();
    _dialogFocusNode.dispose();
    super.dispose();
  }

  List<FocusNode> _createButtonFocusNodes() {
    return List<FocusNode>.generate(
      widget.buttons.length,
      (index) => FocusNode(debugLabel: 'FdcDialogButton[$index]'),
    );
  }

  void _disposeButtonFocusNodes() {
    for (final node in _buttonFocusNodes) {
      node.dispose();
    }
  }

  void _scheduleDefaultButtonFocus() {
    final requestGeneration = ++_defaultFocusRequestGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || requestGeneration != _defaultFocusRequestGeneration) {
        return;
      }
      _requestDefaultButtonFocus();
    });
  }

  void _requestDefaultButtonFocus() {
    if (!mounted || _buttonFocusNodes.isEmpty) {
      return;
    }

    final defaultNode = _buttonFocusNodes[_defaultButtonIndex];
    if (!defaultNode.canRequestFocus || defaultNode.hasFocus) {
      return;
    }

    defaultNode.requestFocus();
  }

  void _dismiss() {
    if (widget.dismissResult != null) {
      Navigator.of(context).pop(widget.dismissResult);
      return;
    }

    final button = widget.buttons[_dismissButtonIndex];
    Navigator.of(context).pop(button.result);
  }

  void _activateDefaultButton() {
    final button = widget.buttons[_defaultButtonIndex];
    Navigator.of(context).pop(button.result);
  }

  void _moveButtonFocus(int delta) {
    if (_buttonFocusNodes.isEmpty) {
      return;
    }

    var currentIndex = _buttonFocusNodes.indexWhere((node) => node.hasFocus);
    if (currentIndex < 0) {
      currentIndex = _defaultButtonIndex;
    } else {
      currentIndex = (currentIndex + delta) % _buttonFocusNodes.length;
      if (currentIndex < 0) {
        currentIndex += _buttonFocusNodes.length;
      }
    }

    _buttonFocusNodes[currentIndex].requestFocus();
  }

  List<Widget> _buildActions() {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return List<Widget>.generate(widget.buttons.length, (index) {
      final button = widget.buttons[index];
      return _FdcDialogActionButton<T>(
        button: button,
        focusNode: _buttonFocusNodes[index],
        autofocus: index == _defaultButtonIndex,
        accentColor: accent,
        focusColor: accent,
        focusedForegroundColor: colorScheme.onPrimary,
        onPressed: () => Navigator.of(context).pop(button.result),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FdcModalDialogScope(
      preferredFocusNode: _buttonFocusNodes[_defaultButtonIndex],
      onDismiss: _dismiss,
      onActivateDefault: _activateDefaultButton,
      onMovePrevious: () => _moveButtonFocus(-1),
      onMoveNext: () => _moveButtonFocus(1),
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          SingleActivator(LogicalKeyboardKey.enter):
              _ActivateDefaultButtonIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter):
              _ActivateDefaultButtonIntent(),
          SingleActivator(LogicalKeyboardKey.arrowLeft):
              _FdcPreviousDialogButtonIntent(),
          SingleActivator(LogicalKeyboardKey.arrowRight):
              _FdcNextDialogButtonIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (intent) {
                _dismiss();
                return null;
              },
            ),
            _FdcPreviousDialogButtonIntent:
                CallbackAction<_FdcPreviousDialogButtonIntent>(
                  onInvoke: (intent) {
                    _moveButtonFocus(-1);
                    return null;
                  },
                ),
            _FdcNextDialogButtonIntent:
                CallbackAction<_FdcNextDialogButtonIntent>(
                  onInvoke: (intent) {
                    _moveButtonFocus(1);
                    return null;
                  },
                ),
            _ActivateDefaultButtonIntent:
                CallbackAction<_ActivateDefaultButtonIntent>(
                  onInvoke: (intent) {
                    _activateDefaultButton();
                    return null;
                  },
                ),
          },
          child: Focus(
            focusNode: _dialogFocusNode,
            autofocus: true,
            onFocusChange: (focused) {
              if (focused) {
                _requestDefaultButtonFocus();
              }
            },
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) {
                return KeyEventResult.ignored;
              }

              if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                _activateDefaultButton();
                return KeyEventResult.handled;
              }

              if (event.logicalKey == LogicalKeyboardKey.escape) {
                _dismiss();
                return KeyEventResult.handled;
              }

              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _moveButtonFocus(-1);
                return KeyEventResult.handled;
              }

              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _moveButtonFocus(1);
                return KeyEventResult.handled;
              }

              return KeyEventResult.ignored;
            },
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: _dialogMinWidth,
                  maxWidth: _dialogMaxWidth,
                ),
                child: Material(
                  color: colorScheme.surface,
                  elevation: 18,
                  shadowColor: Colors.black.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(_dialogRadius),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (widget.showCloseButton)
                              IconButton(
                                tooltip: FdcApp.translationsOf(
                                  context,
                                ).common.close,
                                onPressed: _dismiss,
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.close,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Divider(
                          height: 1,
                          thickness: 0.6,
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 360),
                          child: SingleChildScrollView(
                            child: DefaultTextStyle.merge(
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.35,
                                color: colorScheme.onSurface,
                              ),
                              child: widget.content,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 0, 18, 18),
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 10,
                          runSpacing: 8,
                          children: _buildActions(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FdcDialogActionButton<T> extends StatefulWidget {
  const _FdcDialogActionButton({
    required this.button,
    required this.focusNode,
    required this.autofocus,
    required this.accentColor,
    required this.focusColor,
    required this.focusedForegroundColor,
    required this.onPressed,
  });

  final FdcDialogButton<T> button;
  final FocusNode focusNode;
  final bool autofocus;
  final Color accentColor;
  final Color focusColor;
  final Color focusedForegroundColor;
  final VoidCallback onPressed;

  @override
  State<_FdcDialogActionButton<T>> createState() =>
      _FdcDialogActionButtonState<T>();
}

class _FdcDialogActionButtonState<T> extends State<_FdcDialogActionButton<T>> {
  bool _focused = false;
  bool _hovered = false;
  bool _pressed = false;

  bool get _isFilled => widget.button.style == FdcDialogButtonStyle.filled;

  void _setInteractionState(VoidCallback update) {
    if (!mounted) {
      return;
    }
    setState(update);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedFilledColor = Color.alphaBlend(
      widget.accentColor.withValues(alpha: 0.10),
      colorScheme.surface,
    );

    final backgroundColor = _focused
        ? (_pressed
              ? Color.alphaBlend(
                  Colors.black.withValues(alpha: 0.10),
                  widget.focusColor,
                )
              : widget.focusColor)
        : _isFilled
        ? (_pressed
              ? Color.alphaBlend(
                  Colors.black.withValues(alpha: 0.06),
                  mutedFilledColor,
                )
              : _hovered
              ? Color.alphaBlend(
                  widget.accentColor.withValues(alpha: 0.14),
                  colorScheme.surface,
                )
              : mutedFilledColor)
        : _pressed
        ? Color.alphaBlend(
            widget.focusColor.withValues(alpha: 0.10),
            colorScheme.surface,
          )
        : _hovered
        ? Color.alphaBlend(
            widget.focusColor.withValues(alpha: 0.06),
            colorScheme.surface,
          )
        : colorScheme.surface;

    final borderColor = _focused
        ? widget.focusColor
        : _isFilled
        ? Colors.transparent
        : colorScheme.outlineVariant;

    final foregroundColor = _focused
        ? widget.focusedForegroundColor
        : _isFilled
        ? widget.accentColor
        : colorScheme.onSurfaceVariant;

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (value) => _setInteractionState(() => _focused = value),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          widget.onPressed();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _setInteractionState(() => _hovered = true),
        onExit: (_) => _setInteractionState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setInteractionState(() => _pressed = true),
          onTapCancel: () => _setInteractionState(() => _pressed = false),
          onTapUp: (_) => _setInteractionState(() => _pressed = false),
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minWidth: 86, minHeight: 38),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: widget.focusColor.withValues(alpha: 0.24),
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.button.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: _isFilled ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
