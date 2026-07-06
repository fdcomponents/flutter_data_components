// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

// ignore_for_file: public_member_api_docs

import 'fdc_data_errors.dart';
import 'fdc_data_validation.dart';
import 'fdc_dataset_error_store.dart';

typedef FdcDataSetEmitValidationError =
    void Function(List<FdcValidationError> errors);

typedef FdcDataSetEmitError =
    void Function(List<FdcDataSetError> errors, {Object? cause});

/// Centralizes dataset error storage, conversion and event emission.
///
/// `FdcDataSet` remains the lifecycle orchestrator. This controller owns the
/// repetitive mechanics of translating validation/abort/unexpected failures
/// into [FdcDataSetError] entries and raising the user-facing error events.
class FdcDataSetErrorController {
  FdcDataSetErrorController({
    required FdcDataSetErrorStore store,
    required FdcDataSetEmitValidationError emitValidationError,
    required FdcDataSetEmitError emitError,
    required void Function() notifyListeners,
  }) : _store = store,
       _emitValidationError = emitValidationError,
       _emitError = emitError,
       _notifyListeners = notifyListeners;

  final FdcDataSetErrorStore _store;
  final FdcDataSetEmitValidationError _emitValidationError;
  final FdcDataSetEmitError _emitError;
  final void Function() _notifyListeners;

  T? runOperation<T>({
    required String operation,
    required T Function() body,
    int? recordId,
    bool notifyOnAbort = true,
    bool wrapUnexpected = true,
    bool preserveValidationException = false,
    void Function(FdcDataSetAbortException error)? beforeAbort,
    void Function(FdcDataSetException error)? beforeDataSetException,
    void Function(Object error)? beforeUnexpected,
  }) {
    assert(operation.isNotEmpty);
    try {
      return body();
    } on FdcDataSetAbortException catch (error) {
      beforeAbort?.call(error);
      handleAbortException(error, notify: notifyOnAbort);
      return null;
    } on FdcDataSetValidationException catch (error) {
      if (!preserveValidationException) {
        setValidationErrors(error.errors, notify: true);
      }
      rethrow;
    } on FdcDataAdapterException catch (error) {
      beforeDataSetException?.call(error);
      setErrors(
        error.errors,
        fallbackMessage: error.message,
        cause: error,
        notify: true,
      );
      rethrow;
    } on FdcDataSetException catch (error) {
      beforeDataSetException?.call(error);
      setErrors(
        error.errors,
        fallbackMessage: error.message,
        cause: error.cause ?? error,
        notify: true,
      );
      rethrow;
    } on Object catch (error) {
      beforeUnexpected?.call(error);
      if (!wrapUnexpected || _mustRethrowUnexpected(error)) {
        rethrow;
      }
      throw _wrapUnexpected(error, recordId: recordId);
    }
  }

  Future<T?> runOperationAsync<T>({
    required String operation,
    required Future<T> Function() body,
    required int Function() captureGeneration,
    required bool Function(int generation) isGenerationCurrent,
    int? recordId,
    bool notifyOnAbort = true,
    bool wrapUnexpected = true,
    bool preserveValidationException = false,
    void Function(FdcDataSetAbortException error)? beforeAbort,
    void Function(FdcDataSetException error)? beforeDataSetException,
    void Function(Object error)? beforeUnexpected,
  }) async {
    final generation = captureGeneration();
    assert(operation.isNotEmpty);
    try {
      final result = await body();
      return isGenerationCurrent(generation) ? result : null;
    } on FdcDataSetAbortException catch (error) {
      if (!isGenerationCurrent(generation)) return null;
      beforeAbort?.call(error);
      handleAbortException(error, notify: notifyOnAbort);
      return null;
    } on FdcDataSetValidationException catch (error) {
      if (!isGenerationCurrent(generation)) return null;
      if (!preserveValidationException) {
        setValidationErrors(error.errors, notify: true);
      }
      rethrow;
    } on FdcDataAdapterException catch (error) {
      if (!isGenerationCurrent(generation)) return null;
      beforeDataSetException?.call(error);
      setErrors(
        error.errors,
        fallbackMessage: error.message,
        cause: error,
        notify: true,
      );
      rethrow;
    } on FdcDataSetException catch (error) {
      if (!isGenerationCurrent(generation)) return null;
      beforeDataSetException?.call(error);
      setErrors(
        error.errors,
        fallbackMessage: error.message,
        cause: error.cause ?? error,
        notify: true,
      );
      rethrow;
    } on Object catch (error) {
      if (!isGenerationCurrent(generation)) return null;
      beforeUnexpected?.call(error);
      if (!wrapUnexpected || _mustRethrowUnexpected(error)) {
        rethrow;
      }
      throw _wrapUnexpected(error, recordId: recordId);
    }
  }

