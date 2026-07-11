import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FdcDataSet createDataSet() {
    return FdcDataSet(
      adapter: FdcMemoryDataAdapter(rows: const <Map<String, Object?>>[]),
    );
  }

  testWidgets('progress bar keeps dataset-driven public API', (tester) async {
    final dataSet = createDataSet();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 96,
            child: FdcProgressBar(
              dataSet: dataSet,
              style: const FdcProgressBarStyle(height: 3),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FdcProgressBar), findsOneWidget);
  });

  testWidgets('progress bar stays hidden while dataset is idle', (
    tester,
  ) async {
    final dataSet = createDataSet();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(child: FdcProgressBar(dataSet: dataSet)),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FdcProgressBar), findsOneWidget);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('progress bar renders when dataset work is active', (
    tester,
  ) async {
    final dataSet = createDataSet();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 96,
            child: FdcProgressBar(
              dataSet: dataSet,
              semanticLabel: 'Dataset work',
              style: const FdcProgressBarStyle(
                height: 3,
                visibilityDelay: Duration.zero,
              ),
            ),
          ),
        ),
      ),
    );

    dataSet.work.begin(
      phase: FdcDataSetWorkPhase.filter,
      progress: 0.5,
      message: 'Filtering',
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(dataSet.work.isWorking, isTrue);
    expect(dataSet.work.progress, 0.5);
    expect(find.bySemanticsLabel('Dataset work'), findsOneWidget);
  });

  testWidgets('progress bar waits for visibility delay', (tester) async {
    final dataSet = createDataSet();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 96,
            child: FdcProgressBar(
              dataSet: dataSet,
              semanticLabel: 'Delayed work',
              style: const FdcProgressBarStyle(
                height: 3,
                visibilityDelay: Duration(milliseconds: 300),
                displayMode: FdcProgressBarDisplayMode.auto,
              ),
            ),
          ),
        ),
      ),
    );

    dataSet.work.begin(phase: FdcDataSetWorkPhase.filter, progress: 0.5);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 299));

    expect(find.bySemanticsLabel('Delayed work'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2));

    expect(find.bySemanticsLabel('Delayed work'), findsOneWidget);
  });

  testWidgets('progress bar does not show for short work', (tester) async {
    final dataSet = createDataSet();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 96,
            child: FdcProgressBar(
              dataSet: dataSet,
              semanticLabel: 'Short work',
              style: const FdcProgressBarStyle(
                height: 3,
                visibilityDelay: Duration(milliseconds: 300),
                displayMode: FdcProgressBarDisplayMode.auto,
              ),
            ),
          ),
        ),
      ),
    );

    dataSet.work.begin(phase: FdcDataSetWorkPhase.sort, progress: 0.5);
    await tester.pump(const Duration(milliseconds: 100));
    dataSet.work.end();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.bySemanticsLabel('Short work'), findsNothing);
  });

  testWidgets('indeterminate progress waits for visibility delay', (
    tester,
  ) async {
    final dataSet = createDataSet();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 96,
            child: FdcProgressBar(
              dataSet: dataSet,
              semanticLabel: 'Indeterminate work',
              style: const FdcProgressBarStyle(
                height: 3,
                visibilityDelay: Duration(milliseconds: 300),
              ),
            ),
          ),
        ),
      ),
    );

    dataSet.work.begin(phase: FdcDataSetWorkPhase.sort, message: 'Sorting');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 299));

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Indeterminate work'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2));

    expect(find.bySemanticsLabel('Indeterminate work'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('indeterminate progress does not show for short work', (
    tester,
  ) async {
    final dataSet = createDataSet();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 96,
            child: FdcProgressBar(
              dataSet: dataSet,
              semanticLabel: 'Short indeterminate work',
              style: const FdcProgressBarStyle(
                height: 3,
                visibilityDelay: Duration(milliseconds: 300),
              ),
            ),
          ),
        ),
      ),
    );

    dataSet.work.begin(phase: FdcDataSetWorkPhase.sort, message: 'Sorting');
    await tester.pump(const Duration(milliseconds: 100));
    dataSet.work.end();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.bySemanticsLabel('Short indeterminate work'), findsNothing);
  });

  testWidgets(
    'indeterminate progress uses safe repeat duration when animations are disabled',
    (tester) async {
      final dataSet = createDataSet();

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SizedBox(
              width: 96,
              child: FdcProgressBar(
                dataSet: dataSet,
                semanticLabel: 'Sorting work',
                style: const FdcProgressBarStyle(
                  height: 3,
                  animationDuration: Duration.zero,
                  visibilityDelay: Duration.zero,
                ),
              ),
            ),
          ),
        ),
      );

      dataSet.work.begin(phase: FdcDataSetWorkPhase.sort, message: 'Sorting');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Sorting work'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('indeterminate progress finishes sweep before hiding', (
    tester,
  ) async {
    final dataSet = createDataSet();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: SizedBox(
            width: 96,
            child: FdcProgressBar(
              dataSet: dataSet,
              semanticLabel: 'Closing work',
              style: const FdcProgressBarStyle(
                height: 3,
                animationDuration: Duration(milliseconds: 100),
                visibilityDelay: Duration.zero,
              ),
            ),
          ),
        ),
      ),
    );

    dataSet.work.begin(phase: FdcDataSetWorkPhase.search, message: 'Searching');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    expect(find.bySemanticsLabel('Closing work'), findsOneWidget);

    dataSet.work.end();
    await tester.pump();

    expect(find.bySemanticsLabel('Closing work'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 120));

    expect(find.bySemanticsLabel('Closing work'), findsNothing);
  });

  test('dataset work normalizes progress and returns to idle', () {
    final dataSet = createDataSet();

    dataSet.work.begin(
      phase: FdcDataSetWorkPhase.sort,
      progress: 2,
      message: 'Sorting',
    );

    expect(dataSet.work.isWorking, isTrue);
    expect(dataSet.work.phase, FdcDataSetWorkPhase.sort);
    expect(dataSet.work.progress, 1);
    expect(dataSet.work.mode, FdcDataSetWorkMode.determinate);
    expect(dataSet.work.message, 'Sorting');

    dataSet.work.end();

    expect(dataSet.work.isWorking, isFalse);
    expect(dataSet.work.phase, FdcDataSetWorkPhase.idle);
    expect(dataSet.work.progress, isNull);
    expect(dataSet.work.mode, isNull);
    expect(dataSet.work.message, isNull);
  });

  testWidgets('progress bar can reserve its idle footprint', (tester) async {
    final dataSet = createDataSet();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: FdcProgressBar(
            dataSet: dataSet,
            width: 96,
            style: const FdcProgressBarStyle(
              height: 3,
              reserveSpaceWhenIdle: true,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final progressBox = find.descendant(
      of: find.byType(FdcProgressBar),
      matching: find.byWidgetPredicate((widget) {
        return widget is SizedBox && widget.width == 96 && widget.height == 3;
      }),
    );

    expect(progressBox, findsOneWidget);
    final size = tester.getSize(progressBox);
    expect(size.width, 96);
    expect(size.height, 3);
  });

  test('progress bar style defaults to indeterminate display mode', () {
    expect(
      FdcProgressBarStyle.defaults.displayMode,
      FdcProgressBarDisplayMode.indeterminate,
    );
  });

  test('progress bar style merge preserves base values', () {
    const base = FdcProgressBarStyle(
      height: 3,
      animationDuration: Duration(milliseconds: 100),
      reserveSpaceWhenIdle: true,
      displayMode: FdcProgressBarDisplayMode.auto,
    );
    const override = FdcProgressBarStyle(height: 4);

    final merged = base.merge(override);

    expect(merged.height, 4);
    expect(merged.animationDuration, const Duration(milliseconds: 100));
    expect(merged.reserveSpaceWhenIdle, isTrue);
    expect(merged.displayMode, FdcProgressBarDisplayMode.auto);
  });

  test('progress bar style merge preserves visibility delay', () {
    const base = FdcProgressBarStyle(
      visibilityDelay: Duration(milliseconds: 300),
    );
    const override = FdcProgressBarStyle(height: 4);

    final merged = base.merge(override);

    expect(merged.visibilityDelay, const Duration(milliseconds: 300));
  });
}
