import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/managers/fdc_grid_row_indicator_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('status-only row indicator uses padded control slot width', () {
    final manager = FdcGridRowIndicatorManager();

    final width = manager.columnWidth(
      rowIndicator: const FdcGridRowIndicator(visible: true),
      rowCount: 2000,
      showsFilterRow: false,
    );

    expect(width, 44);
  });

  test(
    'select-only row indicator uses the select slot width when menu is in toolbar',
    () {
      final manager = FdcGridRowIndicatorManager();

      final width = manager.columnWidth(
        rowIndicator: const FdcGridRowIndicator(
          visible: true,
          options: FdcGridRowIndicatorOptions(
            showRecordStatus: false,
            showRowSelect: true,
          ),
        ),
        rowCount: 2000,
        showsFilterRow: false,
        mainMenuInToolbar: true,
      );

      expect(width, 32);
    },
  );

  test(
    'status and select row indicator uses compact composite status slot',
    () {
      final manager = FdcGridRowIndicatorManager();

      final width = manager.columnWidth(
        rowIndicator: const FdcGridRowIndicator(
          visible: true,
          options: FdcGridRowIndicatorOptions(showRowSelect: true),
        ),
        rowCount: 2000,
        showsFilterRow: false,
        mainMenuInToolbar: true,
      );

      expect(width, 56);
    },
  );

  test('composite row indicator uses compact status plus enabled slots', () {
    final manager = FdcGridRowIndicatorManager();

    final width = manager.columnWidth(
      rowIndicator: const FdcGridRowIndicator(
        visible: true,
        options: FdcGridRowIndicatorOptions(showRowNumbers: true),
      ),
      rowCount: 2000,
      showsFilterRow: false,
    );

    expect(width, 68);
  });
}
