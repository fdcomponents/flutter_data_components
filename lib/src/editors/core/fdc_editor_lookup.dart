// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import '../../common/lookup/fdc_lookup_context.dart';
import '../../common/lookup/fdc_lookup_result.dart';

/// Asynchronous lookup callback for a standalone data-aware editor.
///
/// Return an [FdcLookupResult] to apply its field values. Return `null` to
/// cancel the lookup without changing the dataset.
typedef FdcEditorLookup<T> =
    Future<FdcLookupResult?> Function(FdcLookupContext context);
