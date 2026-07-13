import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fdc_widget_test_pumps.dart';

void main() {
  group('FdcGrid header hints', () {
    testWidgets('column hint is exposed as a header tooltip', (tester) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(name: 'name', size: 50),
          FdcStringField(name: 'status', size: 50),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'name': 'Alpha', 'status': 'Active'},
          ],
        ),
      );
      dataSet.open();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 240,
              child: FdcGrid(
                dataSet: dataSet,
                toolbar: const FdcGridToolbar(visible: false),
                header: const FdcGridHeader(
                  filters: FdcGridHeaderFilters(initiallyVisible: false),
                ),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcTextColumn<dynamic>(
                    fieldName: 'name',
                    label: 'Name',
                    hint: 'Customer display name',
                  ),
                  FdcTextColumn<dynamic>(fieldName: 'status', label: 'Status'),
                ],
              ),
            ),
          ),
        ),
      );
      await pumpPendingFrames(tester);

      expect(find.byTooltip('Customer display name'), findsOneWidget);
      expect(find.byTooltip('Status'), findsNothing);
    });
  });
}
