// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/widgets/progress/fdc_progress_widgets.dart';
import 'fdc_grid_items.dart';

export 'fdc_grid_button.dart' show FdcGridButton;
export 'fdc_grid_items.dart' hide FdcGridItemTheme;

/// Built-in dataset status text containing record, state, filter, and sort info.
class FdcGridStatusText extends FdcGridItem {
  /// Creates a [FdcGridStatusText].
  const FdcGridStatusText({
    super.id,
    super.visible,
    super.placement = FdcGridItemPlacement.start,
  });
}

/// Dataset work progress indicator for the grid status bar.
class FdcGridProgressBar extends FdcGridItem {
  /// Creates a [FdcGridProgressBar].
  const FdcGridProgressBar({
    super.id,
    super.visible,
    super.placement = FdcGridItemPlacement.end,
    this.width,
    this.style = const FdcProgressBarStyle(),
  });

  /// Fallback width used by the status-bar progress indicator when [width] is
  /// not provided.
  static const double defaultWidth = 96.0;

  /// Optional fixed width of the progress indicator.
  final double? width;

  /// Visual style applied to the progress indicator.
  final FdcProgressBarStyle style;
}
