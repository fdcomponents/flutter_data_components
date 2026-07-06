// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

/// Structured error for a record rejected during adapter apply.
///
/// Errors may identify a record and field and carry a stable backend/application
/// code in addition to the user-facing [message].
class FdcDataApplyError {
  /// Creates a [FdcDataApplyError].
  const FdcDataApplyError({
    required this.recordId,
    required this.message,
    this.fieldName,
    this.code,
  });

  /// Internal record identifier.
  final int recordId;

  /// User-facing message text.
  final String message;

  /// Dataset field name associated with this object.
  final String? fieldName;

  /// Optional stable machine-readable error code.
  final String? code;
}

/// Read-only dataset error entry emitted by the dataset error pipeline.
///
/// Application code normally should not create this object directly. To abort a
/// lifecycle event, throw [FdcDataSetAbortException] with a message and optional
/// code/field context instead.
class FdcDataSetError {
  const FdcDataSetError._({
    required this.message,
    this.fieldName,
    this.recordId,
    this.code,
    this.cause,
  });

  /// User-facing message text.
  final String message;

  /// Dataset field name associated with this object.
  final String? fieldName;

  /// Internal record identifier.
  final int? recordId;

  /// Optional stable machine-readable error code.
  final String? code;

  /// Original exception or backend object that caused this error.
  final Object? cause;

  @override
  String toString() => message;
}

/// Internal factory used by dataset infrastructure.
///
/// This helper is intentionally hidden from the package barrel export so users
/// can read [FdcDataSetError] instances but do not construct them as part of the
/// normal public API.
FdcDataSetError fdcDataSetError({
  required String message,
  String? fieldName,
  int? recordId,
  String? code,
  Object? cause,
}) {
  return FdcDataSetError._(
    message: message,
    fieldName: fieldName,
    recordId: recordId,
    code: code,
    cause: cause,
  );
}

/// Base exception for dataset and adapter operation failures.
///
/// The exception keeps stable `operation` and `code` values plus a user-facing `message`
/// so UI and logging layers do not need to parse backend exception text.
class FdcDataSetException implements Exception {
  /// Creates a [FdcDataSetException].
  const FdcDataSetException({
    required this.message,
    this.errors = const <FdcDataSetError>[],
    this.cause,
  });

  /// User-facing message text.
  final String message;

  /// Errors associated with this result.
  final List<FdcDataSetError> errors;

  /// Original exception or backend object that caused this error.
  final Object? cause;

  @override
  String toString() {
    if (errors.isEmpty) {
      return message;
    }

    final errorText = errors.map((error) => error.message).join('; ');
    if (message.isEmpty) {
      return errorText;
    }

    return '$message: $errorText';
  }
}

/// Canonical exception raised at the adapter/dataset boundary.
///
/// Adapters may throw this directly to preserve backend-specific context. The
/// dataset also wraps plain adapter/backend exceptions into this type before
/// storing or emitting user-visible errors, so grids/editors/custom UI can
/// handle adapter failures uniformly without knowing the concrete adapter.
class FdcDataAdapterException extends FdcDataSetException {
  /// Creates a [FdcDataAdapterException].
  FdcDataAdapterException({
    required super.message,
    this.operation,
    this.recordId,
    this.fieldName,
    this.code,
    this.details,
    this.stackTrace,
    super.cause,
  }) : super(
         errors: message.isEmpty
             ? const <FdcDataSetError>[]
             : <FdcDataSetError>[
                 fdcDataSetError(
                   message: message,
                   fieldName: fieldName,
                   recordId: recordId,
                   code: code,
                   cause: cause,
                 ),
               ],
       );

  /// Dataset/adapter operation that failed, for diagnostics.
  final String? operation;

  /// Dataset record id related to the failure, when known.
  final int? recordId;

  /// Field related to the failure, when known.
  final String? fieldName;

  /// Stable backend/FDC error code, when available.
  final String? code;

  /// Optional backend-specific diagnostic payload.
  final Object? details;

  /// Original stack trace captured at the adapter boundary, when available.
  final StackTrace? stackTrace;
}

/// Returns a user-facing message for an adapter-layer [error].
String fdcAdapterExceptionMessage(Object error) {
  if (error is FdcDataSetException) {
    return error.message;
  }
  final text = error.toString();
  const exceptionPrefix = 'Exception: ';
  if (text.startsWith(exceptionPrefix)) {
    return text.substring(exceptionPrefix.length);
  }
  const stateErrorPrefix = 'Bad state: ';
  if (text.startsWith(stateErrorPrefix)) {
    return text.substring(stateErrorPrefix.length);
  }
  return text;
}

/// Normalizes an arbitrary adapter failure to [FdcDataAdapterException].
FdcDataAdapterException fdcNormalizeAdapterException(
  Object error, {
  required String operation,
  int? recordId,
  String? fieldName,
  String? code,
  Object? details,
  StackTrace? stackTrace,
}) {
  if (error is FdcDataAdapterException) {
    return error;
  }

  if (error is FdcDataSetException && error.errors.isNotEmpty) {
    final first = error.errors.first;
    return FdcDataAdapterException(
      operation: operation,
      recordId: recordId ?? first.recordId,
      fieldName: fieldName ?? first.fieldName,
      code: code ?? first.code,
      message: first.message,
      details: details,
      cause: error.cause ?? error,
      stackTrace: stackTrace,
    );
  }

  return FdcDataAdapterException(
    operation: operation,
    recordId: recordId,
    fieldName: fieldName,
    code: code ?? 'adapter_error',
    message: fdcAdapterExceptionMessage(error),
    details: details,
    cause: error,
    stackTrace: stackTrace,
  );
}

/// Signals an intentional cancellation of the current dataset operation.
///
/// This is distinct from an adapter or validation failure and is used to stop
/// lifecycle work without reporting a backend error.
class FdcDataSetAbortException extends FdcDataSetException {
  /// Creates a [FdcDataSetAbortException].
  FdcDataSetAbortException(
    String message, {
    String? fieldName,
    String? code,
    super.cause,
  }) : super(
         message: message,
         errors: message.isEmpty
             ? const <FdcDataSetError>[]
             : <FdcDataSetError>[
                 fdcDataSetError(
                   message: message,
                   fieldName: fieldName,
                   code: code,
                   cause: cause,
                 ),
               ],
       );

  /// Creates a [FdcDataSetAbortException].
  const FdcDataSetAbortException.silent()
    : super(message: '', errors: const <FdcDataSetError>[]);

  /// True when the abort carries no message and no structured errors.
  ///
  /// Silent aborts stop the current dataset operation without presenting an
  /// application-facing validation or error message.
  bool get isSilent => errors.isEmpty && message.isEmpty;

  /// True when the abort contains content suitable for application error UI.
  ///
  /// This is the inverse of [isSilent]: either a non-empty message or at least
  /// one structured dataset error makes the abort displayable.
  bool get hasDisplayError => !isSilent;
}
