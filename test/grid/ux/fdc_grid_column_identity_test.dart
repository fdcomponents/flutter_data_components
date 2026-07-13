import 'fdc_grid_ux_test_support.dart';

void _registerColumnIdentityTests() {
  group('Column identity and sizing', () {
    testWidgets(
      'duplicate identical field-bound header filters keep separate focus',
      (tester) async {
        final dataSet = uxPeopleDataSet();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          header: uxZeroDebounceHeader,
        );

        FocusNode headerFilterFocusNodeAt(int index) => tester
            .widget<EditableText>(find.byType(EditableText).at(index))
            .focusNode;

        expect(find.byType(EditableText), findsNWidgets(2));

        expect(
          identical(headerFilterFocusNodeAt(0), headerFilterFocusNodeAt(1)),
          isFalse,
        );

        await tester.tap(find.byType(EditableText).at(0));
        await uxPumpPendingFrames(tester);

        expect(headerFilterFocusNodeAt(0).hasFocus, isTrue);
        expect(headerFilterFocusNodeAt(1).hasFocus, isFalse);
      },
    );

    testWidgets(
      'duplicate field-bound columns keep separate selected-cell identity',
      (tester) async {
        const selectedColor = Colors.deepPurple;
        final dataSet = uxPeopleDataSet();

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name A'),
            FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name B'),
          ],
          style: const FdcGridStyle(selectedCellBackgroundColor: selectedColor),
        );

        Rect selectedCellRect() {
          final selectedCellFinder = find.byWidgetPredicate((widget) {
            if (widget is! Container) {
              return false;
            }
            final decoration = widget.decoration;
            return decoration is BoxDecoration &&
                decoration.color == selectedColor;
          });

          final matches = selectedCellFinder.evaluate().toList();
          expect(matches, isNotEmpty);

          final rects = <Rect>[
            for (var i = 0; i < matches.length; i++)
              tester.getRect(selectedCellFinder.at(i)),
          ];
          rects.sort(
            (a, b) => (b.width * b.height).compareTo(a.width * a.height),
          );
          return rects.first;
        }

        expect(find.text('Alpha'), findsNWidgets(2));

        await tester.tap(find.text('Alpha').at(0));
        await uxPumpPendingFrames(tester);
        final firstColumnSelectedRect = selectedCellRect();

        await tester.tap(find.text('Alpha').at(1));
        await uxPumpPendingFrames(tester);
        final secondColumnSelectedRect = selectedCellRect();

        expect(
          secondColumnSelectedRect.center.dx,
          greaterThan(firstColumnSelectedRect.center.dx + 50),
        );
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      },
    );

    testWidgets('duplicate field-bound columns keep separate explicit widths', (
      tester,
    ) async {
      final dataSet = uxPeopleDataSet();

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name', label: 'Name A', width: 80),
          FdcTextColumn<dynamic>(
            fieldName: 'name',
            label: 'Name B',
            width: 180,
          ),
        ],
      );

      final firstHeader = tester.getRect(find.text('Name A'));
      final secondHeader = tester.getRect(find.text('Name B'));
      final delta = secondHeader.left - firstHeader.left;

      expect(delta, greaterThan(60));
      expect(
        delta,
        lessThan(120),
        reason:
            'Duplicate field-bound columns must keep width by runtime column id, '
            'not by shared fieldName.',
      );
    });
  });
}

void main() {
  group('FdcGrid widget UX / Column Identity', () {
    _registerColumnIdentityTests();
  });
}
