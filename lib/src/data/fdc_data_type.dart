// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Supported logical data types used by data-aware components.
enum FdcDataType {
  /// Text values.
  string,

  /// Whole-number values.
  integer,

  /// Exact fixed-point decimal values.
  decimal,

  /// Boolean values.
  boolean,

  /// Date-only values.
  date,

  /// Combined date-and-time values.
  dateTime,

  /// Time-of-day values.
  time,

  /// 128-bit GUID values.
  guid,

  /// Opaque application object values.
  object,
}
