// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@internal
class FdcFocusTraversal {
  const FdcFocusTraversal._();

  static Widget wrap({required Widget child, required int? focusOrder}) {
    if (focusOrder == null) {
      return child;
    }

    return FocusTraversalOrder(
      order: NumericFocusOrder(focusOrder.toDouble()),
      child: child,
    );
  }
}
