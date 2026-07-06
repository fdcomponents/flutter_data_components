// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

import '../../../common/menu/fdc_menu.dart';
import '../../../data/fdc_data.dart';
import '../../../i18n/fdc_translations.dart';
import '../../columns/fdc_grid_columns.dart';
import '../../models/fdc_grid_internal_models.dart';

class FdcGridHeaderFilterMenuBuilder {
  const FdcGridHeaderFilterMenuBuilder({
    required this.callbacks,
    required this.column,
    required this.runtimeColumnId,
    this.translations = const FdcTranslations(),
  });

  final FdcGridHeaderCallbacks callbacks;
  final FdcGridColumn<dynamic> column;
  final FdcColumnIdentity runtimeColumnId;
  final FdcTranslations translations;

  List<FdcMenuEntry> buildEntries() {
    final entries = <FdcMenuEntry>[];

    _addOperatorEntries(entries);
    _addTypeSpecificEntries(entries);
    _addClearFilterEntries(entries);

    return entries;
  }

  void _addClearFilterEntries(List<FdcMenuEntry> entries) {
    final clearFilterVisible = callbacks.hasHeaderFilterStateForColumn(
      column,
      runtimeColumnId,
    );
    final clearAllVisible = callbacks.headerFilterStateCount() > 1;

    if (!clearFilterVisible && !clearAllVisible) {
      return;
    }

    if (entries.isNotEmpty) {
      entries.add(const FdcMenuSeparator());
    }

    if (clearFilterVisible) {
      entries.add(
        FdcMenuAction(
          text: translations.grid.clearFilter,
          icon: Icons.clear,
          enabled: callbacks.canChangeView(),
          onPressed: callbacks.canChangeView()
              ? () => callbacks.onClearHeaderFilter(column, runtimeColumnId)
              : null,
        ),
      );
    }

    if (clearAllVisible) {
      entries.add(
        FdcMenuAction(
          text: translations.grid.clearAllFilters,
          icon: Icons.filter_alt_off,
          enabled: callbacks.canChangeView(),
          onPressed: callbacks.canChangeView()
              ? callbacks.onClearHeaderFilters
              : null,
        ),
      );
    }
  }

  void _addOperatorEntries(List<FdcMenuEntry> entries) {
    final operator = callbacks.headerFilterOperatorOf(column, runtimeColumnId);
    final operators = callbacks.operatorsForColumn(column);
    final hasFilterState = callbacks.hasHeaderFilterStateForColumn(
      column,
      runtimeColumnId,
    );
    final isBooleanFilter = callbacks.dataTypeOf(column) == FdcDataType.boolean;

    if (operators.isEmpty) {
      return;
    }

    if (entries.isNotEmpty) {
      entries.add(const FdcMenuSeparator());
    }
    for (final item in operators) {
      entries.add(
        FdcMenuCheckAction(
          text: callbacks.filterOperatorLabel(item),
          checked: item == operator && (!isBooleanFilter || hasFilterState),
          onPressed: () => callbacks.onSetHeaderFilterOperator(
            column,
            runtimeColumnId,
            item,
          ),
        ),
      );
    }
  }

  void _addTypeSpecificEntries(List<FdcMenuEntry> entries) {
    switch (callbacks.dataTypeOf(column)) {
      case FdcDataType.string:
      case FdcDataType.guid:
        _addStringFilterEntries(entries);
        break;
      case FdcDataType.integer:
      case FdcDataType.decimal:
        _addNumericFilterEntries(entries);
        break;
      case FdcDataType.date:
      case FdcDataType.dateTime:
        _addDateFilterEntries(entries);
        break;
      case FdcDataType.time:
        _addTimeFilterEntries(entries);
        break;
      case FdcDataType.boolean:
        _addBooleanFilterEntries(entries);
        break;
      case FdcDataType.object:
        _addObjectFilterEntries(entries);
        break;
    }
  }

  void _addStringFilterEntries(List<FdcMenuEntry> entries) {
    // Reserved extension point for string filter actions such as
    // case sensitivity, starts-with/ends-with shortcuts, and unique values.
  }

  void _addNumericFilterEntries(List<FdcMenuEntry> entries) {
    // Reserved extension point for numeric filter actions such as ranges,
    // zero/non-zero shortcuts, and aggregate-aware filter helpers.
  }

  void _addDateFilterEntries(List<FdcMenuEntry> entries) {
    // Reserved extension point for date filter actions such as today,
    // this week/month, before/after, and empty/non-empty shortcuts.
  }

  void _addTimeFilterEntries(List<FdcMenuEntry> entries) {
    // Reserved extension point for time filter actions such as before/after,
    // business-hours shortcuts, and empty/non-empty handling.
  }

  void _addBooleanFilterEntries(List<FdcMenuEntry> entries) {
    // Reserved extension point for boolean filter actions such as checked,
    // unchecked, and empty-value handling.
  }

  void _addObjectFilterEntries(List<FdcMenuEntry> entries) {
    // Reserved extension point for object-backed filter controls where the
    // visual editor owns the concrete value semantics.
  }
}
