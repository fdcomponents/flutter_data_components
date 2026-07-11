import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/models/fdc_column_identity.dart';
import 'package:flutter_data_components/src/grid/models/fdc_grid_layout_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stretched last column marks its trailing edge as projected', () {
    const column = FdcTextColumn<dynamic>(fieldName: 'name', width: 120);
    const runtimeColumnId = FdcColumnIdentity(1);
    const band = FdcGridColumnBand(
      columns: <FdcGridColumn<dynamic>>[column],
      runtimeColumnIds: <FdcColumnIdentity>[runtimeColumnId],
      columnIndexes: <int>[0],
      columnSignature: '1',
    );
    const layout = FdcGridColumnBandLayout(
      band: band,
      geometries: <FdcGridColumnGeometry>[
        FdcGridColumnGeometry(
          runtimeColumnId: runtimeColumnId,
          column: column,
          sourceColumnIndex: 0,
          localColumnIndex: 0,
          width: 120,
          offset: 0,
          visible: true,
        ),
      ],
      columnWidths: <double>[120],
      columnOffsets: <double>[0],
      width: 120,
      resizeTargetLocalColumnIndexes: <int?>[0],
      resizeTargetColumns: <FdcGridColumn<dynamic>?>[column],
      resizeTargetRuntimeColumnIds: <FdcColumnIdentity?>[runtimeColumnId],
      resizeTargetColumnIndexes: <int?>[0],
      resizeDeltaFactors: <double>[1],
    );

    final stretched = layout.stretchLastColumnToWidth(240);

    expect(stretched.width, 240);
    expect(stretched.columnWidths, const <double>[240]);
    expect(stretched.stretchesLastColumn, isTrue);
    expect(layout.stretchesLastColumn, isFalse);
  });

  test('non-stretched layout keeps normal trailing edge behavior', () {
    expect(
      FdcGridColumnBandLayout.empty
          .stretchLastColumnToWidth(240)
          .stretchesLastColumn,
      isFalse,
    );
  });
  test('action column is never used as trailing stretch filler', () {
    const dataColumn = FdcTextColumn<dynamic>(fieldName: 'name', width: 120);
    const actionColumn = FdcActionColumn(
      actions: <FdcRowAction>[FdcRowAction.delete()],
    );
    const dataId = FdcColumnIdentity(1);
    const actionId = FdcColumnIdentity(2);
    const band = FdcGridColumnBand(
      columns: <FdcGridColumn<dynamic>>[dataColumn, actionColumn],
      runtimeColumnIds: <FdcColumnIdentity>[dataId, actionId],
      columnIndexes: <int>[0, 1],
      columnSignature: '1,2',
    );
    const layout = FdcGridColumnBandLayout(
      band: band,
      geometries: <FdcGridColumnGeometry>[
        FdcGridColumnGeometry(
          runtimeColumnId: dataId,
          column: dataColumn,
          sourceColumnIndex: 0,
          localColumnIndex: 0,
          width: 120,
          offset: 0,
          visible: true,
        ),
        FdcGridColumnGeometry(
          runtimeColumnId: actionId,
          column: actionColumn,
          sourceColumnIndex: 1,
          localColumnIndex: 1,
          width: 40,
          offset: 120,
          visible: true,
        ),
      ],
      columnWidths: <double>[120, 40],
      columnOffsets: <double>[0, 120],
      width: 160,
      resizeTargetLocalColumnIndexes: <int?>[0, null],
      resizeTargetColumns: <FdcGridColumn<dynamic>?>[dataColumn, null],
      resizeTargetRuntimeColumnIds: <FdcColumnIdentity?>[dataId, null],
      resizeTargetColumnIndexes: <int?>[0, null],
      resizeDeltaFactors: <double>[1, 1],
    );

    final stretched = layout.stretchLastColumnToWidth(260);

    expect(stretched.width, 260);
    expect(stretched.columnWidths, const <double>[220, 40]);
    expect(stretched.geometries.last.width, 40);
  });
}
