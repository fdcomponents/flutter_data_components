// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/widgets.dart' show TextDirection;

import '../columns/fdc_action_column.dart';
import '../columns/fdc_column_base.dart';
import '../managers/fdc_grid_column_sizing_manager.dart';
import 'fdc_column_identity.dart';
import 'fdc_grid_row_indicator_models.dart';

@immutable
class FdcColumnIdentityKey {
  const FdcColumnIdentityKey.explicit(this.id)
    : fieldName = null,
      occurrence = null,
      columnType = null;

  const FdcColumnIdentityKey.implicit({
    required this.fieldName,
    required this.occurrence,
    required this.columnType,
  }) : id = null;

  final String? id;
  final String? fieldName;
  final int? occurrence;
  final Type? columnType;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is FdcColumnIdentityKey &&
            id == other.id &&
            fieldName == other.fieldName &&
            occurrence == other.occurrence &&
            columnType == other.columnType;
  }

  @override
  int get hashCode => Object.hash(id, fieldName, occurrence, columnType);

  @override
  String toString() {
    if (id != null) {
      return 'FdcColumnIdentityKey(id: $id)';
    }
    return 'FdcColumnIdentityKey(fieldName: $fieldName, occurrence: $occurrence, columnType: $columnType)';
  }
}

class FdcGridRuntimeColumn {
  const FdcGridRuntimeColumn({
    required this.runtimeColumnId,
    required this.column,
  });

  // Runtime identity assigned by a concrete grid instance. This is not part of
  // the public column definition; the same FdcGridColumn definition can be used
  // in multiple grids and receive different runtime identities in each grid.
  final FdcColumnIdentity runtimeColumnId;
  final FdcGridColumn<dynamic> column;
}

class FdcGridColumnBand {
  const FdcGridColumnBand({
    required this.columns,
    required this.runtimeColumnIds,
    required this.columnIndexes,
    required this.columnSignature,
  });

  static const empty = FdcGridColumnBand(
    columns: <FdcGridColumn<dynamic>>[],
    runtimeColumnIds: <FdcColumnIdentity>[],
    columnIndexes: <int>[],
    columnSignature: '',
  );

  final List<FdcGridColumn<dynamic>> columns;
  final List<FdcColumnIdentity> runtimeColumnIds;
  final List<int> columnIndexes;
  final String columnSignature;

  bool get isEmpty => columns.isEmpty;
  bool get isNotEmpty => columns.isNotEmpty;
  int get length => columns.length;
}

class FdcGridColumnBands {
  const FdcGridColumnBands({
    required this.pinnedLeft,
    required this.scrollable,
    required this.pinnedRight,
  });

