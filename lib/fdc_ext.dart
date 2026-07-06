// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Stable extension seam for FD Components add-on packages.
///
/// This library is intended for first-party and compatible extension packages
/// that integrate with selected grid and dataset runtime hooks. Application
/// code should normally import `fdc.dart` instead.
///
/// The exposed contracts cover controller features, layout persistence, detail
/// rows, range selection, menu entries, prepared search, and other host-facing
/// integration points deliberately kept separate from the main Community API.
library;

export 'src/common/menu/fdc_menu_entry.dart' show FdcMenuAction, FdcMenuEntry;
export 'src/data/fdc_dataset_search.dart'
    show FdcPreparedDataSetSearch, prepareDataSetSearch;
export 'src/data/fdc_dataset_state.dart' show FdcDataSetState;
export 'src/grid/controllers/fdc_grid_controller.dart'
    show FdcGridControllerExtensionApi;
export 'src/grid/models/fdc_grid_cell_ref.dart' show FdcGridCellRef;
export 'src/grid/models/fdc_grid_controller_feature.dart'
    show FdcGridControllerFeature;
export 'src/grid/models/fdc_grid_detail_row_feature.dart'
    show FdcGridDetailRowContext, FdcGridDetailRowFeature;
export 'src/grid/models/fdc_grid_layout_persistence_feature.dart'
    show FdcGridLayoutPersistenceFeature;
export 'src/grid/models/fdc_grid_layout_snapshot.dart'
    show FdcGridColumnLayoutSnapshot, FdcGridLayoutSnapshot;
export 'src/grid/models/fdc_grid_range_selection_feature.dart'
    show
        FdcGridRangeSelectionBounds,
        FdcGridRangeSelectionCellEditablePredicate,
        FdcGridRangeSelectionCellTextParser,
        FdcGridRangeSelectionCellTextReader,
        FdcGridRangeSelectionContextMenuBuilder,
        FdcGridRangeSelectionContextMenuContext,
        FdcGridRangeSelectionFeature,
        FdcGridRangeSelectionHost,
        FdcGridRangeSelectionOverlayBand,
        FdcGridRangeSelectionOverlayBuilder,
        FdcGridRangeSelectionOverlayColumnGeometry,
        FdcGridRangeSelectionOverlayContext,
        FdcGridRangeSelectionPastePlan,
        FdcGridRangeSelectionPasteUpdate,
        FdcGridRangeSelectionRowTopResolver,
        FdcGridRangeSelectionSession;
export 'src/grid/runtime/fdc_grid_runtime.dart' show FdcGridHost;
export 'src/internal/fdc_dataset_extensions.dart' show FdcDataSetExtensions;
