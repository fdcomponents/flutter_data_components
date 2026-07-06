// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import '../columns/fdc_grid_columns.dart';
import '../models/fdc_column_identity.dart';

class FdcGridColumnSizingManager {
  final Map<FdcColumnIdentity, double> columnWidths =
      <FdcColumnIdentity, double>{};
  final Map<FdcColumnIdentity, double> effectiveColumnWidths =
      <FdcColumnIdentity, double>{};
  final Map<FdcColumnIdentity, double> _suspendedAutoColumnWidths =
      <FdcColumnIdentity, double>{};
  final Map<FdcColumnIdentity, FdcGridColumnWidthMatrixEntry> _widthMatrix =
      <FdcColumnIdentity, FdcGridColumnWidthMatrixEntry>{};

  double? _lastAutoSizeAvailableWidth;
  bool _autoSizeTracksViewportDelta = false;

  bool get hasUserColumnWidths => columnWidths.isNotEmpty;

  void resetUserColumnWidths() {
    columnWidths.clear();
    effectiveColumnWidths.clear();
    _widthMatrix.clear();
    resetAutoSize();
  }

  void resetAutoSize() {
    _suspendedAutoColumnWidths.clear();
    _lastAutoSizeAvailableWidth = null;
    _autoSizeTracksViewportDelta = false;
  }

  /// Synchronizes the private runtime metrics companion with the current
  /// visible column definitions. Public column definitions remain declarative;
  ///
  /// this store owns mutable layout state such as user/effective width and
  /// visibility.
  void syncRuntimeColumns({
    required List<FdcGridColumn<dynamic>> columns,
    required List<FdcColumnIdentity> runtimeColumnIds,
    required double defaultColumnWidth,
  }) {
    _syncWidthMatrix(
      columns: columns,
      runtimeColumnIds: runtimeColumnIds,
      defaultColumnWidth: defaultColumnWidth,
    );
  }

  void removeMissingColumns(Set<FdcColumnIdentity> visibleRuntimeColumnIds) {
    columnWidths.removeWhere(
      (id, width) => !visibleRuntimeColumnIds.contains(id),
    );
    effectiveColumnWidths.removeWhere(
      (id, width) => !visibleRuntimeColumnIds.contains(id),
    );
    _suspendedAutoColumnWidths.removeWhere(
      (id, width) => !visibleRuntimeColumnIds.contains(id),
    );
    _widthMatrix.removeWhere(
      (id, entry) => !visibleRuntimeColumnIds.contains(id),
    );
  }

  double columnWidth(
    FdcColumnIdentity runtimeColumnId,
    FdcGridColumn<dynamic> column, {
    required double defaultColumnWidth,
  }) {
    return _widthMatrix[runtimeColumnId]?.width ??
        effectiveColumnWidths[runtimeColumnId] ??
        baseColumnWidth(
          runtimeColumnId,
          column,
          defaultColumnWidth: defaultColumnWidth,
        );
  }

  bool columnVisible(
    FdcColumnIdentity runtimeColumnId,
    FdcGridColumn<dynamic> column,
  ) {
    return _widthMatrix[runtimeColumnId]?.visible ?? column.visible;
  }

  FdcGridRuntimeColumnMetricsSnapshot buildRuntimeColumnSnapshot({
    required List<FdcGridColumn<dynamic>> columns,
    required List<FdcColumnIdentity> runtimeColumnIds,
    required double defaultColumnWidth,
    FdcGridColumnPin Function(
      FdcGridColumn<dynamic> column,
      FdcColumnIdentity runtimeColumnId,
    )?
    pinOf,
  }) {
    _syncWidthMatrix(
      columns: columns,
      runtimeColumnIds: runtimeColumnIds,
      defaultColumnWidth: defaultColumnWidth,
    );

    final metrics = <FdcGridRuntimeColumnMetric>[];
    final length = math.min(columns.length, runtimeColumnIds.length);
    for (var index = 0; index < length; index++) {
      final column = columns[index];
      final runtimeColumnId = runtimeColumnIds[index];
      final entry = _widthMatrix[runtimeColumnId];
      final width =
          entry?.width ??
          baseColumnWidth(
            runtimeColumnId,
            column,
            defaultColumnWidth: defaultColumnWidth,
          );
      final visible = entry?.visible ?? column.visible;
      metrics.add(
        FdcGridRuntimeColumnMetric(
          runtimeColumnId: runtimeColumnId,
          column: column,
          sourceColumnIndex: index,
          width: width,
          visible: visible,
          pin: pinOf?.call(column, runtimeColumnId) ?? column.pin,
        ),
      );
    }

    return FdcGridRuntimeColumnMetricsSnapshot(
      metrics: List<FdcGridRuntimeColumnMetric>.unmodifiable(metrics),
    );
  }

