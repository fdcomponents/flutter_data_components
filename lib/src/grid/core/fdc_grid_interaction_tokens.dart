// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Shared interaction group tokens used by grid-owned editor surfaces.
///
/// Keeping these tokens outside `_FdcGridState` allows leaf editor widgets to
/// live in normal Dart libraries instead of depending on the grid part graph.
final Object fdcGridTapRegionGroup = Object();
