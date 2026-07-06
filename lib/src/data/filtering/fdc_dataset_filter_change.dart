// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';

/// Internal notification payload emitted when the dataset active filter changes.
///
/// This object intentionally keeps the grid-specific header clearing decision
/// out of the public filter controller API and gives us a clean shape to evolve
/// into a future public `onFilterChanged` callback.
@internal
class FdcDataSetFilterChange {
  const FdcDataSetFilterChange({required this.clearHeaderFilters});

  final bool clearHeaderFilters;
}

@internal
typedef FdcDataSetFilterChanged = void Function(FdcDataSetFilterChange change);