  double baseColumnWidth(
    FdcColumnIdentity runtimeColumnId,
    FdcGridColumn<dynamic> column, {
    required double defaultColumnWidth,
  }) {
    return columnWidths[runtimeColumnId] ?? column.width ?? defaultColumnWidth;
  }

  double baseGridWidth(
    List<FdcGridColumn<dynamic>> columns, {
    required List<FdcColumnIdentity> runtimeColumnIds,
    required double defaultColumnWidth,
  }) {
    _syncWidthMatrix(
      columns: columns,
      runtimeColumnIds: runtimeColumnIds,
      defaultColumnWidth: defaultColumnWidth,
    );
    return _indexedFold(
      columns,
      runtimeColumnIds,
      0.0,
      (sum, column, runtimeColumnId) =>
          sum +
          (_widthMatrix[runtimeColumnId]?.width ??
              baseColumnWidth(
                runtimeColumnId,
                column,
                defaultColumnWidth: defaultColumnWidth,
              )),
    );
  }

  void setColumnWidth(
    FdcColumnIdentity runtimeColumnId,
    FdcGridColumn<dynamic> column,
    double width, {
    required List<FdcGridColumn<dynamic>> columns,
    required List<FdcColumnIdentity> runtimeColumnIds,
    required double defaultColumnWidth,
  }) {
    _syncWidthMatrix(
      columns: columns,
      runtimeColumnIds: runtimeColumnIds,
      defaultColumnWidth: defaultColumnWidth,
    );
    _setMatrixWidth(runtimeColumnId, column, width, defaultColumnWidth);
    columnWidths[runtimeColumnId] = width;
    _applyMatrixToEffectiveWidths();
    _suspendAutoSizeAtCurrentWidth(
      resizedRuntimeColumnId: runtimeColumnId,
      resizedColumn: column,
      resizedWidth: width,
      columns: columns,
      runtimeColumnIds: runtimeColumnIds,
      defaultColumnWidth: defaultColumnWidth,
    );
  }

  void refreshEffectiveColumnWidths({
    required double? availableWidth,
    required List<FdcGridColumn<dynamic>> columns,
    required List<FdcColumnIdentity> runtimeColumnIds,
    required double defaultColumnWidth,
    required double minimumResizableColumnWidth,
  }) {
    _syncWidthMatrix(
      columns: columns,
      runtimeColumnIds: runtimeColumnIds,
      defaultColumnWidth: defaultColumnWidth,
    );
    final widths = <FdcColumnIdentity, double>{
      for (var index = 0; index < columns.length; index++)
        runtimeColumnIds[index]: _widthMatrix[runtimeColumnIds[index]]!.width,
    };
    final autoEntries = _autoColumnEntries(columns, runtimeColumnIds);
    final preferredAutoWidths = _preferredAutoColumnWidths(
      autoEntries,
      defaultColumnWidth: defaultColumnWidth,
    );

    if (availableWidth != null && autoEntries.isNotEmpty) {
      final fixedWidth = _fixedColumnsWidth(
        columns,
        runtimeColumnIds,
        autoEntries,
        widths,
      );
      final previousAvailableWidth = _lastAutoSizeAvailableWidth;
      final minimums = <FdcColumnIdentity, double>{
        for (final entry in autoEntries)
          entry.id: _configuredMinColumnWidth(
            entry.column,
            minimumResizableColumnWidth,
          ),
      };
      final maximums = <FdcColumnIdentity, double>{
        for (final entry in autoEntries)
          entry.id: _columnMaxWidth(entry.column, minimums[entry.id]!),
      };
      final preferredAutoWidth = autoEntries.fold(0.0, (sum, entry) {
        return sum +
            preferredAutoWidths[entry.id]!
                .clamp(minimums[entry.id]!, maximums[entry.id]!)
                .toDouble();
      });
      final targetAutoWidth = _autoSizeTracksViewportDelta
          ? math.max(
              0.0,
              preferredAutoWidth +
                  (previousAvailableWidth == null
                      ? 0.0
                      : availableWidth - previousAvailableWidth),
            )
          : math.max(0.0, availableWidth - fixedWidth);
      final autoWidths = _distributeAutoColumnWidths(
        autoEntries,
        targetAutoWidth,
        minimums,
        maximums,
        defaultColumnWidth: defaultColumnWidth,
        preferredWidths: preferredAutoWidths,
      );
      _suspendedAutoColumnWidths.clear();
      widths.addAll(autoWidths);
    }

    _replaceMatrixWidths(widths);
    effectiveColumnWidths
      ..clear()
      ..addAll(widths);
    _lastAutoSizeAvailableWidth = availableWidth;
  }

