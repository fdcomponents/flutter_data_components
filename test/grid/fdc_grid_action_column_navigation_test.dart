import 'package:flutter/widgets.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/managers/fdc_grid_navigation_manager.dart';
import 'package:flutter_data_components/src/grid/models/fdc_column_identity.dart';
import 'package:flutter_data_components/src/grid/models/fdc_grid_cell_ref.dart';
import 'package:flutter_data_components/src/grid/models/fdc_grid_layout_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('action columns are skipped by keyboard navigation order', () {
    final manager = FdcGridNavigationManager();
    const columns = <FdcGridColumn<dynamic>>[
      FdcTextColumn<dynamic>(fieldName: 'code'),
      FdcActionColumn(
        actions: <FdcRowAction>[FdcRowAction.delete()],
        tabStop: true,
        focusOrder: -100,
      ),
      FdcTextColumn<dynamic>(fieldName: 'name'),
    ];
    const identities = <FdcColumnIdentity>[
      FdcColumnIdentity(1),
      FdcColumnIdentity(2),
      FdcColumnIdentity(3),
    ];
    final bands = FdcGridColumnBands.fromVisibleColumns(
      columns: columns,
      runtimeColumnIds: identities,
      textDirection: TextDirection.ltr,
    );

    expect(manager.visualColumnIndexes(columns: columns, bands: bands), <int>[
      0,
      2,
    ]);
    expect(
      manager.tabTraversalColumnIndexes(columns: columns, bands: bands),
      <int>[0, 2],
    );
    expect(
      manager.adjacentColumnIndex(
        columnOrder: manager.visualColumnIndexes(
          columns: columns,
          bands: bands,
        ),
        fromColumnIndex: 0,
        columnOffset: 1,
      ),
      2,
    );
    expect(
      manager.adjacentColumnIndex(
        columnOrder: manager.visualColumnIndexes(
          columns: columns,
          bands: bands,
        ),
        fromColumnIndex: 1,
        columnOffset: 1,
      ),
      2,
    );
    expect(
      manager.adjacentColumnIndex(
        columnOrder: manager.visualColumnIndexes(
          columns: columns,
          bands: bands,
        ),
        fromColumnIndex: 1,
        columnOffset: -1,
      ),
      0,
    );
  });

  test('logical pin bands resolve to physical sides in RTL', () {
    const columns = <FdcGridColumn<dynamic>>[
      FdcTextColumn<dynamic>(fieldName: 'start', pin: FdcGridColumnPin.start),
      FdcTextColumn<dynamic>(fieldName: 'center'),
      FdcTextColumn<dynamic>(fieldName: 'end', pin: FdcGridColumnPin.end),
    ];
    const identities = <FdcColumnIdentity>[
      FdcColumnIdentity(1),
      FdcColumnIdentity(2),
      FdcColumnIdentity(3),
    ];

    final ltr = FdcGridColumnBands.fromVisibleColumns(
      columns: columns,
      runtimeColumnIds: identities,
      textDirection: TextDirection.ltr,
    );
    final rtl = FdcGridColumnBands.fromVisibleColumns(
      columns: columns,
      runtimeColumnIds: identities,
      textDirection: TextDirection.rtl,
    );

    expect(ltr.pinnedLeft.columns.single.fieldName, 'start');
    expect(ltr.pinnedRight.columns.single.fieldName, 'end');
    expect(rtl.pinnedLeft.columns.single.fieldName, 'end');
    expect(rtl.pinnedRight.columns.single.fieldName, 'start');
  });

  test(
    'vertical keyboard navigation moves away from selected action column',
    () {
      final manager = FdcGridNavigationManager();
      const columns = <FdcGridColumn<dynamic>>[
        FdcTextColumn<dynamic>(fieldName: 'code'),
        FdcActionColumn(actions: <FdcRowAction>[FdcRowAction.delete()]),
        FdcTextColumn<dynamic>(fieldName: 'name'),
      ];

      final down = manager.findVerticalCell(
        rowOffset: 1,
        rowCount: 3,
        columns: columns,
        editingCell: null,
        selectedCell: const FdcGridCellRef(0, 1),
      );
      final page = manager.findPageCell(
        rowOffset: 2,
        rowCount: 3,
        columns: columns,
        editingCell: null,
        selectedCell: const FdcGridCellRef(0, 1),
      );

      expect(down, const FdcGridCellRef(1, 0));
      expect(page, const FdcGridCellRef(2, 0));
    },
  );
}
