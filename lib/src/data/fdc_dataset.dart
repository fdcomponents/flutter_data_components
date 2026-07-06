// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../common/fdc_aggregate.dart';
import '../common/format/fdc_format_settings.dart';
import '../i18n/fdc_translations.dart';
import 'adapters/memory/fdc_memory_data_adapter.dart';
import 'aggregation/fdc_dataset_aggregator.dart';
import 'fdc_change_set.dart';
import 'fdc_data_adapter.dart';
import 'fdc_data_errors.dart';
import 'fdc_data_paging.dart';
import 'fdc_data_type.dart';
import 'fdc_data_validation.dart';
import 'fdc_dataset_change_set_builder.dart';
import 'fdc_dataset_error_controller.dart';
import 'fdc_dataset_error_store.dart';
import 'fdc_dataset_field_writer.dart';
import 'fdc_dataset_filter.dart';
import 'fdc_dataset_search.dart';
import 'fdc_dataset_state.dart';
import 'fdc_dataset_view_controller.dart';
import 'fdc_dataset_work.dart';
import 'fdc_field.dart';
import 'fdc_field_def.dart';
import 'fdc_field_name.dart';
import 'fdc_field_value_normalizer.dart';
import 'fdc_filter_operator.dart';
import 'fdc_record.dart';
import 'fdc_record_store.dart';
import 'filtering/fdc_dataset_filter_change.dart';
import 'filtering/fdc_dataset_filter_controller.dart';
import 'internal/fdc_dataset_aggregate_coordinator.dart';
import 'internal/fdc_dataset_apply_coordinator.dart';
import 'internal/fdc_dataset_cursor_coordinator.dart';
import 'internal/fdc_dataset_edit_coordinator.dart';
import 'internal/fdc_dataset_lifecycle_coordinator.dart';
import 'internal/fdc_dataset_paging_coordinator.dart';
import 'internal/fdc_dataset_query_coordinator.dart';
import 'internal/fdc_dataset_record_view_coordinator.dart';
import 'internal/fdc_dataset_schema_coordinator.dart';
import 'internal/fdc_dataset_selection_coordinator.dart';
import 'internal/fdc_dataset_work_coordinator.dart';
import 'sorting/fdc_dataset_sort_controller.dart';
import 'types/fdc_decimal.dart';

/// An immutable position marker for a record in an [FdcDataSet].
///
/// Bookmarks are scoped to the dataset instance that created them. They are
/// transient runtime objects: they are not serializable and cannot be used to
/// position another dataset instance.
@immutable
final class FdcDataSetBookmark {
  const FdcDataSetBookmark._({
    required Object dataSetIdentity,
    required int recordId,
    required int recordIndex,
  }) : _dataSetIdentity = dataSetIdentity,
       _recordId = recordId,
       _recordIndex = recordIndex;

  final Object _dataSetIdentity;
  final int _recordId;
  final int _recordIndex;
}

/// Read-only message view over the current [FdcDataSet] errors.
///
/// Exposes error text through a compact count/index API without leaking the
/// internal error store into the dataset root API.
final class FdcDataSetErrorMessagesApi {
  FdcDataSetErrorMessagesApi._(this._dataSet);

  final FdcDataSet _dataSet;

  /// Number of current error messages.
  int get count => _dataSet._errorStore.length;

  /// True when there are no current error messages.
  bool get isEmpty => _dataSet._errorStore.isEmpty;

  /// True when at least one error message is available.
  bool get isNotEmpty => _dataSet._errorStore.isNotEmpty;

  /// Returns the error message at [index].
  ///
  /// Uses the same zero-based bounds semantics as normal Dart indexed access.
  String operator [](int index) =>
      _dataSet._errorStore.unmodifiable[index].message;
}

/// Public error-message facade for [FdcDataSet].
///
/// Error clearing remains controlled by dataset lifecycle/edit/apply operations;
///
/// this API is intentionally read-only.
final class FdcDataSetErrorsApi {
  FdcDataSetErrorsApi._(FdcDataSet dataSet)
    : _dataSet = dataSet,

      /// User-facing message texts.
      messages = FdcDataSetErrorMessagesApi._(dataSet);

  final FdcDataSet _dataSet;

  /// Indexed read-only access to individual error messages.
  final FdcDataSetErrorMessagesApi messages;

  /// Combined user-facing dataset error message.
  ///
  /// Returns an empty string when there are no errors. Multiple messages are
  /// joined with newlines.
  String get message =>
      _dataSet._errorStore.isEmpty ? '' : _dataSet._errorStore.message;

  /// Returns the error message for [fieldName] on [recordId].
  ///
  /// When [recordId] is omitted, the current dataset record is used. Returns
  /// null when there is no current record or no field-level message.
  String? messageForField(String fieldName, {int? recordId}) {
    final resolvedRecordId = recordId ?? _dataSet._currentRecordRaw?.id;
    if (resolvedRecordId == null) {
      return null;
    }
    return _dataSet._errorStore.messageForField(
      fieldName,
      recordId: resolvedRecordId,
    );
  }
}

/// Public bookmark facade for [FdcDataSet].
///
/// Keeps transient cursor bookmarks out of the dataset root API while preserving
/// clear, page-independent record-position semantics.
final class FdcDataSetBookmarksApi {
  FdcDataSetBookmarksApi._(this._dataSet);

  final FdcDataSet _dataSet;

  /// Creates a transient bookmark for the current visible record.
  ///
  /// Returns null when the dataset is closed, empty, or has no current record.
  /// The bookmark is valid only for this dataset instance.
  FdcDataSetBookmark? create() => _dataSet._createBookmark();

  /// Restores the current record from [bookmark].
  ///
  /// Returns true only when the original bookmarked record is still present in
  /// the active view. A bookmark created by another dataset instance is
  /// rejected and returns false.
  ///
  /// When [fallbackToNearest] is true and the original record is no longer
  /// visible, the cursor moves to the nearest valid position based on the
  /// bookmark's former index. That fallback move still returns false because
  /// the original record was not restored.
  bool restore(FdcDataSetBookmark bookmark, {bool fallbackToNearest = false}) =>
      _dataSet._restoreBookmark(bookmark, fallbackToNearest: fallbackToNearest);
}

/// Public aggregate facade for [FdcDataSet].
///
/// Keeps aggregate calculations out of the dataset root API while preserving
/// short, explicit aggregate method names inside the aggregate namespace.
final class FdcDataSetAggregatesApi {
  FdcDataSetAggregatesApi._(this._dataSet);

  final FdcDataSet _dataSet;

  /// Counts records in the current flat dataset view.
  int count() => _dataSet._aggregator().count();

  /// Sums a numeric field over the current flat dataset view.
  ///
  /// Null values are skipped. Empty views and all-null fields return
  /// [FdcDecimal.zero]. Integer and decimal fields are accumulated as
  /// [FdcDecimal] to avoid floating-point drift.
  FdcDecimal sum(String fieldName) =>
      _dataSet._aggregateCached(fieldName, FdcAggregate.sum) as FdcDecimal;

  /// Calculates the average for a numeric field over the current flat dataset
  /// view.
  ///
  /// Null values are skipped. Returns `null` when the current view contains no
  /// non-null values for [fieldName].
  FdcDecimal? avg(String fieldName) =>
      _dataSet._aggregateCached(fieldName, FdcAggregate.avg) as FdcDecimal?;

  /// Returns the minimum non-null field value over the current flat dataset
  /// view, or `null` when no value is available.
  Object? min(String fieldName) =>
      _dataSet._aggregateCached(fieldName, FdcAggregate.min);

  /// Returns the maximum non-null field value over the current flat dataset
  /// view, or `null` when no value is available.
  Object? max(String fieldName) =>
      _dataSet._aggregateCached(fieldName, FdcAggregate.max);

  /// Calculates adapter/query aggregates for the current logical dataset result.
  ///
  /// In non-paged/local mode this uses the normal local aggregate path over the
  /// current filtered view. In paged adapter mode, the adapter must calculate
  /// aggregates over the full matching result set without LIMIT/OFFSET.
  Future<FdcDataAggregateResult> calculate(
    List<FdcDataAggregateItem> aggregates,
  ) => _dataSet._aggregateQuery(aggregates);
}

/// Public paging facade for [FdcDataSet].
///
/// Keeps page navigation and page state out of the dataset root API while
/// preserving [FdcDataSet] as the single object owned by application code.
final class FdcDataSetPagingApi {
  FdcDataSetPagingApi._(this._dataSet);

  final FdcDataSet _dataSet;

  /// True when adapter-driven paging is enabled for the dataset.
  bool get enabled => _dataSet._paging.enabled;

  /// Active paging mode.
  FdcDataPagingMode get mode => _dataSet._paging.mode;

  /// True when standard page replacement or infinite page loading is enabled.
  bool get isPaged => _dataSet._paging.enabled;

  /// True when the dataset appends subsequent pages instead of replacing rows.
  bool get isInfinite =>
      _dataSet._paging.enabled && _dataSet._paging.usesInfinitePaging;

  /// Scroll threshold used by infinite paging hosts.
  double get infiniteLoadThreshold => _dataSet._paging.infiniteLoadThreshold;

  /// Zero-based active page index. With infinite paging this is the last
  /// successfully loaded page index.
  int get pageIndex => _dataSet._pagingCoordinator.pageIndex;

  /// Number of rows requested per page.
  int get pageSize => _dataSet._pagingCoordinator.pageSize;

  /// Zero-based adapter offset for the active page.
  int get pageOffset => _dataSet._pagingCoordinator.pageOffset;

  /// Total record count reported by the adapter for the active query, if known.
  int? get totalRecordCount => _dataSet._pagingCoordinator.totalRecordCount;

  /// Number of records represented by the loaded page set. With infinite paging
  /// enabled this is the number of rows currently retained by the dataset.
  int get pageRecordCount => _dataSet.recordCount;

  /// Total page count for the active query, or null when the adapter did not
  /// report a total count.
  int? get pageCount => _dataSet._pagingCoordinator.pageCount;

  /// True when paging is enabled and the active page is not the first page.
  ///
  /// This is always `false` when paging is disabled or the dataset is closed. In
  /// infinite paging mode it refers to the last successfully loaded page index,
  /// even though earlier pages remain retained in the dataset.
  bool get hasPriorPage => _dataSet._pagingCoordinator.hasPreviousPage;

  /// True when another page can be requested for the active query.
  ///
  /// This is `false` when paging is disabled or the dataset is closed. When the
  /// adapter reports a total count, the value is derived from the current page
  /// and total page count. If
  /// the total is unknown, a full last load is treated as evidence that another
  /// page may exist; a short load means the end has been reached. The same rule
  /// drives incremental loading in infinite paging mode.
  bool get hasNextPage => _dataSet._pagingCoordinator.hasNextPage;

  /// True while an infinite-paging next-page request is in flight.
  ///
  /// The flag covers the shared in-flight request used to coalesce concurrent
  /// next-page loads and returns to `false` when that request completes or
  /// fails. It remains `false` when no incremental next-page load is running and
  /// is reset to `false` when the dataset closes.
  bool get isLoadingNextPage => _dataSet._pagingCoordinator.isLoadingNextPage;

  /// Opens an arbitrary page by zero-based index.
  Future<void> openPage(
    int pageIndex, {
    int? pageSize,
    FdcDataLoadRequest request = const FdcDataLoadRequest(),
  }) => _dataSet._pagingCoordinator.openPage(
    pageIndex: pageIndex,
    pageSize: pageSize,
    request: request,
  );

  /// Loads the first page of the active adapter query.
  Future<void> firstPage() => _dataSet._pagingCoordinator.firstPage();

  /// Loads the page immediately before the active page.
  Future<void> priorPage() => _dataSet._pagingCoordinator.previousPage();

  /// Loads the page immediately after the active page.
  Future<void> nextPage() => _dataSet._pagingCoordinator.nextPage();

  /// Loads the last page when the adapter reported a total count.
  Future<void> lastPage() => _dataSet._pagingCoordinator.lastPage();

  /// Reloads paging data using [mode].
  ///
  /// [FdcPageRefreshMode.keepPage] reloads the current page index, while
  /// [FdcPageRefreshMode.firstPage] restarts the query from page zero.
  Future<void> refreshPage({
    FdcPageRefreshMode mode = FdcPageRefreshMode.keepPage,
  }) => _dataSet._pagingCoordinator.refreshPage(mode: mode);

  /// Changes the page size and reloads from the first page.
  ///
  /// Throws when paging is disabled or [pageSize] violates the configured paging
  /// bounds.
  Future<void> setPageSize(int pageSize) =>
      _dataSet._pagingCoordinator.setPageSize(pageSize);

  /// Loads the next page in infinite paging mode.
  ///
  /// Use [nextPage] when the caller does not care whether the dataset uses standard
  /// or infinite paging. Use [loadNextPage] for infinite-specific UI code.
  Future<void> loadNextPage() {
    if (!isInfinite) {
      throw StateError(
        'FdcDataSet.paging.loadNextPage() requires infinite paging mode.',
      );
    }
    return _dataSet._pagingCoordinator.nextPage();
  }
}

/// Public row-selection facade for [FdcDataSet].
///
/// Keeps row selection operations out of the dataset root API while preserving
/// [FdcDataSet] as the single object owned by application code.
final class FdcDataSetSelectionApi {
  FdcDataSetSelectionApi._(this._dataSet);

  final FdcDataSet _dataSet;

  /// Number of selected rows in the current dataset view.
  int get count => _dataSet._selectionCoordinator.selectedCount;

  /// Returns whether no rows are selected in the current dataset view.
  bool get isEmpty => count == 0;

  /// Returns whether at least one row is selected in the current dataset view.
  bool get isNotEmpty => count > 0;

  /// Returns whether the row at [rowIndex] is selected.
  ///
  /// [rowIndex] is zero-based and refers to the current dataset view, after
  /// filtering and sorting. This matches normal dataset navigation semantics.
  bool isSelectedAt(int rowIndex) =>
      _dataSet._selectionCoordinator.isSelectedAt(rowIndex);

  /// Sets the selection state of the row at [rowIndex].
  ///
  /// [rowIndex] is zero-based and refers to the current dataset view, after
  /// filtering and sorting. Selection changes repaint bound controls but do not
  /// mark data as modified.
  void setSelectedAt(int rowIndex, bool selected) {
    if (_dataSet._selectionCoordinator.setSelectedAt(rowIndex, selected)) {
      _dataSet._invalidateAdapterAggregateCacheAfterSelectionChange();
      _dataSet.notifyListeners();
    }
  }

  /// Toggles the selection state of the row at [rowIndex].
  ///
  /// Returns the new selection value.
  bool toggleAt(int rowIndex) {
    final selected = !isSelectedAt(rowIndex);
    setSelectedAt(rowIndex, selected);
    return selected;
  }

  /// Selects the current dataset record.
  void selectCurrent() => _setCurrentSelected(true);

  /// Clears selection on the current dataset record.
  void unselectCurrent() => _setCurrentSelected(false);

  /// Toggles the current dataset record selection state.
  ///
  /// Returns the new selection value.
  bool toggleCurrent() {
    _ensureCurrentRecordForSelection();
    return toggleAt(_dataSet._cursorCoordinator.currentIndex);
  }

  /// Selects every row in the current dataset view.
  void selectAll() {
    if (_dataSet._selectionCoordinator.setAllVisible(true)) {
      _dataSet._invalidateAdapterAggregateCacheAfterSelectionChange();
      _dataSet.notifyListeners();
    }
  }

  /// Clears selection for every row in the current dataset view.
  void unselectAll() {
    if (_dataSet._selectionCoordinator.setAllVisible(false)) {
      _dataSet._invalidateAdapterAggregateCacheAfterSelectionChange();
      _dataSet.notifyListeners();
    }
  }

  /// Maps selected rows from the current dataset view to immutable row values.
  ///
  /// This intentionally returns value snapshots instead of internal records so
  /// application code can use selected rows for export and batch actions without
  /// mutating dataset internals. Like normal dataset navigation, this method is
  /// view-scoped and respects the current filter/sort view.
  List<Map<String, Object?>> rows({bool includeNonPersistent = false}) {
    return _dataSet._selectionCoordinator.selectedRows(
      includeNonPersistent: includeNonPersistent,
    );
  }

  void _setCurrentSelected(bool selected) {
    _ensureCurrentRecordForSelection();
    setSelectedAt(_dataSet._cursorCoordinator.currentIndex, selected);
  }

  void _ensureCurrentRecordForSelection() {
    if (_dataSet.recordCount == 0 ||
        _dataSet._cursorCoordinator.currentIndex < 0) {
      throw StateError('Dataset has no current record.');
    }
  }
}

/// Called immediately before an open or reload operation begins.
///
/// At this point the existing dataset state has not yet been replaced by the
/// incoming rows. Throw [FdcDataSetAbortException] to veto the operation through
/// the normal dataset abort pipeline; other exceptions follow normal dataset
/// error handling.
typedef FdcDataSetBeforeOpen = void Function(FdcDataSet dataSet);

/// Called after an open operation has committed rows and entered browse state.
///
/// The dataset can be inspected or navigated from this callback. It is a
/// post-commit notification, so throwing does not roll the successful open back.
typedef FdcDataSetAfterOpen = void Function(FdcDataSet dataSet);

