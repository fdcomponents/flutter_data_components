part of '../fdc_grid_widget_ux_test.dart';

void _registerSelectionScrollingTests() {
  group('Selection and scrolling', () {
    testWidgets('row selection follows record identity across dataset sort', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();

      await _pumpIndicatorGrid(
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
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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
      final dataSet = _wideSelectionDataSet();

      await _pumpIndicatorGrid(
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
      await tester.pumpAndSettle();
      final offsetBeforeSelect = controller.offset;
      expect(offsetBeforeSelect, greaterThan(0));

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();

      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);
      expect(controller.offset, closeTo(offsetBeforeSelect, 1.0));
    });

    testWidgets('select all checkbox preserves horizontal scroll', (
      tester,
    ) async {
      final dataSet = _wideSelectionDataSet();

      await _pumpIndicatorGrid(
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
      await tester.pumpAndSettle();
      final offsetBeforeSelectAll = controller.offset;
      expect(offsetBeforeSelectAll, greaterThan(0));

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 2);
      expect(controller.offset, closeTo(offsetBeforeSelectAll, 1.0));
    });

    testWidgets('mouse cell click preserves horizontal and vertical scroll', (
      tester,
    ) async {
      final dataSet = _wideTallTextDataSet();

      await _pumpGrid(
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
      await tester.pumpAndSettle();
      final horizontalBeforeClick = horizontalController.offset;
      final verticalBeforeClick = verticalController.offset;
      expect(horizontalBeforeClick, greaterThan(0));
      expect(verticalBeforeClick, greaterThan(0));

      await tester.tapAt(
        tester.getTopLeft(horizontalScrollView.first) + const Offset(120, 80),
      );
      await tester.pumpAndSettle();

      expect(horizontalController.offset, closeTo(horizontalBeforeClick, 1.0));
      expect(verticalController.offset, closeTo(verticalBeforeClick, 1.0));
    });

    testWidgets(
      'record-scroll active text editor suppresses implicit bottom-row reveal',
      (tester) async {
        final dataSet = _wideTallTextDataSet();

        await _pumpGrid(
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
        await tester.pumpAndSettle();
        final verticalBeforeEdit = verticalController.offset;
        expect(verticalBeforeEdit, greaterThan(0));

        await tester.tapAt(
          tester.getTopLeft(horizontalScrollView.first) + const Offset(60, 162),
        );
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await tester.pumpAndSettle();
        expect(dataSet.state, FdcDataSetState.edit);

        verticalController.jumpTo(verticalBeforeEdit + 8);
        await tester.pump();

        expect(verticalController.offset, closeTo(verticalBeforeEdit, 0.5));
      },
    );

    testWidgets(
      'record-scroll first wheel after mouse cell click keeps scroll direction',
      (tester) async {
        final dataSet = _wideTallTextDataSet();

        await _pumpGrid(
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
        await tester.pumpAndSettle();
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
        await tester.pumpAndSettle();

        expect(
          verticalController.offset,
          closeTo(verticalBeforeClick + 36, 1.0),
        );
      },
    );

    testWidgets(
      'PageDown after mouse cell click cancels pending viewport restore',
      (tester) async {
        final dataSet = _wideTallTextDataSet();

        await _pumpGrid(
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
        await tester.pumpAndSettle();
        final verticalBeforeClick = verticalController.offset;
        expect(verticalBeforeClick, greaterThan(0));

        final bodyCellPosition =
            tester.getTopLeft(verticalList.first) + const Offset(60, 80);

        await tester.tapAt(bodyCellPosition);
        await tester.pump();
        final activeAfterClick = FdcDataSetInternal.activeIndex(dataSet);

        await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
        await tester.pumpAndSettle();

        expect(
          FdcDataSetInternal.activeIndex(dataSet),
          greaterThan(activeAfterClick),
        );
        expect(verticalController.offset, greaterThan(verticalBeforeClick));
      },
    );

    testWidgets(
      'boolean cell background selects row without toggling checkbox',
      (tester) async {
        final dataSet = _wideTallBooleanDataSet();

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'c1', width: 120),
            FdcBooleanColumn<dynamic>(fieldName: 'flag', width: 160),
          ],
          toolbarVisible: false,
          width: 320,
          height: 180,
        );

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'flag'), false);

        final secondRowCheckboxCenter = tester.getCenter(
          find.byType(Checkbox).at(1),
        );
        await tester.tapAt(secondRowCheckboxCenter + const Offset(58, 0));
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
        expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'flag'), false);

        await tester.tap(find.byType(Checkbox).at(1));
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
        expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'flag'), true);
      },
    );

    testWidgets('required boolean checkbox cycles only true and false', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'name'),
          FdcBooleanField(name: 'flag', required: true),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: <Map<String, Object?>>[
            <String, Object?>{'name': 'Row 1', 'flag': true},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name', width: 120),
          FdcBooleanColumn<dynamic>(fieldName: 'flag', width: 120),
        ],
        toolbarVisible: false,
        width: 260,
        height: 120,
      );

      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'flag'), true);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'flag'), false);

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'flag'), true);
    });

    testWidgets(
      'boolean checkbox cell preserves horizontal and vertical scroll',
      (tester) async {
        final dataSet = _wideTallBooleanDataSet();

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'c1'),
            FdcTextColumn<dynamic>(fieldName: 'c2'),
            FdcTextColumn<dynamic>(fieldName: 'c3'),
            FdcBooleanColumn<dynamic>(fieldName: 'flag'),
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

        await tester.drag(horizontalScrollView.first, const Offset(-420, 0));
        await tester.dragFrom(
          tester.getTopLeft(horizontalScrollView.first) + const Offset(120, 80),
          const Offset(0, -220),
        );
        await tester.pumpAndSettle();
        final horizontalBeforeToggle = horizontalController.offset;
        final verticalBeforeToggle = verticalController.offset;
        expect(horizontalBeforeToggle, greaterThan(0));
        expect(verticalBeforeToggle, greaterThan(0));

        await tester.tapAt(
          tester.getTopLeft(horizontalScrollView.first) + const Offset(140, 80),
        );
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.activeIndex(dataSet), greaterThan(0));
        expect(
          horizontalController.offset,
          closeTo(horizontalBeforeToggle, 1.0),
        );
        expect(verticalController.offset, closeTo(verticalBeforeToggle, 1.0));
      },
    );

    testWidgets('date picker button preserves horizontal and vertical scroll', (
      tester,
    ) async {
      final dataSet = _wideTallDateDataSet();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'c1'),
          FdcTextColumn<dynamic>(fieldName: 'c2'),
          FdcTextColumn<dynamic>(fieldName: 'c3'),
          FdcDateColumn<dynamic>(fieldName: 'date'),
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

      horizontalController.jumpTo(420);
      verticalController.jumpTo(220);
      await tester.pumpAndSettle();

      final horizontalBeforePicker = horizontalController.offset;
      final verticalBeforePicker = verticalController.offset;
      expect(horizontalBeforePicker, greaterThan(0));
      expect(verticalBeforePicker, greaterThan(0));

      await tester.tapAt(
        tester.getTopLeft(horizontalScrollView.first) + const Offset(90, 80),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(FdcDataSetInternal.activeIndex(dataSet), greaterThan(0));
      expect(horizontalController.offset, closeTo(horizontalBeforePicker, 1.0));
      expect(verticalController.offset, closeTo(verticalBeforePicker, 1.0));
    });

    testWidgets(
      'header filter focus loss does not apply filter during date picker edit',
      (tester) async {
        final dataSet = _wideTallDateDataSet();

        const manualFilterHeader = FdcGridHeader(
          height: 32,
          filters: FdcGridHeaderFilters(
            visible: true,
            options: FdcGridFilterOptions(
              debouncePolicy: FdcDebouncePolicy.disabled,
              debounceDuration: Duration.zero,
            ),
          ),
        );

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'c1'),
            FdcTextColumn<dynamic>(fieldName: 'c2'),
            FdcTextColumn<dynamic>(fieldName: 'c3'),
            FdcDateColumn<dynamic>(fieldName: 'date'),
            FdcTextColumn<dynamic>(fieldName: 'c5'),
          ],
          toolbarVisible: false,
          header: manualFilterHeader,
          width: 260,
          height: 220,
        );

        await tester.tap(find.byType(EditableText).first);
        await tester.enterText(find.byType(EditableText).first, 'R');
        await tester.pump();
        expect(dataSet.filter.active, isFalse);

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

        horizontalController.jumpTo(420);
        verticalController.jumpTo(220);
        await tester.pumpAndSettle();

        final horizontalBeforePicker = horizontalController.offset;
        final verticalBeforePicker = verticalController.offset;
        expect(horizontalBeforePicker, greaterThan(0));
        expect(verticalBeforePicker, greaterThan(0));

        await tester.tapAt(
          tester.getTopLeft(horizontalScrollView.first) + const Offset(90, 80),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);

        await tester.tap(find.byIcon(Icons.calendar_today_outlined));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(FdcDataSetInternal.activeIndex(dataSet), greaterThan(0));
        expect(dataSet.filter.active, isFalse);
        expect(
          horizontalController.offset,
          closeTo(horizontalBeforePicker, 1.0),
        );
        expect(verticalController.offset, closeTo(verticalBeforePicker, 1.0));

        if (!FdcDataSetInternal.hasActiveEdit(dataSet)) {
          dataSet.edit();
        }
        expect(FdcDataSetInternal.hasActiveEdit(dataSet), isTrue);

        dataSet.post();
        await tester.pumpAndSettle();

        expect(dataSet.filter.active, isFalse);
        expect(
          horizontalController.offset,
          closeTo(horizontalBeforePicker, 1.0),
        );
        expect(verticalController.offset, closeTo(verticalBeforePicker, 1.0));
      },
    );

    testWidgets(
      'custom checkbox control preserves horizontal and vertical scroll',
      (tester) async {
        final dataSet = _wideTallBooleanDataSet();

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: <FdcGridColumn<dynamic>>[
            const FdcTextColumn<dynamic>(fieldName: 'c1'),
            const FdcTextColumn<dynamic>(fieldName: 'c2'),
            const FdcTextColumn<dynamic>(fieldName: 'c3'),
            FdcCustomColumn<bool>(
              fieldName: 'flag',
              width: 120,
              cellBuilder: (field, cell) {
                return cell.control(
                  Checkbox(
                    key: ValueKey<String>('custom-flag-${field.rowIndex}'),
                    value: field.value ?? false,
                    onChanged: cell.canEdit
                        ? (value) => field.setValue(value)
                        : null,
                  ),
                  enabled: cell.canEdit,
                );
              },
            ),
            const FdcTextColumn<dynamic>(fieldName: 'c5'),
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

        horizontalController.jumpTo(420);
        verticalController.jumpTo(220);
        await tester.pumpAndSettle();

        final horizontalBeforeToggle = horizontalController.offset;
        final verticalBeforeToggle = verticalController.offset;
        expect(horizontalBeforeToggle, greaterThan(0));
        expect(verticalBeforeToggle, greaterThan(0));

        await tester.tapAt(
          tester.getTopLeft(horizontalScrollView.first) + const Offset(90, 80),
        );
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.activeIndex(dataSet), greaterThan(0));
        expect(
          horizontalController.offset,
          closeTo(horizontalBeforeToggle, 1.0),
        );
        expect(verticalController.offset, closeTo(verticalBeforeToggle, 1.0));
      },
    );

    testWidgets('row selection on another row is disabled during dirty edit', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name', required: true),
        ],
        beforePost: (dataSet) {
          throw FdcDataSetAbortException('Post is not allowed.');
        },

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
            {'id': 2, 'name': 'Beta'},
          ],
        ),
      );
      dataSet.open();

      await _pumpIndicatorGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Changed');
      await tester.pump();

      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pumpAndSettle();

      expect(find.text('Post is not allowed.'), findsNothing);
      expect(dataSet.state, FdcDataSetState.edit);
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 0);
      final otherRowCheckbox = tester.widget<Checkbox>(
        find.byType(Checkbox).at(2),
      );
      expect(otherRowCheckbox.value, isFalse);
      expect(otherRowCheckbox.onChanged, isNull);
    });

    testWidgets('row selection on same row does not post dirty edit', (
      tester,
    ) async {
      var beforePostCount = 0;
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name', required: true),
        ],
        beforePost: (dataSet) {
          beforePostCount++;
          throw FdcDataSetAbortException('Post is not allowed.');
        },

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha'},
            {'id': 2, 'name': 'Beta'},
          ],
        ),
      );
      dataSet.open();

      await _pumpIndicatorGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
      );

      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Changed');
      await tester.pump();

      await tester.tap(find.byType(Checkbox).at(1));
      await tester.pumpAndSettle();

      expect(beforePostCount, 0);
      expect(find.text('Post is not allowed.'), findsNothing);
      expect(dataSet.state, FdcDataSetState.edit);
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
        isTrue,
      );
    });

    testWidgets(
      'indicator header checkbox reflects partial visible selection',
      (tester) async {
        final dataSet = _peopleDataSet();

        await _pumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        // Header select-all checkbox + one row checkbox for each visible row.
        expect(find.byType(Checkbox), findsNWidgets(3));
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).at(0)).value,
          isFalse,
        );

        FdcDataSetInternal.setRecordSelectedAt(dataSet, 0, true);
        // Internal selection helpers deliberately do not notify by themselves;
        // trigger a normal dataset notification so the mounted grid rebuilds.
        dataSet.moveToRecord(2);
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).at(0)).value,
          isNull,
        );

        await tester.tap(find.byType(Checkbox).at(0));
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 2);
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).at(0)).value,
          isTrue,
        );
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
          isTrue,
        );
        expect(
          tester.widget<Checkbox>(find.byType(Checkbox).at(2)).value,
          isTrue,
        );
      },
    );

    testWidgets(
      'indicator select all uses filter row when filters are visible',
      (tester) async {
        final dataSet = _peopleDataSet();

        await _pumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          headerFiltersVisible: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Checkbox), findsNWidgets(3));
        expect(find.byIcon(Icons.menu), findsOneWidget);

        final menuCenter = tester.getCenter(find.byIcon(Icons.menu));
        final headerCheckboxCenter = tester.getCenter(
          find.byType(Checkbox).first,
        );
        final firstRowCheckboxCenter = tester.getCenter(
          find.byType(Checkbox).at(1),
        );
        expect(headerCheckboxCenter.dy, greaterThan(menuCenter.dy + 20));
        expect(
          headerCheckboxCenter.dx,
          closeTo(firstRowCheckboxCenter.dx, 1.0),
        );
        expect(find.byIcon(Icons.grading_outlined), findsNothing);
      },
    );

    testWidgets(
      'indicator selection filter icon is not shown in the row indicator header',
      (tester) async {
        final dataSet = _peopleDataSet();

        await _pumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        expect(find.byIcon(Icons.grading_outlined), findsNothing);
        expect(find.byIcon(Icons.menu), findsOneWidget);
      },
    );

    testWidgets(
      'indicator select all shares first header row when filters are hidden',
      (tester) async {
        final dataSet = _peopleDataSet();

        await _pumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Checkbox), findsNWidgets(3));
        expect(find.byIcon(Icons.menu), findsOneWidget);

        final menuCenter = tester.getCenter(find.byIcon(Icons.menu));
        final headerCheckboxCenter = tester.getCenter(
          find.byType(Checkbox).first,
        );
        final firstRowCheckboxCenter = tester.getCenter(
          find.byType(Checkbox).at(1),
        );

        expect(headerCheckboxCenter.dx, lessThan(menuCenter.dx));
        expect(headerCheckboxCenter.dy, closeTo(menuCenter.dy, 1.0));
        expect(
          headerCheckboxCenter.dx,
          closeTo(firstRowCheckboxCenter.dx, 1.0),
        );
      },
    );

    testWidgets(
      'indicator main menu is centered over row numbers when select all is hidden',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'name', label: 'Name'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: <Map<String, Object?>>[
              for (var index = 0; index < 2000; index++)
                <String, Object?>{'name': 'Person $index'},
            ],
          ),
        );
        dataSet.open();

        await _pumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          showRecordStatus: false,
          showRowSelect: false,
          showRowNumbers: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Checkbox), findsNothing);
        expect(find.byIcon(Icons.menu), findsOneWidget);

        final menuCenter = tester.getCenter(find.byIcon(Icons.menu));
        final firstRowNumberCenter = tester.getCenter(find.text('1'));

        expect(menuCenter.dx, closeTo(firstRowNumberCenter.dx, 1.0));
      },
    );

    testWidgets(
      'indicator main menu is centered when header filters are visible',
      (tester) async {
        final dataSet = _peopleDataSet();

        await _pumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          headerFiltersVisible: true,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Checkbox), findsNWidgets(3));
        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.byType(FdcGridRowIndicatorHeader), findsOneWidget);

        final menuCenter = tester.getCenter(find.byIcon(Icons.menu));
        final indicatorHeaderCenter = tester.getCenter(
          find.byType(FdcGridRowIndicatorHeader),
        );
        final headerCheckboxCenter = tester.getCenter(
          find.byType(Checkbox).first,
        );

        expect(menuCenter.dx, closeTo(indicatorHeaderCenter.dx, 1.0));
        expect(menuCenter.dy, lessThan(headerCheckboxCenter.dy));
      },
    );

    testWidgets(
      'indicator header keeps select all and main menu visible without overflow',
      (tester) async {
        final dataSet = _peopleDataSet();

        await _pumpIndicatorGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          width: 220,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Checkbox), findsNWidgets(3));
        expect(find.byIcon(Icons.menu), findsOneWidget);
      },
    );

    testWidgets('grid row selection survives filter hide and show by record', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 255, name: 'name'),
          FdcStringField(size: 255, name: 'status'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {'id': 1, 'name': 'Alpha', 'status': 'active'},
            {'id': 2, 'name': 'Beta', 'status': 'blocked'},
          ],
        ),
      );
      dataSet.open();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        rowIndicator: const FdcGridRowIndicator(
          visible: true,
          options: FdcGridRowIndicatorOptions(showRowSelect: true),
        ),
      );

      await tester.tap(find.byType(Checkbox).at(2));
      await tester.pumpAndSettle();

      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);

      FdcDataSetInternal.setViewState(
        dataSet,
        filters: const <FdcDataSetFilter>[
          FdcDataSetFilter(
            fieldName: 'status',
            operator: FdcFilterOperator.equals,
            value: 'active',
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsNothing);
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 0);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(0)).value,
        isFalse,
      );
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
        isFalse,
      );

      FdcDataSetInternal.setViewState(
        dataSet,
        filters: const <FdcDataSetFilter>[],
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(FdcDataSetInternal.visibleSelectedRecordCount(dataSet), 1);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(0)).value,
        isNull,
      );
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(1)).value,
        isFalse,
      );
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).at(2)).value,
        isTrue,
      );
    });

    testWidgets(
      'external append keeps indicator content when grid focus returns',
      (tester) async {
        final dataSet = _peopleDataSet();

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          rowIndicator: const FdcGridRowIndicator(
            visible: true,
            options: FdcGridRowIndicatorOptions(
              showRowNumbers: true,
              showRowSelect: true,
            ),
          ),
        );

        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        dataSet.append();
        await tester.pumpAndSettle();

        expect(dataSet.state, FdcDataSetState.insert);
        expect(dataSet.recordCount, 3);
        expect(find.text('3'), findsOneWidget);
        expect(find.byType(Checkbox), findsNWidgets(4));

        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();

        expect(dataSet.state, FdcDataSetState.browse);
        expect(dataSet.recordCount, 2);
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
        expect(find.text('3'), findsNothing);
        expect(find.byType(Checkbox), findsNWidgets(3));
      },
    );

    testWidgets(
      'beforeScroll visible abort from grid shows dataset error dialog',
      (tester) async {
        var beforeScrollCalls = 0;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcStringField(size: 255, name: 'name'),
          ],
          beforeScroll: (dataSet, currentRecordNumber, targetRecordNumber) {
            beforeScrollCalls++;
            if (targetRecordNumber > 0 &&
                FdcDataSetInternal.fieldValueAt(
                      dataSet,
                      targetRecordNumber - 1,
                      'id',
                    ) ==
                    2) {
              throw FdcDataSetAbortException('Scroll is not allowed.');
            }
          },

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'id': 1, 'name': 'Alpha'},
              {'id': 2, 'name': 'Beta'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Beta'));
        await tester.pumpAndSettle();

        expect(beforeScrollCalls, 1);
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(dataSet.errors.messages.isNotEmpty, isTrue);
        expect(dataSet.errors.messages[0], 'Scroll is not allowed.');
        expect(find.text('Scroll is not allowed.'), findsOneWidget);
      },
    );

    testWidgets(
      'beforeScroll silent abort from grid keeps current row without dialog',
      (tester) async {
        var beforeScrollCalls = 0;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcStringField(size: 255, name: 'name'),
          ],
          beforeScroll: (dataSet, currentRecordNumber, targetRecordNumber) {
            beforeScrollCalls++;
            if (targetRecordNumber > 0 &&
                FdcDataSetInternal.fieldValueAt(
                      dataSet,
                      targetRecordNumber - 1,
                      'id',
                    ) ==
                    2) {
              throw const FdcDataSetAbortException.silent();
            }
          },

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'id': 1, 'name': 'Alpha'},
              {'id': 2, 'name': 'Beta'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Beta'));
        await tester.pumpAndSettle();

        expect(beforeScrollCalls, 1);
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(dataSet.errors.messages.isNotEmpty, isFalse);
        expect(find.byType(AlertDialog), findsNothing);
      },
    );

    testWidgets(
      'parent column reorder updates visual order when no user reorder override exists',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'first'),
            FdcStringField(size: 255, name: 'second'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'first': 'Alpha', 'second': 'Beta'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'first', label: 'First'),
            FdcTextColumn<dynamic>(fieldName: 'second', label: 'Second'),
          ],
        );

        expect(
          tester.getTopLeft(find.text('First')).dx,
          lessThan(tester.getTopLeft(find.text('Second')).dx),
        );

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'second', label: 'Second'),
            FdcTextColumn<dynamic>(fieldName: 'first', label: 'First'),
          ],
        );

        expect(
          tester.getTopLeft(find.text('Second')).dx,
          lessThan(tester.getTopLeft(find.text('First')).dx),
        );
      },
    );

    testWidgets(
      'sort indicator is scoped to runtime column identity for duplicate field columns',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 255, name: 'name')],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'name': 'Beta'},
              {'name': 'Alpha'},
            ],
          ),
        );
        dataSet.open();
        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name A'),
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name B'),
          ],
        );

        expect(find.byIcon(Icons.north), findsNothing);
        expect(find.byIcon(Icons.more_vert), findsNWidgets(2));

        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();

        expect(dataSet.sort.items, isEmpty);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Name A'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.north), findsOneWidget);
        expect(find.byIcon(Icons.unfold_more), findsNothing);
        expect(find.byIcon(Icons.more_vert), findsNWidgets(2));
      },
    );
  });
}
