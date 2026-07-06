// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateColumnCacheRuntime on _FdcGridState {
  void _validateColumnIdentityAndGroups(List<FdcGridColumn<dynamic>> columns) {
    final usedColumnIds = <String>{};
    for (final column in columns) {
      final columnId = column.id;
      if (columnId != null) {
        if (columnId.trim().isEmpty) {
          throw ArgumentError('FdcGridColumn.id must not be empty.');
        }
        if (columnId != columnId.trim()) {
          throw ArgumentError(
            'FdcGridColumn.id must not contain leading or trailing whitespace.',
          );
        }
        if (!usedColumnIds.add(columnId)) {
          throw ArgumentError(
            'Duplicate FdcGridColumn.id "$columnId". Column ids must be unique within one grid.',
          );
        }
      }
    }

    final groupIds = <String>{};
    for (final group in widget.columnGroups) {
      if (group.id.trim().isEmpty) {
        throw ArgumentError('FdcGridColumnGroup.id must not be empty.');
      }
      if (group.id != group.id.trim()) {
        throw ArgumentError(
          'FdcGridColumnGroup.id must not contain leading or trailing whitespace.',
        );
      }
      if (!groupIds.add(group.id)) {
        throw ArgumentError(
          'Duplicate FdcGridColumnGroup.id "${group.id}". Group ids must be unique within one grid.',
        );
      }
    }

    for (final column in columns) {
      final groupId = column.groupId;
      if (groupId == null) {
        continue;
      }
      if (groupId.trim().isEmpty) {
        throw ArgumentError('FdcGridColumn.groupId must not be empty.');
      }
      if (groupId != groupId.trim()) {
        throw ArgumentError(
          'FdcGridColumn.groupId must not contain leading or trailing whitespace.',
        );
      }
      if (!groupIds.contains(groupId)) {
        throw ArgumentError(
          'FdcGridColumn.groupId "$groupId" does not match any FdcGridColumnGroup.id.',
        );
      }
    }
  }

  List<FdcColumnIdentityKey> _identityKeysForResolvedColumns(
    List<FdcGridColumn<dynamic>> columns,
  ) {
    final occurrenceCounts = <String, int>{};
    final usedExplicitIds = <String>{};
    final keys = <FdcColumnIdentityKey>[];

    for (final column in columns) {
      final explicitId = column.id;
      if (explicitId != null) {
        if (!usedExplicitIds.add(explicitId)) {
          throw ArgumentError(
            'Duplicate FdcGridColumn.id "$explicitId". Column ids must be unique within one grid.',
          );
        }
        keys.add(FdcColumnIdentityKey.explicit(explicitId));
        continue;
      }

      final normalizedFieldName = FdcFieldName.normalize(column.fieldName);
      final occurrenceKey = '${column.runtimeType}|$normalizedFieldName';
      final occurrence = occurrenceCounts.update(
        occurrenceKey,
        (value) => value + 1,
        ifAbsent: () => 0,
      );
      keys.add(
        FdcColumnIdentityKey.implicit(
          fieldName: normalizedFieldName,
          occurrence: occurrence,
          columnType: column.runtimeType,
        ),
      );
    }

    return keys;
  }

  void _refreshColumnCache() {
    _clearFieldMetadataCache();
    final resolvedColumns = _runtime.domains.columns.columns.resolveColumns(
      widget.columns,
      _rows,
      widget.dataSet,
    );
    _validateColumnIdentityAndGroups(resolvedColumns);
    final identityKeys = _identityKeysForResolvedColumns(resolvedColumns);
    final activeIdentityKeys = <FdcColumnIdentityKey>{};
    final activeRuntimeColumnIds = <FdcColumnIdentity>{};
    final columnsByRuntimeId = <FdcColumnIdentity, FdcGridColumn<dynamic>>{};
    final visibleEntries = <FdcGridRuntimeColumn>[];
    for (
      var sourceIndex = 0;
      sourceIndex < resolvedColumns.length;
      sourceIndex++
    ) {
      final column = resolvedColumns[sourceIndex];
      final identityKey = identityKeys[sourceIndex];
      activeIdentityKeys.add(identityKey);
      final runtimeColumnId = _columnIdentityForKey(identityKey);
      activeRuntimeColumnIds.add(runtimeColumnId);
      columnsByRuntimeId[runtimeColumnId] = column;
      final visible =
          _runtimeColumnVisibilityOverrides[runtimeColumnId] ?? column.visible;
      if (!visible) {
        continue;
      }
      visibleEntries.add(
        FdcGridRuntimeColumn(runtimeColumnId: runtimeColumnId, column: column),
      );
    }
    _columnIdentitiesByKey.removeWhere(
      (key, _) => !activeIdentityKeys.contains(key),
    );

    _declarativeRuntimeColumnIdsCache = [
      for (final entry in visibleEntries) entry.runtimeColumnId,
    ];

    final orderedEntries = _hasUserColumnOrderOverride
        ? _orderedEntriesFromUserOrder(visibleEntries)
        : visibleEntries;

    _visibleColumnsCache = [for (final entry in orderedEntries) entry.column];
    _visibleRuntimeColumnIdsCache = [
      for (final entry in orderedEntries) entry.runtimeColumnId,
    ];
    _refreshColumnBandsCache();
    _runtimeColumnOrderIds
      ..clear()
      ..addAll(orderedEntries.map((entry) => entry.runtimeColumnId));

    final visibleHeaderFilterRuntimeColumnIds = <FdcColumnIdentity>{
      for (final entry in visibleEntries) entry.runtimeColumnId,
    };
    _removeMissingHeaderFilterFocusNodes(visibleHeaderFilterRuntimeColumnIds);
    _columnSizing.removeMissingColumns(activeRuntimeColumnIds);
    _runtimeColumnVisibilityOverrides.removeWhere(
      (runtimeColumnId, _) => !activeRuntimeColumnIds.contains(runtimeColumnId),
    );
    _runtimeColumnPinOverrides.removeWhere((runtimeColumnId, _) {
      final column = columnsByRuntimeId[runtimeColumnId];
      return column == null || _isGroupedColumn(column);
    });
    _runtimeSummaryAggregateOverrides.removeWhere(
      (runtimeColumnId, _) => !activeRuntimeColumnIds.contains(runtimeColumnId),
    );
    _markColumnWidthsDirty();
  }

  List<FdcGridRuntimeColumn> _orderedEntriesFromUserOrder(
    List<FdcGridRuntimeColumn> visibleEntries,
  ) {
    final entriesById = <FdcColumnIdentity, FdcGridRuntimeColumn>{
      for (final entry in visibleEntries) entry.runtimeColumnId: entry,
    };
    return <FdcGridRuntimeColumn>[
      for (final id in _runtimeColumnOrderIds)
        if (entriesById.containsKey(id)) entriesById[id]!,
      for (final entry in visibleEntries)
        if (!_runtimeColumnOrderIds.contains(entry.runtimeColumnId)) entry,
    ];
  }

  void _refreshColumnBandsCache() {
    _columnBandsCache = FdcGridColumnBands.fromVisibleColumns(
      columns: _visibleColumnsCache,
      runtimeColumnIds: _visibleRuntimeColumnIdsCache,
      pinOf: _effectiveColumnPin,
      textDirection: _textDirection,
    );
  }

  FdcGridColumnBandLayouts _columnBandLayouts() {
    final snapshot = _columnSizing.buildRuntimeColumnSnapshot(
      columns: _visibleColumnsCache,
      runtimeColumnIds: _visibleRuntimeColumnIdsCache,
      defaultColumnWidth: widget.options.resolvedDefaultColumnWidth,
      pinOf: _effectiveColumnPin,
    );

    return FdcGridColumnBandLayouts.fromRuntimeSnapshot(
      snapshot: snapshot,
      textDirection: _textDirection,
    );
  }
}
