import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/grid/managers/fdc_grid_scroll_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

FdcDataSet _scrollDataSet() {
  final dataSet = FdcDataSet(
    fields: const <FdcFieldDef>[
      FdcStringField(size: 255, name: 'left'),
      FdcStringField(size: 255, name: 'centerA'),
      FdcStringField(size: 255, name: 'centerB'),
      FdcStringField(size: 255, name: 'right'),
    ],

    adapter: FdcMemoryDataAdapter(
      rows: <Map<String, Object?>>[
        for (var i = 0; i < 40; i++)
          <String, Object?>{
            'left': 'Left ${i.toString().padLeft(2, '0')}',
            'centerA': 'Center A ${i.toString().padLeft(2, '0')}',
            'centerB': 'Center B ${i.toString().padLeft(2, '0')}',
            'right': 'Right ${i.toString().padLeft(2, '0')}',
          },
      ],
    ),
  );
  unawaited(dataSet.open());
  return dataSet;
}

double _scrollableOffset(WidgetTester tester, Axis axis) {
  final scrollables = tester.widgetList<Scrollable>(find.byType(Scrollable));
  final scrollable = scrollables.singleWhere(
    (widget) => axisDirectionToAxis(widget.axisDirection) == axis,
  );
  return scrollable.controller?.offset ?? 0.0;
}

Widget _scrollGridHost({
  required FdcDataSet dataSet,
  bool rowIndicatorVisible = true,
  bool headerFiltersVisible = false,
  bool columnGroupsVisible = false,
  FdcGridScrollbars scrollbars = FdcGridScrollbars.both,
  FdcGridVerticalScrollMode verticalScrollMode =
      FdcGridVerticalScrollMode.recordScroll,
}) {
  final columns = <FdcGridColumn<dynamic>>[
    const FdcTextColumn<dynamic>(
      fieldName: 'left',
      width: 90,
      pin: FdcGridColumnPin.startFixed,
    ),
    FdcTextColumn<dynamic>(
      fieldName: 'centerA',
      width: 180,
      groupId: columnGroupsVisible ? 'center' : null,
    ),
    FdcTextColumn<dynamic>(
      fieldName: 'centerB',
      width: 180,
      groupId: columnGroupsVisible ? 'center' : null,
    ),
    const FdcTextColumn<dynamic>(
      fieldName: 'right',
      width: 90,
      pin: FdcGridColumnPin.endFixed,
    ),
  ];

  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 420,
        height: 220,
        child: FdcGrid(
          dataSet: dataSet,
          header: FdcGridHeader(
            height: 32,
            filters: FdcGridHeaderFilters(visible: headerFiltersVisible),
          ),
          options: FdcGridOptions(
            defaultColumnWidth: 130,
            rowHeight: 36,
            scrollbars: scrollbars,
            verticalScrollMode: verticalScrollMode,
          ),
          rowIndicator: FdcGridRowIndicator(visible: rowIndicatorVisible),
          columnGroups: columnGroupsVisible
              ? const <FdcGridColumnGroup>[
                  FdcGridColumnGroup(id: 'center', label: 'Center'),
                ]
              : const <FdcGridColumnGroup>[],
          columns: columns,
        ),
      ),
    ),
  );
}

