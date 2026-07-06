// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Groups transient header-filter UI state for a concrete grid instance.
///
/// This state is intentionally separate from `_FdcGridRuntimeController`:
/// controller services are durable runtime collaborators, while this class owns
/// short-lived filter UI values, focus nodes, debounce state, and refresh
/// generations that are tightly coupled to the current widget/state lifecycle.
class _FdcGridHeaderFilterUiState {
  final Map<FdcColumnIdentity, Object?> values = <FdcColumnIdentity, Object?>{};

  final Map<FdcColumnIdentity, FdcFilterOperator> operators =
      <FdcColumnIdentity, FdcFilterOperator>{};

  final Map<FdcColumnIdentity, _FdcGridHeaderFilterRangeEditSnapshot>
  rangeEditSnapshots =
      <FdcColumnIdentity, _FdcGridHeaderFilterRangeEditSnapshot>{};

  final Map<FdcColumnIdentity, FocusNode> focusNodes =
      <FdcColumnIdentity, FocusNode>{};

  Timer? debounceTimer;
  int refreshGeneration = 0;
  int resetGeneration = 0;
  int rangeAutoOpenGeneration = 0;
  FdcColumnIdentity? rangeAutoOpenRuntimeColumnId;
  bool? rowSelectionFilter;
  String? lastAppliedSignature;

  // Serializes async header-filter applies so rapid typing cannot overlap
  // adapter-backed page loads. New input while an apply is active is replayed
  // once, using the latest current filter signature.
  bool applyInFlight = false;
  bool applyQueued = false;
  String? inFlightSignature;

  bool showColumnFilters = false;

  void dispose() {
    debounceTimer?.cancel();
    debounceTimer = null;
    lastAppliedSignature = null;
    rangeAutoOpenRuntimeColumnId = null;
    rangeEditSnapshots.clear();
    applyInFlight = false;
    applyQueued = false;
    inFlightSignature = null;

    for (final focusNode in focusNodes.values) {
      focusNode.dispose();
    }
    focusNodes.clear();
  }
}

class _FdcGridHeaderFilterRangeEditSnapshot {
  const _FdcGridHeaderFilterRangeEditSnapshot({
    required this.hadValue,
    required this.value,
    required this.hadOperator,
    required this.operator,
  });

  final bool hadValue;
  final Object? value;
  final bool hadOperator;
  final FdcFilterOperator? operator;
}