  factory FdcGridColumnBands.fromVisibleColumns({
    required List<FdcGridColumn<dynamic>> columns,
    required List<FdcColumnIdentity> runtimeColumnIds,
    FdcGridColumnPin Function(
      FdcGridColumn<dynamic> column,
      FdcColumnIdentity runtimeColumnId,
    )?
    pinOf,
    required TextDirection textDirection,
  }) {
    assert(columns.length == runtimeColumnIds.length);
    final pinnedLeftColumns = <FdcGridColumn<dynamic>>[];
    final pinnedLeftIds = <FdcColumnIdentity>[];
    final pinnedLeftIndexes = <int>[];
    final scrollableColumns = <FdcGridColumn<dynamic>>[];
    final scrollableIds = <FdcColumnIdentity>[];
    final scrollableIndexes = <int>[];
    final pinnedRightColumns = <FdcGridColumn<dynamic>>[];
    final pinnedRightIds = <FdcColumnIdentity>[];
    final pinnedRightIndexes = <int>[];

    for (var index = 0; index < columns.length; index++) {
      final column = columns[index];
      final runtimeColumnId = runtimeColumnIds[index];
      final pin = pinOf?.call(column, runtimeColumnId) ?? column.pin;
      final pinsLeft = textDirection == TextDirection.ltr
          ? pin.isStart
          : pin.isEnd;
      if (pinsLeft) {
        pinnedLeftColumns.add(column);
        pinnedLeftIds.add(runtimeColumnId);
        pinnedLeftIndexes.add(index);
        continue;
      }

      final pinsRight = textDirection == TextDirection.ltr
          ? pin.isEnd
          : pin.isStart;
      if (pinsRight) {
        pinnedRightColumns.add(column);
        pinnedRightIds.add(runtimeColumnId);
        pinnedRightIndexes.add(index);
        continue;
      }

      scrollableColumns.add(column);
      scrollableIds.add(runtimeColumnId);
      scrollableIndexes.add(index);
    }

    return FdcGridColumnBands(
      pinnedLeft: FdcGridColumnBand(
        columns: List<FdcGridColumn<dynamic>>.unmodifiable(pinnedLeftColumns),
        runtimeColumnIds: List<FdcColumnIdentity>.unmodifiable(pinnedLeftIds),
        columnIndexes: List<int>.unmodifiable(pinnedLeftIndexes),
        columnSignature: _columnSignatureFor(pinnedLeftIds),
      ),
      scrollable: FdcGridColumnBand(
        columns: List<FdcGridColumn<dynamic>>.unmodifiable(scrollableColumns),
        runtimeColumnIds: List<FdcColumnIdentity>.unmodifiable(scrollableIds),
        columnIndexes: List<int>.unmodifiable(scrollableIndexes),
        columnSignature: _columnSignatureFor(scrollableIds),
      ),
      pinnedRight: FdcGridColumnBand(
        columns: List<FdcGridColumn<dynamic>>.unmodifiable(pinnedRightColumns),
        runtimeColumnIds: List<FdcColumnIdentity>.unmodifiable(pinnedRightIds),
        columnIndexes: List<int>.unmodifiable(pinnedRightIndexes),
        columnSignature: _columnSignatureFor(pinnedRightIds),
      ),
    );
  }

  static String _columnSignatureFor(List<FdcColumnIdentity> runtimeColumnIds) {
    if (runtimeColumnIds.isEmpty) {
      return '';
    }
    return runtimeColumnIds.join('|');
  }

  /// Data columns pinned to the leading side of the grid.
  final FdcGridColumnBand pinnedLeft;

  /// Data columns that move with the horizontal scroll area.
  final FdcGridColumnBand scrollable;

  /// Data columns pinned to the trailing side of the grid.
  final FdcGridColumnBand pinnedRight;

  bool get hasPinnedLeftColumns => pinnedLeft.isNotEmpty;
  bool get hasPinnedRightColumns => pinnedRight.isNotEmpty;
}

class FdcGridColumnGeometry {
  const FdcGridColumnGeometry({
    required this.runtimeColumnId,
    required this.column,
    required this.sourceColumnIndex,
    required this.localColumnIndex,
    required this.width,
    required this.offset,
    required this.visible,
  });

  final FdcColumnIdentity runtimeColumnId;
  final FdcGridColumn<dynamic> column;
  final int sourceColumnIndex;
  final int localColumnIndex;
  final double width;
  final double offset;
  final bool visible;

  FdcGridColumnGeometry copyWith({double? width, double? offset}) {
    return FdcGridColumnGeometry(
      runtimeColumnId: runtimeColumnId,
      column: column,
      sourceColumnIndex: sourceColumnIndex,
      localColumnIndex: localColumnIndex,
      width: width ?? this.width,
      offset: offset ?? this.offset,
      visible: visible,
    );
  }
}

class FdcGridColumnBandLayout {
  const FdcGridColumnBandLayout({
    required this.band,
    required this.geometries,
    required this.columnWidths,
    required this.columnOffsets,
    required this.width,
    required this.resizeTargetLocalColumnIndexes,
    required this.resizeTargetColumns,
    required this.resizeTargetRuntimeColumnIds,
    required this.resizeTargetColumnIndexes,
    required this.resizeDeltaFactors,
    this.stretchesLastColumn = false,
  });

