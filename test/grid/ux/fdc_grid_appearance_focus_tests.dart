part of '../fdc_grid_widget_ux_test.dart';

void _registerAppearanceAndFocusTests() {
  group('Appearance and focus', () {
    testWidgets('Grid background styling paints the viewport surface', (
      tester,
    ) async {
      final backgroundColor = Colors.deepPurple.shade50;
      final dataSet = _peopleDataSet();

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        style: FdcGridStyle(backgroundColor: backgroundColor),
      );

      final gridBackgroundCount = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((box) => box.color == backgroundColor)
          .length;

      expect(gridBackgroundCount, greaterThan(0));
    });

    testWidgets('Selected row styling paints the whole row background', (
      tester,
    ) async {
      final selectedRowColor = Colors.indigo.shade100;
      final dataSet = _peopleDataSet();

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        style: FdcGridStyle(selectedRowColor: selectedRowColor),
      );

      await tester.tap(find.text('Alpha').first);
      await tester.pumpAndSettle();

      final selectedRowBackgroundCount = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((box) => box.color == selectedRowColor)
          .length;

      expect(selectedRowBackgroundCount, greaterThan(0));
    });

    testWidgets('Read-only cells do not get a default background fill', (
      tester,
    ) async {
      final dataSet = _peopleStatusDataSet();
      Color? backgroundColor;

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: <FdcGridColumn<dynamic>>[
          FdcCustomColumn<String>(
            fieldName: 'status',
            label: 'Status',
            readOnly: true,
            cellBuilder: (field, cell) {
              if (field.rowIndex == 0) {
                backgroundColor = cell.backgroundColor;
              }
              return Text(field.value ?? '');
            },
          ),
        ],
      );

      expect(backgroundColor, isNull);
    });

    testWidgets('Disabled cell styling uses grid cell style color', (
      tester,
    ) async {
      final disabledCellColor = Colors.blueGrey.shade100;
      final dataSet = _peopleDataSet();

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name', enabled: false),
        ],
        style: FdcGridStyle(disabledCellBackgroundColor: disabledCellColor),
      );

      final disabledCellBackgroundCount = find
          .byWidgetPredicate((widget) {
            if (widget is! Container) {
              return false;
            }
            final decoration = widget.decoration;
            return decoration is BoxDecoration &&
                decoration.color == disabledCellColor;
          })
          .evaluate()
          .length;

      expect(disabledCellBackgroundCount, greaterThan(0));
    });

    testWidgets(
      'Grid header style groups header colors and text style while line color controls bottom divider',
      (tester) async {
        const headerBackgroundColor = Color(0xFFE0F2FE);
        const horizontalLineColor = Color(0xFF0369A1);
        const headerTextStyle = TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        );
        final dataSet = _peopleDataSet();

        await _pumpBasicGrid(
          tester,
          dataSet: dataSet,
          columns: const <FdcGridColumn<dynamic>>[
            FdcIntegerColumn<dynamic>(fieldName: 'id'),
            FdcTextColumn<dynamic>(fieldName: 'name'),
          ],
          header: const FdcGridHeader(
            height: 32,
            style: FdcGridHeaderStyle(
              backgroundColor: headerBackgroundColor,
              textStyle: headerTextStyle,
            ),
          ),
          style: const FdcGridStyle(gridLineColor: horizontalLineColor),
        );

        final headerText = tester.widget<Text>(find.text('Name').first);
        expect(headerText.style?.fontSize, headerTextStyle.fontSize);
        expect(headerText.style?.fontWeight, headerTextStyle.fontWeight);

        final headerBackgroundCount = tester
            .widgetList<Container>(find.byType(Container))
            .where((container) {
              final decoration = container.decoration;
              return decoration is BoxDecoration &&
                  decoration.color == headerBackgroundColor;
            })
            .length;
        final headerBottomBorderCount = tester
            .widgetList<ColoredBox>(find.byType(ColoredBox))
            .where((box) => box.color == horizontalLineColor)
            .length;

        expect(headerBackgroundCount, greaterThan(0));
        expect(headerBottomBorderCount, greaterThan(0));
      },
    );

    testWidgets('Grid header filter style controls filter colors', (
      tester,
    ) async {
      const backgroundColor = Color(0xFFFFFBEB);
      const unfocusedBorderColor = Color(0xFF92400E);
      const focusedBorderColor = Color(0xFF2563EB);
      const unfocusedLabelColor = Color(0xFF78350F);
      const focusedLabelColor = Color(0xFF1D4ED8);
      const filterIconColor = Color(0xFF374151);
      const activeFilterIconColor = Color(0xFF2563EB);
      const unfocusedBorderWidth = 1.5;
      const focusedBorderWidth = 2.0;
      const labelTextStyle = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );
      const filterHeight = 38.0;
      final dataSet = _peopleDataSet();

      await _pumpFilterGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        header: const FdcGridHeader(
          height: 32,
          filters: FdcGridHeaderFilters(
            visible: true,
            style: FdcGridHeaderFilterStyle(
              backgroundColor: backgroundColor,
              unfocusedBorderColor: unfocusedBorderColor,
              focusedBorderColor: focusedBorderColor,
              unfocusedLabelColor: unfocusedLabelColor,
              focusedLabelColor: focusedLabelColor,
              filterIconColor: filterIconColor,
              activeFilterIconColor: activeFilterIconColor,
              unfocusedBorderWidth: unfocusedBorderWidth,
              focusedBorderWidth: focusedBorderWidth,
              labelTextStyle: labelTextStyle,
              height: filterHeight,
            ),
          ),
        ),
      );

      int shellCountFor(Color color, double width) => tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where((box) {
            final decoration = box.decoration;
            if (decoration is! BoxDecoration) {
              return false;
            }
            final border = decoration.border;
            return decoration.color == backgroundColor &&
                border is Border &&
                border.top.color == color &&
                border.top.width == width;
          })
          .length;

      expect(
        shellCountFor(unfocusedBorderColor, unfocusedBorderWidth),
        greaterThan(0),
      );
      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .where(
              (text) =>
                  text.style?.color == unfocusedLabelColor &&
                  text.style?.fontSize == labelTextStyle.fontSize &&
                  text.style?.fontWeight == labelTextStyle.fontWeight,
            )
            .length,
        greaterThan(0),
      );

      await tester.tap(find.byType(EditableText).first);
      await tester.pumpAndSettle();

      expect(
        shellCountFor(focusedBorderColor, focusedBorderWidth),
        greaterThan(0),
      );
      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .where(
              (text) =>
                  text.style?.color == focusedLabelColor &&
                  text.style?.fontSize == labelTextStyle.fontSize &&
                  text.style?.fontWeight == labelTextStyle.fontWeight,
            )
            .length,
        greaterThan(0),
      );
    });

    testWidgets('disabled column filter renders a disabled header filter box', (
      tester,
    ) async {
      final dataSet = _peopleDataSet();

      await _pumpGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(
            fieldName: 'id',
            filterConfig: FdcColumnFilterConfig(enabled: false),
          ),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        header: _zeroDebounceHeader,
        toolbarVisible: false,
      );

      expect(find.byType(FdcGridHeaderFilterRowFrame), findsNWidgets(3));
      expect(find.byType(FdcGridHeaderLabelFilterSeparator), findsNWidgets(2));
      expect(find.byType(EditableText), findsOneWidget);
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      expect(fields.every((field) => field.enabled ?? false), isTrue);
      expect(find.text('Equals'), findsNothing);
    });

    testWidgets('Grid cell style provides default cell text style', (
      tester,
    ) async {
      const cellTextStyle = TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
      );
      final dataSet = _peopleDataSet();

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        style: const FdcGridStyle(cellTextStyle: cellTextStyle),
      );

      final text = tester.widget<Text>(find.text('Alpha').first);

      expect(text.style?.fontSize, cellTextStyle.fontSize);
      expect(text.style?.fontWeight, cellTextStyle.fontWeight);
    });

    testWidgets('In-place editor keeps the cell text font size', (
      tester,
    ) async {
      const cellTextStyle = TextStyle(fontSize: 11);
      final dataSet = _peopleDataSet();

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        style: const FdcGridStyle(cellTextStyle: cellTextStyle),
      );

      final cellFinder = find.text('Alpha').first;
      await tester.tap(cellFinder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(cellFinder);
      await tester.pumpAndSettle();

      var editableText = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(editableText.style.fontSize, cellTextStyle.fontSize);
      expect(editableText.strutStyle.fontSize, cellTextStyle.fontSize);
      expect(editableText.strutStyle.forceStrutHeight, isTrue);

      await tester.enterText(find.byType(EditableText).first, 'Beta');
      await tester.pump();

      editableText = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(editableText.controller.text, 'Beta');
      expect(editableText.style.fontSize, cellTextStyle.fontSize);
      expect(editableText.strutStyle.fontSize, cellTextStyle.fontSize);
      expect(editableText.strutStyle.forceStrutHeight, isTrue);
    });

    testWidgets('Cell indicator style supports outline mode', (tester) async {
      const indicatorColor = Colors.deepPurple;
      final dataSet = _peopleDataSet();

      await _pumpBasicGrid(
        tester,
        dataSet: dataSet,
        columns: const <FdcGridColumn<dynamic>>[
          FdcIntegerColumn<dynamic>(fieldName: 'id'),
          FdcTextColumn<dynamic>(fieldName: 'name'),
        ],
        cellIndicator: const FdcGridCellIndicator(
          mode: FdcGridCellIndicatorMode.outline,
          style: FdcGridCellIndicatorStyle(
            editableColor: indicatorColor,
            thickness: 3,
          ),
        ),
      );

      await tester.tap(find.text('Alpha').first);
      await tester.pumpAndSettle();

      final outlineCount = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where(
            (paint) =>
                paint.painter.runtimeType.toString() == '_CellOutlinePainter',
          )
          .length;

      expect(outlineCount, greaterThan(0));
    });

    testWidgets('Grid theme provides background styling defaults', (
      tester,
    ) async {
      final backgroundColor = Colors.green.shade100;
      final dataSet = _peopleDataSet();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: <ThemeExtension<dynamic>>[
              FdcGridTheme(
                style: FdcGridStyle(backgroundColor: backgroundColor),
              ),
            ],
          ),
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 320,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(height: 32),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcIntegerColumn<dynamic>(fieldName: 'id'),
                  FdcTextColumn<dynamic>(fieldName: 'name'),
                ],
                options: _basicGridOptions.copyWith(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backgroundCount = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((box) => box.color == backgroundColor)
          .length;

      expect(backgroundCount, greaterThan(0));
    });

    testWidgets('Local grid style overrides grid theme background styling', (
      tester,
    ) async {
      final themeBackgroundColor = Colors.green.shade100;
      final localBackgroundColor = Colors.purple.shade100;
      final dataSet = _peopleDataSet();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: <ThemeExtension<dynamic>>[
              FdcGridTheme(
                style: FdcGridStyle(backgroundColor: themeBackgroundColor),
              ),
            ],
          ),
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 320,
              child: FdcGrid(
                dataSet: dataSet,
                header: const FdcGridHeader(height: 32),
                columns: const <FdcGridColumn<dynamic>>[
                  FdcIntegerColumn<dynamic>(fieldName: 'id'),
                  FdcTextColumn<dynamic>(fieldName: 'name'),
                ],
                options: _basicGridOptions.copyWith(
                  defaultColumnWidth: 140,
                  rowHeight: 36,
                ),
                style: FdcGridStyle(backgroundColor: localBackgroundColor),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final localBackgroundCount = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((box) => box.color == localBackgroundColor)
          .length;
      final themeBackgroundCount = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((box) => box.color == themeBackgroundColor)
          .length;

      expect(localBackgroundCount, greaterThan(0));
      expect(themeBackgroundCount, 0);
    });

    testWidgets('External editor focus hides grid selected cell indicator', (
      tester,
    ) async {
      const selectedColor = Colors.pink;
      final dataSet = _peopleDataSet();
      final externalEditorKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 600,
                  height: 220,
                  child: FdcGrid(
                    dataSet: dataSet,
                    header: const FdcGridHeader(height: 32),
                    options: const FdcGridOptions(
                      defaultColumnWidth: 140,
                      rowHeight: 36,
                    ),
                    columns: const <FdcGridColumn<dynamic>>[
                      FdcIntegerColumn<dynamic>(
                        fieldName: 'id',
                        readOnly: true,
                      ),
                      FdcTextColumn<dynamic>(fieldName: 'name'),
                    ],
                    style: const FdcGridStyle(
                      selectedCellBackgroundColor: selectedColor,
                    ),
                  ),
                ),
                FdcTextEdit(
                  key: externalEditorKey,
                  dataSet: dataSet,
                  fieldName: 'name',
                  label: 'External name',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

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

      await tester.tap(find.byKey(externalEditorKey));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Alpha edited');
      await tester.pumpAndSettle();

      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(selectedCellBackgroundCount(), 0);
    });

    testWidgets('External editor focus keeps current row indicator visible', (
      tester,
    ) async {
      const selectedColor = Colors.pink;
      final dataSet = _peopleDataSet();
      final externalEditorKey = UniqueKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 600,
                  height: 220,
                  child: FdcGrid(
                    dataSet: dataSet,
                    header: const FdcGridHeader(height: 32),
                    options: const FdcGridOptions(
                      defaultColumnWidth: 140,
                      rowHeight: 36,
                    ),
                    columns: const <FdcGridColumn<dynamic>>[
                      FdcIntegerColumn<dynamic>(
                        fieldName: 'id',
                        readOnly: true,
                      ),
                      FdcTextColumn<dynamic>(fieldName: 'name'),
                    ],
                    rowIndicator: const FdcGridRowIndicator(visible: true),
                    style: const FdcGridStyle(
                      selectedCellBackgroundColor: selectedColor,
                    ),
                  ),
                ),
                FdcTextEdit(
                  key: externalEditorKey,
                  dataSet: dataSet,
                  fieldName: 'name',
                  label: 'External name',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      int rowIndicatorStatusIconCount() {
        return tester.widgetList<Icon>(find.byType(Icon)).where((icon) {
          return icon.icon == Icons.arrow_right ||
              icon.icon == Icons.edit_outlined ||
              icon.icon == Icons.add;
        }).length;
      }

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
      expect(rowIndicatorStatusIconCount(), 1);

      await tester.tap(find.byKey(externalEditorKey));
      await tester.pumpAndSettle();

      expect(FdcDataSetInternal.activeIndex(dataSet), 0);
      expect(selectedCellBackgroundCount(), 0);
      expect(rowIndicatorStatusIconCount(), 1);
    });
  });
}
