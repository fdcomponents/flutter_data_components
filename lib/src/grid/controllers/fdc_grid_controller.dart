// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import '../models/fdc_grid_controller_feature.dart';
import '../models/fdc_grid_layout_snapshot.dart';

/// Public runtime command surface for an `FdcGrid`.
///
/// The controller is available in the Community package because it owns neutral
/// grid commands such as focusing columns, showing or hiding columns, clearing
/// filters, clearing sorting, and resetting the current grid layout. Pro
/// features can attach additional grid configuration and command extensions
/// through the grid widget rather than through this constructor.
class FdcGridController extends FdcGridControllerFeature {
  /// Creates a [FdcGridController].
  FdcGridController();

  /// Runs the function operation.
  FdcGridLayoutSnapshot Function()? _capture;

  /// Runs the function operation.
  void Function(FdcGridLayoutSnapshot snapshot)? _restore;

  /// Runs the function operation.
  void Function()? _reset;

  /// Runs the function operation.
  bool Function(String columnId)? _focusColumn;

  /// Runs the function operation.
  bool Function(String columnId, bool visible)? _setColumnVisible;

  /// Runs the function operation.
  Future<bool> Function()? _clearFilters;

  /// Runs the function operation.
  bool Function()? _showFilters;

  /// Runs the function operation.
  Future<bool> Function()? _hideFilters;

  /// Runs the function operation.
  Future<bool> Function()? _clearSorting;

  /// Runs the function operation.
  bool Function({int? rowIndex})? _expandDetailRow;

  /// Runs the function operation.
  bool Function({int? rowIndex})? _collapseDetailRow;

  /// Runs the function operation.
  bool Function()? _collapseAllDetailRows;

  /// Runs the function operation.
  bool Function()? _clearRangeSelection;

  /// Runs the function operation.
  Future<void> Function()? _saveLayoutCommand;

  /// Runs the function operation.
  Future<bool> Function()? _loadLayoutCommand;

  /// Runs the function operation.
  Future<void> Function()? _deleteLayoutCommand;

  /// Runs the function operation.
  void Function()? _layoutChangedCommand;
  bool _disposed = false;

  /// Whether this controller is currently attached to a live grid instance.
  bool get isAttached => _capture != null;

  FdcGridLayoutSnapshot _captureLayoutSnapshot() {
    final capture = _capture;
    if (capture == null) {
      throw StateError('FdcGridController is not attached to a grid.');
    }
    return capture();
  }

  void _restoreLayoutSnapshot(FdcGridLayoutSnapshot snapshot) {
    final restore = _restore;
    if (restore == null) {
      throw StateError('FdcGridController is not attached to a grid.');
    }
    restore(snapshot);
  }

  /// Restores the grid to its configured default layout and deletes any persisted snapshot.
  Future<void> resetLayout() async {
    final reset = _reset;
    if (reset == null) {
      throw StateError('FdcGridController is not attached to a grid.');
    }
    reset();
    await (_deleteLayoutCommand?.call() ?? Future<void>.value());
  }

  Future<void> _saveLayout() {
    return _saveLayoutCommand?.call() ?? Future<void>.value();
  }

  Future<bool> _loadLayout() {
    return _loadLayoutCommand?.call() ?? Future<bool>.value(false);
  }

  /// Moves grid focus to the column identified by [columnId].
  ///
  /// Returns `false` when the column cannot be focused in the current layout.
  bool focusColumn(String columnId) {
    return _requireAttached(_focusColumn).call(columnId);
  }

  /// Makes the column identified by [columnId] visible.
  ///
  /// Returns whether the visibility change was accepted.
  bool showColumn(String columnId) {
    return _requireAttached(_setColumnVisible).call(columnId, true);
  }

  /// Hides the column identified by [columnId].
  ///
  /// Returns whether the visibility change was accepted.
  bool hideColumn(String columnId) {
    return _requireAttached(_setColumnVisible).call(columnId, false);
  }

  /// Clears all grid-managed column filters and rebuilds the dataset view.
  ///
  /// Returns whether the operation completed successfully.
  Future<bool> clearFilters() {
    return _requireAttached(_clearFilters).call();
  }

  /// Shows the grid header filter row.
  ///
  /// Returns whether the visibility state changed.
  bool showFilters() {
    return _requireAttached(_showFilters).call();
  }

  /// Hides the header filter row, applying any required filter-state transition.
  ///
  /// Returns whether the operation completed successfully.
  Future<bool> hideFilters() {
    return _requireAttached(_hideFilters).call();
  }

  /// Clears grid-managed sorting and rebuilds the dataset view.
  ///
  /// Returns whether the operation completed successfully.
  Future<bool> clearSorting() {
    return _requireAttached(_clearSorting).call();
  }

  bool _expandDetailRowCommand({int? rowIndex}) {
    return _requireAttached(_expandDetailRow).call(rowIndex: rowIndex);
  }