  void autoSizeColumnsForViewport({
    required double? availableWidth,
    required List<FdcGridColumn<dynamic>> columns,
    required List<FdcColumnIdentity> runtimeColumnIds,
    required double defaultColumnWidth,
    required double minimumResizableColumnWidth,
  }) {
    _syncWidthMatrix(
      columns: columns,
      runtimeColumnIds: runtimeColumnIds,
      defaultColumnWidth: defaultColumnWidth,
    );
    final autoEntries = _autoColumnEntries(columns, runtimeColumnIds);
    if (availableWidth == null || autoEntries.isEmpty) {
      _lastAutoSizeAvailableWidth = availableWidth;
      return;
    }

    final widths = <FdcColumnIdentity, double>{
      for (var index = 0; index < columns.length; index++)
        runtimeColumnIds[index]: _widthMatrix[runtimeColumnIds[index]]!.width,
    };
    final fixedWidth = _fixedColumnsWidth(
      columns,
      runtimeColumnIds,
      autoEntries,
      widths,
    );
    final previousAvailableWidth = _lastAutoSizeAvailableWidth;
    final currentAutoWidth = autoEntries.fold(
      0.0,
      (sum, entry) => sum + widths[entry.id]!,
    );
    final targetAutoWidth = _autoSizeTracksViewportDelta
        ? math.max(
            0.0,
            currentAutoWidth +
                (previousAvailableWidth == null
                    ? 0.0
                    : availableWidth - previousAvailableWidth),
          )
        : math.max(0.0, availableWidth - fixedWidth);
    final minimums = <FdcColumnIdentity, double>{
      for (final entry in autoEntries)
        entry.id: _configuredMinColumnWidth(
          entry.column,
          minimumResizableColumnWidth,
        ),
    };
    final maximums = <FdcColumnIdentity, double>{
      for (final entry in autoEntries)
        entry.id: _columnMaxWidth(entry.column, minimums[entry.id]!),
    };
    final autoWidths = _distributeAutoColumnWidths(
      autoEntries,
      targetAutoWidth,
      minimums,
      maximums,
      defaultColumnWidth: defaultColumnWidth,
      preferredWidths: {
        for (final entry in autoEntries) entry.id: widths[entry.id]!,
      },
    );
    widths.addAll(autoWidths);
    _replaceMatrixWidths(widths);
    effectiveColumnWidths
      ..clear()
      ..addAll(widths);
    _lastAutoSizeAvailableWidth = availableWidth;
  }

  void _suspendAutoSizeAtCurrentWidth({
    required FdcColumnIdentity resizedRuntimeColumnId,
    required FdcGridColumn<dynamic> resizedColumn,
    required double resizedWidth,
    required List<FdcGridColumn<dynamic>> columns,
    required List<FdcColumnIdentity> runtimeColumnIds,
    required double defaultColumnWidth,
  }) {
    final availableWidth = _lastAutoSizeAvailableWidth;
    if (availableWidth == null) {
      return;
    }

    _autoSizeTracksViewportDelta = true;
    _suspendedAutoColumnWidths
      ..clear()
      ..addEntries(
        _autoColumnEntries(columns, runtimeColumnIds).map(
          (entry) => MapEntry(
            entry.id,
            entry.id == resizedRuntimeColumnId
                ? resizedWidth
                : effectiveColumnWidths[entry.id] ??
                      baseColumnWidth(
                        entry.id,
                        entry.column,
                        defaultColumnWidth: defaultColumnWidth,
                      ),
          ),
        ),
      );
  }

  double _fixedColumnsWidth(
    List<FdcGridColumn<dynamic>> columns,
    List<FdcColumnIdentity> runtimeColumnIds,
    List<_ColumnSizingEntry> autoEntries,
    Map<FdcColumnIdentity, double> widths,
  ) {
    final autoEntryIds = {for (final entry in autoEntries) entry.id};
    var width = 0.0;
    _forEachColumnEntry(columns, runtimeColumnIds, (entry) {
      if (!autoEntryIds.contains(entry.id)) {
        width += widths[entry.id]!;
      }
    });
    return width;
  }

