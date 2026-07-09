// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/fdc_grid_theme.dart';
import 'fdc_menu_entry.dart';

class FdcMenuAnchor extends StatefulWidget {
  const FdcMenuAnchor({
    super.key,
    this.entries = const <FdcMenuEntry>[],
    this.entriesBuilder,
    required this.child,
    this.openOnTap = false,
    this.openOnSecondaryTap = true,
    this.consumeSecondaryTap = true,
    this.materialFeedback = false,
    this.openAtAnchor = false,
    this.canOpen,
    this.onOpen,
    this.onClose,
    this.openRequestToken,
  });

  final List<FdcMenuEntry> entries;

  /// Resolves menu entries immediately before the menu opens.
  ///
  /// Use this when menu state depends on current selection, editing, or data.
  final List<FdcMenuEntry> Function()? entriesBuilder;

  final Widget child;
  final bool openOnTap;
  final bool openOnSecondaryTap;
  final bool consumeSecondaryTap;
  final bool materialFeedback;

  /// Opens pointer-triggered menus at the anchor origin instead of the pointer.
  ///
  /// This is useful for editor popups that must align consistently regardless
  /// of the exact cursor/tap position inside the anchor. Programmatic open
  /// requests already use the anchor origin.
  final bool openAtAnchor;

  final bool Function()? canOpen;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;

  /// Opens the menu after build whenever this token changes.
  ///
  /// This is intentionally token-based instead of a boolean so callers can
  /// request another open for the same anchor without rebuilding the anchor
  /// with a transient false state in between.
  final Object? openRequestToken;

  @override
  State<FdcMenuAnchor> createState() => _FdcMenuAnchorState();
}

class _FdcMenuAnchorState extends State<FdcMenuAnchor> {
  final MenuController _controller = MenuController();
  List<FdcMenuEntry> _resolvedEntries = const <FdcMenuEntry>[];
  Object? _lastOpenRequestToken;

  @override
  void initState() {
    super.initState();
    _resolvedEntries = widget.entries;
    _scheduleRequestedOpen();
  }

  @override
  void didUpdateWidget(FdcMenuAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entriesBuilder == null && oldWidget.entries != widget.entries) {
      _resolvedEntries = widget.entries;
    }
    _scheduleRequestedOpen();
  }

  void _scheduleRequestedOpen() {
    final token = widget.openRequestToken;
    if (token == null || token == _lastOpenRequestToken) {
      return;
    }
    _lastOpenRequestToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_open(_controller, Offset.zero));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      style: _FdcMenuLook.panelStyle(context),
      menuChildren: FdcMenuRenderer.buildMenuItems(context, _resolvedEntries),
      onClose: widget.onClose,
      builder: (context, controller, child) {
        final wrappedChild = child ?? const SizedBox.shrink();
        if (widget.materialFeedback) {
          return _buildMaterialAnchor(controller, wrappedChild);
        }
        return _buildGestureAnchor(controller, wrappedChild);
      },
      child: widget.child,
    );
  }

  Widget _buildGestureAnchor(MenuController controller, Widget child) {
    final tapAnchor = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: widget.openOnTap
          ? (details) => _open(controller, _openPosition(details.localPosition))
          : null,
      onSecondaryTap: widget.consumeSecondaryTap ? () {} : null,
      child: child,
    );

    return _withSecondaryPointerAnchor(controller, tapAnchor);
  }

  Widget _buildMaterialAnchor(MenuController controller, Widget child) {
    Offset? tapPosition;

    final materialAnchor = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTap: widget.consumeSecondaryTap ? () {} : null,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTapDown: widget.openOnTap
              ? (details) => tapPosition = _openPosition(details.localPosition)
              : null,
          onTap: widget.openOnTap
              ? () => _open(controller, tapPosition ?? Offset.zero)
              : null,
          containedInkWell: true,
          radius: _FdcMenuLook.anchorSplashRadius,
          borderRadius: BorderRadius.circular(_FdcMenuLook.anchorRadius),
          child: child,
        ),
      ),
    );

    return _withSecondaryPointerAnchor(controller, materialAnchor);
  }

  Widget _withSecondaryPointerAnchor(MenuController controller, Widget child) {
    if (!widget.openOnSecondaryTap) {
      return child;
    }

    // Use the raw pointer stream for context-menu activation. Grid cells can
    // contain nested gesture recognizers and controls, so relying on the tap
    // gesture arena for a secondary click is unnecessarily fragile on Web.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if ((event.buttons & kSecondaryMouseButton) == 0) {
          return;
        }
        unawaited(_open(controller, _openPosition(event.localPosition)));
      },
      child: child,
    );
  }

  Offset _openPosition(Offset pointerPosition) {
    return widget.openAtAnchor ? Offset.zero : pointerPosition;
  }

  Future<void> _open(MenuController controller, Offset position) async {
    final entriesBuilder = widget.entriesBuilder;
    if (entriesBuilder != null) {
      final entries = entriesBuilder();
      if (entries.isEmpty) {
        return;
      }

      // MenuAnchor must rebuild with the resolved menu children before the
      // controller opens. Waiting for endOfFrame is robust on Web where a
      // secondary click can also cause selection updates in the same frame.
      setState(() => _resolvedEntries = entries);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) {
        return;
      }
      _openResolved(_controller, position);
      return;
    }
    _resolvedEntries = widget.entries;
    _openResolved(controller, position);
  }

  void _openResolved(MenuController controller, Offset position) {
    if (_resolvedEntries.isEmpty) {
      return;
    }
    if (controller.isOpen) {
      controller.close();
    }
    if (widget.canOpen?.call() == false) {
      return;
    }
    widget.onOpen?.call();
    controller.open(position: position);
  }
}

