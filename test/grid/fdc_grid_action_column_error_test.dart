import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('action column custom callback errors surface to Flutter', (
    tester,
  ) async {
    final dataSet = FdcDataSet(
      fields: const <FdcFieldDef>[
        FdcIntegerField(name: 'id'),
        FdcStringField(name: 'name', size: 50),
      ],

      adapter: FdcMemoryDataAdapter(
        rows: const <Map<String, Object?>>[
          {'id': 1, 'name': 'Alpha'},
        ],
      ),
    )..open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 180,
            child: FdcGrid(
              dataSet: dataSet,
              header: const FdcGridHeader(visible: false),
              toolbar: const FdcGridToolbar(visible: false),
              columns: <FdcGridColumn<dynamic>>[
                const FdcTextColumn<String>(fieldName: 'name', width: 140),
                FdcActionColumn(
                  width: 48,
                  actions: [
                    FdcRowAction(
                      icon: Icons.bolt,
                      tooltip: 'Throw',
                      onPressed: (_) =>
                          throw StateError('custom action failed'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Throw'));
    await tester.pump();

    final exception = tester.takeException();
    expect(exception, isA<StateError>());
    expect(exception.toString(), contains('custom action failed'));
  });
}
