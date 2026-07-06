// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../app/fdc_app.dart';
import '../../../common/theme/fdc_grid_styles.dart';
import '../fdc_grid_header_metrics.dart';

class FdcGridHeaderFilterShell extends StatelessWidget {
  const FdcGridHeaderFilterShell({
    super.key,
    required this.label,
    required this.child,
    this.focusNode,
    this.fillColor,
    required this.style,
    this.showClearButton = false,
    this.onClear,
    this.overflowTooltipText,
    this.overflowTooltipTextStyle,
    this.overflowTooltipReservedWidth = 0,
  });

  final String label;
  final Widget child;
  final FocusNode? focusNode;
  final Color? fillColor;
  final FdcGridHeaderFilterStyle style;
  final bool showClearButton;
  final VoidCallback? onClear;
  final String? overflowTooltipText;
  final TextStyle? overflowTooltipTextStyle;
  final double overflowTooltipReservedWidth;

  @override
  Widget build(BuildContext context) {
    final node = focusNode;
    if (node == null) {
      return _buildShell(context, focused: false);
    }
    return AnimatedBuilder(
      animation: node,
      builder: (context, _) => _buildShell(context, focused: node.hasFocus),
    );
  }

  Widget _buildShell(BuildContext context, {required bool focused}) {
    final backgroundColor =
        style.backgroundColor ?? fillColor ?? Colors.transparent;
    final borderColor = focused
        ? style.focusedBorderColor ??
              style.unfocusedBorderColor ??
              FdcGridStyle.defaultGridLineColor
        : style.unfocusedBorderColor ?? FdcGridStyle.defaultGridLineColor;
    final borderWidth = focused
        ? style.focusedBorderWidth ??
              FdcGridHeaderFilterStyle.defaults.focusedBorderWidth ??
              1
        : style.unfocusedBorderWidth ??
              FdcGridHeaderFilterStyle.defaults.unfocusedBorderWidth ??
              1;
    final labelColor = focused
        ? style.focusedLabelColor ?? borderColor
        : style.unfocusedLabelColor ?? borderColor;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerSignal: _handlePointerScrollSignal,
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final labelMaxWidth = math.max(
              0.0,
              constraints.maxWidth -
                  (FdcGridHeaderMetrics.filterFieldLabelLeft * 2),
            );

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  top: FdcGridHeaderMetrics.filterFieldLabelTopInset,
                  child: _buildInputFrame(
                    backgroundColor: backgroundColor,
                    borderColor: borderColor,
                    borderWidth: borderWidth,
                    focused: focused,
                  ),
                ),
                if (label.isNotEmpty)
                  Positioned(
                    left: FdcGridHeaderMetrics.filterFieldLabelLeft,
                    top: _labelTop,
                    child: _buildLabel(
                      maxWidth: labelMaxWidth,
                      backgroundColor: backgroundColor,
                      color: labelColor,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handlePointerScrollSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }

    GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
  }

  Widget _buildInputFrame({
    required Color backgroundColor,
    required Color borderColor,
    required double borderWidth,
    required bool focused,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showInlineClear =
            showClearButton &&
            onClear != null &&
            constraints.maxWidth >=
                FdcGridHeaderMetrics.filterInlineClearMinimumWidth;
        final frame = DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(
              FdcGridHeaderMetrics.filterFieldBorderRadius,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: Align(child: child)),
              if (showInlineClear)
                Positioned(
                  top: 0,
                  right: FdcGridHeaderMetrics.filterFieldHorizontalPadding,
                  bottom: 0,
                  child: FdcGridHeaderFilterClearButton(
                    color: style.clearIconColor,
                    onPressed: onClear!,
                  ),
                ),
            ],
          ),
        );

        if (focused) {
          return frame;
        }

        final tooltipText = overflowTooltipText?.trim();
        final tooltipStyle = overflowTooltipTextStyle;
        if (tooltipText == null ||
            tooltipText.isEmpty ||
            tooltipStyle == null) {
          return frame;
        }

        // Match the padded text lane used by header-filter display controls
        // instead of measuring the full input frame. Menu/display filters may
        // also reserve trailing space for picker/dropdown affordances.
        var availableWidth = math.max(
          0.0,
          constraints.maxWidth -
              (FdcGridHeaderMetrics.filterFieldHorizontalPadding * 2),
        );
        if (showInlineClear) {
          availableWidth = math.max(
            0.0,
            availableWidth -
                FdcGridHeaderMetrics.filterClearButtonWidth -
                FdcGridHeaderMetrics.filterClearButtonGap,
          );
        }
        if (overflowTooltipReservedWidth > 0) {
          availableWidth = math.max(
            0.0,
            availableWidth - overflowTooltipReservedWidth,
          );
        }
        if (!_textExceedsWidth(
          context,
          text: tooltipText,
          style: tooltipStyle,
          maxWidth: availableWidth,
        )) {
          return frame;
        }

        return Tooltip(
          message: tooltipText,
          waitDuration: const Duration(milliseconds: 450),
          child: frame,
        );
      },
    );
  }

  bool _textExceedsWidth(
    BuildContext context, {
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    if (!maxWidth.isFinite || maxWidth <= 0) {
      return true;
    }

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    return textPainter.width > maxWidth;
  }

  Widget _buildLabel({
    required double maxWidth,
    required Color backgroundColor,
    required Color color,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(color: backgroundColor),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FdcGridHeaderMetrics.filterFieldLabelHorizontalPadding,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: FdcGridHeaderMetrics.filterFieldLabelFontSize,
              height: 1,
              fontWeight: FontWeight.w400,
            ).merge(style.labelTextStyle).copyWith(color: color),
          ),
        ),
      ),
    );
  }

  double get _labelTop =>
      FdcGridHeaderMetrics.filterFieldLabelTopInset -
      (FdcGridHeaderMetrics.filterFieldLabelFontSize / 2);
}

class FdcGridHeaderFilterClearButton extends StatelessWidget {
  const FdcGridHeaderFilterClearButton({
    super.key,
    required this.onPressed,
    this.color,
  });

  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Tooltip(
      message: FdcApp.translationsOf(context).grid.clearFilter,
      child: SizedBox(
        width: FdcGridHeaderMetrics.filterClearButtonWidth,
        height: double.infinity,
        child: InkResponse(
          radius: FdcGridHeaderMetrics.filterClearButtonWidth / 2,
          onTap: onPressed,
          child: Center(
            child: Transform.translate(
              offset: const Offset(
                0,
                FdcGridHeaderMetrics.filterClearButtonVerticalOffset,
              ),
              child: Icon(
                Icons.close,
                size: FdcGridHeaderMetrics.filterClearIconSize,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