  factory FdcGridColumnBandLayout.fromRuntimeMetrics({
    required List<FdcGridRuntimeColumnMetric> metrics,
    required String columnSignature,
  }) {
    if (metrics.isEmpty) {
      return FdcGridColumnBandLayout.empty;
    }

    final columns = <FdcGridColumn<dynamic>>[];
    final runtimeColumnIds = <FdcColumnIdentity>[];
    final sourceColumnIndexes = <int>[];
    final widths = <double>[];
    final offsets = <double>[];
    final geometries = <FdcGridColumnGeometry>[];
    var offset = 0.0;

    for (var localIndex = 0; localIndex < metrics.length; localIndex++) {
      final metric = metrics[localIndex];
      columns.add(metric.column);
      runtimeColumnIds.add(metric.runtimeColumnId);
      sourceColumnIndexes.add(metric.sourceColumnIndex);
      widths.add(metric.width);
      offsets.add(offset);
      geometries.add(
        FdcGridColumnGeometry(
          runtimeColumnId: metric.runtimeColumnId,
          column: metric.column,
          sourceColumnIndex: metric.sourceColumnIndex,
          localColumnIndex: localIndex,
          width: metric.width,
          offset: offset,
          visible: metric.visible,
        ),
      );
      offset += metric.width;
    }

    final band = FdcGridColumnBand(
      columns: List<FdcGridColumn<dynamic>>.unmodifiable(columns),
      runtimeColumnIds: List<FdcColumnIdentity>.unmodifiable(runtimeColumnIds),
      columnIndexes: List<int>.unmodifiable(sourceColumnIndexes),
      columnSignature: columnSignature,
    );

    return FdcGridColumnBandLayout(
      band: band,
      geometries: List<FdcGridColumnGeometry>.unmodifiable(geometries),
      columnWidths: List<double>.unmodifiable(widths),
      columnOffsets: List<double>.unmodifiable(offsets),
      width: offset,
      resizeTargetLocalColumnIndexes: List<int?>.filled(band.length, null),
      resizeTargetColumns: List<FdcGridColumn<dynamic>?>.filled(
        band.length,
        null,
      ),
      resizeTargetRuntimeColumnIds: List<FdcColumnIdentity?>.filled(
        band.length,
        null,
      ),
      resizeTargetColumnIndexes: List<int?>.filled(band.length, null),
      resizeDeltaFactors: List<double>.filled(band.length, 1.0),
    );
  }

  factory FdcGridColumnBandLayout.fromBand({
    required FdcGridColumnBand band,
    required FdcGridColumnSizingManager columnSizing,
    required double defaultColumnWidth,
  }) {
    if (band.isEmpty) {
      return FdcGridColumnBandLayout.empty;
    }

    final widths = <double>[];
    final offsets = <double>[];
    final geometries = <FdcGridColumnGeometry>[];
    var offset = 0.0;
    for (var index = 0; index < band.columns.length; index++) {
      final width = columnSizing.columnWidth(
        band.runtimeColumnIds[index],
        band.columns[index],
        defaultColumnWidth: defaultColumnWidth,
      );
      widths.add(width);
      offsets.add(offset);
      geometries.add(
        FdcGridColumnGeometry(
          runtimeColumnId: band.runtimeColumnIds[index],
          column: band.columns[index],
          sourceColumnIndex: band.columnIndexes[index],
          localColumnIndex: index,
          width: width,
          offset: offset,
          visible: columnSizing.columnVisible(
            band.runtimeColumnIds[index],
            band.columns[index],
          ),
        ),
      );
      offset += width;
    }

    return FdcGridColumnBandLayout(
      band: band,
      geometries: List<FdcGridColumnGeometry>.unmodifiable(geometries),
      columnWidths: List<double>.unmodifiable(widths),
      columnOffsets: List<double>.unmodifiable(offsets),
      width: offset,
      resizeTargetLocalColumnIndexes: List<int?>.filled(band.length, null),
      resizeTargetColumns: List<FdcGridColumn<dynamic>?>.filled(
        band.length,
        null,
      ),
      resizeTargetRuntimeColumnIds: List<FdcColumnIdentity?>.filled(
        band.length,
        null,
      ),
      resizeTargetColumnIndexes: List<int?>.filled(band.length, null),
      resizeDeltaFactors: List<double>.filled(band.length, 1.0),
    );
  }

