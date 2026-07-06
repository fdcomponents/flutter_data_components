// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';

/// Lookup invocation mode.
///
/// [search] is used when the user explicitly asks for lookup UI, such as the
/// lookup button or lookup shortcut. [resolve] is used when the user commits an
/// entered value and the callback is expected to resolve it silently.
enum FdcLookupMode {
  /// Explicit user request for interactive lookup or search UI.
  search,

  /// Silent resolution of an entered value during commit.
  resolve,
}

/// Result returned by grid and standalone editor lookup callbacks.
///
/// Returning `null` from a lookup callback cancels the lookup. Returning an
/// [FdcLookupResult] applies the supplied dataset field values as one logical
/// lookup write set.
@immutable
class FdcLookupResult {
  /// Creates a [FdcLookupResult].
  const FdcLookupResult(this.values);

  /// Dataset field values to write when the lookup is accepted.
  ///
  /// Keys are dataset field names. Values may include the field that invoked
  /// the lookup and any same-record sibling fields that should be updated by
  /// the lookup workflow.
  final Map<String, Object?> values;
}
