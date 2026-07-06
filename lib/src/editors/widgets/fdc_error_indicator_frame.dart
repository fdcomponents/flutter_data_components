// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../../common/widgets/validation/fdc_error_indicator.dart';

/// Wraps an editor child with the configured validation error presentation.
class FdcErrorIndicatorFrame extends StatelessWidget {
  /// Creates an error indicator frame.
  const FdcErrorIndicatorFrame({
    super.key,
    required this.child,
    required this.errorIndicator,
    this.errorMessage,
    this.inlineHandledByChild = false,
  });

  /// Editor widget wrapped by this frame.
  final Widget child;

  /// Error indicator presentation options.
  final FdcErrorIndicatorOptions errorIndicator;

  /// Current validation error message, when any.
  final String? errorMessage;

  /// Set to true when the child is a native form field that already renders
  /// inline error text through its own decoration/validator pipeline.
  final bool inlineHandledByChild;

  @override
  Widget build(BuildContext context) {
    final message = errorMessage;

    switch (errorIndicator.mode) {
      case FdcErrorIndicatorMode.none:
        return child;
      case FdcErrorIndicatorMode.inline:
        if (inlineHandledByChild) {
          return child;
        }
        return _FdcInlineValidationMessage(message: message, child: child);
      case FdcErrorIndicatorMode.marker:
        return _buildIndicator(message);
    }
  }

  Widget _buildIndicator(String? message) {
    final style = FdcErrorIndicatorMarkerStyle.defaults.merge(
      errorIndicator.markerStyle,
    );
    final size = style.size ?? FdcErrorIndicatorMarkerStyle.defaults.size!;
    final color = style.color ?? FdcErrorIndicatorMarkerStyle.defaults.color!;

    final hasMessage = message != null && message.isNotEmpty;

    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        if (hasMessage)
          Positioned(
            left: 0,
            top: 0,
            width: size,
            height: size,
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              descendantsAreFocusable: false,
              descendantsAreTraversable: false,
              child: FdcErrorIndicatorMarker(
                message: message,
                color: color,
                size: size,
              ),
            ),
          ),
      ],
    );
  }
}

class _FdcInlineValidationMessage extends StatelessWidget {
  const _FdcInlineValidationMessage({
    required this.child,
    required this.message,
  });

  /// Editor widget wrapped by this frame.
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorStyle =
        theme.inputDecorationTheme.errorStyle ??
        theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error) ??
        TextStyle(color: theme.colorScheme.error, fontSize: 12);

    final text = message;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        if (text != null && text.isNotEmpty)
          Focus(
            canRequestFocus: false,
            skipTraversal: true,
            descendantsAreFocusable: false,
            descendantsAreTraversable: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(text, style: errorStyle),
            ),
          ),
      ],
    );
  }
}