  static const empty = FdcGridColumnBandLayout(
    band: FdcGridColumnBand.empty,
    geometries: <FdcGridColumnGeometry>[],
    columnWidths: <double>[],
    columnOffsets: <double>[],
    width: 0.0,
    resizeTargetLocalColumnIndexes: <int?>[],
    resizeTargetColumns: <FdcGridColumn<dynamic>?>[],
    resizeTargetRuntimeColumnIds: <FdcColumnIdentity?>[],
    resizeTargetColumnIndexes: <int?>[],
    resizeDeltaFactors: <double>[],
  );

  final FdcGridColumnBand band;
  final List<FdcGridColumnGeometry> geometries;
  final List<double> columnWidths;
  final List<double> columnOffsets;
  final double width;
  final List<int?> resizeTargetLocalColumnIndexes;
  final List<FdcGridColumn<dynamic>?> resizeTargetColumns;
  final List<FdcColumnIdentity?> resizeTargetRuntimeColumnIds;
  final List<int?> resizeTargetColumnIndexes;
  final List<double> resizeDeltaFactors;

  /// Whether this viewport projection expanded the last scrollable column.
  ///
  /// The projected trailing edge is a center-band filler next to right-pinned
  /// columns, not a normal resizable column boundary.
  final bool stretchesLastColumn;

  List<FdcGridColumn<dynamic>> get columns => band.columns;
  List<FdcColumnIdentity> get runtimeColumnIds => band.runtimeColumnIds;
  List<int> get columnIndexes => band.columnIndexes;
  String get columnSignature => band.columnSignature;
  bool get isEmpty => band.isEmpty;
  bool get isNotEmpty => band.isNotEmpty;
  int get length => band.length;

