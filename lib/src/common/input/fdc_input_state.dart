// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';

@internal
class FdcInputState {
  const FdcInputState({required this.enabled, required this.readOnly});

  final bool enabled;
  final bool readOnly;

  bool get canEdit => enabled && !readOnly;
}
