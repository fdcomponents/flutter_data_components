import 'fdc_grid_ux_test_support.dart';

void _registerColumnReorderTests() {
  group('Column reordering', () {
    testWidgets(
      'column reorder live-swaps the full column while hovering target',
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

        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'first', label: 'First'),
            FdcTextColumn<dynamic>(fieldName: 'second', label: 'Second'),
          ],
          toolbarVisible: false,
        );

        final firstHeader = find.byKey(
          const ValueKey<String>('fdc-grid-header-field-first'),
        );
        final secondHeader = find.byKey(
          const ValueKey<String>('fdc-grid-header-field-second'),
        );

        double centerX(Finder finder) => tester.getCenter(finder).dx;

        expect(centerX(firstHeader), lessThan(centerX(secondHeader)));
        expect(
          centerX(find.text('Alpha')),
          lessThan(centerX(find.text('Beta'))),
        );

        final sourceCenter = tester.getCenter(firstHeader);
        final targetCenter = tester.getCenter(secondHeader);
        final gesture = await tester.startGesture(sourceCenter);
        await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
        await gesture.moveTo(targetCenter);
        await tester.pump();

        final secondMidAnimationCenter = centerX(secondHeader);
        expect(secondMidAnimationCenter, greaterThan(centerX(firstHeader)));

        await tester.pump(fdcGridColumnReorderAnimationDuration);

        expect(centerX(secondHeader), lessThan(centerX(firstHeader)));
        expect(
          centerX(find.text('Beta')),
          lessThan(centerX(find.text('Alpha'))),
        );

        await gesture.up();
        await uxPumpPendingFrames(tester);
      },
    );

    testWidgets('column reorder live-swap does not ping-pong on wider target', (
      tester,
    ) async {
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

      await uxPumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'first', label: 'First', width: 60),
          FdcTextColumn<dynamic>(
            fieldName: 'second',
            label: 'Second',
            width: 240,
          ),
        ],
        toolbarVisible: false,
        width: 360,
      );

      final firstHeader = find.byKey(
        const ValueKey<String>('fdc-grid-header-field-first'),
      );
      final secondHeader = find.byKey(
        const ValueKey<String>('fdc-grid-header-field-second'),
      );

      double centerX(Finder finder) => tester.getCenter(finder).dx;

      final sourceCenter = tester.getCenter(firstHeader);
      final originalSecondCenter = tester.getCenter(secondHeader);
      final gesture = await tester.startGesture(sourceCenter);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.moveTo(originalSecondCenter);
      await tester.pump();

      // During the locked animation window the pointer can still be inside the
      // wider column that just moved left. That stale hover must not queue an
      // immediate swap-back while the short cooldown is active.
      await gesture.moveTo(originalSecondCenter.translate(1, 0));
      await tester.pump();
      await tester.pump(fdcGridColumnReorderAnimationDuration);

      expect(centerX(secondHeader), lessThan(centerX(firstHeader)));
      expect(centerX(find.text('Beta')), lessThan(centerX(find.text('Alpha'))));

      // After the cooldown expires, the user may deliberately drag back over
      // the same column and swap it again.
      await gesture.moveTo(originalSecondCenter.translate(2, 0));
      await tester.pump();
      await tester.pump(fdcGridColumnReorderAnimationDuration);

      expect(centerX(firstHeader), lessThan(centerX(secondHeader)));
      expect(centerX(find.text('Alpha')), lessThan(centerX(find.text('Beta'))));

      await gesture.up();
      await uxPumpPendingFrames(tester);
    });

    testWidgets(
      'column reorder flushes pending hover target after swap animation',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcStringField(size: 255, name: 'first'),
            FdcStringField(size: 255, name: 'second'),
            FdcStringField(size: 255, name: 'third'),
          ],

          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              {'first': 'Alpha', 'second': 'Beta', 'third': 'Gamma'},
            ],
          ),
        );
        dataSet.open();
        await uxPumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'first', label: 'First'),
            FdcTextColumn<dynamic>(fieldName: 'second', label: 'Second'),
            FdcTextColumn<dynamic>(fieldName: 'third', label: 'Third'),
          ],
          toolbarVisible: false,
          width: 480,
        );

        final firstHeader = find.byKey(
          const ValueKey<String>('fdc-grid-header-field-first'),
        );
        final secondHeader = find.byKey(
          const ValueKey<String>('fdc-grid-header-field-second'),
        );
        final thirdHeader = find.byKey(
          const ValueKey<String>('fdc-grid-header-field-third'),
        );

        double centerX(Finder finder) => tester.getCenter(finder).dx;

        final gesture = await tester.startGesture(
          tester.getCenter(firstHeader),
        );
        await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

        await gesture.moveTo(tester.getCenter(secondHeader));
        await tester.pump();

        // While the first swap animation is locked, hovering a later valid
        // target should be remembered instead of causing immediate flicker.
        await gesture.moveTo(tester.getCenter(thirdHeader).translate(-8, 0));
        await tester.pump();
        await tester.pump(fdcGridColumnReorderAnimationDuration);

        // When the lock expires, the pending hover target is re-evaluated and
        // the full dragged column continues swapping toward the mouse. Pump the
        // second animation window so the implicit column movement settles.
        await tester.pump(fdcGridColumnReorderAnimationDuration);

        expect(centerX(secondHeader), lessThan(centerX(thirdHeader)));
        expect(centerX(thirdHeader), lessThan(centerX(firstHeader)));
        expect(
          centerX(find.text('Beta')),
          lessThan(centerX(find.text('Gamma'))),
        );
        expect(
          centerX(find.text('Gamma')),
          lessThan(centerX(find.text('Alpha'))),
        );

        await gesture.up();
        await uxPumpPendingFrames(tester);
      },
    );

    testWidgets(
      'header filters remain interactive after repeated no-op column drags',
      (tester) async {
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

        await tester.drag(find.text('Name'), const Offset(1, 0));
        await uxPumpPendingFrames(tester);
        await tester.drag(find.text('Name'), const Offset(1, 0));
        await uxPumpPendingFrames(tester);
        await tester.drag(find.text('Status'), const Offset(1, 0));
        await uxPumpPendingFrames(tester);

        final firstFilterFinder = find.byType(EditableText).first;
        final secondFilterFinder = find.byType(EditableText).at(1);
        final firstFilter = tester.widget<EditableText>(firstFilterFinder);
        final secondFilter = tester.widget<EditableText>(secondFilterFinder);

        await tester.tap(firstFilterFinder);
        await tester.enterText(firstFilterFinder, 'Al');
        await uxPumpPendingFrames(tester);

        expect(firstFilter.focusNode.hasFocus, isTrue);
        expect(secondFilter.focusNode.hasFocus, isFalse);
        expect(firstFilter.controller.text, 'Al');

        await tester.tap(secondFilterFinder);
        await tester.enterText(secondFilterFinder, 'Active');
        await uxPumpPendingFrames(tester);

        expect(firstFilter.focusNode.hasFocus, isFalse);
        expect(secondFilter.focusNode.hasFocus, isTrue);
        expect(secondFilter.controller.text, 'Active');
      },
    );
  });
}

void main() {
  group('FdcGrid widget UX / Column Reorder', () {
    _registerColumnReorderTests();
  });
}
