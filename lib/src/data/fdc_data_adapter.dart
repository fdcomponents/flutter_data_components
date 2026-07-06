// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'fdc_change_set.dart';
import 'fdc_data_adapter_capabilities.dart';
import 'fdc_data_adapter_filter.dart';
import 'fdc_data_aggregate.dart';
import 'fdc_data_apply.dart';
import 'fdc_data_errors.dart';
import 'fdc_data_load.dart';
import 'fdc_field_def.dart';

export 'fdc_data_adapter_capabilities.dart';
export 'fdc_data_adapter_filter.dart';
export 'fdc_data_aggregate.dart';
export 'fdc_data_apply.dart';
export 'fdc_data_load.dart';

/// Contract between an `FdcDataSet` and an external data source.
///
/// Implementations provide query/open behavior and may optionally support
/// applying changes and calculating server-side aggregates.
abstract class FdcDataAdapter implements IFdcDataAdapter {
  /// Creates a [FdcDataAdapter].
  const FdcDataAdapter({
    required this.readOnly,
    this.filters = const <FdcDataAdapterFilter>[],
    this.sorts = const <FdcDataAdapterSort>[],
    FdcDataAdapterCapabilities capabilities =
        const FdcDataAdapterCapabilities.none(),
  }) : _capabilities = capabilities;

  @override
  final bool readOnly;

  /// Source-level filters that are always applied by datasets using this
  /// adapter.
  ///
  /// These filters are combined with dataset/grid filters using AND semantics.
  /// UI clear-filter actions do not remove them.
  final List<FdcDataAdapterFilter> filters;

  /// Default source-level ordering used when the dataset/grid has no active
  /// user sort.
  ///
  /// UI clear-sort actions return to this ordering.
  final List<FdcDataAdapterSort> sorts;

  final FdcDataAdapterCapabilities _capabilities;

  @override
  FdcDataAdapterCapabilities get capabilities => _capabilities;

  /// Calculates adapter-side aggregates over the full effective adapter result
  /// set. Subclasses that support aggregate queries override this and expose
  /// `capabilities.aggregates == true`.
  @override
  Future<FdcDataAggregateResult> aggregate(
    FdcDataAggregateRequest request,
  ) async {
    throw FdcDataAdapterException(
      operation: 'aggregate',
      code: 'unsupported_adapter_operation',
      message: '$runtimeType does not support aggregate queries.',
    );
  }

  @override
  FdcDataApplyError mapApplyException(
    FdcChangeSetEntry entry,
    Object error, {
    required FdcDataApplyOperation operation,
  }) {
    return FdcDataApplyError(
      recordId: entry.recordId,
      message: '${operation.name} failed: $error',
      code: 'adapter_error',
    );
  }

  @override
  String? validateStorageValue(FdcFieldDef field, Object? value) => null;

  /// Releases adapter-owned resources.
  ///
  /// Most adapters do not own external resources. Worker-backed adapters use
  /// this hook to stop background isolates when their dataset is disposed.
  void dispose() {}
}

/// Adapter contract for sources that can execute an immediate synchronous load.
///
/// This is intentionally separate from [IFdcDataAdapter] so async-only adapters
/// do not need to provide a fake synchronous implementation. The dataset uses
/// this contract for local, unpaged memory-backed opens where preserving the
/// synchronous path avoids an extra async lifecycle hop.
abstract interface class IFdcSynchronousDataAdapter implements IFdcDataAdapter {
  /// Loads data synchronously for adapters that support an immediate path.
  FdcDataLoadResult loadSync(FdcDataLoadRequest request);
}

/// Contract implemented by dataset data adapters.
abstract interface class IFdcDataAdapter {
  /// Whether this adapter exposes a non-committable data source.
  ///
  /// Datasets derive their dataset-level read-only state from this capability.
  /// Writable adapters should return `false`; query/view adapters and other
  /// sources that cannot apply changes should return `true`.
  bool get readOnly;

  /// Adapter-side operation capabilities.
  ///
  /// Datasets validate adapter load requests against these capabilities before
  /// calling [load], so custom adapters that implement [IFdcDataAdapter]
  /// directly must declare the operations they support.
  FdcDataAdapterCapabilities get capabilities;

  /// Loads rows for the supplied [request].
  Future<FdcDataLoadResult> load(FdcDataLoadRequest request);

  /// Calculates adapter-side aggregates over the full effective adapter result
  /// set. The request uses filter/search criteria but never includes paging
  /// limits. Adapters that do not support aggregates should expose
  /// `capabilities.aggregates == false`; [FdcDataAdapter] provides a default
  /// unsupported implementation for subclass-based adapters.
  Future<FdcDataAggregateResult> aggregate(FdcDataAggregateRequest request);

  /// Applies a dataset change set to the backend.
  ///
  /// All adapters use backend-confirmed immediate semantics. In immediate
  /// update mode, the dataset may complete the local post/delete transition
  /// before this asynchronous backend call finishes, but it keeps the posted
  /// edit/insert/delete state recoverable until the apply result is confirmed.
  /// If the adapter returns errors or throws, the dataset normalizes the
  /// failure, restores the rejected dirty state when needed, and emits the
  /// canonical dataset error event.
  Future<FdcDataApplyResult> applyUpdates(FdcChangeSet changes);

  /// Converts an adapter/backend exception raised while applying one change
  /// entry into a structured row-level apply error.
  ///
  /// [FdcDataAdapter] provides a generic `adapter_error` implementation.
  /// Writable adapters should override it only to preserve backend-specific
  /// diagnostics such as SQL/constraint error codes. The dataset uses the
  /// returned error to populate dataset errors and UI components such as grids
  /// can present it without knowing the backend type.
  FdcDataApplyError mapApplyException(
    FdcChangeSetEntry entry,
    Object error, {
    required FdcDataApplyOperation operation,
  });

  /// Validates a value against adapter/storage-level constraints.
  ///
  /// Dataset field definitions remain storage-agnostic. Writable storage adapters
  /// can reject values that cannot be represented by their backend, such as
  /// SQLite INTEGER values outside signed 64-bit storage. Adapters with no
  /// additional storage constraints can inherit the null-returning default
  /// from [FdcDataAdapter].
  String? validateStorageValue(FdcFieldDef field, Object? value);
}
