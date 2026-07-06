// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Built-in aggregate operations shared by data-aware FDC components.
///
/// Numeric values can generally use [sum], [min], [max], and [avg].
/// Date/date-time values generally support [min] and [max]. Individual
/// components decide how to render unsupported aggregate/type combinations.
enum FdcAggregate {
  /// Sum of all non-null values.
  sum,

  /// Minimum non-null value.
  min,

  /// Maximum non-null value.
  max,

  /// Arithmetic mean of non-null numeric values.
  avg,
}
