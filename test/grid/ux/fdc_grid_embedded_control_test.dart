import 'fdc_grid_ux_test_support.dart';

void _registerEmbeddedControlTests() {
  group('Embedded controls', () {
    testWidgets(
      'boolean cell background selects row without toggling checkbox',
      (tester) async {
        final dataSet = uxWideTallBooleanDataSet();

        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);

        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
        expect(FdcDataSetInternal.fieldValueAt(dataSet, 1, 'flag'), false);

        await tester.tap(find.byType(Checkbox).at(1));
        await uxPumpPendingFrames(tester);

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

      await uxPumpGrid(
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
      await uxPumpPendingFrames(tester);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'flag'), false);

      await tester.tap(find.byType(Checkbox).first);
      await uxPumpPendingFrames(tester);
      expect(FdcDataSetInternal.fieldValueAt(dataSet, 0, 'flag'), true);
    });

    testWidgets(
      'boolean checkbox cell preserves horizontal and vertical scroll',
      (tester) async {
        final dataSet = uxWideTallBooleanDataSet();

        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);
        final horizontalBeforeToggle = horizontalController.offset;
        final verticalBeforeToggle = verticalController.offset;
        expect(horizontalBeforeToggle, greaterThan(0));
        expect(verticalBeforeToggle, greaterThan(0));

        await tester.tapAt(
          tester.getTopLeft(horizontalScrollView.first) + const Offset(140, 80),
        );
        await uxPumpPendingFrames(tester);

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
      final dataSet = uxWideTallDateDataSet();

      await uxPumpGrid(
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
      await uxPumpPendingFrames(tester);

      final horizontalBeforePicker = horizontalController.offset;
      final verticalBeforePicker = verticalController.offset;
      expect(horizontalBeforePicker, greaterThan(0));
      expect(verticalBeforePicker, greaterThan(0));

      await tester.tapAt(
        tester.getTopLeft(horizontalScrollView.first) + const Offset(90, 80),
      );
      await uxPumpPendingFrames(tester);

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
        final dataSet = uxWideTallDateDataSet();

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

        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);

        final horizontalBeforePicker = horizontalController.offset;
        final verticalBeforePicker = verticalController.offset;
        expect(horizontalBeforePicker, greaterThan(0));
        expect(verticalBeforePicker, greaterThan(0));

        await tester.tapAt(
          tester.getTopLeft(horizontalScrollView.first) + const Offset(90, 80),
        );
        await uxPumpPendingFrames(tester);

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
        await uxPumpPendingFrames(tester);

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
        final dataSet = uxWideTallBooleanDataSet();

        await uxPumpGrid(
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
        await uxPumpPendingFrames(tester);

        final horizontalBeforeToggle = horizontalController.offset;
        final verticalBeforeToggle = verticalController.offset;
        expect(horizontalBeforeToggle, greaterThan(0));
        expect(verticalBeforeToggle, greaterThan(0));

        await tester.tapAt(
          tester.getTopLeft(horizontalScrollView.first) + const Offset(90, 80),
        );
        await uxPumpPendingFrames(tester);

        expect(FdcDataSetInternal.activeIndex(dataSet), greaterThan(0));
        expect(
          horizontalController.offset,
          closeTo(horizontalBeforeToggle, 1.0),
        );
        expect(verticalController.offset, closeTo(verticalBeforeToggle, 1.0));
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Embedded Control', () {
    _registerEmbeddedControlTests();
  });
}
