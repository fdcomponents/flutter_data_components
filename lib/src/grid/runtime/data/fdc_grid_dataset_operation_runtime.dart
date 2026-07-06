// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

part of '../fdc_grid_runtime.dart';

extension _FdcGridDatasetOperationRuntime on _FdcGridState {
  bool _postCurrentRowIfLeaving(
    int nextRowIndex, {
    FdcGridCellRef? continueToCellAfterImmediatePost,
    bool editIfPossibleAfterImmediatePost = false,
    bool preferLeadingColumnContext = false,
    FdcGridFocusChangeReason focusReasonAfterImmediatePost =
        FdcGridFocusChangeReason.keyboard,
    bool suppressColumnRevealAfterImmediatePost = false,
  }) {
    final current = _editingCell ?? _selectedCell;
    final currentRowIndex = current?.rowIndex;
    if (currentRowIndex != null) {
      if (currentRowIndex == nextRowIndex) {
        return true;
      }
      return _postRowForPendingMove(
        currentRowIndex,
        continueToCellAfterImmediatePost: continueToCellAfterImmediatePost,
        editIfPossibleAfterImmediatePost: editIfPossibleAfterImmediatePost,
        preferLeadingColumnContext: preferLeadingColumnContext,
        focusReasonAfterImmediatePost: focusReasonAfterImmediatePost,
        suppressColumnRevealAfterImmediatePost:
            suppressColumnRevealAfterImmediatePost,
      );
    }

    // A row can be in DataSet edit/insert state even when the grid itself does
    // not own cell focus. This happens, for example, when an external Append
    // button calls DataSet.append() while a grid is bound to the same dataset.
    // Leaving that passive insert row must still run the normal post/cancel
    // guard before the grid moves to another row; otherwise grid selection
    // can be restored against a stale transition state.
    final dataSetIsEditing =
        widget.dataSet.state == FdcDataSetState.edit ||
        widget.dataSet.state == FdcDataSetState.insert;
    final dataSetRowIndex = FdcDataSetInternal.activeIndex(widget.dataSet);
    if (!dataSetIsEditing || dataSetRowIndex == nextRowIndex) {
      return true;
    }

    return _postRowForPendingMove(
      dataSetRowIndex,
      continueToCellAfterImmediatePost: continueToCellAfterImmediatePost,
      editIfPossibleAfterImmediatePost: editIfPossibleAfterImmediatePost,
      preferLeadingColumnContext: preferLeadingColumnContext,
      focusReasonAfterImmediatePost: focusReasonAfterImmediatePost,
      suppressColumnRevealAfterImmediatePost:
          suppressColumnRevealAfterImmediatePost,
    );
  }

  bool _postRowForPendingMove(
    int rowIndex, {
    FdcGridCellRef? continueToCellAfterImmediatePost,
    bool editIfPossibleAfterImmediatePost = false,
    bool preferLeadingColumnContext = false,
    FdcGridFocusChangeReason focusReasonAfterImmediatePost =
        FdcGridFocusChangeReason.keyboard,
    bool suppressColumnRevealAfterImmediatePost = false,
  }) {
    _clearPendingCellMove();
    final posted = _postRow(rowIndex);
    if (posted) {
      return true;
    }

    if (continueToCellAfterImmediatePost != null &&
        _hasPendingImmediatePostForGridRow(rowIndex) &&
        widget.dataSet.errors.messages.isEmpty) {
      _setPendingCellMove(
        continueToCellAfterImmediatePost,
        editIfPossible: editIfPossibleAfterImmediatePost,
        preferLeadingColumnContext: preferLeadingColumnContext,
        focusReason: focusReasonAfterImmediatePost,
        suppressColumnReveal:
            suppressColumnRevealAfterImmediatePost ||
            _suppressKeyboardColumnReveal,
      );
    }

    return false;
  }

