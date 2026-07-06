// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../app/fdc_app.dart';
import 'fdc_dialog_base.dart';

/// Modal informational dialog with a single dismiss action.
class FdcMessageDialog extends StatelessWidget {
  /// Creates a [FdcMessageDialog].
  const FdcMessageDialog({
    super.key,
    required this.title,
    required this.message,
    this.okText,
  });

  /// Dialog title shown above the message.
  final String title;

  /// User-facing message text.
  final String message;

  /// Optional label overriding the localized dismiss action text.
  final String? okText;

  @override
  Widget build(BuildContext context) {
    return FdcDialogBase<void>(
      title: title,
      content: Text(message),
      buttons: [
        FdcDialogButton<void>(
          label: okText ?? FdcApp.translationsOf(context).common.ok,
          isDefault: true,
          isDismiss: true,
          style: FdcDialogButtonStyle.filled,
        ),
      ],
    );
  }
}

/// Shows an informational message dialog.
Future<void> showFdcMessageDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? okText,
}) {
  FocusManager.instance.primaryFocus?.unfocus();

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    requestFocus: true,
    builder: (context) {
      return FdcMessageDialog(title: title, message: message, okText: okText);
    },
  );
}
