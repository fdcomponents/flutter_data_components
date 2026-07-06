// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

/// Private grid runtime constants shared by the grid state, runtime helpers,
/// and leaf widgets.
///
/// Keep these values outside the concrete `State` class so public barrels do
/// not need to export the grid implementation state just to expose layout and
/// interaction constants internally.
const double fdcGridFrameInset = 2;

const double fdcGridColumnResizeHandleWidth = 8;

const double fdcGridMinimumResizableColumnWidth = 32;

const Duration fdcGridCellDoubleTapTimeout = Duration(milliseconds: 300);

const Duration fdcGridColumnReorderAnimationDuration = Duration(
  milliseconds: 600,
);

const Duration fdcGridColumnReorderRepeatSwapCooldown = Duration(
  milliseconds: 500,
);