  bool _mustRethrowUnexpected(Object error) {
    return error is StateError && error.message.contains('Use open() instead');
  }

  FdcDataSetException _wrapUnexpected(Object error, {int? recordId}) {
    final dataSetError = unexpectedError(error: error, recordId: recordId);
    setErrors(<FdcDataSetError>[dataSetError], notify: true);
    return FdcDataSetException(
      message: dataSetError.message,
      errors: <FdcDataSetError>[dataSetError],
      cause: error,
    );
  }

  void clearErrors({required bool notify}) {
    if (_store.isEmpty) {
      return;
    }
    _store.clear();
    if (notify) {
      _notifyListeners();
    }
  }

  void clearFieldErrors(
    String fieldName, {
    int? recordId,
    required bool notify,
  }) {
    final removed = clearErrorsForField(fieldName, recordId: recordId);
    if (removed && notify) {
      _notifyListeners();
    }
  }

  void setValidationErrors(
    List<FdcValidationError> validationErrors, {
    required bool notify,
  }) {
    setErrors(<FdcDataSetError>[
      for (final error in validationErrors)
        fdcDataSetError(
          message: error.message,
          fieldName: error.fieldName,
          recordId: error.recordId,
          code: error.code,
        ),
    ], notify: notify);
    _emitValidationErrorIfAny(validationErrors);
  }

  void setFieldValidationErrors(
    String fieldName, {
    required int? recordId,
    required List<FdcValidationError> validationErrors,
    required bool notify,
  }) {
    var changed = clearErrorsForField(fieldName, recordId: recordId);

    if (validationErrors.isNotEmpty) {
      _store.addValidationErrors(validationErrors);
      changed = true;
    }

    if (validationErrors.isNotEmpty) {
      _emitValidationErrorIfAny(validationErrors);
      _emitErrorIfAny(_store.items);
    }

    if (changed && notify) {
      _notifyListeners();
    }
  }

  bool clearErrorsForField(String fieldName, {int? recordId}) {
    return _store.clearForField(fieldName, recordId: recordId);
  }

  void setErrors(
    List<FdcDataSetError> errors, {
    String? fallbackMessage,
    Object? cause,
    bool notify = false,
  }) {
    _store.replace(errors, fallbackMessage: fallbackMessage, cause: cause);
    if (_store.isNotEmpty) {
      _emitErrorIfAny(
        _store.items,
        cause: cause ?? _firstErrorCause(_store.items),
      );
    }

    if (notify) {
      _notifyListeners();
    }
  }

  void handleAbortException(
    FdcDataSetAbortException error, {
    bool notify = false,
  }) {
    if (error.isSilent) {
      final hadErrors = _store.isNotEmpty;
      _store.clear();
      if (notify && hadErrors) {
        _notifyListeners();
      }
      return;
    }

    setErrors(
      error.errors,
      fallbackMessage: error.message,
      cause: error.cause ?? error,
      notify: notify,
    );
  }

  FdcDataSetError unexpectedError({required Object error, int? recordId}) {
    return fdcDataSetError(
      recordId: recordId,
      message: exceptionMessage(error),
      cause: error,
    );
  }

  String exceptionMessage(Object error) {
    if (error is FdcDataSetException) {
      return error.message;
    }
    if (error is FdcDataSetValidationException) {
      return error.errors.map((item) => item.message).join('\n');
    }
    final text = error.toString();
    const exceptionPrefix = 'Exception: ';
    if (text.startsWith(exceptionPrefix)) {
      return text.substring(exceptionPrefix.length);
    }
    return text;
  }

  void _emitValidationErrorIfAny(List<FdcValidationError> validationErrors) {
    if (validationErrors.isEmpty) {
      return;
    }
    _emitValidationError(
      List<FdcValidationError>.unmodifiable(validationErrors),
    );
  }

  void _emitErrorIfAny(List<FdcDataSetError> errors, {Object? cause}) {
    if (errors.isEmpty) {
      return;
    }
    _emitError(List<FdcDataSetError>.unmodifiable(errors), cause: cause);
  }

  Object? _firstErrorCause(List<FdcDataSetError> errors) {
    for (final error in errors) {
      if (error.cause != null) {
        return error.cause;
      }
    }
    return null;
  }
}