/// Called immediately before a dataset is closed and its current view is cleared.
///
/// Throw [FdcDataSetAbortException] to keep the dataset open and stop the close
/// operation through the normal abort pipeline.
typedef FdcDataSetBeforeClose = void Function(FdcDataSet dataSet);

/// Called after records, query state, selection, paging state, and edit buffers
/// have been cleared and the dataset has entered the closed state.
///
/// This callback is notification-only with respect to the completed close;
/// throwing does not restore the previous dataset contents.
typedef FdcDataSetAfterClose = void Function(FdcDataSet dataSet);

/// Called before the current record enters edit state and before an edit buffer
/// is created.
///
/// Throw [FdcDataSetAbortException] to veto editing. Application code may inspect
/// the current record here, but should not start a competing dataset operation.
typedef FdcDataSetBeforeEdit = void Function(FdcDataSet dataSet);

/// Called after the edit buffer has been created and the dataset entered edit
/// state, before listeners are notified.
///
/// Use this as a notification hook; mutations that belong to the edit should use
/// normal field assignment APIs against the active edit buffer.
typedef FdcDataSetAfterEdit = void Function(FdcDataSet dataSet);

/// Called before an inserted record is added to the record store or activated.
///
/// Throw [FdcDataSetAbortException] to veto the insert. Defaults have not yet been
/// applied when this callback runs.
typedef FdcDataSetBeforeInsert = void Function(FdcDataSet dataSet);

/// Called after the new record has been inserted, activated, initialized with
/// defaults, and placed in the current view, before listeners are notified.
///
/// The dataset is already in insert state and field changes made through normal
/// dataset APIs become part of that insert buffer. If this callback throws, the
/// in-progress insert operation rolls the newly inserted record back.
typedef FdcDataSetAfterInsert = void Function(FdcDataSet dataSet);

/// Called before calculated values and validation are run for the active edit.
///
/// This is the supported veto point for posting: throw
/// [FdcDataSetAbortException] to leave the dataset in its current edit/insert
/// state. Field values may be adjusted through normal dataset APIs before
/// validation continues.
typedef FdcDataSetBeforePost = void Function(FdcDataSet dataSet);

/// Called after posted values have been applied to the record and the dataset
/// has returned to browse state, before listeners are notified.
///
/// For adapter-backed datasets, transport may still be scheduled or pending
/// according to the update mode. This is not a rollback hook.
typedef FdcDataSetAfterPost = void Function(FdcDataSet dataSet);

/// Called before an existing record is removed or marked deleted.
///
/// Throw [FdcDataSetAbortException] to veto deletion. An unposted insert that is
/// deleted is discarded directly and does not fire delete callbacks.
typedef FdcDataSetBeforeDelete = void Function(FdcDataSet dataSet);

/// Called after an existing record has been removed or marked deleted and the
/// dataset has returned to browse state, before listeners are notified.
///
/// Adapter apply may still be scheduled according to the update mode; this
/// callback observes the local delete transition after it has happened.
typedef FdcDataSetAfterDelete = void Function(FdcDataSet dataSet);

/// Called before an active edit or insert buffer is discarded.
///
/// Throw [FdcDataSetAbortException] to veto cancel and keep the active edit.
typedef FdcDataSetBeforeCancel = void Function(FdcDataSet dataSet);

/// Called after original values have been restored, or an unposted insert has
/// been discarded, and the dataset has returned to browse state.
///
/// This callback observes the completed cancel transition and is not a rollback
/// point.
typedef FdcDataSetAfterCancel = void Function(FdcDataSet dataSet);

/// Called synchronously whenever the dataset state value changes.
///
/// [previousState] is the state being left and [currentState] is already the
/// dataset's active state when the callback runs. Because this callback runs
/// inside lifecycle transitions, avoid starting re-entrant lifecycle operations.
typedef FdcDataSetStateChanged =
    void Function(
      FdcDataSet dataSet,
      FdcDataSetState previousState,
      FdcDataSetState currentState,
    );

/// Called after post validation has produced one or more validation errors.
///
/// The supplied list describes the failed post attempt and the dataset error
/// store has already been updated when the callback runs. The active edit remains
/// available for correction.
typedef FdcDataSetValidationError =
    void Function(FdcDataSet dataSet, List<FdcValidationError> errors);

/// Called whenever the dataset records one or more user-visible errors.
///
/// Silent [FdcDataSetAbortException] instances do not raise this event because
/// they intentionally do not produce dataset errors. The callback is invoked
/// after [errors] has already been stored in [FdcDataSet.errors].
typedef FdcDataSetErrorEvent =
    void Function(
      FdcDataSet dataSet,
      List<FdcDataSetError> errors,
      Object? cause,
    );

/// Called when a dataset work operation starts.
typedef FdcDataSetWorkStarted =
    void Function(FdcDataSet dataSet, FdcDataSetWorkInfo work);

/// Called when a dataset work operation completes successfully.
typedef FdcDataSetWorkCompleted =
    void Function(FdcDataSet dataSet, FdcDataSetWorkInfo work);

/// Called when a dataset work operation fails.
typedef FdcDataSetWorkError =
    void Function(
      FdcDataSet dataSet,
      FdcDataSetWorkInfo work,
      Object error,
      StackTrace stackTrace,
    );

/// Called after a field value changes in the active edit buffer or through a
/// direct field-level update operation.
///
/// This is a notification event only. It does not participate in the dataset
/// abort/error lifecycle. If the handler changes another field, that nested
/// change will raise its own [FdcDataSetFieldChanged] notification.
typedef FdcDataSetFieldChanged =
    void Function(
      FdcDataSet dataSet,
      FdcFieldDef field,
      Object? oldValue,
      Object? newValue,
    );

/// Called after a newly inserted record has been created, added to the dataset
/// and placed in an active insert edit buffer.
///
/// Use this event to populate programmatic defaults with `setFieldValue`. The
/// event runs before [FdcDataSetAfterInsert], so defaults are part of the insert
/// buffer from the start of the user's edit session.
typedef FdcDataSetNewRecord = void Function(FdcDataSet dataSet);

/// Called before the dataset current record changes through navigation.
///
/// [currentRecordNumber] and [targetRecordNumber] are 1-based visible record
/// numbers. They are -1 when the dataset has no active record. Throw
/// [FdcDataSetAbortException] to block scrolling.
typedef FdcDataSetBeforeScroll =
    void Function(
      FdcDataSet dataSet,
      int currentRecordNumber,
      int targetRecordNumber,
    );

/// Called after the dataset current record changes through navigation.
///
/// [previousRecordNumber] and [currentRecordNumber] are 1-based visible record
/// numbers. They are -1 when the dataset has no active record.
typedef FdcDataSetAfterScroll =
    void Function(
      FdcDataSet dataSet,
      int previousRecordNumber,
      int currentRecordNumber,
    );

/// Flutter-friendly in-memory dataset with typed schema metadata, edit
/// lifecycle management, validation, filtering, sorting and cached updates.
///
/// [FdcDataSet] extends `ChangeNotifier`, so low-level Flutter UI code may use
/// `addListener` / `removeListener` for coarse-grained repaint notifications.
/// Business logic should prefer the typed lifecycle callbacks such as
/// `beforePost`, `afterPost`, `onFieldChanged`, `onValidationError` and
/// `onError`, because a plain listener does not describe what changed.
class FdcDataSet extends ChangeNotifier {
  /// Creates a dataset.
  ///
  /// [updateMode] defaults to [FdcUpdateMode.immediate]. Pass
  /// [FdcUpdateMode.cachedUpdates] only when the dataset should buffer changes
  /// until an explicit [applyUpdates] call.
  // ignore: sort_constructors_first
  FdcDataSet({
    List<FdcFieldDef> fields = const <FdcFieldDef>[],
    IFdcDataAdapter? adapter,
    FdcUpdateMode updateMode = FdcUpdateMode.immediate,
    FdcRecordValidator? recordValidator,
    FdcDataSetBeforeOpen? beforeOpen,
    FdcDataSetAfterOpen? afterOpen,
    FdcDataSetBeforeClose? beforeClose,
    FdcDataSetAfterClose? afterClose,
    FdcDataSetBeforeEdit? beforeEdit,
    FdcDataSetAfterEdit? afterEdit,
    FdcDataSetBeforeInsert? beforeInsert,
    FdcDataSetAfterInsert? afterInsert,
    FdcDataSetBeforePost? beforePost,
    FdcDataSetAfterPost? afterPost,
    FdcDataSetBeforeDelete? beforeDelete,
    FdcDataSetAfterDelete? afterDelete,
    FdcDataSetBeforeCancel? beforeCancel,
    FdcDataSetAfterCancel? afterCancel,
    FdcDataSetStateChanged? onStateChanged,
    FdcDataSetValidationError? onValidationError,
    FdcDataSetErrorEvent? onError,
    FdcDataSetWorkStarted? onWorkStarted,
    FdcDataSetWorkCompleted? onWorkCompleted,
    FdcDataSetWorkError? onWorkError,
    FdcDataSetFieldChanged? onFieldChanged,
    FdcDataSetNewRecord? onNewRecord,
    FdcDataSetBeforeScroll? beforeScroll,
    FdcDataSetAfterScroll? afterScroll,
    FdcDataSetOperationOptions operationOptions =
        const FdcDataSetOperationOptions(),
    FdcDataPagingOptions paging = const FdcDataPagingOptions.disabled(),
    FdcFormatSettings? formatSettings,
    FdcValidationTranslations validationTranslations =
        const FdcValidationTranslations(),
  }) : _adapter = adapter,
       _paging = paging,
       _updateMode = updateMode,
       _recordValidator = recordValidator,
       _beforeOpen = beforeOpen,
       _afterOpen = afterOpen,
       _beforeClose = beforeClose,
       _afterClose = afterClose,
       _beforeEdit = beforeEdit,
       _afterEdit = afterEdit,
       _beforeInsert = beforeInsert,
       _afterInsert = afterInsert,
       _beforePost = beforePost,
       _afterPost = afterPost,
       _beforeDelete = beforeDelete,
       _afterDelete = afterDelete,
       _beforeCancel = beforeCancel,
       _afterCancel = afterCancel,
       _onStateChanged = onStateChanged,
       _onValidationError = onValidationError,
       _onError = onError,
       _onWorkStarted = onWorkStarted,
       _onWorkCompleted = onWorkCompleted,
       _onWorkError = onWorkError,
       _onFieldChanged = onFieldChanged,
       _onNewRecord = onNewRecord,
       _beforeScroll = beforeScroll,
       _afterScroll = afterScroll {
    paging.validate();
    _view.operationOptions = operationOptions;
    if (formatSettings != null) {
      _view.filterContext = _view.filterContext.copyWith(
        formatSettings: formatSettings,
      );
    }
    _schemaCoordinator = FdcDataSetSchemaCoordinator(
      recordValidator: _recordValidator,
      ownerDescription: runtimeType.toString(),
      validationTranslations: validationTranslations,
      invalidateComparableCacheForField: _invalidateComparableCacheForField,
    );
    _schemaCoordinator.configure(fields);
    _lifecycleCoordinator = FdcDataSetLifecycleCoordinator(
      openCore: _openCore,
      openFutureCore: _openFutureCore,
      loadRowsCore: _loadRowsCore,
      loadRowsFutureCore: _loadRowsFutureCore,
      closeCore: _closeCore,
    );
    _workCoordinator = FdcDataSetWorkCoordinator(
      captureLifecycleGeneration: _lifecycleCoordinator.captureGeneration,
      isLifecycleCurrent: _isLifecycleCurrent,
      onStarted: (work) => _onWorkStarted?.call(this, work),
      onCompleted: (work) => _onWorkCompleted?.call(this, work),
      onError: (work, error, stackTrace) =>
          _onWorkError?.call(this, work, error, stackTrace),
    );
    _errorController = FdcDataSetErrorController(
      store: _errorStore,
      emitValidationError: (errors) {
        _onValidationError?.call(this, errors);
      },
      emitError: (errors, {Object? cause}) {
        _onError?.call(this, errors, cause);
        for (final listener in List<FdcDataSetErrorEvent>.of(
          _internalErrorListeners,
        )) {
          listener(this, errors, cause);
        }
      },
      notifyListeners: notifyListeners,
    );
    _aggregateCoordinator = FdcDataSetAggregateCoordinator();
    _cursorCoordinator = FdcDataSetCursorCoordinator(
      ensureOpen: _ensureOpen,
      readRecordCount: () => recordCount,
      readViewIndexes: () => _view.viewIndexes,
      resolveActiveEdit: _tryResolveEditForRecordsetChange,
      readCurrentRecordId: () => _currentRecordRaw?.id,
      runOperation: ({required operation, required recordId, required body}) =>
          _errorController.runOperation<void>(
            operation: operation,
            recordId: recordId,
            body: body,
          ),
      beforeScroll: (previousRecordNumber, targetRecordNumber) {
        for (final guard in List<void Function()>.of(
          _internalBeforeScrollGuards.values,
        )) {
          guard();
        }
        _beforeScroll?.call(this, previousRecordNumber, targetRecordNumber);
      },
      afterScroll: (previousRecordNumber, currentRecordNumber) =>
          _afterScroll?.call(this, previousRecordNumber, currentRecordNumber),
      notifyListeners: notifyListeners,
    );
    _recordViewCoordinator = FdcDataSetRecordViewCoordinator(
      recordStore: _recordStore,
      view: _view,
      cursor: _cursorCoordinator,
      readRecordMapper: () => _schemaCoordinator.recordMapper,
      rebuildView: ({preserveRecordId, required notify}) =>
          _rebuildView(preserveRecordId: preserveRecordId, notify: notify),
      beforeAppendRows: () {
        _bumpDataRevision(adapterQueryChanged: false);
        _view.clearComparableValueCache();
      },
      beforeReplaceRows: (adapterQueryChanged) {
        _applyCoordinator.clearPendingImmediateDeletes();
        _bumpDataRevision(adapterQueryChanged: adapterQueryChanged);
        _view.clearComparableValueCache();
        _clearRetainedVisibleRecords();
      },
      beforeDiscardRecord: (record) {
        if (record.selected) {
          _selectionCoordinator.syncSelectionKeyForRecord(record, false);
        }
        _bumpDataRevision(adapterQueryChanged: !_paging.enabled);
        _view.clearComparableValueCache();
      },
      clearEditBuffer: ({required invalidateAggregateCache}) =>
          _clearEditBuffer(invalidateAggregateCache: invalidateAggregateCache),
      readDiscardInvalidatesAggregateCache: () => !_paging.enabled,
      readPagingEnabled: () => _paging.enabled,
    );
    _applyCoordinator = FdcDataSetApplyCoordinator(
      updateMode: _updateMode,
      hasUpdates: () => hasUpdates,
      readState: () => _state,
      ensureOpen: _ensureOpen,
      tryPostActiveEdit: _tryPostActiveEdit,
      buildApplyChangeSet: _buildApplyChangeSet,
      applyLocalChanges: _applyLocalChanges,
      beginAdapterApply: _beginAdapterApply,
      captureLifecycleGeneration: _lifecycleCoordinator.captureGeneration,
      isLifecycleCurrent: _isLifecycleCurrent,
      applyAdapterChanges: _applyAdapterChanges,
      completeApplyResult: _completeApplyResult,
      completeApplyException: _completeApplyException,
      readAdapter: () => _adapter,
      exceptionMessage: _errorController.exceptionMessage,
    );
    _editCoordinator = FdcDataSetEditCoordinator(
      readState: () => _state,
      isImmediateApplyRunning: () => _applyCoordinator.isImmediateApplyRunning,
      readPendingImmediatePostRecordId: () =>
          _applyCoordinator.pendingImmediatePostRecordId,
      hasDirtyEdit: () => _hasDirtyEdit,
      ensureWritable: _ensureWritable,
      ensureOpen: _ensureOpen,
      readCurrentRecord: () => _currentRecordRaw,
      clearErrors: () => _errorController.clearErrors(notify: false),
      beforeEdit: () => _beforeEdit?.call(this),
      beginEdit: (record) => _beginEditBuffer(record, insertRecord: false),
      setState: _setState,
      afterEdit: () => _afterEdit?.call(this),
      notifyListeners: notifyListeners,
      runOperation: ({required operation, required recordId, required body}) =>
          _errorController.runOperation<void>(
            operation: operation,
            recordId: recordId,
            body: body,
          ),
      ensureBrowseLikeState: _ensureBrowseLikeState,
      readCurrentRecordId: () => _currentRecordRaw?.id,
      createInsertedRecord: () => _schemaCoordinator.recordMapper
          .createInsertedRecord(recordId: _recordStore.takeNextRecordId()),
      prepareInsert: (_) {
        _bumpDataRevision(adapterQueryChanged: false);
        _view.clearComparableValueCache();
      },
      resolveInsertRawIndex: (target) => target.resolveRawIndex(
        currentIndex: _cursorCoordinator.currentIndex,
        recordCount: _recordStore.length,
        rawIndexForActiveIndex: _recordViewCoordinator.rawIndexForActiveIndex,
      ),
      insertRawRecord: _recordStore.insertRaw,
      activateInsertedRecord: _activateInsertedRecord,
      emitNewRecordDefaults: _emitNewRecordWithDefaults,
      refreshInsertedRecordView: _refreshInsertedRecordView,
      rollbackFailedInsert: _rollbackFailedInsert,
      beforeInsert: () => _beforeInsert?.call(this),
      afterInsert: () => _afterInsert?.call(this),
      ensureDeleteAllowed: () {
        _ensureWritable();
        _ensureOpen();
        if (_state == FdcDataSetState.loading ||
            _state == FdcDataSetState.applyingUpdates) {
          throw StateError('Cannot delete while dataset is busy.');
        }
      },
      beforeDelete: () => _beforeDelete?.call(this),
      afterDelete: () => _afterDelete?.call(this),
      markPendingImmediateDelete: _applyCoordinator.markPendingImmediateDelete,
      markRecordDeleted: (record, oldIndex) {
        _bumpDataRevision(adapterQueryChanged: !_paging.enabled);
        _view.clearComparableValueCache();
        if (record.selected) {
          _selectionCoordinator.syncSelectionKeyForRecord(record, false);
        }
        record.selected = false;
        record.state = FdcRecordState.deleted;
        _clearEditBuffer(invalidateAggregateCache: !_paging.enabled);
        _rebuildViewSelectingNearestRow(oldIndex);
      },
      ensureEditState: _ensureEditState,
      runPostOperation:
          ({required operation, required recordId, required body}) =>
              _errorController.runOperation<void>(
                operation: operation,
                recordId: recordId,
                wrapUnexpected: false,
                preserveValidationException: true,
                body: body,
              ),
      beforePost: () => _beforePost?.call(this),
      calculateCalculatedValues: _applyCalculatedFields,
      validatePost: (record, values) => <FdcValidationError>[
        ..._schemaCoordinator.validator.validateRecord(record, values: values),
        ..._adapterStorageValidationErrors(record, values),
      ],
      publishValidationErrors: (errors) =>
          _errorController.setValidationErrors(errors, notify: true),
      changedIndexesBetween: (record, values) => _schemaCoordinator.fieldWriter
          .changedIndexesBetween(record.valuesSnapshot(), values)
          .toList(growable: false),
      applyPostedValues: (record, values, changedIndexes) {
        for (final index in changedIndexes) {
          record.setValueAt(index, values[index]);
          _invalidateComparableCacheForField(index);
        }
        _bumpDataRevision(invalidateAggregateCache: false);
      },
      resolvePostedRecordState: (record) {
        if (record.state == FdcRecordState.inserted) {
          return;
        }
        record.state = record.changedFieldIndexes().isEmpty
            ? FdcRecordState.unchanged
            : FdcRecordState.modified;
      },
      retainVisibleRecord: _retainVisibleRecord,
      hasAdapter: () => _adapter != null,
      readUpdateMode: () => _updateMode,
      acceptChanges: (record) => record.acceptChanges(),
      clearEditBuffer: ({required invalidateAggregateCache}) =>
          _clearEditBuffer(invalidateAggregateCache: invalidateAggregateCache),
      markPendingImmediatePost: _applyCoordinator.markPendingImmediatePost,
      afterPost: () => _afterPost?.call(this),
      scheduleImmediateApply: _scheduleImmediateApplyUpdates,
      readPagingEnabled: () => _paging.enabled,
      readCurrentIndex: () => _cursorCoordinator.currentIndex,
      discardRecordFromStore: _discardRecordFromStore,
      rebuildView: ({preserveRecordId}) =>
          _rebuildView(preserveRecordId: preserveRecordId, notify: false),
      beforeCancel: () => _beforeCancel?.call(this),
      afterCancel: () => _afterCancel?.call(this),
    );
    _pagingCoordinator = FdcDataSetPagingCoordinator(
      options: _paging,
      openPageCore: _openPage,
    );
    this.paging = FdcDataSetPagingApi._(this);
    selection = FdcDataSetSelectionApi._(this);
    aggregates = FdcDataSetAggregatesApi._(this);
    bookmarks = FdcDataSetBookmarksApi._(this);
    errors = FdcDataSetErrorsApi._(this);
    _queryCoordinator = FdcDataSetQueryCoordinator(
      pagingEnabled: () => _paging.enabled,
      validateSearchFields: _validateSearchFields,
      readSearchState: () => _view.searchState,
      writeSearchState: (state) => _view.searchState = state,
      validateFilterFields: _validateFilterFields,
      readFilters: () => _view.filters,
      writeFilters: (filters) {
        _view.filters
          ..clear()
          ..addAll(filters);
      },
      readFilterContext: () => _view.filterContext,
      writeFilterContext: (context) => _view.filterContext = context,
      retainedVisibleRecordsAreEmpty: () =>
          _view.retainedVisibleRecordIds.isEmpty,
      notifyFilterChanged: _notifyFilterChanged,
      readSorts: () => _view.sorts,
      writeSorts: (sorts) {
        _view.sorts
          ..clear()
          ..addAll(sorts);
      },
      normalizeSorts: _normalizeSorts,
      isCursorAtFirst: () => _cursorCoordinator.isAtFirst,
      resolveActiveEdit: _tryResolveEditForRecordsetChange,
      clearRetainedVisibleRecords: _clearRetainedVisibleRecords,
      invalidateAggregateCache: _invalidateAggregateCache,
      rebuildView: ({required notify, required resetToFirst}) =>
          _rebuildView(notify: notify, resetToFirst: resetToFirst),
      rebuildViewAsync: ({required notify, required resetToFirst}) =>
          _rebuildViewAsync(notify: notify, resetToFirst: resetToFirst),
      openFirstPage: () => _pagingCoordinator.openPage(),
      notifyListeners: notifyListeners,
    );
    _selectionCoordinator = FdcDataSetSelectionCoordinator(
      pagingEnabled: () => _paging.enabled,
      readViewIndexes: () => _view.viewIndexes,
      recordAtRawIndex: _recordStore.atRawIndex,
      readRecords: () => _recordStore.records,
      replaceRecords: (records) => _recordStore.replaceAll(records),
      ensureNextRecordIdAfter: (internalIds) =>
          _recordStore.ensureNextRecordIdAfter(internalIds),
      readFields: () => _fields,
      fieldIndexByNormalizedName: (name) =>
          _schemaCoordinator.fieldIndexByName[name],
      readSelectedFilter: () => _view.filterContext.selected,
      setTotalRecordCount: _pagingCoordinator.setTotalRecordCount,
      recordToMap: (record, {required includeNonPersistent}) =>
          _schemaCoordinator.recordMapper.recordToMap(
            record,
            includeNonPersistent: includeNonPersistent,
          ),
    );
    filter = FdcDataSetFilters(
      canApplyViewOperation: () => _canApplyViewOperation,
      useAsyncViewOperations: () => _paging.enabled,
      readFilters: () => _view.unmodifiableFilters,
      readContext: () => _view.filterContext,
      isQueryConstraintBlocked: () => _view.isQueryConstraintBlocked,
      replaceFilters: _replaceApiFilters,
      replaceFiltersAsync: _replaceApiFiltersAsync,
      replaceFiltersAndSorts: _replaceApiFiltersAndSorts,
      replaceFiltersAndSortsAsync: _replaceApiFiltersAndSortsAsync,
    );
    sort = FdcDataSetSorts(
      canApplyViewOperation: () => _canApplyViewOperation,
      useAsyncViewOperations: () => _paging.enabled,
      readSorts: () => _view.unmodifiableSorts,
      normalizeSorts: _normalizeSorts,
      replaceSorts: _replaceApiSorts,
      replaceSortsAsync: _replaceApiSortsAsync,
    );
    search = FdcDataSetSearchApi.internal(
      readState: () => _view.currentSearchState,
      applySearch: _applySearch,
      clearSearch: _clearSearch,
    );
    _rebuildView(notify: false);
  }