  bool _collapseDetailRowCommand({int? rowIndex}) {
    return _requireAttached(_collapseDetailRow).call(rowIndex: rowIndex);
  }

  bool _collapseAllDetailRowsCommand() {
    return _requireAttached(_collapseAllDetailRows).call();
  }

  bool _clearRangeSelectionCommand() {
    return _requireAttached(_clearRangeSelection).call();
  }

  T _requireAttached<T extends Object>(T? callback) {
    if (callback == null) {
      throw StateError('FdcGridController is not attached to a grid.');
    }
    return callback;
  }

  @override
  void attach({
    required FdcGridLayoutSnapshot Function() capture,
    required void Function(FdcGridLayoutSnapshot snapshot) restore,
    required void Function() reset,
    required bool Function(String columnId) focusColumn,
    required bool Function(String columnId, bool visible) setColumnVisible,
    required Future<bool> Function() clearFilters,
    required bool Function() showFilters,
    required Future<bool> Function() hideFilters,
    required Future<bool> Function() clearSorting,
    required bool Function({int? rowIndex}) expandDetailRow,
    required bool Function({int? rowIndex}) collapseDetailRow,
    required bool Function() collapseAllDetailRows,
    required bool Function() clearRangeSelection,
    required Future<void> Function() saveLayout,
    required Future<bool> Function() loadLayout,
    required Future<void> Function() deleteLayout,
    required void Function() layoutChanged,
  }) {
    if (_disposed) {
      throw StateError('FdcGridController has been disposed.');
    }
    _capture = capture;
    _restore = restore;
    _reset = reset;
    _focusColumn = focusColumn;
    _setColumnVisible = setColumnVisible;
    _clearFilters = clearFilters;
    _showFilters = showFilters;
    _hideFilters = hideFilters;
    _clearSorting = clearSorting;
    _expandDetailRow = expandDetailRow;
    _collapseDetailRow = collapseDetailRow;
    _collapseAllDetailRows = collapseAllDetailRows;
    _clearRangeSelection = clearRangeSelection;
    _saveLayoutCommand = saveLayout;
    _loadLayoutCommand = loadLayout;
    _deleteLayoutCommand = deleteLayout;
    _layoutChangedCommand = layoutChanged;
  }

  @override
  void layoutChanged() {
    if (!isAttached || _disposed) {
      return;
    }
    _layoutChangedCommand?.call();
  }

  @override
  void detach() {
    _capture = null;
    _restore = null;
    _reset = null;
    _focusColumn = null;
    _setColumnVisible = null;
    _clearFilters = null;
    _showFilters = null;
    _hideFilters = null;
    _clearSorting = null;
    _expandDetailRow = null;
    _collapseDetailRow = null;
    _collapseAllDetailRows = null;
    _clearRangeSelection = null;
    _saveLayoutCommand = null;
    _loadLayoutCommand = null;
    _deleteLayoutCommand = null;
    _layoutChangedCommand = null;
  }

  /// Detaches this controller and prevents it from being attached again.
  void dispose() {
    if (_disposed) {
      return;
    }
    detach();
    _disposed = true;
  }
}

/// Extension-package access to controller layout internals.
///
/// This API is exported only through `fdc_ext.dart`. Application code should use
/// the high-level controller methods and Pro extensions instead.
abstract final class FdcGridControllerExtensionApi {
  const FdcGridControllerExtensionApi._();

  /// Captures the current layout state for extension packages.
  static FdcGridLayoutSnapshot captureLayoutSnapshot(
    FdcGridController controller,
  ) {
    return controller._captureLayoutSnapshot();
  }

  /// Restores a previously captured layout snapshot.
  static void restoreLayoutSnapshot(
    FdcGridController controller,
    FdcGridLayoutSnapshot snapshot,
  ) {
    controller._restoreLayoutSnapshot(snapshot);
  }

  /// Saves the controller layout through the configured persistence layer.
  static Future<void> saveLayout(FdcGridController controller) {
    return controller._saveLayout();
  }

  /// Loads a persisted layout, returning whether one was restored.
  static Future<bool> loadLayout(FdcGridController controller) {
    return controller._loadLayout();
  }

  /// Expands a detail row through the attached grid runtime.
  static bool expandDetailRow(FdcGridController controller, {int? rowIndex}) {
    return controller._expandDetailRowCommand(rowIndex: rowIndex);
  }

  /// Collapses a detail row through the attached grid runtime.
  static bool collapseDetailRow(FdcGridController controller, {int? rowIndex}) {
    return controller._collapseDetailRowCommand(rowIndex: rowIndex);
  }

  /// Collapses all expanded detail rows.
  static bool collapseAllDetailRows(FdcGridController controller) {
    return controller._collapseAllDetailRowsCommand();
  }

  /// Clears the active range selection.
  static bool clearRangeSelection(FdcGridController controller) {
    return controller._clearRangeSelectionCommand();
  }
}
