// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Removes Unicode control and format characters from clipboard text.
///
/// [preserveTabAndLineBreaks] is intended for tabular clipboard payloads where
/// tab and line-break characters are structural delimiters rather than cell
/// content.
String fdcPrintableClipboardText(
  String value, {
  bool preserveTabAndLineBreaks = false,
}) {
  if (value.isEmpty) {
    return value;
  }

  final result = StringBuffer();
  for (final rune in value.runes) {
    if (_isNonPrintableRune(
      rune,
      preserveTabAndLineBreaks: preserveTabAndLineBreaks,
    )) {
      continue;
    }
    result.writeCharCode(rune);
  }
  return result.toString();
}

bool _isNonPrintableRune(int rune, {required bool preserveTabAndLineBreaks}) {
  if (preserveTabAndLineBreaks &&
      (rune == 0x09 || rune == 0x0A || rune == 0x0D)) {
    return false;
  }

  return rune <= 0x1F ||
      (rune >= 0x7F && rune <= 0x9F) ||
      rune == 0x061C ||
      rune == 0x180E ||
      (rune >= 0x200B && rune <= 0x200F) ||
      (rune >= 0x202A && rune <= 0x202E) ||
      (rune >= 0x2060 && rune <= 0x206F) ||
      rune == 0xFEFF;
}
