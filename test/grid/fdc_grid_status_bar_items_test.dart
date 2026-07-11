import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/widgets/fdc_grid_status_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('status bar composes start center and end items', (tester) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          <String, Object?>{'id': 1},
        ],
      ),
    );
    dataSet.open();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 500,
          height: 32,
          child: FdcGridStatusBarShell(
            dataSet: dataSet,
            statusBar: const FdcGridStatusBar(
              visible: true,
              items: <FdcGridItem>[
                FdcGridCustomItem(
                  placement: FdcGridItemPlacement.start,
                  builder: _buildStart,
                ),
                FdcGridCustomItem(
                  placement: FdcGridItemPlacement.center,
                  builder: _buildCenter,
                ),
                FdcGridCustomItem(builder: _buildEnd),
              ],
            ),
            style: FdcGridStatusBarStyle.defaults,
            separatorColor: Colors.transparent,
            progressBarStyle: const FdcProgressBarStyle(),
          ),
        ),
      ),
    );

    final start = tester.getCenter(find.text('start')).dx;
    final center = tester.getCenter(find.text('center')).dx;
    final end = tester.getCenter(find.text('end')).dx;
    expect(start, lessThan(center));
    expect(center, lessThan(end));
  });

  testWidgets(
    'status bar clips oversized placement zones without flex overflow',
    (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{'id': 1},
          ],
        ),
      );
      dataSet.open();

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 120,
            height: 32,
            child: FdcGridStatusBarShell(
              dataSet: dataSet,
              statusBar: const FdcGridStatusBar(
                visible: true,
                items: <FdcGridItem>[
                  FdcGridCustomItem(
                    placement: FdcGridItemPlacement.start,
                    builder: _buildOversized,
                  ),
                  FdcGridCustomItem(
                    placement: FdcGridItemPlacement.center,
                    builder: _buildOversized,
                  ),
                  FdcGridCustomItem(builder: _buildOversized),
                ],
              ),
              style: FdcGridStatusBarStyle.defaults,
              separatorColor: Colors.transparent,
              progressBarStyle: const FdcProgressBarStyle(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('status bar paging navigator renders for standard paging', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[FdcIntegerField(name: 'id')],
      adapter: FdcMemoryDataAdapter(
        rows: <Map<String, Object?>>[
          for (var i = 1; i <= 12; i++) <String, Object?>{'id': i},
        ],
      ),
      paging: const FdcDataPagingOptions(enabled: true, pageSize: 5),
    );
    await dataSet.open();

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 500,
          height: 32,
          child: FdcGridStatusBarShell(
            dataSet: dataSet,
            statusBar: const FdcGridStatusBar(
              visible: true,
              items: <FdcGridItem>[FdcGridPagingNavigator.input()],
            ),
            style: FdcGridStatusBarStyle.defaults,
            separatorColor: Colors.transparent,
            progressBarStyle: const FdcProgressBarStyle(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page'), findsOneWidget);
    expect(find.text('of'), findsOneWidget);
  });

  test('spacer validates public width at runtime', () {
    expect(() => FdcGridSpacer(width: -1), throwsRangeError);
    expect(() => FdcGridSpacer(width: double.nan), throwsRangeError);
    expect(() => FdcGridSpacer(width: double.infinity), throwsRangeError);
    expect(FdcGridSpacer(width: 0).width, 0);
  });

  test('separator validates public dimensions at runtime', () {
    expect(() => FdcGridSeparator(width: -1), throwsRangeError);
    expect(() => FdcGridSeparator(height: -1), throwsRangeError);
    expect(() => FdcGridSeparator(thickness: 0), throwsRangeError);
    expect(() => FdcGridSeparator(thickness: double.nan), throwsRangeError);

    final separator = FdcGridSeparator(width: 0, height: 0, thickness: 0.5);
    expect(separator.width, 0);
    expect(separator.height, 0);
    expect(separator.thickness, 0.5);
  });
}

Widget _buildStart(BuildContext context) => const Text('start');
Widget _buildCenter(BuildContext context) => const Text('center');
Widget _buildEnd(BuildContext context) => const Text('end');

Widget _buildOversized(BuildContext context) => const SizedBox(width: 240);
