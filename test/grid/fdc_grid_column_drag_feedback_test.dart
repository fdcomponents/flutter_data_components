// Copyright (c) 2026, FD Components
// https://fdcomponents.com
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:flutter_data_components/src/grid/widgets/fdc_grid_header_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('column drag feedback snaps to the pointer origin', () {
    expect(FdcGridHeaderMetrics.columnDragFeedbackOffset, Offset.zero);
  });

  test('column drag feedback is not vertically locked', () {
    final source = File(
      'lib/src/grid/widgets/fdc_grid_header_label.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('axis: Axis.horizontal')));
  });
  test('column drag target spans the complete grid viewport', () {
    final source = File(
      'lib/src/grid/runtime/core/fdc_grid_view_builder_runtime.dart',
    ).readAsStringSync();

    expect(source, contains('return DragTarget<int>('));
    expect(source, contains('_columnDragTargetAtViewportX'));
    expect(source, contains('renderBox.globalToLocal(details.offset)'));
  });
}