  FdcGridColumnGeometry? geometryAt(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= geometries.length) {
      return null;
    }
    return geometries[columnIndex];
  }

  FdcGridColumn<dynamic>? columnAt(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= columns.length) {
      return null;
    }
    return columns[columnIndex];
  }

  FdcColumnIdentity? runtimeColumnIdAt(int columnIndex) {
    if (columnIndex < 0 || columnIndex >= runtimeColumnIds.length) {
      return null;
    }
    return runtimeColumnIds[columnIndex];
  }

  int? resizeTargetLocalColumnIndexAt(int localColumnIndex) {
    if (localColumnIndex < 0 ||
        localColumnIndex >= resizeTargetLocalColumnIndexes.length) {
      return null;
    }
    return resizeTargetLocalColumnIndexes[localColumnIndex];
  }

  FdcGridColumn<dynamic>? resizeTargetColumnAt(int localColumnIndex) {
    if (localColumnIndex < 0 ||
        localColumnIndex >= resizeTargetColumns.length) {
      return null;
    }
    return resizeTargetColumns[localColumnIndex];
  }

  FdcColumnIdentity? resizeTargetRuntimeColumnIdAt(int localColumnIndex) {
    if (localColumnIndex < 0 ||
        localColumnIndex >= resizeTargetRuntimeColumnIds.length) {
      return null;
    }
    return resizeTargetRuntimeColumnIds[localColumnIndex];
  }

  int? resizeTargetColumnIndexAt(int localColumnIndex) {
    if (localColumnIndex < 0 ||
        localColumnIndex >= resizeTargetColumnIndexes.length) {
      return null;
    }
    return resizeTargetColumnIndexes[localColumnIndex];
  }

  double resizeDeltaFactorAt(int localColumnIndex) {
    if (localColumnIndex < 0 || localColumnIndex >= resizeDeltaFactors.length) {
      return 1.0;
    }
    return resizeDeltaFactors[localColumnIndex];
  }

  int columnIndexAt(int localColumnIndex) {
    if (localColumnIndex < 0 || localColumnIndex >= columnIndexes.length) {
      return localColumnIndex;
    }
    return columnIndexes[localColumnIndex];
  }

  double columnWidthAt(int columnIndex, {required double fallbackWidth}) {
    if (columnIndex < 0 || columnIndex >= columnWidths.length) {
      return fallbackWidth;
    }
    return columnWidths[columnIndex];
  }

  double columnOffsetAt(int columnIndex, {required double fallbackWidth}) {
    if (columnIndex < 0) {
      return 0.0;
    }
    if (columnIndex < columnOffsets.length) {
      return columnOffsets[columnIndex];
    }
    if (columnIndex == columnOffsets.length) {
      return width;
    }
    return width + (columnIndex - columnOffsets.length) * fallbackWidth;
  }

  /// Returns a layout whose trailing normal column expands to [targetWidth].
  ///
  /// The runtime/configured column width is not mutated. This is a viewport
  /// layout projection used when a trailing pinned band would otherwise leave
  /// unused center space. UI-only action columns are never used as filler:
  /// their visual width must remain fixed even while adjacent columns resize.
  FdcGridColumnBandLayout stretchLastColumnToWidth(double targetWidth) {
    if (isEmpty || targetWidth <= width) {
      return this;
    }
    var stretchIndex = columns.length - 1;
    while (stretchIndex >= 0 && columns[stretchIndex] is FdcActionColumn) {
      stretchIndex--;
    }
    if (stretchIndex < 0) {
      return this;
    }
    final widths = List<double>.of(columnWidths);
    widths[stretchIndex] += targetWidth - width;
    return copyWithColumnWidths(widths, stretchesLastColumn: true);
  }

  FdcGridColumnBandLayout copyWithColumnWidths(
    List<double> widths, {
    bool? stretchesLastColumn,
  }) {
    final nextWidths = List<double>.unmodifiable(widths);
    final offsets = <double>[];
    final nextGeometries = <FdcGridColumnGeometry>[];
    var offset = 0.0;
    for (var index = 0; index < nextWidths.length; index++) {
      final width = nextWidths[index];
      offsets.add(offset);
      final geometry = index < geometries.length ? geometries[index] : null;
      if (geometry != null) {
        nextGeometries.add(geometry.copyWith(width: width, offset: offset));
      }
      offset += width;
    }
    return FdcGridColumnBandLayout(
      band: band,
      geometries: List<FdcGridColumnGeometry>.unmodifiable(nextGeometries),
      columnWidths: nextWidths,
      columnOffsets: List<double>.unmodifiable(offsets),
      width: offset,
      resizeTargetLocalColumnIndexes: resizeTargetLocalColumnIndexes,
      resizeTargetColumns: resizeTargetColumns,
      resizeTargetRuntimeColumnIds: resizeTargetRuntimeColumnIds,
      resizeTargetColumnIndexes: resizeTargetColumnIndexes,
      resizeDeltaFactors: resizeDeltaFactors,
      stretchesLastColumn: stretchesLastColumn ?? this.stretchesLastColumn,
    );
  }

  FdcGridColumnBandLayout _withResizeTargets() {
    if (isEmpty) {
      return this;
    }

    final localTargets = <int?>[];
    final targetColumns = <FdcGridColumn<dynamic>?>[];
    final targetRuntimeColumnIds = <FdcColumnIdentity?>[];
    final targetColumnIndexes = <int?>[];
    for (var index = 0; index < length; index++) {
      final column = columns[index];
      final resizable = column is! FdcActionColumn && column.allowResize;
      localTargets.add(resizable ? index : null);
      targetColumns.add(resizable ? column : null);
      targetRuntimeColumnIds.add(resizable ? runtimeColumnIds[index] : null);
      targetColumnIndexes.add(resizable ? columnIndexes[index] : null);
    }

    return FdcGridColumnBandLayout(
      band: band,
      geometries: geometries,
      columnWidths: columnWidths,
      columnOffsets: columnOffsets,
      width: width,
      resizeTargetLocalColumnIndexes: List<int?>.unmodifiable(localTargets),
      resizeTargetColumns: List<FdcGridColumn<dynamic>?>.unmodifiable(
        targetColumns,
      ),
      resizeTargetRuntimeColumnIds: List<FdcColumnIdentity?>.unmodifiable(
        targetRuntimeColumnIds,
      ),
      resizeTargetColumnIndexes: List<int?>.unmodifiable(targetColumnIndexes),
      resizeDeltaFactors: List<double>.unmodifiable(
        List<double>.filled(length, 1.0),
      ),
      stretchesLastColumn: stretchesLastColumn,
    );
  }

  FdcGridColumnBandLayout _withTrailingResizeTarget({
    required FdcGridColumn<dynamic> targetColumn,
    required FdcColumnIdentity targetRuntimeColumnId,
    required int targetColumnIndex,
    required double deltaFactor,
  }) {
    if (isEmpty) {
      return this;
    }

    final localTargets = List<int?>.of(resizeTargetLocalColumnIndexes);
    final targetColumns = List<FdcGridColumn<dynamic>?>.of(resizeTargetColumns);
    final targetRuntimeColumnIds = List<FdcColumnIdentity?>.of(
      resizeTargetRuntimeColumnIds,
    );
    final targetColumnIndexes = List<int?>.of(resizeTargetColumnIndexes);
    final factors = List<double>.of(resizeDeltaFactors);
    final trailingIndex = length - 1;
    localTargets[trailingIndex] = null;
    targetColumns[trailingIndex] = targetColumn;
    targetRuntimeColumnIds[trailingIndex] = targetRuntimeColumnId;
    targetColumnIndexes[trailingIndex] = targetColumnIndex;
    factors[trailingIndex] = deltaFactor;

    return FdcGridColumnBandLayout(
      band: band,
      geometries: geometries,
      columnWidths: columnWidths,
      columnOffsets: columnOffsets,
      width: width,
      resizeTargetLocalColumnIndexes: List<int?>.unmodifiable(localTargets),
      resizeTargetColumns: List<FdcGridColumn<dynamic>?>.unmodifiable(
        targetColumns,
      ),
      resizeTargetRuntimeColumnIds: List<FdcColumnIdentity?>.unmodifiable(
        targetRuntimeColumnIds,
      ),
      resizeTargetColumnIndexes: List<int?>.unmodifiable(targetColumnIndexes),
      resizeDeltaFactors: List<double>.unmodifiable(factors),
      stretchesLastColumn: stretchesLastColumn,
    );
  }

  FdcGridColumnBandLayout _withRightPinnedResizeTargets() {
    if (isEmpty) {
      return this;
    }

    final localTargets = <int?>[];
    final targetColumns = <FdcGridColumn<dynamic>?>[];
    final targetRuntimeColumnIds = <FdcColumnIdentity?>[];
    final targetColumnIndexes = <int?>[];
    final factors = <double>[];
    for (var index = 0; index < length; index++) {
      final nextPinnedIndex = index + 1;
      final hasNextPinned = nextPinnedIndex < length;
      final nextColumn = hasNextPinned ? columns[nextPinnedIndex] : null;
      final hasResizableNext =
          nextColumn != null &&
          nextColumn is! FdcActionColumn &&
          nextColumn.allowResize;
      localTargets.add(hasResizableNext ? nextPinnedIndex : null);
      targetColumns.add(hasResizableNext ? nextColumn : null);
      targetRuntimeColumnIds.add(
        hasResizableNext ? runtimeColumnIds[nextPinnedIndex] : null,
      );
      targetColumnIndexes.add(
        hasResizableNext ? columnIndexes[nextPinnedIndex] : null,
      );
      factors.add(-1.0);
    }

    return FdcGridColumnBandLayout(
      band: band,
      geometries: geometries,
      columnWidths: columnWidths,
      columnOffsets: columnOffsets,
      width: width,
      resizeTargetLocalColumnIndexes: List<int?>.unmodifiable(localTargets),
      resizeTargetColumns: List<FdcGridColumn<dynamic>?>.unmodifiable(
        targetColumns,
      ),
      resizeTargetRuntimeColumnIds: List<FdcColumnIdentity?>.unmodifiable(
        targetRuntimeColumnIds,
      ),
      resizeTargetColumnIndexes: List<int?>.unmodifiable(targetColumnIndexes),
      resizeDeltaFactors: List<double>.unmodifiable(factors),
      stretchesLastColumn: stretchesLastColumn,
    );
  }
}

