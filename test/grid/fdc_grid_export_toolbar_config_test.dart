import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('built-in toolbar menu and export defaults use start placement', () {
    const mainMenuButton = FdcGridMainMenuButton();
    const exportButton = FdcGridExportButton();

    expect(mainMenuButton.placement, FdcGridItemPlacement.start);
    expect(mainMenuButton.tooltip, 'Main menu');
    expect(exportButton.placement, FdcGridItemPlacement.start);
    expect(exportButton.tooltip, 'Export');
  });

  test('grid columns are exportable by default and can opt out', () {
    const defaultColumn = FdcTextColumn<dynamic>(fieldName: 'name');
    const excludedColumn = FdcTextColumn<dynamic>(
      fieldName: 'internal_note',
      exportable: false,
    );
    const actionColumn = FdcActionColumn(actions: <FdcRowAction>[]);

    expect(defaultColumn.exportable, isTrue);
    expect(excludedColumn.exportable, isFalse);
    expect(actionColumn.exportable, isFalse);
  });

  test('FdcGridExportButton behaves as a value object', () {
    void onExport(FdcExportResult result) {}

    final left = FdcGridExportButton(
      visible: true,
      placement: FdcGridItemPlacement.center,
      formats: const <FdcExportFormat>[FdcExportFormat.csv],
      scope: FdcExportScope.selectedRows,
      valueMode: FdcExportValueMode.display,
      columnMode: FdcGridExportColumnMode.dataSetFields,
      includeHeaders: false,
      includeNonPersistentFields: true,
      label: 'Export',
      tooltip: 'Export data',
      onExport: onExport,
    );
    final right = FdcGridExportButton(
      visible: true,
      placement: FdcGridItemPlacement.center,
      formats: const <FdcExportFormat>[FdcExportFormat.csv],
      scope: FdcExportScope.selectedRows,
      valueMode: FdcExportValueMode.display,
      columnMode: FdcGridExportColumnMode.dataSetFields,
      includeHeaders: false,
      includeNonPersistentFields: true,
      label: 'Export',
      tooltip: 'Export data',
      onExport: onExport,
    );

    expect(left, right);
    expect(left.hashCode, right.hashCode);
    expect(
      left.toExportOptions(),
      FdcExportOptions(
        scope: FdcExportScope.selectedRows,
        valueMode: FdcExportValueMode.display,
        includeHeaders: false,
        includeNonPersistentFields: true,
      ),
    );
  });

  test('FdcGridExportButton passes visible grid columns to export options', () {
    const columns = <FdcExportColumn>[
      FdcExportColumn(fieldName: 'name', key: 'Name', label: 'Name'),
    ];
    const button = FdcGridExportButton(visible: true);

    expect(button.toExportOptions(columns: columns).columns, columns);
  });
}