  /// Adapter configured for this dataset, or `null` for a local in-memory
  /// dataset.
  ///
  /// The adapter association is configuration metadata and does not change as
  /// records are opened, navigated, or edited.
  IFdcDataAdapter? get adapter => _adapter;

  /// True when this dataset owns its rows directly instead of using an adapter.
  bool get isLocal => _adapter == null;

  List<FdcFieldDef> get _fields => _schemaCoordinator.fields;
  final IFdcDataAdapter? _adapter;
  final FdcDataPagingOptions _paging;
  final FdcUpdateMode _updateMode;
  final FdcRecordValidator? _recordValidator;
  final FdcDataSetBeforeOpen? _beforeOpen;
  final FdcDataSetAfterOpen? _afterOpen;
  final FdcDataSetBeforeClose? _beforeClose;
  final FdcDataSetAfterClose? _afterClose;
  final FdcDataSetBeforeEdit? _beforeEdit;
  final FdcDataSetAfterEdit? _afterEdit;
  final FdcDataSetBeforeInsert? _beforeInsert;
  final FdcDataSetAfterInsert? _afterInsert;
  final FdcDataSetBeforePost? _beforePost;
  final FdcDataSetAfterPost? _afterPost;
  final FdcDataSetBeforeDelete? _beforeDelete;
  final FdcDataSetAfterDelete? _afterDelete;
  final FdcDataSetBeforeCancel? _beforeCancel;
  final FdcDataSetAfterCancel? _afterCancel;
  final FdcDataSetStateChanged? _onStateChanged;
  final FdcDataSetValidationError? _onValidationError;
  final FdcDataSetErrorEvent? _onError;
  final Set<FdcDataSetErrorEvent> _internalErrorListeners =
      <FdcDataSetErrorEvent>{};
  final FdcDataSetWorkStarted? _onWorkStarted;
  final FdcDataSetWorkCompleted? _onWorkCompleted;
  final FdcDataSetWorkError? _onWorkError;
  final FdcDataSetFieldChanged? _onFieldChanged;
  final FdcDataSetNewRecord? _onNewRecord;
  final FdcDataSetBeforeScroll? _beforeScroll;
  final FdcDataSetAfterScroll? _afterScroll;

  /// Runs the function operation.
  final Map<Object, void Function()> _internalBeforeScrollGuards =
      <Object, void Function()>{};
  int _queryConstraintRevision = 0;
  int _committedQueryConstraintRevision = -1;
  int _controlsDisableCount = 0;
  bool _controlsNotificationPending = false;
  bool _restoreCurrentRecordOnEnable = false;
  FdcDataSetBookmark? _controlsRestoreBookmark;

  /// Paging state and page/chunk navigation API.
  late final FdcDataSetPagingApi paging;

  /// Row-selection state and operations API.
  late final FdcDataSetSelectionApi selection;

  /// Aggregate calculation API.
  late final FdcDataSetAggregatesApi aggregates;

  /// Transient record bookmark API.
  late final FdcDataSetBookmarksApi bookmarks;

  /// Dataset error-message API.
  late final FdcDataSetErrorsApi errors;

  late final FdcDataSetAggregateCoordinator _aggregateCoordinator;
  late final FdcDataSetApplyCoordinator _applyCoordinator;
  late final FdcDataSetCursorCoordinator _cursorCoordinator;
  late final FdcDataSetPagingCoordinator _pagingCoordinator;
  late final FdcDataSetEditCoordinator _editCoordinator;
  late final FdcDataSetSelectionCoordinator _selectionCoordinator;
  late final FdcDataSetSchemaCoordinator _schemaCoordinator;
  late final FdcDataSetQueryCoordinator _queryCoordinator;
  late final FdcDataSetRecordViewCoordinator _recordViewCoordinator;
  late final FdcDataSetLifecycleCoordinator _lifecycleCoordinator;
  late final FdcDataSetWorkCoordinator _workCoordinator;

  bool get _readOnly => _adapter?.readOnly ?? false;

  final FdcDataSetErrorStore _errorStore = FdcDataSetErrorStore();

  final FdcRecordStore _recordStore = FdcRecordStore();
  final FdcDataSetViewController _view = FdcDataSetViewController();
  final List<FdcDataSetFilterChanged> _filterChangedListeners =
      <FdcDataSetFilterChanged>[];

  /// Controls the dataset's single active filter and filtered view.
  late final FdcDataSetFilters filter;

  /// Controls the dataset's active sort definition and sorted view.
  late final FdcDataSetSorts sort;

  /// Controls the dataset's active global search definition.
  late final FdcDataSetSearchApi search;

  late final FdcDataSetErrorController _errorController;

  FdcDataSetState _state = FdcDataSetState.closed;
  int get _adapterAggregateRevision => _aggregateCoordinator.adapterRevision;

  /// Unmodifiable schema definition list used by this dataset.
  ///
  /// The list reflects the configured schema, including adapter-supplied fields
  /// adopted during open when no schema was configured explicitly. Callers must
  /// not treat it as mutable runtime record state.
  List<FdcFieldDef> get fields => _fields;

  /// Number of fields defined by this dataset schema.
  int get fieldCount => _fields.length;

  /// Unmodifiable schema field-name list in field-index order.
  ///
  /// The names correspond one-to-one with [fields] and are not record values.
  List<String> get fieldNames => _schemaCoordinator.fieldNames;

  /// Live dataset lifecycle state observed at the time of access.
  FdcDataSetState get state => _state;

  /// Whether notifications to data-aware controls are currently suspended.
  ///
  /// Dataset state, navigation, editing, validation, persistence, and typed
  /// lifecycle callbacks continue to run while controls are disabled. Only
  /// [ChangeNotifier] listener delivery is deferred.
  bool get controlsDisabled => _controlsDisableCount > 0;

  /// Number of unmatched [disableControls] calls.
  ///
  /// Controls are enabled only after the same number of [enableControls] calls.
  int get controlsDisableCount => _controlsDisableCount;

  /// Whether the current controls suspension will restore its saved record.
  bool get restoresCurrentRecordOnEnable => _restoreCurrentRecordOnEnable;

  /// Suspends notifications to data-aware controls.
  ///
  /// Calls may be nested. Use a `try`/`finally` block so every call is balanced
  /// by [enableControls]. Dataset operations and typed lifecycle events remain
  /// fully active while notifications are suspended.
  ///
  /// When [restoreCurrentRecord] is true, the current record is saved for the
  /// active suspension cycle and restored immediately before the outermost
  /// [enableControls] completes. The default is false. If no current record
  /// exists, no bookmark is captured and a later nested call may capture one.
  /// Nested calls do not replace an already saved record; the first call that
  /// successfully captures a bookmark owns it for that suspension cycle.
  void disableControls({bool restoreCurrentRecord = false}) {
    if (_lifecycleCoordinator.isDisposed) {
      return;
    }

    if (restoreCurrentRecord && !_restoreCurrentRecordOnEnable) {
      final bookmark = _createBookmark();
      if (bookmark != null) {
        _restoreCurrentRecordOnEnable = true;
        _controlsRestoreBookmark = bookmark;
      }
    }
    _controlsDisableCount++;
  }

  /// Resumes notifications to data-aware controls.
  ///
  /// When the outermost suspension ends, a saved current record is restored
  /// first and at most one deferred notification is then delivered. Throws
  /// [StateError] when no matching [disableControls] call exists.
  void enableControls() {
    if (_lifecycleCoordinator.isDisposed) {
      return;
    }
    if (_controlsDisableCount == 0) {
      throw StateError(
        'FdcDataSet.enableControls called without a matching '
        'disableControls call.',
      );
    }

    if (_controlsDisableCount > 1) {
      _controlsDisableCount--;
      return;
    }

    Object? restoreError;
    StackTrace? restoreStackTrace;
    try {
      _restoreControlsRecord();
    } on Object catch (error, stackTrace) {
      restoreError = error;
      restoreStackTrace = stackTrace;
    } finally {
      _controlsDisableCount = 0;
      _clearControlsRestoreState();
      if (_controlsNotificationPending) {
        _controlsNotificationPending = false;
        super.notifyListeners();
      }
    }

    if (restoreError != null) {
      Error.throwWithStackTrace(restoreError, restoreStackTrace!);
    }
  }

  void _restoreControlsRecord() {
    final bookmark = _controlsRestoreBookmark;
    if (!_restoreCurrentRecordOnEnable || bookmark == null) {
      return;
    }
    _restoreBookmark(bookmark, fallbackToNearest: true);
  }

  void _clearControlsRestoreState() {
    _restoreCurrentRecordOnEnable = false;
    _controlsRestoreBookmark = null;
  }

  /// Creates a transient bookmark for the current visible record.
  ///
  /// Returns null when the dataset is closed, empty, or has no current record.
  /// The bookmark is valid only for this dataset instance.
  FdcDataSetBookmark? _createBookmark() {
    if (_lifecycleCoordinator.isDisposed || !isOpen || recordCount == 0) {
      return null;
    }
    final record = _currentRecordRaw;
    final index = _cursorCoordinator.currentIndex;
    if (record == null || index < 0) {
      return null;
    }
    return FdcDataSetBookmark._(
      dataSetIdentity: this,
      recordId: record.id,
      recordIndex: index,
    );
  }

