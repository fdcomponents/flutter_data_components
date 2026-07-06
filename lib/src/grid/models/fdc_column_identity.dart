// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:meta/meta.dart';

/// Internal identity assigned by a concrete grid instance to a resolved grid
/// column.
///
/// This is intentionally separate from `FdcGridColumn.id`. The public column id
/// is developer-defined semantic input; `FdcColumnIdentity` is the grid-owned
/// runtime key used for layout/state maps after identity resolution.
///
/// This type is not part of the stable public API. Do not import or construct it
/// from application code.
@internal
@immutable
final class FdcColumnIdentity {
  const FdcColumnIdentity(this.value);

  final int value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FdcColumnIdentity && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'FdcColumnIdentity($value)';
}
