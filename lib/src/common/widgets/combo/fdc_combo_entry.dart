// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/foundation.dart';

import '../../fdc_option.dart';

@internal
class FdcComboEntry<T> {
  const FdcComboEntry({required this.index, required this.option});

  final int index;
  final FdcOption<T> option;
}