void main() {
  group('FdcGrid scroll architecture', () {
    testWidgets(
      'pinned layout keeps a single vertical and horizontal scrollbar',
      (tester) async {
        final dataSet = _scrollDataSet();

        await tester.pumpWidget(_scrollGridHost(dataSet: dataSet));
        await tester.pumpAndSettle();

        expect(find.byType(Scrollbar), findsNWidgets(2));
        expect(find.byType(Scrollable), findsNWidgets(2));
      },
    );

    testWidgets('vertical restore lock suppresses delayed reset-to-top jumps', (
      tester,
    ) async {
      final coordinator = FdcGridScrollCoordinator();
      addTearDown(coordinator.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 240,
            height: 180,
            child: ListView.builder(
              controller: coordinator.verticalFlutterController,
              itemExtent: 20,
              itemCount: 100,
              itemBuilder: (context, index) => Text('Row $index'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      coordinator.syncVerticalOffsetFromAttachedPosition();

      expect(coordinator.verticalMaxScrollExtent, greaterThan(0));
      expect(coordinator.jumpVerticalTo(400), isTrue);
      await tester.pump();
      expect(coordinator.verticalFlutterController.offset, closeTo(400, 0.1));

      coordinator.beginVerticalOffsetRestore(400);
      expect(coordinator.jumpVerticalToStart(), isFalse);
      await tester.pump();

      expect(coordinator.currentVerticalOffset, closeTo(400, 0.1));
      expect(coordinator.liveVerticalOffset, closeTo(400, 0.1));
      expect(coordinator.verticalFlutterController.offset, closeTo(400, 0.1));

      coordinator.endVerticalOffsetRestore();
      await tester.pump();
      expect(coordinator.verticalFlutterController.offset, closeTo(400, 0.1));
    });

    testWidgets(
      'vertical jump suppression blocks delayed jumps without restoring',
      (tester) async {
        final coordinator = FdcGridScrollCoordinator();
        addTearDown(coordinator.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 240,
              height: 180,
              child: ListView.builder(
                controller: coordinator.verticalFlutterController,
                itemExtent: 20,
                itemCount: 100,
                itemBuilder: (context, index) => Text('Row $index'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        coordinator.syncVerticalOffsetFromAttachedPosition();

        expect(coordinator.verticalMaxScrollExtent, greaterThan(0));
        expect(coordinator.jumpVerticalTo(400), isTrue);
        await tester.pump();
        expect(coordinator.verticalFlutterController.offset, closeTo(400, 0.1));

        coordinator.beginVerticalJumpSuppression(400);
        expect(coordinator.jumpVerticalToStart(), isFalse);
        await tester.pump();

        expect(coordinator.currentVerticalOffset, closeTo(400, 0.1));
        expect(coordinator.liveVerticalOffset, closeTo(400, 0.1));
        expect(coordinator.verticalFlutterController.offset, closeTo(400, 0.1));

        coordinator.endVerticalJumpSuppression();
        await tester.pump();
        expect(coordinator.verticalFlutterController.offset, closeTo(400, 0.1));
      },
    );

    testWidgets('scrollbars controls rendered scrollbar thumbs only', (
      tester,
    ) async {
      final dataSet = _scrollDataSet();

      await tester.pumpWidget(
        _scrollGridHost(
          dataSet: dataSet,
          scrollbars: FdcGridScrollbars.vertical,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scrollbar), findsOneWidget);
      expect(find.byType(Scrollable), findsNWidgets(2));

      final scrollbar = tester.widget<Scrollbar>(find.byType(Scrollbar));
      final verticalScrollable = tester
          .widgetList<Scrollable>(find.byType(Scrollable))
          .singleWhere(
            (widget) =>
                axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
          );
      expect(scrollbar.controller, verticalScrollable.controller);
    });

    testWidgets('scrollbars can hide both thumbs without disabling scrolling', (
      tester,
    ) async {
      final dataSet = _scrollDataSet();

      await tester.pumpWidget(
        _scrollGridHost(dataSet: dataSet, scrollbars: FdcGridScrollbars.none),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scrollbar), findsNothing);
      expect(find.byType(Scrollable), findsNWidgets(2));
      expect(_scrollableOffset(tester, Axis.horizontal), 0);
      expect(_scrollableOffset(tester, Axis.vertical), 0);

      final scrollableBody = find.text('Center A 00');
      await tester.drag(scrollableBody, const Offset(-120, 0));
      await tester.pumpAndSettle();
      expect(_scrollableOffset(tester, Axis.horizontal), greaterThan(0));

      final bodyCell = find.text('Center B 00');
      await tester.drag(bodyCell, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(_scrollableOffset(tester, Axis.vertical), greaterThan(0));
    });

    testWidgets('vertical scrollbar is constrained to the body area', (
      tester,
    ) async {
      final dataSet = _scrollDataSet();

      await tester.pumpWidget(_scrollGridHost(dataSet: dataSet));
      await tester.pumpAndSettle();

      final verticalController = tester
          .widgetList<Scrollable>(find.byType(Scrollable))
          .singleWhere(
            (widget) =>
                axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
          )
          .controller;

      final verticalScrollbarFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollbar && widget.controller == verticalController,
      );

      expect(verticalScrollbarFinder, findsOneWidget);
      expect(tester.getTopLeft(verticalScrollbarFinder).dy, greaterThan(0));
      expect(
        tester.getTopLeft(verticalScrollbarFinder).dy,
        greaterThanOrEqualTo(32),
      );
      expect(tester.getSize(verticalScrollbarFinder).height, lessThan(220));
      expect(find.byType(Scrollbar), findsNWidgets(2));
      expect(find.byType(Scrollable), findsNWidgets(2));
    });

    testWidgets('touch drag over left pinned body scrolls all row regions', (
      tester,
    ) async {
      final dataSet = _scrollDataSet();

      await tester.pumpWidget(_scrollGridHost(dataSet: dataSet));
      await tester.pumpAndSettle();

      expect(find.text('Left 00'), findsOneWidget);
      expect(find.text('Right 00'), findsOneWidget);

      // x=92 lands in the left-pinned body after the row indicator region.
      await tester.dragFrom(const Offset(92, 160), const Offset(0, -180));
      await tester.pumpAndSettle();

      expect(find.text('Left 00'), findsNothing);
      expect(find.text('Right 00'), findsNothing);
      expect(find.text('Left 05'), findsOneWidget);
      expect(find.text('Right 05'), findsOneWidget);
    });

    testWidgets('touch drag over right pinned body scrolls all row regions', (
      tester,
    ) async {
      final dataSet = _scrollDataSet();

      await tester.pumpWidget(_scrollGridHost(dataSet: dataSet));
      await tester.pumpAndSettle();

      expect(find.text('Left 00'), findsOneWidget);
      expect(find.text('Right 00'), findsOneWidget);

      // x=385 lands in the right-pinned body. The right-pinned region must not
      // own a Scrollable; it feeds the same central vertical coordinator.
      await tester.dragFrom(const Offset(385, 160), const Offset(0, -180));
      await tester.pumpAndSettle();

      expect(find.text('Left 00'), findsNothing);
      expect(find.text('Center A 05'), findsOneWidget);
      expect(find.text('Right 05'), findsOneWidget);
    });

    testWidgets('touch drag over center body keeps pinned regions in sync', (
      tester,
    ) async {
      final dataSet = _scrollDataSet();

      await tester.pumpWidget(_scrollGridHost(dataSet: dataSet));
      await tester.pumpAndSettle();

      expect(find.text('Left 00'), findsOneWidget);
      expect(find.text('Center A 00'), findsOneWidget);
      expect(find.text('Right 00'), findsOneWidget);

      // x=230 lands in the center body. The native center ListView owns the
      // drag gesture, while pinned regions repaint from the same coordinator
      // vertical offset.
      await tester.dragFrom(const Offset(230, 160), const Offset(0, -180));
      await tester.pumpAndSettle();

      expect(find.text('Left 00'), findsNothing);
      expect(find.text('Center A 05'), findsOneWidget);
      expect(find.text('Right 05'), findsOneWidget);
      expect(find.byType(Scrollbar), findsNWidgets(2));
      expect(find.byType(Scrollable), findsNWidgets(2));
    });

    testWidgets('touch drag over row indicator body scrolls pinned columns', (
      tester,
    ) async {
      final dataSet = _scrollDataSet();

      await tester.pumpWidget(_scrollGridHost(dataSet: dataSet));
      await tester.pumpAndSettle();

      expect(find.text('Left 00'), findsOneWidget);

      // x=20 lands in the row-indicator body; the indicator itself is not a
      // Scrollable but it feeds the central scroll coordinator.
      await tester.dragFrom(const Offset(20, 160), const Offset(0, -180));
      await tester.pumpAndSettle();

      expect(find.text('Left 00'), findsNothing);
      expect(find.text('Center A 05'), findsOneWidget);
      expect(find.text('Right 05'), findsOneWidget);
    });

    testWidgets(
      'horizontal pointer scroll over pinned body uses center scrollable',
      (tester) async {
        final dataSet = _scrollDataSet();

        await tester.pumpWidget(_scrollGridHost(dataSet: dataSet));
        await tester.pumpAndSettle();

        expect(_scrollableOffset(tester, Axis.horizontal), 0.0);

        await tester.sendEventToBinding(
          const PointerScrollEvent(
            position: Offset(92, 160),
            scrollDelta: Offset(180, 0),
          ),
        );
        await tester.pumpAndSettle();

        expect(_scrollableOffset(tester, Axis.horizontal), greaterThan(0.0));
        expect(find.byType(Scrollbar), findsNWidgets(2));
        expect(find.byType(Scrollable), findsNWidgets(2));
      },
    );

    testWidgets(
      'vertical pointer scroll over right pinned body uses shared coordinator',
      (tester) async {
        final dataSet = _scrollDataSet();

        await tester.pumpWidget(
          _scrollGridHost(
            dataSet: dataSet,
            verticalScrollMode: FdcGridVerticalScrollMode.smooth,
          ),
        );
        await tester.pumpAndSettle();

        expect(_scrollableOffset(tester, Axis.vertical), 0.0);
        expect(find.text('Right 00'), findsOneWidget);

        await tester.sendEventToBinding(
          const PointerScrollEvent(
            position: Offset(385, 160),
            scrollDelta: Offset(0, 180),
          ),
        );
        await tester.pumpAndSettle();

        expect(_scrollableOffset(tester, Axis.vertical), greaterThan(0.0));
        expect(find.text('Right 00'), findsNothing);
        expect(find.text('Left 00'), findsNothing);
        expect(find.byType(Scrollbar), findsNWidgets(2));
        expect(find.byType(Scrollable), findsNWidgets(2));
      },
    );

    testWidgets('vertical drag over pinned header does not scroll rows', (
      tester,
    ) async {
      final dataSet = _scrollDataSet();

      await tester.pumpWidget(_scrollGridHost(dataSet: dataSet));
      await tester.pumpAndSettle();

      expect(_scrollableOffset(tester, Axis.vertical), 0.0);
      expect(find.text('Left 00'), findsOneWidget);

      // The header is intentionally outside _FdcGridBodyScrollInputRegion.
      // Drag input over pinned headers must not act as a body touch scroll.
      await tester.dragFrom(const Offset(92, 20), const Offset(0, -180));
      await tester.pumpAndSettle();

      expect(_scrollableOffset(tester, Axis.vertical), 0.0);
      expect(find.text('Left 00'), findsOneWidget);
      expect(find.text('Right 00'), findsOneWidget);
    });

    testWidgets(
      'vertical grid-line paint avoids ScrollController position reads',
      (tester) async {
        final dataSet = _scrollDataSet();

        await tester.pumpWidget(
          _scrollGridHost(dataSet: dataSet, rowIndicatorVisible: false),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(Scrollbar), findsNWidgets(2));
        expect(find.byType(Scrollable), findsNWidgets(2));
      },
    );

    testWidgets(
      'scrollbars are wired only to the two center scrollable controllers',
      (tester) async {
        final dataSet = _scrollDataSet();

        await tester.pumpWidget(_scrollGridHost(dataSet: dataSet));
        await tester.pumpAndSettle();

        final scrollables = tester
            .widgetList<Scrollable>(find.byType(Scrollable))
            .toList();
        final scrollbars = tester
            .widgetList<Scrollbar>(find.byType(Scrollbar))
            .toList();

        expect(scrollables, hasLength(2));
        expect(scrollbars, hasLength(2));

        final scrollableControllers = scrollables
            .map((scrollable) => scrollable.controller)
            .whereType<ScrollController>()
            .toSet();
        final scrollbarControllers = scrollbars
            .map((scrollbar) => scrollbar.controller)
            .whereType<ScrollController>()
            .toSet();

        expect(scrollableControllers, hasLength(2));
        expect(scrollbarControllers, scrollableControllers);
      },
    );

    testWidgets(
      'pointer wheel over header filter does not move vertical scroll',
      (tester) async {
        final dataSet = _scrollDataSet();

        await tester.pumpWidget(
          _scrollGridHost(dataSet: dataSet, headerFiltersVisible: true),
        );
        await tester.pumpAndSettle();

        final filterFinder = find.byType(EditableText).first;
        final beforeOffset = _scrollableOffset(tester, Axis.vertical);

        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: tester.getCenter(filterFinder),
            scrollDelta: const Offset(0, 240),
          ),
        );
        await tester.pumpAndSettle();

        expect(_scrollableOffset(tester, Axis.vertical), beforeOffset);
        expect(find.text('Left 00'), findsOneWidget);
      },
    );

    testWidgets(
      'pointer wheel over column header does not move vertical scroll',
      (tester) async {
        final dataSet = _scrollDataSet();

        await tester.pumpWidget(_scrollGridHost(dataSet: dataSet));
        await tester.pumpAndSettle();

        final headerFinder = find.text('Center A');
        final beforeOffset = _scrollableOffset(tester, Axis.vertical);

        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: tester.getCenter(headerFinder),
            scrollDelta: const Offset(0, 240),
          ),
        );
        await tester.pumpAndSettle();

        expect(_scrollableOffset(tester, Axis.vertical), beforeOffset);
        expect(find.text('Left 00'), findsOneWidget);
      },
    );

    testWidgets(
      'pointer wheel over column group header does not move vertical scroll',
      (tester) async {
        final dataSet = _scrollDataSet();

        await tester.pumpWidget(
          _scrollGridHost(dataSet: dataSet, columnGroupsVisible: true),
        );
        await tester.pumpAndSettle();

        final groupFinder = find.text('Center');
        final beforeOffset = _scrollableOffset(tester, Axis.vertical);

        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: tester.getCenter(groupFinder),
            scrollDelta: const Offset(0, 240),
          ),
        );
        await tester.pumpAndSettle();

        expect(_scrollableOffset(tester, Axis.vertical), beforeOffset);
        expect(find.text('Left 00'), findsOneWidget);
      },
    );
  });
}
