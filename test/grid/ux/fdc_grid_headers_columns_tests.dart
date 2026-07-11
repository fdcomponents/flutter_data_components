part of '../fdc_grid_widget_ux_test.dart';

void _registerHeadersAndColumnsTests() {
  group('Headers and columns', () {
    testWidgets(
      'Column header label click hides grid selected cell indicator',
      (tester) async {
        const selectedColor = Colors.cyan;
        final dataSet = _peopleDataSet();

        await _pumpGrid(
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
        await tester.pumpAndSettle();
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.tap(find.text('Name'));
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), 0);
        expect(dataSet.sort.items, isEmpty);
      },
    );

    testWidgets('Sortable column header label click keeps grid defocused', (
      tester,
    ) async {
      const selectedColor = Colors.cyan;
      final dataSet = _peopleDataSet();

      await _pumpGrid(
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
      await tester.pumpAndSettle();
      expect(selectedCellBackgroundCount(), greaterThan(0));

      await tester.tap(find.text('Name'));
      await tester.pumpAndSettle();

      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(selectedCellBackgroundCount(), 0);
      expect(dataSet.sort.items, isNotEmpty);
    });

    testWidgets('Header filter focus hides grid selected cell indicator', (
      tester,
    ) async {
      const selectedColor = Colors.cyan;
      final dataSet = _peopleDataSet();

      await _pumpFilterGrid(
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
      await tester.pumpAndSettle();
      expect(selectedCellBackgroundCount(), greaterThan(0));

      await tester.tap(find.byType(EditableText).first);
      await tester.pumpAndSettle();

      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(selectedCellBackgroundCount(), 0);
    });

    testWidgets('Enter in header filter keeps focus in header filter', (
      tester,
    ) async {
      final dataSet = _peopleStatusDataSet();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        header: _zeroDebounceHeader,
      );

      final firstFilter = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );

      await tester.tap(find.byType(EditableText).first);
      await tester.pumpAndSettle();

      expect(firstFilter.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(firstFilter.focusNode.hasFocus, isTrue);
    });

    testWidgets('Home and End in header filter keep text input focus', (
      tester,
    ) async {
      final dataSet = _peopleStatusDataSet();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        header: _zeroDebounceHeader,
      );

      final filterFinder = find.byType(EditableText).first;

      await tester.tap(filterFinder);
      await tester.enterText(filterFinder, 'Alpha');
      await tester.pumpAndSettle();

      EditableText filter = tester.widget<EditableText>(filterFinder);
      expect(filter.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();

      filter = tester.widget<EditableText>(filterFinder);
      expect(filter.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();

      filter = tester.widget<EditableText>(filterFinder);
      expect(filter.focusNode.hasFocus, isTrue);
    });

    testWidgets('mouse wheel over header filter keeps focus in header filter', (
      tester,
    ) async {
      final dataSet = _peopleStatusDataSet();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name'),
          FdcTextColumn<dynamic>(fieldName: 'status'),
        ],
        header: _zeroDebounceHeader,
      );

      final statusFilterFinder = find.byType(EditableText).at(1);
      final statusFilter = tester.widget<EditableText>(statusFilterFinder);

      await tester.tap(statusFilterFinder);
      await tester.pumpAndSettle();

      expect(statusFilter.focusNode.hasFocus, isTrue);

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(statusFilterFinder),
          scrollDelta: const Offset(0, -24),
        ),
      );
      await tester.pumpAndSettle();

      expect(statusFilter.focusNode.hasFocus, isTrue);

      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: tester.getCenter(statusFilterFinder),
          scrollDelta: const Offset(0, 24),
        ),
      );
      await tester.pumpAndSettle();

      expect(statusFilter.focusNode.hasFocus, isTrue);
    });

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

        await _pumpGrid(
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
        await tester.pumpAndSettle();
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

      await _pumpGrid(
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
      await tester.pumpAndSettle();
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
        await _pumpGrid(
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
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'header filters remain interactive after repeated no-op column drags',
      (tester) async {
        final dataSet = _peopleStatusDataSet();

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
            FdcTextColumn<dynamic>(fieldName: 'status'),
          ],
          header: _zeroDebounceHeader,
        );

        await tester.drag(find.text('Name'), const Offset(1, 0));
        await tester.pumpAndSettle();
        await tester.drag(find.text('Name'), const Offset(1, 0));
        await tester.pumpAndSettle();
        await tester.drag(find.text('Status'), const Offset(1, 0));
        await tester.pumpAndSettle();

        final firstFilterFinder = find.byType(EditableText).first;
        final secondFilterFinder = find.byType(EditableText).at(1);
        final firstFilter = tester.widget<EditableText>(firstFilterFinder);
        final secondFilter = tester.widget<EditableText>(secondFilterFinder);

        await tester.tap(firstFilterFinder);
        await tester.enterText(firstFilterFinder, 'Al');
        await tester.pumpAndSettle();

        expect(firstFilter.focusNode.hasFocus, isTrue);
        expect(secondFilter.focusNode.hasFocus, isFalse);
        expect(firstFilter.controller.text, 'Al');

        await tester.tap(secondFilterFinder);
        await tester.enterText(secondFilterFinder, 'Active');
        await tester.pumpAndSettle();

        expect(firstFilter.focusNode.hasFocus, isFalse);
        expect(secondFilter.focusNode.hasFocus, isTrue);
        expect(secondFilter.controller.text, 'Active');
      },
    );

    testWidgets(
      'duplicate identical field-bound header filters keep separate focus',
      (tester) async {
        final dataSet = _peopleDataSet();

        await _pumpGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(fieldName: 'name'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          header: _zeroDebounceHeader,
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
        await tester.pumpAndSettle();

        expect(headerFilterFocusNodeAt(0).hasFocus, isTrue);
        expect(headerFilterFocusNodeAt(1).hasFocus, isFalse);
      },
    );

    testWidgets(
      'duplicate field-bound columns keep separate selected-cell identity',
      (tester) async {
        const selectedColor = Colors.deepPurple;
        final dataSet = _peopleDataSet();

        await _pumpGrid(
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
        await tester.pumpAndSettle();
        final firstColumnSelectedRect = selectedCellRect();

        await tester.tap(find.text('Alpha').at(1));
        await tester.pumpAndSettle();
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
      final dataSet = _peopleDataSet();

      await _pumpGrid(
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

    testWidgets(
      'ArrowUp on first row keeps grid focus when filters are hidden',
      (tester) async {
        const selectedColor = Colors.orange;
        final dataSet = _peopleDataSet();

        await _pumpGrid(
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
        await tester.pumpAndSettle();
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      },
    );

    testWidgets(
      'ArrowUp on first row ignores non-focusable header filter cell',
      (tester) async {
        const selectedColor = Colors.orange;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcBooleanField(name: 'active'),
            FdcStringField(size: 255, name: 'name'),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'active': false, 'name': 'Alpha'},
              <String, Object?>{'id': 2, 'active': true, 'name': 'Beta'},
            ],
          ),
        );
        dataSet.open();

        await _pumpFilterGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcBooleanColumn<dynamic>(fieldName: 'active', width: 100),
            FdcTextColumn<dynamic>(fieldName: 'name', width: 140),
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

        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      },
    );

    testWidgets(
      'ArrowUp on first row ignores menu-only list header filter cell',
      (tester) async {
        const selectedColor = Colors.orange;
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[
            FdcIntegerField(name: 'id'),
            FdcStringField(size: 32, name: 'status'),
          ],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              <String, Object?>{'id': 1, 'status': 'New'},
              <String, Object?>{'id': 2, 'status': 'Closed'},
            ],
          ),
        );
        dataSet.open();

        await _pumpFilterGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(
              fieldName: 'status',
              width: 140,
              filterConfig: FdcColumnFilterConfig(
                editor: FdcFilterEditor.list,
                values: <FdcOption<Object?>>[
                  FdcOption<Object?>(value: 'New', label: 'New'),
                  FdcOption<Object?>(value: 'Closed', label: 'Closed'),
                ],
              ),
            ),
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

        await tester.tap(find.text('New').last, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(selectedCellBackgroundCount(), greaterThan(0));

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(FdcDataSetInternal.activeIndex(dataSet), 1);
      },
    );

    testWidgets(
      'list header filter apply waits for draft changes and all applies immediately',
      (tester) async {
        final dataSet = FdcDataSet(
          fields: const <FdcFieldDef>[FdcStringField(size: 32, name: 'status')],
          adapter: FdcMemoryDataAdapter(
            rows: const <Map<String, Object?>>[
              <String, Object?>{'status': 'New'},
              <String, Object?>{'status': 'Closed'},
            ],
          ),
        );
        dataSet.open();

        await _pumpFilterGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcTextColumn<dynamic>(
              fieldName: 'status',
              width: 140,
              filterConfig: FdcColumnFilterConfig(
                editor: FdcFilterEditor.list,
                values: <FdcOption<Object?>>[
                  FdcOption<Object?>(value: 'New', label: 'New'),
                  FdcOption<Object?>(value: 'Closed', label: 'Closed'),
                ],
              ),
            ),
          ],
        );

        await tester.tap(find.text('All').first);
        await tester.pumpAndSettle();

        var applyButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Apply'),
        );
        expect(applyButton.onPressed, isNull);

        await tester.tap(find.text('New').last, warnIfMissed: false);
        await tester.pumpAndSettle();

        applyButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Apply'),
        );
        expect(applyButton.onPressed, isNotNull);

        await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
        await tester.pumpAndSettle();

        expect(dataSet.filter.fieldItems, hasLength(1));
        expect(
          dataSet.filter.fieldItems.single.operator,
          FdcFilterOperator.inList,
        );
        expect(find.text('New'), findsOneWidget);
        expect(find.text('Closed'), findsNothing);

        await tester.tap(find.text('1 selected'));
        await tester.pumpAndSettle();

        applyButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Apply'),
        );
        expect(applyButton.onPressed, isNull);

        await tester.tap(find.text('All').last, warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(dataSet.filter.fieldItems, isEmpty);
        expect(find.widgetWithText(FilledButton, 'Apply'), findsNothing);
        expect(find.text('New'), findsOneWidget);
        expect(find.text('Closed'), findsOneWidget);
      },
    );

    testWidgets('Tab in header filters skips non-focusable filter columns', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcIntegerField(name: 'id'),
          FdcStringField(size: 32, name: 'name'),
          FdcStringField(size: 32, name: 'status'),
          FdcBooleanField(name: 'active'),
          FdcStringField(size: 32, name: 'note'),
        ],
        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            <String, Object?>{
              'id': 1,
              'name': 'Alpha',
              'status': 'New',
              'active': true,
              'note': 'First',
            },
          ],
        ),
      );
      dataSet.open();

      await _pumpFilterGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcTextColumn<dynamic>(fieldName: 'name', width: 120),
          FdcTextColumn<dynamic>(
            fieldName: 'status',
            width: 120,
            filterConfig: FdcColumnFilterConfig(
              editor: FdcFilterEditor.list,
              values: <FdcOption<Object?>>[
                FdcOption<Object?>(value: 'New', label: 'New'),
                FdcOption<Object?>(value: 'Closed', label: 'Closed'),
              ],
            ),
          ),
          FdcBooleanColumn<dynamic>(fieldName: 'active', width: 100),
          FdcTextColumn<dynamic>(fieldName: 'note', width: 120),
        ],
      );

      List<EditableText> headerFilterInputs() => tester
          .widgetList<EditableText>(find.byType(EditableText))
          .where((editor) => editor.controller.text.isEmpty && !editor.readOnly)
          .toList(growable: false);

      final inputs = headerFilterInputs();
      expect(inputs, hasLength(2));

      await tester.tap(find.byType(EditableText).first);
      await tester.pumpAndSettle();
      expect(headerFilterInputs().first.focusNode.hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final afterTab = headerFilterInputs();
      expect(afterTab.first.focusNode.hasFocus, isFalse);
      expect(afterTab.last.focusNode.hasFocus, isTrue);
    });

    testWidgets(
      'ArrowUp on first row is no-op while editing with filters visible',
      (tester) async {
        final dataSet = _peopleDataSet();

        await _pumpFilterGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id', readOnly: true),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
        );

        await tester.tap(find.text('Alpha').first);
        await tester.pumpAndSettle();
        expect(FdcDataSetInternal.activeIndex(dataSet), 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.f2);
        await tester.pumpAndSettle();
        expect(dataSet.state, FdcDataSetState.edit);

        EditableText activeNameEditor() {
          return tester
              .widgetList<EditableText>(find.byType(EditableText))
              .firstWhere((editor) => editor.controller.text == 'Alpha');
        }

        expect(activeNameEditor().focusNode.hasFocus, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();

        expect(FdcDataSetInternal.activeIndex(dataSet), 0);
        expect(dataSet.state, FdcDataSetState.edit);
        expect(activeNameEditor().focusNode.hasFocus, isTrue);
        expect(
          tester
              .widgetList<EditableText>(find.byType(EditableText))
              .where((editor) => editor.controller.text != 'Alpha')
              .any((editor) => editor.focusNode.hasFocus),
          isFalse,
        );
      },
    );

    testWidgets('external editor update preserves grid horizontal scroll', (
      tester,
    ) async {
      final dataSet = FdcDataSet(
        fields: const <FdcFieldDef>[
          FdcStringField(size: 255, name: 'c1'),
          FdcStringField(size: 255, name: 'c2'),
          FdcStringField(size: 255, name: 'c3'),
          FdcStringField(size: 255, name: 'c4'),
          FdcStringField(size: 255, name: 'c5'),
        ],

        adapter: FdcMemoryDataAdapter(
          rows: const <Map<String, Object?>>[
            {
              'c1': 'one',
              'c2': 'two',
              'c3': 'three',
              'c4': 'four',
              'c5': 'five',
            },
          ],
        ),
      )..open();
      final externalEditorKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 260,
                  height: 180,
                  child: FdcGrid(
                    dataSet: dataSet,
                    header: const FdcGridHeader(height: 32),
                    columns: const <FdcGridColumn<dynamic>>[
                      FdcTextColumn<dynamic>(fieldName: 'c1'),
                      FdcTextColumn<dynamic>(fieldName: 'c2'),
                      FdcTextColumn<dynamic>(fieldName: 'c3'),
                      FdcTextColumn<dynamic>(fieldName: 'c4'),
                      FdcTextColumn<dynamic>(fieldName: 'c5'),
                    ],
                    options: const FdcGridOptions(
                      defaultColumnWidth: 150,
                      rowHeight: 36,
                    ),
                  ),
                ),
                FdcTextEdit(
                  key: externalEditorKey,
                  dataSet: dataSet,
                  fieldName: 'c1',
                  label: 'External c1',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

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
      final offsetBeforeExternalEdit = controller.offset;
      expect(offsetBeforeExternalEdit, greaterThan(0));

      await tester.tap(find.byKey(externalEditorKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).last,
        'changed outside',
      );
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      expect(dataSet['c1'], 'changed outside');
      expect(controller.offset, offsetBeforeExternalEdit);
    });
  });
}
