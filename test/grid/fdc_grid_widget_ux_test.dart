import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/data/fdc_dataset.dart'
    show FdcDataSetInternal;
import 'package:flutter_data_components/src/grid/core/fdc_grid_interaction_tokens.dart';
import 'package:flutter_data_components/src/grid/core/fdc_grid_runtime_constants.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_cell_frame.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_header_cell.dart'
    show FdcGridHeaderLabelFilterSeparator;
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_row_indicator_header.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_status_bar.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_viewport.dart'
    show FdcGridBodyRow;
import 'package:flutter_data_components/src/grid/widgets/header_filters/fdc_grid_header_filter_cell.dart';
import 'package:flutter_data_components/src/grid/widgets/header_filters/fdc_grid_header_filter_shell.dart';
import 'package:flutter_test/flutter_test.dart';

part 'ux/fdc_grid_ux_test_support.dart';
part 'ux/fdc_grid_appearance_focus_tests.dart';
part 'ux/fdc_grid_headers_columns_tests.dart';
part 'ux/fdc_grid_editing_actions_tests.dart';
part 'ux/fdc_grid_keyboard_navigation_tests.dart';
part 'ux/fdc_grid_toolbar_search_tests.dart';
part 'ux/fdc_grid_editing_validation_tests.dart';
part 'ux/fdc_grid_filtering_menus_tests.dart';
part 'ux/fdc_grid_selection_scrolling_tests.dart';
part 'ux/fdc_grid_column_menu_sorting_tests.dart';
part 'ux/fdc_grid_status_summary_tests.dart';
part 'ux/fdc_grid_custom_columns_tests.dart';

void main() {
  group('FdcGrid widget UX', () {
    _registerAppearanceAndFocusTests();
    _registerHeadersAndColumnsTests();
    _registerEditingActionTests();
    _registerKeyboardNavigationTests();
    _registerToolbarSearchTests();
    _registerEditingValidationTests();
    _registerFilteringMenuTests();
    _registerSelectionScrollingTests();
    _registerColumnMenuSortingTests();
    _registerStatusSummaryTests();
    _registerCustomColumnTests();
  });
}
