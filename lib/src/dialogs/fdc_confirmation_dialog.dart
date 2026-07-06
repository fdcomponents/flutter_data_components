// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';

import '../app/fdc_app.dart';
import 'fdc_dialog_base.dart';

/// Selects which confirmation action receives initial keyboard focus.
enum FdcConfirmationDefaultButton {
  /// Focus the affirmative action by default.
  yes,

  /// Focus the negative action by default.
  no,
}

/// Modal yes/no confirmation dialog using FDC translations and button styling.
class FdcConfirmationDialog extends StatelessWidget {
  /// Creates a [FdcConfirmationDialog].
  const FdcConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.yesText,
    this.noText,
    this.defaultButton = FdcConfirmationDefaultButton.no,
  });

  /// Dialog title shown above the confirmation message.
  final String title;

  /// User-facing message text.
  final String message;

  /// Optional label overriding the localized affirmative action text.
  final String? yesText;

  /// Optional label overriding the localized negative action text.
  final String? noText;

  /// The default button.
  final FdcConfirmationDefaultButton defaultButton;

  @override
  Widget build(BuildContext context) {
    final translations = FdcApp.translationsOf(context);
    final yesIsDefault = defaultButton == FdcConfirmationDefaultButton.yes;
    final noIsDefault = defaultButton == FdcConfirmationDefaultButton.no;

    return FdcDialogBase<bool>(
      title: title,
      content: Text(message),
      dismissResult: false,
      buttons: [
        FdcDialogButton<bool>(
          label: noText ?? translations.common.no,
          result: false,
          isDefault: noIsDefault,
          isDismiss: true,
        ),
        FdcDialogButton<bool>(
          label: yesText ?? translations.common.yes,
          result: true,
          isDefault: yesIsDefault,
          style: FdcDialogButtonStyle.filled,
        ),
      ],
    );
  }
}

/// Shows a confirmation dialog and returns whether the user confirmed.
Future<bool> showFdcConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? yesText,
  String? noText,
  FdcConfirmationDefaultButton defaultButton = FdcConfirmationDefaultButton.no,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    requestFocus: true,
    builder: (context) {
      return FdcConfirmationDialog(
        title: title,
        message: message,
        yesText: yesText,
        noText: noText,
        defaultButton: defaultButton,
      );
    },
  );

  return result == true;
}
