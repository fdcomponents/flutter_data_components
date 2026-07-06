// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../common/theme/fdc_grid_theme.dart';
import '../../data/fdc_data.dart';
import '../columns/fdc_grid_columns.dart';

const double _fdcGridBadgeBorderRadius = 4;
const double _fdcGridBadgeIconGap = 4;

class FdcGridBadge extends StatelessWidget {
  const FdcGridBadge({
    super.key,
    required this.column,
    required this.value,
    required this.cellTextStyle,
    required this.alignment,
  });

  final FdcGridColumn<dynamic> column;
  final Object? value;
  final TextStyle? cellTextStyle;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cellValue = value;
    if (cellValue == null) {
      return const SizedBox.shrink();
    }
    final FdcBadgeValue? badge = cellValue is FdcBadgeValue ? cellValue : null;
    final text =
        badge?.text ??
        column.badgeTextBuilder?.call(cellValue) ??
        column.badgeText ??
        _optionLabel(column, cellValue) ??
        cellValue.toString();
    final color =
        badge?.color ??
        column.badgeColorBuilder?.call(cellValue) ??
        column.badgeColor ??
        theme.colorScheme.secondaryContainer;
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final resolvedTextStyle = _badgeTextStyle(theme, badge);
    final textStyle = resolvedTextStyle.copyWith(
      color: resolvedTextStyle.color ?? foreground,
      fontWeight: resolvedTextStyle.fontWeight ?? FontWeight.w600,
    );
    final icon = badge?.icon;
    final iconSize = textStyle.fontSize;
    final iconColor = textStyle.color;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(minHeight: 22),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: _darkerBadgeBorderColor(color)),
          borderRadius: BorderRadius.circular(_fdcGridBadgeBorderRadius),
        ),
        child: icon == null
            ? Text(text, overflow: TextOverflow.ellipsis, style: textStyle)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: iconSize, color: iconColor),
                  const SizedBox(width: _fdcGridBadgeIconGap),
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  TextStyle _badgeTextStyle(ThemeData theme, FdcBadgeValue? badge) {
    final defaultStyle =
        cellTextStyle?.merge(theme.textTheme.labelSmall) ??
        theme.textTheme.labelSmall ??
        cellTextStyle ??
        const TextStyle(fontSize: 11);
    return defaultStyle.merge(column.badgeTextStyle).merge(badge?.textStyle);
  }
}

Color _darkerBadgeBorderColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness - 0.12).clamp(0.0, 1.0).toDouble();
  final saturation = (hsl.saturation + 0.04).clamp(0.0, 1.0).toDouble();
  return hsl.withLightness(lightness).withSaturation(saturation).toColor();
}

class FdcGridProgress extends StatelessWidget {
  const FdcGridProgress({
    super.key,
    required this.column,
    required this.value,
    required this.cellTextStyle,
    this.style,
  });

  final FdcGridColumn<dynamic> column;
  final Object? value;
  final TextStyle? cellTextStyle;
  final FdcGridProgressStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cellValue = value;
    final FdcProgressValue? progressValue = cellValue is FdcProgressValue
        ? cellValue
        : null;
    final rawValue = _progressNumericValue(cellValue);
    final progressStyle = style ?? _resolveProgressStyle(context, theme);
    final min = column.progressMin;
    final max = column.progressMax;
    final range = max - min;
    final normalized = range == 0
        ? 0.0
        : ((rawValue.toDouble() - min) / range).clamp(0.0, 1.0);
    final color = progressValue?.color ?? progressStyle.color;
    final backgroundColor =
        progressValue?.backgroundColor ?? progressStyle.backgroundColor;
    final text =
        progressValue?.text ??
        column.progressTextBuilder?.call(rawValue) ??
        '${(normalized * 100).round()}%';

    final height = progressStyle.height ?? FdcGridProgressStyle.defaultHeight;
    final borderRadius =
        progressStyle.borderRadius ??
        const BorderRadius.all(
          Radius.circular(FdcGridProgressStyle.defaultBorderRadius),
        );

    return Semantics(
      container: true,
      value: text,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: borderRadius,
          child: SizedBox(
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: progressStyle.border,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: normalized,
                      child: SizedBox.expand(
                        child: ColoredBox(color: color ?? Colors.transparent),
                      ),
                    ),
                  ),
                  if (progressStyle.showText ?? true)
                    _buildProgressText(progressStyle, text),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressText(FdcGridProgressStyle progressStyle, String text) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: progressStyle.textStyle ?? const TextStyle(fontSize: 11),
    );
  }

  FdcGridProgressStyle _resolveProgressStyle(
    BuildContext context,
    ThemeData materialTheme,
  ) {
    final colorScheme = materialTheme.colorScheme;
    final labelStyle =
        materialTheme.textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    final defaults = FdcGridProgressStyle.defaults.merge(
      FdcGridProgressStyle(
        color: colorScheme.primary,
        backgroundColor: colorScheme.surfaceContainerHighest,
        textStyle: labelStyle.copyWith(
          color: labelStyle.color ?? colorScheme.onSurface,
          fontWeight: labelStyle.fontWeight ?? FontWeight.w700,
        ),
      ),
    );
    final theme = FdcGridTheme.resolveData(context, null);
    return defaults.merge(theme.progress).merge(column.progressStyle);
  }
}

num _progressNumericValue(Object? value) {
  if (value is FdcProgressValue) {
    return value.value;
  }
  if (value is FdcDecimal) {
    return value.toNum();
  }
  if (value is num) {
    return value;
  }
  return 0;
}

String? _optionLabel(FdcGridColumn<dynamic> column, Object? value) {
  for (final option in column.options) {
    if (option.value == value) {
      return option.label;
    }
  }
  return null;
}
