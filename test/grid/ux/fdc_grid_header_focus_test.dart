import 'fdc_grid_ux_test_support.dart';

void _registerHeaderFocusTests() {
  group('Header focus and selection', () {
    testWidgets(
      'Column header label click hides grid selected cell indicator',
      (tester) async {
        const selectedColor = Colors.cyan;
        final dataSet = uxPeopleDataSet();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          options: const FdcGridOptions(),
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
          ],
          style: const FdcGridStyle(selectedCellBackgroundColor: selectedColor),
        );

        int selectedCellBackgroundCount() {
          return tester.widgetList<Container>(find.byType(Container)).where((
            container,
          ) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.color == selectedColor;
          }).length;
        }

        await tester.tap(find.text('Alpha').first);
        await uxPumpPendingFrames(tester);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.tap(find.text('Name'));
        await uxPumpPendingFrames(tester);

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), 0);
        expect(dataSet.sort.items, isEmpty);
      },
    );

    testWidgets('Sortable column header label click keeps grid defocused', (
      tester,
    ) async {
      const selectedColor = Colors.cyan;
      final dataSet = uxPeopleDataSet();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name'),
        ],
        style: const FdcGridStyle(selectedCellBackgroundColor: selectedColor),
      );

      int selectedCellBackgroundCount() {
        return tester.widgetList<Container>(find.byType(Container)).where((
          container,
        ) {
          final decoration = container.decoration;
          return decoration is BoxDecoration &&
              decoration.color == selectedColor;
        }).length;
      }

      await tester.tap(find.text('Alpha').first);
      await uxPumpPendingFrames(tester);
      expect(selectedCellBackgroundCount(), greaterThan(0));

      await tester.tap(find.text('Name'));
      await uxPumpPendingFrames(tester);

      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(selectedCellBackgroundCount(), 0);
      expect(dataSet.sort.items, isNotEmpty);
    });

    testWidgets('Header filter focus hides grid selected cell indicator', (
      tester,
    ) async {
      const selectedColor = Colors.cyan;
      final dataSet = uxPeopleDataSet();

      await uxPumpFilterGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        style: const FdcGridStyle(selectedCellBackgroundColor: selectedColor),
      );

      int selectedCellBackgroundCount() {
        return tester.widgetList<Container>(find.byType(Container)).where((
          container,
        ) {
          final decoration = container.decoration;
          return decoration is BoxDecoration &&
              decoration.color == selectedColor;
        }).length;
      }

      await tester.tap(find.text('Alpha').first);
      await uxPumpPendingFrames(tester);
      expect(selectedCellBackgroundCount(), greaterThan(0));

      await tester.tap(find.byType(EditableText).first);
      await uxPumpPendingFrames(tester);

      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(selectedCellBackgroundCount(), 0);
    });

    testWidgets('Enter in header filter keeps focus in header filter', (
      tester,
    ) async {
      final dataSet = uxPeopleStatusDataSet();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        header: uxZeroDebounceHeader,
      );

      final firstFilter = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );

      await tester.tap(find.byType(EditableText).first);
      await uxPumpPendingFrames(tester);

      expect(firstFilter.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await uxPumpPendingFrames(tester);

      expect(firstFilter.focusNode.hasFocus, isTrue);
    });

    testWidgets('Home and End in header filter keep text input focus', (
      tester,
    ) async {
      final dataSet = uxPeopleStatusDataSet();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        header: uxZeroDebounceHeader,
      );

      final filterFinder = find.byType(EditableText).first;

      await tester.tap(filterFinder);
      await tester.enterText(filterFinder, 'Alpha');
      await uxPumpPendingFrames(tester);

      EditableText filter = tester.widget<EditableText>(filterFinder);
      expect(filter.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await uxPumpPendingFrames(tester);

      filter = tester.widget<EditableText>(filterFinder);
      expect(filter.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await uxPumpPendingFrames(tester);

      filter = tester.widget<EditableText>(filterFinder);
      expect(filter.focusNode.hasFocus, isTrue);
    });

    testWidgets('mouse wheel over header filter keeps focus in header filter', (
      tester,
    ) async {
      final dataSet = uxPeopleStatusDataSet();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        header: uxZeroDebounceHeader,
      );

      final statusFilterFinder = find.byType(EditableText).at(1);
      final statusFilter = tester.widget<EditableText>(statusFilterFinder);

      await tester.tap(statusFilterFinder);
      await uxPumpPendingFrames(tester);

      expect(statusFilter.focusNode.hasFocus, isTrue);

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(statusFilterFinder),
          scrollDelta: const Offset(0, -24),
        ),
      );
      await uxPumpPendingFrames(tester);

      expect(statusFilter.focusNode.hasFocus, isTrue);

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(statusFilterFinder),
          scrollDelta: const Offset(0, 24),
        ),
      );
      await uxPumpPendingFrames(tester);

      expect(statusFilter.focusNode.hasFocus, isTrue);
    });
  });
}

void main() {
  group('FdcGrid widget UX / Header Focus', () {
    _registerHeaderFocusTests();
  });
}