class FdcGridColumnBandLayouts {
  const FdcGridColumnBandLayouts({
    required this.pinnedLeft,
    required this.scrollable,
    required this.pinnedRight,
  });

  factory FdcGridColumnBandLayouts.fromRuntimeSnapshot({
    required FdcGridRuntimeColumnMetricsSnapshot snapshot,
    required TextDirection textDirection,
  }) {
    final pinnedLeftMetrics = snapshot
        .visibleMetricsForPin(
          (pin) => textDirection == TextDirection.ltr ? pin.isStart : pin.isEnd,
        )
        .toList(growable: false);
    final scrollableMetrics = snapshot
        .visibleMetricsForPin((pin) => !pin.isStart && !pin.isEnd)
        .toList(growable: false);
    final pinnedRightMetrics = snapshot
        .visibleMetricsForPin(
          (pin) => textDirection == TextDirection.ltr ? pin.isEnd : pin.isStart,
        )
        .toList(growable: false);

    final pinnedLeft = FdcGridColumnBandLayout.fromRuntimeMetrics(
      metrics: pinnedLeftMetrics,
      columnSignature: _runtimeMetricsSignature(pinnedLeftMetrics),
    );
    final scrollable = FdcGridColumnBandLayout.fromRuntimeMetrics(
      metrics: scrollableMetrics,
      columnSignature: _runtimeMetricsSignature(scrollableMetrics),
    );
    final pinnedRight = FdcGridColumnBandLayout.fromRuntimeMetrics(
      metrics: pinnedRightMetrics,
      columnSignature: _runtimeMetricsSignature(pinnedRightMetrics),
    );

    final resolvedPinnedRight = pinnedRight._withRightPinnedResizeTargets();
    var resolvedScrollable = scrollable._withResizeTargets();
    final firstPinnedRightColumn = pinnedRight.isNotEmpty
        ? pinnedRight.columns.first
        : null;
    if (resolvedScrollable.isNotEmpty &&
        firstPinnedRightColumn != null &&
        firstPinnedRightColumn is! FdcActionColumn &&
        firstPinnedRightColumn.allowResize) {
      resolvedScrollable = resolvedScrollable._withTrailingResizeTarget(
        targetColumn: firstPinnedRightColumn,
        targetRuntimeColumnId: pinnedRight.runtimeColumnIds.first,
        targetColumnIndex: pinnedRight.columnIndexes.first,
        deltaFactor: -1.0,
      );
    }

    return FdcGridColumnBandLayouts(
      pinnedLeft: pinnedLeft._withResizeTargets(),
      scrollable: resolvedScrollable,
      pinnedRight: resolvedPinnedRight,
    );
  }

