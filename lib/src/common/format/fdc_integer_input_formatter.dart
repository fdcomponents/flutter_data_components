// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/services.dart';

class FdcIntegerInputFormatter extends TextInputFormatter {
  FdcIntegerInputFormatter({this.negative = true});

  final bool negative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!negative && newValue.text.contains('-')) {
      return oldValue;
    }

    final buffer = StringBuffer();
    int? selectionOffset;
    final rawSelectionOffset = newValue.selection.extentOffset;

    for (var i = 0; i < newValue.text.length; i++) {
      if (i == rawSelectionOffset) {
        selectionOffset = buffer.length;
      }

      final char = newValue.text[i];
      if (_isDigit(char)) {
        buffer.write(char);
        continue;
      }

      if (negative &&
          char == '-' &&
          buffer.isEmpty &&
          !newValue.text.startsWith('--')) {
        buffer.write(char);
      }
    }

    if (rawSelectionOffset >= newValue.text.length) {
      selectionOffset = buffer.length;
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: (selectionOffset ?? text.length).clamp(0, text.length),
      ),
    );
  }

  bool _isDigit(String char) {
    return char.compareTo('0') >= 0 && char.compareTo('9') <= 0;
  }
}