class FdcMenuPanel extends StatelessWidget {
  const FdcMenuPanel({super.key, required this.entries});

  final List<FdcMenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    final style = _FdcMenuLook.popupStyleOf(context);
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.backgroundColor,
          border: Border.all(color: style.borderColor!),
          borderRadius: BorderRadius.circular(_FdcMenuLook.panelRadius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: style.shadowColor!,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: FdcMenuRenderer.buildMenuItems(context, entries),
            ),
          ),
        ),
      ),
    );
  }
}

class FdcMenuRenderer {
  const FdcMenuRenderer._();

  static List<Widget> buildMenuItems(
    BuildContext context,
    List<FdcMenuEntry> entries,
  ) {
    return [for (final entry in entries) _buildMenuItem(context, entry)];
  }

  static Widget _buildMenuItem(BuildContext context, FdcMenuEntry entry) {
    if (entry is FdcMenuTitle) {
      return _FdcMenuTitleWidget(text: entry.text);
    }
    if (entry is FdcMenuSeparator) {
      return const _FdcMenuSeparatorWidget();
    }
    if (entry is FdcMenuWidgetEntry) {
      return entry.child;
    }
    if (entry is FdcSubMenu) {
      if (!entry.enabled || entry.children.isEmpty) {
        return _FdcMenuItemFrame(
          child: MenuItemButton(
            style: _FdcMenuLook.itemStyle(context, enabled: false),
            child: _FdcMenuItemContent(
              text: entry.text,
              icon: entry.icon,
              enabled: false,
              showSubmenuArrow: true,
            ),
          ),
        );
      }
      return _FdcMenuItemFrame(
        child: SubmenuButton(
          style: _FdcMenuLook.itemStyle(context, enabled: entry.enabled),
          menuStyle: _FdcMenuLook.panelStyle(context),
          hoverOpenDelay: _FdcMenuLook.submenuHoverOpenDelay,
          menuChildren: buildMenuItems(context, entry.children),
          child: _FdcMenuItemContent(
            text: entry.text,
            icon: entry.icon,
            enabled: entry.enabled,
          ),
        ),
      );
    }
    if (entry is FdcMenuCheckAction) {
      return _FdcMenuItemFrame(
        child: MenuItemButton(
          style: _FdcMenuLook.itemStyle(
            context,
            enabled: entry.enabled,
            selected: entry.checked,
          ),
          closeOnActivate: !entry.keepOpen,
          onPressed: entry.enabled && entry.onPressed != null
              ? () => entry.keepOpen
                    ? entry.onPressed?.call()
                    : _runActionAfterActivation(entry.onPressed)
              : null,
          child: _FdcMenuItemContent(
            text: entry.text,
            icon: entry.icon,
            shortcutText: entry.shortcutText,
            customChild: entry.child,
            checked: entry.checked,
            enabled: entry.enabled,
          ),
        ),
      );
    }
    if (entry is FdcMenuAction) {
      return _FdcMenuItemFrame(
        child: MenuItemButton(
          style: _FdcMenuLook.itemStyle(context, enabled: entry.enabled),
          onPressed: entry.enabled && entry.onPressed != null
              ? () => _runActionAfterActivation(entry.onPressed)
              : null,
          child: _FdcMenuItemContent(
            text: entry.text,
            icon: entry.icon,
            shortcutText: entry.shortcutText,
            enabled: entry.enabled,
          ),
        ),
      );
    }
    throw UnsupportedError('Unsupported FDC menu entry: ${entry.runtimeType}');
  }