  factory FdcGridColumnBandLayouts.fromBands({
    required FdcGridColumnBands bands,
    required FdcGridColumnSizingManager columnSizing,
    required double defaultColumnWidth,
  }) {
    final pinnedLeft = FdcGridColumnBandLayout.fromBand(
      band: bands.pinnedLeft,
      columnSizing: columnSizing,
      defaultColumnWidth: defaultColumnWidth,
    );
    final scrollable = FdcGridColumnBandLayout.fromBand(
      band: bands.scrollable,
      columnSizing: columnSizing,
      defaultColumnWidth: defaultColumnWidth,
    );
    final pinnedRight = FdcGridColumnBandLayout.fromBand(
      band: bands.pinnedRight,
      columnSizing: columnSizing,
      defaultColumnWidth: defaultColumnWidth,
    );

    final resolvedPinnedRight = pinnedRight._withRightPinnedResizeTargets();
    var resolvedScrollable = scrollable._withResizeTargets();
    final firstPinnedRightColumn = pinnedRight.isNotEmpty
        ? pinnedRight.columns.first
        : null;
    if (resolvedScrollable.isNotEmpty &&
        firstPinnedRightColumn != null &&
        firstPinnedRightColumn is! FdcActionColumn &&
        firstPinnedRightColumn.allowResize) {
      resolvedScrollable = resolvedScrollable._withTrailingResizeTarget(
        targetColumn: firstPinnedRightColumn,
        targetRuntimeColumnId: pinnedRight.runtimeColumnIds.first,
        targetColumnIndex: pinnedRight.columnIndexes.first,
        deltaFactor: -1.0,
      );
    }

    return FdcGridColumnBandLayouts(
      pinnedLeft: pinnedLeft._withResizeTargets(),
      scrollable: resolvedScrollable,
      pinnedRight: resolvedPinnedRight,
    );
  }

