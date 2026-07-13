import 'fdc_grid_ux_test_support.dart';

void _registerViewportBehaviorTests() {
  group('Viewport behavior', () {
    testWidgets('row selection follows record identity across dataset sort', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();

      await uxPumpIndicatorGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
        isFalse,
      );
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(2)).value,
        isFalse,
      );

      await tester.tap(find.byType(Checkbox).at(2));
      await uxPumpPendingFrames(tester);

      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
        isFalse,
      );
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(2)).value,
        isTrue,
      );

      FdcDataSetInternal.setViewState(
        dataSet,
        sorts: const <FdcDataSetSort>[
          FdcDataSetSort(fieldName: 'name', sortType: FdcSortType.descending),
        ],
      );
      await uxPumpPendingFrames(tester);

      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'name'), 'Beta');
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'name'), 'Alpha');
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
        isTrue,
      );
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(2)).value,
        isFalse,
      );
    });

    testWidgets('row checkbox preserves horizontal scroll', (tester) async {
      final dataSet = uxWideSelectionDataSet();

      await uxPumpIndicatorGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'c1'),
          FdcTextColumn<dynamic>(fieldName: 'c2'),
          FdcTextColumn<dynamic>(fieldName: 'c3'),
          FdcTextColumn<dynamic>(fieldName: 'c4'),
          FdcTextColumn<dynamic>(fieldName: 'c5'),
        ],
        showRecordStatus: false,
        width: 260,
      );

      final horizontalScrollView = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      );
      final scrollView = tester.widget<SingleChildScrollView>(
        horizontalScrollView.first,
      );
      final controller = scrollView.controller!;

      await tester.drag(horizontalScrollView.first, const Offset(-320, 0));
      await uxPumpPendingFrames(tester);
      final offsetBeforeSelect = controller.offset;
      expect(offsetBeforeSelect, greaterThan(0));

      await tester.tap(find.byType(Checkbox).at(1));
      await uxPumpPendingFrames(tester);

      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);
      expect(controller.offset, closeTo(offsetBeforeSelect, 1.0));
    });

    testWidgets('select all checkbox preserves horizontal scroll', (
      tester,
    ) async {
      final dataSet = uxWideSelectionDataSet();

      await uxPumpIndicatorGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'c1'),
          FdcTextColumn<dynamic>(fieldName: 'c2'),
          FdcTextColumn<dynamic>(fieldName: 'c3'),
          FdcTextColumn<dynamic>(fieldName: 'c4'),
          FdcTextColumn<dynamic>(fieldName: 'c5'),
        ],
        showRecordStatus: false,
        width: 260,
      );

      final horizontalScrollView = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      );
      final scrollView = tester.widget<SingleChildScrollView>(
        horizontalScrollView.first,
      );
      final controller = scrollView.controller!;

      await tester.drag(horizontalScrollView.first, const Offset(-320, 0));
      await uxPumpPendingFrames(tester);
      final offsetBeforeSelectAll = controller.offset;
      expect(offsetBeforeSelectAll, greaterThan(0));

      await tester.tap(find.byType(Checkbox).first);
      await uxPumpPendingFrames(tester);

      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 2);
      expect(controller.offset, closeTo(offsetBeforeSelectAll, 1.0));
    });

    testWidgets('mouse cell click preserves horizontal and vertical scroll', (
      tester,
    ) async {
      final dataSet = uxWideTallTextDataSet();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'c1'),
          FdcTextColumn<dynamic>(fieldName: 'c2'),
          FdcTextColumn<dynamic>(fieldName: 'c3'),
          FdcTextColumn<dynamic>(fieldName: 'c4'),
          FdcTextColumn<dynamic>(fieldName: 'c5'),
        ],
        toolbarVisible: false,
        width: 260,
        height: 220,
      );

      final horizontalScrollView = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      );
      final horizontalController = tester
          .widget<SingleChildScrollView>(horizontalScrollView.first)
          .controller!;
      final verticalList = find.byWidgetPredicate(
        (widget) => widget is ListView && widget.controller != null,
      );
      final verticalController = tester
          .widget<ListView>(verticalList.first)
          .controller!;

      await tester.drag(horizontalScrollView.first, const Offset(-320, 0));
      await tester.dragFrom(
        tester.getTopLeft(horizontalScrollView.first) + const Offset(120, 80),
        const Offset(0, -220),
      );
      await uxPumpPendingFrames(tester);
      final horizontalBeforeClick = horizontalController.offset;
      final verticalBeforeClick = verticalController.offset;
      expect(horizontalBeforeClick, greaterThan(0));
      expect(verticalBeforeClick, greaterThan(0));

      await tester.tapAt(
        tester.getTopLeft(horizontalScrollView.first) + const Offset(120, 80),
      );
      await uxPumpPendingFrames(tester);

      expect(horizontalController.offset, closeTo(horizontalBeforeClick, 1.0));
      expect(verticalController.offset, closeTo(verticalBeforeClick, 1.0));
    });

    testWidgets(
      'record-scroll active text editor suppresses implicit bottom-row reveal',
      (tester) async {
        final dataSet = uxWideTallTextDataSet();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'c1'),
            FdcTextColumn<dynamic>(fieldName: 'c2'),
            FdcTextColumn<dynamic>(fieldName: 'c3'),
          ],
          toolbarVisible: false,
          width: 260,
          height: 220,
        );

        final horizontalScrollView = find.byWidgetPredicate(
          (widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.horizontal,
        );
        final verticalList = find.byWidgetPredicate(
          (widget) => widget is ListView && widget.controller != null,
        );
        final verticalController = tester
            .widget<ListView>(verticalList.first)
            .controller!;

        verticalController.jumpTo(360);
        await uxPumpPendingFrames(tester);
        final verticalBeforeEdit = verticalController.offset;
        expect(verticalBeforeEdit, greaterThan(0));

        await tester.tapAt(
          tester.getTopLeft(horizontalScrollView.first) + const Offset(60, 162),
        );
        await uxPumpPendingFrames(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await uxPumpPendingFrames(tester);
        expect(dataSet.state, FdcDataSetState.edit);

        verticalController.jumpTo(verticalBeforeEdit + 8);
        await tester.pump();

        expect(verticalController.offset, closeTo(verticalBeforeEdit, 0.5));
      },
    );

    testWidgets(
      'record-scroll first wheel after mouse cell click keeps scroll direction',
      (tester) async {
        final dataSet = uxWideTallTextDataSet();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'c1'),
            FdcTextColumn<dynamic>(fieldName: 'c2'),
            FdcTextColumn<dynamic>(fieldName: 'c3'),
          ],
          toolbarVisible: false,
          width: 260,
          height: 220,
        );

        final verticalList = find.byWidgetPredicate(
          (widget) => widget is ListView && widget.controller != null,
        );
        final verticalController = tester
            .widget<ListView>(verticalList.first)
            .controller!;

        verticalController.jumpTo(360);
        await uxPumpPendingFrames(tester);
        final verticalBeforeClick = verticalController.offset;
        expect(verticalBeforeClick, greaterThan(0));

        final bodyBottomCellPosition =
            tester.getTopLeft(verticalList.first) +
            Offset(60, tester.getSize(verticalList.first).height - 10);

        await tester.tapAt(bodyBottomCellPosition);
        await tester.sendEventToBinding(
          PointerScrollEvent(
            position: bodyBottomCellPosition,
            scrollDelta: const Offset(0, 120),
          ),
        );
        await uxPumpPendingFrames(tester);

        expect(
          verticalController.offset,
          closeTo(verticalBeforeClick + 36, 1.0),
        );
      },
    );

    testWidgets(
      'PageDown after mouse cell click cancels pending viewport restore',
      (tester) async {
        final dataSet = uxWideTallTextDataSet();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'c1'),
            FdcTextColumn<dynamic>(fieldName: 'c2'),
            FdcTextColumn<dynamic>(fieldName: 'c3'),
          ],
          toolbarVisible: false,
          width: 260,
          height: 220,
        );

        final verticalList = find.byWidgetPredicate(
          (widget) => widget is ListView && widget.controller != null,
        );
        final verticalController = tester
            .widget<ListView>(verticalList.first)
            .controller!;

        verticalController.jumpTo(360);
        await uxPumpPendingFrames(tester);
        final verticalBeforeClick = verticalController.offset;
        expect(verticalBeforeClick, greaterThan(0));

        final bodyCellPosition =
            tester.getTopLeft(verticalList.first) + const Offset(60, 80);

        await tester.tapAt(bodyCellPosition);
        await tester.pump();
        final activeAfterClick = FdcDataSetInternal.activeIndex(dataSet);

        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await uxPumpPendingFrames(tester);

        expect(
          FdcDataSetInternal.activeIndex(dataSet),
          greaterThan(activeAfterClick),
        );
        expect(verticalController.offset, greaterThan(verticalBeforeClick));
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Viewport Behavior', () {
    _registerViewportBehaviorTests();
  });
}
