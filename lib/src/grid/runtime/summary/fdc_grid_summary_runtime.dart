// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridStateSummaryAggregates on _FdcGridState {
  bool get _showsSummaryRow {
    if (!widget.summary.visible) {
      return false;
    }

    for (var index = 0; index < _visibleColumnsCache.length; index++) {
      final column = _visibleColumnsCache[index];
      final runtimeColumnId = _visibleRuntimeColumnIdsCache[index];
      if (_effectiveSummaryAggregateForColumn(
            column,
            runtimeColumnId: runtimeColumnId,
          ) !=
          null) {
        return true;
      }
    }
    return false;
  }

  void _clearSummaryAggregateCache({bool clearDisplayedValues = false}) {
    _summaryAggregatePending.clear();
    _summaryAggregateLoadDeferred = false;
    _summaryAggregateValueCache.clear();
    _lastSummaryAggregateQuerySignature = null;
    if (clearDisplayedValues) {
      _summaryDisplayedValueCache.clear();
      _summaryDisplayedValueSemanticCache.clear();
    }
  }

  void _clearSummaryCacheIfQueryChanged() {
    if (!widget.dataSet.isOpen || !widget.dataSet.paging.enabled) {
      _clearSummaryAggregateCache();
      return;
    }

    final signature = FdcDataSetInternal.aggregateQuerySignature(
      widget.dataSet,
    );
    if (_lastSummaryAggregateQuerySignature == signature) {
      return;
    }

    _lastSummaryAggregateQuerySignature = signature;
    _clearSummaryAggregateCache();
    _lastSummaryAggregateQuerySignature = signature;
  }

  Map<FdcColumnIdentity, String> _summaryValuesForLayouts(
    FdcGridColumnBandLayouts layouts,
  ) {
    if (!_showsSummaryRow) {
      return const <FdcColumnIdentity, String>{};
    }
    if (widget.dataSet.isOpen && _rows.isEmpty) {
      if (!widget.dataSet.paging.enabled) {
        return const <FdcColumnIdentity, String>{};
      }

      // Adapter-backed paged datasets can briefly expose an empty page while a
      // master-detail or filter reload is moving through the dataset/grid
      // lifecycle. Do not blank the summary row in that transient window. Let
      // the paged summary path below either keep the last displayed value while
      // work is active/pending, or schedule a fresh aggregate request for the
      // new query signature once the dataset is idle.
    }

    final result = <FdcColumnIdentity, String>{};
    void addLayout(FdcGridColumnBandLayout layout) {
      for (final geometry in layout.geometries) {
        final value = _summaryValueForColumn(
          geometry.column,
          runtimeColumnId: geometry.runtimeColumnId,
        );
        if (value != null && value.isNotEmpty) {
          result[geometry.runtimeColumnId] = value;
        }
      }
    }

    addLayout(layouts.pinnedLeft);
    addLayout(layouts.scrollable);
    addLayout(layouts.pinnedRight);
    return Map<FdcColumnIdentity, String>.unmodifiable(result);
  }

  Map<FdcColumnIdentity, FdcAggregate?> _summaryAggregatesForLayouts(
    FdcGridColumnBandLayouts layouts,
  ) {
    if (!_showsSummaryRow) {
      return const <FdcColumnIdentity, FdcAggregate?>{};
    }

    final result = <FdcColumnIdentity, FdcAggregate?>{};
    void addLayout(FdcGridColumnBandLayout layout) {
      for (final geometry in layout.geometries) {
        result[geometry.runtimeColumnId] = _effectiveSummaryAggregateForColumn(
          geometry.column,
          runtimeColumnId: geometry.runtimeColumnId,
        );
      }
    }

    addLayout(layouts.pinnedLeft);
    addLayout(layouts.scrollable);
    addLayout(layouts.pinnedRight);
    return Map<FdcColumnIdentity, FdcAggregate?>.unmodifiable(result);
  }

  FdcAggregate? _effectiveSummaryAggregateForColumn(
    FdcGridColumn<dynamic> column, {
    required FdcColumnIdentity runtimeColumnId,
  }) {
    if (_runtimeSummaryAggregateOverrides.containsKey(runtimeColumnId)) {
      return _runtimeSummaryAggregateOverrides[runtimeColumnId];
    }
    return column.summary.aggregate;
  }

  void _setRuntimeSummaryAggregate(
    FdcColumnIdentity runtimeColumnId,
    FdcAggregate? aggregate,
  ) {
    _setGridState(() {
      _runtimeSummaryAggregateOverrides[runtimeColumnId] = aggregate;
      final fieldName = _fieldNameForRuntimeColumnId(runtimeColumnId);
      _summaryDisplayedValueCache.remove(runtimeColumnId);
      if (fieldName != null) {
        _summaryDisplayedValueSemanticCache.removeWhere(
          (key, _) => key.fieldName == fieldName,
        );
      }
      _summaryAggregateValueCache.removeWhere(
        (key, _) => key.fieldName == fieldName,
      );
    });
    _notifyGridLayoutChanged();
  }

  String? _fieldNameForRuntimeColumnId(FdcColumnIdentity runtimeColumnId) {
    final index = _visibleRuntimeColumnIdsCache.indexOf(runtimeColumnId);
    if (index < 0 || index >= _visibleColumnsCache.length) {
      return null;
    }
    return _visibleColumnsCache[index].fieldName;
  }

  String? _summaryValueForColumn(
    FdcGridColumn<dynamic> column, {
    required FdcColumnIdentity runtimeColumnId,
  }) {
    final aggregate = _effectiveSummaryAggregateForColumn(
      column,
      runtimeColumnId: runtimeColumnId,
    );
    if (aggregate == null) {
      return null;
    }
    if (!_supportsSummaryAggregate(column, aggregate)) {
      _warnUnsupportedSummaryAggregate(column, aggregate);
      return 'N/A';
    }

    if (!widget.dataSet.isOpen) {
      return _closedSummaryValueForColumn(
        column,
        aggregate: aggregate,
        runtimeColumnId: runtimeColumnId,
      );
    }

    if (widget.dataSet.paging.enabled) {
      return _pagedSummaryValueForColumn(
        column,
        aggregate: aggregate,
        runtimeColumnId: runtimeColumnId,
      );
    }

    final Object? value;
    try {
      value = FdcDataSetInternal.aggregate(
        widget.dataSet,
        column.fieldName,
        aggregate,
      );
    } on Object {
      return 'N/A';
    }

    if (value == null) {
      return '';
    }
    return _formatSummaryValue(
      column,
      value,
      aggregate: aggregate,
      runtimeColumnId: runtimeColumnId,
    );
  }

  String? _pagedSummaryValueForColumn(
    FdcGridColumn<dynamic> column, {
    required FdcAggregate aggregate,
    required FdcColumnIdentity runtimeColumnId,
  }) {
    final key = _FdcGridSummaryAggregateCacheKey(
      fieldName: column.fieldName,
      aggregate: aggregate,
      querySignature: FdcDataSetInternal.aggregateQuerySignature(
        widget.dataSet,
      ),
    );
    if (_summaryAggregateValueCache.containsKey(key)) {
      final value = _summaryAggregateValueCache[key];
      if (value == null) {
        return _lastDisplayedSummaryValue(
              column,
              aggregate: aggregate,
              runtimeColumnId: runtimeColumnId,
            ) ??
            '';
      }
      return _formatSummaryValue(
        column,
        value,
        aggregate: aggregate,
        runtimeColumnId: runtimeColumnId,
      );
    }

    if (_shouldDeferPagedSummaryAggregateLoad) {
      _summaryAggregateLoadDeferred = true;
      return _lastDisplayedSummaryValue(
            column,
            aggregate: aggregate,
            runtimeColumnId: runtimeColumnId,
          ) ??
          '';
    }

    _schedulePagedSummaryAggregateLoad(key);
    return _lastDisplayedSummaryValue(
          column,
          aggregate: aggregate,
          runtimeColumnId: runtimeColumnId,
        ) ??
        '';
  }

  bool get _shouldDeferPagedSummaryAggregateLoad {
    if (!widget.dataSet.isOpen || !widget.dataSet.paging.enabled) {
      return false;
    }
    return widget.dataSet.state == FdcDataSetState.loading ||
        widget.dataSet.work.isWorking;
  }

  void _schedulePagedSummaryAggregateLoad(
    _FdcGridSummaryAggregateCacheKey key,
  ) {
    if (_summaryAggregatePending.contains(key)) {
      return;
    }

    _summaryAggregatePending.add(key);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_summaryAggregatePending.contains(key)) {
        return;
      }
      if (!widget.dataSet.isOpen || !widget.dataSet.paging.enabled) {
        _summaryAggregatePending.remove(key);
        return;
      }
      final currentSignature = FdcDataSetInternal.aggregateQuerySignature(
        widget.dataSet,
      );
      if (key.querySignature != currentSignature) {
        _summaryAggregatePending.remove(key);
        return;
      }
      if (_shouldDeferPagedSummaryAggregateLoad) {
        _summaryAggregatePending.remove(key);
        _summaryAggregateLoadDeferred = true;
        return;
      }
      _startPagedSummaryAggregateLoad(key);
    });
  }

  void _startPagedSummaryAggregateLoad(_FdcGridSummaryAggregateCacheKey key) {
    unawaited(
      FdcDataSetInternal.aggregateQuery(widget.dataSet, <FdcDataAggregateItem>[
            FdcDataAggregateItem(
              fieldName: key.fieldName,
              aggregate: key.aggregate,
            ),
          ])
          .then((result) {
            if (!mounted) {
              return;
            }
            _applyGridState(() {
              _summaryAggregatePending.remove(key);
              _summaryAggregateValueCache[key] = result.valueFor(
                key.fieldName,
                key.aggregate,
              );
            });
          })
          .catchError((Object error) {
            if (!mounted) {
              return;
            }
            _applyGridState(() {
              _summaryAggregatePending.remove(key);
              _summaryAggregateValueCache[key] = null;
            });
            _warnPagedSummaryAggregateUnavailable(error);
          }),
    );
  }

  void _warnPagedSummaryAggregateUnavailable(Object error) {
    assert(() {
      final warningKey = 'paged-summary-aggregate-unavailable|$error';
      if (!_unsupportedSummaryAggregateWarnings.add(warningKey)) {
        return true;
      }
      debugPrint(
        '[FDC-META-WARNING] Paged summary aggregate is unavailable: $error',
      );
      return true;
    }());
  }

  bool _supportsSummaryAggregate(
    FdcGridColumn<dynamic> column,
    FdcAggregate aggregate,
  ) {
    return _availableSummaryAggregatesForColumn(column).contains(aggregate);
  }

  String _closedSummaryValueForColumn(
    FdcGridColumn<dynamic> column, {
    required FdcAggregate aggregate,
    required FdcColumnIdentity runtimeColumnId,
  }) {
    final dataType = _summaryDataTypeFor(column);
    if (dataType == FdcDataType.date ||
        dataType == FdcDataType.dateTime ||
        dataType == FdcDataType.time) {
      return '';
    }

    final Object value = switch (dataType) {
      FdcDataType.decimal => FdcDecimal.fromScaled(
        BigInt.zero,
        scale: _fieldMetadata(column.fieldName).decimalScale ?? 0,
      ),
      FdcDataType.integer => 0,
      _ => 0,
    };

    return _formatSummaryValue(
      column,
      value,
      aggregate: aggregate,
      runtimeColumnId: runtimeColumnId,
    );
  }

  List<FdcAggregate> _availableSummaryAggregatesForColumn(
    FdcGridColumn<dynamic> column,
  ) {
    final dataType = _summaryDataTypeFor(column);
    return switch (dataType) {
      FdcDataType.integer || FdcDataType.decimal => FdcAggregate.values,
      FdcDataType.date || FdcDataType.dateTime || FdcDataType.time =>
        const <FdcAggregate>[FdcAggregate.min, FdcAggregate.max],
      _ => const <FdcAggregate>[],
    };
  }

  FdcDataType _summaryDataTypeFor(FdcGridColumn<dynamic> column) {
    return column.dataType;
  }

  void _warnUnsupportedSummaryAggregate(
    FdcGridColumn<dynamic> column,
    FdcAggregate aggregate,
  ) {
    assert(() {
      final dataType = _summaryDataTypeFor(column);
      final warningKey =
          '${column.runtimeType}|${column.fieldName}|${dataType.name}|${aggregate.name}';
      if (!_unsupportedSummaryAggregateWarnings.add(warningKey)) {
        return true;
      }

      debugPrint(
        '[FDC-META-WARNING] Unsupported summary aggregate: '
        'column "${_columnLabel(column)}" '
        '(field "${column.fieldName}", type ${dataType.name}) uses '
        'FdcAggregate.${aggregate.name}. Summary cell will render N/A.',
      );
      return true;
    }());
  }

  String? _lastDisplayedSummaryValue(
    FdcGridColumn<dynamic> column, {
    required FdcAggregate aggregate,
    required FdcColumnIdentity runtimeColumnId,
  }) {
    return _summaryDisplayedValueCache[runtimeColumnId] ??
        _summaryDisplayedValueSemanticCache[_FdcGridSummaryDisplayCacheKey(
          fieldName: column.fieldName,
          aggregate: aggregate,
        )];
  }

  String _formatSummaryValue(
    FdcGridColumn<dynamic> column,
    Object value, {
    required FdcAggregate aggregate,
    required FdcColumnIdentity runtimeColumnId,
  }) {
    final dataType = _summaryDataTypeFor(column);
    final effectiveFormatSettings = column.formatSettings ?? _formatSettings;
    final String formatted;
    if (dataType == FdcDataType.integer && value is FdcDecimal) {
      final scale = aggregate == FdcAggregate.avg ? 2 : 0;
      final codec = FdcFieldValueCodec(
        settings: effectiveFormatSettings,
        translations: _translations,
      );
      final decimalText = codec.formatDecimal(
        value,
        forEditing: false,
        scale: scale,
      );
      formatted = codec.applyDisplayTextAffixes(column, decimalText);
    } else if (value is DateTime && dataType == FdcDataType.dateTime) {
      formatted = FdcDateFormat(
        effectiveFormatSettings.effectiveDateTimeFormat,
      ).formatDate(value);
    } else if (value is DateTime && dataType == FdcDataType.date) {
      formatted = FdcDateFormat(
        effectiveFormatSettings.dateFormat,
      ).formatDate(value);
    } else {
      formatted = _valueFormatter.format(
        column,
        value,
        runtimeColumnId: runtimeColumnId,
      );
    }

    _summaryDisplayedValueCache[runtimeColumnId] = formatted;
    _summaryDisplayedValueSemanticCache[_FdcGridSummaryDisplayCacheKey(
          fieldName: column.fieldName,
          aggregate: aggregate,
        )] =
        formatted;
    return formatted;
  }
}

final class _FdcGridSummaryDisplayCacheKey {
  const _FdcGridSummaryDisplayCacheKey({
    required this.fieldName,
    required this.aggregate,
  });

  final String fieldName;
  final FdcAggregate aggregate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FdcGridSummaryDisplayCacheKey &&
          other.fieldName == fieldName &&
          other.aggregate == aggregate;

  @override
  int get hashCode => Object.hash(fieldName, aggregate);
}

final class _FdcGridSummaryAggregateCacheKey {
  const _FdcGridSummaryAggregateCacheKey({
    required this.fieldName,
    required this.aggregate,
    required this.querySignature,
  });

  final String fieldName;
  final FdcAggregate aggregate;
  final String querySignature;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FdcGridSummaryAggregateCacheKey &&
          other.fieldName == fieldName &&
          other.aggregate == aggregate &&
          other.querySignature == querySignature;

  @override
  int get hashCode => Object.hash(fieldName, aggregate, querySignature);
}