  /// Restores the current record from [bookmark].
  ///
  /// Returns true only when the original bookmarked record is still present in
  /// the active view. A bookmark created by another dataset instance is
  /// rejected and returns false.
  ///
  /// When [fallbackToNearest] is true and the original record is no longer
  /// visible, the cursor moves to the nearest valid position based on the
  /// bookmark's former index. That fallback move still returns false because
  /// the original record was not restored.
  bool _restoreBookmark(
    FdcDataSetBookmark bookmark, {
    bool fallbackToNearest = false,
  }) {
    if (_lifecycleCoordinator.isDisposed ||
        !identical(bookmark._dataSetIdentity, this) ||
        !isOpen ||
        recordCount == 0) {
      return false;
    }

    final recordIndex = _recordViewCoordinator.activeIndexForRecordId(
      bookmark._recordId,
    );
    if (recordIndex >= 0) {
      if (_cursorCoordinator.currentIndex != recordIndex) {
        _cursorCoordinator.moveToIndex(recordIndex);
      }
      return true;
    }

    if (fallbackToNearest) {
      final fallbackIndex = bookmark._recordIndex.clamp(0, recordCount - 1);
      if (_cursorCoordinator.currentIndex != fallbackIndex) {
        _cursorCoordinator.moveToIndex(fallbackIndex);
      }
    }
    return false;
  }

  /// Dataset persistence/apply semantics selected at construction time.
  ///
  /// This value is intentionally read-only. Switching between immediate and
  /// cached update semantics after edits/deletes/inserts exist would change the
  /// meaning of already staged work, so choose the mode when constructing the
  /// dataset.
  FdcUpdateMode get updateMode => _updateMode;

  /// Observable dataset work/progress state.
  ///
  /// This is the single public work/progress entry point. Application code may
  /// listen to it and read its current state; dataset internals own mutation.
  FdcDataSetWork get work => _workCoordinator.work;

  /// True when the dataset is in any state other than [FdcDataSetState.closed].
  ///
  /// This includes browse, edit, and insert states. It becomes `false` after
  /// the dataset is closed and before a subsequent open operation succeeds.
  bool get isOpen => _state != FdcDataSetState.closed;
  bool get _canApplyViewOperation => _state != FdcDataSetState.closed;

  /// Whether this object contains no items.
  bool get isEmpty => recordCount == 0;

  /// True when the dataset cursor is positioned on the first visible record.
  /// Empty datasets are both BOF and EOF.
  bool get bof => _cursorCoordinator.bof;

  /// True after navigation reaches or lands on the end of the dataset.
  ///
  /// Empty datasets are EOF. For non-empty datasets, EOF is set when navigation
  /// reaches the logical end boundary while keeping the cursor on the last real
  /// record. This includes [next] from the last visible record, [last], and
  /// [moveToRecord] with `recordCount + 1`. The classic
  /// `while (!dataSet.eof) { ... dataSet.next(); }` loop still processes the
  /// last row and leaves [recordNumber] on the last record number.
  bool get eof => recordCount == 0 || _cursorCoordinator.eof;

  /// Number of records currently visible/navigable in the dataset view.
  int get recordCount => _recordViewCoordinator.visibleRecordCount;

  /// 1-based number of the current visible record/cursor position.
  ///
  /// Returns -1 when there are no visible records.
  ///
  /// This makes iteration diagnostics natural: after
  /// `while (!dataSet.eof) { ... dataSet.next(); }`, [recordNumber] still
  /// reports the last processed record number. Internal grid/data code should use
  /// `FdcDataSetInternal.activeIndex(dataSet)`.
  int get recordNumber => _cursorCoordinator.recordNumber;

  bool get _isActiveInsertBufferUnmodified =>
      _state == FdcDataSetState.insert &&
      _editCoordinator.insertRecordId != null &&
      _editCoordinator.editRecordId == _editCoordinator.insertRecordId &&
      !_editCoordinator.modifiedByUser;

  bool get _isActiveEditBufferModified =>
      _state == FdcDataSetState.edit &&
      _editCoordinator.editRecordId != null &&
      _editCoordinator.insertRecordId == null &&
      _editCoordinator.modifiedByUser;

  bool get _hasDirtyEdit =>
      (_state == FdcDataSetState.edit || _state == FdcDataSetState.insert) &&
      _editCoordinator.editRecordId != null &&
      _editCoordinator.buffer != null &&
      _editCoordinator.modifiedByUser;

  List<FdcDataSetFilter> get _effectiveFilters =>
      List<FdcDataSetFilter>.unmodifiable(_view.effectiveFilters);

