// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Controls whether exported values remain typed/raw or are converted to text.
enum FdcExportValueMode {
  /// Preserve simple Dart values where the format supports them.
  ///
  /// Format writers still normalize non-JSON-native value objects such as
  /// decimals, GUIDs, time values and dates to stable textual representations.
  raw,

  /// Convert values to display-oriented strings before writing them.
  display,
}