  static void _runActionAfterActivation(VoidCallback? action) {
    if (action == null) {
      return;
    }

    // Let MenuItemButton finish its activation/close bookkeeping before a
    // dataset operation rebuilds or removes the menu anchor. A microtask runs
    // exactly once before the next frame and avoids the post-frame feedback
    // cycle that can occur with append/edit operations.
    scheduleMicrotask(action);
  }
}

class _FdcMenuItemFrame extends StatelessWidget {
  const _FdcMenuItemFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _FdcMenuLook.itemGap),
      child: child,
    );
  }
}

class _FdcMenuItemContent extends StatelessWidget {
  const _FdcMenuItemContent({
    required this.text,
    this.icon,
    this.shortcutText,
    this.customChild,
    this.checked = false,
    this.enabled = true,
    this.showSubmenuArrow = false,
  });

  final String text;
  final IconData? icon;
  final String? shortcutText;
  final Widget? customChild;
  final bool checked;
  final bool enabled;
  final bool showSubmenuArrow;

  @override
  Widget build(BuildContext context) {
    final colors = _FdcMenuLook.colors(context, enabled: enabled);
    final fontWeight = checked ? FontWeight.w600 : FontWeight.w400;
    final textStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colors.text,
          fontSize: 13,
          fontWeight: fontWeight,
          height: 1.20,
        ) ??
        TextStyle(
          color: colors.text,
          fontSize: 13,
          fontWeight: fontWeight,
          height: 1.20,
        );
    final shortcutStyle = textStyle.copyWith(color: colors.shortcut);
    final leadingIcon = checked ? Icons.check : icon;

