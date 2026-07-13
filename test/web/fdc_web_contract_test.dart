import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Community web contract', () {
    test('public value objects remain browser compatible', () {
      const option = FdcOption<int>(value: 1, label: 'One');
      const options = FdcGridOptions(readOnly: true);

      expect(option, const FdcOption<int>(value: 1, label: 'One'));
      expect(options.readOnly, isTrue);
      expect(options.defaultColumnWidth, 160);
      expect(options.rowHeight, 40);
    });

    testWidgets('dataset-backed widget renders in Chrome', (tester) async {
      final dataSet = FdcDataSet(
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{'id': 1, 'name': 'Alpha'},
          ],
        ),
      );
      addTearDown(dataSet.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SizedBox(
              width: 120,
              child: FdcProgressBar(
                dataSet: dataSet,
                semanticLabel: 'Dataset work',
                style: const FdcProgressBarStyle(
                  visibilityDelay: Duration.zero,
                ),
              ),
            ),
          ),
        ),
      );

      dataSet.work.begin(phase: FdcDataSetWorkPhase.load, progress: 0.5);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(FdcProgressBar), findsOneWidget);
      expect(dataSet.work.isWorking, isTrue);

      dataSet.work.end();
      await tester.pump();
    });
  });
}