  Map<FdcColumnIdentity, double> _distributeAutoColumnWidths(
    List<_ColumnSizingEntry> entries,
    double targetWidth,
    Map<FdcColumnIdentity, double> minimums,
    Map<FdcColumnIdentity, double> maximums, {
    required double defaultColumnWidth,
    Map<FdcColumnIdentity, double>? preferredWidths,
  }) {
    final widths = <FdcColumnIdentity, double>{
      for (final entry in entries)
        entry.id:
            (preferredWidths?[entry.id] ??
                    baseColumnWidth(
                      entry.id,
                      entry.column,
                      defaultColumnWidth: defaultColumnWidth,
                    ))
                .clamp(minimums[entry.id]!, maximums[entry.id]!)
                .toDouble(),
    };
    var remaining =
        targetWidth - widths.values.fold(0.0, (sum, width) => sum + width);
    if (remaining.abs() <= 0.5) {
      return widths;
    }

    var openEntries = entries.toList();
    while (remaining.abs() > 0.5 && openEntries.isNotEmpty) {
      final weightTotal = openEntries.fold(0.0, (sum, entry) {
        final width = widths[entry.id]!;
        if (remaining > 0) {
          return sum + math.max(1.0, width);
        }
        return sum + math.max(1.0, width - minimums[entry.id]!);
      });
      var distributed = 0.0;
      final nextOpenEntries = <_ColumnSizingEntry>[];

      for (final entry in openEntries) {
        if (weightTotal <= 0) {
          break;
        }
        final current = widths[entry.id]!;
        final minWidth = minimums[entry.id]!;
        final maxWidth = maximums[entry.id]!;
        final bound = remaining > 0 ? maxWidth : minWidth;
        final weight = remaining > 0
            ? math.max(1.0, current)
            : math.max(1.0, current - minWidth);
        final share = remaining * weight / weightTotal;
        final next = remaining > 0
            ? math.min(maxWidth, current + share)
            : math.max(minWidth, current + share);
        final delta = next - current;
        widths[entry.id] = next;
        distributed += delta.abs();
        if ((bound - next).abs() > 0.5) {
          nextOpenEntries.add(entry);
        }
      }

      if (distributed <= 0.5) {
        break;
      }
      remaining =
          targetWidth - widths.values.fold(0.0, (sum, width) => sum + width);
      openEntries = nextOpenEntries;
    }

    return widths;
  }

  double _configuredMinColumnWidth(
    FdcGridColumn<dynamic> column,
    double minimumResizableColumnWidth,
  ) {
    return math.max(
      column.minWidth > 0 ? column.minWidth : 0.0,
      minimumResizableColumnWidth,
    );
  }

  double _columnMaxWidth(FdcGridColumn<dynamic> column, double lowerBound) {
    if (column.maxWidth <= 0) {
      return double.infinity;
    }
    return math.max(column.maxWidth, lowerBound);
  }

  Map<FdcColumnIdentity, double> _preferredAutoColumnWidths(
    List<_ColumnSizingEntry> entries, {
    required double defaultColumnWidth,
  }) {
    return {
      for (final entry in entries)
        entry.id:
            _suspendedAutoColumnWidths[entry.id] ??
            _widthMatrix[entry.id]?.width ??
            effectiveColumnWidths[entry.id] ??
            baseColumnWidth(
              entry.id,
              entry.column,
              defaultColumnWidth: defaultColumnWidth,
            ),
    };
  }

  void _syncWidthMatrix({
    required List<FdcGridColumn<dynamic>> columns,
    required List<FdcColumnIdentity> runtimeColumnIds,
    required double defaultColumnWidth,
  }) {
    final ids = <FdcColumnIdentity>{};
    final length = math.min(columns.length, runtimeColumnIds.length);
    for (var index = 0; index < length; index++) {
      final column = columns[index];
      final id = runtimeColumnIds[index];
      ids.add(id);
      final explicitBaseWidth = baseColumnWidth(
        id,
        column,
        defaultColumnWidth: defaultColumnWidth,
      );
      final existing = _widthMatrix[id];
      if (existing == null) {
        _widthMatrix[id] = FdcGridColumnWidthMatrixEntry(
          runtimeColumnId: id,
          width: effectiveColumnWidths[id] ?? explicitBaseWidth,
          visible: column.visible,
        );
        continue;
      }

      _widthMatrix[id] = existing.copyWith(
        visible: column.visible,
        width: existing.width,
      );
    }
  }

