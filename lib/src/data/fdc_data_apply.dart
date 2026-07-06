// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_data_errors.dart';

/// Persistent operation represented by a change-set entry.
enum FdcDataApplyOperation {
  /// Insert option.
  insert,

  /// Update option.
  update,

  /// Delete option.
  delete,

  /// Apply updates option.
  applyUpdates,
}

/// Result returned by `IFdcDataAdapter.applyUpdates()`.
///
/// A result is either [FdcDataApplySuccess] or [FdcDataApplyFailure]. The
/// dataset uses it to confirm pending local state or restore rejected changes.
sealed class FdcDataApplyResult {
  /// Creates a [FdcDataApplyResult].
  factory FdcDataApplyResult({
    required bool success,
    Map<int, Object> insertedKeys = const <int, Object>{},
    Map<int, Map<String, Object?>> serverRows =
        const <int, Map<String, Object?>>{},
    List<FdcDataApplyError> errors = const <FdcDataApplyError>[],
  }) {
    if (success) {
      return FdcDataApplySuccess(
        insertedKeys: insertedKeys,
        serverRows: serverRows,
      );
    }
    return FdcDataApplyFailure(
      insertedKeys: insertedKeys,
      serverRows: serverRows,
      errors: errors,
    );
  }

  const FdcDataApplyResult._({
    required this.success,
    this.insertedKeys = const <int, Object>{},
    this.serverRows = const <int, Map<String, Object?>>{},
    this.errors = const <FdcDataApplyError>[],
  });

  const factory FdcDataApplyResult.success({
    Map<int, Object>? insertedKeys,
    Map<int, Map<String, Object?>>? serverRows,
  }) = FdcDataApplySuccess;

  const factory FdcDataApplyResult.failure({
    Map<int, Object>? insertedKeys,
    Map<int, Map<String, Object?>>? serverRows,
    List<FdcDataApplyError>? errors,
  }) = FdcDataApplyFailure;

  /// Whether the adapter accepted the complete apply request.
  final bool success;

  /// Backend-generated keys indexed by local record identifier.
  final Map<int, Object> insertedKeys;

  /// Backend-confirmed row values indexed by local record identifier.
  final Map<int, Map<String, Object?>> serverRows;

  /// Errors associated with this result.
  final List<FdcDataApplyError> errors;
}

/// Successful adapter apply result.
///
/// `updatedRows` may contain backend-confirmed values such as generated keys
/// or server-calculated columns that the dataset merges into local records.
final class FdcDataApplySuccess extends FdcDataApplyResult {
  /// Creates a [FdcDataApplySuccess].
  const FdcDataApplySuccess({
    Map<int, Object>? insertedKeys,
    Map<int, Map<String, Object?>>? serverRows,
  }) : super._(
         success: true,
         insertedKeys: insertedKeys ?? const <int, Object>{},
         serverRows: serverRows ?? const <int, Map<String, Object?>>{},
       );
}

/// Failed adapter apply result containing structured row-level errors.
///
/// The dataset preserves or restores rejected dirty state so callers can
/// correct values and retry or cancel the operation.
final class FdcDataApplyFailure extends FdcDataApplyResult {
  /// Creates a [FdcDataApplyFailure].
  const FdcDataApplyFailure({
    Map<int, Object>? insertedKeys,
    Map<int, Map<String, Object?>>? serverRows,
    List<FdcDataApplyError>? errors,
  }) : super._(
         success: false,
         insertedKeys: insertedKeys ?? const <int, Object>{},
         serverRows: serverRows ?? const <int, Map<String, Object?>>{},
         errors: errors ?? const <FdcDataApplyError>[],
       );
}
