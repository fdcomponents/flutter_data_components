import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grid style objects use value equality', () {
    expect(
      const FdcGridStyle(
        backgroundColor: Colors.white,
        gridLineColor: Colors.blue,
      ),
      const FdcGridStyle(
        backgroundColor: Colors.white,
        gridLineColor: Colors.blue,
      ),
    );
    expect(
      const FdcGridHeaderStyle(backgroundColor: Colors.black, groupHeight: 28),
      const FdcGridHeaderStyle(backgroundColor: Colors.black, groupHeight: 28),
    );
    expect(
      const FdcGridToolbarStyle(
        backgroundColor: Colors.white,
        searchExpandedWidth: 260,
      ),
      const FdcGridToolbarStyle(
        backgroundColor: Colors.white,
        searchExpandedWidth: 260,
      ),
    );
    expect(
      const FdcGridControlsStyle(
        iconColor: Colors.black,
        disabledIconColor: Colors.grey,
      ),
      const FdcGridControlsStyle(
        iconColor: Colors.black,
        disabledIconColor: Colors.grey,
      ),
    );
    expect(
      const FdcGridProgressStyle(
        color: Colors.green,
        backgroundColor: Colors.black12,
      ),
      const FdcGridProgressStyle(
        color: Colors.green,
        backgroundColor: Colors.black12,
      ),
    );
    expect(
      const FdcGridStatusBarStyle(height: 30, backgroundColor: Colors.white),
      const FdcGridStatusBarStyle(height: 30, backgroundColor: Colors.white),
    );
  });

  test('grid theme data and app theme extension use value equality', () {
    final left = FdcGridThemes.dark.copyWith(
      grid: FdcGridThemes.dark.grid.copyWith(backgroundColor: Colors.black),
      toolbar: FdcGridThemes.dark.toolbar.copyWith(height: 48),
      statusBarProgressBar: const FdcProgressBarStyle(
        height: 6,
        valueColor: Colors.green,
      ),
    );
    final right = FdcGridThemes.dark.copyWith(
      grid: FdcGridThemes.dark.grid.copyWith(backgroundColor: Colors.black),
      toolbar: FdcGridThemes.dark.toolbar.copyWith(height: 48),
      statusBarProgressBar: const FdcProgressBarStyle(
        height: 6,
        valueColor: Colors.green,
      ),
    );

    expect(left, right);
    expect(left.hashCode, right.hashCode);
    expect(FdcGridTheme(data: left), FdcGridTheme(data: right));
  });

  test('export options keep value equality for explicit columns', () {
    expect(
      FdcExportOptions(
        columns: <FdcExportColumn>[
          const FdcExportColumn(fieldName: 'id', label: 'ID'),
        ],
      ),
      FdcExportOptions(
        columns: <FdcExportColumn>[
          const FdcExportColumn(fieldName: 'id', label: 'ID'),
        ],
      ),
    );
  });
}