  Future<FdcDataAggregateResult> _aggregateQuery(
    List<FdcDataAggregateItem> aggregates,
  ) async {
    if (aggregates.isEmpty) {
      return const FdcDataAggregateResult();
    }

    if (_view.isQueryConstraintBlocked) {
      return const FdcDataAggregateResult();
    }

    if (!_paging.enabled || _adapter == null) {
      final values = <FdcDataAggregateKey, Object?>{};
      for (final item in aggregates) {
        values[FdcDataAggregateKey(
          fieldName: item.fieldName,
          aggregate: item.aggregate,
        )] = _aggregateCached(
          item.fieldName,
          item.aggregate,
        );
      }
      return FdcDataAggregateResult(values: Map.unmodifiable(values));
    }

    // Paged `selected(false)` is a hybrid local-view filter: the adapter
    // loads the normal page and the dataset removes selected records locally.
    // Its summaries must therefore use the same visible local view rather than
    // an adapter aggregate that cannot express that local exclusion.
    if (_view.filterContext.selected == false) {
      final values = <FdcDataAggregateKey, Object?>{};
      for (final item in aggregates) {
        values[FdcDataAggregateKey(
          fieldName: item.fieldName,
          aggregate: item.aggregate,
        )] = _aggregateCached(
          item.fieldName,
          item.aggregate,
        );
      }
      return FdcDataAggregateResult(values: Map.unmodifiable(values));
    }

    final cachedResult = _adapterAggregateResultFromCache(aggregates);
    if (cachedResult != null) {
      return cachedResult;
    }

    final activeAdapter = _adapter;
    final requestAdapterRevision = _adapterAggregateRevision;
    if (_view.filterContext.selected == true &&
        !activeAdapter.capabilities.selectedKeyFiltering) {
      throw FdcDataAdapterException(
        operation: 'aggregate',
        code: 'unsupported_adapter_operation',
        message:
            '${activeAdapter.runtimeType} does not support selected-key '
            'filtering. Paged selected-row aggregates require adapter-side '
            'selected-key filtering support.',
      );
    }
    if (!activeAdapter.capabilities.aggregates) {
      throw FdcDataAdapterException(
        operation: 'aggregate',
        code: 'unsupported_adapter_operation',
        message:
            '${activeAdapter.runtimeType} does not support aggregate queries. '
            'Paged summary aggregates require adapter-side aggregate support.',
      );
    }

    final request = FdcDataAggregateRequest(
      filters: _lifecycleCoordinator.effectiveAdapterFilters(
        adapter: _adapter,
        filters: _lifecycleCoordinator.adapterFiltersFromView(
          _effectiveFilters,
        ),
      ),
      search: _view.searchState,
      aggregates: aggregates,
      fields: _fields,
      selectedKeysOnly: _view.filterContext.selected == true,
      selectedKeys: _view.filterContext.selected == true
          ? _selectionCoordinator.selectedKeysSnapshot
          : const <FdcDataRecordKey>[],
    );

    return _workCoordinator.runAsync<FdcDataAggregateResult>(
      phase: FdcDataSetWorkPhase.load,
      message: 'Calculating aggregates',
      body: () async {
        final generation = _lifecycleCoordinator.captureGeneration();
        try {
          final result = await activeAdapter.aggregate(request);
          if (!_isLifecycleCurrent(generation)) {
            return result;
          }
          if (requestAdapterRevision == _adapterAggregateRevision) {
            _storeAdapterAggregateResult(result);
          } else {}
          return result;
        } on Object catch (error, stackTrace) {
          throw fdcNormalizeAdapterException(
            error,
            operation: 'aggregate',
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  FdcRecord? get _currentRecordRaw => _recordViewCoordinator.currentRecord(
    state: _state,
    editRecordId: _editCoordinator.editRecordId,
  );

  FdcDataSetAggregator _aggregator() => FdcDataSetAggregator(
    fields: _fields,
    fieldIndexByName: _schemaCoordinator.fieldIndexByName,
    viewIndexes: _view.viewIndexes,
    valueReader: _aggregateValueAtRawIndex,
    isReadableRawIndex: _isAggregateRawIndexReadable,
  );

  Object? _aggregateCached(String fieldName, FdcAggregate aggregate) {
    return _aggregateCoordinator.cachedValue(
      fieldName: fieldName,
      aggregate: aggregate,
      createAggregator: _aggregator,
    );
  }

  Object? _aggregateValueAtRawIndex(int rawIndex, int fieldIndex) {
    final record = _recordStore.atRawIndex(rawIndex);
    final editBuffer = _editBufferForRecord(record);
    if (editBuffer != null &&
        fieldIndex >= 0 &&
        fieldIndex < editBuffer.length) {
      return editBuffer[fieldIndex];
    }
    return record.valueAt(fieldIndex);
  }

  bool _isAggregateRawIndexReadable(int rawIndex) {
    if (rawIndex < 0 || rawIndex >= _recordStore.length) {
      return false;
    }

    final record = _recordStore.atRawIndex(rawIndex);
    if (record.state == FdcRecordState.deleted) {
      return false;
    }

    // Aggregates reflect the current dataset view, including the active
    // edit/insert buffer. This keeps bound summary rows consistent as soon as
    // a field value changes, instead of waiting for post().
    return true;
  }

  /// Builds and returns a fresh snapshot of pending inserted, updated, and
  /// deleted records.
  ///
  /// The returned [FdcChangeSet] is derived from live dataset change tracking at
  /// access time; it is not a mutable view onto the dataset's internal record
  /// store.
  FdcChangeSet get changeSet => _buildChangeSet();

  FdcChangeSet _buildChangeSet({Set<int> excludedRecordIds = const <int>{}}) {
    return FdcDataSetChangeSetBuilder(
      fields: _fields,
      records: _recordStore.records,
      recordMapper: _schemaCoordinator.recordMapper,
      excludedRecordIds: excludedRecordIds,
    ).build();
  }

  FdcChangeSet _buildApplyChangeSet() {
    final activeRecord = _currentRecordRaw;
    if (_state == FdcDataSetState.insert &&
        activeRecord != null &&
        _isActiveInsertBufferUnmodified) {
      return _buildChangeSet(excludedRecordIds: <int>{activeRecord.id});
    }

    return _buildChangeSet();
  }

  /// True when the dataset contains pending persistent changes.
  ///
  /// Inserted and deleted records always count as updates. Modified records count
  /// only when at least one changed field is persistent, so edits limited to
  /// non-persistent or calculated fields do not make this getter `true`.
  bool get hasUpdates {
    for (final record in _recordStore.records) {
      if (record.state == FdcRecordState.inserted ||
          record.state == FdcRecordState.deleted) {
        return true;
      }

      if (record.state != FdcRecordState.modified) {
        continue;
      }

      for (final fieldIndex in record.changedFieldIndexes()) {
        if (_fields[fieldIndex].isPersistent) {
          return true;
        }
      }
    }
    return false;
  }

  /// Whether the schema contains [fieldName], using case-insensitive lookup.
  bool hasField(String fieldName) => _schemaCoordinator.fieldIndexByName
      .containsKey(FdcFieldName.normalize(fieldName));

  /// Returns the zero-based schema index of [fieldName].
  ///
  /// Field lookup is case-insensitive. Throws when the field is unknown.
  int fieldIndex(String fieldName) {
    final index =
        _schemaCoordinator.fieldIndexByName[FdcFieldName.normalize(fieldName)];
    if (index == null) {
      throw ArgumentError.value(fieldName, 'fieldName', 'Unknown field.');
    }
    return index;
  }

  /// Returns the schema definition for [fieldName], using case-insensitive lookup.
  FdcField fieldByName(String fieldName) {
    final field = _fields[fieldIndex(fieldName)];
    return FdcField(
      definition: field,
      valueReader: fieldValue,
      valueWriter: setFieldValue,
    );
  }

  /// Returns the schema/metadata definition for [fieldName] as [T].
  ///
  /// Use this for type-specific field metadata, for example
  /// `fieldDef<FdcDecimalField>('amount').precision`. Runtime values should
  /// be read or written through [fieldByName], [operator []], or [operator []=].
  T fieldDef<T extends FdcFieldDef>(String fieldName) {
    final field = _fields[fieldIndex(fieldName)];

    if (field is T) {
      return field;
    }

    throw StateError(
      'Invalid field definition type: field "$fieldName" is ${field.runtimeType}, expected $T.',
    );
  }

  /// Returns the current value for [fieldName].
  ///
  /// Shorthand for `fieldByName(fieldName).value`. The returned value is
  /// intentionally raw (`Object?`); use `fieldByName(fieldName).asString` and
  /// related typed accessors when a typed read is preferred.
  Object? operator [](String fieldName) => fieldByName(fieldName).value;

  /// Sets the current edit/insert buffer value for [fieldName].
  ///
  /// Shorthand for `fieldByName(fieldName).value = value`, so it follows the
  /// same dataset state and validation rules as regular field value writes.
  void operator []=(String fieldName, Object? value) {
    fieldByName(fieldName).value = value;
  }

  /// Opens the dataset asynchronously.
  ///
  /// This is the lifecycle entry point for every data adapter. For local,
  /// adapter-less datasets use [loadRows].
  Future<void> open({FdcDataLoadRequest request = const FdcDataLoadRequest()}) {
    if (!_paging.enabled && _adapter is FdcMemoryDataAdapter) {
      _lifecycleCoordinator.openSync(request: request);
      return Future<void>.value();
    }
    return _lifecycleCoordinator.open(request: request);
  }

  void _openCore(FdcDataLoadRequest request) {
    final activeAdapter = _adapter;
    if (activeAdapter == null) {
      throw StateError(
        'FdcDataSet.open() requires an adapter. Use loadRows() for local datasets.',
      );
    }
    if (_paging.enabled) {
      throw StateError(
        'FdcDataSet.open() cannot use immediate adapter loading when paging is enabled. Use await open() or paging.openPage().',
      );
    }
    if (_view.isQueryConstraintBlocked) {
      _openBlockedQueryConstraint();
      return;
    }
    request.validatePagingContract();
    final effectiveRequest = _effectiveUnpagedAdapterLoadRequest(request);

    _openLoadedRows(
      operation: 'open',
      phase: FdcDataSetWorkPhase.load,
      message: 'Loading dataset',
      loadResult: () {
        _lifecycleCoordinator.validateAdapterLoadRequest(
          adapter: activeAdapter,
          request: effectiveRequest,
          pagingEnabled: _paging.enabled,
          requireTotalCount: _paging.requireTotalCount,
        );
        return _runAdapterLoadSyncOperation(activeAdapter, effectiveRequest);
      },
    );
  }

  void _openBlockedQueryConstraint() {
    _openLoadedRows(
      operation: 'open',
      phase: FdcDataSetWorkPhase.load,
      message: 'Opening dataset',
      loadResult: () => const FdcDataLoadResult(
        rows: <Map<String, Object?>>[],
        totalCount: 0,
      ),
    );
    if (_paging.enabled) {
      _pagingCoordinator.setTotalRecordCount(0);
    }
  }

  Future<void> _openFutureCore(FdcDataLoadRequest request) async {
    final activeAdapter = _adapter;
    if (activeAdapter == null) {
      throw StateError(
        'FdcDataSet.open() requires an adapter. Use loadRows() for local datasets.',
      );
    }
    if (_view.isQueryConstraintBlocked) {
      _openBlockedQueryConstraint();
      return;
    }
    request.validatePagingContract();
    if (_paging.enabled) {
      final requestedPageSize = request.limit ?? _pagingCoordinator.pageSize;
      final requestedOffset = request.offset;
      if (requestedOffset != null && requestedOffset % requestedPageSize != 0) {
        throw ArgumentError.value(
          requestedOffset,
          'request.offset',
          'Paged FdcDataSet.open(request:) uses an offset-based paging contract. '
              'The offset must be divisible by the effective limit/pageSize.',
        );
      }
      final requestedPageIndex = requestedOffset == null
          ? 0
          : requestedOffset ~/ requestedPageSize;
      await _pagingCoordinator.openPage(
        pageIndex: requestedPageIndex,
        pageSize: requestedPageSize,
        request: request.copyWith(offset: null, limit: null),
      );
      return;
    }

    final effectiveRequest = _effectiveUnpagedAdapterLoadRequest(request);

    await _openAdapterRowsAsync(activeAdapter, effectiveRequest);
  }

  FdcDataLoadRequest _effectiveUnpagedAdapterLoadRequest(
    FdcDataLoadRequest request,
  ) {
    final requestFilters = request.filters.isEmpty
        ? _lifecycleCoordinator.adapterFiltersFromView(_effectiveFilters)
        : request.filters;
    final requestSorts = request.sorts.isEmpty
        ? _lifecycleCoordinator.adapterSortsFromView(_view.sorts)
        : request.sorts;
    final requestSearch = request.search.isActive
        ? request.search
        : _view.searchState;

    return _lifecycleCoordinator.effectiveAdapterLoadRequest(
      adapter: _adapter,
      request: request.copyWith(
        filters: requestFilters,
        sorts: requestSorts,
        search: requestSearch,
        includeFields: _fields.isEmpty,
        includeTotalCount: request.includeTotalCount,
        fields: _fields,
      ),
    );
  }

  Future<void> _openPage({
    required int pageIndex,
    int? pageSize,
    required FdcDataLoadRequest request,
    required FdcDataPageNavigation navigation,
    Object? pageCursor,
    int? loadLimit,
    required bool appendPage,
  }) async {
    final activeAdapter = _adapter;
    if (activeAdapter == null) {
      throw StateError('FdcDataSet.paging.openPage() requires an adapter.');
    }
    if (!_paging.enabled) {
      throw StateError(
        'FdcDataSet.paging.openPage() requires FdcDataPagingOptions.enabled.',
      );
    }
    if (_view.isQueryConstraintBlocked) {
      _openBlockedQueryConstraint();
      return;
    }
    if (pageIndex < 0) {
      throw ArgumentError.value(
        pageIndex,
        'pageIndex',
        'Page index cannot be negative.',
      );
    }
    request.validatePagingContract();
    if (request.offset != null || request.limit != null) {
      throw ArgumentError(
        'FdcDataSet.paging.openPage() receives pageIndex/pageSize explicitly. '
        'Do not pass offset/limit in the request; use open(request:) for '
        'offset-based paging requests.',
      );
    }
    final nextPageSize = _paging.normalizePageSize(
      pageSize ?? _pagingCoordinator.pageSize,
    );
    final effectiveRequest = _lifecycleCoordinator
        .pagedLoadRequest(
          adapter: _adapter,
          request: request,
          pageIndex: pageIndex,
          pageSize: nextPageSize,
          viewFilters: _effectiveFilters,
          viewSorts: _view.sorts,
          viewSearch: _view.searchState,
          selectedFilter: _view.filterContext.selected,
          fields: _fields,
          requireTotalCount: _paging.requireTotalCount,
          selectedKeys: _selectionCoordinator.selectedKeysSnapshot,
        )
        .copyWith(
          limit: loadLimit ?? nextPageSize,
          pageNavigation: navigation,
          pageCursor: pageCursor,
        );
    await _openAdapterRowsAsync(
      activeAdapter,
      effectiveRequest,
      pageIndex: pageIndex,
      pageSize: nextPageSize,
      appendPage: appendPage,
    );
  }

  void _openLoadedRows({
    required String operation,
    required FdcDataSetWorkPhase phase,
    required String message,
    required FdcDataLoadResult Function() loadResult,
    bool replaceRows = true,
  }) {
    if (_state == FdcDataSetState.loading ||
        _state == FdcDataSetState.applyingUpdates) {
      throw StateError('Cannot open dataset while it is busy.');
    }

    _errorController.runOperation<void>(
      operation: operation,
      body: () {
        _workCoordinator.run<void>(
          phase: phase,
          message: message,
          body: () {
            _errorController.clearErrors(notify: false);
            _beforeOpen?.call(this);

            final result = loadResult();
            if (replaceRows) {
              _lifecycleCoordinator.commitLoadedResult(
                result: result,
                adoptFields: _schemaCoordinator.adoptLoadResultFieldsIfNeeded,
                replaceRows: _replaceRows,
                rebuildView: () => _rebuildView(notify: false),
                setTotalRecordCount: _pagingCoordinator.setTotalRecordCount,
                readRecordCount: () => recordCount,
                setCurrentIndex: (index) =>
                    _cursorCoordinator.currentIndex = index,
                setEof: (value) => _cursorCoordinator.eof = value,
                clearEditBuffer: _clearEditBuffer,
              );
            }
            _setState(FdcDataSetState.browse);

            _afterOpen?.call(this);
            notifyListeners();
          },
        );
      },
    );
  }

  Future<void> _openAdapterRowsAsync(
    IFdcDataAdapter adapter,
    FdcDataLoadRequest request, {
    int? pageIndex,
    int? pageSize,
    bool appendPage = false,
  }) async {
    final previousState = _state;
    final previousIndex = _cursorCoordinator.currentIndex;
    final previousEof = _cursorCoordinator.eof;

    if (_state == FdcDataSetState.loading ||
        _state == FdcDataSetState.applyingUpdates) {
      throw StateError('Cannot open dataset while it is busy.');
    }

    await _errorController.runOperationAsync<void>(
      operation: 'open',
      captureGeneration: _lifecycleCoordinator.captureGeneration,
      isGenerationCurrent: _isLifecycleCurrent,
      beforeAbort: (_) {
        if (_state == FdcDataSetState.loading) {
          _setState(previousState);
          _cursorCoordinator.currentIndex = previousIndex;
          _cursorCoordinator.eof = previousEof;
        }
      },
      beforeDataSetException: (_) {
        if (_state == FdcDataSetState.loading) {
          _setState(appendPage ? previousState : FdcDataSetState.closed);
          _cursorCoordinator.currentIndex = appendPage ? previousIndex : -1;
          _cursorCoordinator.eof = appendPage ? previousEof : true;
        }
      },
      beforeUnexpected: (_) {
        if (_state == FdcDataSetState.loading) {
          _setState(appendPage ? previousState : FdcDataSetState.closed);
          _cursorCoordinator.currentIndex = appendPage ? previousIndex : -1;
          _cursorCoordinator.eof = appendPage ? previousEof : true;
        }
      },
      body: () async {
        await _workCoordinator.runAsync<void>(
          phase: FdcDataSetWorkPhase.load,
          message: 'Loading dataset',
          body: () async {
            _errorController.clearErrors(notify: false);
            _beforeOpen?.call(this);

            _setState(FdcDataSetState.loading);
            notifyListeners();

            final adapterLoadWatch = Stopwatch()..start();
            _lifecycleCoordinator.validateAdapterLoadRequest(
              adapter: adapter,
              request: request,
              pagingEnabled: _paging.enabled,
              requireTotalCount: _paging.requireTotalCount,
            );
            final generation = _lifecycleCoordinator.captureGeneration();
            final queryConstraintRevision = _queryConstraintRevision;
            final result = await _runAdapterLoadOperation(
              () => adapter.load(request),
            );
            if (!_isLifecycleCurrent(generation)) {
              return;
            }
            if (queryConstraintRevision != _queryConstraintRevision) {
              _setState(previousState);
              _cursorCoordinator.currentIndex = previousIndex;
              _cursorCoordinator.eof = previousEof;
              notifyListeners();
              return;
            }
            adapterLoadWatch.stop();
            final commitWatch = Stopwatch()..start();
            _lifecycleCoordinator.commitAdapterLoadResult(
              result: result,
              pagingEnabled: _paging.enabled,
              requireTotalCount: _paging.requireTotalCount,
              appendPage: appendPage,
              pageIndex: pageIndex,
              pageSize: pageSize,
              defaultPageSize: _pagingCoordinator.pageSize,
              previousIndex: previousIndex,
              preserveTotalCount: _view.filterContext.selected == false,
              adoptFields: _schemaCoordinator.adoptLoadResultFieldsIfNeeded,
              appendRows: _appendRows,
              replaceRows:
                  (
                    rows, {
                    internalRowIds,
                    internalNextRowId,
                    required adapterQueryChanged,
                  }) => _replaceRows(
                    rows,
                    internalRowIds: internalRowIds,
                    internalNextRowId: internalNextRowId,
                    adapterQueryChanged: adapterQueryChanged,
                  ),
              syncLoadedSelection:
                  _selectionCoordinator.syncLoadedRecordsFromKeys,
              applyPagedUnselectedLocalFilter:
                  _selectionCoordinator.applyPagedUnselectedLocalFilter,
              commitPaging: _pagingCoordinator.commitLoad,
              rebuildAdapterPageView: (currentIndex) =>
                  _view.rebuildAdapterPageView(
                    records: _recordStore.records,
                    currentIndex: currentIndex,
                  ),
              rebuildLocalView: () => _rebuildView(notify: false),
              setTotalRecordCount: _pagingCoordinator.setTotalRecordCount,
              readRecordCount: () => recordCount,
              setCurrentIndex: (index) =>
                  _cursorCoordinator.currentIndex = index,
              setEof: (value) => _cursorCoordinator.eof = value,
              clearEditBuffer: ({required invalidateAggregateCache}) =>
                  _clearEditBuffer(
                    invalidateAggregateCache: invalidateAggregateCache,
                  ),
              invalidateAggregateCache: _invalidateAggregateCache,
            );
            _committedQueryConstraintRevision = queryConstraintRevision;
            commitWatch.stop();
            _setState(FdcDataSetState.browse);

            _afterOpen?.call(this);
            notifyListeners();
          },
        );
      },
    );
  }

  /// Replaces the contents of a local, adapter-less dataset.
  ///
  /// This is the ergonomic in-memory mode for applications that want the
  /// dataset itself to own the record store. It cannot be mixed with an
  /// adapter-backed dataset; use [open] when an adapter is configured.
  Future<void> loadRows(FutureOr<List<Map<String, Object?>>> rows) {
    if (rows is List<Map<String, Object?>>) {
      _lifecycleCoordinator.loadRowsSync(rows);
      return Future<void>.value();
    }
    return _lifecycleCoordinator.loadRows(rows);
  }

  void _loadRowsCore(List<Map<String, Object?>> rows) {
    _ensureLocalLoadAllowed('loadRows');
    _openLoadedRows(
      operation: 'loadRows',
      phase: FdcDataSetWorkPhase.load,
      message: 'Loading local dataset',
      loadResult: () => FdcDataLoadResult(rows: rows),
    );
  }

  Future<void> _loadRowsFutureCore(
    FutureOr<List<Map<String, Object?>>> rows,
  ) async {
    _ensureLocalLoadAllowed('loadRows');
    if (_state == FdcDataSetState.loading ||
        _state == FdcDataSetState.applyingUpdates) {
      throw StateError('Cannot load local dataset while it is busy.');
    }

    await _errorController.runOperationAsync<void>(
      operation: 'loadRows',
      captureGeneration: _lifecycleCoordinator.captureGeneration,
      isGenerationCurrent: _isLifecycleCurrent,
      beforeAbort: (_) {
        if (_state == FdcDataSetState.loading) {
          _setState(FdcDataSetState.closed);
          _cursorCoordinator.currentIndex = -1;
          _cursorCoordinator.eof = true;
        }
      },
      beforeDataSetException: (_) {
        if (_state == FdcDataSetState.loading) {
          _setState(FdcDataSetState.closed);
          _cursorCoordinator.currentIndex = -1;
          _cursorCoordinator.eof = true;
        }
      },
      beforeUnexpected: (_) {
        if (_state == FdcDataSetState.loading) {
          _setState(FdcDataSetState.closed);
          _cursorCoordinator.currentIndex = -1;
          _cursorCoordinator.eof = true;
        }
      },
      body: () async {
        await _workCoordinator.runAsync<void>(
          phase: FdcDataSetWorkPhase.load,
          message: 'Loading local dataset',
          body: () async {
            _errorController.clearErrors(notify: false);
            _beforeOpen?.call(this);

            _setState(FdcDataSetState.loading);
            notifyListeners();

            final generation = _lifecycleCoordinator.captureGeneration();
            final loadedRows = await rows;
            if (!_isLifecycleCurrent(generation)) {
              return;
            }
            _lifecycleCoordinator.commitLoadedResult(
              result: FdcDataLoadResult(rows: loadedRows),
              adoptFields: _schemaCoordinator.adoptLoadResultFieldsIfNeeded,
              replaceRows: _replaceRows,
              rebuildView: () => _rebuildView(notify: false),
              setTotalRecordCount: _pagingCoordinator.setTotalRecordCount,
              readRecordCount: () => recordCount,
              setCurrentIndex: (index) =>
                  _cursorCoordinator.currentIndex = index,
              setEof: (value) => _cursorCoordinator.eof = value,
              clearEditBuffer: _clearEditBuffer,
            );
            _setState(FdcDataSetState.browse);

            _afterOpen?.call(this);
            notifyListeners();
          },
        );
      },
    );
  }

  void _ensureLocalLoadAllowed(String operation) {
    if (_adapter != null) {
      throw StateError(
        'FdcDataSet.$operation cannot be used when an adapter is assigned. '
        'Use open() for adapter-backed datasets.',
      );
    }
  }

  /// Closes the dataset or data source.
  void close() => _lifecycleCoordinator.close();

  void _closeCore() {
    if (_state == FdcDataSetState.loading ||
        _state == FdcDataSetState.applyingUpdates) {
      throw StateError('Cannot close dataset while it is busy.');
    }

    _errorController.runOperation<void>(
      operation: 'close',
      body: () {
        _errorController.clearErrors(notify: false);
        _beforeClose?.call(this);

        _bumpDataRevision();
        _recordStore.clear();
        _view.viewIndexes.clear();
        _view.filters.clear();
        _view.sorts.clear();
        _view.searchState = const FdcDataSetSearchState();
        _view.filterContext = const FdcDataSetFilterContext();
        _view.clearComparableValueCache();
        _clearRetainedVisibleRecords();
        _applyCoordinator.clearPendingImmediateDeletes();
        _selectionCoordinator.clear();
        _invalidateAggregateCache();
        _cursorCoordinator.currentIndex = -1;
        _cursorCoordinator.eof = true;
        _pagingCoordinator.reset();
        _clearEditBuffer();
        _setState(FdcDataSetState.closed);
        _notifyFilterChanged(clearHeaderFilters: true);

        _afterClose?.call(this);
        notifyListeners();
      },
    );
  }

  /// Moves the cursor to the first visible record.
  void first() => _cursorCoordinator.first();

  /// Moves the cursor to the previous visible record.
  void prior() => _cursorCoordinator.prior();

  /// Moves the cursor to the next visible record.
  void next() => _cursorCoordinator.next();

  /// Moves the cursor to the last visible record.
  void last() => _cursorCoordinator.last();

  /// Moves to the visible record identified by its 1-based [recordNumber].
  ///
  /// Throws [RangeError] when [recordNumber] is outside the valid public
  /// range `1..recordCount`. Empty datasets cannot be moved to a record.
  void moveToRecord(int recordNumber) =>
      _cursorCoordinator.moveToRecord(recordNumber);

  Object? _fieldValueAt(int rowIndex, String fieldName) {
    final record = _recordViewCoordinator.recordAtActiveIndex(rowIndex);
    return _fieldValueForRecord(record, fieldName);
  }

  Object? _fieldValueForRecordId(int recordId, String fieldName) {
    final record = _recordStore.byId(recordId);
    if (record == null) {
      throw StateError('Dataset record no longer exists.');
    }
    return _fieldValueForRecord(record, fieldName);
  }

  Object? _fieldValueForRecord(FdcRecord record, String fieldName) {
    final index = fieldIndex(fieldName);
    if (_isEditingRecord(record)) {
      return _editCoordinator.buffer![index];
    }

    return record.valueAt(index);
  }

  /// Returns the current value of [fieldName].
  ///
  /// During edit or insert state this reads from the active edit buffer; in
  /// browse state it reads the current stored record. Throws when there is no
  /// current record or the field name is unknown.
  Object? fieldValue(String fieldName) {
    final record = _currentRecordRaw;
    if (record == null) {
      throw StateError('Dataset has no current record.');
    }

    final index = fieldIndex(fieldName);
    if (_isEditingRecord(record)) {
      return _editCoordinator.buffer![index];
    }

    return record.valueAt(index);
  }

  /// Sets a field value on the current edit/insert record.
  ///
  /// Dataset write operations are intentionally current-record based. Use
  /// [moveToRecord], [edit]/[append]/[insert], then [setFieldValue] and [post] to
  /// mutate data through the normal lifecycle.
  void setFieldValue(String fieldName, Object? value) {
    _ensureWritable();
    _ensureEditState();
    final record = _currentRecordRaw;
    if (record == null) {
      throw StateError('Dataset has no current record.');
    }
    _setRecordFieldValue(record, fieldName, value);
  }

  /// Validates [value] against the schema and validators of [fieldName].
  ///
  /// This is a pure public validation helper: it returns validation errors but
  /// does not update `errors`, does not emit `onValidationError`, and does not
  /// show or clear UI errors. Grid/editor bindings use the internal
  /// validate-and-emit path when they need interactive feedback.
  List<FdcValidationError> validateFieldValue(String fieldName, Object? value) {
    return _validateFieldValue(fieldName, value, emitErrors: false);
  }

  List<FdcValidationError> _validateFieldValueAndEmit(
    String fieldName,
    Object? value,
  ) {
    return _validateFieldValue(fieldName, value, emitErrors: true);
  }

  List<FdcValidationError> _validateFieldValue(
    String fieldName,
    Object? value, {
    required bool emitErrors,
  }) {
    final record = _currentRecordRaw;
    if (record == null) {
      throw StateError('Dataset has no current record.');
    }

    final index = fieldIndex(fieldName);
    final values = _isEditingRecord(record)
        ? List<Object?>.of(_editCoordinator.buffer!)
        : record.valuesSnapshot();

    try {
      values[index] = FdcFieldValueNormalizer.normalize(_fields[index], value);
      // ignore: avoid_catching_errors
    } on ArgumentError catch (error) {
      final validationErrors = <FdcValidationError>[
        FdcValidationError(
          fieldName: fieldName,
          recordId: record.id,
          message: error.message?.toString() ?? error.toString(),
        ),
      ];

      if (emitErrors) {
        _errorController.setFieldValidationErrors(
          fieldName,
          recordId: record.id,
          validationErrors: validationErrors,
          notify: true,
        );
      }

      return validationErrors;
    }

    _applyCalculatedFields(values);

    final validationRecord = FdcRecord(
      id: record.id,
      values: values,
      originalValues: record.originalValuesSnapshot(),
      state: record.state,
    );
    final errors = <FdcValidationError>[
      ..._schemaCoordinator.validator.validateFieldAtIndex(
        validationRecord,
        index,
      ),
      ..._storageErrorsForField(
        field: _fields[index],
        value: values[index],
        recordId: record.id,
      ),
    ];

    if (emitErrors) {
      _errorController.setFieldValidationErrors(
        fieldName,
        recordId: record.id,
        validationErrors: errors,
        notify: true,
      );
    }

    return errors;
  }

  List<FdcValidationError> _adapterStorageValidationErrors(
    FdcRecord record,
    List<Object?> values,
  ) {
    final errors = <FdcValidationError>[];
    for (var index = 0; index < _fields.length; index++) {
      errors.addAll(
        _storageErrorsForField(
          field: _fields[index],
          value: values[index],
          recordId: record.id,
        ),
      );
    }
    return errors;
  }

  List<FdcValidationError> _storageErrorsForField({
    required FdcFieldDef field,
    required Object? value,
    required int recordId,
  }) {
    final adapter = _adapter;
    if (adapter == null) {
      return const <FdcValidationError>[];
    }

    final message = adapter.validateStorageValue(field, value);
    if (message == null || message.isEmpty) {
      return const <FdcValidationError>[];
    }

    return <FdcValidationError>[
      FdcValidationError(
        fieldName: field.name,
        recordId: recordId,
        message: message,
      ),
    ];
  }

  /// Starts editing the current record.
  void edit() => _editCoordinator.edit();

  /// Starts inserting a new record at the logical end of the current view.
  ///
  /// Defaults, calculated fields, and `onNewRecord` initialization run before
  /// the dataset enters [FdcDataSetState.insert].
  void append() => _editCoordinator.append();

  /// Inserts a new record.
  void insert() => _editCoordinator.insert();

  void _activateInsertedRecord(FdcRecord record) {
    _beginEditBuffer(record, insertRecord: true);
    _setState(FdcDataSetState.insert);
  }

  void _refreshInsertedRecordView(
    FdcRecord record, {
    required bool keepAtViewEnd,
    int? keepBeforeRecordId,
  }) => _recordViewCoordinator.refreshInsertedRecordView(
    record,
    keepAtViewEnd: keepAtViewEnd,
    keepBeforeRecordId: keepBeforeRecordId,
  );

  void _rollbackFailedInsert(FdcRecord record, int? previousRecordId) {
    final removed = _recordStore.removeById(record.id);
    _clearEditBuffer(invalidateAggregateCache: false);
    _setState(FdcDataSetState.browse);

    if (!removed) {
      return;
    }

    _bumpDataRevision(adapterQueryChanged: false);
    _view.clearComparableValueCache();
    _rebuildView(preserveRecordId: previousRecordId, notify: false);
  }

  /// Deletes the current record.
  void delete() => _editCoordinator.delete();

  /// Posts the current edit buffer.
  void post() => _editCoordinator.post();

  /// Cancels the current operation or edit state.
  void cancel() => _editCoordinator.cancel();

  bool _tryPostActiveEdit() => _editCoordinator.tryPostActiveEdit();

  bool _tryResolveEditForRecordsetChange() =>
      _editCoordinator.tryResolveEditForRecordsetChange();

  bool _tryCancelActiveEdit() => _editCoordinator.tryCancelActiveEdit();

  void _discardRecordFromStore(FdcRecord record, {required int oldIndex}) =>
      _recordViewCoordinator.discardRecord(record, oldIndex: oldIndex);

  void _rebuildViewSelectingNearestRow(int oldIndex) =>
      _recordViewCoordinator.rebuildViewSelectingNearestRow(oldIndex);

  void _scheduleImmediateApplyUpdates() {
    _applyCoordinator.scheduleImmediateApplyUpdates();
  }

  /// Applies the current persistent [changeSet] through the configured adapter.
  ///
  /// In cached-update mode this is the explicit commit boundary. In immediate
  /// mode it is also used internally after post/delete. Backend-confirmed values
  /// are merged into records on success; rejected changes remain recoverable.
  Future<FdcDataApplyResult> applyUpdates() {
    return _applyCoordinator.applyUpdates();
  }

  Future<FdcDataApplyResult> _applyLocalChanges(FdcChangeSet changes) async {
    final appliedRecordIds = _applyCoordinator.changeSetRecordIds(changes);
    _schemaCoordinator.updateApplier.acceptAppliedChanges(
      recordStore: _recordStore,
      result: const FdcDataApplyResult.success(),
      appliedRecordIds: appliedRecordIds,
    );
    _bumpDataRevision();
    _rebuildView(notify: false);
    _cursorCoordinator.normalize(
      _view.normalizeCurrentIndex(_cursorCoordinator.currentIndex),
    );
    notifyListeners();
    return const FdcDataApplyResult.success();
  }

  FdcDataSetState _beginAdapterApply() {
    final previousState = _state;
    _setState(FdcDataSetState.applyingUpdates);
    notifyListeners();
    return previousState;
  }

  Future<FdcDataApplyResult> _applyAdapterChanges(
    IFdcDataAdapter adapter,
    FdcChangeSet changes,
  ) {
    return _workCoordinator.runAsync<FdcDataApplyResult>(
      phase: FdcDataSetWorkPhase.applyUpdates,
      message: 'Applying updates',
      body: () => adapter.applyUpdates(changes),
    );
  }

  Future<FdcDataApplyResult> _completeApplyResult(
    FdcChangeSet changes,
    FdcDataApplyResult result,
    FdcDataSetState previousState,
  ) async {
    var completedImmediatePost = false;
    var applySucceeded = false;
    int? preserveRecordIdAfterApply;
    switch (result) {
      case FdcDataApplySuccess():
        applySucceeded = true;
        final appliedRecordIds = _applyCoordinator.changeSetRecordIds(changes);
        preserveRecordIdAfterApply = _currentRecordRaw?.id;
        _schemaCoordinator.updateApplier.acceptAppliedChanges(
          recordStore: _recordStore,
          result: result,
          appliedRecordIds: appliedRecordIds,
        );
        completedImmediatePost = _applyCoordinator
            .completeImmediatePostIfApplied(
              appliedRecordIds: appliedRecordIds,
              updateMode: _updateMode,
              editRecordId: _editCoordinator.editRecordId,
              clearEditBuffer: () =>
                  _clearEditBuffer(invalidateAggregateCache: false),
              setState: _setState,
            );
        _applyCoordinator.clearAppliedImmediateDeletes(appliedRecordIds);
        if (_paging.enabled && _pagingCoordinator.totalRecordCount != null) {
          if (_pagedApplyRequiresTotalCountReload()) {
            _pagingCoordinator.setTotalRecordCount(null);
          } else {
            _pagingCoordinator.setTotalRecordCount(
              (_pagingCoordinator.totalRecordCount! +
                      changes.inserts.length -
                      changes.deletes.length)
                  .clamp(0, 1 << 62)
                  .toInt(),
            );
          }
        }
        if (_paging.enabled) {
          _invalidateAdapterAggregatesAfterApply(changes, result: result);
          _bumpDataRevision(adapterQueryChanged: false);
        } else {
          _bumpDataRevision();
        }

      case FdcDataApplyFailure(:final errors):
        if (errors.isNotEmpty) {
          _errorController.setErrors(<FdcDataSetError>[
            for (final error in errors)
              fdcDataSetError(
                recordId: error.recordId,
                fieldName: error.fieldName,
                code: error.code,
                message: error.message,
              ),
          ]);
        }
        _restoreImmediateDeletesAfterFailure(changes);
    }

    final restoredImmediatePost =
        !applySucceeded && _restoreImmediatePostAfterFailure(changes);
    final nextState = _applyCoordinator.resolveStateAfterApplyResult(
      restoredImmediatePost: restoredImmediatePost,
      completedImmediatePost: completedImmediatePost,
      currentState: _state,
      previousState: previousState,
    );
    if (_paging.enabled) {
      _cursorCoordinator.currentIndex = _view.rebuildAdapterPageView(
        records: _recordStore.records,
        currentIndex: _cursorCoordinator.currentIndex,
        preserveRecordId: preserveRecordIdAfterApply,
      );
    } else {
      _rebuildView(preserveRecordId: preserveRecordIdAfterApply, notify: false);
    }
    _cursorCoordinator.normalize(
      _view.normalizeCurrentIndex(_cursorCoordinator.currentIndex),
    );
    _setState(nextState);
    notifyListeners();
    return result;
  }

  FdcDataApplyResult _completeApplyException(
    FdcChangeSet changes,
    Object error,
    StackTrace stackTrace,
    FdcDataSetState previousState,
    int lifecycleGeneration,
  ) {
    if (!_isLifecycleCurrent(lifecycleGeneration)) {
      return const FdcDataApplyResult.failure();
    }
    final applyError = _applyCoordinator.mapApplyException(changes, error);
    final adapterError = fdcNormalizeAdapterException(
      error,
      operation: 'applyUpdates',
      recordId: applyError.recordId >= 0 ? applyError.recordId : null,
      fieldName: applyError.fieldName,
      code: applyError.code,
      stackTrace: stackTrace,
    );
    final dataSetError = fdcDataSetError(
      recordId: applyError.recordId,
      fieldName: applyError.fieldName,
      code: applyError.code,
      message: applyError.message,
      cause: adapterError,
    );
    _errorController.setErrors(<FdcDataSetError>[
      dataSetError,
    ], cause: adapterError);
    _restoreImmediateDeletesAfterFailure(changes);
    final restoredImmediatePost = _restoreImmediatePostAfterFailure(changes);
    final nextState = _applyCoordinator.resolveStateAfterApplyException(
      restoredImmediatePost: restoredImmediatePost,
      currentState: _state,
      previousState: previousState,
    );
    _rebuildView(notify: false);
    _cursorCoordinator.normalize(
      _view.normalizeCurrentIndex(_cursorCoordinator.currentIndex),
    );
    _setState(nextState);
    notifyListeners();
    return FdcDataApplyResult.failure(errors: <FdcDataApplyError>[applyError]);
  }

  FdcDataLoadResult _runAdapterLoadSyncOperation(
    IFdcDataAdapter adapter,
    FdcDataLoadRequest request,
  ) {
    if (adapter is! IFdcSynchronousDataAdapter) {
      throw StateError(
        'The configured data adapter does not expose synchronous loadSync(). '
        'Await open() to use the asynchronous adapter load path.',
      );
    }

    try {
      return adapter.loadSync(request);
    } on Object catch (error, stackTrace) {
      throw fdcNormalizeAdapterException(
        error,
        operation: 'load',
        stackTrace: stackTrace,
      );
    }
  }

  Future<FdcDataLoadResult> _runAdapterLoadOperation(
    Future<FdcDataLoadResult> Function() body,
  ) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      throw fdcNormalizeAdapterException(
        error,
        operation: 'load',
        stackTrace: stackTrace,
      );
    }
  }

  bool _restoreImmediatePostAfterFailure(FdcChangeSet changes) {
    return _applyCoordinator.restoreImmediatePostAfterFailure(
      changes: changes,
      updateMode: _updateMode,
      editRecordId: _editCoordinator.editRecordId,
      activeIndexForRecordId: _recordViewCoordinator.activeIndexForRecordId,
      setCurrentIndex: (index) => _cursorCoordinator.currentIndex = index,
      setState: _setState,
    );
  }

  void _restoreImmediateDeletesAfterFailure(FdcChangeSet changes) {
    _applyCoordinator.restoreImmediateDeletesAfterFailure(
      changes: changes,
      updateMode: _updateMode,
      recordById: _recordStore.byId,
      rebuildView: (preserveRecordId) =>
          _rebuildView(preserveRecordId: preserveRecordId, notify: false),
      readRecordCount: () => recordCount,
      activeIndexForRecordId: _recordViewCoordinator.activeIndexForRecordId,
      setCurrentIndex: (index) => _cursorCoordinator.currentIndex = index,
      setEof: (value) => _cursorCoordinator.eof = value,
    );
  }

  /// Reverts all unapplied cached inserts, edits, and deletes.
  ///
  /// This operation is intended for [FdcUpdateMode.cachedUpdates] workflows and
  /// rebuilds the active view from accepted record state.
  void cancelUpdates() {
    _ensureOpen();
    if (!_tryCancelActiveEdit()) {
      return;
    }

    if (!hasUpdates) {
      return;
    }

    _bumpDataRevision();
    _view.clearComparableValueCache();
    _schemaCoordinator.updateApplier.cancelCachedUpdates(_recordStore);
    _applyCoordinator.clearPendingImmediateDeletes();
    _errorController.clearErrors(notify: false);
    _clearRetainedVisibleRecords();

    _rebuildView(notify: false);
    _cursorCoordinator.normalize(
      _view.normalizeCurrentIndex(_cursorCoordinator.currentIndex),
    );
    notifyListeners();
  }

  void _setViewState({
    List<FdcDataSetFilter>? filters,
    List<FdcDataSetSort>? sorts,
    FdcDataSetFilterContext context = const FdcDataSetFilterContext(),
    bool? clearRetainedVisibleRecords,
    bool notify = true,
  }) {
    if (!_canApplyViewOperation) {
      return;
    }
    if ((filters != null || sorts != null) &&
        !_tryResolveEditForRecordsetChange()) {
      return;
    }

    final shouldClearRetainedVisibleRecords =
        clearRetainedVisibleRecords ?? filters != null;
    if (filters != null) {
      final filtersApplied = _replaceFilters(
        filters,
        context,
        clearRetainedVisibleRecords: shouldClearRetainedVisibleRecords,
        notify: false,
        clearHeaderFilters: true,
      );
      if (!filtersApplied) {
        return;
      }
    } else if (shouldClearRetainedVisibleRecords &&
        _view.retainedVisibleRecordIds.isNotEmpty) {
      _clearRetainedVisibleRecords();
      _invalidateAggregateCache(adapterQueryChanged: false);
    }
    if (sorts != null) {
      _view.sorts
        ..clear()
        ..addAll(_normalizeSorts(sorts));
    }
    _rebuildView(
      notify: notify,
      resetToFirst: filters != null || sorts != null,
    );
  }

  Future<void> _applySearch(
    String text, {
    FdcSearchMode mode = FdcSearchMode.phrase,
    bool caseSensitive = false,
    Iterable<String>? fields,
    Map<String, FdcSearchFieldTextFormatter>? fieldTextFormatters,
    Map<String, FdcFormatSettings>? fieldFormatSettings,
    FdcFormatSettings? formatSettings,
  }) {
    final searchState = FdcDataSetSearchState(
      text: text,
      mode: mode,
      caseSensitive: caseSensitive,
      fields: fields == null ? null : Set<String>.unmodifiable(fields),
      fieldTextFormatters: fieldTextFormatters == null
          ? null
          : Map<String, FdcSearchFieldTextFormatter>.unmodifiable(
              fieldTextFormatters,
            ),
      fieldFormatSettings: fieldFormatSettings == null
          ? null
          : Map<String, FdcFormatSettings>.unmodifiable(fieldFormatSettings),
      formatSettings: formatSettings ?? _view.filterContext.formatSettings,
    );

    if (!_paging.enabled) {
      _replaceApiSearch(searchState);
      return Future<void>.value();
    }

    return _replaceApiSearchAsync(searchState).then((_) {});
  }

  Future<void> _clearSearch() {
    if (!_paging.enabled) {
      _replaceApiSearch(const FdcDataSetSearchState());
      return Future<void>.value();
    }

    return _replaceApiSearchAsync(const FdcDataSetSearchState()).then((_) {});
  }

  bool _replaceApiSearch(
    FdcDataSetSearchState searchState, {
    bool notify = true,
  }) {
    if (!_canApplyViewOperation) {
      return false;
    }

    final nextSearchState = searchState.normalized();
    final isClearingSearch = !nextSearchState.isActive;
    return _workCoordinator.run<bool>(
      phase: FdcDataSetWorkPhase.search,
      message: isClearingSearch ? 'Clearing search' : 'Searching dataset',
      progress: isClearingSearch ? null : 0,
      body: () => _replaceSearch(nextSearchState, notify: notify),
    );
  }

  Future<bool> _replaceApiSearchAsync(
    FdcDataSetSearchState searchState, {
    bool notify = true,
  }) {
    if (!_canApplyViewOperation) {
      return Future<bool>.value(false);
    }

    final nextSearchState = searchState.normalized();
    final isClearingSearch = !nextSearchState.isActive;
    return _workCoordinator.runAsync<bool>(
      phase: FdcDataSetWorkPhase.search,
      message: isClearingSearch ? 'Clearing search' : 'Searching dataset',
      progress: isClearingSearch ? null : 0,
      // Active global search can spend several seconds in the cooperative scan
      // loop on large in-memory datasets. Let progress/status widgets paint
      // once after the work state is emitted; otherwise the UI isolate can
      // start scanning before the status bar has a chance to become visible.
      yieldAfterBegin: true,
      onLifecycleInvalidated: () => false,
      body: () => _replaceSearchAsync(nextSearchState, notify: notify),
    );
  }

  bool _replaceSearch(
    FdcDataSetSearchState searchState, {
    bool notify = true,
  }) => _queryCoordinator.replaceSearch(searchState, notify: notify);

  Future<bool> _replaceSearchAsync(
    FdcDataSetSearchState searchState, {
    bool notify = true,
  }) => _queryCoordinator.replaceSearchAsync(searchState, notify: notify);

  bool _replaceApiFilters(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context, {
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
  }) {
    if (!_canApplyViewOperation) {
      return false;
    }

    final hasFilterCriteria = filters.isNotEmpty || context.selected != null;
    return _workCoordinator.run<bool>(
      phase: FdcDataSetWorkPhase.filter,
      message: hasFilterCriteria ? 'Filtering dataset' : 'Clearing filter',
      body: () => _replaceFilters(
        filters,
        context,
        clearRetainedVisibleRecords: clearRetainedVisibleRecords,
        notify: notify,
        clearHeaderFilters: true,
      ),
    );
  }

  Future<bool> _replaceApiFiltersAsync(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context, {
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
  }) {
    if (!_canApplyViewOperation) {
      return Future<bool>.value(false);
    }

    final hasFilterCriteria = filters.isNotEmpty || context.selected != null;
    final isClearingFilters = !hasFilterCriteria;
    return _workCoordinator.runAsync<bool>(
      phase: FdcDataSetWorkPhase.filter,
      message: isClearingFilters ? 'Clearing filter' : 'Filtering dataset',
      progress: isClearingFilters ? null : 0,
      yieldAfterBegin: isClearingFilters,
      onLifecycleInvalidated: () => false,
      body: () => _replaceFiltersAsync(
        filters,
        context,
        clearRetainedVisibleRecords: clearRetainedVisibleRecords,
        notify: notify,
        clearHeaderFilters: true,
      ),
    );
  }

  bool _replaceApiFiltersAndSorts(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context,
    List<FdcDataSetSort> sorts, {
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
  }) {
    if (!_canApplyViewOperation) {
      return false;
    }
    return _workCoordinator.run<bool>(
      phase: FdcDataSetWorkPhase.filter,
      message: 'Filtering dataset',
      body: () => _queryCoordinator.replaceFiltersAndSorts(
        filters,
        context,
        sorts,
        clearRetainedVisibleRecords: clearRetainedVisibleRecords,
        notify: notify,
      ),
    );
  }

  Future<bool> _replaceApiFiltersAndSortsAsync(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context,
    List<FdcDataSetSort> sorts, {
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
  }) {
    if (!_canApplyViewOperation) {
      return Future<bool>.value(false);
    }
    final hasFilterCriteria = filters.isNotEmpty || context.selected != null;
    final isClearingFilters = !hasFilterCriteria;
    return _workCoordinator.runAsync<bool>(
      phase: FdcDataSetWorkPhase.filter,
      message: isClearingFilters ? 'Clearing filter' : 'Filtering dataset',
      progress: isClearingFilters ? null : 0,
      yieldAfterBegin: isClearingFilters,
      onLifecycleInvalidated: () => false,
      body: () => _queryCoordinator.replaceFiltersAndSortsAsync(
        filters,
        context,
        sorts,
        clearRetainedVisibleRecords: clearRetainedVisibleRecords,
        notify: notify,
      ),
    );
  }

  bool _replaceFilters(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context, {
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
    required bool clearHeaderFilters,
  }) => _queryCoordinator.replaceFilters(
    filters,
    context,
    clearRetainedVisibleRecords: clearRetainedVisibleRecords,
    notify: notify,
    clearHeaderFilters: clearHeaderFilters,
  );

  Future<bool> _replaceFiltersAsync(
    List<FdcDataSetFilter> filters,
    FdcDataSetFilterContext context, {
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
    required bool clearHeaderFilters,
  }) => _queryCoordinator.replaceFiltersAsync(
    filters,
    context,
    clearRetainedVisibleRecords: clearRetainedVisibleRecords,
    notify: notify,
    clearHeaderFilters: clearHeaderFilters,
  );

  bool _applyInternalFilter(
    List<FdcDataSetFilter> filters, {
    FdcDataSetFilterContext context = const FdcDataSetFilterContext(),
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
  }) {
    if (!_canApplyViewOperation) {
      return false;
    }

    final hasFilterCriteria = filters.isNotEmpty || context.selected != null;
    return _workCoordinator.run<bool>(
      phase: FdcDataSetWorkPhase.filter,
      message: hasFilterCriteria ? 'Filtering dataset' : 'Clearing filter',
      body: () => _replaceFilters(
        List<FdcDataSetFilter>.unmodifiable(filters),
        context,
        clearRetainedVisibleRecords: clearRetainedVisibleRecords,
        notify: notify,
        clearHeaderFilters: false,
      ),
    );
  }

  Future<bool> _applyInternalFilterAsync(
    List<FdcDataSetFilter> filters, {
    FdcDataSetFilterContext context = const FdcDataSetFilterContext(),
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
  }) {
    if (!_canApplyViewOperation) {
      return Future<bool>.value(false);
    }

    final hasFilterCriteria = filters.isNotEmpty || context.selected != null;
    final isClearingFilters = !hasFilterCriteria;
    return _workCoordinator.runAsync<bool>(
      phase: FdcDataSetWorkPhase.filter,
      message: isClearingFilters ? 'Clearing filter' : 'Filtering dataset',
      progress: isClearingFilters ? null : 0,
      yieldAfterBegin: isClearingFilters,
      onLifecycleInvalidated: () => false,
      body: () => _replaceFiltersAsync(
        List<FdcDataSetFilter>.unmodifiable(filters),
        context,
        clearRetainedVisibleRecords: clearRetainedVisibleRecords,
        notify: notify,
        clearHeaderFilters: false,
      ),
    );
  }

  void _addFilterChangedListener(FdcDataSetFilterChanged listener) {
    if (_filterChangedListeners.contains(listener)) {
      return;
    }
    _filterChangedListeners.add(listener);
  }

  void _removeFilterChangedListener(FdcDataSetFilterChanged listener) {
    _filterChangedListeners.remove(listener);
  }

  void _notifyFilterChanged({required bool clearHeaderFilters}) {
    if (_filterChangedListeners.isEmpty) {
      return;
    }
    final change = FdcDataSetFilterChange(
      clearHeaderFilters: clearHeaderFilters,
    );
    final listeners = List<FdcDataSetFilterChanged>.of(_filterChangedListeners);
    for (final listener in listeners) {
      listener(change);
    }
  }

  void _validateSearchFields(FdcDataSetSearchState searchState) {
    final searchFields = searchState.fields;
    if (searchFields == null) {
      return;
    }
    for (final fieldName in searchFields) {
      final normalized = FdcFieldName.normalize(fieldName);
      if (!_schemaCoordinator.fieldIndexByName.containsKey(normalized)) {
        throw ArgumentError.value(
          fieldName,
          'fields',
          'Unknown search field "$fieldName".',
        );
      }
    }
  }

  void _validateFilterFields(List<FdcDataSetFilter> filters) {
    for (final filter in filters) {
      final fieldIndex = _schemaCoordinator
          .fieldIndexByName[FdcFieldName.normalize(filter.fieldName)];
      if (fieldIndex == null) {
        throw FdcDataSetException(
          message:
              'Unknown filter field "${filter.fieldName}" in dataset $runtimeType.',
        );
      }

      final field = _fields[fieldIndex];
      if ((filter.operator == FdcFilterOperator.isEmpty ||
              filter.operator == FdcFilterOperator.isNotEmpty ||
              filter.operator == FdcFilterOperator.isNullOrWhitespace ||
              filter.operator == FdcFilterOperator.isNotNullOrWhitespace) &&
          field.dataType != FdcDataType.string) {
        throw FdcDataSetException(
          message:
              'Filter operator ${filter.operator.name} can only be used with string fields. '
              'Field "${field.name}" is ${field.dataType.name}.',
        );
      }
    }
  }

  bool _replaceApiSorts(List<FdcDataSetSort> sorts, {required bool notify}) {
    if (_paging.enabled) {
      throw StateError('Use async sort APIs when dataset paging is enabled.');
    }
    if (!_canApplyViewOperation) {
      return false;
    }
    return _workCoordinator.run<bool>(
      phase: FdcDataSetWorkPhase.sort,
      message: sorts.isEmpty ? 'Clearing sort' : 'Sorting dataset',
      body: () => _queryCoordinator.replaceSorts(sorts, notify: notify),
    );
  }

  Future<bool> _replaceApiSortsAsync(
    List<FdcDataSetSort> sorts, {
    required bool notify,
  }) {
    if (!_canApplyViewOperation) {
      return Future<bool>.value(false);
    }
    return _workCoordinator.runAsync<bool>(
      phase: FdcDataSetWorkPhase.sort,
      message: sorts.isEmpty ? 'Clearing sort' : 'Sorting dataset',
      progress: sorts.isEmpty ? 0.0 : null,
      yieldAfterBegin: sorts.isNotEmpty,
      onLifecycleInvalidated: () => false,
      body: () => _queryCoordinator.replaceSortsAsync(sorts, notify: notify),
    );
  }

  List<FdcDataSetSort> _normalizeSorts(List<FdcDataSetSort> sorts) {
    if (sorts.isEmpty) {
      return const <FdcDataSetSort>[];
    }

    final normalizedSorts = <FdcDataSetSort>[];
    final seenFieldNames = <String>{};

    for (final sort in sorts) {
      final normalizedFieldName = FdcFieldName.normalize(sort.fieldName);
      final fieldIndex =
          _schemaCoordinator.fieldIndexByName[normalizedFieldName];

      if (fieldIndex == null) {
        throw FdcDataSetException(
          message:
              'Unknown sort field "${sort.fieldName}" in dataset $runtimeType.',
        );
      }

      if (!seenFieldNames.add(normalizedFieldName)) {
        throw FdcDataSetException(
          message:
              'Duplicate sort field "${_fields[fieldIndex].name}" in dataset $runtimeType.',
        );
      }

      normalizedSorts.add(
        FdcDataSetSort(
          fieldName: _fields[fieldIndex].name,
          sortType: sort.sortType,
        ),
      );
    }

    return List<FdcDataSetSort>.unmodifiable(normalizedSorts);
  }

  /// Materializes dataset records as field-name maps.
  ///
  /// By default only records in the current visible view and persistent fields
  /// are included. [includeDeleted] reads the raw record store, and
  /// [includeNonPersistent] also emits calculated/non-persistent fields.
  List<Map<String, Object?>> toMaps({
    bool includeDeleted = false,
    bool includeNonPersistent = false,
  }) {
    if (includeDeleted) {
      return [
        for (final record in _recordStore.records)
          _schemaCoordinator.recordMapper.recordToMap(
            record,
            includeNonPersistent: includeNonPersistent,
          ),
      ];
    }
    return [
      for (final index in _view.viewIndexes)
        _schemaCoordinator.recordMapper.recordToMap(
          _recordStore.atRawIndex(index),
          includeNonPersistent: includeNonPersistent,
        ),
    ];
  }

  void _bumpDataRevision({
    bool invalidateAggregateCache = true,
    bool adapterQueryChanged = true,
  }) {
    if (invalidateAggregateCache) {
      _invalidateAggregateCache(adapterQueryChanged: adapterQueryChanged);
    }
  }

  void _invalidateAggregateCache({bool adapterQueryChanged = true}) {
    _aggregateCoordinator.invalidate(adapterQueryChanged: adapterQueryChanged);
  }

  FdcDataAggregateResult? _adapterAggregateResultFromCache(
    List<FdcDataAggregateItem> aggregates,
  ) {
    return _aggregateCoordinator.adapterResultFromCache(aggregates);
  }

  void _storeAdapterAggregateResult(FdcDataAggregateResult result) {
    if (!_paging.enabled || result.values.isEmpty) {
      return;
    }
    _aggregateCoordinator.storeAdapterResult(result);
  }

  void _markAdapterAggregateCacheChanged() {
    _aggregateCoordinator.markAdapterChanged();
  }

  void _invalidateAdapterAggregateCacheAfterSelectionChange() {
    if (!_paging.enabled ||
        _adapter == null ||
        _view.filterContext.selected != true) {
      return;
    }
    _aggregateCoordinator.clearAdapter();
    _markAdapterAggregateCacheChanged();
  }

  bool _pagedApplyRequiresTotalCountReload() {
    if (_view.searchState.isActive) {
      return true;
    }
    return _lifecycleCoordinator
        .effectiveAdapterFilters(
          adapter: _adapter,
          filters: _lifecycleCoordinator.adapterFiltersFromView(
            _effectiveFilters,
          ),
        )
        .isNotEmpty;
  }

  void _invalidateAdapterAggregatesAfterApply(
    FdcChangeSet changes, {
    required FdcDataApplyResult result,
  }) {
    if (!_paging.enabled) {
      return;
    }

    // Adapter-backed writes may have backend-side effects that are invisible to
    // the client change set: database triggers, generated/default values,
    // server-side business logic, or rows refreshed by the adapter response.
    // Do not patch adapter aggregate cache optimistically from local deltas;
    // require the next aggregate request to ask the adapter again. Bump the
    // revision even when the cache is empty so in-flight aggregate results from
    // the pre-apply revision are not stored as fresh values.
    if (changes.inserts.isEmpty &&
        changes.updates.isEmpty &&
        changes.deletes.isEmpty &&
        result.serverRows.isEmpty) {
      return;
    }

    _aggregateCoordinator.clearAdapter();
    _markAdapterAggregateCacheChanged();
  }

  bool _setState(FdcDataSetState value) {
    if (_state == value) {
      return false;
    }

    final previousState = _state;
    _state = value;
    _onStateChanged?.call(this, previousState, value);
    return true;
  }

  void _appendRows(
    List<Map<String, Object?>> rows, {
    List<int>? internalRowIds,
    int? internalNextRowId,
  }) => _recordViewCoordinator.appendRows(
    rows,
    internalRowIds: internalRowIds,
    internalNextRowId: internalNextRowId,
  );

  void _replaceRows(
    List<Map<String, Object?>> rows, {
    List<int>? internalRowIds,
    int? internalNextRowId,
    bool adapterQueryChanged = true,
  }) => _recordViewCoordinator.replaceRows(
    rows,
    internalRowIds: internalRowIds,
    internalNextRowId: internalNextRowId,
    adapterQueryChanged: adapterQueryChanged,
  );

  bool _isEditingRecord(FdcRecord record) {
    return (_state == FdcDataSetState.edit ||
            _state == FdcDataSetState.insert) &&
        _editCoordinator.editRecordId == record.id &&
        _editCoordinator.buffer != null;
  }

  List<Object?>? _editBufferForRecord(FdcRecord record) {
    return _isEditingRecord(record) ? _editCoordinator.buffer : null;
  }

  void _retainVisibleRecord(int recordId) {
    _view.retainVisibleRecord(
      recordId: recordId,
      records: _recordStore.records,
    );
  }

  void _clearRetainedVisibleRecords() {
    _view.clearRetainedVisibleRecords();
  }

  void _beginEditBuffer(FdcRecord record, {required bool insertRecord}) {
    _editCoordinator.begin(record, insertRecord: insertRecord);
  }

  void _clearEditBuffer({bool invalidateAggregateCache = true}) {
    _editCoordinator.clear();
    if (invalidateAggregateCache) {
      _invalidateAggregateCache();
    }
  }

  bool _applyCalculatedFields(List<Object?> values) {
    return _schemaCoordinator.validator.applyCalculatedFields(values);
  }

  void _setRecordFieldValue(FdcRecord record, String fieldName, Object? value) {
    if (!_isEditingRecord(record)) {
      throw StateError('Record is not the active edit record.');
    }

    final changes = _schemaCoordinator.fieldWriter.writeEditBufferFieldValue(
      edit: _editCoordinator.rawBuffer,
      fieldName: fieldName,
      value: value,
    );
    if (changes.isEmpty) {
      return;
    }

    if (!_editCoordinator.suppressUserTracking) {
      _editCoordinator.modifiedByUser = true;
    }

    _aggregateCoordinator.invalidateForChanges(_fields, changes);
    _emitFieldChanged(changes);
    notifyListeners();
  }

  void _emitNewRecordWithDefaults() {
    final handler = _onNewRecord;
    if (handler == null) {
      return;
    }

    final previousSuppress = _editCoordinator.suppressUserTracking;
    _editCoordinator.suppressUserTracking = true;
    try {
      handler(this);
    } finally {
      _editCoordinator.suppressUserTracking = previousSuppress;
      // onNewRecord defaults are the initial values of the blank insert row,
      // not user input. Keep the row pristine until an actual user-driven
      // edit changes the insert buffer.
      _editCoordinator.modifiedByUser = false;
    }
  }

  void _emitFieldChanged(List<FdcFieldChange> changes) {
    final handler = _onFieldChanged;
    if (handler == null || changes.isEmpty) {
      return;
    }

    for (final change in changes) {
      handler(
        this,
        _fields[change.fieldIndex],
        change.oldValue,
        change.newValue,
      );
    }
  }

  void _rebuildView({
    int? preserveRecordId,
    required bool notify,
    bool resetToFirst = false,
  }) {
    preserveRecordId = resetToFirst
        ? null
        : preserveRecordId ?? _currentRecordRaw?.id;
    _cursorCoordinator.currentIndex = _view.rebuildView(
      records: _recordStore.records,
      fields: _fields,
      fieldIndexByName: _schemaCoordinator.fieldIndexByName,
      currentIndex: resetToFirst ? -1 : _cursorCoordinator.currentIndex,
      preserveRecordId: preserveRecordId,
      mustKeepRecordInView: (record) =>
          _state == FdcDataSetState.insert && _isEditingRecord(record),
    );
    if (resetToFirst) {
      _cursorCoordinator.currentIndex = recordCount == 0 ? -1 : 0;
      _cursorCoordinator.eof = recordCount == 0;
    } else {
      _cursorCoordinator.eof = recordCount == 0
          ? true
          : _cursorCoordinator.currentIndex >= recordCount;
      if (_cursorCoordinator.currentIndex >= recordCount && recordCount > 0) {
        _cursorCoordinator.currentIndex = recordCount - 1;
        _cursorCoordinator.eof = true;
      }
    }

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _rebuildViewAsync({
    int? preserveRecordId,
    required bool notify,
    bool resetToFirst = false,
  }) async {
    preserveRecordId = resetToFirst
        ? null
        : preserveRecordId ?? _currentRecordRaw?.id;
    final generation = _lifecycleCoordinator.captureGeneration();
    final rebuiltIndex = await _view.rebuildViewAsync(
      records: _recordStore.records,
      fields: _fields,
      fieldIndexByName: _schemaCoordinator.fieldIndexByName,
      currentIndex: resetToFirst ? -1 : _cursorCoordinator.currentIndex,
      preserveRecordId: preserveRecordId,
      mustKeepRecordInView: (record) =>
          _state == FdcDataSetState.insert && _isEditingRecord(record),
      onProgress: _workCoordinator.update,
    );
    if (!_isLifecycleCurrent(generation)) {
      return;
    }
    _cursorCoordinator.currentIndex = rebuiltIndex;
    if (resetToFirst) {
      _cursorCoordinator.currentIndex = recordCount == 0 ? -1 : 0;
      _cursorCoordinator.eof = recordCount == 0;
    } else {
      _cursorCoordinator.eof = recordCount == 0
          ? true
          : _cursorCoordinator.currentIndex >= recordCount;
      if (_cursorCoordinator.currentIndex >= recordCount && recordCount > 0) {
        _cursorCoordinator.currentIndex = recordCount - 1;
        _cursorCoordinator.eof = true;
      }
    }

    if (notify) {
      notifyListeners();
    }
  }

  void _invalidateComparableCacheForField(int fieldIndex) {
    _view.invalidateComparableCacheForField(fieldIndex);
  }

  void _ensureOpen() {
    if (_state == FdcDataSetState.closed) {
      throw StateError('Dataset is closed.');
    }
  }

  void _ensureWritable() {
    _ensureOpen();
    if (_readOnly) {
      throw StateError('Dataset is read-only.');
    }
  }

  void _ensureBrowseLikeState() {
    _ensureOpen();
    if (_state != FdcDataSetState.browse) {
      throw StateError(
        'Dataset must be in browse state. Current state: $_state',
      );
    }
  }

  void _ensureEditState() {
    _ensureOpen();
    if (_state != FdcDataSetState.edit && _state != FdcDataSetState.insert) {
      throw StateError(
        'Dataset must be in edit or insert state. Current state: $_state',
      );
    }
  }

  bool _isLifecycleCurrent(int generation) =>
      _lifecycleCoordinator.isCurrent(generation);

  @override
  void notifyListeners() {
    if (_lifecycleCoordinator.isDisposed) {
      return;
    }
    if (controlsDisabled) {
      _controlsNotificationPending = true;
      return;
    }
    super.notifyListeners();
  }

  @override
  void dispose() {
    if (!_lifecycleCoordinator.dispose()) {
      return;
    }
    _pagingCoordinator.dispose();
    _applyCoordinator.dispose();
    _editCoordinator.dispose();
    _selectionCoordinator.dispose();
    _aggregateCoordinator.dispose();
    final activeAdapter = _adapter;
    if (activeAdapter is FdcDataAdapter) {
      activeAdapter.dispose();
    }
    _workCoordinator.dispose();
    _controlsDisableCount = 0;
    _controlsNotificationPending = false;
    _clearControlsRestoreState();
    super.dispose();
  }
}

/// Internal access facade for package code that needs dataset row-indexed
/// operations without exposing those hooks on the public [FdcDataSet] API.
///
/// This class is intentionally not exported by `fdc_data.dart`; package widgets
/// and internal tests import `src/data/fdc_dataset.dart` directly when they need
/// these low-level hooks.
@internal
final class FdcDataSetInternal {
  const FdcDataSetInternal._();

  /// Runs the error details operation.
  static List<FdcDataSetError> errorDetails(FdcDataSet dataSet) =>
      dataSet._errorStore.unmodifiable;

  /// Runs the has errors operation.
  static bool hasErrors(FdcDataSet dataSet) => dataSet._errorStore.isNotEmpty;

  /// Runs the error message for field operation.
  static String? errorMessageForField(
    FdcDataSet dataSet,
    String fieldName, {
    required int recordId,
  }) {
    return dataSet._errorStore.messageForField(fieldName, recordId: recordId);
  }

  /// Runs the active index operation.
  static int activeIndex(FdcDataSet dataSet) =>
      dataSet._cursorCoordinator.currentIndex;

  /// Runs the has current record operation.
  static bool hasCurrentRecord(FdcDataSet dataSet) =>
      dataSet._currentRecordRaw != null;

  /// Runs the is active insert buffer unmodified operation.
  static bool isActiveInsertBufferUnmodified(FdcDataSet dataSet) {
    return dataSet._isActiveInsertBufferUnmodified;
  }

  /// Runs the is active edit buffer modified operation.
  static bool isActiveEditBufferModified(FdcDataSet dataSet) {
    return dataSet._isActiveEditBufferModified;
  }

  /// Runs the has dirty edit operation.
  static bool hasDirtyEdit(FdcDataSet dataSet) {
    return dataSet._hasDirtyEdit;
  }

  /// Runs the is read only operation.
  static bool isReadOnly(FdcDataSet dataSet) => dataSet._readOnly;

  /// Runs the has active edit operation.
  static bool hasActiveEdit(FdcDataSet dataSet) {
    return dataSet.state == FdcDataSetState.edit ||
        dataSet.state == FdcDataSetState.insert;
  }

  /// Runs the current record id operation.
  static int? currentRecordId(FdcDataSet dataSet) {
    return dataSet._currentRecordRaw?.id;
  }

  /// Runs the pending immediate post record id operation.
  static int? pendingImmediatePostRecordId(FdcDataSet dataSet) {
    return dataSet._applyCoordinator.pendingImmediatePostRecordId;
  }

  /// Runs the all record ids operation.
  static List<int> allRecordIds(FdcDataSet dataSet) {
    return List<int>.unmodifiable(dataSet._recordStore.ids);
  }

  /// Runs the all rows operation.
  static List<Map<String, Object?>> allRows(
    FdcDataSet dataSet, {
    bool includeDeleted = false,
    bool includeNonPersistent = false,
  }) {
    return <Map<String, Object?>>[
      for (final record in dataSet._recordStore.records)
        if (includeDeleted || record.state != FdcRecordState.deleted)
          dataSet._schemaCoordinator.recordMapper.recordToMap(
            record,
            includeNonPersistent: includeNonPersistent,
          ),
    ];
  }

  /// Runs the row map at operation.
  static Map<String, Object?> rowMapAt(
    FdcDataSet dataSet,
    int index, {
    bool includeNonPersistent = false,
  }) {
    return dataSet._schemaCoordinator.recordMapper.recordToMap(
      dataSet._recordViewCoordinator.recordAtActiveIndex(index),
      includeNonPersistent: includeNonPersistent,
    );
  }

  /// Runs the aggregate operation.
  static Object? aggregate(
    FdcDataSet dataSet,
    String fieldName,
    FdcAggregate aggregate,
  ) {
    return dataSet._aggregateCached(fieldName, aggregate);
  }

  /// Runs the aggregate query operation.
  static Future<FdcDataAggregateResult> aggregateQuery(
    FdcDataSet dataSet,
    List<FdcDataAggregateItem> aggregates,
  ) {
    return dataSet._aggregateQuery(aggregates);
  }

  /// Runs the aggregate query signature operation.
  static String aggregateQuerySignature(FdcDataSet dataSet) {
    final filters = dataSet._lifecycleCoordinator.effectiveAdapterFilters(
      adapter: dataSet._adapter,
      filters: dataSet._lifecycleCoordinator.adapterFiltersFromView(
        dataSet._effectiveFilters,
      ),
    );
    final filterText = filters
        .map(
          (filter) =>
              '${filter.fieldName}|${filter.operator.name}|${filter.value}',
        )
        .join('&&');
    final search = dataSet._view.searchState;
    final searchText = search.isActive
        ? '${search.text}|${search.mode.name}|${search.caseSensitive}|${search.fields?.join(',')}'
        : '';
    final selected = dataSet._view.filterContext.selected;
    final selectionText = selected == null ? '' : 'selected=$selected';
    return 'paging=${dataSet._paging.enabled};'
        'revision=${dataSet._adapterAggregateRevision};'
        'filters=$filterText;'
        'search=$searchText;'
        '$selectionText';
  }

  /// Runs the register before scroll guard operation.
  static void registerBeforeScrollGuard(
    FdcDataSet dataSet, {
    required Object owner,
    required void Function() guard,
  }) {
    dataSet._internalBeforeScrollGuards[owner] = guard;
  }

  /// Runs the unregister before scroll guard operation.
  static void unregisterBeforeScrollGuard(
    FdcDataSet dataSet, {
    required Object owner,
  }) {
    dataSet._internalBeforeScrollGuards.remove(owner);
  }

  /// Runs the update query constraint operation.
  static void updateQueryConstraint(
    FdcDataSet dataSet, {
    required Object owner,
    required List<FdcDataSetFilter> filters,
    bool blocked = false,
  }) {
    dataSet._validateFilterFields(filters);
    dataSet._queryConstraintRevision++;
    dataSet._view.queryConstraintFilters[owner] =
        List<FdcDataSetFilter>.unmodifiable(filters);
    if (blocked) {
      dataSet._view.blockedQueryConstraints.add(owner);
      dataSet._committedQueryConstraintRevision =
          dataSet._queryConstraintRevision;
    } else {
      dataSet._view.blockedQueryConstraints.remove(owner);
    }
    dataSet._clearRetainedVisibleRecords();
    dataSet._invalidateAggregateCache();
    if (!dataSet.isOpen || dataSet._adapter == null || blocked) {
      dataSet._rebuildView(notify: true, resetToFirst: true);
      if (blocked && dataSet._paging.enabled) {
        dataSet._pagingCoordinator.setTotalRecordCount(0);
      }
    }
  }

  /// Runs the clear query constraint operation.
  static void clearQueryConstraint(
    FdcDataSet dataSet, {
    required Object owner,
  }) {
    dataSet._queryConstraintRevision++;
    dataSet._view.queryConstraintFilters.remove(owner);
    dataSet._view.blockedQueryConstraints.remove(owner);
    dataSet._clearRetainedVisibleRecords();
    dataSet._invalidateAggregateCache();
    if (!dataSet.isOpen || dataSet._adapter == null) {
      dataSet._rebuildView(notify: true, resetToFirst: true);
    }
  }

  /// Runs the refresh query constraints operation.
  static Future<void> refreshQueryConstraints(FdcDataSet dataSet) async {
    while (true) {
      await dataSet._workCoordinator.waitUntilIdle();

      if (dataSet._lifecycleCoordinator.isDisposed ||
          !dataSet.isOpen ||
          dataSet._view.isQueryConstraintBlocked ||
          dataSet._committedQueryConstraintRevision ==
              dataSet._queryConstraintRevision) {
        return;
      }

      if (dataSet._paging.enabled) {
        await dataSet.paging.openPage(0);
      } else if (dataSet._adapter != null) {
        await dataSet.open();
      } else {
        await dataSet._rebuildViewAsync(notify: true, resetToFirst: true);
        dataSet._committedQueryConstraintRevision =
            dataSet._queryConstraintRevision;
      }
    }
  }

  /// Runs the adapter aggregate revision operation.
  static int adapterAggregateRevision(FdcDataSet dataSet) {
    return dataSet._adapterAggregateRevision;
  }

  /// Runs the loaded record count operation.
  static int loadedRecordCount(FdcDataSet dataSet) {
    return dataSet._recordStore.length;
  }

  /// Runs the contains record id operation.
  static bool containsRecordId(FdcDataSet dataSet, int recordId) {
    return dataSet._recordStore.containsId(recordId);
  }

  /// Runs the move to index operation.
  static void moveToIndex(FdcDataSet dataSet, int index) {
    dataSet._cursorCoordinator.moveToIndex(index);
  }

  /// Runs the record id at operation.
  static int recordIdAt(FdcDataSet dataSet, int index) {
    return dataSet._recordViewCoordinator.recordAtActiveIndex(index).id;
  }

  /// Runs the active index for record id operation.
  static int activeIndexForRecordId(FdcDataSet dataSet, int recordId) {
    return dataSet._recordViewCoordinator.activeIndexForRecordId(recordId);
  }

  /// Runs the is record selected at operation.
  static bool isRecordSelectedAt(FdcDataSet dataSet, int index) {
    return dataSet._selectionCoordinator.isSelectedAt(index);
  }

  /// Runs the set record selected at operation.
  static void setRecordSelectedAt(
    FdcDataSet dataSet,
    int index,
    bool selected,
  ) {
    if (dataSet._selectionCoordinator.setSelectedAt(index, selected)) {
      dataSet.notifyListeners();
    }
  }

  /// Runs the set all visible records selected operation.
  static void setAllVisibleRecordsSelected(FdcDataSet dataSet, bool selected) {
    if (dataSet._selectionCoordinator.setAllVisible(selected)) {
      dataSet.notifyListeners();
    }
  }

  /// Runs the visible selected record count operation.
  static int visibleSelectedRecordCount(FdcDataSet dataSet) {
    return dataSet._selectionCoordinator.selectedCount;
  }

  /// Runs the record state at operation.
  static FdcRecordState recordStateAt(FdcDataSet dataSet, int index) {
    return dataSet._recordViewCoordinator.recordAtActiveIndex(index).state;
  }

  /// Runs the field value at operation.
  static Object? fieldValueAt(
    FdcDataSet dataSet,
    int rowIndex,
    String fieldName,
  ) {
    return dataSet._fieldValueAt(rowIndex, fieldName);
  }

  /// Runs the field value for record id operation.
  static Object? fieldValueForRecordId(
    FdcDataSet dataSet,
    int recordId,
    String fieldName,
  ) {
    return dataSet._fieldValueForRecordId(recordId, fieldName);
  }

  /// Runs the validate field value and emit operation.
  static List<FdcValidationError> validateFieldValueAndEmit(
    FdcDataSet dataSet,
    String fieldName,
    Object? value,
  ) {
    return dataSet._validateFieldValueAndEmit(fieldName, value);
  }

  /// Runs the apply internal filter operation.
  static bool applyInternalFilter(
    FdcDataSet dataSet,
    List<FdcDataSetFilter> filters, {
    FdcDataSetFilterContext context = const FdcDataSetFilterContext(),
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
  }) {
    return dataSet._applyInternalFilter(
      filters,
      context: context,
      clearRetainedVisibleRecords: clearRetainedVisibleRecords,
      notify: notify,
    );
  }

  /// Runs the apply internal filter query operation.
  static Future<bool> applyInternalFilterQuery(
    FdcDataSet dataSet,
    List<FdcDataSetFilter> filters, {
    FdcDataSetFilterContext context = const FdcDataSetFilterContext(),
    bool clearRetainedVisibleRecords = true,
    bool notify = true,
  }) {
    return dataSet._applyInternalFilterAsync(
      filters,
      context: context,
      clearRetainedVisibleRecords: clearRetainedVisibleRecords,
      notify: notify,
    );
  }

  /// Runs the add filter changed listener operation.
  static void addFilterChangedListener(
    FdcDataSet dataSet,
    FdcDataSetFilterChanged listener,
  ) {
    dataSet._addFilterChangedListener(listener);
  }

  /// Runs the remove filter changed listener operation.
  static void removeFilterChangedListener(
    FdcDataSet dataSet,
    FdcDataSetFilterChanged listener,
  ) {
    dataSet._removeFilterChangedListener(listener);
  }

  /// Runs the add error listener operation.
  static void addErrorListener(
    FdcDataSet dataSet,
    FdcDataSetErrorEvent listener,
  ) {
    dataSet._internalErrorListeners.add(listener);
  }

  /// Runs the remove error listener operation.
  static void removeErrorListener(
    FdcDataSet dataSet,
    FdcDataSetErrorEvent listener,
  ) {
    dataSet._internalErrorListeners.remove(listener);
  }

  /// Runs the set view state operation.
  static void setViewState(
    FdcDataSet dataSet, {
    List<FdcDataSetFilter>? filters,
    List<FdcDataSetSort>? sorts,
    FdcDataSetFilterContext context = const FdcDataSetFilterContext(),
    bool? clearRetainedVisibleRecords,
    bool notify = true,
  }) {
    dataSet._setViewState(
      filters: filters,
      sorts: sorts,
      context: context,
      clearRetainedVisibleRecords: clearRetainedVisibleRecords,
      notify: notify,
    );
  }
}