  void _setMatrixWidth(
    FdcColumnIdentity runtimeColumnId,
    FdcGridColumn<dynamic> column,
    double width,
    double defaultColumnWidth,
  ) {
    final existing = _widthMatrix[runtimeColumnId];
    _widthMatrix[runtimeColumnId] = FdcGridColumnWidthMatrixEntry(
      runtimeColumnId: runtimeColumnId,
      width: width,
      visible: column.visible,
    );
    if (existing == null) {
      effectiveColumnWidths[runtimeColumnId] = width;
    }
  }

  void _replaceMatrixWidths(Map<FdcColumnIdentity, double> widths) {
    for (final entry in widths.entries) {
      final current = _widthMatrix[entry.key];
      if (current == null) {
        _widthMatrix[entry.key] = FdcGridColumnWidthMatrixEntry(
          runtimeColumnId: entry.key,
          width: entry.value,
          visible: true,
        );
        continue;
      }
      _widthMatrix[entry.key] = current.copyWith(width: entry.value);
    }
  }

  void _applyMatrixToEffectiveWidths() {
    effectiveColumnWidths
      ..clear()
      ..addEntries(
        _widthMatrix.entries.map(
          (entry) => MapEntry(entry.key, entry.value.width),
        ),
      );
  }

  void _forEachColumnEntry(
    List<FdcGridColumn<dynamic>> columns,
    List<FdcColumnIdentity> runtimeColumnIds,
    void Function(_ColumnSizingEntry entry) action,
  ) {
    final length = math.min(columns.length, runtimeColumnIds.length);
    for (var index = 0; index < length; index++) {
      action(_ColumnSizingEntry(runtimeColumnIds[index], columns[index]));
    }
  }

  List<_ColumnSizingEntry> _autoColumnEntries(
    List<FdcGridColumn<dynamic>> columns,
    List<FdcColumnIdentity> runtimeColumnIds,
  ) {
    final entries = <_ColumnSizingEntry>[];
    _forEachColumnEntry(columns, runtimeColumnIds, (entry) {
      if (entry.column.autoSizeMode == FdcGridColumnAutoSizeMode.viewport &&
          entry.column.visible) {
        entries.add(entry);
      }
    });
    return entries;
  }

  T _indexedFold<T>(
    List<FdcGridColumn<dynamic>> columns,
    List<FdcColumnIdentity> runtimeColumnIds,
    T initialValue,
    T Function(
      T value,
      FdcGridColumn<dynamic> column,
      FdcColumnIdentity runtimeColumnId,
    )
    combine,
  ) {
    var value = initialValue;
    final length = math.min(columns.length, runtimeColumnIds.length);
    for (var index = 0; index < length; index++) {
      value = combine(value, columns[index], runtimeColumnIds[index]);
    }
    return value;
  }
}

class FdcGridRuntimeColumnMetricsSnapshot {
  const FdcGridRuntimeColumnMetricsSnapshot({required this.metrics});

  final List<FdcGridRuntimeColumnMetric> metrics;

  Iterable<FdcGridRuntimeColumnMetric> visibleMetricsForPin(
    bool Function(FdcGridColumnPin pin) matches,
  ) {
    return metrics.where((metric) => metric.visible && matches(metric.pin));
  }
}

class FdcGridRuntimeColumnMetric {
  const FdcGridRuntimeColumnMetric({
    required this.runtimeColumnId,
    required this.column,
    required this.sourceColumnIndex,
    required this.width,
    required this.visible,
    required this.pin,
  });

  final FdcColumnIdentity runtimeColumnId;
  final FdcGridColumn<dynamic> column;
  final int sourceColumnIndex;
  final double width;
  final bool visible;
  final FdcGridColumnPin pin;
}

class FdcGridColumnWidthMatrixEntry {
  const FdcGridColumnWidthMatrixEntry({
    required this.runtimeColumnId,
    required this.width,
    required this.visible,
  });

  final FdcColumnIdentity runtimeColumnId;
  final double width;
  final bool visible;

  FdcGridColumnWidthMatrixEntry copyWith({double? width, bool? visible}) {
    return FdcGridColumnWidthMatrixEntry(
      runtimeColumnId: runtimeColumnId,
      width: width ?? this.width,
      visible: visible ?? this.visible,
    );
  }
}

class _ColumnSizingEntry {
  const _ColumnSizingEntry(this.id, this.column);

  final FdcColumnIdentity id;
  final FdcGridColumn<dynamic> column;
}