    return SizedBox(
      width: _FdcMenuLook.contentWidth,
      child: DefaultTextStyle.merge(
        style: textStyle,
        child: Row(
          children: [
            SizedBox(
              width: _FdcMenuLook.iconSlotWidth,
              child: leadingIcon == null
                  ? null
                  : Icon(
                      leadingIcon,
                      size: _FdcMenuLook.iconSize,
                      color: checked ? colors.text : colors.icon,
                    ),
            ),
            const SizedBox(width: _FdcMenuLook.iconTextGap),
            Expanded(
              child:
                  customChild ??
                  Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (shortcutText != null) ...[
              const SizedBox(width: _FdcMenuLook.trailingGap),
              Text(shortcutText!, style: shortcutStyle),
            ],
            if (showSubmenuArrow) ...[
              const SizedBox(width: _FdcMenuLook.trailingGap),
              Icon(
                Icons.chevron_right,
                size: _FdcMenuLook.submenuIconSize,
                color: colors.shortcut,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FdcMenuTitleWidget extends StatelessWidget {
  const _FdcMenuTitleWidget({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = _FdcMenuLook.colors(context, enabled: true);
    final textStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colors.shortcut,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.20,
        ) ??
        TextStyle(
          color: colors.shortcut,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.20,
        );

    return Semantics(
      container: true,
      header: true,
      child: SizedBox(
        width: _FdcMenuLook.contentWidth,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _FdcMenuLook.titleHorizontalPadding,
            _FdcMenuLook.titleTopPadding,
            _FdcMenuLook.titleHorizontalPadding,
            _FdcMenuLook.titleBottomPadding,
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ),
    );
  }
}

class _FdcMenuSeparatorWidget extends StatelessWidget {
  const _FdcMenuSeparatorWidget();

  @override
  Widget build(BuildContext context) {
    final style = _FdcMenuLook.popupStyleOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Divider(height: 1, thickness: 1, color: style.separatorColor!),
    );
  }
}

class _FdcMenuLook {
  const _FdcMenuLook._();

  static const double contentWidth = 220;
  static const double panelRadius = 7;
  static const double itemRadius = 5;
  static const double anchorRadius = 7;
  static const double anchorSplashRadius = 9;
  static const double iconSlotWidth = 22;
  static const double iconSize = 18;
  static const double submenuIconSize = 18;
  static const Duration submenuHoverOpenDelay = Duration(milliseconds: 180);
  static const double iconTextGap = 9;
  static const double trailingGap = 18;
  static const double itemGap = 1;
  static const double titleHorizontalPadding = 12;
  static const double titleTopPadding = 8;
  static const double titleBottomPadding = 4;

  static MenuStyle panelStyle(BuildContext context) {
    final style = popupStyleOf(context);

    return MenuStyle(
      backgroundColor: WidgetStatePropertyAll<Color>(style.backgroundColor!),
      surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      shadowColor: WidgetStatePropertyAll<Color>(style.shadowColor!),
      elevation: const WidgetStatePropertyAll<double>(10),
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 0)),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(panelRadius),
          side: BorderSide(color: style.borderColor!),
        ),
      ),
    );
  }

  static ButtonStyle itemStyle(
    BuildContext context, {
    required bool enabled,
    bool selected = false,
  }) {
    final colors = colorsOf(context);
    return ButtonStyle(
      alignment: Alignment.centerLeft,
      minimumSize: const WidgetStatePropertyAll<Size>(Size(0, 34)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
        EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(itemRadius)),
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (!enabled || states.contains(WidgetState.disabled)) {
          return colors.disabledText;
        }
        return colors.text;
      }),
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (!enabled || states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        if (states.contains(WidgetState.pressed)) {
          return colors.pressed;
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return colors.hover;
        }
        if (selected) {
          return colors.selected;
        }
        return Colors.transparent;
      }),
    );
  }

  static _FdcMenuContentColors colors(
    BuildContext context, {
    required bool enabled,
  }) {
    final colors = colorsOf(context);
    if (!enabled) {
      return _FdcMenuContentColors(
        text: colors.disabledText,
        shortcut: colors.disabledShortcut,
        icon: colors.disabledIcon,
      );
    }
    return _FdcMenuContentColors(
      text: colors.text,
      shortcut: colors.shortcut,
      icon: colors.icon,
    );
  }

  static FdcGridPopupMenuStyle popupStyleOf(BuildContext context) {
    return FdcGridTheme.resolveData(context, null).popupMenu.resolve();
  }

  static _FdcMenuColors colorsOf(BuildContext context) {
    final style = popupStyleOf(context);

    return _FdcMenuColors(
      text: style.textColor!,
      shortcut: style.secondaryTextColor!,
      icon: style.iconColor!,
      disabledText: style.disabledTextColor!,
      disabledShortcut: style.disabledTextColor!,
      disabledIcon: style.disabledIconColor!,
      hover: style.hoverColor!,
      selected: style.selectedItemColor!,
      pressed: style.pressedColor!,
    );
  }
}

class _FdcMenuColors {
  const _FdcMenuColors({
    required this.text,
    required this.shortcut,
    required this.icon,
    required this.disabledText,
    required this.disabledShortcut,
    required this.disabledIcon,
    required this.hover,
    required this.selected,
    required this.pressed,
  });

  final Color text;
  final Color shortcut;
  final Color icon;
  final Color disabledText;
  final Color disabledShortcut;
  final Color disabledIcon;
  final Color hover;
  final Color selected;
  final Color pressed;
}

class _FdcMenuContentColors {
  const _FdcMenuContentColors({
    required this.text,
    required this.shortcut,
    required this.icon,
  });

  final Color text;
  final Color shortcut;
  final Color icon;
}