  bool _hasPendingImmediatePostForGridRow(int rowIndex) {
    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null) {
      return false;
    }
    final recordId = FdcDataSetInternal.recordIdAt(widget.dataSet, sourceIndex);
    return FdcDataSetInternal.pendingImmediatePostRecordId(widget.dataSet) ==
        recordId;
  }

  bool _isPristineActiveInsertRow(int rowIndex) {
    final isCurrentDataSetRow =
        FdcDataSetInternal.activeIndex(widget.dataSet) == rowIndex;
    final isActiveInsertRow =
        isCurrentDataSetRow && widget.dataSet.state == FdcDataSetState.insert;
    return isActiveInsertRow &&
        FdcDataSetInternal.isActiveInsertBufferUnmodified(widget.dataSet);
  }

  bool _cancelPristineInsertRowIfNeeded(int rowIndex) {
    if (!_isPristineActiveInsertRow(rowIndex)) {
      return false;
    }
    return _cancelCleanEditOrInsert(rowIndex);
  }

  bool _isCleanActiveEditOrInsertRow(int rowIndex) {
    final isCurrentDataSetRow =
        FdcDataSetInternal.activeIndex(widget.dataSet) == rowIndex;
    if (!isCurrentDataSetRow) {
      return false;
    }

    if (widget.dataSet.state == FdcDataSetState.insert) {
      return FdcDataSetInternal.isActiveInsertBufferUnmodified(widget.dataSet);
    }

    if (widget.dataSet.state == FdcDataSetState.edit) {
      return !FdcDataSetInternal.isActiveEditBufferModified(widget.dataSet);
    }

    return false;
  }

  bool _cancelCleanEditOrInsert(int rowIndex) {
    if (!_isCleanActiveEditOrInsertRow(rowIndex)) {
      return false;
    }

    _updatingDataSetFromGrid = true;
    try {
      widget.dataSet.cancel();
    } on Object catch (error, stackTrace) {
      _restoreCellAfterFailedRowPost(rowIndex);
      unawaited(
        _handleDataSetPostError(
          error,
          stackTrace,
          focusActiveEditorAfterDialog: true,
        ),
      );
      return false;
    } finally {
      _updatingDataSetFromGrid = false;
    }

    _refreshRowsFromDataSet();
    _syncGridSelectionFromDataSetCurrent();
    return true;
  }

  bool _postRow(int rowIndex) {
    if (!_isLiveGridRowIndex(rowIndex)) {
      _refreshRowsAndValidateState();
      return true;
    }

    if (_cancelCleanEditOrInsert(rowIndex)) {
      return true;
    }

    final isCurrentDataSetRow =
        FdcDataSetInternal.activeIndex(widget.dataSet) == rowIndex;
    final isEditingDataSetRow =
        isCurrentDataSetRow &&
        (widget.dataSet.state == FdcDataSetState.edit ||
            widget.dataSet.state == FdcDataSetState.insert);

    if (!isEditingDataSetRow) {
      return true;
    }

    if (isEditingDataSetRow) {
      _updatingDataSetFromGrid = true;
      try {
        widget.dataSet.post();
      } on Object catch (error, stackTrace) {
        _restoreCellAfterFailedRowPost(rowIndex);
        unawaited(
          _handleDataSetPostError(
            error,
            stackTrace,
            focusActiveEditorAfterDialog: true,
          ),
        );
        return false;
      } finally {
        _updatingDataSetFromGrid = false;
      }

      // Controlled dataset aborts do not necessarily throw. For example,
      // beforePost can call FdcDataSetAbortException.silent() for a silent abort or
      // FdcDataSetAbortException('message') for a visible abort. In both cases
      // the row is still not posted, so grid navigation must stay on the row.
      final stillEditingThisRow =
          FdcDataSetInternal.activeIndex(widget.dataSet) == rowIndex &&
          (widget.dataSet.state == FdcDataSetState.edit ||
              widget.dataSet.state == FdcDataSetState.insert);
      if (stillEditingThisRow) {
        _restoreCellAfterFailedRowPost(rowIndex);
        if (widget.dataSet.errors.messages.isNotEmpty) {
          _showGridOperationErrorsIfNeeded(focusActiveEditorAfterDialog: true);
        }
        return false;
      }

      final pendingImmediatePostForThisRow =
          _hasPendingImmediatePostForGridRow(rowIndex) &&
          widget.dataSet.errors.messages.isEmpty;

      _refreshRowsFromDataSet();
      _syncGridSelectionFromDataSetCurrent();

      if (pendingImmediatePostForThisRow) {
        return false;
      }
    }

    return true;
  }

  Future<void> _handleDataSetPostError(
    Object error,
    StackTrace stackTrace, {
    bool focusActiveEditorAfterDialog = false,
  }) {
    if (!mounted) {
      return Future<void>.value();
    }

    _syncInteractionState();
    if (focusActiveEditorAfterDialog) {
      _focusActiveEditorAfterGridErrorDialog = true;
    }

    if (error is FdcDataSetAbortException && error.isSilent) {
      return Future<void>.value();
    }

    return _showGridOperationErrorDialog(error);
  }

  void _restoreCellAfterFailedRowPost(int rowIndex) {
    if (!mounted || !_isLiveGridRowIndex(rowIndex)) {
      _refreshRowsAndValidateState();
      return;
    }

    final cell = _enrichCellRef(
      _cellForFirstDataSetErrorOnRow(rowIndex) ??
          _editingCell ??
          _selectedCell ??
          _firstEditableCellInRow(rowIndex) ??
          _cellRef(rowIndex, 0),
    )!;

    _setGridState(() {
      _selectedRowIndex = rowIndex;
      _selectedCell = cell;
      _editingCell = _isCellEditableForRestore(cell) ? cell : null;
      _editAtEndCell = null;
    });

    if (_editingCell != null) {
      _focusActiveEditorAfterLayout();
    } else {
      _focusGridForSelectedCell();
    }
  }

  FdcGridCellRef? _cellForFirstDataSetErrorOnRow(int rowIndex) {
    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null) {
      return null;
    }

    final recordId = FdcDataSetInternal.recordIdAt(widget.dataSet, sourceIndex);

    for (final error in FdcDataSetInternal.errorDetails(widget.dataSet)) {
      if (error.recordId != recordId || error.fieldName == null) {
        continue;
      }
      final normalizedErrorFieldName = FdcFieldName.normalize(error.fieldName!);
      final columnIndex = _visibleColumns.indexWhere(
        (column) =>
            FdcFieldName.normalize(column.fieldName) ==
            normalizedErrorFieldName,
      );
      if (columnIndex >= 0) {
        return _cellRef(rowIndex, columnIndex);
      }
    }

    return null;
  }

  FdcGridCellRef? _firstEditableCellInRow(int rowIndex) {
    final columns = _visibleColumns;
    for (var columnIndex = 0; columnIndex < columns.length; columnIndex++) {
      final column = columns[columnIndex];
      if (_isCellEditable(column, rowIndex)) {
        return _cellRef(rowIndex, columnIndex);
      }
    }
    return null;
  }

  bool _isCellEditableForRestore(FdcGridCellRef cell) {
    if (!_isLiveGridRowIndex(cell.rowIndex) ||
        cell.columnIndex < 0 ||
        cell.columnIndex >= _visibleColumns.length) {
      return false;
    }
    final column = _visibleColumns[cell.columnIndex];
    return _isCellEditable(column, cell.rowIndex);
  }

  bool _cancelDataSetEditOrInsertFromEscape() {
    if (widget.dataSet.state != FdcDataSetState.edit &&
        widget.dataSet.state != FdcDataSetState.insert) {
      return false;
    }

    _updatingDataSetFromGrid = true;
    try {
      widget.dataSet.cancel();
    } on Object catch (error, stackTrace) {
      unawaited(_handleDataSetPostError(error, stackTrace));
      return true;
    } finally {
      _updatingDataSetFromGrid = false;
    }

    final stillEditing =
        widget.dataSet.state == FdcDataSetState.edit ||
        widget.dataSet.state == FdcDataSetState.insert;
    if (stillEditing) {
      _syncInteractionState();
      if (widget.dataSet.errors.messages.isNotEmpty) {
        _showGridOperationErrorsIfNeeded();
      }
      return true;
    }

    final preferredColumnIndex = _selectedCell?.columnIndex;
    _setGridState(() {
      _refreshRowsFromDataSet();
      _validateCellState();
      _syncGridSelectionFromDataSetCurrent(
        preferredColumnIndex: preferredColumnIndex,
      );
    });
    _focusGridForSelectedCell();
    return true;
  }

  bool _insertCurrentRecordFromKeyboard() {
    if (!_canInsertCurrentRecordFromKeyboard()) {
      return false;
    }

    final preferredColumnIndex = _selectedCell?.columnIndex;
    final insertedRowIndex = _insertDataSetRow();
    if (insertedRowIndex < 0 || insertedRowIndex >= _rows.length) {
      return true;
    }

    var columnIndex = preferredColumnIndex ?? -1;
    if (columnIndex < 0 ||
        columnIndex >= _visibleColumns.length ||
        !_isCellEditable(_visibleColumns[columnIndex], insertedRowIndex)) {
      columnIndex = _firstEditableColumnIndexForRow(insertedRowIndex);
    }

    _focusNewRecordRowField(
      insertedRowIndex,
      preferredColumnIndex: columnIndex,
    );
    return true;
  }

  void _focusNewRecordRowField(
    int rowIndex, {
    int? preferredColumnIndex,
    bool editIfPossible = true,
  }) {
    if (rowIndex < 0 || rowIndex >= _rows.length) {
      return;
    }

    var columnIndex = preferredColumnIndex ?? -1;
    if (columnIndex < 0 ||
        columnIndex >= _visibleColumns.length ||
        !_isCellEditable(_visibleColumns[columnIndex], rowIndex)) {
      columnIndex = _firstEditableColumnIndexForRow(rowIndex);
    }

    if (columnIndex < 0) {
      _setGridState(() {
        _selectedRowIndex = rowIndex;
        _selectedCell = null;
        _editingCell = null;
        _editAtEndCell = null;
        _clearPendingEditText();
        _clearEditingOriginalValue();
      });
      _scrollRowIntoViewAfterLayout(rowIndex);
      _focusGridForSelectedCell();
      return;
    }

    _scrollRowIntoViewAfterLayout(rowIndex);
    _activateCell(
      _cellRef(rowIndex, columnIndex),
      editIfPossible: editIfPossible,
      revealColumnOnlyIfOutside: true,
    );
  }

  bool _canStartNewRecordFromMenu() {
    return !widget.options.readOnly &&
        !FdcDataSetInternal.isReadOnly(widget.dataSet) &&
        widget.dataSet.isOpen &&
        widget.dataSet.state == FdcDataSetState.browse &&
        _editingCell == null &&
        !_showingGridOperationErrorDialog;
  }

  bool _canInsertRecordFromMenu(int rowIndex, int? recordId) {
    if (!_canStartNewRecordFromMenu()) {
      return false;
    }
    if (widget.dataSet.recordCount == 0) {
      return true;
    }
    final liveRowIndex = _resolveLiveRowIndex(rowIndex, recordId);
    if (!_isLiveGridRowIndex(liveRowIndex)) {
      return false;
    }
    final sourceIndex = _sourceRowIndex(liveRowIndex);
    return sourceIndex != null &&
        sourceIndex >= 0 &&
        sourceIndex < widget.dataSet.recordCount;
  }

  bool _canAppendRecordFromMenu() {
    return _canStartNewRecordFromMenu();
  }

  bool _canCancelEditFromMenu() {
    return widget.dataSet.state == FdcDataSetState.edit ||
        widget.dataSet.state == FdcDataSetState.insert;
  }

  bool _insertRecordFromMenu(
    int rowIndex,
    int? recordId,
    int preferredColumnIndex,
  ) {
    if (!_canInsertRecordFromMenu(rowIndex, recordId)) {
      return false;
    }

    final liveRowIndex = _resolveLiveRowIndex(rowIndex, recordId);
    if (_isLiveGridRowIndex(liveRowIndex) &&
        !_syncDataSetCurrentRow(liveRowIndex)) {
      return true;
    }

    final insertedRowIndex = _insertDataSetRow();
    if (insertedRowIndex < 0 || insertedRowIndex >= _rows.length) {
      return true;
    }

    _focusNewRecordRowField(
      insertedRowIndex,
      preferredColumnIndex: preferredColumnIndex,
    );
    return true;
  }

  bool _appendRecordFromMenu() {
    if (!_canAppendRecordFromMenu()) {
      return false;
    }

    final appendedRowIndex = _appendDataSetRow();
    if (appendedRowIndex < 0 || appendedRowIndex >= _rows.length) {
      return true;
    }

    _focusNewRecordRowField(appendedRowIndex);
    return true;
  }

  bool _cancelEditFromMenu() {
    return _cancelDataSetEditOrInsertFromEscape();
  }

  bool _canInsertCurrentRecordFromKeyboard() {
    if (widget.options.readOnly ||
        FdcDataSetInternal.isReadOnly(widget.dataSet) ||
        widget.dataSet.state != FdcDataSetState.browse ||
        !_gridCellHasPrimaryFocus ||
        _editingCell != null ||
        _showingGridOperationErrorDialog) {
      return false;
    }

    if (widget.dataSet.recordCount == 0) {
      return true;
    }

    final rowIndex = _selectedCell?.rowIndex ?? _selectedRowIndex;
    return rowIndex != null && rowIndex >= 0 && rowIndex < _rows.length;
  }

  bool _deleteCurrentRecordFromKeyboard() {
    if (!_canDeleteCurrentRecordFromKeyboard()) {
      return false;
    }

    // A not-yet-posted insert/append row is canceled, not deleted. It must not
    // show the delete confirmation dialog because DataSet.delete() delegates this
    // case to DataSet.cancel().
    if (widget.options.confirmDelete &&
        widget.dataSet.state != FdcDataSetState.insert) {
      unawaited(_confirmKeyboardDelete());
      return true;
    }

    _deleteCurrentRecordCore();
    return true;
  }

  bool _canDeleteCurrentRecordFromKeyboard() {
    if (widget.options.readOnly ||
        FdcDataSetInternal.isReadOnly(widget.dataSet) ||
        !_gridCellHasPrimaryFocus ||
        _editingCell != null ||
        _showingDeleteConfirmDialog) {
      return false;
    }

    final rowIndex = _selectedCell?.rowIndex ?? _selectedRowIndex;
    if (rowIndex == null || rowIndex < 0 || rowIndex >= _rows.length) {
      return false;
    }

    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null ||
        sourceIndex < 0 ||
        sourceIndex >= widget.dataSet.recordCount) {
      return false;
    }

    return true;
  }

  Future<void> _confirmKeyboardDelete() async {
    if (_showingDeleteConfirmDialog || !mounted) {
      return;
    }

    _showingDeleteConfirmDialog = true;
    var confirmed = false;
    try {
      final translations = FdcApp.translationsOf(context);
      confirmed = await showFdcConfirmationDialog(
        context,
        title: translations.dialogs.confirmDelete,
        message: translations.dialogs.deleteCurrentRecord,
        yesText: translations.common.delete,
        noText: translations.common.cancel,
      );
    } on Object catch (_) {
      confirmed = false;
    } finally {
      _showingDeleteConfirmDialog = false;
    }

    if (!mounted) {
      return;
    }

    if (!confirmed) {
      _focusGridForSelectedCell();
      return;
    }

    _deleteCurrentRecordCore();
  }

  void _deleteCurrentRecordCore() {
    final rowIndex = _selectedCell?.rowIndex ?? _selectedRowIndex;
    if (rowIndex == null || rowIndex < 0 || rowIndex >= _rows.length) {
      return;
    }

    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null ||
        sourceIndex < 0 ||
        sourceIndex >= widget.dataSet.recordCount) {
      return;
    }

    _updatingDataSetFromGrid = true;
    try {
      if (FdcDataSetInternal.activeIndex(widget.dataSet) != sourceIndex) {
        FdcDataSetInternal.moveToIndex(widget.dataSet, sourceIndex);
      }
      widget.dataSet.delete();
    } on Object catch (error, stackTrace) {
      unawaited(_handleDataSetPostError(error, stackTrace));
      return;
    } finally {
      _updatingDataSetFromGrid = false;
    }

    if (widget.dataSet.errors.messages.isNotEmpty) {
      _syncInteractionState();
      _showGridOperationErrorsIfNeeded();
      return;
    }

    final preferredColumnIndex = _selectedCell?.columnIndex;
    _setGridState(() {
      _refreshRowsFromDataSet();
      _validateCellState();
      _syncGridSelectionFromDataSetCurrent(
        preferredColumnIndex: preferredColumnIndex,
      );
      _rememberDeleteSelectionRestore();
    });
    _focusGridForSelectedCellAfterLayout();
  }

  void _handleGridAsyncOperationError(
    Object error,
    StackTrace stackTrace, {
    required String operation,
    bool focusActiveEditorAfterDialog = false,
  }) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'flutter_data_components',
        context: ErrorDescription('while $operation'),
      ),
    );

    if (!mounted) {
      return;
    }

    if (widget.dataSet.errors.messages.isNotEmpty) {
      _showGridOperationErrorsIfNeeded(
        focusActiveEditorAfterDialog: focusActiveEditorAfterDialog,
      );
      return;
    }

    if (focusActiveEditorAfterDialog) {
      _focusActiveEditorAfterGridErrorDialog = true;
    }
    unawaited(_showGridOperationErrorDialog(error));
  }

  void _showGridOperationErrorsIfNeeded({
    bool focusActiveEditorAfterDialog = false,
  }) {
    if (!mounted) {
      return;
    }

    if (focusActiveEditorAfterDialog) {
      _focusActiveEditorAfterGridErrorDialog = true;
    }

    if (widget.dataSet.errors.messages.isEmpty) {
      _lastShownGridOperationErrorSignature = null;
      return;
    }

    final signature = _gridOperationErrorSignature();
    if (signature == _lastShownGridOperationErrorSignature) {
      return;
    }

    _lastShownGridOperationErrorSignature = signature;
    final errors = FdcDataSetInternal.errorDetails(widget.dataSet);
    unawaited(
      _showGridOperationErrorDialog(
        FdcDataSetException(
          message: FdcApp.translationsOf(context).validation.validationError,
          errors: errors,
          cause: _firstGridOperationErrorCause(errors),
        ),
      ),
    );
  }

  String _gridOperationErrorSignature() {
    return FdcDataSetInternal.errorDetails(widget.dataSet)
        .map(
          (error) =>
              '${error.recordId}|${error.fieldName}|${error.code}|${error.message}',
        )
        .join('\n');
  }

  void _runGridAppCallback(VoidCallback callback) {
    try {
      callback();
    } on Object catch (error) {
      unawaited(_showGridOperationErrorDialog(error));
    }
  }

  Object? _firstGridOperationErrorCause(List<FdcDataSetError> errors) {
    for (final error in errors) {
      if (error.cause != null) {
        return error.cause;
      }
    }
    return null;
  }

  String _gridOperationErrorDialogTitle(Object error) {
    if (_isGridValidationError(error)) {
      return FdcApp.translationsOf(context).validation.validationError;
    }
    if (_isGridAdapterError(error)) {
      return FdcApp.translationsOf(context).validation.dataOperationError;
    }
    if (error is FdcDataSetException) {
      return FdcApp.translationsOf(context).validation.dataSetError;
    }
    return FdcApp.translationsOf(context).validation.error;
  }

  bool _isGridValidationError(Object? error) {
    if (error is FdcDataSetValidationException ||
        error is FdcDataSetAbortException) {
      return true;
    }
    if (error is! FdcDataSetException) {
      return false;
    }
    if (_isGridValidationError(error.cause)) {
      return true;
    }
    if (error.errors.isEmpty) {
      return false;
    }
    return error.errors.every(
      (item) => item.cause == null || _isGridValidationError(item.cause),
    );
  }

  bool _isGridAdapterError(Object? error) {
    if (error is FdcDataAdapterException) {
      return true;
    }
    if (error is! FdcDataSetException) {
      return false;
    }
    if (_isGridAdapterError(error.cause)) {
      return true;
    }
    return error.errors.any((item) => _isGridAdapterError(item.cause));
  }

  Future<void> _showGridOperationErrorDialog(Object error) {
    if (!mounted) {
      return Future<void>.value();
    }
    if (_showingGridOperationErrorDialog) {
      return _gridOperationErrorDialogFuture ?? Future<void>.value();
    }

    final completer = Completer<void>();
    _showingGridOperationErrorDialog = true;
    _gridOperationErrorDialogFuture = completer.future;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _showingGridOperationErrorDialog = false;
        _gridOperationErrorDialogFuture = null;
        if (!completer.isCompleted) {
          completer.complete();
        }
        return;
      }

      // The dialog is scheduled one frame later. In the meantime DataSet.cancel()
      // or DataSet.delete() may already have cleared the validation errors for
      // an unposted insert/append row. In that case the scheduled dialog is
      // stale and must not be shown.
      final requiresLiveDataSetErrors =
          error is FdcDataSetException &&
          error.errors.isNotEmpty &&
          _isGridValidationError(error);
      if (requiresLiveDataSetErrors && widget.dataSet.errors.messages.isEmpty) {
        _showingGridOperationErrorDialog = false;
        _gridOperationErrorDialogFuture = null;
        _lastShownGridOperationErrorSignature = null;
        if (!completer.isCompleted) {
          completer.complete();
        }
        return;
      }

      try {
        final message = FdcValidationMessageFormatter.fromObject(
          error,
          dataSet: widget.dataSet,
          translations: FdcApp.translationsOf(context).validation,
        );

        unawaited(
          showFdcMessageDialog(
                context,
                title: _gridOperationErrorDialogTitle(error),
                message: message,
              )
              .catchError((_) {
                // Dialog presentation must never become a second, unhandled exception
                // after the original dataset error was already captured.
              })
              .whenComplete(() {
                _completeGridOperationErrorDialog();
                if (!completer.isCompleted) {
                  completer.complete();
                }
              }),
        );
      } on Object catch (_) {
        _completeGridOperationErrorDialog();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // addPostFrameCallback does not, by itself, request a new frame. Several
    // controlled-abort paths (beforeEdit/beforeCancel/beforeInsert) update only
    // dataset error state and intentionally do not call setState because the
    // grid selection/editor state does not change. Without forcing a visual
    // update, the queued dialog callback can remain pending until some unrelated
    // UI event occurs, which makes visible aborts look silent.
    WidgetsBinding.instance.ensureVisualUpdate();
    return completer.future;
  }

  void _completeGridOperationErrorDialog() {
    _showingGridOperationErrorDialog = false;
    _gridOperationErrorDialogFuture = null;
    _lastShownGridOperationErrorSignature = null;
    if (!mounted) {
      return;
    }

    // Do not clear dataset errors simply because the dialog was closed.
    // Errors represent current dataset/editor validity and must stay alive
    // until the value is corrected, post/cancel succeeds, or the next dataset
    // operation explicitly clears/replaces them. Clearing here made immediate
    // validation non-blocking after OK was pressed.

    final focusEditor = _focusActiveEditorAfterGridErrorDialog;
    _focusActiveEditorAfterGridErrorDialog = false;
    if (focusEditor && _activeCellEditorState != null) {
      _activeCellEditorState?.requestTextFocus();
    } else {
      _focusGridForSelectedCell();
    }
  }

  bool _ensureDataSetEditForField(
    int rowIndex,
    String fieldName, {
    bool focusActiveEditorAfterDialog = false,
  }) {
    if (_isEmptyInsertGridRowIndex(rowIndex)) {
      if (!widget.dataSet.hasField(fieldName)) {
        return false;
      }
      final appendedRowIndex = _appendDataSetRow();
      if (appendedRowIndex < 0) {
        return false;
      }
    }

    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null ||
        sourceIndex < 0 ||
        sourceIndex >= widget.dataSet.recordCount ||
        !widget.dataSet.hasField(fieldName)) {
      return false;
    }

    if (widget.dataSet.state == FdcDataSetState.insert) {
      if (FdcDataSetInternal.activeIndex(widget.dataSet) != sourceIndex) {
        _syncInteractionState();
        _showGridOperationErrorsIfNeeded(
          focusActiveEditorAfterDialog: focusActiveEditorAfterDialog,
        );
        return false;
      }
      return true;
    }

    _updatingDataSetFromGrid = true;
    try {
      if (FdcDataSetInternal.activeIndex(widget.dataSet) != sourceIndex) {
        FdcDataSetInternal.moveToIndex(widget.dataSet, sourceIndex);
      }

      if (FdcDataSetInternal.activeIndex(widget.dataSet) != sourceIndex) {
        _syncInteractionState();
        _showGridOperationErrorsIfNeeded(
          focusActiveEditorAfterDialog: focusActiveEditorAfterDialog,
        );
        return false;
      }

      if (widget.dataSet.state != FdcDataSetState.edit) {
        widget.dataSet.edit();
      }

      if (widget.dataSet.state != FdcDataSetState.edit &&
          widget.dataSet.state != FdcDataSetState.insert) {
        _syncInteractionState();
        _showGridOperationErrorsIfNeeded(
          focusActiveEditorAfterDialog: focusActiveEditorAfterDialog,
        );
        return false;
      }

      return true;
    } on Object catch (error, stackTrace) {
      unawaited(_handleDataSetPostError(error, stackTrace));
      if (focusActiveEditorAfterDialog) {
        _focusActiveEditorAfterGridErrorDialog = true;
      }
      return false;
    } finally {
      _updatingDataSetFromGrid = false;
    }
  }

  bool _ensureDataSetEditForCell(
    int rowIndex,
    FdcGridColumn<dynamic> column, {
    bool focusActiveEditorAfterDialog = false,
  }) {
    if (_isEmptyInsertGridRowIndex(rowIndex)) {
      if (!widget.dataSet.hasField(column.fieldName)) {
        return false;
      }
      final appendedRowIndex = _appendDataSetRow();
      if (appendedRowIndex < 0) {
        return false;
      }
    }

    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null ||
        sourceIndex < 0 ||
        sourceIndex >= widget.dataSet.recordCount ||
        !widget.dataSet.hasField(column.fieldName)) {
      return false;
    }

    // While an insert/append buffer is active, the active edit record is the
    // only row that may continue editing. Do not blindly allow edits on a
    // different grid row: moving away from an invalid insert can fail and leave
    // the dataset current record unchanged, while the grid still tries to edit
    // the requested row.
    if (widget.dataSet.state == FdcDataSetState.insert) {
      if (FdcDataSetInternal.activeIndex(widget.dataSet) != sourceIndex) {
        _syncInteractionState();
        _showGridOperationErrorsIfNeeded(
          focusActiveEditorAfterDialog: focusActiveEditorAfterDialog,
        );
        return false;
      }
      return true;
    }

    _updatingDataSetFromGrid = true;
    try {
      if (FdcDataSetInternal.activeIndex(widget.dataSet) != sourceIndex) {
        FdcDataSetInternal.moveToIndex(widget.dataSet, sourceIndex);
      }

      if (FdcDataSetInternal.activeIndex(widget.dataSet) != sourceIndex) {
        _syncInteractionState();
        _showGridOperationErrorsIfNeeded(
          focusActiveEditorAfterDialog: focusActiveEditorAfterDialog,
        );
        return false;
      }

      if (widget.dataSet.state != FdcDataSetState.edit) {
        widget.dataSet.edit();
      }

      if (widget.dataSet.state != FdcDataSetState.edit &&
          widget.dataSet.state != FdcDataSetState.insert) {
        _syncInteractionState();
        _showGridOperationErrorsIfNeeded(
          focusActiveEditorAfterDialog: focusActiveEditorAfterDialog,
        );
        return false;
      }

      return true;
    } on Object catch (error, stackTrace) {
      unawaited(_handleDataSetPostError(error, stackTrace));
      if (focusActiveEditorAfterDialog) {
        _focusActiveEditorAfterGridErrorDialog = true;
      }
      return false;
    } finally {
      _updatingDataSetFromGrid = false;
    }
  }

  Object? _dataSetValueAt(int rowIndex, FdcGridColumn<dynamic> column) {
    if (!column.isDataBound) {
      return null;
    }
    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null ||
        sourceIndex < 0 ||
        sourceIndex >= widget.dataSet.recordCount) {
      return null;
    }

    try {
      return FdcDataSetInternal.fieldValueAt(
        widget.dataSet,
        sourceIndex,
        column.fieldName,
      );
      // ignore: avoid_catching_errors
    } on RangeError {
      return null;
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return null;
    }
  }

  Object? _dataSetFieldValueAt(int rowIndex, String fieldName) {
    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null ||
        sourceIndex < 0 ||
        sourceIndex >= widget.dataSet.recordCount) {
      return null;
    }

    try {
      return FdcDataSetInternal.fieldValueAt(
        widget.dataSet,
        sourceIndex,
        fieldName,
      );
      // ignore: avoid_catching_errors
    } on RangeError {
      return null;
      // ignore: avoid_catching_errors
    } on ArgumentError {
      return null;
    }
  }

  FdcGridRowContext _gridRowAt(int rowIndex) {
    if (_isLiveGridRowIndex(rowIndex)) {
      return _rows[rowIndex];
    }

    return FdcGridTransientRow(
      rowIndex: rowIndex,
      fieldNames: _rows.fieldNames,
      valueResolver: (_) => null,
    );
  }

  void _emitDataSetFieldValidationByName(
    int rowIndex,
    String fieldName,
    Object? value,
  ) {
    final skipPristineInsert =
        widget.dataSet.state == FdcDataSetState.insert &&
        FdcDataSetInternal.isActiveInsertBufferUnmodified(widget.dataSet);
    if (skipPristineInsert) {
      return;
    }

    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null ||
        sourceIndex < 0 ||
        sourceIndex >= widget.dataSet.recordCount) {
      return;
    }

    try {
      _updatingDataSetFromGrid = true;
      if (FdcDataSetInternal.activeIndex(widget.dataSet) != sourceIndex) {
        FdcDataSetInternal.moveToIndex(widget.dataSet, sourceIndex);
      }

      FdcDataSetInternal.validateFieldValueAndEmit(
        widget.dataSet,
        fieldName,
        value,
      );
      // ignore: avoid_catching_errors
    } on ArgumentError {
      // Keep immediate validation non-blocking; post() will surface canonical
      // dataset validation failures through the normal operation path.
    } finally {
      _updatingDataSetFromGrid = false;
    }
  }

  void _emitDataSetFieldValidation(
    int rowIndex,
    FdcGridColumn<dynamic> column,
    Object? value,
  ) {
    final skipPristineInsert =
        widget.dataSet.state == FdcDataSetState.insert &&
        FdcDataSetInternal.isActiveInsertBufferUnmodified(widget.dataSet);
    if (skipPristineInsert) {
      return;
    }

    final sourceIndex = _sourceRowIndex(rowIndex);
    if (sourceIndex == null ||
        sourceIndex < 0 ||
        sourceIndex >= widget.dataSet.recordCount) {
      return;
    }

    try {
      _updatingDataSetFromGrid = true;
      if (FdcDataSetInternal.activeIndex(widget.dataSet) != sourceIndex) {
        FdcDataSetInternal.moveToIndex(widget.dataSet, sourceIndex);
      }

      // Field-level validation is intentionally non-blocking. The grid accepts
      // the edited value, emits onValidationError for application code, and
      // leaves modal presentation to the later grid-owned post() operation.
      FdcDataSetInternal.validateFieldValueAndEmit(
        widget.dataSet,
        column.fieldName,
        value,
      );
      // ignore: avoid_catching_errors
    } on ArgumentError {
      // The value has already been accepted into the dataset edit buffer. If a
      // later validation pass cannot normalize it, post() will surface the
      // dataset-level validation failure through the normal operation-owner
      // path. Do not show immediate validation dialogs here.
    } finally {
      _updatingDataSetFromGrid = false;
    }
  }

  int _insertDataSetRow() {
    _collapseAllDetailRowsImmediately();

    _updatingDataSetFromGrid = true;
    try {
      if (widget.dataSet.state == FdcDataSetState.edit ||
          widget.dataSet.state == FdcDataSetState.insert) {
        widget.dataSet.post();
        if (widget.dataSet.state == FdcDataSetState.edit ||
            widget.dataSet.state == FdcDataSetState.insert) {
          _restoreCellAfterFailedRowPost(
            FdcDataSetInternal.activeIndex(widget.dataSet),
          );
          if (widget.dataSet.errors.messages.isNotEmpty) {
            _showGridOperationErrorsIfNeeded(
              focusActiveEditorAfterDialog: true,
            );
          }
          return -1;
        }
      }

      widget.dataSet.insert();
      _lastObservedDataSetState = widget.dataSet.state;
      _lastObservedDataSetRecordCount = widget.dataSet.recordCount;

      if (widget.dataSet.state != FdcDataSetState.insert) {
        _setGridState(() {
          _editingCell = null;
          _editAtEndCell = null;
          _clearPendingEditText();
          _clearEditingOriginalValue();
          _syncGridSelectionFromDataSetCurrent();
        });
        if (widget.dataSet.errors.messages.isNotEmpty) {
          _showGridOperationErrorsIfNeeded();
        }
        return -1;
      }
    } on Object catch (error, stackTrace) {
      unawaited(_handleDataSetPostError(error, stackTrace));
      return -1;
    } finally {
      _updatingDataSetFromGrid = false;
    }

    _refreshRowsFromDataSet();
    _syncGridSelectionFromDataSetCurrent();
    return FdcDataSetInternal.activeIndex(widget.dataSet);
  }

  int _appendDataSetRow() {
    // Appending changes the row count and moves focus to the absolute end.
    // Collapse detail panels first so the end-positioning flow starts from a
    // stable, fixed row geometry.
    _collapseAllDetailRowsImmediately();

    _updatingDataSetFromGrid = true;
    try {
      if (widget.dataSet.state == FdcDataSetState.edit ||
          widget.dataSet.state == FdcDataSetState.insert) {
        widget.dataSet.post();
        if (widget.dataSet.state == FdcDataSetState.edit ||
            widget.dataSet.state == FdcDataSetState.insert) {
          _restoreCellAfterFailedRowPost(
            FdcDataSetInternal.activeIndex(widget.dataSet),
          );
          if (widget.dataSet.errors.messages.isNotEmpty) {
            _showGridOperationErrorsIfNeeded(
              focusActiveEditorAfterDialog: true,
            );
          }
          return -1;
        }
      }

      widget.dataSet.append();
      _lastObservedDataSetState = widget.dataSet.state;
      _lastObservedDataSetRecordCount = widget.dataSet.recordCount;

      if (widget.dataSet.state != FdcDataSetState.insert) {
        _setGridState(() {
          _editingCell = null;
          _editAtEndCell = null;
          _clearPendingEditText();
          _clearEditingOriginalValue();
          _syncGridSelectionFromDataSetCurrent();
        });
        if (widget.dataSet.errors.messages.isNotEmpty) {
          _showGridOperationErrorsIfNeeded();
        }
        return -1;
      }
    } on Object catch (error, stackTrace) {
      unawaited(_handleDataSetPostError(error, stackTrace));
      return -1;
    } finally {
      _updatingDataSetFromGrid = false;
    }

    _refreshRowsFromDataSet();
    _syncGridSelectionFromDataSetCurrent();
    return FdcDataSetInternal.activeIndex(widget.dataSet);
  }
}
