// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

/// Owns data-domain transient UI state for one grid instance.
///
/// The dataset remains the source of truth for records, filters, sorts, and
/// edits. This holder only groups short-lived UI/session guards used while the
/// grid drives dataset operations, confirmations, and validation/error dialogs.
class _FdcGridDataUiState {
  final _FdcGridDataOperationUiState operation = _FdcGridDataOperationUiState();
}