  static String _runtimeMetricsSignature(
    List<FdcGridRuntimeColumnMetric> metrics,
  ) {
    if (metrics.isEmpty) {
      return '';
    }
    return metrics.map((metric) => metric.runtimeColumnId).join('|');
  }

  final FdcGridColumnBandLayout pinnedLeft;
  final FdcGridColumnBandLayout scrollable;
  final FdcGridColumnBandLayout pinnedRight;

  double get pinnedLeftWidth => pinnedLeft.width;
  double get scrollableWidth => scrollable.width;
  double get pinnedRightWidth => pinnedRight.width;
  double get totalDataWidth =>
      pinnedLeftWidth + scrollableWidth + pinnedRightWidth;
}

extension FdcGridColumnBandLayoutSummaryState on FdcGridColumnBandLayout {
  bool get lastColumnHasSummary {
    if (geometries.isEmpty) {
      return false;
    }
    return geometries.last.column.summary.aggregate != null;
  }
}

class FdcGridLayoutRegions {
  const FdcGridLayoutRegions({
    required this.rowIndicator,
    required this.rowIndicatorWidth,
    required this.pinnedLeftWidth,
    required this.scrollableDataWidth,
    required this.pinnedRightWidth,
  });

  factory FdcGridLayoutRegions.fromColumnBandLayouts({
    required FdcGridRowIndicatorLayout rowIndicator,
    required FdcGridColumnBandLayouts columnBandLayouts,
  }) {
    return FdcGridLayoutRegions(
      rowIndicator: rowIndicator,
      rowIndicatorWidth: rowIndicator.isVisible ? rowIndicator.width : 0.0,
      pinnedLeftWidth: columnBandLayouts.pinnedLeftWidth,
      scrollableDataWidth: math.max(0.0, columnBandLayouts.scrollableWidth),
      pinnedRightWidth: columnBandLayouts.pinnedRightWidth,
    );
  }

  final FdcGridRowIndicatorLayout rowIndicator;

  /// Width occupied by the always-leading row indicator region.
  ///
  /// The row indicator is intentionally separate from pinned data columns. The
  /// active grid layout is:
  ///
  /// Row indicator | Pinned left | Scrollable columns | Pinned right
  final double rowIndicatorWidth;

  /// Width occupied by data columns pinned to the leading side.
  final double pinnedLeftWidth;

  /// Width occupied by data columns inside the horizontal scroll area.
  final double scrollableDataWidth;

  /// Width occupied by data columns pinned to the trailing side.
  final double pinnedRightWidth;

  FdcGridRowIndicatorLayout? get rowIndicatorLayout =>
      rowIndicator.isVisible ? rowIndicator : null;

  double get leadingPinnedWidth => rowIndicatorWidth + pinnedLeftWidth;

  bool get hasRowIndicatorRegion => rowIndicatorWidth > 0;
  bool get hasPinnedLeftRegion => pinnedLeftWidth > 0;
  bool get hasPinnedRightRegion => pinnedRightWidth > 0;
}

enum FdcGridRowIndicatorStatus {
  /// Current row while the dataset is in browse state.
  browse,

  /// Current row while the dataset is in edit state with a clean edit buffer.
  edit,

  /// Current row while the dataset is in edit state after user changes.
  ///
  /// This is intentionally the active edit-buffer dirty state, not posted
  /// `FdcRecordState.modified`. It currently renders like `edit`.
  modified,

  /// Current row while the dataset is in insert state.
  insert,
}
