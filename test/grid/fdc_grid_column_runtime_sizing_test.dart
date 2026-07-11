import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/managers/fdc_grid_column_sizing_manager.dart';
import 'package:flutter_data_components/src/grid/models/fdc_column_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcGridColumnSizingManager runtime sizing', () {
    test(
      'keeps resized widths attached to runtime column ids after reorder',
      () {
        final manager = FdcGridColumnSizingManager();
        final columns = <FdcGridColumn<dynamic>>[
          const FdcTextColumn<dynamic>(fieldName: 'a', width: 100),
          const FdcTextColumn<dynamic>(fieldName: 'b', width: 120),
          const FdcTextColumn<dynamic>(fieldName: 'c', width: 140),
        ];
        final runtimeColumnIds = <FdcColumnIdentity>[
          const FdcColumnIdentity(1),
          const FdcColumnIdentity(2),
          const FdcColumnIdentity(3),
        ];

        manager.setColumnWidth(
          const FdcColumnIdentity(2),
          columns[1],
          180,
          columns: columns,
          runtimeColumnIds: runtimeColumnIds,
          defaultColumnWidth: 90,
        );

        final reorderedColumns = <FdcGridColumn<dynamic>>[
          columns[1],
          columns[0],
          columns[2],
        ];
        final reorderedIds = <FdcColumnIdentity>[
          const FdcColumnIdentity(2),
          const FdcColumnIdentity(1),
          const FdcColumnIdentity(3),
        ];
        manager.syncRuntimeColumns(
          columns: reorderedColumns,
          runtimeColumnIds: reorderedIds,
          defaultColumnWidth: 90,
        );

        final snapshot = manager.buildRuntimeColumnSnapshot(
          columns: reorderedColumns,
          runtimeColumnIds: reorderedIds,
          defaultColumnWidth: 90,
        );

        expect(
          snapshot.metrics.map((metric) => metric.runtimeColumnId),
          orderedEquals(<FdcColumnIdentity>[
            const FdcColumnIdentity(2),
            const FdcColumnIdentity(1),
            const FdcColumnIdentity(3),
          ]),
        );
        expect(
          snapshot.metrics.map((metric) => metric.width),
          orderedEquals(<double>[180, 100, 140]),
          reason:
              'Widths must follow runtime column identity, not visual index.',
        );
      },
    );

    test(
      'keeps duplicate field-bound column widths independent after reorder',
      () {
        final manager = FdcGridColumnSizingManager();
        final columns = <FdcGridColumn<dynamic>>[
          const FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name A'),
          const FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name B'),
        ];
        final runtimeColumnIds = <FdcColumnIdentity>[
          const FdcColumnIdentity(1),
          const FdcColumnIdentity(2),
        ];

        manager.setColumnWidth(
          const FdcColumnIdentity(1),
          columns[0],
          80,
          columns: columns,
          runtimeColumnIds: runtimeColumnIds,
          defaultColumnWidth: 140,
        );
        manager.setColumnWidth(
          const FdcColumnIdentity(2),
          columns[1],
          180,
          columns: columns,
          runtimeColumnIds: runtimeColumnIds,
          defaultColumnWidth: 140,
        );

        final reorderedColumns = <FdcGridColumn<dynamic>>[
          columns[1],
          columns[0],
        ];
        final reorderedIds = <FdcColumnIdentity>[
          const FdcColumnIdentity(2),
          const FdcColumnIdentity(1),
        ];
        manager.syncRuntimeColumns(
          columns: reorderedColumns,
          runtimeColumnIds: reorderedIds,
          defaultColumnWidth: 140,
        );

        final snapshot = manager.buildRuntimeColumnSnapshot(
          columns: reorderedColumns,
          runtimeColumnIds: reorderedIds,
          defaultColumnWidth: 140,
        );

        expect(
          snapshot.metrics.map((metric) => metric.runtimeColumnId),
          orderedEquals(<FdcColumnIdentity>[
            const FdcColumnIdentity(2),
            const FdcColumnIdentity(1),
          ]),
        );
        expect(
          snapshot.metrics.map((metric) => metric.width),
          orderedEquals(<double>[180, 80]),
          reason:
              'Duplicate field-bound columns cannot use fieldName/index as width identity.',
        );
      },
    );
  });
}
